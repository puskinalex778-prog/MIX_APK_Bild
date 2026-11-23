@file:OptIn(ExperimentalMaterial3Api::class)

package com.khranitoniks.box

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { BoxTheme { BoxRoot() } }
    }
}

private val Teal = Color(0xFF00897B)

@Composable
private fun BoxTheme(content: @Composable () -> Unit) {
    val light = lightColorScheme(
        primary = Teal,
        onPrimary = Color.White,
        primaryContainer = Color(0xFFB2DFDB),
        onPrimaryContainer = Color(0xFF00201C),
        secondary = Color(0xFFFFB300),
        secondaryContainer = Color(0xFFFFE9B3),
        background = Color(0xFFF4F8F7),
        surface = Color.White
    )
    val dark = darkColorScheme(
        primary = Color(0xFF4DB6AC),
        onPrimary = Color(0xFF00382F),
        primaryContainer = Color(0xFF00504A),
        onPrimaryContainer = Color(0xFFB2DFDB),
        secondary = Color(0xFFFFCA28),
        background = Color(0xFF101413),
        surface = Color(0xFF1A1F1E)
    )
    MaterialTheme(colorScheme = if (isSystemInDarkTheme()) dark else light, content = content)
}

fun optionLabel(ctx: Context, minutes: Int): String =
    if (minutes < 0) ctx.getString(R.string.opt_unlimited) else ctx.getString(R.string.opt_minutes, minutes)

@Composable
private fun BoxRoot() {
    val ctx = LocalContext.current
    val store = remember { BoxStore(ctx) }
    var unlocked by remember { mutableStateOf(!store.hasPin) }
    if (!unlocked) {
        LockScreen(store) { unlocked = true }
    } else {
        MainScreen(store)
    }
}

@Composable
private fun LockScreen(store: BoxStore, onOk: () -> Unit) {
    val ctx = LocalContext.current
    var pin by remember { mutableStateOf("") }
    var err by remember { mutableStateOf("") }
    Column(
        Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Image(painterResource(R.drawable.ic_launcher), contentDescription = null, modifier = Modifier.size(120.dp))
        Spacer(Modifier.height(16.dp))
        Text(stringResource(R.string.lock_title), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(16.dp))
        OutlinedTextField(
            value = pin,
            onValueChange = { pin = it.filter { c -> c in '0'..'9' }.take(4) },
            label = { Text(stringResource(R.string.pin_label)) },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword)
        )
        if (err.isNotEmpty()) Text(err, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(top = 8.dp))
        Spacer(Modifier.height(16.dp))
        Button(enabled = pin.length == 4, onClick = {
            val locked = store.lockedSeconds()
            if (locked > 0) {
                err = ctx.getString(R.string.pin_locked, locked)
            } else if (store.checkPin(pin)) {
                onOk()
            } else {
                val l = store.lockedSeconds()
                err = if (l > 0) ctx.getString(R.string.pin_locked, l) else ctx.getString(R.string.pin_wrong)
            }
            pin = ""
        }) { Text(stringResource(R.string.unlock)) }
    }
}

@Composable
private fun MainScreen(store: BoxStore) {
    val ctx = LocalContext.current
    var children by remember { mutableStateOf(store.children()) }
    var history by remember { mutableStateOf(store.history()) }
    var selected by remember { mutableStateOf<Child?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var showSettings by remember { mutableStateOf(false) }

    fun refresh() {
        children = store.children()
        history = store.history()
    }

    BackHandler(enabled = selected != null || showSettings) {
        selected = null
        showSettings = false
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(selected?.name ?: if (showSettings) stringResource(R.string.settings) else stringResource(R.string.app_name)) },
                navigationIcon = {
                    if (selected != null || showSettings) {
                        IconButton(onClick = {
                            selected = null
                            showSettings = false
                        }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back)) }
                    }
                },
                actions = {
                    if (selected == null && !showSettings) {
                        IconButton(onClick = { showSettings = true }) {
                            Icon(Icons.Filled.Settings, contentDescription = stringResource(R.string.settings))
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                    navigationIconContentColor = MaterialTheme.colorScheme.onPrimary,
                    actionIconContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        }
    ) { padding ->
        Box(
            Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            val sel = selected
            when {
                showSettings -> SettingsScreen(store, onChanged = { refresh() })
                sel != null -> ChildScreen(store, sel, onChanged = {
                    refresh()
                    selected = store.children().firstOrNull { it.id == sel.id }
                })
                else -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    item { IntroCard(children.isEmpty()) }
                    items(children, key = { it.id }) { c ->
                        Card(
                            shape = RoundedCornerShape(20.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selected = c },
                            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                        ) {
                            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    Modifier
                                        .size(48.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(c.name.take(1).uppercase(), fontSize = 26.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                                }
                                Spacer(Modifier.width(12.dp))
                                Column(Modifier.weight(1f)) {
                                    Text(c.name, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                                    Text(stringResource(R.string.child_tap_hint), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                    item {
                        Button(onClick = { showAdd = true }, modifier = Modifier.fillMaxWidth().height(52.dp)) {
                            Icon(Icons.Filled.Add, contentDescription = null)
                            Spacer(Modifier.width(8.dp))
                            Text(stringResource(R.string.add_child))
                        }
                    }
                    if (history.isNotEmpty()) {
                        item {
                            Column {
                                Text(stringResource(R.string.history), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                                Text(stringResource(R.string.history_tap_copy), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                        items(history.take(20)) { h ->
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .clickable { Clip.copy(ctx, CodeCrypto.prettyCode(h.code), R.string.copied) }
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(Modifier.weight(1f)) {
                                    Text("${h.childName}: ${optionLabel(ctx, h.minutes)}", fontWeight = FontWeight.SemiBold)
                                    Text(
                                        SimpleDateFormat("dd.MM HH:mm", Locale.getDefault()).format(Date(h.time)),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                Text(CodeCrypto.prettyCode(h.code), fontFamily = FontFamily.Monospace)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAdd) {
        AddChildDialog(store, onDismiss = { showAdd = false }, onAdded = {
            showAdd = false
            refresh()
        })
    }
}

@Composable
private fun IntroCard(empty: Boolean) {
    Card(
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Image(painterResource(R.drawable.char_hroni_happy), contentDescription = null, modifier = Modifier.size(96.dp))
            Spacer(Modifier.width(12.dp))
            Column {
                Text(stringResource(R.string.intro_title), fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Text(
                    stringResource(if (empty) R.string.intro_text_empty else R.string.intro_text),
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
private fun ChildScreen(store: BoxStore, child: Child, onChanged: () -> Unit) {
    val ctx = LocalContext.current
    var code by remember(child.id) { mutableStateOf("") }
    var codeMinutes by remember(child.id) { mutableStateOf(0) }
    var codeTime by remember(child.id) { mutableStateOf(0L) }
    var showKey by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var rename by remember { mutableStateOf(false) }

    LazyColumn(
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text(stringResource(R.string.choose_time), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }
        items(CodeCrypto.OPTIONS.indices.toList().chunked(2)) { pair ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                pair.forEach { idx ->
                    val m = CodeCrypto.OPTIONS[idx]
                    OutlinedButton(
                        onClick = {
                            val c = store.issue(child, idx)
                            if (c != null) {
                                code = c
                                codeMinutes = m
                                codeTime = System.currentTimeMillis()
                                onChanged()
                            }
                        },
                        modifier = Modifier
                            .weight(1f)
                            .height(56.dp)
                    ) { Text(optionLabel(ctx, m), fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center) }
                }
                if (pair.size == 1) Spacer(Modifier.weight(1f))
            }
        }
        if (code.isNotEmpty()) {
            item {
                Card(
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(Modifier.padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(stringResource(R.string.code_for, child.name, optionLabel(ctx, codeMinutes)), textAlign = TextAlign.Center)
                        Text(
                            CodeCrypto.prettyCode(code),
                            fontSize = 38.sp,
                            fontWeight = FontWeight.ExtraBold,
                            fontFamily = FontFamily.Monospace,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(stringResource(R.string.code_valid), style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center)
                        Text(
                            stringResource(
                                R.string.code_expires,
                                SimpleDateFormat("dd.MM HH:mm", Locale.getDefault()).format(Date(codeTime + CodeCrypto.VALID_HOURS * 3_600_000L))
                            ),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        val msg = ctx.getString(R.string.code_message, optionLabel(ctx, codeMinutes), CodeCrypto.prettyCode(code))
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(onClick = {
                                Clip.copy(ctx, CodeCrypto.prettyCode(code), R.string.copied)
                            }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.copy)) }
                            OutlinedButton(onClick = {
                                Clip.copy(ctx, msg, R.string.message_copied)
                            }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.copy_message), textAlign = TextAlign.Center) }
                        }
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedButton(onClick = {
                                val i = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")).putExtra("sms_body", msg)
                                try {
                                    ctx.startActivity(i)
                                } catch (e: Exception) {
                                    Toast.makeText(ctx, R.string.no_sms_app, Toast.LENGTH_SHORT).show()
                                }
                            }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.sms)) }
                            OutlinedButton(onClick = {
                                val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, msg)
                                ctx.startActivity(Intent.createChooser(send, ctx.getString(R.string.share)))
                            }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.share)) }
                        }
                    }
                }
            }
        }
        item { HorizontalDivider() }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(stringResource(R.string.pair_key), style = MaterialTheme.typography.titleSmall)
                Text(
                    if (showKey) child.key else "••••-••••-••••-••••-•",
                    fontFamily = FontFamily.Monospace,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { showKey = !showKey }) {
                        Text(stringResource(if (showKey) R.string.hide else R.string.show))
                    }
                    TextButton(onClick = { Clip.copy(ctx, child.key, R.string.key_copied, sensitive = true) }) {
                        Text(stringResource(R.string.copy))
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { rename = true }) { Text(stringResource(R.string.rename)) }
                    TextButton(onClick = { confirmDelete = true }) { Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error) }
                }
            }
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text(stringResource(R.string.delete)) },
            text = { Text(stringResource(R.string.delete_child_q, child.name)) },
            confirmButton = {
                TextButton(onClick = {
                    store.removeChild(child.id)
                    confirmDelete = false
                    onChanged()
                }) { Text(stringResource(R.string.delete)) }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text(stringResource(R.string.cancel)) } }
        )
    }
    if (rename) {
        var name by remember { mutableStateOf(child.name) }
        AlertDialog(
            onDismissRequest = { rename = false },
            title = { Text(stringResource(R.string.rename)) },
            text = {
                OutlinedTextField(value = name, onValueChange = { name = it.take(30) }, singleLine = true, label = { Text(stringResource(R.string.child_name)) })
            },
            confirmButton = {
                TextButton(onClick = {
                    store.renameChild(child.id, name)
                    rename = false
                    onChanged()
                }) { Text(stringResource(R.string.save)) }
            },
            dismissButton = { TextButton(onClick = { rename = false }) { Text(stringResource(R.string.cancel)) } }
        )
    }
}

@Composable
private fun AddChildDialog(store: BoxStore, onDismiss: () -> Unit, onAdded: () -> Unit) {
    val ctx = LocalContext.current
    var name by remember { mutableStateOf("") }
    var mode by remember { mutableStateOf(0) }
    var keyText by remember { mutableStateOf("") }
    val generated = remember { CodeCrypto.formatKey(CodeCrypto.generateKey()) }
    var err by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.add_child)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it.take(30) },
                    label = { Text(stringResource(R.string.child_name)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = mode == 0, onClick = { mode = 0 }, label = { Text(stringResource(R.string.mode_enter)) })
                    FilterChip(selected = mode == 1, onClick = { mode = 1 }, label = { Text(stringResource(R.string.mode_create)) })
                }
                if (mode == 0) {
                    Text(stringResource(R.string.mode_enter_hint), style = MaterialTheme.typography.bodySmall)
                    OutlinedTextField(
                        value = keyText,
                        onValueChange = { keyText = it.uppercase().take(24) },
                        label = { Text("XXXX-XXXX-XXXX-XXXX-X") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    TextButton(onClick = {
                        val k = Clip.extractKey(Clip.read(ctx))
                        if (k.isNullOrEmpty()) err = ctx.getString(R.string.paste_empty) else {
                            keyText = k
                            err = ""
                        }
                    }) { Text(stringResource(R.string.paste)) }
                } else {
                    Text(stringResource(R.string.mode_create_hint), style = MaterialTheme.typography.bodySmall)
                    Text(generated, fontFamily = FontFamily.Monospace, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = { Clip.copy(ctx, generated, R.string.key_copied, sensitive = true) }) {
                            Text(stringResource(R.string.copy))
                        }
                        OutlinedButton(onClick = {
                            val send = Intent(Intent.ACTION_SEND).setType("text/plain")
                                .putExtra(Intent.EXTRA_TEXT, ctx.getString(R.string.key_share_text, generated))
                            ctx.startActivity(Intent.createChooser(send, ctx.getString(R.string.share)))
                        }) { Text(stringResource(R.string.share)) }
                    }
                }
                if (err.isNotEmpty()) Text(err, color = MaterialTheme.colorScheme.error)
            }
        },
        confirmButton = {
            TextButton(enabled = name.isNotBlank(), onClick = {
                val c = store.addChild(name, if (mode == 0) keyText else generated)
                if (c == null) err = ctx.getString(R.string.key_invalid) else onAdded()
            }) { Text(stringResource(R.string.save)) }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } }
    )
}

@Composable
private fun SettingsScreen(store: BoxStore, onChanged: () -> Unit) {
    val ctx = LocalContext.current
    var hasPin by remember { mutableStateOf(store.hasPin) }
    var pinA by remember { mutableStateOf("") }
    var pinB by remember { mutableStateOf("") }
    var msg by remember { mutableStateOf("") }
    LaunchedEffect(msg) {
        if (msg.isNotEmpty()) {
            delay(3000)
            msg = ""
        }
    }
    LazyColumn(
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Card(shape = RoundedCornerShape(20.dp), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(stringResource(R.string.pin_section), fontWeight = FontWeight.Bold)
                    Text(stringResource(R.string.pin_section_sub), style = MaterialTheme.typography.bodySmall)
                    Text(stringResource(if (hasPin) R.string.pin_on else R.string.pin_off), color = MaterialTheme.colorScheme.primary)
                    OutlinedTextField(
                        value = pinA, onValueChange = { pinA = it.filter { c -> c in '0'..'9' }.take(4) },
                        label = { Text(stringResource(R.string.pin_new)) }, singleLine = true,
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword)
                    )
                    OutlinedTextField(
                        value = pinB, onValueChange = { pinB = it.filter { c -> c in '0'..'9' }.take(4) },
                        label = { Text(stringResource(R.string.pin_repeat)) }, singleLine = true,
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword)
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(enabled = pinA.length == 4 && pinB.length == 4, onClick = {
                            if (pinA != pinB) msg = ctx.getString(R.string.pin_mismatch) else {
                                store.setPin(pinA)
                                hasPin = true
                                pinA = ""
                                pinB = ""
                                msg = ctx.getString(R.string.saved)
                            }
                        }) { Text(stringResource(R.string.save)) }
                        if (hasPin) {
                            OutlinedButton(onClick = {
                                store.setPin(null)
                                hasPin = false
                                msg = ctx.getString(R.string.saved)
                            }) { Text(stringResource(R.string.pin_remove)) }
                        }
                    }
                    if (msg.isNotEmpty()) Text(msg, color = MaterialTheme.colorScheme.primary)
                }
            }
        }
        item {
            Card(shape = RoundedCornerShape(20.dp), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(stringResource(R.string.how_title), fontWeight = FontWeight.Bold)
                    Text(stringResource(R.string.how_text), style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
        item {
            OutlinedButton(onClick = {
                store.clearHistory()
                onChanged()
                msg = ctx.getString(R.string.saved)
            }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.clear_history)) }
        }
    }
}
