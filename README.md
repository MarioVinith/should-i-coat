# Should I Coat?

**Live: https://should-i-coat.netlify.app**

A one-page website that asks the only question that matters in the morning:

> Should I coat?

It looks at your local weather for the day, runs a simple rule across the next 13 hours, and answers with one of three options, in a friendly font that's the size of your face.

![the answer is one of three things](https://img.shields.io/badge/Bundle%20up.-3b5fe6?style=for-the-badge) ![the answer is one of three things](https://img.shields.io/badge/Pack%20a%20jacket.-1fb88e?style=for-the-badge) ![the answer is one of three things](https://img.shields.io/badge/You're%20good.-f5a623?style=for-the-badge)

## How it decides

The verdict uses **apparent ("feels like") temperature**, not raw air temp — a 12° day with 30 km/h wind feels colder than a 12° still day, and your jacket choice should reflect that.

For each of the 13 hours from **8am to 8pm** in your local time:

- `< 10°C` → **Bundle up.** (puff jacket weather)
- `10–18°C` → **Pack a jacket.** (normal jacket)
- `> 18°C` → **You're good.** (no jacket)

Whichever bucket has the most hours wins. Ties prefer the colder bucket — better to bring a jacket you don't need than freeze.

If you don't grant location permission, it falls back to Melbourne and tells you so.

## What it is, technically

A single self-contained `index.html` file. Inline CSS, inline JS, Chart.js loaded from a CDN. No build step. No npm. No bundler. Two free APIs:

- **[Open-Meteo](https://open-meteo.com)** for the hourly forecast (no API key needed)
- **[BigDataCloud](https://www.bigdatacloud.com/reverse-geocoding)** for suburb-level reverse geocoding (no API key needed)

Hosted on Netlify, auto-deployed from this repo's `main` branch.

## How it was actually built — the interesting part

This project is a small experiment in two ideas borrowed from people who think hard about how to work with coding agents:

### 1. The Ralph Wiggum loop

The **Ralph technique**, named for the Simpsons character known for his cheerful, persistent stupidity, is a pattern coined by [Geoffrey Huntley](https://ghuntley.com/ralph/). Instead of one heroic LLM session that builds the whole thing, you run a tight loop:

```
while not done:
    fire up a fresh agent
    give it the same prompt every time
    let it do one small thing
    commit
```

The trick is that **memory lives on disk** (files + git history), not in the model's context window. Each iteration starts with a clean slate and reads what's already been built. This avoids "context rot" — the gradual degradation that happens when you stuff too much into a single conversation.

This repo is the result of 17 such iterations, plus a few human-driven polish patches afterwards. You can see the loop in `git log`:

```
ralph: iter 17
ralph: iter 16
ralph: iter 15
...
ralph: initial scaffold
```

The driver files are still here, and you can run the loop yourself (see below).

### 2. The grill-me skill

Before any code was written, the spec was sharpened using **[Matt Pocock's `grill-me` skill](https://github.com/mattpocock/skills/blob/main/skills/productivity/grill-me/SKILL.md)** — a 7-line Claude Code skill that forces the agent to interview you, one question at a time with a recommended answer, walking down every branch of the design tree.

The questions it asked were the ones I wouldn't have thought of: *"What does 'today's temperature' actually mean? Is it the daily min? The current temp? The next 12 hours?"* — and *"how do you collapse 13 hourly readings into one verdict?"* These are the kinds of decisions that, left unmade, cause AI coding sessions to produce something plausible-but-wrong. Making them up-front is the cheapest part of the project; finding them mid-build is the most expensive.

You can find the answers I gave in `AGENTS.md`.

## Running the Ralph loop yourself

If you want to watch a build-from-scratch loop work on your own machine:

```bash
git clone https://github.com/YOUR-USERNAME/should-i-coat.git
cd should-i-coat
chmod +x ralph.sh
./ralph.sh                  # up to 20 iterations
MAX_ITERS=5 ./ralph.sh      # cap iterations
DRY_RUN=1 ./ralph.sh        # see what would happen, don't call claude
```

Each iteration calls `claude --print` with `PROMPT.md` as the input, lets it tick one box in `TODO.md`, then commits. The loop stops when `TODO.md` ends with `STATUS: DONE`.

Requirements: [Claude Code CLI](https://docs.claude.com/en/docs/agents-and-tools/claude-code/overview), `git`. That's it.

To rerun it cleanly from scratch, delete `index.html` and unstuck the checkboxes in `TODO.md`.

## Files

- `index.html` — the entire app
- `netlify.toml` — zero-build static deploy + security headers
- `AGENTS.md` — the product spec; the answers from the grilling, written down
- `TODO.md` — the Ralph work list, 17 ticked items plus a few post-loop fixes
- `PROMPT.md` — the per-iteration instructions for the Ralph agent
- `ralph.sh` — the loop runner

## Credits

- The Ralph Wiggum loop is [Geoffrey Huntley's](https://ghuntley.com/ralph/).
- The grill-me skill is [Matt Pocock's](https://github.com/mattpocock/skills/blob/main/skills/productivity/grill-me/SKILL.md).
- Weather: [Open-Meteo](https://open-meteo.com).
- Reverse geocoding: [BigDataCloud](https://www.bigdatacloud.com/reverse-geocoding).

Built in a weekend while figuring out whether to wear a coat.
