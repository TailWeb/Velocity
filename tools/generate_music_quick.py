#!/usr/bin/env python3
"""Quick music generator - shorter tracks for faster generation"""

import os
import wave
import struct
import math
import random

SAMPLE_RATE = 44100
MUSIC_PATH = "/home/user/Velocity/assets/audio/music"

def save_wav(filename, samples, channels=2):
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(channels)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        if channels == 1:
            data = struct.pack('<' + 'h' * len(samples), *[int(max(-32767, min(32767, s * 32767))) for s in samples])
        else:
            data = b''
            for i in range(len(samples) // 2):
                left = int(max(-32767, min(32767, samples[i*2] * 32767)))
                right = int(max(-32767, min(32767, samples[i*2+1] * 32767)))
                data += struct.pack('<hh', left, right)
        wav.writeframes(data)

def generate_track(name, duration, bpm, key):
    """Generate a synthwave track"""
    samples_per_beat = int(SAMPLE_RATE * 60 / bpm)
    total_samples = int(SAMPLE_RATE * duration)

    left = [0.0] * total_samples
    right = [0.0] * total_samples

    # Bass
    bass_pattern = [1, 0, 0.7, 0, 1, 0.5, 0.7, 0.3]
    for beat in range(int(duration * bpm / 60 * 2)):
        i = beat * (samples_per_beat // 2)
        if i >= total_samples:
            break
        vol = bass_pattern[beat % 8] * 0.3
        if vol > 0:
            freq = key
            for j in range(min(samples_per_beat // 2, total_samples - i)):
                t = j / SAMPLE_RATE
                env = max(0, 1 - t * 8)
                s = vol * env * (2 * (t * freq - math.floor(0.5 + t * freq)))
                left[i + j] += s * 0.8
                right[i + j] += s * 0.8

    # Kick
    for beat in range(int(duration * bpm / 60)):
        i = beat * samples_per_beat
        if i >= total_samples:
            break
        for j in range(min(int(0.15 * SAMPLE_RATE), total_samples - i)):
            t = j / SAMPLE_RATE
            env = max(0, 1 - t * 7)
            s = 0.5 * env * math.sin(2 * math.pi * 60 * t)
            left[i + j] += s
            right[i + j] += s

    # Hihat
    for beat in range(int(duration * bpm / 60 * 2)):
        i = beat * (samples_per_beat // 2) + samples_per_beat // 4
        if i >= total_samples:
            break
        for j in range(min(int(0.05 * SAMPLE_RATE), total_samples - i)):
            t = j / SAMPLE_RATE
            env = max(0, 1 - t * 20)
            s = 0.15 * env * (random.random() * 2 - 1)
            left[i + j] += s * 0.6
            right[i + j] += s

    # Pad
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        s = 0.08 * math.sin(2 * math.pi * key * 2 * t)
        s += 0.06 * math.sin(2 * math.pi * key * 3 * t)
        s *= 0.7 + 0.3 * math.sin(2 * math.pi * 0.25 * t)
        left[i] += s * 0.7
        right[i] += s

    # Normalize
    max_val = max(max(abs(s) for s in left), max(abs(s) for s in right))
    if max_val > 0.9:
        scale = 0.85 / max_val
        left = [s * scale for s in left]
        right = [s * scale for s in right]

    # Interleave
    stereo = []
    for i in range(total_samples):
        stereo.append(left[i])
        stereo.append(right[i])

    save_wav(os.path.join(MUSIC_PATH, f"{name}.wav"), stereo, channels=2)
    print(f"Generated: {name}.wav")

if __name__ == "__main__":
    print("Generating music tracks...")
    generate_track("chapter1", 10, 128, 146.83)
    generate_track("chapter2", 10, 135, 164.81)
    generate_track("chapter3", 10, 145, 174.61)
    generate_track("editor", 10, 100, 130.81)
    print("Done!")
