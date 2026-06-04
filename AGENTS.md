# Should I Coat? — Project context for agents

You are working on a one-page static website called **Should I Coat?** This file is the source of truth for *what the product is*. `TODO.md` is the source of truth for *what to do next*. `PROMPT.md` is the source of truth for *how to behave each iteration*.

Read this file at the start of every iteration.

## What the product is

A single HTML page that opens, asks the browser for the user's location, fetches today's weather from Open-Meteo, and tells the user — in one giant verdict — whether to wear a puff jacket, a normal jacket, or no jacket. A two-line temperature chart sits underneath as supporting evidence.

The whole site is one self-contained `index.html` with inline CSS and JS. No build step. No npm. No bundler. Chart.js is the only external dependency and it's loaded from a CDN.

## The decision rule

The verdict is based on **apparent ("feels like") temperature**, not raw air temperature. Open-Meteo provides this as the `apparent_temperature` hourly variable.

**Window:** the 13 hourly readings from **8am through 8pm in the location's local time, today**. Use Open-Meteo's `timezone=auto` so the timestamps you receive are already in the location's local zone. Filter the hourly array to the 13 entries whose local hour is between 8 and 20 inclusive.

**Classification per hour:**
- apparent temp `< 12°C` → puff
- apparent temp `12°C` to `18°C` → normal
- apparent temp `> 18°C` → none

(Threshold history: the puff cutoff was originally `<10°C` but bumped to `<12°C` after lived-experience testing in Melbourne — 10–12° apparent days were verdicting as "normal jacket" when they realistically called for a puffer.)

**Aggregation:** majority vote. Count how many of the 13 hours fall in each bucket. The bucket with the most hours wins. On ties, prefer the **colder** bucket (better to bring a jacket you don't need than freeze).

**Past hours:** if the user opens the site at 6pm, eight of the 13 decision hours are already in the past. Open-Meteo serves recent observed values for those hours through the same endpoint, so the same request gives you a sensible mix of observed-where-possible and forecast-where-not. No special handling needed beyond requesting `forecast_days=1` (which includes today from 00:00 local).

## Mode toggle: outside vs at home

A small two-button toggle above the eyebrow flips the page between **outside** and **at home** modes. The page **always opens in `outside` mode** — there is no persistence (no `localStorage`). The toggle is session-only; reload, and you're back outside.

### Outside mode (default)
Uses `decideOutside()` — the majority-vote rule above, across 8am–8pm apparent temps.

### At-home mode
Uses `decideHome()`. **Reads only the current hour's apparent temperature**, not the 8am–8pm window. Two states:

- apparent temp `< 17°C` → `Throw on a hoodie and trackies.` (uses the `puff` color class — cold blue)
- apparent temp `≥ 17°C` → `Be good in your pyjamas.` (uses the `none` color class — warm amber)

Rationale for using only the current hour: when you're at home, you're not committing to a jacket for the day — you're putting on whatever feels right *right now*. Indoor temps don't track outdoor highs the way "what to wear outside all day" does.

If the current hour's value is missing from the hourly array (shouldn't happen but defensively), fall back to the first non-null apparent reading. Never crash.

## Umbrella verdict

A second, smaller verdict line below the jacket verdict, decided by `decideUmbrella()`. **Binary** — always shows in outside mode, hidden in at-home mode.

**Rule:** For each hour in the 8am–8pm window, the day is "wet" if **any single hour** has both:
- `precipitation_probability ≥ 50%` **AND**
- `precipitation ≥ 0.2 mm`

Both signals must agree. A 60%-chance-of-trace-drizzle day shouldn't trigger an umbrella, and neither should a 30%-chance-of-5mm day (the model isn't confident enough). The "any hour" rule (rather than majority vote) is intentional — rain is asymmetric in a way temperature isn't. A single rainy afternoon hour means you want a brolly even if the rest of the day is dry.

**Copy:**
- wet → `Take the brolly.` (puff blue)
- dry → `Skip the brolly.` (none amber)

**Visibility:** the entire umbrella line is hidden when `state.mode === "home"`. No "umbrella indoors" verdict ever shows.

**Sentence continuity:** the umbrella line reads as a second imperative clause from the eyebrow. e.g. *"Today you should… Bundle up. Take the brolly."*

## Inputs

**Geolocation.** Ask the browser for `navigator.geolocation.getCurrentPosition`. If the user denies it, or it times out, or the API isn't available, fall back to **Melbourne, Australia (-37.8136, 144.9631)** and show a small note at the bottom of the verdict area: *"Couldn't get your location. Showing Melbourne."*

**Weather API.** Open-Meteo, no API key required.

```
https://api.open-meteo.com/v1/forecast
  ?latitude={lat}
  &longitude={lon}
  &hourly=temperature_2m,apparent_temperature,precipitation,precipitation_probability
  &timezone=auto
  &forecast_days=1
```

`temperature_2m` and `apparent_temperature` feed the jacket verdict and the chart. `precipitation` (mm/hr) and `precipitation_probability` (%) feed the umbrella verdict.

**Reverse geocoding** for the location name in the header. Two-tier:

1. **BigDataCloud (preferred):** `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude={lat}&longitude={lon}&localityLanguage=en`. Returns suburb-level resolution (e.g. `"St Kilda, Melbourne"`) which Open-Meteo's geocoder cannot. Format: `{locality}, {city}` when they differ; just `{city}` when they're the same.
2. **Open-Meteo (fallback):** `https://geocoding-api.open-meteo.com/v1/reverse?latitude={lat}&longitude={lon}&count=1&language=en&format=json`. City-level only.
3. **Coordinates (last resort):** rounded to two decimals, e.g. `"-37.81, 144.96"`.

**Melbourne fallback:** when geolocation is denied/unavailable, skip reverse geocoding entirely and display the hardcoded string `Melbourne (default)` — no API call needed for a known constant.

## UI

**Layout.** Verdict on top, chart card below.

```
┌──────────────────────────────────┐
│ Should I Coat?      Melbourne    │  ← header, small uppercase grey
│                                  │
│   Today you should…              │  ← eyebrow, small grey
│                                  │
│   Bundle up.                     │  ← verdict, ~18vw, bold, colored
│                                  │
│   Today: 11°–19° · Feels 8°–17°  │  ← subtext, small grey
│                                  │
│   ╭────────────────────────────╮ │
│   │ ╱╲    ╱╲                   │ │  ← chart card, dark surface
│   │╱  ╲__╱  ╲___               │ │
│   ╰────────────────────────────╯ │
│                                  │
│   Couldn't get your location...  │  ← fallback note (only when fallback)
└──────────────────────────────────┘
```

**Verdict copy (exact strings):**

Outside mode — `decideOutside()`:

| Bucket | Text                          | Color (on dark bg)         |
| ------ | ----------------------------- | -------------------------- |
| puff   | `Bundle up.`                  | deep navy — `#3b5fe6`      |
| normal | `Pack a jacket.`              | muted teal — `#1fb88e`     |
| none   | `Live a little, no jacket.`   | warm amber — `#f5a623`     |

At-home mode — `decideHome()`, two states based on the *current hour's* apparent temp:

| Bucket | Threshold | Text                                | Reused class |
| ------ | --------- | ----------------------------------- | ------------ |
| cold   | `< 17°C`  | `Throw on a hoodie and trackies.`   | `puff`       |
| warm   | `≥ 17°C`  | `Be good in your pyjamas.`          | `none`       |

Umbrella verdict — `decideUmbrella()`, binary, always shown in outside mode (hidden in home mode):

| State | Trigger                                            | Text                  | Color                 |
| ----- | -------------------------------------------------- | --------------------- | --------------------- |
| wet   | Any hour 8am–8pm with `prob ≥ 50%` AND `precip ≥ 0.2mm` | `Take the brolly.` | `var(--puff)` blue    |
| dry   | Otherwise                                          | `Skip the brolly.`    | `var(--none)` amber   |

All five verdict strings (three outside + two at-home) are written to flow grammatically from the eyebrow text "Today you should…". The umbrella line reads as a second clause: e.g. "Today you should… Bundle up. Take the brolly."

Eyebrow text above the verdict: `Today you should…`

Subtext below the verdict, on one line: `Today: {min_actual}°–{max_actual}° · Feels like {min_apparent}°–{max_apparent}°` (all rounded to whole degrees). Use the daily min/max for the actual range and computed min/max of the apparent values for the feels-like range.

**Header:** small, uppercase, letter-spaced. Brand name `Should I Coat?` on the left, location name on the right.

**Tab title:** `Should I Coat?`

**Visual style:** dark mode only. Background ~`#0b0d12`. Foreground ~`#f6f7fb`. Muted text ~`#8a93a6`. Card surface ~`#141823`. System sans font stack.

**Responsive:** verdict text uses `clamp()` so it scales down on mobile but stays huge on desktop. Chart canvas resizes with viewport. The header layout stays a flex row top to bottom on phones; if it gets cramped, the location can wrap below the brand.

## Chart

Two lines, both rendered with Chart.js:

1. **Actual air temperature** — solid line, color `#f6f7fb` (foreground white) at 80% opacity.
2. **Feels-like (apparent) temperature** — dashed line (`borderDash: [6, 4]`), color `#f5a623` at full opacity. The dashing is the load-bearing signal that this is the line driving the decision.

A legend sits above or below the chart with small chips: `● Actual   ╌ Feels like`.

**X-axis.** All 24 hours of today, labelled every 3 hours: `00, 03, 06, 09, 12, 15, 18, 21`. Local time.

**Y-axis.** Degrees Celsius, auto-scaled with `°` suffix on tick labels.

**Decision-window shading.** A subtle background band covering the 8am–20:00 region. Implemented as a Chart.js plugin or a faint vertical rectangle. About 8% white on the dark card.

**Now-line.** A subtle vertical line at the current hour, 30% opacity, behind the data lines.

**No data dots, smooth curves** (`tension: 0.35`, `pointRadius: 0`).

## Rain animation

When the umbrella verdict is `wet` AND the mode is `outside`, the page rains in the background. Implementation choices, in case they need re-tuning:

- **CSS-only animation.** 100 individual `<span class="raindrop">` elements are generated once on page load (`buildRainDrops()`), each with randomized inline styles: `left` (0–100%), `animation-duration` (0.6–1.3s), and `animation-delay` (negative, so each drop starts mid-flight). No `requestAnimationFrame` loop; the browser handles compositing.
- **The randomized delay matters.** Without it, all drops fall in unison and the effect reads as a sliding wallpaper. With negative-staggered delays, the eye sees drops at varying stages of their fall, which reads as actual rain.
- **Bounded to the verdict area only.** The `.rain-layer` is `position: absolute` inside `.verdict-wrap`, so drops fall from the top of the verdict area and "land" exactly at the chart card's top edge. Drops fade out in their final ~30% of travel so the landing looks like absorption, not a hard cutoff. The `--fall` CSS custom property is set from the layer's `clientHeight` on load and on `resize`, so the landing point follows the chart card regardless of viewport height.
- **Drop appearance.** Each drop is a 1px × 14px vertical streak with a top-transparent → bottom-light-blue gradient, mimicking motion-blur on a real raindrop.
- **Toggling.** `renderVerdict()` toggles `.is-active` on the layer. Class drives a 600ms opacity fade — the rain crossfades in/out rather than popping.
- **Reduced motion.** Honors `prefers-reduced-motion: reduce`. The drops stop animating; the layer is dimmed to 30% opacity. The signal "it's raining" survives, but no motion.

## Loading and error states

- **Loading.** Show the eyebrow with `Checking the sky…` and a soft animated dot. Replace with the real verdict once data arrives.
- **Forecast API failure.** Replace the verdict with `Sky unreachable` and the subtext with `The weather API didn't answer. Try refreshing.` Don't render the chart in this case.
- **Geolocation denied/timeout.** Use Melbourne, show the fallback note. Don't treat this as an error visually — the site should still feel functional.
- **Reverse geocoding failure.** Header shows rounded coordinates. No user-visible error.

## Deployment

Static site, deployed via Netlify, linked to a GitHub repository. Every commit on `main` auto-deploys to the production URL. There is no build step, so `netlify.toml` should be minimal:

```toml
[build]
  publish = "."
  command = ""

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options          = "DENY"
    X-Content-Type-Options   = "nosniff"
    Referrer-Policy          = "strict-origin-when-cross-origin"
    Permissions-Policy       = "geolocation=(self)"
```

## File structure (target end state)

```
.
├── index.html       # the entire app — HTML, inline CSS, inline JS
├── netlify.toml     # zero-build static deploy + security headers
├── README.md        # what the site is, how to deploy, how Ralph works
├── TODO.md          # the Ralph work list (this gets ticked off iteration by iteration)
├── PROMPT.md        # the per-iteration instructions for Ralph
├── AGENTS.md        # this file
└── ralph.sh         # the Ralph loop runner
```

## Hard constraints — read every iteration

- **No build step.** Don't introduce npm, vite, esbuild, tailwind-cli, or any other tooling.
- **No new dependencies beyond Chart.js.** Chart.js is loaded from a CDN inside `index.html`. No package.json.
- **`index.html` stays a single self-contained file.** Inline CSS in `<style>`, inline JS in `<script>`. No external `.css` or `.js` files.
- **Vanilla JS only.** No React, Vue, Svelte, Alpine, jQuery, etc.
- **No API keys.** Open-Meteo doesn't need one. If a task seems to need a key, you've picked the wrong API.
- **Don't rewrite files from scratch.** Edit in place. The only file you may create from nothing is `index.html` on iteration 1.

## What "good" looks like

A coworker shows the page on their phone, the verdict reads in under a second of attention, and they say "huh, neat." The chart is glanceable, not studied. The page feels like a single confident answer with the evidence visible underneath it.
