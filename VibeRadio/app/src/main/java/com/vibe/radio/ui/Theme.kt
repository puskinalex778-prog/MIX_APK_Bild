package com.vibe.radio.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

object Neon {
    val Bg = Color(0xFF0B0B1A)
    val Bg2 = Color(0xFF1B0F33)
    val Card = Color(0x1FFFFFFF)
    val Pink = Color(0xFFFF4FD8)
    val Cyan = Color(0xFF4FE3FF)
    val Violet = Color(0xFF7B2FF7)
    val Text2 = Color(0xB3FFFFFF)
    val bgBrush = Brush.verticalGradient(listOf(Bg2, Bg, Color(0xFF07070F)))
    val accent = Brush.linearGradient(listOf(Violet, Pink))
}

@Composable
fun VibeTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Neon.Pink,
            secondary = Neon.Cyan,
            tertiary = Neon.Violet,
            background = Neon.Bg,
            surface = Neon.Bg2,
            onPrimary = Color.White,
            onBackground = Color.White,
            onSurface = Color.White,
        ),
        content = content,
    )
}
