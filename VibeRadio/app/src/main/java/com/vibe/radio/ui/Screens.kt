@file:OptIn(ExperimentalFoundationApi::class)

package com.vibe.radio.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.basicMarquee
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FavoriteBorder
import androidx.compose.material.icons.rounded.KeyboardArrowDown
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.SkipNext
import androidx.compose.material.icons.rounded.SkipPrevious
import androidx.compose.material.icons.rounded.Timer
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.vibe.radio.audio.VoiceEffect
import com.vibe.radio.data.Region
import com.vibe.radio.data.Station

@Composable
fun AppScreen(vm: PlayerViewModel) {
    val snack = remember { SnackbarHostState() }
    LaunchedEffect(vm.message) {
        vm.message?.let { snack.showSnackbar(it); vm.message = null }
    }
    BackHandler(enabled = vm.playerOpen) { vm.playerOpen = false }

    Box(Modifier.fillMaxSize().background(Neon.bgBrush)) {
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            Header()
            SearchBar(vm.query, vm::onQuery)
            Tabs(vm.tab, vm::selectTab)
            StationList(vm, Modifier.weight(1f))
        }

        AnimatedVisibility(
            visible = vm.current != null && !vm.playerOpen,
            modifier = Modifier.align(Alignment.BottomCenter),
            enter = slideInVertically { it } + fadeIn(),
            exit = slideOutVertically { it } + fadeOut(),
        ) {
            MiniPlayer(vm)
        }

        AnimatedVisibility(
            visible = vm.playerOpen,
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            FullPlayer(vm)
        }

        SnackbarHost(snack, Modifier.align(Alignment.TopCenter).statusBarsPadding())
    }
}

@Composable
private fun Header() {
    Column(Modifier.padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 4.dp)) {
        Text(
            "VibeRadio",
            style = TextStyle(brush = Brush.linearGradient(listOf(Neon.Cyan, Neon.Pink)), fontSize = 32.sp, fontWeight = FontWeight.Black),
        )
        Text("Радио мира · эффекты голоса · танцы", color = Neon.Text2, fontSize = 13.sp)
    }
}

@Composable
private fun SearchBar(query: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = query,
        onValueChange = onChange,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        placeholder = { Text("Найти станцию или жанр…") },
        leadingIcon = { Icon(Icons.Rounded.Search, null) },
        trailingIcon = {
            if (query.isNotEmpty()) IconButton(onClick = { onChange("") }) { Icon(Icons.Rounded.Close, null) }
        },
        singleLine = true,
        shape = RoundedCornerShape(18.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Neon.Pink,
            unfocusedBorderColor = Color.White.copy(alpha = 0.15f),
            focusedContainerColor = Neon.Card,
            unfocusedContainerColor = Neon.Card,
        ),
    )
}

@Composable
private fun Tabs(selected: Tab, onSelect: (Tab) -> Unit) {
    val tabs = Region.entries.map { Triple(Tab.valueOf(it.name), it.flag, it.title) } + Triple(Tab.FAV, "❤️", "Избранное")
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(vertical = 6.dp),
    ) {
        items(tabs) { (tab, flag, title) ->
            val active = tab == selected
            Row(
                Modifier
                    .clip(RoundedCornerShape(50))
                    .background(if (active) Neon.accent else Brush.linearGradient(listOf(Neon.Card, Neon.Card)))
                    .clickable { onSelect(tab) }
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(flag, fontSize = 16.sp)
                Spacer(Modifier.width(6.dp))
                Text(title, fontWeight = if (active) FontWeight.Bold else FontWeight.Medium, color = Color.White)
            }
        }
    }
}

@Composable
private fun StationList(vm: PlayerViewModel, modifier: Modifier) {
    Box(modifier.fillMaxWidth()) {
        when {
            vm.loading && vm.stations.isEmpty() ->
                CircularProgressIndicator(Modifier.align(Alignment.Center), color = Neon.Pink)

            vm.stations.isEmpty() -> Column(
                Modifier.align(Alignment.Center).padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(if (vm.tab == Tab.FAV) "Здесь пока пусто.\nНажмите ♥ у станции, чтобы добавить." else "Станции не загрузились",
                    color = Neon.Text2)
                if (vm.tab != Tab.FAV) TextButton(onClick = vm::reload) {
                    Icon(Icons.Rounded.Refresh, null); Spacer(Modifier.width(6.dp)); Text("Повторить")
                }
            }

            else -> LazyColumn(
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 120.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                items(vm.stations, key = { it.id }) { st ->
                    StationRow(
                        st,
                        isCurrent = vm.current?.id == st.id,
                        isPlaying = vm.isPlaying && vm.current?.id == st.id,
                        isFav = vm.isFavorite(st),
                        onClick = { vm.play(st) },
                        onFav = { vm.toggleFavorite(st) },
                    )
                }
            }
        }
        if (vm.loading && vm.stations.isNotEmpty()) {
            CircularProgressIndicator(Modifier.align(Alignment.TopCenter).padding(8.dp).size(24.dp), color = Neon.Cyan, strokeWidth = 2.dp)
        }
    }
}

@Composable
private fun StationRow(
    st: Station, isCurrent: Boolean, isPlaying: Boolean, isFav: Boolean,
    onClick: () -> Unit, onFav: () -> Unit,
) {
    val shape = RoundedCornerShape(20.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(if (isCurrent) Brush.linearGradient(listOf(Neon.Violet.copy(alpha = 0.55f), Neon.Pink.copy(alpha = 0.35f)))
                        else Brush.linearGradient(listOf(Neon.Card, Neon.Card)))
            .border(1.dp, if (isCurrent) Neon.Pink.copy(alpha = 0.7f) else Color.White.copy(alpha = 0.06f), shape)
            .clickable(onClick = onClick)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StationLogo(st, 52.dp)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(st.name, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, color = Color.White)
            val sub = listOfNotNull(
                st.tags.takeIf { it.isNotBlank() },
                st.bitrate.takeIf { it > 0 }?.let { "$it kbps" },
                st.codec.takeIf { it.isNotBlank() },
            ).joinToString(" · ")
            if (sub.isNotBlank()) Text(sub, color = Neon.Text2, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (isPlaying) MiniEq(Modifier.padding(horizontal = 6.dp))
        IconButton(onClick = onFav) {
            Icon(
                if (isFav) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder, null,
                tint = if (isFav) Neon.Pink else Color.White.copy(alpha = 0.6f),
            )
        }
    }
}

@Composable
private fun StationLogo(st: Station, size: Dp) {
    Box(
        Modifier.size(size).clip(RoundedCornerShape(14.dp)).background(Neon.accent),
        contentAlignment = Alignment.Center,
    ) {
        Text(st.name.take(1).uppercase(), fontWeight = FontWeight.Black, fontSize = (size.value * 0.42f).sp, color = Color.White)
        if (st.favicon.isNotBlank()) {
            AsyncImage(
                model = st.favicon, contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize().background(Color.Transparent),
            )
        }
    }
}

@Composable
private fun MiniEq(modifier: Modifier = Modifier) {
    val tr = rememberInfiniteTransition(label = "eq")
    Row(modifier.height(18.dp), horizontalArrangement = Arrangement.spacedBy(2.dp), verticalAlignment = Alignment.Bottom) {
        listOf(380, 520, 300, 450).forEachIndexed { i, ms ->
            val h by tr.animateFloat(0.2f, 1f, infiniteRepeatable(tween(ms), RepeatMode.Reverse), label = "b$i")
            Box(Modifier.width(3.dp).height((18 * h).dp).clip(RoundedCornerShape(2.dp)).background(Neon.Cyan))
        }
    }
}

@Composable
private fun PlayButton(vm: PlayerViewModel, size: Dp) {
    Box(
        Modifier.size(size).clip(CircleShape).background(Neon.accent).clickable { vm.togglePlay() },
        contentAlignment = Alignment.Center,
    ) {
        if (vm.isBuffering) CircularProgressIndicator(Modifier.size(size * 0.55f), color = Color.White, strokeWidth = 3.dp)
        else Icon(if (vm.isPlaying) Icons.Rounded.Pause else Icons.Rounded.PlayArrow, null, tint = Color.White, modifier = Modifier.size(size * 0.55f))
    }
}

@Composable
private fun MiniPlayer(vm: PlayerViewModel) {
    val st = vm.current ?: return
    Row(
        Modifier
            .navigationBarsPadding()
            .padding(12.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(Brush.linearGradient(listOf(Color(0xFF2A1450), Color(0xFF3B0F45))))
            .border(1.dp, Neon.Pink.copy(alpha = 0.4f), RoundedCornerShape(24.dp))
            .clickable { vm.playerOpen = true }
            .padding(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StationLogo(st, 46.dp)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(st.name, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis, color = Color.White)
            Text(
                vm.nowPlaying.ifBlank { "${vm.effect.emoji} ${vm.effect.title} · ${vm.dancer.emoji} ${vm.dancer.title}" },
                color = Neon.Text2, fontSize = 12.sp, maxLines = 1,
                modifier = Modifier.basicMarquee(),
            )
        }
        IconButton(onClick = vm::next) { Icon(Icons.Rounded.SkipNext, null, tint = Color.White) }
        PlayButton(vm, 48.dp)
    }
}

@Composable
private fun FullPlayer(vm: PlayerViewModel) {
    val st = vm.current
    var sleepMenu by remember { mutableStateOf(false) }

    Column(
        Modifier.fillMaxSize().background(Neon.bgBrush).statusBarsPadding().navigationBarsPadding(),
    ) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { vm.playerOpen = false }) {
                Icon(Icons.Rounded.KeyboardArrowDown, null, tint = Color.White, modifier = Modifier.size(32.dp))
            }
            Text("Сейчас играет", Modifier.weight(1f), color = Neon.Text2, fontWeight = FontWeight.Medium)
            Box {
                TextButton(onClick = { sleepMenu = true }) {
                    Icon(Icons.Rounded.Timer, null, tint = if (vm.sleepMinutesLeft > 0) Neon.Cyan else Color.White)
                    if (vm.sleepMinutesLeft > 0) Text(" ${vm.sleepMinutesLeft} мин", color = Neon.Cyan)
                }
                DropdownMenu(expanded = sleepMenu, onDismissRequest = { sleepMenu = false }) {
                    listOf(0 to "Выключить таймер", 15 to "15 минут", 30 to "30 минут", 60 to "1 час", 90 to "1,5 часа")
                        .forEach { (m, label) ->
                            DropdownMenuItem(text = { Text(label) }, onClick = { vm.setSleep(m); sleepMenu = false })
                        }
                }
            }
        }

        DancerStage(vm.dancer, vm.isPlaying, Modifier.fillMaxWidth().weight(1f))

        // выбор персонажа
        LazyRow(
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(Dancer.entries.toList()) { d ->
                val active = d == vm.dancer
                Column(
                    Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(if (active) Neon.accent else Brush.linearGradient(listOf(Neon.Card, Neon.Card)))
                        .clickable { vm.selectDancer(d) }
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(d.emoji, fontSize = 22.sp)
                    Text(d.title, fontSize = 11.sp, color = Color.White)
                }
            }
        }

        Spacer(Modifier.height(14.dp))
        Column(Modifier.padding(horizontal = 24.dp)) {
            Text(st?.name ?: "—", fontSize = 24.sp, fontWeight = FontWeight.Black, color = Color.White, maxLines = 1,
                modifier = Modifier.basicMarquee())
            Text(
                vm.nowPlaying.ifBlank { st?.tags?.ifBlank { "Прямой эфир" } ?: "Прямой эфир" },
                color = Neon.Text2, maxLines = 1, modifier = Modifier.basicMarquee(),
            )
        }

        Row(
            Modifier.fillMaxWidth().padding(vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = { st?.let(vm::toggleFavorite) }) {
                Icon(
                    if (st != null && vm.isFavorite(st)) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder, null,
                    tint = Neon.Pink, modifier = Modifier.size(28.dp),
                )
            }
            IconButton(onClick = vm::prev) { Icon(Icons.Rounded.SkipPrevious, null, tint = Color.White, modifier = Modifier.size(40.dp)) }
            PlayButton(vm, 76.dp)
            IconButton(onClick = vm::next) { Icon(Icons.Rounded.SkipNext, null, tint = Color.White, modifier = Modifier.size(40.dp)) }
            Spacer(Modifier.size(48.dp))
        }

        Text("Эффекты звука", Modifier.padding(start = 24.dp, bottom = 6.dp), color = Neon.Text2, fontSize = 13.sp)
        LazyRow(
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(VoiceEffect.entries.toList()) { e ->
                val active = e == vm.effect
                Column(
                    Modifier
                        .width(78.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(if (active) Neon.accent else Brush.linearGradient(listOf(Neon.Card, Neon.Card)))
                        .border(1.dp, if (active) Color.White.copy(alpha = 0.5f) else Color.Transparent, RoundedCornerShape(18.dp))
                        .clickable { vm.selectEffect(e) }
                        .padding(vertical = 10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(e.emoji, fontSize = 24.sp)
                    Text(e.title, fontSize = 11.sp, color = Color.White, maxLines = 1)
                }
            }
        }
    }
}
