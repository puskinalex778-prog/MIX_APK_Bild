#!/usr/bin/env python3
"""Синтез музыки и звуковых эффектов (оригинальные, без сторонних сэмплов).
Пишет OGG Vorbis в project/assets/audio/{music,sfx}. Требуется numpy и ffmpeg."""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "project", "assets", "audio"))


def save(path, sig, quality=4):
    sig = np.clip(sig, -1, 1)
    pcm = (sig * 32000).astype(np.int16)
    if pcm.ndim == 1:
        pcm = np.stack([pcm, pcm], axis=1)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp = f.name
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
    os.unlink(tmp)


def env(n, a=0.01, d=0.1, s=0.6, r=0.2):
    t = np.arange(n) / SR
    dur = n / SR
    e = np.ones(n) * s
    e[t < a] = t[t < a] / a
    m = (t >= a) & (t < a + d)
    e[m] = 1 - (1 - s) * (t[m] - a) / d
    rel = t > dur - r
    e[rel] *= np.clip((dur - t[rel]) / r, 0, 1)
    return e


def tone(freq, dur, kind="sine", vol=0.5, a=0.01, d=0.1, s=0.6, r=0.15):
    n = int(SR * dur)
    t = np.arange(n) / SR
    ph = 2 * np.pi * freq * t
    if kind == "sine":
        w = np.sin(ph)
    elif kind == "tri":
        w = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == "bell":
        w = np.sin(ph) * 0.7 + np.sin(ph * 2.0) * 0.2 * np.exp(-t * 6) + np.sin(ph * 3.01) * 0.1 * np.exp(-t * 9)
    elif kind == "pluck":
        w = (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.25 * np.sin(3 * ph)) * np.exp(-t * 5)
    elif kind == "pad":
        w = (np.sin(ph) + 0.5 * np.sin(ph * 1.005) + 0.3 * np.sin(ph * 2.0)) / 1.8
    else:
        w = np.sign(np.sin(ph)) * 0.4
    return w * env(n, a, d, s, r) * vol


def note(n):  # midi -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def mix_at(buf, sig, start):
    i = int(start * SR)
    j = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:j] += sig[: j - i]


def music(path, bpm, chords, melody, lead="bell", bass_kind="tri", bars_rep=2, pad_vol=0.12, swing=0.0):
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * len(chords) * bars_rep
    buf = np.zeros(int(SR * total) + SR)
    for rep in range(bars_rep):
        for ci, ch in enumerate(chords):
            t0 = (rep * len(chords) + ci) * bar
            for nn in ch:
                mix_at(buf, tone(note(nn), bar, "pad", pad_vol, 0.3, 0.3, 0.8, 0.4), t0)
            mix_at(buf, tone(note(ch[0] - 12), beat * 1.8, bass_kind, 0.22, 0.01, 0.2, 0.5, 0.2), t0)
            mix_at(buf, tone(note(ch[0] - 12), beat * 1.8, bass_kind, 0.18, 0.01, 0.2, 0.5, 0.2), t0 + beat * 2)
            # лёгкая перкуссия: шорох
            for b in range(4):
                n = int(SR * 0.05)
                hat = np.random.RandomState(ci * 4 + b).randn(n) * np.exp(-np.arange(n) / (SR * 0.01)) * 0.04
                mix_at(buf, hat, t0 + b * beat + beat * 0.5)
    t = 0.0
    for rep in range(bars_rep):
        for (nn, dur) in melody:
            if nn is not None:
                mix_at(buf, tone(note(nn), dur * beat * 1.1, lead, 0.2, 0.005, 0.15, 0.4, 0.2), t)
            t += dur * beat
    buf = buf[: int(SR * total)]
    # мягкий «реверб» — несколько задержек
    out = buf.copy()
    for dl, g in [(0.11, 0.25), (0.23, 0.15), (0.37, 0.08)]:
        k = int(dl * SR)
        out[k:] += buf[:-k] * g
    # сглаживаем стык цикла
    fade = int(0.05 * SR)
    out[:fade] *= np.linspace(0, 1, fade)
    out[-fade:] *= np.linspace(1, 0, fade)
    out /= max(1e-6, np.max(np.abs(out))) / 0.7
    save(path, out, 3)


def sfx():
    d = os.path.join(ROOT, "sfx")
    os.makedirs(d, exist_ok=True)
    save(f"{d}/click.ogg", tone(1200, 0.06, "sine", 0.4, 0.001, 0.03, 0.2, 0.03))
    save(f"{d}/tick.ogg", tone(1800, 0.035, "sine", 0.25, 0.001, 0.02, 0.1, 0.01))
    save(f"{d}/pop.ogg", np.concatenate([tone(600 + i * 60, 0.012, "sine", 0.4, 0.001, 0.005, 0.8, 0.003) for i in range(8)]))
    c = np.zeros(int(SR * 0.6))
    for i, n in enumerate([72, 76, 79, 84]):
        mix_at(c, tone(note(n), 0.35, "bell", 0.35, 0.005, 0.1, 0.4, 0.2), i * 0.07)
    save(f"{d}/correct.ogg", c)
    w = np.zeros(int(SR * 0.5))
    mix_at(w, tone(note(64), 0.22, "tri", 0.3, 0.01, 0.1, 0.5, 0.1), 0)
    mix_at(w, tone(note(60), 0.3, "tri", 0.3, 0.01, 0.1, 0.5, 0.15), 0.16)
    save(f"{d}/wrong.ogg", w)
    a = np.zeros(int(SR * 1.4))
    for i, n in enumerate([67, 72, 76, 79, 84, 88]):
        mix_at(a, tone(note(n), 0.6, "bell", 0.3, 0.005, 0.2, 0.4, 0.3), i * 0.09)
    for n in [72, 76, 79]:
        mix_at(a, tone(note(n), 0.8, "pad", 0.15, 0.05, 0.2, 0.6, 0.4), 0.55)
    save(f"{d}/achievement.ogg", a)
    lv = np.zeros(int(SR * 1.2))
    for i, n in enumerate([60, 64, 67, 72, 67, 72, 76]):
        mix_at(lv, tone(note(n), 0.3, "pluck", 0.35), i * 0.1)
    save(f"{d}/levelup.ogg", lv)
    save(f"{d}/star.ogg", tone(note(88), 0.4, "bell", 0.35, 0.002, 0.1, 0.3, 0.25))
    n = int(SR * 0.35)
    noise = np.random.RandomState(1).randn(n)
    sweep = np.convolve(noise, np.ones(30) / 30, mode="same") * np.sin(np.linspace(0, np.pi, n)) * 0.5
    save(f"{d}/whoosh.ogg", sweep)
    u = np.zeros(int(SR * 0.5))
    mix_at(u, tone(note(76), 0.2, "bell", 0.3), 0)
    mix_at(u, tone(note(83), 0.35, "bell", 0.3), 0.1)
    save(f"{d}/unlock.ogg", u)
    ch = np.zeros(int(SR * 1.5))
    for i, nn in enumerate([79, 84]):
        mix_at(ch, tone(note(nn), 1.2, "bell", 0.3, 0.005, 0.3, 0.3, 0.8), i * 0.25)
    save(f"{d}/chime.ogg", ch)
    st = np.random.RandomState(2).randn(int(SR * 0.08)) * np.exp(-np.arange(int(SR * 0.08)) / (SR * 0.015)) * 0.3
    save(f"{d}/step.ogg", np.convolve(st, np.ones(12) / 12, mode="same"))
    sp = np.zeros(int(SR * 0.5))
    for i in range(5):
        mix_at(sp, tone(note(84 + i * 2), 0.15, "bell", 0.2, 0.002, 0.05, 0.3, 0.1), i * 0.05)
    save(f"{d}/sparkle.ogg", sp)


def all_music():
    d = os.path.join(ROOT, "music")
    os.makedirs(d, exist_ok=True)
    C, Am, F, G, Dm, Em = [60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62], [50, 53, 57], [52, 55, 59]
    mel_menu = [(72, 1), (74, 0.5), (76, 0.5), (79, 1), (76, 1), (74, 1), (72, 0.5), (74, 0.5), (76, 2),
                (77, 1), (76, 0.5), (74, 0.5), (72, 1), (69, 1), (71, 1), (72, 1), (74, 2)]
    music(f"{d}/menu.ogg", 96, [C, Am, F, G], mel_menu, "bell", bars_rep=3)
    mel_map = [(67, 0.5), (69, 0.5), (72, 1), (69, 0.5), (67, 0.5), (64, 1), (65, 0.5), (67, 0.5), (69, 1), (67, 2),
               (72, 0.5), (74, 0.5), (76, 1), (74, 0.5), (72, 0.5), (69, 1), (71, 0.5), (72, 0.5), (74, 1), (72, 2)]
    music(f"{d}/map.ogg", 108, [C, G, Am, F], mel_map, "pluck", bars_rep=3)
    mel_lesson = [(None, 1), (76, 1), (None, 1), (79, 1), (None, 2), (74, 2), (None, 1), (72, 1), (None, 1), (71, 1), (None, 4),
                  (None, 1), (69, 1), (None, 1), (72, 1)]
    music(f"{d}/lesson.ogg", 72, [F, C, Dm, G], mel_lesson, "bell", bars_rep=3, pad_vol=0.1)
    mel_break = [(72, 2), (67, 2), (69, 2), (64, 2), (65, 2), (60, 2), (65, 2), (67, 2)]
    music(f"{d}/break.ogg", 60, [C, Em, F, G], mel_break, "bell", bars_rep=2, pad_vol=0.14)


if __name__ == "__main__":
    sfx()
    all_music()
    print("audio ok")
