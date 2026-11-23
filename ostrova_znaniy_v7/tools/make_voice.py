#!/usr/bin/env python3
"""Офлайн-озвучка английских слов и фраз (eSpeak NG) -> project/assets/audio/voice/*.ogg + index.json."""
import glob, hashlib, json, os, subprocess
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "project"))
OUT = os.path.join(ROOT, "assets", "audio", "voice")
os.makedirs(OUT, exist_ok=True)
texts = set(["Hello! Let's learn English!"])
for f in glob.glob(os.path.join(ROOT, "data", "content", "g*_eng.json")):
    for tasks in json.load(open(f, encoding="utf-8"))["topics"].values():
        for t in tasks:
            if t.get("audio"):
                texts.add(t["audio"])
index = {}
for tx in sorted(texts):
    name = hashlib.sha1(tx.encode()).hexdigest()[:12] + ".ogg"
    p = os.path.join(OUT, name)
    if not os.path.exists(p):
        wav = p + ".wav"
        subprocess.run(["espeak-ng", "-v", "en-gb", "-s", "130", "-w", wav, tx], check=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af", "loudnorm", "-c:a", "libvorbis", "-q:a", "3", p], check=True)
        os.remove(wav)
    index[tx] = name
json.dump(index, open(os.path.join(OUT, "index.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)
print("voice files:", len(index))
