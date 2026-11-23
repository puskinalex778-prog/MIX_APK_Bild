package com.khranitoniks.guard.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Indigo = Color(0xFF3949AB)
val IndigoLight = Color(0xFF8E99F3)
val Teal = Color(0xFF00ACC1)
val Amber = Color(0xFFFFB300)
val Danger = Color(0xFFD32F2F)
val Good = Color(0xFF2E7D32)

private val LightColors = lightColorScheme(
    primary = Indigo,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFDDE1FF),
    onPrimaryContainer = Color(0xFF001257),
    secondary = Teal,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFCDF3F8),
    onSecondaryContainer = Color(0xFF00363D),
    tertiary = Amber,
    background = Color(0xFFF5F6FB),
    surface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFFE7E9F3),
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002)
)

private val DarkColors = darkColorScheme(
    primary = IndigoLight,
    onPrimary = Color(0xFF00218B),
    primaryContainer = Color(0xFF2A3A8F),
    onPrimaryContainer = Color(0xFFDDE1FF),
    secondary = Color(0xFF4DD0E1),
    onSecondary = Color(0xFF00363D),
    secondaryContainer = Color(0xFF004F58),
    onSecondaryContainer = Color(0xFFCDF3F8),
    tertiary = Amber,
    background = Color(0xFF111318),
    surface = Color(0xFF1A1C22),
    surfaceVariant = Color(0xFF2A2D36)
)

@Composable
fun KhTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors,
        content = content
    )
}
