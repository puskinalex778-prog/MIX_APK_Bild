package com.vibe.radio.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

data class Station(
    val id: String,
    val name: String,
    val url: String,
    val favicon: String = "",
    val country: String = "",
    val tags: String = "",
    val bitrate: Int = 0,
    val codec: String = "",
)

enum class Region(val code: String, val title: String, val flag: String) {
    RU("RU", "Россия", "🇷🇺"),
    US("US", "США", "🇺🇸"),
    KR("KR", "Корея", "🇰🇷"),
    DE("DE", "Германия", "🇩🇪"),
}

/**
 * Станции берутся из открытого каталога Radio Browser (десятки тысяч живых потоков),
 * поэтому список всегда актуален. Если каталог недоступен — используется встроенный запасной список.
 */
class RadioRepository(context: Context) {

    private val prefs = context.getSharedPreferences("vibe", Context.MODE_PRIVATE)

    private val servers = listOf(
        "https://de1.api.radio-browser.info",
        "https://fi1.api.radio-browser.info",
        "https://de2.api.radio-browser.info",
        "https://all.api.radio-browser.info",
    )

    suspend fun byRegion(region: Region): List<Station> = withContext(Dispatchers.IO) {
        val path = "/json/stations/search?countrycode=${region.code}" +
            "&order=clickcount&reverse=true&limit=120&hidebroken=true"
        val list = fetch(path)
        list.ifEmpty { fallback[region].orEmpty() }
    }

    suspend fun search(query: String): List<Station> = withContext(Dispatchers.IO) {
        val q = URLEncoder.encode(query.trim(), "UTF-8")
        val codes = Region.entries.joinToString(",") { it.code }
        // ищем по всему миру, но сортируем так, чтобы станции 4 стран шли первыми
        fetch("/json/stations/search?name=$q&order=clickcount&reverse=true&limit=100&hidebroken=true")
            .sortedByDescending { st -> codes.contains(st.country.take(2).uppercase()) && st.country.isNotEmpty() }
    }

    private fun fetch(path: String): List<Station> {
        for (base in servers) {
            try {
                val conn = URL(base + path).openConnection() as HttpURLConnection
                conn.connectTimeout = 8000
                conn.readTimeout = 10000
                conn.setRequestProperty("User-Agent", "VibeRadio/1.0")
                val body = conn.inputStream.bufferedReader().use { it.readText() }
                conn.disconnect()
                val arr = JSONArray(body)
                val seen = HashSet<String>()
                val out = ArrayList<Station>()
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    val url = o.optString("url_resolved").ifBlank { o.optString("url") }
                    val name = o.optString("name").trim()
                    if (url.isBlank() || name.isBlank()) continue
                    if (!seen.add(name.lowercase())) continue
                    out += Station(
                        id = o.optString("stationuuid", url),
                        name = name,
                        url = url,
                        favicon = o.optString("favicon"),
                        country = o.optString("countrycode"),
                        tags = o.optString("tags").split(",").take(3).joinToString(" · "),
                        bitrate = o.optInt("bitrate"),
                        codec = o.optString("codec"),
                    )
                }
                if (out.isNotEmpty()) return out
            } catch (_: Exception) {
                // пробуем следующий сервер
            }
        }
        return emptyList()
    }

    // ---------- Избранное ----------
    fun favorites(): List<Station> {
        val raw = prefs.getString("favs", "[]") ?: "[]"
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Station(
                    id = o.getString("id"), name = o.getString("name"), url = o.getString("url"),
                    favicon = o.optString("favicon"), country = o.optString("country"),
                    tags = o.optString("tags"), bitrate = o.optInt("bitrate"), codec = o.optString("codec"),
                )
            }
        } catch (_: Exception) { emptyList() }
    }

    fun saveFavorites(list: List<Station>) {
        val arr = JSONArray()
        list.forEach { s ->
            arr.put(JSONObject().apply {
                put("id", s.id); put("name", s.name); put("url", s.url); put("favicon", s.favicon)
                put("country", s.country); put("tags", s.tags); put("bitrate", s.bitrate); put("codec", s.codec)
            })
        }
        prefs.edit().putString("favs", arr.toString()).apply()
    }

    fun getString(key: String, def: String) = prefs.getString(key, def) ?: def
    fun putString(key: String, value: String) = prefs.edit().putString(key, value).apply()

    private val fallback = mapOf(
        Region.RU to listOf(
            Station("fb-ru-1", "Европа Плюс", "https://ep256.hostingradio.ru:8052/europaplus256.mp3", country = "RU", tags = "pop"),
            Station("fb-ru-2", "Русское Радио", "https://rusradio.hostingradio.ru/rusradio128.mp3", country = "RU", tags = "pop · russian"),
            Station("fb-ru-3", "Radio Record", "https://radiorecord.hostingradio.ru/rr_main96.aacp", country = "RU", tags = "dance · edm"),
        ),
        Region.US to listOf(
            Station("fb-us-1", "KEXP 90.3 Seattle", "https://kexp-mp3-128.streamguys1.com/kexp128.mp3", country = "US", tags = "indie · rock"),
            Station("fb-us-2", "SomaFM Groove Salad", "https://ice1.somafm.com/groovesalad-128-mp3", country = "US", tags = "chill · ambient"),
            Station("fb-us-3", "SomaFM Drone Zone", "https://ice1.somafm.com/dronezone-128-mp3", country = "US", tags = "ambient"),
        ),
        Region.DE to listOf(
            Station("fb-de-1", "1LIVE", "https://wdr-1live-live.icecastssl.wdr.de/wdr/1live/live/mp3/128/stream.mp3", country = "DE", tags = "pop"),
            Station("fb-de-2", "Deutschlandfunk", "https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3", country = "DE", tags = "news"),
            Station("fb-de-3", "SWR3", "https://liveradio.swr.de/sw282p3/swr3/play.mp3", country = "DE", tags = "pop · rock"),
        ),
    )
}
