#!/usr/bin/env python3
"""Ultra-fast music generator using numpy"""
import os
import wave
import struct
import numpy as np

SAMPLE_RATE = 44100
MUSIC_PATH = "/home/user/Velocity/assets/audio/music"

def save_wav(filename, samples):
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        samples = np.clip(samples * 32767, -32767, 32767).astype(np.int16)
        wav.writeframes(samples.tobytes())

def gen_track(name, dur, bpm, key):
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n)

    # Bass
    bass = 0.25 * np.sin(2 * np.pi * key * t)
    bass *= np.sin(2 * np.pi * bpm/60/2 * t) > 0  # Pulse

    # Kick
    kick = np.zeros(n)
    beat_samples = int(SAMPLE_RATE * 60 / bpm)
    for i in range(0, n, beat_samples):
        end = min(i + int(0.1 * SAMPLE_RATE), n)
        kick_t = np.arange(end - i) / SAMPLE_RATE
        kick[i:end] += 0.4 * np.exp(-kick_t * 15) * np.sin(2 * np.pi * 60 * kick_t)

    # Pad
    pad = 0.08 * np.sin(2 * np.pi * key * 2 * t)
    pad += 0.06 * np.sin(2 * np.pi * key * 3 * t)

    # Hihat noise
    hihat = np.random.randn(n) * 0.1
    hihat *= np.sin(2 * np.pi * bpm/60 * t) > 0.7

    # Mix
    mix = bass + kick + pad + hihat
    mix = mix / np.max(np.abs(mix)) * 0.85

    # Stereo
    stereo = np.column_stack([mix * 0.9, mix]).flatten()
    save_wav(os.path.join(MUSIC_PATH, f"{name}.wav"), stereo)
    print(f"Generated: {name}.wav")

if __name__ == "__main__":
    print("Generating music...")
    gen_track("chapter1", 8, 128, 146.83)
    gen_track("chapter2", 8, 135, 164.81)
    gen_track("chapter3", 8, 145, 174.61)
    gen_track("editor", 8, 100, 130.81)
    print("Done!")
