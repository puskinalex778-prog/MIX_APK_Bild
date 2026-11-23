@file:OptIn(ExperimentalMaterial3Api::class)

package com.khranitoniks.guard.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.khranitoniks.guard.R
import com.khranitoniks.guard.core.Prefs
import com.khranitoniks.guard.service.GuardService
import com.khranitoniks.guard.ui.common.PinDialog
import com.khranitoniks.guard.ui.home.HomeScreen
import com.khranitoniks.guard.ui.onboarding.OnboardingScreen
import com.khranitoniks.guard.ui.permissions.PermissionsScreen
import com.khranitoniks.guard.ui.settings.JournalScreen
import com.khranitoniks.guard.ui.settings.SettingsScreen
import com.khranitoniks.guard.ui.stats.StatsScreen
import com.khranitoniks.guard.ui.theme.KhTheme
import com.khranitoniks.guard.ui.tools.ToolsScreen

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            KhTheme { Root() }
        }
    }

    override fun onResume() {
        super.onResume()
        GuardService.start(this)
    }
}

private enum class Sub { NONE, PERMISSIONS, TOOLS, JOURNAL }

@Composable
private fun Root() {
    val ctx = LocalContext.current
    var onboarded by remember { mutableStateOf(Prefs.get(ctx).onboardingDone) }
    if (!onboarded) {
        OnboardingScreen(onDone = {
            Prefs.get(ctx).onboardingDone = true
            GuardService.start(ctx)
            onboarded = true
        })
    } else {
        MainScaffold()
    }
}

@Composable
private fun MainScaffold() {
    var tab by remember { mutableStateOf(0) }
    var sub by remember { mutableStateOf(Sub.NONE) }
    var settingsUnlocked by remember { mutableStateOf(false) }
    var askPin by remember { mutableStateOf(false) }
    var subNeedsPin by remember { mutableStateOf(false) }

    BackHandler(enabled = sub != Sub.NONE || tab != 0) {
        if (sub != Sub.NONE) sub = Sub.NONE else {
            tab = 0
            settingsUnlocked = false
        }
    }

    val title = when (sub) {
        Sub.PERMISSIONS -> stringResource(R.string.perm_title)
        Sub.TOOLS -> stringResource(R.string.tools_title)
        Sub.JOURNAL -> stringResource(R.string.journal_title)
        Sub.NONE -> when (tab) {
            1 -> stringResource(R.string.nav_stats_long)
            2 -> stringResource(R.string.nav_settings)
            else -> stringResource(R.string.app_name)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    if (sub != Sub.NONE) {
                        IconButton(onClick = { sub = Sub.NONE }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                    navigationIconContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        },
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = tab == 0 && sub == Sub.NONE,
                    onClick = {
                        tab = 0
                        sub = Sub.NONE
                        settingsUnlocked = false
                    },
                    icon = { Icon(Icons.Filled.Home, contentDescription = null) },
                    label = { Text(stringResource(R.string.nav_home)) }
                )
                NavigationBarItem(
                    selected = tab == 1 && sub == Sub.NONE,
                    onClick = {
                        tab = 1
                        sub = Sub.NONE
                        settingsUnlocked = false
                    },
                    icon = { Icon(Icons.Filled.DateRange, contentDescription = null) },
                    label = { Text(stringResource(R.string.nav_stats)) }
                )
                NavigationBarItem(
                    selected = tab == 2 && sub == Sub.NONE,
                    onClick = {
                        if (settingsUnlocked) {
                            tab = 2
                            sub = Sub.NONE
                        } else {
                            subNeedsPin = false
                            askPin = true
                        }
                    },
                    icon = { Icon(if (settingsUnlocked) Icons.Filled.Settings else Icons.Filled.Lock, contentDescription = null) },
                    label = { Text(stringResource(R.string.nav_settings)) }
                )
            }
        }
    ) { padding ->
        Box(
            Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (sub) {
                Sub.PERMISSIONS -> PermissionsScreen()
                Sub.TOOLS -> ToolsScreen()
                Sub.JOURNAL -> JournalScreen()
                Sub.NONE -> when (tab) {
                    1 -> StatsScreen()
                    2 -> SettingsScreen(
                        onOpenPermissions = { sub = Sub.PERMISSIONS },
                        onOpenJournal = { sub = Sub.JOURNAL }
                    )
                    else -> HomeScreen(
                        onOpenPermissions = { sub = Sub.PERMISSIONS },
                        onOpenTools = {
                            if (settingsUnlocked) sub = Sub.TOOLS else {
                                subNeedsPin = true
                                askPin = true
                            }
                        }
                    )
                }
            }
        }
    }

    if (askPin) {
        PinDialog(
            title = stringResource(R.string.pin_enter_title),
            onDismiss = { askPin = false },
            onSuccess = {
                askPin = false
                settingsUnlocked = true
                if (subNeedsPin) sub = Sub.TOOLS else {
                    tab = 2
                    sub = Sub.NONE
                }
            }
        )
    }
}
