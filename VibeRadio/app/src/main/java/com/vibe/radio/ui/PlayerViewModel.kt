package com.vibe.radio.ui

import android.app.Application
import android.content.ComponentName
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.vibe.radio.PlaybackService
import com.vibe.radio.audio.AudioFx
import com.vibe.radio.audio.VoiceEffect
import com.vibe.radio.data.RadioRepository
import com.vibe.radio.data.Region
import com.vibe.radio.data.Station
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch

enum class Tab { RU, US, KR, DE, FAV }

enum class Dancer(val title: String, val emoji: String) {
    CAT("Вислоухий кот", "🐱"),
    RAT("Белый крыс", "🐀"),
    DIKAMIK("Дикамик", "👾"),
    ROACH("Таракан", "🪳"),
    GIRL("Девочка", "👧"),
    BARS("Эквалайзер", "📊"),
}

class PlayerViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = RadioRepository(app)
    private var controller: MediaController? = null

    var tab by mutableStateOf(Tab.RU); private set
    var stations by mutableStateOf<List<Station>>(emptyList()); private set
    var loading by mutableStateOf(false); private set
    var query by mutableStateOf("")
    val favorites = mutableStateListOf<Station>()

    var current by mutableStateOf<Station?>(null); private set
    var isPlaying by mutableStateOf(false); private set
    var isBuffering by mutableStateOf(false); private set
    var nowPlaying by mutableStateOf(""); private set
    var message by mutableStateOf<String?>(null)

    var effect by mutableStateOf(VoiceEffect.NONE); private set
    var dancer by mutableStateOf(Dancer.CAT)
    var sleepMinutesLeft by mutableStateOf(0); private set
    var playerOpen by mutableStateOf(false)

    private val known = HashMap<String, Station>()
    private var sleepJob: Job? = null
    private var searchJob: Job? = null

    private fun connect() {
        val ctx = getApplication<Application>()
        val token = SessionToken(ctx, ComponentName(ctx, PlaybackService::class.java))
        viewModelScope.launch {
            try {
                val c = MediaController.Builder(ctx, token).buildAsync().await()
                controller = c
                c.addListener(listener)
                syncFromPlayer(c)
                applyPitch()
            } catch (e: Exception) {
                message = "Не удалось запустить плеер: ${e.message}"
            }
        }
    }

    private val listener = object : Player.Listener {
        override fun onEvents(player: Player, events: Player.Events) = syncFromPlayer(player)

        override fun onPlayerError(error: PlaybackException) {
            val c = controller ?: return
            message = "Станция «${current?.name ?: ""}» недоступна — переключаю"
            if (c.hasNextMediaItem()) {
                c.seekToNextMediaItem(); c.prepare(); c.play()
            }
        }
    }

    init {
        favorites.addAll(repo.favorites())
        favorites.forEach { known[it.id] = it }
        effect = runCatching { VoiceEffect.valueOf(repo.getString("effect", "NONE")) }.getOrDefault(VoiceEffect.NONE)
        AudioFx.effect = effect
        dancer = runCatching { Dancer.valueOf(repo.getString("dancer", "CAT")) }.getOrDefault(Dancer.CAT)
        tab = runCatching { Tab.valueOf(repo.getString("tab", "RU")) }.getOrDefault(Tab.RU)
        connect()
        loadTab(tab)
    }

    private fun syncFromPlayer(p: Player) {
        isPlaying = p.isPlaying
        isBuffering = p.playbackState == Player.STATE_BUFFERING
        val id = p.currentMediaItem?.mediaId
        current = id?.let { known[it] } ?: p.currentMediaItem?.let { item ->
            Station(
                id = item.mediaId,
                name = item.mediaMetadata.artist?.toString() ?: "Радио",
                url = item.requestMetadata.mediaUri?.toString() ?: "",
                favicon = item.mediaMetadata.artworkUri?.toString() ?: "",
            ).also { known[it.id] = it }
        }
        val title = p.mediaMetadata.title?.toString().orEmpty()
        nowPlaying = if (title.isNotBlank() && title != current?.name) title else ""
    }

    // ---------------- Список станций ----------------
    fun selectTab(t: Tab) {
        tab = t
        query = ""
        repo.putString("tab", t.name)
        loadTab(t)
    }

    fun reload() {
        if (query.isNotBlank()) onQuery(query) else loadTab(tab)
    }

    private fun loadTab(t: Tab) {
        if (t == Tab.FAV) {
            stations = favorites.toList(); return
        }
        val region = Region.valueOf(t.name)
        viewModelScope.launch {
            loading = true
            val list = repo.byRegion(region)
            list.forEach { known[it.id] = it }
            if (tab == t && query.isBlank()) stations = list
            if (list.isEmpty()) message = "Нет соединения с каталогом станций"
            loading = false
        }
    }

    fun onQuery(q: String) {
        query = q
        searchJob?.cancel()
        if (q.isBlank()) { loadTab(tab); return }
        searchJob = viewModelScope.launch {
            delay(450)
            loading = true
            val list = repo.search(q)
            list.forEach { known[it.id] = it }
            stations = list
            loading = false
        }
    }

    // ---------------- Воспроизведение ----------------
    fun play(station: Station) {
        val c = controller ?: run { message = "Плеер ещё запускается…"; return }
        if (current?.id == station.id) { togglePlay(); return }
        val list = stations.ifEmpty { listOf(station) }
        val index = list.indexOfFirst { it.id == station.id }.coerceAtLeast(0)
        c.setMediaItems(list.map { it.toMediaItem() }, index, 0L)
        c.prepare()
        c.play()
        current = station
        nowPlaying = ""
    }

    fun togglePlay() {
        val c = controller ?: return
        if (c.isPlaying) c.pause() else {
            if (c.playbackState == Player.STATE_IDLE) c.prepare()
            c.play()
        }
    }

    fun next() {
        val c = controller ?: return
        if (c.hasNextMediaItem()) { c.seekToNextMediaItem(); c.play() }
    }

    fun prev() {
        val c = controller ?: return
        if (c.hasPreviousMediaItem()) { c.seekToPreviousMediaItem(); c.play() }
    }

    fun isFavorite(s: Station) = favorites.any { it.id == s.id }

    fun toggleFavorite(s: Station) {
        val i = favorites.indexOfFirst { it.id == s.id }
        if (i >= 0) favorites.removeAt(i) else favorites.add(0, s)
        repo.saveFavorites(favorites)
        if (tab == Tab.FAV) stations = favorites.toList()
    }

    // ---------------- Эффекты ----------------
    fun selectEffect(e: VoiceEffect) {
        effect = e
        AudioFx.effect = e
        repo.putString("effect", e.name)
        applyPitch()
    }

    private fun applyPitch() {
        controller?.playbackParameters = PlaybackParameters(1f, effect.pitch)
    }

    fun selectDancer(d: Dancer) {
        dancer = d
        repo.putString("dancer", d.name)
    }

    // ---------------- Таймер сна ----------------
    fun setSleep(minutes: Int) {
        sleepJob?.cancel()
        sleepMinutesLeft = minutes
        if (minutes <= 0) return
        sleepJob = viewModelScope.launch {
            while (sleepMinutesLeft > 0) {
                delay(60_000)
                sleepMinutesLeft--
            }
            controller?.pause()
            message = "Таймер сна: воспроизведение остановлено"
        }
    }

    private fun Station.toMediaItem(): MediaItem {
        val uri = Uri.parse(url)
        val meta = MediaMetadata.Builder()
            .setArtist(name)
            .setAlbumTitle(listOf(country, tags).filter { it.isNotBlank() }.joinToString(" · "))
            .apply { if (favicon.isNotBlank()) setArtworkUri(Uri.parse(favicon)) }
            .build()
        return MediaItem.Builder()
            .setMediaId(id)
            .setUri(uri)
            .setMediaMetadata(meta)
            .setRequestMetadata(MediaItem.RequestMetadata.Builder().setMediaUri(uri).build())
            .build()
    }

    override fun onCleared() {
        controller?.removeListener(listener)
        controller?.release()
        super.onCleared()
    }
}
