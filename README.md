# Should I Coat?

A one-page static site that asks for your location, fetches today's weather from Open-Meteo, and answers the only question that matters: *should I coat?*

The whole app is a single self-contained `index.html` — inline CSS, inline JS, Chart.js from a CDN. No build step, no npm, no bundler.

## The decision rule

The verdict reads off **apparent ("feels like") temperature**, not raw air temp. For each of the 13 hours from 8am to 8pm in the location's local time today:

- `< 10°C` → **puff** (`Bundle up.`)
- `10°C – 18°C` → **normal** (`Pack a jacket.`)
- `> 18°C` → **none** (`You're good.`)

Majority vote across the 13 hours wins. Ties prefer the colder bucket — better to bring a jacket you don't need than freeze.

If geolocation is denied or times out, the site falls back to Melbourne (`-37.8136, 144.9631`) and shows a small note. If the weather API is unreachable, the verdict becomes `Sky unreachable`.

## Deploy via Netlify + GitHub

It's a static site with no build step. Point Netlify at the repo and it ships.

```bash
git init
git add -A
git commit -m "initial commit"
gh repo create should-i-coat --public --source=. --push
```

Then on [netlify.com](https://netlify.com): **New site → Import from GitHub → pick the repo**. Every push to `main` auto-deploys.

`netlify.toml` sets `publish = "."`, an empty build command, and a small block of security headers (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy: geolocation=(self)`).

## Run the Ralph loop locally

The site was assembled iteratively by a Ralph loop — a fresh agent each iteration, ticking one TODO box at a time. To run it yourself:

```bash
chmod +x ralph.sh
./ralph.sh                  # up to 20 iterations
MAX_ITERS=5 ./ralph.sh      # cap iterations
DRY_RUN=1 ./ralph.sh        # see what would happen, don't call claude
```

Each iteration calls `claude` with `PROMPT.md`, lets it tick one box in `TODO.md`, and commits. The loop stops when `TODO.md` ends with `STATUS: DONE` or when `MAX_ITERS` is hit.

## Files

- `index.html` — the entire app
- `netlify.toml` — zero-build static deploy + security headers
- `AGENTS.md` — the product spec (read every iteration)
- `TODO.md` — the Ralph work list
- `PROMPT.md` — per-iteration agent instructions
- `ralph.sh` — the loop runner
