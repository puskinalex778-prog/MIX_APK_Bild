package com.khranitoniks.guard.core

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager

/** Данные для главного экрана (собираются в фоне). */
data class AppStat(val app: TrackedApp, val installedPkg: String?, val ms: Long)

data class DashboardData(
    val screenMs: Long,
    val trackedMs: Long,
    val limitMs: Long,
    val limitsEnabled: Boolean,
    val unlimited: Boolean,
    val bonusMin: Int,
    val apps: List<AppStat>,
    val breakLeftMs: Long,
    val untilBreakMs: Long,
    val batteryLevel: Int,
    val plugged: Boolean,
    val temperature: Double,
    val chargeLockEnabled: Boolean,
    val chargeThreshold: Int,
    val nightEnabled: Boolean,
    val nightActive: Boolean,
    val nightStart: Int,
    val nightEnd: Int,
    val acEnabled: Boolean,
    val acUsedMs: Long,
    val acTotalMs: Long,
    val acBreakLeftMs: Long,
    val acSessionLeftMs: Long,
    val permsOk: Boolean,
    val gameActive: Boolean,
    val paired: Boolean
)

object Dashboard {

    fun load(context: Context): DashboardData {
        Day.ensure(context)
        val p = Prefs.get(context)
        val now = System.currentTimeMillis()
        val reader = UsageReader(context)
        val usageOk = Perms.usage(context)
        val usage = if (usageOk) reader.todayUsage() else emptyMap()
        val tracked = TrackedApps.load(context)
        val stats = tracked.map { a ->
            AppStat(a, TrackedApps.installedPackage(context, a), a.packages.sumOf { usage[it] ?: 0L })
        }
        val trackedMs = stats.sumOf { it.ms }
        val sysScreen = if (usageOk) reader.screenTime(TimeUtil.startOfDay(), now) else -1L
        val screenMs = maxOf(p.screenMsToday, sysScreen)

        val battery = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        var level = -1
        var plugged = false
        var temp = 0.0
        if (battery != null) {
            val l = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val s = battery.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
            if (l >= 0 && s > 0) level = l * 100 / s
            plugged = battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) != 0
            temp = battery.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0
        }
        val nightActive = p.nightEnabled && now > p.nightUnlockUntil &&
            TimeUtil.inInterval(TimeUtil.minuteOfDay(now), p.nightStartMin, p.nightEndMin)
        val acTotal = (p.acTotalMin + p.bonusMinToday) * TimeUtil.MIN
        return DashboardData(
            screenMs = screenMs,
            trackedMs = trackedMs,
            limitMs = (p.dailyLimitMin + p.bonusMinToday) * TimeUtil.MIN,
            limitsEnabled = p.limitsEnabled,
            unlimited = p.unlimitedToday,
            bonusMin = p.bonusMinToday,
            apps = stats,
            breakLeftMs = (p.breakUntil - now).coerceAtLeast(0L),
            untilBreakMs = (p.breakEveryMin * TimeUtil.MIN - p.usageSinceBreakMs).coerceAtLeast(0L),
            batteryLevel = level,
            plugged = plugged,
            temperature = temp,
            chargeLockEnabled = p.chargeLockEnabled,
            chargeThreshold = p.chargeThreshold,
            nightEnabled = p.nightEnabled,
            nightActive = nightActive,
            nightStart = p.nightStartMin,
            nightEnd = p.nightEndMin,
            acEnabled = p.acEnabled,
            acUsedMs = p.acUsedMs,
            acTotalMs = acTotal,
            acBreakLeftMs = (p.acBreakUntil - now).coerceAtLeast(0L),
            acSessionLeftMs = (p.acSessionMin * TimeUtil.MIN - p.acSessionUsedMs).coerceAtLeast(0L),
            permsOk = Perms.allRequired(context),
            gameActive = p.gameActive,
            paired = p.pairingKey.isNotEmpty()
        )
    }
}

/** Список установленных приложений с экраном запуска. */
object InstalledApps {

    data class Entry(val pkg: String, val label: String)

    fun launchable(context: Context): List<Entry> {
        val pm = context.packageManager
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return try {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(i, 0)
                .mapNotNull { ri ->
                    val pkg = ri.activityInfo?.packageName ?: return@mapNotNull null
                    if (pkg == context.packageName) null else Entry(pkg, ri.loadLabel(pm).toString())
                }
                .distinctBy { it.pkg }
                .sortedBy { it.label.lowercase() }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
