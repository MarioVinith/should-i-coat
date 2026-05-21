# Should I Coat? — Work list

Strictly top-to-bottom. Each iteration: find the first unchecked item, do the smallest thing that satisfies it, tick the box, exit. Don't skip ahead, don't batch multiple items.

When every box below is ticked, append a final line: `STATUS: DONE`. The Ralph runner watches for that line and stops.

---

## Scaffolding

- [x] **1. Create the bare `index.html` shell** — doctype, `<html lang="en">`, `<head>` with charset / viewport / theme-color / `<title>Should I Coat?</title>`, empty `<body>`. Inline `<style>` and `<script>` blocks exist but are empty.

- [x] **2. Add the page-level styles and dark background** — CSS variables for `--bg #0b0d12`, `--fg #f6f7fb`, `--muted #8a93a6`, `--card #141823`, plus the three verdict colors `--puff #3b5fe6`, `--normal #1fb88e`, `--none #f5a623`. Set `html, body` to dark background, white foreground, system sans font, no margin. Body becomes a vertical flex column at min-height 100vh.

- [x] **3. Build the header markup** — `<header>` with `.brand` (left, text `Should I Coat?`) and a `#loc` element (right, placeholder `—`). Small, uppercase, letter-spaced, muted color.

- [x] **4. Build the verdict block markup** — `<main>` containing a `.verdict-wrap` with: `#eyebrow` (`Today you should…`), `#verdict` (`Checking the sky` with a `.loading` class for the animated dots), `#sub` (empty placeholder), `#note` (empty placeholder for the fallback note).

- [ ] **5. Style the verdict text** — `#verdict` font-size `clamp(56px, 18vw, 320px)`, weight 800, line-height 0.92, letter-spacing `-0.04em`. Add `.verdict.puff`, `.verdict.normal`, `.verdict.none` modifier classes that set color from the CSS variables, with a `color` transition.

- [ ] **6. Add the loading-dots animation** — a `.loading::after` pseudo-element that cycles `''`, `'.'`, `'..'`, `'...'` via a keyframes animation, attached to `#verdict.loading`.

## Data layer

- [ ] **7. Add geolocation with Melbourne fallback** — a JS function that returns a Promise resolving to `{lat, lon, fallback}`. Uses `navigator.geolocation.getCurrentPosition` with an 8-second timeout. On denial, timeout, or missing API: resolve with Melbourne (`-37.8136, 144.9631`, `fallback: true`).

- [ ] **8. Fetch the Open-Meteo forecast** — async function `getForecast(lat, lon)` calling `https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&hourly=temperature_2m,apparent_temperature&timezone=auto&forecast_days=1`. Throws on non-OK responses. Returns parsed JSON.

- [ ] **9. Reverse-geocode the location name** — async function `reverseGeocode(lat, lon)` hitting Open-Meteo's geocoding reverse endpoint. Returns `"{name}, {country_code}"` on success, `null` on failure. Caller falls back to rounded coords.

## Decision

- [ ] **10. Wire up the end-to-end flow with no verdict logic yet** — top-level `async function run()` that: gets location, reverse-geocodes, sets the header location text, fetches forecast, and logs the result to the console. Sets the fallback note when geolocation fell back. Replaces the `#verdict` text with a placeholder `Working…` (no class yet).

- [ ] **11. Implement the verdict computation** — a pure function `decide(apparentHourly, hourlyTimes)` that filters readings to local hours 8 through 20 inclusive, classifies each as `puff` / `normal` / `none` by the rule (`<10`, `10–18`, `>18`), majority votes, breaks ties toward the colder bucket, and returns `{ key, label }` using the exact copy `Bundle up.` / `Pack a jacket.` / `You're good.`.

- [ ] **12. Render the verdict** — inside `run()`, after getting the forecast, call `decide()` and update `#verdict`: remove `.loading`, add `.puff` / `.normal` / `.none`, set `textContent` to the label. Set `#sub` to `Today: {min_actual}°–{max_actual}° · Feels like {min_app}°–{max_app}°`, all rounded to whole degrees, using daily min/max for actuals and min/max across the hourly apparent array for feels-like.

## Chart

- [ ] **13. Add the chart card markup and Chart.js CDN script** — a `.chart-card` section in `<main>` containing a `.chart-head` row (label `Hourly temperature — today` and a range indicator) and a `<canvas id="chart">`. Add `<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js">` in `<head>`. Style the card: rounded corners, `--card` background, internal padding, fixed canvas height (180px desktop, 140px mobile).

- [ ] **14. Render the two-line chart** — function `drawChart(times, actualTemps, apparentTemps)` building a Chart.js line chart with two datasets: actual (solid, color `rgba(246,247,251,0.8)`, no dash) and feels-like (dashed, `borderDash: [6, 4]`, color `#f5a623`). Labels are hours formatted `HH`. Y-axis ticks suffix `°`. No dots, smooth curves (tension 0.35), legend visible (Chart.js default position).

- [ ] **15. Add the decision-window shading and now-line** — a small Chart.js plugin (or `afterDraw` hook) that draws a faint rectangle behind the data for the 8am–8pm region (`rgba(255,255,255,0.06)`) and a vertical line at the current hour (`rgba(255,255,255,0.3)`, 1px). These give visual context for the verdict at a glance.

## Polish

- [ ] **16. Handle the forecast-error case** — wrap the `getForecast` call in `try/catch`. On failure, remove `.loading`, set `#verdict` to `Sky unreachable`, set `#sub` to `The weather API didn't answer. Try refreshing.`, and skip rendering the chart.

- [ ] **17. Add `netlify.toml` and a short README** — `netlify.toml` with `publish = "."`, empty `command`, and the security headers block from `AGENTS.md`. `README.md` describes what the site is, the decision rule, how to deploy to Netlify via GitHub, and how to run the Ralph loop locally (`chmod +x ralph.sh && ./ralph.sh`).

---

When every box above is ticked, append `STATUS: DONE` on a new line.
