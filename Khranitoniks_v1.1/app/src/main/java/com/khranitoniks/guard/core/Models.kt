package com.khranitoniks.guard.core

/** Персонажи для уведомлений и экранов блокировки. */
enum class CharacterKind(val key: String) {
    SEMA("sema"),
    TIMMA("timma"),
    OLEZHKA("olezhka"),
    HRONI("hroni");

    companion object {
        fun of(name: String?): CharacterKind = entries.firstOrNull { it.name == name } ?: HRONI
    }
}

/** Эмоция/действие персонажа — подбирается под текст уведомления. */
enum class Mood(val key: String) {
    HAPPY("happy"),
    CHARGED("charged"),
    BREAK("break"),
    STOP("stop"),
    CHARGING("charging"),
    LOW("low"),
    SLEEP("sleep"),
    ANGRY("angry"),
    GAMER("gamer"),
    HOT("hot")
}

enum class OverlayTheme {
    DARK, LIGHT, NEON;

    companion object {
        fun of(name: String?): OverlayTheme = entries.firstOrNull { it.name == name } ?: DARK
    }
}

/** Причина блокировки экрана. */
enum class BlockReason {
    BREAK, LIMIT, NIGHT, SETTINGS_LOCK, ACCESS_BREAK, ACCESS_DONE, CHARGING
}

/** Отслеживаемое приложение (группа пакетов разных версий/регионов). */
data class TrackedApp(
    val id: String,
    val name: String,
    val packages: List<String>,
    val builtIn: Boolean,
    val color: Long
)

/** Запись журнала событий. */
data class LogEntry(val time: Long, val type: String, val text: String)

/** Статистика одного дня. */
data class DayRecord(
    val day: String,
    val screenMs: Long,
    val apps: Map<String, Long>
)

object LogType {
    const val CHARGE_INTERRUPTED = "charge_interrupted"
    const val CHARGED = "charged"
    const val EMERGENCY_UNLOCK = "emergency_unlock"
    const val BONUS = "bonus"
    const val PIN_FAILED = "pin_failed"
    const val PIN_LOCKOUT = "pin_lockout"
    const val CODE_OK = "code_ok"
    const val CODE_FAILED = "code_failed"
    const val NIGHT_UNLOCK = "night_unlock"
    const val SETTINGS_UNLOCK = "settings_unlock"
    const val ADMIN = "admin"
    const val GAME_MODE = "game_mode"
    const val CLEAN = "clean"
    const val INFO = "info"
}
