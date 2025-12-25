To add more presets long-term without constantly “guessing” parameters, treat this as a **sound-design problem with a repeatable tuning workflow**. You’ll add presets by (a) choosing a synthesis recipe and (b) tuning a small set of parameters using clear heuristics.

Below is a practical playbook you can use every time.

---

## 1) Adding a preset is just adding a `SoundPreset` entry

You add one line-item in `sound_preset.dart`:

```dart
const SoundPreset(
  id: 'insects',
  name: 'Insects',
  category: SoundCategory.insects,
  kind: SynthKind.hybrid,
  baseGain: 0.20,
  noiseSmooth: 0.08,
  lowpassHz: 4000,
  highpassHz: 250,
  lfoHz: 0.3,
  lfoDepth: 0.2,
  eventRate: 8.0,
  eventDecay: 0.05,
  eventGain: 0.22,
);
```

You do not change the engine.

---

## 2) What each parameter “means” in sound terms

### Loudness / output

* **`baseGain`**: overall intensity of this preset before the UI volume.
  Typical:

    * night: 0.10–0.20
    * rain: 0.25–0.40
    * wind/ocean: 0.35–0.60
    * fire crackle: 0.25–0.45

### “Texture” (smooth vs harsh)

* **`noiseSmooth`**: smoothing factor (higher = smoother / less harsh, but too high becomes dull).
  Think of it as “how filtered the noise is before any EQ”.

    * wind: 0.01–0.04 (very smooth / whoosh)
    * ocean: 0.03–0.08
    * rain: 0.08–0.15 (a bit brighter texture)
    * night: 0.12–0.20 (soft hiss)

### Tone shaping (EQ)

* **`lowpassHz`**: removes high-frequency hiss.

    * wind: 600–1200
    * ocean: 900–2000
    * rain: 2500–4500
    * night: 800–1800
* **`highpassHz`**: removes low-frequency rumble.

    * ocean/waves: 60–120
    * fire: 80–180
    * night: often 0–80
    * insects: 200–600 (keeps it “thin” and bright)

(Your current engine code shows these fields but may not yet apply them; if you want them to actually affect audio, we add a lightweight HP/LP filter in Dart. I can provide that diff.)

### Movement over time (gusts / swell)

* **`lfoHz`**: how fast the volume slowly “breathes”.

    * ocean swell: 0.05–0.15 Hz
    * wind gusts: 0.10–0.40 Hz
    * night: 0.05–0.20 Hz
    * rain flutter: 3–10 Hz (small “shimmer”)
* **`lfoDepth`**: how strong the movement is.

    * ocean: 0.6–0.9
    * wind: 0.6–0.9
    * rain: 0.1–0.35
    * night: 0.05–0.2

### Events (crackles, chirps, drops)

* **`eventRate`**: events per second

    * fire: 8–20
    * birds: 0.2–2
    * insects: 3–12
    * rain droplets: 10–40 (small events)
* **`eventDecay`**: event “tail” in seconds

    * crackle: 0.01–0.05
    * chirp: 0.08–0.25
* **`eventGain`**: event loudness

    * keep modest: 0.08–0.40
    * too high will sound like pops/clicks

### Tone (focus/instruments)

* **`toneHz`**: base tone frequency

    * drone: 110/220/440 common
* **`secondToneHz`**: used for stereo binaural or interval/harmony

    * binaural beat: right = left + beatHz

Important: binaural requires **stereo output**; mono cannot do it.

---

## 3) A repeatable “parameter setting” workflow

### Step A — Start from a template family

Pick the closest template:

* **Rain family**: brighter noise + mild shimmer + lots of small events
* **Wind family**: heavy smoothing + strong slow LFO
* **Ocean family**: smoothing + strong very slow LFO + slight highpass
* **Fire family**: mid smoothing + lots of short events + HP to remove rumble
* **Night family**: low gain + lowpass + minimal movement
* **Insect/bird family**: hybrid + sparse events + higher highpass

### Step B — Set the “3 knobs first”

1. `baseGain`
2. `noiseSmooth`
3. `lowpassHz`

Listen. These three dominate the character.

### Step C — Add motion

Set `lfoHz` and `lfoDepth` to make it feel alive without pumping.

### Step D — Add events only if needed

Tune `eventRate → eventDecay → eventGain` in that order.

---

## 4) Practical tuning targets by category (cheat-sheet)

**Ocean**

* baseGain 0.35–0.55
* noiseSmooth 0.03–0.08
* lowpass 900–1800, highpass 60–120
* lfoHz 0.05–0.15, depth 0.7–0.9
* events: usually off

**Forest**

* baseGain 0.20–0.35
* noiseSmooth 0.08–0.15
* lowpass 2000–3500, highpass 150–300
* lfoHz 0.15–0.35, depth 0.2–0.4
* events: birds 0.3–2.0, decay 0.1–0.25, gain 0.2–0.4

**Fire**

* baseGain 0.25–0.45
* noiseSmooth 0.04–0.08
* lowpass 1200–2200, highpass 80–200
* lfoHz 0.2–0.6, depth 0.2–0.4
* events: 8–20, decay 0.01–0.05, gain 0.25–0.45

**Night**

* baseGain 0.10–0.20
* noiseSmooth 0.12–0.20
* lowpass 800–1800
* lfoHz 0.05–0.2, depth 0.05–0.15
* events: off or very low

**Insects**

* baseGain 0.15–0.30
* noiseSmooth 0.06–0.12
* lowpass 3000–5000, highpass 250–700
* lfoHz 0.2–0.5, depth 0.1–0.25
* events: 3–12, decay 0.03–0.09, gain 0.15–0.30

---

## 5) A highly effective improvement: build a “preset tuning page”

To avoid guessing, make a dev-only page where:

* you pick a preset
* sliders update parameters live
* you press “Save JSON”
* you paste back into `sound_preset.dart`

This is exactly how sound design is usually done.

If you want, I’ll provide:

* a Flutter tuning UI with sliders for each parameter
* a “Copy preset as Dart code” button
* optional persistence to `shared_preferences`

---

## 6) One important caveat

Your current engine, as last shown, may not yet *apply* `lowpassHz` and `highpassHz` as actual DSP filters (it uses smoothing and modulation; LP/HP fields are present as placeholders). If you want those parameters to be real, I’ll add a small, efficient IIR LP/HP implementation and connect it to the preset fields.

---
