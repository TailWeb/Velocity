#!/usr/bin/env python3
"""
Velocity - Audio Generator
Generates all SFX and music tracks using procedural synthesis
Style: Synthwave / Cyberpunk
"""

import os
import wave
import struct
import math
import random

# Audio settings
SAMPLE_RATE = 44100
CHANNELS = 2  # Stereo

# Output directories
SFX_PATH = "/home/user/Velocity/assets/audio/sfx"
MUSIC_PATH = "/home/user/Velocity/assets/audio/music"

os.makedirs(SFX_PATH, exist_ok=True)
os.makedirs(MUSIC_PATH, exist_ok=True)

def save_wav(filename, samples, sample_rate=SAMPLE_RATE, channels=1):
    """Save samples as a WAV file"""
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(channels)
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(sample_rate)

        # Convert to bytes
        if channels == 1:
            data = struct.pack('<' + 'h' * len(samples), *[int(max(-32767, min(32767, s * 32767))) for s in samples])
        else:
            # Interleave stereo samples
            data = b''
            for i in range(len(samples) // 2):
                left = int(max(-32767, min(32767, samples[i*2] * 32767)))
                right = int(max(-32767, min(32767, samples[i*2+1] * 32767)))
                data += struct.pack('<hh', left, right)

        wav.writeframes(data)

def sine_wave(freq, duration, volume=0.5, sample_rate=SAMPLE_RATE):
    """Generate a sine wave"""
    samples = []
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        sample = volume * math.sin(2 * math.pi * freq * t)
        samples.append(sample)
    return samples

def square_wave(freq, duration, volume=0.3, sample_rate=SAMPLE_RATE):
    """Generate a square wave"""
    samples = []
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        sample = volume * (1 if math.sin(2 * math.pi * freq * t) > 0 else -1)
        samples.append(sample)
    return samples

def sawtooth_wave(freq, duration, volume=0.3, sample_rate=SAMPLE_RATE):
    """Generate a sawtooth wave"""
    samples = []
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        sample = volume * (2 * (t * freq - math.floor(0.5 + t * freq)))
        samples.append(sample)
    return samples

def noise(duration, volume=0.3, sample_rate=SAMPLE_RATE):
    """Generate white noise"""
    samples = []
    for _ in range(int(sample_rate * duration)):
        samples.append(volume * (random.random() * 2 - 1))
    return samples

def apply_envelope(samples, attack=0.01, decay=0.1, sustain=0.7, release=0.2):
    """Apply ADSR envelope to samples"""
    total = len(samples)
    attack_samples = int(attack * SAMPLE_RATE)
    decay_samples = int(decay * SAMPLE_RATE)
    release_samples = int(release * SAMPLE_RATE)
    sustain_samples = total - attack_samples - decay_samples - release_samples

    result = []
    for i, sample in enumerate(samples):
        if i < attack_samples:
            # Attack
            env = i / attack_samples
        elif i < attack_samples + decay_samples:
            # Decay
            progress = (i - attack_samples) / decay_samples
            env = 1 - (1 - sustain) * progress
        elif i < attack_samples + decay_samples + sustain_samples:
            # Sustain
            env = sustain
        else:
            # Release
            progress = (i - attack_samples - decay_samples - sustain_samples) / release_samples
            env = sustain * (1 - progress)

        result.append(sample * env)

    return result

def lowpass_filter(samples, cutoff=0.1):
    """Simple lowpass filter"""
    result = [samples[0]]
    for i in range(1, len(samples)):
        result.append(result[-1] + cutoff * (samples[i] - result[-1]))
    return result

def mix_samples(*sample_lists):
    """Mix multiple sample lists together"""
    max_len = max(len(s) for s in sample_lists)
    result = [0] * max_len

    for samples in sample_lists:
        for i, s in enumerate(samples):
            result[i] += s

    # Normalize
    max_val = max(abs(s) for s in result) or 1
    if max_val > 1:
        result = [s / max_val for s in result]

    return result

def pitch_sweep(start_freq, end_freq, duration, wave_func=sine_wave, volume=0.5):
    """Generate a pitch sweep"""
    samples = []
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = start_freq + (end_freq - start_freq) * progress
        sample = volume * math.sin(2 * math.pi * freq * t)
        samples.append(sample)
    return samples

# ============================================
# SOUND EFFECTS
# ============================================

def generate_jump():
    """Jump sound - quick rising tone"""
    samples = pitch_sweep(200, 600, 0.12, volume=0.4)
    samples = apply_envelope(samples, attack=0.005, decay=0.05, sustain=0.3, release=0.06)

    # Add some noise for texture
    n = noise(0.12, 0.08)
    n = apply_envelope(n, attack=0.001, decay=0.02, sustain=0.1, release=0.08)

    samples = mix_samples(samples, n)
    save_wav(os.path.join(SFX_PATH, "jump.wav"), samples)
    print("Generated: jump.wav")

def generate_double_jump():
    """Double jump - higher pitched, sparkly"""
    samples = pitch_sweep(400, 900, 0.15, volume=0.4)
    samples = apply_envelope(samples, attack=0.005, decay=0.04, sustain=0.3, release=0.08)

    # Sparkle harmonics
    h1 = pitch_sweep(800, 1400, 0.1, volume=0.15)
    h2 = pitch_sweep(1200, 1800, 0.08, volume=0.1)

    samples = mix_samples(samples, h1, h2)
    save_wav(os.path.join(SFX_PATH, "double_jump.wav"), samples)
    print("Generated: double_jump.wav")

def generate_dash():
    """Dash sound - whoosh with energy"""
    # Filtered noise whoosh
    n = noise(0.2, 0.5)
    n = lowpass_filter(n, 0.15)
    n = apply_envelope(n, attack=0.01, decay=0.05, sustain=0.4, release=0.1)

    # Low frequency punch
    bass = sine_wave(80, 0.15, 0.4)
    bass = apply_envelope(bass, attack=0.005, decay=0.05, sustain=0.2, release=0.08)

    # Synth sweep
    sweep = pitch_sweep(300, 150, 0.18, volume=0.25)
    sweep = apply_envelope(sweep, attack=0.01, decay=0.08, sustain=0.3, release=0.06)

    samples = mix_samples(n, bass, sweep)
    save_wav(os.path.join(SFX_PATH, "dash.wav"), samples)
    print("Generated: dash.wav")

def generate_wall_slide():
    """Wall slide - friction sound"""
    n = noise(0.3, 0.2)
    n = lowpass_filter(n, 0.08)
    n = apply_envelope(n, attack=0.02, decay=0.1, sustain=0.5, release=0.15)

    # Add some grit
    for i in range(len(n)):
        if random.random() > 0.95:
            n[i] *= 2

    save_wav(os.path.join(SFX_PATH, "wall_slide.wav"), n)
    print("Generated: wall_slide.wav")

def generate_wall_jump():
    """Wall jump - punchy with direction"""
    samples = pitch_sweep(250, 550, 0.1, volume=0.4)
    samples = apply_envelope(samples, attack=0.005, decay=0.03, sustain=0.4, release=0.05)

    # Impact
    impact = noise(0.05, 0.3)
    impact = lowpass_filter(impact, 0.2)
    impact = apply_envelope(impact, attack=0.001, decay=0.02, sustain=0.2, release=0.02)

    samples = mix_samples(samples, impact)
    save_wav(os.path.join(SFX_PATH, "wall_jump.wav"), samples)
    print("Generated: wall_jump.wav")

def generate_land():
    """Landing sound - thud"""
    # Low thud
    bass = sine_wave(60, 0.1, 0.5)
    bass = apply_envelope(bass, attack=0.001, decay=0.03, sustain=0.2, release=0.06)

    # Impact noise
    n = noise(0.08, 0.25)
    n = lowpass_filter(n, 0.15)
    n = apply_envelope(n, attack=0.001, decay=0.02, sustain=0.15, release=0.05)

    samples = mix_samples(bass, n)
    save_wav(os.path.join(SFX_PATH, "land.wav"), samples)
    print("Generated: land.wav")

def generate_death():
    """Death sound - dramatic descending"""
    # Main descending tone
    samples = pitch_sweep(400, 80, 0.5, volume=0.4)
    samples = apply_envelope(samples, attack=0.01, decay=0.1, sustain=0.5, release=0.3)

    # Distortion/glitch
    n = noise(0.4, 0.3)
    for i in range(len(n)):
        t = i / SAMPLE_RATE
        n[i] *= max(0, 1 - t * 2)

    # Low rumble
    bass = sine_wave(50, 0.5, 0.3)
    bass = apply_envelope(bass, attack=0.02, decay=0.15, sustain=0.3, release=0.3)

    samples = mix_samples(samples, n, bass)
    save_wav(os.path.join(SFX_PATH, "death.wav"), samples)
    print("Generated: death.wav")

def generate_respawn():
    """Respawn sound - ascending, hopeful"""
    samples = pitch_sweep(200, 600, 0.3, volume=0.35)
    samples = apply_envelope(samples, attack=0.02, decay=0.1, sustain=0.5, release=0.15)

    # Shimmer
    h1 = pitch_sweep(400, 1000, 0.25, volume=0.15)
    h1 = apply_envelope(h1, attack=0.05, decay=0.1, sustain=0.4, release=0.1)

    h2 = sine_wave(800, 0.2, 0.1)
    h2 = apply_envelope(h2, attack=0.08, decay=0.05, sustain=0.3, release=0.07)

    samples = mix_samples(samples, h1, h2)
    save_wav(os.path.join(SFX_PATH, "respawn.wav"), samples)
    print("Generated: respawn.wav")

def generate_checkpoint():
    """Checkpoint activation - positive chime"""
    # Major chord arpeggio
    c = sine_wave(523, 0.15, 0.3)  # C5
    e = sine_wave(659, 0.15, 0.25)  # E5
    g = sine_wave(784, 0.15, 0.25)  # G5

    # Offset them
    e = [0] * int(0.05 * SAMPLE_RATE) + e
    g = [0] * int(0.1 * SAMPLE_RATE) + g

    samples = mix_samples(c, e, g)
    samples = apply_envelope(samples, attack=0.01, decay=0.05, sustain=0.6, release=0.1)

    save_wav(os.path.join(SFX_PATH, "checkpoint.wav"), samples)
    print("Generated: checkpoint.wav")

def generate_level_complete():
    """Level complete - triumphant fanfare"""
    # Ascending chord progression
    notes = [
        (523, 0.15),  # C5
        (659, 0.15),  # E5
        (784, 0.15),  # G5
        (1047, 0.3),  # C6
    ]

    all_samples = []
    offset = 0

    for freq, dur in notes:
        tone = sine_wave(freq, dur, 0.35)
        tone = apply_envelope(tone, attack=0.01, decay=0.03, sustain=0.7, release=0.1)

        # Add harmonic
        h = sine_wave(freq * 2, dur, 0.15)
        h = apply_envelope(h, attack=0.02, decay=0.05, sustain=0.5, release=0.08)

        combined = mix_samples(tone, h)
        all_samples.append([0] * offset + combined)
        offset += int(0.12 * SAMPLE_RATE)

    samples = mix_samples(*all_samples)
    save_wav(os.path.join(SFX_PATH, "level_complete.wav"), samples)
    print("Generated: level_complete.wav")

def generate_star_collect():
    """Star collection - sparkly pickup"""
    samples = pitch_sweep(800, 1200, 0.1, volume=0.3)
    samples = apply_envelope(samples, attack=0.005, decay=0.03, sustain=0.4, release=0.05)

    # Sparkle
    sparkle = sine_wave(1500, 0.08, 0.2)
    sparkle = apply_envelope(sparkle, attack=0.01, decay=0.02, sustain=0.3, release=0.04)

    samples = mix_samples(samples, sparkle)
    save_wav(os.path.join(SFX_PATH, "star_collect.wav"), samples)
    print("Generated: star_collect.wav")

def generate_ui_select():
    """UI selection - soft click"""
    samples = sine_wave(800, 0.05, 0.25)
    samples = apply_envelope(samples, attack=0.002, decay=0.01, sustain=0.3, release=0.03)
    save_wav(os.path.join(SFX_PATH, "ui_select.wav"), samples)
    print("Generated: ui_select.wav")

def generate_ui_confirm():
    """UI confirm - positive beep"""
    samples = pitch_sweep(600, 900, 0.08, volume=0.3)
    samples = apply_envelope(samples, attack=0.005, decay=0.02, sustain=0.4, release=0.04)
    save_wav(os.path.join(SFX_PATH, "ui_confirm.wav"), samples)
    print("Generated: ui_confirm.wav")

def generate_ui_back():
    """UI back - descending tone"""
    samples = pitch_sweep(600, 400, 0.08, volume=0.25)
    samples = apply_envelope(samples, attack=0.005, decay=0.02, sustain=0.4, release=0.04)
    save_wav(os.path.join(SFX_PATH, "ui_back.wav"), samples)
    print("Generated: ui_back.wav")

def generate_ui_hover():
    """UI hover - subtle tick"""
    samples = sine_wave(1000, 0.03, 0.15)
    samples = apply_envelope(samples, attack=0.001, decay=0.01, sustain=0.2, release=0.015)
    save_wav(os.path.join(SFX_PATH, "ui_hover.wav"), samples)
    print("Generated: ui_hover.wav")

def generate_medal_sounds():
    """Generate medal achievement sounds"""
    # Bronze
    samples = pitch_sweep(400, 500, 0.2, volume=0.3)
    samples = apply_envelope(samples, attack=0.01, decay=0.05, sustain=0.5, release=0.1)
    save_wav(os.path.join(SFX_PATH, "medal_bronze.wav"), samples)

    # Silver
    samples = pitch_sweep(500, 650, 0.25, volume=0.35)
    h = sine_wave(1000, 0.2, 0.15)
    samples = mix_samples(samples, h)
    samples = apply_envelope(samples, attack=0.01, decay=0.05, sustain=0.5, release=0.12)
    save_wav(os.path.join(SFX_PATH, "medal_silver.wav"), samples)

    # Gold
    notes = [sine_wave(523, 0.12, 0.3), sine_wave(659, 0.12, 0.3), sine_wave(784, 0.15, 0.35)]
    offset = 0
    all_s = []
    for n in notes:
        n = apply_envelope(n, attack=0.01, decay=0.03, sustain=0.6, release=0.05)
        all_s.append([0] * offset + n)
        offset += int(0.08 * SAMPLE_RATE)
    samples = mix_samples(*all_s)
    save_wav(os.path.join(SFX_PATH, "medal_gold.wav"), samples)

    # Platinum - epic
    samples = []
    for i, freq in enumerate([523, 659, 784, 1047]):
        tone = sine_wave(freq, 0.2 + i * 0.05, 0.25)
        tone = apply_envelope(tone, attack=0.01, decay=0.03, sustain=0.6, release=0.08)
        h = sine_wave(freq * 2, 0.15 + i * 0.03, 0.12)
        h = apply_envelope(h, attack=0.02, decay=0.03, sustain=0.4, release=0.05)
        combined = mix_samples(tone, h)
        samples.append([0] * int(i * 0.07 * SAMPLE_RATE) + combined)
    samples = mix_samples(*samples)
    save_wav(os.path.join(SFX_PATH, "medal_platinum.wav"), samples)

    print("Generated: medal sounds")

# ============================================
# MUSIC
# ============================================

def generate_synthwave_loop(name, duration=30, bpm=120, key_freq=130.81):
    """Generate a synthwave music loop"""
    samples_per_beat = int(SAMPLE_RATE * 60 / bpm)
    total_samples = int(SAMPLE_RATE * duration)

    # Initialize stereo output
    left = [0] * total_samples
    right = [0] * total_samples

    # Bass line pattern
    bass_pattern = [1, 0, 0.8, 0, 1, 0.5, 0.8, 0]
    bass_notes = [key_freq, key_freq, key_freq * 1.5, key_freq * 1.25]

    # Generate bass
    beat = 0
    for i in range(0, total_samples, samples_per_beat // 2):
        pattern_idx = beat % len(bass_pattern)
        note_idx = (beat // 8) % len(bass_notes)
        volume = bass_pattern[pattern_idx] * 0.35

        if volume > 0:
            freq = bass_notes[note_idx]
            dur = (samples_per_beat // 2) / SAMPLE_RATE
            bass = sawtooth_wave(freq, dur, volume)
            bass = lowpass_filter(bass, 0.08)
            bass = apply_envelope(bass, attack=0.01, decay=0.05, sustain=0.6, release=0.1)

            for j, s in enumerate(bass):
                if i + j < total_samples:
                    left[i + j] += s * 0.9
                    right[i + j] += s * 0.9

        beat += 1

    # Kick drum on beats 1 and 3
    for i in range(0, total_samples, samples_per_beat):
        kick = sine_wave(60, 0.15, 0.5)
        kick_click = noise(0.02, 0.3)
        kick_click = lowpass_filter(kick_click, 0.3)
        kick = mix_samples(kick, kick_click)
        kick = apply_envelope(kick, attack=0.001, decay=0.05, sustain=0.3, release=0.1)

        for j, s in enumerate(kick):
            if i + j < total_samples:
                left[i + j] += s
                right[i + j] += s

    # Hi-hat on off-beats
    for i in range(samples_per_beat // 2, total_samples, samples_per_beat):
        hihat = noise(0.05, 0.15)
        hihat = apply_envelope(hihat, attack=0.001, decay=0.02, sustain=0.1, release=0.03)

        for j, s in enumerate(hihat):
            if i + j < total_samples:
                left[i + j] += s * 0.7
                right[i + j] += s * 1.0

    # Snare on beats 2 and 4
    for i in range(samples_per_beat, total_samples, samples_per_beat * 2):
        snare = noise(0.12, 0.35)
        snare_tone = sine_wave(180, 0.1, 0.25)
        snare = mix_samples(snare, snare_tone)
        snare = apply_envelope(snare, attack=0.001, decay=0.04, sustain=0.2, release=0.08)

        for j, s in enumerate(snare):
            if i + j < total_samples:
                left[i + j] += s
                right[i + j] += s

    # Synth pad
    pad_freqs = [key_freq * 2, key_freq * 2.5, key_freq * 3]
    for k, freq in enumerate(pad_freqs):
        pad = sine_wave(freq, duration, 0.08)
        # Slow modulation
        for i in range(len(pad)):
            t = i / SAMPLE_RATE
            pad[i] *= 0.7 + 0.3 * math.sin(2 * math.pi * 0.2 * t + k)

        pan = 0.3 + k * 0.35  # Pan across stereo
        for i, s in enumerate(pad):
            left[i] += s * (1 - pan)
            right[i] += s * pan

    # Lead arpeggio
    arp_notes = [1, 1.25, 1.5, 2, 1.5, 1.25]
    arp_idx = 0
    for i in range(0, total_samples, samples_per_beat // 4):
        if random.random() > 0.3:  # Some randomness
            freq = key_freq * 4 * arp_notes[arp_idx % len(arp_notes)]
            arp = square_wave(freq, 0.08, 0.12)
            arp = lowpass_filter(arp, 0.4)
            arp = apply_envelope(arp, attack=0.01, decay=0.02, sustain=0.5, release=0.04)

            pan = 0.3 + 0.4 * math.sin(i / SAMPLE_RATE * 0.5)
            for j, s in enumerate(arp):
                if i + j < total_samples:
                    left[i + j] += s * (1 - pan)
                    right[i + j] += s * pan

        arp_idx += 1

    # Normalize and interleave
    max_val = max(max(abs(s) for s in left), max(abs(s) for s in right)) or 1
    if max_val > 0.9:
        scale = 0.9 / max_val
        left = [s * scale for s in left]
        right = [s * scale for s in right]

    # Interleave stereo
    stereo = []
    for i in range(total_samples):
        stereo.append(left[i])
        stereo.append(right[i])

    save_wav(os.path.join(MUSIC_PATH, f"{name}.wav"), stereo, channels=2)
    print(f"Generated: {name}.wav")

# ============================================
# MAIN
# ============================================

if __name__ == "__main__":
    print("Generating Velocity audio assets...")
    print("=" * 40)

    # Generate all SFX
    print("\n--- Sound Effects ---")
    generate_jump()
    generate_double_jump()
    generate_dash()
    generate_wall_slide()
    generate_wall_jump()
    generate_land()
    generate_death()
    generate_respawn()
    generate_checkpoint()
    generate_level_complete()
    generate_star_collect()
    generate_ui_select()
    generate_ui_confirm()
    generate_ui_back()
    generate_ui_hover()
    generate_medal_sounds()

    # Generate music tracks
    print("\n--- Music Tracks ---")
    generate_synthwave_loop("menu", duration=20, bpm=110, key_freq=130.81)
    generate_synthwave_loop("chapter1", duration=30, bpm=128, key_freq=146.83)
    generate_synthwave_loop("chapter2", duration=30, bpm=135, key_freq=164.81)
    generate_synthwave_loop("chapter3", duration=30, bpm=145, key_freq=174.61)
    generate_synthwave_loop("editor", duration=25, bpm=100, key_freq=130.81)

    print("\n" + "=" * 40)
    print("Audio generation complete!")
