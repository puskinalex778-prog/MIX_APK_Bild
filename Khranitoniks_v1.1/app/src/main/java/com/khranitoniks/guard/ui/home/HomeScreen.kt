@file:OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)

package com.khranitoniks.guard.ui.home

import android.widget.Toast
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khranitoniks.guard.R
import com.khranitoniks.guard.core.AppStat
import com.khranitoniks.guard.core.CharacterArt
import com.khranitoniks.guard.core.Dashboard
import com.khranitoniks.guard.core.DashboardData
import com.khranitoniks.guard.core.InstalledApps
import com.khranitoniks.guard.core.Mood
import com.khranitoniks.guard.core.Prefs
import com.khranitoniks.guard.core.TimeUtil
import com.khranitoniks.guard.core.TrackedApp
import com.khranitoniks.guard.core.TrackedApps
import com.khranitoniks.guard.ui.common.AppIcon
import com.khranitoniks.guard.ui.common.CodeDialog
import com.khranitoniks.guard.ui.common.PinDialog
import com.khranitoniks.guard.ui.common.fmt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

@Composable
fun HomeScreen(onOpenPermissions: () -> Unit, onOpenTools: () -> Unit) {
    val ctx = LocalContext.current
    var data by remember { mutableStateOf<DashboardData?>(null) }
    var reload by remember { mutableStateOf(0) }
    var showCode by remember { mutableStateOf(false) }
    var showAdd by remember { mutableStateOf(false) }
    var toRemove by remember { mutableStateOf<TrackedApp?>(null) }

    LaunchedEffect(reload) {
        while (true) {
            data = withContext(Dispatchers.IO) { Dashboard.load(ctx) }
            delay(3000)
        }
    }

    val d = data
    if (d == null) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        return
    }

    LazyColumn(
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        if (!d.permsOk) {
            item { PermissionBanner(onOpenPermissions) }
        }
        item { ScreenTimeCard(d) }
        item { StatusCard(d) }
        if (d.acEnabled) item { AccessCard(d) }
        item {
            Text(
                stringResource(R.string.home_apps_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
        items(d.apps.chunked(2)) { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                row.forEach { s ->
                    AppCard(
                        stat = s,
                        modifier = Modifier.weight(1f),
                        onOpen = {
                            if (!TrackedApps.launch(ctx, s.app)) {
                                Toast.makeText(ctx, ctx.getString(R.string.not_installed), Toast.LENGTH_SHORT).show()
                            }
                        },
                        onLongPress = { if (!s.app.builtIn) toRemove = s.app }
                    )
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
        item {
            OutlinedButton(onClick = { showAdd = true }, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.Add, contentDescription = null)
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.home_add_app))
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = { showCode = true }, modifier = Modifier.weight(1f).height(56.dp)) {
                    Icon(Icons.Filled.Star, contentDescription = null)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.home_enter_code), maxLines = 2)
                }
                OutlinedButton(onClick = onOpenTools, modifier = Modifier.weight(1f).height(56.dp)) {
                    Icon(Icons.Filled.Build, contentDescription = null)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.home_tools), maxLines = 2)
                }
            }
        }
        item { Spacer(Modifier.height(8.dp)) }
    }

    if (showCode) CodeDialog(onDismiss = {
        showCode = false
        reload++
    })
    if (showAdd) AddAppDialog(onDismiss = {
        showAdd = false
        reload++
    })
    val rm = toRemove
    if (rm != null) {
        PinDialog(
            title = stringResource(R.string.home_remove_app, rm.name),
            onDismiss = { toRemove = null },
            onSuccess = {
                TrackedApps.remove(ctx, rm.id)
                toRemove = null
                reload++
            }
        )
    }
}

@Composable
private fun PermissionBanner(onClick: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
        shape = RoundedCornerShape(20.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Warning, contentDescription = null, tint = MaterialTheme.colorScheme.onErrorContainer)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    stringResource(R.string.banner_perms_title),
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
                Text(
                    stringResource(R.string.banner_perms_text),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
            Spacer(Modifier.width(8.dp))
            Button(onClick = onClick) { Text(stringResource(R.string.banner_perms_btn)) }
        }
    }
}

@Composable
private fun ScreenTimeCard(d: DashboardData) {
    val ctx = LocalContext.current
    val kind = Prefs.get(ctx).characterKind
    val progress = if (d.limitMs > 0) (d.trackedMs.toFloat() / d.limitMs).coerceIn(0f, 1f) else 0f
    val mood = when {
        d.nightActive -> Mood.SLEEP
        d.breakLeftMs > 0 -> Mood.BREAK
        d.limitsEnabled && !d.unlimited && d.trackedMs >= d.limitMs -> Mood.STOP
        d.gameActive -> Mood.GAMER
        else -> Mood.HAPPY
    }
    Card(
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(stringResource(R.string.home_screen_today), style = MaterialTheme.typography.titleSmall)
                Text(
                    fmt(ctx, d.screenMs),
                    fontSize = 34.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Spacer(Modifier.height(10.dp))
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(10.dp)
                        .clip(RoundedCornerShape(5.dp)),
                    color = if (progress >= 1f) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary,
                    trackColor = MaterialTheme.colorScheme.surface
                )
                Spacer(Modifier.height(6.dp))
                val limitText = when {
                    !d.limitsEnabled -> stringResource(R.string.home_limit_off, fmt(ctx, d.trackedMs))
                    d.unlimited -> stringResource(R.string.home_limit_unlimited, fmt(ctx, d.trackedMs))
                    else -> stringResource(R.string.home_limit_progress, fmt(ctx, d.trackedMs), fmt(ctx, d.limitMs))
                }
                Text(limitText, style = MaterialTheme.typography.bodySmall)
                if (d.bonusMin > 0) {
                    Text(
                        stringResource(R.string.home_bonus, d.bonusMin),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.secondary
                    )
                }
            }
            Image(
                painter = painterResource(CharacterArt.res(kind, mood)),
                contentDescription = null,
                modifier = Modifier.size(104.dp)
            )
        }
    }
}

@Composable
private fun StatusCard(d: DashboardData) {
    val ctx = LocalContext.current
    Card(shape = RoundedCornerShape(20.dp), modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            val breakText = when {
                !d.limitsEnabled || d.unlimited -> stringResource(R.string.status_breaks_off)
                d.breakLeftMs > 0 -> stringResource(R.string.status_break_now, TimeUtil.countdown(d.breakLeftMs))
                else -> stringResource(R.string.status_until_break, fmt(ctx, d.untilBreakMs))
            }
            StatusLine("⏱", breakText)
            HorizontalDivider()
            val battery = when {
                d.batteryLevel < 0 -> stringResource(R.string.status_battery_unknown)
                d.plugged && d.chargeLockEnabled && d.batteryLevel < d.chargeThreshold ->
                    stringResource(R.string.status_charging_lock, d.batteryLevel, d.chargeThreshold)
                d.plugged -> stringResource(R.string.status_charging, d.batteryLevel)
                else -> stringResource(R.string.status_battery, d.batteryLevel)
            }
            StatusLine("🔋", battery + " · " + String.format("%.1f °C", d.temperature))
            HorizontalDivider()
            val night = when {
                !d.nightEnabled -> stringResource(R.string.status_night_off)
                d.nightActive -> stringResource(R.string.status_night_active, TimeUtil.hm(d.nightEnd))
                else -> stringResource(R.string.status_night_planned, TimeUtil.hm(d.nightStart), TimeUtil.hm(d.nightEnd))
            }
            StatusLine("🌙", night)
            if (d.gameActive) {
                HorizontalDivider()
                StatusLine("🎮", stringResource(R.string.status_game_on))
            }
        }
    }
}

@Composable
private fun StatusLine(emoji: String, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(emoji, fontSize = 20.sp)
        Spacer(Modifier.width(10.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun AccessCard(d: DashboardData) {
    val ctx = LocalContext.current
    val progress = if (d.acTotalMs > 0) (d.acUsedMs.toFloat() / d.acTotalMs).coerceIn(0f, 1f) else 0f
    Card(
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(stringResource(R.string.ac_card_title), fontWeight = FontWeight.Bold)
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp))
            )
            Text(stringResource(R.string.ac_card_used, fmt(ctx, d.acUsedMs), fmt(ctx, d.acTotalMs)), style = MaterialTheme.typography.bodySmall)
            val state = when {
                d.unlimited -> stringResource(R.string.home_limit_unlimited, fmt(ctx, d.acUsedMs))
                d.acUsedMs >= d.acTotalMs -> stringResource(R.string.ac_state_done)
                d.acBreakLeftMs > 0 -> stringResource(R.string.ac_state_break, TimeUtil.countdown(d.acBreakLeftMs))
                else -> stringResource(R.string.ac_state_session, fmt(ctx, d.acSessionLeftMs))
            }
            Text(state, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun AppCard(stat: AppStat, modifier: Modifier, onOpen: () -> Unit, onLongPress: () -> Unit) {
    val ctx = LocalContext.current
    val color = Color(stat.app.color)
    Card(
        shape = RoundedCornerShape(22.dp),
        modifier = modifier.combinedClickable(onClick = onOpen, onLongClick = onLongPress),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(64.dp)
                    .background(color),
                contentAlignment = Alignment.CenterStart
            ) {
                Row(Modifier.padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    AppIcon(stat.installedPkg, stat.app.name, 40.dp, color)
                    Spacer(Modifier.width(10.dp))
                    Text(
                        stat.app.name,
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(stringResource(R.string.home_app_today), style = MaterialTheme.typography.labelMedium)
                Text(fmt(ctx, stat.ms), fontSize = 20.sp, fontWeight = FontWeight.Bold)
                if (stat.installedPkg != null) {
                    Button(onClick = onOpen, modifier = Modifier.fillMaxWidth().heightIn(min = 40.dp)) {
                        Icon(Icons.Filled.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(4.dp))
                        Text(stringResource(R.string.open))
                    }
                } else {
                    Text(
                        stringResource(R.string.not_installed),
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.heightIn(min = 40.dp).padding(top = 10.dp)
                    )
                }
            }
        }
    }
}

/** Добавление приложения: популярные + любое установленное. */
@Composable
private fun AddAppDialog(onDismiss: () -> Unit) {
    val ctx = LocalContext.current
    var apps by remember { mutableStateOf<List<InstalledApps.Entry>?>(null) }
    var query by remember { mutableStateOf("") }
    val current = remember { TrackedApps.allPackages(TrackedApps.load(ctx)) }
    LaunchedEffect(Unit) { apps = withContext(Dispatchers.IO) { InstalledApps.launchable(ctx) } }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.home_add_app)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    label = { Text(stringResource(R.string.search)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                val list = apps
                LazyColumn(Modifier.heightIn(max = 400.dp)) {
                    val sugg = TrackedApps.SUGGESTED.filter { s ->
                        s.packages.none { it in current } && (query.isBlank() || s.name.contains(query, true))
                    }
                    if (sugg.isNotEmpty()) {
                        item {
                            Text(stringResource(R.string.add_popular), style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(vertical = 6.dp))
                        }
                        items(sugg, key = { "s_" + it.id }) { s ->
                            val pkg = TrackedApps.installedPackage(ctx, s)
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        TrackedApps.add(ctx, s)
                                        onDismiss()
                                    }
                                    .padding(vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                AppIcon(pkg, s.name, 32.dp, Color(s.color))
                                Spacer(Modifier.width(10.dp))
                                Column {
                                    Text(s.name)
                                    Text(
                                        stringResource(if (pkg != null) R.string.installed else R.string.not_installed),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                    item {
                        Text(stringResource(R.string.add_installed), style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(vertical = 6.dp))
                    }
                    if (list == null) {
                        item { CircularProgressIndicator(Modifier.padding(16.dp)) }
                    } else {
                        val filtered = list.filter {
                            it.pkg !in current && (query.isBlank() || it.label.contains(query, true) || it.pkg.contains(query, true))
                        }
                        items(filtered, key = { "i_" + it.pkg }) { e ->
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        TrackedApps.addPackage(ctx, e.pkg, e.label)
                                        onDismiss()
                                    }
                                    .padding(vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                AppIcon(e.pkg, e.label, 32.dp)
                                Spacer(Modifier.width(10.dp))
                                Text(e.label, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.close)) } }
    )
}
