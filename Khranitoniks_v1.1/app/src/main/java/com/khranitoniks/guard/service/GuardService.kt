package com.khranitoniks.guard.service

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Telephony
import com.khranitoniks.guard.R
import com.khranitoniks.guard.core.BlockReason
import com.khranitoniks.guard.core.Bonus
import com.khranitoniks.guard.core.Day
import com.khranitoniks.guard.core.EventLog
import com.khranitoniks.guard.core.LogType
import com.khranitoniks.guard.core.Mood
import com.khranitoniks.guard.core.Perms
import com.khranitoniks.guard.core.Prefs
import com.khranitoniks.guard.core.StatsStore
import com.khranitoniks.guard.core.TimeUtil
import com.khranitoniks.guard.core.TrackedApp
import com.khranitoniks.guard.core.TrackedApps
import com.khranitoniks.guard.core.UsageReader
import com.khranitoniks.guard.tools.GameMode
import java.util.Locale
import java.util.concurrent.Executors

/**
 * Фоновый мониторинг (ForegroundService, тип specialUse).
 * Каждые 2 секунды при включённом экране определяет активное приложение и применяет правила:
 * перерывы, дневной лимит, ночной режим, контроль доступа, замок настроек, блокировку при зарядке.
 */
class GuardService : Service(), OverlayListener {

    private val handler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private lateinit var prefs: Prefs
    private lateinit var reader: UsageReader
    private lateinit var bgReader: UsageReader
    private lateinit var overlay: OverlayController
    private lateinit var audio: AudioManager

    @Volatile private var todayUsage: Map<String, Long> = emptyMap()
    @Volatile private var usageAt = 0L
    @Volatile private var usageLoading = false

    private var screenOn = true
    private var lastTick = 0L
    private var lastNotifText = ""
    private var lastNotifAt = 0L
    private var lastStatsSave = 0L
    private var tracked: List<TrackedApp> = emptyList()
    private var trackedAt = 0L
    private var allowedCache: Set<String> = emptySet()
    private var allowedAt = 0L
    private var homeCache: Set<String> = emptySet()

    /**
     * «Липкая» блокировка: после срабатывания экран блокировки остаётся и поверх рабочего стола,
     * и поверх списка недавних приложений, пока ребёнок не нажмёт «Понятно» или условие не закончится.
     * Так приложение нельзя просто свернуть кнопкой «Домой» и открыть снова из недавних.
     */
    private var sticky: BlockReason? = null
    private var lastBlockedGroup: TrackedApp? = null
    private var lastHomeAt = 0L

    // состояние батареи
    private var batteryLevel = -1
    private var plugged = false
    private var temperature = 0.0

    private val tick = object : Runnable {
        override fun run() {
            try {
                onTick()
            } catch (t: Throwable) {
                // не даём сервису упасть
            }
            val delay = when {
                !screenOn -> TICK_OFF_MS
                overlay.isShowing || sticky != null -> TICK_FAST_MS
                else -> TICK_MS
            }
            handler.postDelayed(this, delay)
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val now = System.currentTimeMillis()
            when (intent.action) {
                Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                    if (!screenOn) {
                        screenOn = true
                        lastTick = now
                        reader.resetForeground()
                        handler.removeCallbacks(tick)
                        handler.post(tick)
                    }
                }
                Intent.ACTION_SCREEN_OFF -> {
                    if (screenOn) {
                        if (lastTick > 0) addScreenTime((now - lastTick).coerceIn(0L, 5_000L))
                        screenOn = false
                        lastTick = now
                        sticky = null
                        overlay.hide()
                    }
                }
            }
        }
    }

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_BATTERY_CHANGED) {
                readBattery(intent)
            } else {
                registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))?.let { readBattery(it) }
            }
            handleCharging(System.currentTimeMillis())
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        prefs = Prefs.get(this)
        reader = UsageReader(this)
        bgReader = UsageReader(this)
        overlay = OverlayController(this, this)
        audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        Notifier.createChannels(this)
        goForeground()
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        screenOn = pm.isInteractive
        registerReceiver(screenReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        })
        registerReceiver(batteryReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
        })?.let { readBattery(it) }
        scheduleWatchdog(this)
        lastTick = System.currentTimeMillis()
        handler.post(tick)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        goForeground()
        return START_STICKY
    }

    private fun goForeground() {
        val n = Notifier.serviceNotification(this, getString(R.string.service_text_start))
        try {
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(Notifier.ID_SERVICE, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(Notifier.ID_SERVICE, n)
            }
        } catch (e: Exception) {
            // система не разрешила — сервис будет перезапущен сторожем
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        scheduleRestart(this)
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        try {
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
        }
        try {
            unregisterReceiver(batteryReceiver)
        } catch (e: Exception) {
        }
        overlay.hide()
        io.shutdown()
        if (prefs.onboardingDone) scheduleRestart(this)
        super.onDestroy()
    }

    // =====================================================================
    //  основной цикл
    // =====================================================================
    private fun onTick() {
        val now = System.currentTimeMillis()
        val dt = if (lastTick == 0L) 0L else (now - lastTick).coerceIn(0L, 5_000L)
        lastTick = now
        if (Day.ensure(this, bgReader)) {
            todayUsage = emptyMap()
            usageAt = 0L
        }
        handleCharging(now)
        if (!screenOn) {
            overlay.hide()
            updateNotification(now)
            return
        }
        addScreenTime(dt)
        refreshUsage(now)
        if (now - trackedAt > 10_000L) {
            tracked = TrackedApps.load(this)
            trackedAt = now
        }
        val fg = if (Perms.usage(this)) reader.foreground() else null
        val visible = if (fg != null) reader.visiblePackages() else emptySet()
        gameUpkeep(fg, now)

        // Во время звонка оверлей не мешает — но только если на экране звонилка/разрешённое приложение.
        // Иначе любой VoIP-звонок (Discord, Telegram) был бы «ключом» от блокировки.
        val callSafe = isInCall() && (fg == null || fg in alwaysAllowed(now))
        var spec = if (callSafe) null else decide(fg, visible, now, dt)

        val stuck = sticky
        if (spec != null) {
            if (spec.reason in STICKY_REASONS) sticky = spec.reason
        } else if (stuck != null && !callSafe) {
            when {
                fg == packageName -> Unit // своё приложение: экран не показываем, но и не сбрасываем
                fg != null && !isNeutral(fg, now) -> sticky = null
                else -> {
                    spec = stickySpec(stuck, now)
                    if (spec == null) sticky = null
                }
            }
        }
        if (spec == null) {
            overlay.hide()
        } else {
            overlay.show(spec)
            maybeMinimize(spec, fg, now)
        }

        updateNotification(now)
        if (now - lastStatsSave > 60_000L) {
            lastStatsSave = now
            io.execute {
                try {
                    StatsStore.day(this, 0, bgReader)
                } catch (e: Exception) {
                }
            }
        }
    }

    private fun addScreenTime(dt: Long) {
        if (dt > 0) prefs.screenMsToday = prefs.screenMsToday + dt
    }

    private fun refreshUsage(now: Long) {
        if (usageLoading || now - usageAt < 15_000L || !Perms.usage(this)) return
        usageLoading = true
        io.execute {
            try {
                val u = bgReader.todayUsage()
                val t = System.currentTimeMillis()
                handler.post {
                    todayUsage = u
                    usageAt = t
                }
            } catch (e: Exception) {
            } finally {
                usageLoading = false
            }
        }
    }

    /** Время во всех отслеживаемых приложениях сегодня (с учётом текущей сессии). */
    private fun trackedToday(fg: String?, now: Long): Long {
        val pk = TrackedApps.allPackages(tracked)
        var sum = todayUsage.filterKeys { it in pk }.values.sum()
        if (fg != null && fg in pk && usageAt > 0) sum += (now - usageAt).coerceAtLeast(0L)
        return sum
    }

    private fun isInCall(): Boolean {
        val m = audio.mode
        return m == AudioManager.MODE_RINGTONE || m == AudioManager.MODE_IN_CALL ||
            m == AudioManager.MODE_IN_COMMUNICATION || m == 4 || m == 5 || m == 6
    }

    // =====================================================================
    //  правила
    // =====================================================================
    /**
     * @param fg активное приложение
     * @param visible все видимые окна (активное + «картинка в картинке», разделённый экран, плавающие окна)
     */
    private fun decide(fg: String?, visible: Set<String>, now: Long, dt: Long): OverlaySpec? {
        val own = fg == packageName
        if (chargeLockActive(now) && !own) return chargingSpec()
        if (fg == null) return null
        val others = visible - packageName
        if (others.isEmpty()) return null

        if (prefs.settingsLockEnabled && now > prefs.settingsUnlockUntil && others.any { it in SETTINGS_PACKAGES }) {
            return settingsSpec()
        }

        val allowed = alwaysAllowed(now)
        if (prefs.acEnabled && !prefs.unlimitedToday && others.any { it !in allowed }) {
            val total = (prefs.acTotalMin + prefs.bonusMinToday) * TimeUtil.MIN
            if (now < prefs.acBreakUntil) return acBreakSpec(now, total)
            if (prefs.acUsedMs >= total) return acDoneSpec()
            prefs.acUsedMs = prefs.acUsedMs + dt
            prefs.acSessionUsedMs = prefs.acSessionUsedMs + dt
            if (prefs.acUsedMs >= total) return acDoneSpec()
            if (prefs.acSessionUsedMs >= prefs.acSessionMin * TimeUtil.MIN) {
                prefs.acSessionUsedMs = 0L
                prefs.acBreakUntil = now + prefs.acBreakMin * TimeUtil.MIN
                return acBreakSpec(now, total)
            }
        }

        val group = others.firstNotNullOfOrNull { TrackedApps.groupOf(tracked, it) } ?: return null
        lastBlockedGroup = group

        if (nightActive(now)) return nightSpec()

        if (prefs.limitsEnabled && !prefs.unlimitedToday) {
            val limitMs = (prefs.dailyLimitMin + prefs.bonusMinToday) * TimeUtil.MIN
            val used = trackedToday(fg, now)
            if (now < prefs.breakUntil) return breakOrSoft(now)
            if (used >= limitMs) return limitOrSoft(now, used, group)
            prefs.usageSinceBreakMs = prefs.usageSinceBreakMs + dt
            if (prefs.breakEveryMin > 0 && prefs.breakDurationMin > 0 &&
                prefs.usageSinceBreakMs >= prefs.breakEveryMin * TimeUtil.MIN
            ) {
                prefs.usageSinceBreakMs = 0L
                prefs.breakUntil = now + prefs.breakDurationMin * TimeUtil.MIN
                prefs.softNotifiedAt = 0L
                return breakOrSoft(now)
            }
        }
        return null
    }

    private fun nightActive(now: Long): Boolean =
        prefs.nightEnabled && now > prefs.nightUnlockUntil &&
            TimeUtil.inInterval(TimeUtil.minuteOfDay(now), prefs.nightStartMin, prefs.nightEndMin)

    private fun chargeLockActive(now: Long): Boolean =
        prefs.chargeLockEnabled && plugged && batteryLevel in 0 until prefs.chargeThreshold &&
            !prefs.chargeUnlockUntilUnplug && now >= prefs.chargeUnlockUntil

    /** Приложения, которые работают всегда при контроле доступа. */
    private fun alwaysAllowed(now: Long): Set<String> {
        if (now - allowedAt < 60_000L && allowedCache.isNotEmpty()) return allowedCache
        val s = HashSet<String>(prefs.acAllowed)
        s.add(packageName)
        s.addAll(ALWAYS_ALLOWED)
        GameMode.dialerPackage(this)?.let { s.add(it) }
        try {
            Telephony.Sms.getDefaultSmsPackage(this)?.let { s.add(it) }
        } catch (e: Exception) {
        }
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val homes = HashSet<String>()
        try {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(home, 0).forEach { ri -> ri.activityInfo?.packageName?.let { homes.add(it) } }
        } catch (e: Exception) {
        }
        homes.add("com.android.systemui")
        homeCache = homes
        s.addAll(homes)
        try {
            android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.DEFAULT_INPUT_METHOD)
                ?.substringBefore('/')?.let { s.add(it) }
        } catch (e: Exception) {
        }
        allowedCache = s
        allowedAt = now
        return s
    }

    /** Рабочий стол, экран «Недавние», шторка — «нейтральная» территория для липкой блокировки. */
    private fun isNeutral(pkg: String, now: Long): Boolean {
        alwaysAllowed(now)
        return pkg in homeCache
    }

    /** Повторно строит экран липкой блокировки, если её условие ещё действует. */
    private fun stickySpec(reason: BlockReason, now: Long): OverlaySpec? = when (reason) {
        BlockReason.BREAK ->
            if (prefs.limitsEnabled && !prefs.unlimitedToday && prefs.strictMode && now < prefs.breakUntil) breakOrSoft(now) else null
        BlockReason.LIMIT -> {
            val g = lastBlockedGroup
            val limitMs = (prefs.dailyLimitMin + prefs.bonusMinToday) * TimeUtil.MIN
            val used = trackedToday(null, now)
            if (g != null && prefs.limitsEnabled && !prefs.unlimitedToday && prefs.strictMode && used >= limitMs) {
                limitOrSoft(now, used, g)
            } else null
        }
        BlockReason.NIGHT -> if (nightActive(now)) nightSpec() else null
        BlockReason.SETTINGS_LOCK ->
            if (prefs.settingsLockEnabled && now > prefs.settingsUnlockUntil) settingsSpec() else null
        BlockReason.ACCESS_BREAK -> {
            val total = (prefs.acTotalMin + prefs.bonusMinToday) * TimeUtil.MIN
            if (prefs.acEnabled && !prefs.unlimitedToday && now < prefs.acBreakUntil) acBreakSpec(now, total) else null
        }
        BlockReason.ACCESS_DONE -> {
            val total = (prefs.acTotalMin + prefs.bonusMinToday) * TimeUtil.MIN
            if (prefs.acEnabled && !prefs.unlimitedToday && prefs.acUsedMs >= total) acDoneSpec() else null
        }
        BlockReason.CHARGING -> null
    }

    /** Отправляет заблокированное приложение в фон: видео/игра останавливаются, а экран блокировки остаётся. */
    private fun maybeMinimize(spec: OverlaySpec, fg: String?, now: Long) {
        if (!prefs.autoMinimize || spec.reason !in STICKY_REASONS) return
        if (fg == null || fg == packageName || isNeutral(fg, now)) return
        if (now - lastHomeAt < 1_500L) return
        lastHomeAt = now
        goHome()
    }

    private fun goHome() {
        try {
            startActivity(
                Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (e: Exception) {
            // нет лаунчера или запуск запрещён
        }
    }

    override fun onHome() {
        sticky = null
        goHome()
        handler.post { overlay.hide() }
    }

    private fun bonusOptions(): List<OverlayOption> = listOf(
        OverlayOption("m10", getString(R.string.opt_plus_min, 10)),
        OverlayOption("m15", getString(R.string.opt_plus_min, 15)),
        OverlayOption("m30", getString(R.string.opt_plus_min, 30)),
        OverlayOption("unlimited", getString(R.string.opt_unlimited_today))
    )

    private fun breakOrSoft(now: Long): OverlaySpec? {
        val msg = prefs.breakMessage.ifBlank { getString(R.string.ov_break_msg_default) }
        if (!prefs.strictMode) {
            if (now - prefs.softNotifiedAt > 2 * TimeUtil.MIN) {
                prefs.softNotifiedAt = now
                Notifier.alert(this, Notifier.ID_BREAK, getString(R.string.ov_break_title), msg, Mood.BREAK)
            }
            return null
        }
        return OverlaySpec(
            reason = BlockReason.BREAK,
            title = getString(R.string.ov_break_title),
            message = msg,
            big = TimeUtil.countdown(prefs.breakUntil - now),
            progress = null,
            sub = getString(R.string.ov_break_sub),
            warning = null,
            mood = Mood.BREAK,
            pinLabel = getString(R.string.ov_btn_pin),
            showCode = true,
            showHome = true,
            optionsTitle = getString(R.string.ov_options_bonus),
            options = bonusOptions()
        )
    }

    private fun limitOrSoft(now: Long, used: Long, group: TrackedApp): OverlaySpec? {
        val msg = prefs.limitMessage.ifBlank { getString(R.string.ov_limit_msg_default) }
        if (!prefs.strictMode) {
            if (now - prefs.softNotifiedAt > 5 * TimeUtil.MIN) {
                prefs.softNotifiedAt = now
                Notifier.alert(this, Notifier.ID_LIMIT, getString(R.string.ov_limit_title), msg, Mood.STOP)
            }
            return null
        }
        return OverlaySpec(
            reason = BlockReason.LIMIT,
            title = getString(R.string.ov_limit_title),
            message = msg,
            big = null,
            progress = null,
            sub = getString(R.string.ov_limit_sub, group.name, TimeUtil.duration(this, used)),
            warning = null,
            mood = Mood.STOP,
            pinLabel = getString(R.string.ov_btn_pin),
            showCode = true,
            showHome = true,
            optionsTitle = getString(R.string.ov_options_bonus),
            options = bonusOptions()
        )
    }

    private fun nightSpec(): OverlaySpec = OverlaySpec(
        reason = BlockReason.NIGHT,
        title = getString(R.string.ov_night_title),
        message = getString(R.string.ov_night_msg, TimeUtil.hm(prefs.nightEndMin)),
        big = null,
        progress = null,
        sub = null,
        warning = null,
        mood = Mood.SLEEP,
        pinLabel = getString(R.string.ov_btn_pin),
        showCode = false,
        showHome = true,
        optionsTitle = getString(R.string.ov_options_night),
        options = listOf(
            OverlayOption("n15", getString(R.string.opt_for_min, 15)),
            OverlayOption("n30", getString(R.string.opt_for_min, 30)),
            OverlayOption("n60", getString(R.string.opt_for_min, 60)),
            OverlayOption("nall", getString(R.string.opt_until_morning))
        )
    )

    private fun settingsSpec(): OverlaySpec = OverlaySpec(
        reason = BlockReason.SETTINGS_LOCK,
        title = getString(R.string.ov_settings_title),
        message = getString(R.string.ov_settings_msg),
        big = null,
        progress = null,
        sub = null,
        warning = null,
        mood = Mood.ANGRY,
        pinLabel = getString(R.string.ov_btn_pin),
        showCode = false,
        showHome = true,
        optionsTitle = "",
        options = listOf(OverlayOption("unlock", getString(R.string.ov_btn_pin)))
    )

    private fun acBreakSpec(now: Long, total: Long): OverlaySpec = OverlaySpec(
        reason = BlockReason.ACCESS_BREAK,
        title = getString(R.string.ov_ac_break_title),
        message = getString(R.string.ov_ac_break_msg),
        big = TimeUtil.countdown(prefs.acBreakUntil - now),
        progress = null,
        sub = getString(R.string.ov_ac_left, TimeUtil.duration(this, total - prefs.acUsedMs)),
        warning = null,
        mood = Mood.BREAK,
        pinLabel = getString(R.string.ov_btn_pin),
        showCode = true,
        showHome = true,
        optionsTitle = getString(R.string.ov_options_bonus),
        options = bonusOptions()
    )

    private fun acDoneSpec(): OverlaySpec = OverlaySpec(
        reason = BlockReason.ACCESS_DONE,
        title = getString(R.string.ov_ac_done_title),
        message = getString(R.string.ov_ac_done_msg),
        big = null,
        progress = null,
        sub = null,
        warning = null,
        mood = Mood.STOP,
        pinLabel = getString(R.string.ov_btn_pin),
        showCode = true,
        showHome = true,
        optionsTitle = getString(R.string.ov_options_bonus),
        options = bonusOptions()
    )

    private fun chargingSpec(): OverlaySpec {
        val threshold = prefs.chargeThreshold
        val hot = temperature > OVERHEAT_C
        val msg = prefs.chargeMessage.ifBlank { getString(R.string.ov_charge_msg_default, threshold) }
        return OverlaySpec(
            reason = BlockReason.CHARGING,
            title = getString(R.string.ov_charge_title),
            message = msg,
            big = "$batteryLevel%",
            progress = if (threshold > 0) batteryLevel * 100 / threshold else 0,
            sub = getString(R.string.ov_charge_sub, threshold, String.format(Locale.getDefault(), "%.1f", temperature)),
            warning = if (hot) getString(R.string.ov_overheat) else null,
            mood = if (hot) Mood.HOT else Mood.CHARGING,
            pinLabel = getString(R.string.ov_btn_emergency),
            showCode = false,
            showHome = false,
            optionsTitle = getString(R.string.ov_options_charge),
            options = listOf(
                OverlayOption("c5", getString(R.string.opt_for_min, 5)),
                OverlayOption("c15", getString(R.string.opt_for_min, 15)),
                OverlayOption("cunplug", getString(R.string.opt_until_unplug))
            )
        )
    }

    // ---------- обработка выбора после PIN ----------
    override fun onOption(reason: BlockReason, optionId: String) {
        val now = System.currentTimeMillis()
        sticky = null
        val source = getString(R.string.source_pin)
        when (optionId) {
            "m10" -> Bonus.grantMinutes(this, 10, source)
            "m15" -> Bonus.grantMinutes(this, 15, source)
            "m30" -> Bonus.grantMinutes(this, 30, source)
            "unlimited" -> Bonus.grantUnlimited(this, source)
            "n15", "n30", "n60", "nall" -> {
                prefs.nightUnlockUntil = when (optionId) {
                    "n15" -> now + 15 * TimeUtil.MIN
                    "n30" -> now + 30 * TimeUtil.MIN
                    "n60" -> now + 60 * TimeUtil.MIN
                    else -> TimeUtil.nextOccurrence(prefs.nightEndMin, now)
                }
                EventLog.add(this, LogType.NIGHT_UNLOCK, getString(R.string.log_night_unlock, TimeUtil.clock(prefs.nightUnlockUntil)))
            }
            "c5", "c15" -> {
                val m = if (optionId == "c5") 5 else 15
                prefs.chargeUnlockUntil = now + m * TimeUtil.MIN
                EventLog.add(this, LogType.EMERGENCY_UNLOCK, getString(R.string.log_emergency_min, m, batteryLevel))
            }
            "cunplug" -> {
                prefs.chargeUnlockUntilUnplug = true
                EventLog.add(this, LogType.EMERGENCY_UNLOCK, getString(R.string.log_emergency_unplug, batteryLevel))
            }
            "unlock" -> {
                prefs.settingsUnlockUntil = now + 5 * TimeUtil.MIN
                EventLog.add(this, LogType.SETTINGS_UNLOCK, getString(R.string.log_settings_unlock))
            }
        }
        handler.post { overlay.hide() }
    }

    override fun onCode(code: String): String? =
        when (val r = Bonus.redeem(this, code)) {
            is Bonus.RedeemResult.Ok -> {
                sticky = null
                handler.post { overlay.hide() }
                null
            }
            Bonus.RedeemResult.NotPaired -> getString(R.string.code_not_paired)
            Bonus.RedeemResult.Used -> getString(R.string.code_used)
            is Bonus.RedeemResult.Wrong -> getString(R.string.code_wrong_left, r.attemptsLeft)
            is Bonus.RedeemResult.Locked -> getString(R.string.pin_locked_sec, r.seconds)
        }

    // =====================================================================
    //  батарея
    // =====================================================================
    private fun readBattery(i: Intent) {
        val level = i.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = i.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
        if (level >= 0 && scale > 0) batteryLevel = level * 100 / scale
        plugged = i.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) != 0
        temperature = i.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0
    }

    private fun handleCharging(now: Long) {
        if (batteryLevel < 0) return
        val threshold = prefs.chargeThreshold
        if (plugged && !prefs.wasPlugged) {
            prefs.wasPlugged = true
            prefs.chargeSession = batteryLevel < threshold
            prefs.chargeUnlockUntilUnplug = false
            Notifier.cancel(this, Notifier.ID_LOW_BATTERY)
        } else if (!plugged && prefs.wasPlugged) {
            prefs.wasPlugged = false
            if (prefs.chargeLockEnabled && prefs.chargeSession && batteryLevel < threshold) {
                EventLog.add(
                    this, LogType.CHARGE_INTERRUPTED,
                    getString(R.string.log_charge_interrupted, batteryLevel, TimeUtil.clock(now))
                )
            }
            prefs.chargeSession = false
            prefs.chargeUnlockUntilUnplug = false
            prefs.chargeUnlockUntil = 0L
            if (overlay.reason == BlockReason.CHARGING) overlay.hide()
        }
        if (plugged && batteryLevel < threshold && !prefs.chargeSession) prefs.chargeSession = true
        if (plugged && batteryLevel >= threshold && prefs.chargeSession) {
            prefs.chargeSession = false
            if (overlay.reason == BlockReason.CHARGING) overlay.hide()
            if (prefs.chargeLockEnabled) {
                Notifier.alert(
                    this, Notifier.ID_CHARGED, getString(R.string.charged_title),
                    getString(R.string.charged_text, threshold), Mood.CHARGED, Notifier.CH_EVENTS
                )
                Notifier.playChime(this)
                EventLog.add(this, LogType.CHARGED, getString(R.string.log_charged, threshold, TimeUtil.clock(now)))
            }
        }
        // напоминание о низком заряде (каждые 2 минуты)
        if (prefs.lowBatteryEnabled && !plugged && batteryLevel <= prefs.lowBatteryLevel &&
            now - prefs.lastLowBatteryNotify >= LOW_BATTERY_INTERVAL
        ) {
            prefs.lastLowBatteryNotify = now
            Notifier.alert(
                this, Notifier.ID_LOW_BATTERY, getString(R.string.low_battery_title),
                getString(R.string.low_battery_text, batteryLevel), Mood.LOW
            )
        }
    }

    // =====================================================================
    //  игровой режим
    // =====================================================================
    private fun gameUpkeep(fg: String?, now: Long) {
        if (!prefs.gameActive) return
        val game = prefs.gamePackage
        if (game.isNotEmpty() && fg == game) {
            prefs.gameLastSeen = now
            if (now - prefs.gameLastKill > 120_000L) {
                prefs.gameLastKill = now
                io.execute {
                    try {
                        GameMode.killBackground(this, game)
                    } catch (e: Exception) {
                    }
                }
            }
        }
        if (game.isNotEmpty() && now - prefs.gameLastSeen > 5 * TimeUtil.MIN) {
            GameMode.disable(this)
        }
    }

    // =====================================================================
    //  постоянное уведомление
    // =====================================================================
    private fun updateNotification(now: Long) {
        if (now - lastNotifAt < 30_000L) return
        lastNotifAt = now
        val text = getString(
            R.string.service_text,
            TimeUtil.duration(this, prefs.screenMsToday),
            TimeUtil.duration(this, trackedToday(null, now))
        )
        if (text != lastNotifText) {
            lastNotifText = text
            Notifier.updateService(this, text)
        }
    }

    companion object {
        private const val TICK_MS = 1_000L
        private const val TICK_FAST_MS = 500L
        private const val TICK_OFF_MS = 30_000L
        private const val LOW_BATTERY_INTERVAL = 2 * 60_000L
        const val OVERHEAT_C = 42.0
        const val ACTION_WATCHDOG = "com.khranitoniks.guard.WATCHDOG"

        val SETTINGS_PACKAGES = setOf(
            "com.android.settings",
            "com.android.settings.intelligence",
            "com.google.android.packageinstaller",
            "com.android.packageinstaller",
            "com.samsung.android.packageinstaller",
            "com.miui.securitycenter",
            // «оптимизаторы» и менеджеры автозапуска производителей — через них можно усыпить защиту
            "com.samsung.android.lool",
            "com.samsung.android.sm",
            "com.samsung.android.sm_cn",
            "com.huawei.systemmanager",
            "com.hihonor.systemmanager",
            "com.transsion.phonemaster",
            "com.coloros.safecenter",
            "com.oplus.safecenter",
            "com.coloros.phonemanager",
            "com.vivo.permissionmanager",
            "com.iqoo.secure",
            "com.oneplus.security",
            "com.google.android.apps.wellbeing"
        )

        /** Причины, при которых блокировка «липкая» и приложение сворачивается. */
        private val STICKY_REASONS = setOf(
            BlockReason.BREAK, BlockReason.LIMIT, BlockReason.NIGHT,
            BlockReason.SETTINGS_LOCK, BlockReason.ACCESS_BREAK, BlockReason.ACCESS_DONE
        )

        val ALWAYS_ALLOWED = setOf(
            "com.android.systemui", "com.android.phone", "com.android.server.telecom",
            "com.android.incallui", "com.google.android.dialer", "com.samsung.android.incallui",
            "com.android.dialer", "com.samsung.android.dialer", "com.android.emergency",
            "com.google.android.apps.safetyhub", "com.android.contacts", "com.android.mms",
            "com.google.android.apps.messaging", "com.samsung.android.messaging",
            "com.android.permissioncontroller", "com.google.android.permissioncontroller"
        )

        fun start(context: Context) {
            if (!Prefs.get(context).onboardingDone) return
            try {
                context.startForegroundService(Intent(context, GuardService::class.java))
            } catch (e: Exception) {
                // запуск в фоне запрещён — сработает сторож
            }
        }

        private fun watchdogIntent(context: Context, code: Int): PendingIntent =
            PendingIntent.getBroadcast(
                context, code,
                Intent(context, StartReceiver::class.java).setAction(ACTION_WATCHDOG),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

        fun scheduleWatchdog(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.setInexactRepeating(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + AlarmManager.INTERVAL_FIFTEEN_MINUTES,
                AlarmManager.INTERVAL_FIFTEEN_MINUTES,
                watchdogIntent(context, 1)
            )
        }

        fun scheduleRestart(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, SystemClock.elapsedRealtime() + 3_000L, watchdogIntent(context, 2))
        }
    }
}
