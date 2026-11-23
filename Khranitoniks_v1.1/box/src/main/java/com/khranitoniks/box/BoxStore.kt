package com.khranitoniks.box

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.util.Locale
import java.util.UUID

data class Child(val id: String, val name: String, val key: String, val created: Long)

data class Issued(val time: Long, val childName: String, val minutes: Int, val code: String)

/** Хранилище «Хранитоникс Бокс»: дети (ключи сопряжения), история кодов, PIN родителя. */
class BoxStore(context: Context) {

    private val sp = context.applicationContext.getSharedPreferences("box_prefs", Context.MODE_PRIVATE)

    fun children(): List<Child> = try {
        val arr = JSONArray(sp.getString("children", "[]"))
        (0 until arr.length()).map {
            val o = arr.getJSONObject(it)
            Child(o.getString("id"), o.getString("name"), o.getString("key"), o.optLong("created"))
        }
    } catch (e: Exception) {
        emptyList()
    }

    private fun saveChildren(list: List<Child>) {
        val arr = JSONArray()
        list.forEach {
            arr.put(JSONObject().put("id", it.id).put("name", it.name).put("key", it.key).put("created", it.created))
        }
        sp.edit().putString("children", arr.toString()).apply()
    }

    /** Добавить ребёнка; ключ проверяется и нормализуется. Возвращает null при неверном ключе. */
    fun addChild(name: String, keyText: String): Child? {
        val bytes = CodeCrypto.parseKey(keyText) ?: return null
        val c = Child(UUID.randomUUID().toString(), name.trim().ifEmpty { "?" }, CodeCrypto.formatKey(bytes), System.currentTimeMillis())
        saveChildren(children() + c)
        return c
    }

    fun removeChild(id: String) = saveChildren(children().filterNot { it.id == id })

    fun renameChild(id: String, name: String) =
        saveChildren(children().map { if (it.id == id) it.copy(name = name.trim().ifEmpty { it.name }) else it })

    /** Создать код времени для ребёнка и записать в историю. */
    fun issue(child: Child, optionIndex: Int): String? {
        val key = CodeCrypto.parseKey(child.key) ?: return null
        val code = CodeCrypto.makeCode(key, optionIndex)
        val list = listOf(Issued(System.currentTimeMillis(), child.name, CodeCrypto.OPTIONS[optionIndex], code)) + history()
        val arr = JSONArray()
        list.take(60).forEach {
            arr.put(JSONObject().put("t", it.time).put("n", it.childName).put("m", it.minutes).put("c", it.code))
        }
        sp.edit().putString("history", arr.toString()).apply()
        return code
    }

    fun history(): List<Issued> = try {
        val arr = JSONArray(sp.getString("history", "[]"))
        (0 until arr.length()).map {
            val o = arr.getJSONObject(it)
            Issued(o.getLong("t"), o.optString("n"), o.optInt("m"), o.optString("c"))
        }
    } catch (e: Exception) {
        emptyList()
    }

    fun clearHistory() = sp.edit().remove("history").apply()

    // ---------- PIN родителя (необязательный, SHA-256) ----------
    val hasPin: Boolean get() = sp.getString("pin_hash", "").orEmpty().isNotEmpty()

    fun setPin(pin: String?) {
        if (pin.isNullOrEmpty()) {
            sp.edit().remove("pin_hash").remove("pin_salt").apply()
            return
        }
        val salt = UUID.randomUUID().toString()
        sp.edit().putString("pin_salt", salt).putString("pin_hash", sha256(salt + pin)).apply()
    }

    fun checkPin(pin: String): Boolean {
        val lock = sp.getLong("lock_until", 0L)
        if (System.currentTimeMillis() < lock) return false
        val ok = sha256(sp.getString("pin_salt", "").orEmpty() + pin) == sp.getString("pin_hash", "")
        if (ok) {
            sp.edit().putInt("fails", 0).apply()
        } else {
            val f = sp.getInt("fails", 0) + 1
            if (f >= 3) sp.edit().putInt("fails", 0).putLong("lock_until", System.currentTimeMillis() + 60_000L).apply()
            else sp.edit().putInt("fails", f).apply()
        }
        return ok
    }

    fun lockedSeconds(): Int {
        val left = sp.getLong("lock_until", 0L) - System.currentTimeMillis()
        return if (left > 0) ((left + 999) / 1000).toInt() else 0
    }

    private fun sha256(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.toByteArray(Charsets.UTF_8))
            .joinToString("") { String.format(Locale.US, "%02x", it) }
}
