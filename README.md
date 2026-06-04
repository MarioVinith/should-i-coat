# Should I Coat?

**Live: https://should-i-coat.netlify.app**

A one-page website that asks the only question that matters in the morning:

> Should I coat?

It looks at your local weather for the day, runs a simple rule across the next 13 hours, and answers with one of three options, in a friendly font that's the size of your face.

![the answer is one of three things](https://img.shields.io/badge/Bundle%20up.-3b5fe6?style=for-the-badge) ![the answer is one of three things](https://img.shields.io/badge/Pack%20a%20jacket.-1fb88e?style=for-the-badge) ![the answer is one of three things](https://img.shields.io/badge/Live%20a%20little%2C%20no%20jacket.-f5a623?style=for-the-badge)

## How it decides

The verdict uses **apparent ("feels like") temperature**, not raw air temp — a 14° day with 30 km/h wind feels colder than a 14° still day, and your jacket choice should reflect that.

For each of the 13 hours from **8am to 8pm** in your local time:

- `< 12°C` → **Bundle up.** (puff jacket weather)
- `12–18°C` → **Pack a jacket.** (normal jacket)
- `> 18°C` → **Live a little, no jacket.** (no jacket)

Whichever bucket has the most hours wins. Ties prefer the colder bucket — better to bring a jacket you don't need than freeze.

If you don't grant location permission, it falls back to Melbourne and tells you so.

## Rain, too

A second verdict line tells you whether to bring a brolly. The rule looks at the same 8am–8pm window and triggers `Take the brolly.` if any hour has **at least 50% chance of rain AND at least 0.2mm expected**. Both signals have to agree, so you don't end up carrying an umbrella for a 60%-chance-of-trace-drizzle day. On dry days it reads `Skip the brolly.`

When the verdict is wet, the page also rains gently in the background, with each drop landing on the chart card. It's subtle. It honors `prefers-reduced-motion` if you have that on.

## At home or out and about

A small toggle at the top switches between two modes:

- **out and about** — the verdicts above. Jacket + umbrella.
- **at home** — based on the *current hour's* feels-like temp. Below 17°C, *Throw on a hoodie and trackies.* Above, *Be good in your pyjamas.* The umbrella line hides because you don't need one indoors.

The page always opens in *out and about*. The toggle is session-only — refresh the page and you're back outside.

## What it is, technically

A single self-contained `index.html` file. Inline CSS, inline JS, Chart.js loaded from a CDN. No build step. No npm. No bundler. Two free APIs:

- **[Open-Meteo](https://open-meteo.com)** for the hourly forecast — temperature, apparent temperature, precipitation, precipitation probability (no API key needed)
- **[BigDataCloud](https://www.bigdatacloud.com/reverse-geocoding)** for suburb-level reverse geocoding (no API key needed)

Hosted on Netlify, auto-deployed from this repo's `main` branch.

## Credits

- Weather: [Open-Meteo](https://open-meteo.com).
- Reverse geocoding: [BigDataCloud](https://www.bigdatacloud.com/reverse-geocoding).
- Charting: [Chart.js](https://www.chartjs.org/).

Built by Maria Vinith Darwin, in a weekend, while figuring out whether to wear a coat.
