package com.vibe.radio.audio

/** Голосовые / звуковые эффекты. pitch применяется через Media3 (Sonic), остальное — в FxAudioProcessor. */
enum class VoiceEffect(val title: String, val emoji: String, val pitch: Float) {
    NONE("Обычный", "🎧", 1f),
    ECHO("Эхо", "🏔️", 1f),
    CAVE("Пещера", "🕳️", 1f),
    ROBOT("Робот", "🤖", 1f),
    MONSTER("Монстр", "👹", 0.62f),
    CHILD("Детский", "👶", 1.45f),
    CHIPMUNK("Бурундук", "🐿️", 1.9f),
    ALIEN("Пришелец", "👽", 1.2f),
    TELEPHONE("Телефон", "📞", 1f),
    UNDERWATER("Под водой", "🌊", 1f),
    BASS("Мега-бас", "🔊", 1f),
    STADIUM("Стадион", "🏟️", 1f),
}

/** Общее состояние между сервисом воспроизведения и UI (один процесс). */
object AudioFx {
    @Volatile var effect: VoiceEffect = VoiceEffect.NONE

    /** Громкость текущего звука 0..1 (RMS) — для анимации танцоров. */
    @Volatile var level: Float = 0f

    /** Энергия низких частот 0..1 — «бит». */
    @Volatile var bass: Float = 0f
}
