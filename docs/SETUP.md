# Setup

Everything here goes into a repo named **exactly the same as your GitHub username**
(`github.com/hey-amanthakur/hey-amanthakur`). That magic repo's README is what shows
on your profile.

---

## 1. Regenerate the local assets (optional)

Everything is already committed under `assets/`, so you only need this after
changing inputs (new photo, new skill values, new featured repos):

```bash
./setup.sh --image assets/me.png          # portrait + radars
python3 scripts/cards.py --user hey-amanthakur --projects assets/projects.json --out assets
```

Then open `preview.html` in a browser to see the local assets before you push anything.

Hand-editable inputs:

| file | controls |
|---|---|
| `assets/skills.json` | the self-rated `~/` skill radar |
| `assets/projects.json` | which repos get a card in `~/` selected work + their descriptions |
| `README.md` | social links, whoami bullets, toolbox icons |

## 2. Push it

```bash
git add -A && git commit -m "profile readme" && git push origin main
```

The repo must be **public** — the SVG assets are loaded by URL, so a private repo shows
broken images.

## 3. Let Actions write to the repo

Repo → **Settings** → **Actions** → **General** → **Workflow permissions** →
select **Read and write permissions** → Save.

Without this the Radar and Snake workflows fail on push.

## 4. Add the metrics token

`lowlighter/metrics` needs its own token — the built-in `GITHUB_TOKEN` can't read profile data.

1. https://github.com/settings/tokens → **Generate new token (classic)**
2. Scopes: **`read:user`** (add **`repo`** too if you want private repos counted)
3. Expiry: whatever you're happy re-doing later
4. Copy it, then repo → **Settings** → **Secrets and variables** → **Actions** →
   **New repository secret** → name it **`METRICS_TOKEN`**, paste the value

## 5. Kick off the workflows

Repo → **Actions** tab → enable workflows if prompted, then run each one via
**Run workflow**:

| workflow | produces | lands in |
|---|---|---|
| **Metrics** | 3D isometric calendar, coding habits, language mix, achievements | `assets/metrics.*.svg` on `main` |
| **Snake** | snake eating your contribution graph | the `output` branch |
| **Charts and cards** | both spider charts, stat card, repo cards | `assets/radar*.svg`, `assets/card-*.svg` on `main` |

First run takes a couple of minutes. After that they're on a schedule (metrics every 6h,
snake every 12h, radar daily).

> The snake images are referenced from the `output` branch via `raw.githubusercontent.com`,
> so they'll 404 until the Snake workflow has run once. That's expected.
> The stat card's contribution/streak tiles also need `METRICS_TOKEN`; until then the
> card renders with three tiles instead of six.

---

## Tuning the artwork

### The portrait

```bash
python3 scripts/dotify.py assets/me.png -o assets/portrait \
  --cols 100 --equalize --detail 0.5 --color --reveal
```

Other looks from the same source:

```bash
# green monochrome, matching the contribution-graph palette
python3 scripts/dotify.py assets/me.png -o assets/portrait --cols 88 --equalize --detail 0.5 --animate

# literal 0s and 1s instead of dots
python3 scripts/dotify.py assets/me.png -o assets/portrait --mode binary --cols 62 --equalize --detail 0.5

# plain text art — paste the .txt into a ``` code block in the README
python3 scripts/dotify.py assets/me.png -o assets/portrait --mode ascii --cols 80
python3 scripts/dotify.py assets/me.png -o assets/portrait --mode braille --cols 100
```

Worth knowing:

- **`--equalize` is the one that matters for a portrait.** A lit face against dark hair
  spans a far wider range than the ~10 tones a dot ramp can show, so a straight render
  blows the face into a flat blob and loses the hair entirely. Equalising against the
  subject's own histogram buys the shadow detail back.
- `--detail 0.5` then puts local facial structure back on top, since equalising flattens
  it. Above about 1.0 it starts looking noisy.
- `--color` keeps each dot's original pixel colour. Because the fills then come from the
  photo rather than a theme, it writes a single `portrait.svg` instead of a
  `-dark`/`-light` pair — the README references it directly.
- `--cols` is the whole quality/size dial. 60 is chunky and abstract, 100 is what's in
  use now (~470 KB), 130 is more detailed but pushes past 500 KB.
- `--reveal` draws the portrait in row by row when the page loads, like a slow scan.
  `--reveal-time` is the full sweep (2.5s), `--reveal-fade` is how long one row takes to
  appear (0.45s). It plays once per image load — open `preview.html` and use the
  **replay the load-in** button to rewatch it.
- `--animate` adds a slow shimmer sweeping across the columns. It suits the green
  monochrome version; on the colour one it reads as vertical banding across the face,
  which is why it's off here.
- `--square` crops to 1:1, with `--focus X,Y` saying which point ends up centred
  (`0.55,0.45` for a face sitting right of and above the middle). `me.png` (the GitHub
  avatar) is already square, so it isn't used.
- `--circle` masks to a circle and fades the edge. Good for a tight head shot.
- Swap in any better photo: drop it at `assets/me.png` (or pass a different path to
  `setup.sh`) and rerun.

If the source has an alpha channel, it's treated as a subject cutout: nothing is drawn
outside it, and `--equalize` measures only the subject rather than a huge empty background.

### The stat and repo cards

`scripts/cards.py` generates these into your own repo, on purpose. The usual choices —
`github-readme-stats`, `github-profile-trophy`, `streak-stats` — are shared public
instances, and when they fall over your profile shows broken images. A file in your
repo has none of those failure modes.

```bash
python3 scripts/cards.py --user hey-amanthakur --out assets
```

- **Which repos get a card** is `assets/projects.json`. Stars, forks and language are
  fetched live on every run; the `description` there overrides the repo's own GitHub
  description. Setting the descriptions on GitHub too is worth doing — it helps anyone
  browsing your repo list, and then you can delete the overrides.
- **The contribution and streak tiles need a token**, because they come from the GraphQL
  API. The workflow passes `METRICS_TOKEN` for this. Run it locally without one and the
  card still renders, just with three tiles instead of six.
- Star and fork counts are the live numbers, so the cards genuinely track reality — they
  just do it on a daily schedule rather than on every page view.

### The radar

Edit `assets/skills.json` and re-run — values are 0-100 and entirely self-rated. Five to
eight axes reads best; past that the labels crowd each other.

The second radar (`radar-langs`) is generated from real language byte counts across your
public repos, so it needs no editing. Two knobs in `.github/workflows/radar.yml`:

- `--exclude` drops languages you don't want counted (HTML/CSS/Shell are out by default,
  otherwise generated files skew everything).
- `--curve` controls how hard a dominant language is compressed. Raw byte counts are
  brutally lopsided — if one language is 90% of your code, a linear radar is just a spike.
  `1.0` is linear, `0.5` is sqrt, `0.4` is the default here, `0.3` flattens it further.

---

## If something looks broken

**Images don't load on the profile.** The repo has to be public, and the paths in the
README are relative (`assets/…`) — those only resolve once the files are actually pushed.

**Metrics workflow fails.** Almost always the `METRICS_TOKEN` secret: missing, expired, or
created as a fine-grained token instead of a classic one.

**Snake images 404.** The Snake workflow hasn't completed yet, or step 3 (write permissions)
was skipped so it couldn't create the `output` branch.

**Stats look low.** Contribution-based widgets only count public activity unless the
token includes private-repo access.
