# Should I Coat?

A one-page Ralph-loop experiment. **`AGENTS.md` is the spec. `TODO.md` is the work list. `PROMPT.md` is the per-iteration procedure.** Ralph will rewrite this README as the final TODO item, so this is just a runner's guide for *you*.

## One-time setup

```bash
# 1. Make sure you have the Claude Code CLI installed and logged in.
#    https://docs.claude.com/en/docs/agents-and-tools/claude-code/overview

# 2. (Optional but recommended) link this folder to a GitHub repo,
#    then connect it to Netlify so every commit auto-deploys.
git init
git add -A
git commit -m "initial: Ralph driver files"
gh repo create should-i-coat --public --source=. --push
# then on netlify.com: New site → Import from GitHub → pick the repo.

# 3. Mark the loop runner executable.
chmod +x ralph.sh
```

## Run the loop

```bash
./ralph.sh                  # up to 20 iterations
MAX_ITERS=5 ./ralph.sh      # cap iterations
DRY_RUN=1 ./ralph.sh        # see what would happen, don't call claude
```

Each iteration calls `claude` with `PROMPT.md`, lets it tick one box in `TODO.md`, and commits. Stops when `TODO.md` ends with `STATUS: DONE`, or when `MAX_ITERS` is reached.

Between iterations: open `index.html` in a browser to eyeball progress. If Netlify is linked, every commit also ships a live URL — that's the magic.

## Editing the loop

- **`TODO.md`** — work list. Tick items off manually if Ralph misses one; add items if the spec grows.
- **`PROMPT.md`** — per-iteration instructions. Tweak this if Ralph keeps doing the wrong shape of thing.
- **`AGENTS.md`** — the spec. Edit this if the product changes; Ralph will pick up new requirements next iteration.

## Why three files?

- `AGENTS.md` answers *"what is the product?"* — read every iteration to stay oriented.
- `TODO.md` answers *"what's the next thing to do?"* — the queue.
- `PROMPT.md` answers *"how do I behave this iteration?"* — the procedure.

Each file has one job, no overlap.
