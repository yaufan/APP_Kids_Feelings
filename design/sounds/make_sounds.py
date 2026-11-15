"""心情小屋 (Feelings House): every sound in the app, made here from sine waves and noise: nothing
recorded, nothing downloaded, every tune written for this app.

- Music (WAV, 16,000 Hz, seamless loops of about 20 to 27 s): very slow, soft lullaby-like tunes
  (music box, glockenspiel, kalimba, a soft pad): one for the house, a lighter one for the stories,
  a slower, breathing one for 冷靜小屋, and the quietest one for resting.
- Short sounds (WAV, 22,050 Hz): one small sound per feeling (開心 two notes up, 難過 two down, 生氣 a
  low "hmph", 害怕 a trembling note, 驚訝 "ding", 害羞 a little giggle, 緊張 a fast heartbeat, 失望 a
  sigh, 得意 a tiny fanfare, 累累的 a yawn, 無聊 a long flat hum, 嫉妒 a short "hmph!", 安心 a long
  "whoo" breath, 委屈 a small sob), the breathing that follows the finger (breath_in / breath_out,
  4 s each), the balloon floating off, the counting bells, the hug's "mmm", a heartbeat, the pillow's
  thump, pouring and gulping water, footsteps, and the soft UI sounds.
- Every random choice uses a fixed seed (from the sound's name), so each run writes the same files.
- Soft for 2 to 5 year olds: no sudden or harsh sounds; 生氣 and 嫉妒 are short, low and gentle.

    python3 design/sounds/make_sounds.py              # writes app/assets/sounds/*.wav
    python3 design/sounds/make_sounds.py tap hug      # only these
    python3 design/sounds/make_sounds.py preview OUT.m4a   # all of them in a row (needs ffmpeg)
"""
import pathlib
import subprocess
import sys
import tempfile
import wave
import zlib

import numpy as np
from scipy.signal import lfilter

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "assets" / "sounds"
SR = 22050
LOOP_SR = 16000
LIMIT = 8_000_000       # bytes, the whole folder

NOTE = {f"{n}{o}": 440 * 2 ** ((k - 9) / 12 + o - 4) for o in range(1, 9) for k, n in enumerate("C C# D D# E F F# G G# A A# B".split())}
for _o in range(1, 9):
    for _f, _s in (("Db", "C#"), ("Eb", "D#"), ("Gb", "F#"), ("Ab", "G#"), ("Bb", "A#")):
        NOTE[f"{_f}{_o}"] = NOTE[f"{_s}{_o}"]


# ---------------------------------------------------------------- helpers
def rng(name):
    return np.random.default_rng(zlib.crc32(name.encode()))


def t_of(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env(n, attack=.005, release=.05, sr=SR):
    e = np.ones(n)
    a, r = max(1, min(n, int(attack * sr))), max(1, min(n, int(release * sr)))
    e[:a] = np.linspace(0, 1, a) ** 2
    e[-r:] *= np.linspace(1, 0, r) ** 2
    return e


def adsr(n, a, d, s, r, sr=SR):
    """Attack, decay to sustain level s, release (seconds)."""
    e = np.full(n, s, float)
    ia, idd, ir = int(a * sr), int(d * sr), int(r * sr)
    ia = max(1, min(ia, n))
    e[:ia] = np.linspace(0, 1, ia)
    j = min(n, ia + idd)
    if j > ia:
        e[ia:j] = np.linspace(1, s, j - ia)
    ir = max(1, min(ir, n))
    e[-ir:] *= np.linspace(1, 0, ir) ** 1.5
    return e


def lowpass(x, cutoff, sr=SR):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (f / cutoff) ** 4)
    return np.fft.irfft(spec, len(x))


def bandpass(x, lo, hi, sr=SR):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (lo / np.maximum(f, 1)) ** 4) / (1 + (f / hi) ** 4)
    return np.fft.irfft(spec, len(x))


def partial(freq, t, sr):
    return np.sin(2 * np.pi * freq * t) if freq < .45 * sr else np.zeros_like(t)


def bell(freq, dur=.8, sr=SR, bright=.6):
    """A soft glockenspiel / music-box note."""
    t = t_of(dur, sr)
    x = (partial(freq, t, sr) * np.exp(-t / (dur * .35))
         + .3 * bright * partial(freq * 2.76, t, sr) * np.exp(-t / (dur * .12))
         + .12 * bright * partial(freq * 5.4, t, sr) * np.exp(-t / (dur * .06)))
    return x * env(len(t), .002, .04, sr)


def kalimba(freq, dur=.9, sr=SR):
    t = t_of(dur, sr)
    x = partial(freq, t, sr) * np.exp(-t / (dur * .3)) + .25 * partial(freq * 3.0, t, sr) * np.exp(-t / .04) + .1 * partial(freq * 5.2, t, sr) * np.exp(-t / .02)
    return x * env(len(t), .003, .05, sr)


def pad(freqs, dur, sr=SR, swell=.6):
    """A soft, slowly swelling chord (a few detuned sines)."""
    t = t_of(dur, sr)
    x = np.zeros_like(t)
    for f in freqs:
        for det in (-.15, .15):
            x += np.sin(2 * np.pi * (f + det) * t) + .25 * partial(2 * f + det, t, sr)
    return x / len(freqs) * adsr(len(t), dur * swell * .5, .1, .9, dur * .45, sr)


def place(total, parts, sr=SR):
    out = np.zeros(int(total * sr))
    for start, sig in parts:
        i = int(start * sr)
        j = min(len(out), i + len(sig))
        if j > i:
            out[i:j] += sig[: j - i]
    return out


def place_loop(total, parts, sr):
    """Like place, but what runs past the end comes back in at the start (a seamless loop)."""
    n = int(total * sr)
    out = np.zeros(n)
    for start, sig in parts:
        i = int(start * sr) % n
        k = 0
        while k < len(sig):
            j = min(n, i + len(sig) - k)
            out[i:j] += sig[k: k + j - i]
            k += j - i
            i = 0
    return out


def resonator(x, freq, bw, sr=SR):
    r = np.exp(-np.pi * bw / sr)
    th = 2 * np.pi * freq / sr
    return lfilter([1 - r], [1, -2 * r * np.cos(th), r * r], x)


def voice(f0, formants, dur, sr=SR, breath=.15, seed="v"):
    """A soft little hum: a buzz whose pitch follows f0 (an array or a number) through formants."""
    n = int(dur * sr)
    f = np.full(n, f0, float) if np.isscalar(f0) else np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(f0)), f0)
    ph = np.cumsum(f) / sr
    buzz = sum(np.sin(2 * np.pi * k * ph) / k ** 1.2 for k in range(1, 14) if True)
    buzz = buzz + breath * rng(seed).standard_normal(n)
    y = sum(g * resonator(buzz, fr, bw, sr) for fr, bw, g in formants)
    return y / max(1e-9, np.abs(y).max())


VOWEL_M = [(300, 90, 1.0), (900, 160, .25), (2300, 220, .08)]      # a closed-mouth "mmm"
VOWEL_U = [(330, 90, 1.0), (850, 140, .3), (2250, 200, .1)]        # "uu"
VOWEL_A = [(750, 110, 1.0), (1200, 130, .6), (2500, 200, .2)]      # "aa"
VOWEL_E = [(450, 100, 1.0), (1900, 160, .4), (2600, 220, .15)]     # "eh"


def noise(n, name):
    return rng(name).standard_normal(n)


def norm(x, peak=.7):
    return x / max(1e-9, np.abs(x).max()) * peak


def fade_edges(x, sr=SR, ms=6):
    k = max(1, int(sr * ms / 1000))
    x = x.copy()
    x[:k] *= np.linspace(0, 1, k)
    x[-k:] *= np.linspace(1, 0, k)
    return x


# ---------------------------------------------------------------- the short sounds
def s_tap():
    n = int(.13 * SR)
    x = lowpass(noise(n, "tap"), 900) * np.exp(-t_of(.13) / .025) * .6 + np.sin(2 * np.pi * 180 * t_of(.13)) * np.exp(-t_of(.13) / .03)
    return norm(x, .5)


def s_pop():
    t = t_of(.16)
    f = np.linspace(500, 1100, len(t))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .04)
    return norm(x, .55)


def s_chime():
    return norm(place(1.0, [(0, bell(NOTE["E6"], .9)), (.12, bell(NOTE["B6"], .8))]), .55)


def s_right():
    return norm(place(1.0, [(0, bell(NOTE["C6"], .7)), (.1, bell(NOTE["E6"], .7)), (.2, bell(NOTE["G6"], .8))]), .55)


def s_try():
    """A gentle 「嗯？」: wrong, but nothing bad happened."""
    f0 = np.concatenate([np.full(30, 260), np.linspace(260, 340, 40)])
    return norm(voice(f0, VOWEL_M, .42, seed="try") * env(int(.42 * SR), .03, .12), .5)


def s_whoosh():
    n = int(.5 * SR)
    t = t_of(.5)
    x = np.zeros(n)
    nz = noise(n, "whoosh")
    for i, c in enumerate(np.linspace(600, 2400, 8)):
        seg = slice(i * n // 8, (i + 1) * n // 8)
        x[seg] = bandpass(nz, c * .7, c * 1.3)[seg]
    return norm(lowpass(x, 3000) * np.sin(np.pi * t / .5) ** 2, .4)


def s_ding():
    return norm(bell(NOTE["A6"], 1.0, bright=.8), .5)


def breath(rising):
    """4.2 s of soft wind, getting louder (in) or softer (out), as the finger holds or lets go."""
    d = 4.2
    t = t_of(d)
    n = len(t)
    nz = noise(n, "in" if rising else "out")
    x = bandpass(nz, 350, 2600) * .7 + lowpass(nz, 500) * .4
    shape = (t / d) ** .7 if rising else (1 - t / d) ** 1.4
    tone = np.sin(2 * np.pi * (220 + (60 if rising else -30) * t / d) * t) * .05
    return norm((x + tone) * shape * env(n, .25, .4), .42)


def s_float():
    t = t_of(1.3)
    f = 600 + 900 * (t / 1.3) ** 1.5
    w = np.sin(2 * np.pi * np.cumsum(f) / SR) * .4 * env(len(t), .05, .4)
    b = place(1.3, [(.2, bell(NOTE["G6"], .6)), (.5, bell(NOTE["C7"], .6)), (.8, bell(NOTE["E7"], .5))])
    return norm(w * np.exp(-t / .8) + b, .5)


def s_count(i):
    notes = ["C6", "D6", "E6", "G6"]
    return norm(place(.9, [(0, bell(NOTE[notes[i]], .85, bright=.4)), (0, .3 * kalimba(NOTE[notes[i]] / 2, .8))]), .55)


def s_hug():
    d = .9
    f0 = 220 + 30 * np.sin(np.linspace(0, np.pi, 50))
    x = voice(f0, VOWEL_M, d, seed="hug") * adsr(int(d * SR), .08, .1, .9, .4)
    return norm(lowpass(x, 1500), .5)


def s_heartbeat():
    t = t_of(.6)
    def thump(at, amp):
        tt = np.clip(t - at, 0, None)
        return amp * np.sin(2 * np.pi * 70 * tt) * np.exp(-tt / .05) * (t >= at)
    return norm(thump(0, 1) + thump(.22, .7), .6)


def s_thump():
    t = t_of(.3)
    x = lowpass(noise(len(t), "thump"), 300) * np.exp(-t / .05) + .8 * np.sin(2 * np.pi * (110 - 50 * t / .3) * t) * np.exp(-t / .06)
    return norm(x * env(len(t), .004, .08), .65)


def s_pour():
    d = .9
    n = int(d * SR)
    x = bandpass(noise(n, "pour"), 700, 3200) * .5
    r = rng("pour2")
    parts = []
    for i in range(14):
        f = r.uniform(500, 1100)
        tt = t_of(.06)
        parts.append((r.uniform(.05, .75), np.sin(2 * np.pi * np.cumsum(np.linspace(f, f * 1.6, len(tt))) / SR) * np.exp(-tt / .02) * .6))
    return norm((x + place(d, parts)) * env(n, .08, .2), .45)


def s_gulp():
    t = t_of(.3)
    f = 300 + 500 * np.exp(-t / .05)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .07)
    return norm(lowpass(x, 1200) * env(len(t), .004, .05), .55)


def s_steps():
    parts = []
    for i in range(3):
        t = t_of(.12)
        parts.append((i * .26, lowpass(noise(len(t), f"st{i}"), 500) * np.exp(-t / .03) + .5 * np.sin(2 * np.pi * 140 * t) * np.exp(-t / .03)))
    return norm(place(.8, parts), .45)


def s_sparkle():
    r = rng("sparkle")
    notes = ["E7", "G7", "B6", "D7", "G7", "E7"]
    return norm(place(.9, [(i * .07, bell(NOTE[n], .4) * r.uniform(.6, 1)) for i, n in enumerate(notes)]), .45)


def s_clap():
    parts = []
    for i in range(3):
        t = t_of(.08)
        parts.append((i * .22, bandpass(noise(len(t), f"cl{i}"), 900, 3500) * np.exp(-t / .015)))
    return norm(place(.7, parts), .5)


def s_page():
    t = t_of(.32)
    x = bandpass(noise(len(t), "page"), 1500, 6000) * np.sin(np.pi * t / .32) ** 3
    return norm(x, .35)


def s_night():
    return norm(place(1.5, [(i * .22, bell(NOTE[n], .9, bright=.3)) for i, n in enumerate(["G5", "E5", "C5", "G4"])]), .5)


# ---- one small sound per feeling
def f_happy():
    return norm(place(.7, [(0, bell(NOTE["C6"], .5)), (.15, bell(NOTE["G6"], .55))]) + .4 * place(.7, [(0, kalimba(NOTE["C5"], .6))]), .55)


def f_sad():
    return norm(place(.9, [(0, kalimba(NOTE["E5"], .6)), (.25, kalimba(NOTE["C5"], .65))]), .55)


def f_angry():
    d = .45
    f0 = np.linspace(170, 130, 40)
    x = voice(f0, VOWEL_M, d, breath=.3, seed="angry") * adsr(int(d * SR), .02, .1, .8, .15)
    return norm(lowpass(x, 1000), .5)


def f_scared():
    t = t_of(.8)
    x = np.sin(2 * np.pi * NOTE["A5"] * t + .4 * np.sin(2 * np.pi * 9 * t)) * (0.6 + .4 * np.sin(2 * np.pi * 11 * t)) * env(len(t), .05, .3)
    return norm(x * np.exp(-t / .6), .45)


def f_surprised():
    t = t_of(.7)
    f = NOTE["E6"] * (1 + .25 * (1 - np.exp(-t / .05)))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .3) + .3 * bell(NOTE["E7"], .7)[: len(t)]
    return norm(x * env(len(t), .003, .1), .55)


def f_shy():
    parts = [(i * .09, voice(520 + 60 * (i % 2), VOWEL_E, .07, seed=f"shy{i}") * env(int(.07 * SR), .01, .03)) for i in range(4)]
    return norm(lowpass(place(.55, parts), 2500), .4)


def f_nervous():
    t = t_of(.11)
    beat = np.sin(2 * np.pi * 85 * t) * np.exp(-t / .03)
    return norm(place(.9, [(i * .2, beat * (1 if i % 2 == 0 else .7)) for i in range(4)]), .55)


def f_disappointed():
    d = .9
    n = int(d * SR)
    t = t_of(d)
    x = bandpass(noise(n, "sigh"), 300, 1800) * (1 - t / d) ** 1.5 * env(n, .08, .2)
    v = voice(np.linspace(240, 170, 40), VOWEL_A, d, breath=.6, seed="sigh2") * (1 - t / d) * .3
    return norm(x + v, .45)


def f_proud():
    def horn(f, d):
        t = t_of(d)
        return sum(np.sin(2 * np.pi * k * f * t) / k ** 1.5 for k in range(1, 7)) * adsr(len(t), .02, .05, .8, .08)
    return norm(lowpass(place(.75, [(0, horn(NOTE["G4"], .14)), (.16, horn(NOTE["G4"], .1)), (.3, horn(NOTE["C5"], .4))]), 2200), .45)


def f_tired():
    d = 1.2
    f0 = np.concatenate([np.linspace(300, 380, 30), np.linspace(380, 180, 70)])
    vow = [(a + (b - a) * 0, bw, g) for (a, bw, g), (b, _, _) in zip(VOWEL_A, VOWEL_U)]
    x = voice(f0, vow, d, breath=.4, seed="yawn") * adsr(int(d * SR), .15, .2, .8, .45)
    return norm(lowpass(x, 1800), .45)


def f_bored():
    d = 1.1
    x = voice(np.full(10, 200.0), VOWEL_M, d, seed="bored") * adsr(int(d * SR), .1, .1, .85, .4)
    return norm(lowpass(x, 1200), .42)


def f_jealous():
    d = .3
    x = voice(np.linspace(260, 200, 20), VOWEL_M, d, breath=.4, seed="jealous") * adsr(int(d * SR), .01, .05, .8, .12)
    return norm(lowpass(x, 1400), .5)


def f_calm():
    d = 1.4
    n = int(d * SR)
    t = t_of(d)
    x = bandpass(noise(n, "calm"), 250, 1400) * (1 - t / d) ** 1.2 * env(n, .2, .3) * .6
    p = pad([NOTE["F4"], NOTE["A4"], NOTE["C5"]], d) * .5
    return norm(x + p, .45)


def f_wronged():
    parts = []
    for i, f in enumerate((420, 380, 330)):
        d = .16
        tt = t_of(d)
        parts.append((i * .2, voice(f * (1 + .03 * np.sin(2 * np.pi * 7 * tt[::100])), VOWEL_U, d, breath=.3, seed=f"sob{i}") * env(len(tt), .02, .06)))
    return norm(lowpass(place(.75, parts), 1800), .42)


# ---------------------------------------------------------------- the music
def tune(name, bpm, beats, melody, chords, voice_fn, sr=LOOP_SR, pad_gain=.35, mel_gain=1.0, bass=True):
    """melody: [(beat, note, length in beats)], chords: [(beat, [notes], length)]. A seamless loop."""
    beat = 60 / bpm
    total = beats * beat
    parts = []
    for b, nt, ln in melody:
        parts.append((b * beat, mel_gain * voice_fn(NOTE[nt], max(.6, ln * beat * 1.6), sr)))
    for b, notes, ln in chords:
        parts.append((b * beat, pad_gain * pad([NOTE[x] for x in notes], ln * beat * 1.15, sr)))
        if bass:
            parts.append((b * beat, .5 * kalimba(NOTE[notes[0]] / 2, min(2.5, ln * beat), sr)))
    x = place_loop(total, parts, sr)
    return x / max(1e-9, np.abs(x).max()) * .42


def m_home():
    mel = [(0, "C6", 1), (1, "E6", 1), (2, "G6", 2), (4, "F6", 1), (5, "E6", 1), (6, "D6", 2),
           (8, "E6", 1), (9, "G6", 1), (10, "C7", 2), (12, "B6", 1), (13, "G6", 1), (14, "A6", 2),
           (16, "F6", 1), (17, "A6", 1), (18, "G6", 2), (20, "E6", 1), (21, "D6", 1), (22, "C6", 2)]
    ch = [(0, ["C4", "E4", "G4"], 4), (4, ["F4", "A4", "C5"], 4), (8, ["C4", "E4", "G4"], 4), (12, ["G3", "B3", "D4"], 4),
          (16, ["F4", "A4", "C5"], 4), (20, ["C4", "E4", "G4"], 4)]
    return tune("home", 66, 24, mel, ch, lambda f, d, sr: bell(f, d, sr, .5))


def m_story():
    mel = [(0, "G5", .5), (.5, "A5", .5), (1, "B5", 1), (2, "D6", 1), (3, "B5", 1), (4, "A5", .5), (4.5, "G5", .5), (5, "A5", 1),
           (6, "E5", 2), (8, "G5", .5), (8.5, "A5", .5), (9, "B5", 1), (10, "D6", 1), (11, "E6", 1), (12, "D6", 1), (13, "B5", 1),
           (14, "G5", 2), (16, "C6", 1), (17, "B5", 1), (18, "A5", 1), (19, "G5", 1), (20, "A5", 2), (22, "D5", 2)]
    ch = [(0, ["G3", "B3", "D4"], 4), (4, ["E3", "G3", "B3"], 4), (8, ["G3", "B3", "D4"], 4), (12, ["C4", "E4", "G4"], 4),
          (16, ["C4", "E4", "G4"], 4), (20, ["D4", "F#4", "A4"], 4)]
    return tune("story", 80, 24, mel, ch, lambda f, d, sr: kalimba(f, d, sr), pad_gain=.3)


def m_calm():
    mel = [(0, "F#5", 3), (3, "A5", 3), (6, "E5", 6), (12, "D5", 3), (15, "F#5", 3), (18, "A4", 6)]
    ch = [(0, ["D4", "F#4", "A4"], 6), (6, ["A3", "C#4", "E4"], 6), (12, ["B3", "D4", "F#4"], 6), (18, ["G3", "B3", "D4"], 6)]
    return tune("calm", 52, 24, mel, ch, lambda f, d, sr: bell(f, d, sr, .3), pad_gain=.55, mel_gain=.6)


def m_rest():
    mel = [(0, "E5", 2), (2, "D5", 1), (3, "C5", 1), (4, "D5", 2), (6, "G4", 2), (8, "E5", 2), (10, "G5", 1), (11, "E5", 1),
           (12, "D5", 4), (16, "C5", 2), (18, "D5", 1), (19, "E5", 1), (20, "C5", 4)]
    ch = [(0, ["C4", "E4", "G4"], 4), (4, ["G3", "B3", "D4"], 4), (8, ["A3", "C4", "E4"], 4), (12, ["G3", "B3", "D4"], 4),
          (16, ["F3", "A3", "C4"], 4), (20, ["C4", "E4", "G4"], 4)]
    return tune("rest", 56, 24, mel, ch, lambda f, d, sr: bell(f, d, sr, .25), pad_gain=.45, mel_gain=.7)


SOUNDS = {
    "tap": s_tap, "pop": s_pop, "chime": s_chime, "right": s_right, "try": s_try, "whoosh": s_whoosh, "ding": s_ding,
    "breath_in": lambda: breath(True), "breath_out": lambda: breath(False), "float": s_float,
    "count_1": lambda: s_count(0), "count_2": lambda: s_count(1), "count_3": lambda: s_count(2), "count_4": lambda: s_count(3),
    "hug": s_hug, "heartbeat": s_heartbeat, "thump": s_thump, "pour": s_pour, "gulp": s_gulp, "steps": s_steps,
    "sparkle": s_sparkle, "clap": s_clap, "page": s_page, "night": s_night,
    "feel_happy": f_happy, "feel_sad": f_sad, "feel_angry": f_angry, "feel_scared": f_scared, "feel_surprised": f_surprised,
    "feel_shy": f_shy, "feel_nervous": f_nervous, "feel_disappointed": f_disappointed, "feel_proud": f_proud,
    "feel_tired": f_tired, "feel_bored": f_bored, "feel_jealous": f_jealous, "feel_calm": f_calm, "feel_wronged": f_wronged,
}
MUSIC = {"music_home": m_home, "music_story": m_story, "music_calm": m_calm, "music_rest": m_rest}
LONG = {"breath_in": 4.3, "breath_out": 4.3}


def write(path, x, sr):
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def make(names=None):
    OUT.mkdir(parents=True, exist_ok=True)
    wanted = set(names or [*SOUNDS, *MUSIC])
    for name, f in SOUNDS.items():
        if name not in wanted:
            continue
        x = fade_edges(np.asarray(f(), float))
        d = len(x) / SR
        if d > LONG.get(name, 1.5):
            raise SystemExit(f"{name}: {d:.2f} s is too long")
        if np.abs(x).max() > .75:
            raise SystemExit(f"{name}: too loud")
        write(OUT / f"{name}.wav", x, SR)
        print(f"  {name:20s} {d:5.2f} s  peak {np.abs(x).max():.2f}")
    for name, f in MUSIC.items():
        if name not in wanted:
            continue
        x = np.asarray(f(), float)
        d = len(x) / LOOP_SR
        jump = abs(x[0] - x[-1])
        if not 18 <= d <= 30 or jump > .05:
            raise SystemExit(f"{name}: {d:.1f} s, seam jump {jump:.3f}")
        write(OUT / f"{name}.wav", x, LOOP_SR)
        print(f"  {name:20s} {d:5.2f} s  loop seam {jump:.3f}")
    known = {f"{n}.wav" for n in [*SOUNDS, *MUSIC]}
    extra = [p.name for p in OUT.glob("*.wav") if p.name not in known]
    if extra:
        raise SystemExit(f"files nobody makes: {extra}")
    size = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    if size > LIMIT:
        raise SystemExit(f"{size} bytes: over {LIMIT}")
    print(f"{len(known)} sounds, {size:,} bytes")


def preview(out):
    with tempfile.TemporaryDirectory(dir="/dev/shm") as tmp:
        parts = []
        for name in [*MUSIC, *SOUNDS]:
            parts.append(str(OUT / f"{name}.wav"))
        lst = pathlib.Path(tmp) / "list.txt"
        lst.write_text("".join(f"file '{p}'\n" for p in parts))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(lst), "-ar", "22050", "-c:a", "aac", "-b:a", "96k", out], check=True)
    print(out)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["preview"]:
        preview(args[1])
    else:
        make(args or None)
