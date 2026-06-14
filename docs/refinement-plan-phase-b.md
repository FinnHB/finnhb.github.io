# Refinement Plan — Phase B (polish) + off-brand page fixes

**Status:** ready for implementation handoff.
**Owner:** implementer (Sonnet or equivalent). **Reviewer:** Finn.
**Supersedes:** the "Phase B / Phase C" sections of [`docs/refinement-plan.md`](./refinement-plan.md). That document's Phase A is **fully built and verified** (see below); its Phase B snippets are now partly stale because Phase A changed the surrounding code. **Use the snippets in *this* file** — they are written against the current working tree.
**Design source-of-truth:** [`/CONTEXT.md`](../CONTEXT.md). "Refined Isabella": coral (`#F57A7A`) on near-white, Fraunces + Inter, coral used **only** on interactive/important moments (scarcity preserves its signal). Every task below is checked against that rule.

---

## Verified current state (audited 2026-06-14, against the running build)

**Phase A is done and working** — do not redo:
- `.main` 768px cap removed (`02-base.css:2`); sections claim the viewport.
- Grid tokens set: `--max-width-grid: 1280px`, `--max-width-feed: 1320px` (`01-tokens.css:50-51`).
- Hero cream banner with bottom border (`04-home.css:2-7`) — clear separation from the feed.
- Language filter **works**: verified by driving the page — All→7, R→1, Python→1, Julia→2 cards; hidden cards genuinely disappear via `.card[hidden]{display:none!important}` (`04-home.css:123-125`).
- Card breathing room: body padding `--space-5`, summary at `--fs-body` (`04-home.css:174-209`).
- Cards already have hover **lift + shadow** (`04-home.css:155-158`) — but no coral title treatment yet (see T3).

**What this plan fixes** — Phase B polish that is *not* yet built, plus two off-brand pages found in the audit:

| Area | Current state | Target |
|---|---|---|
| Active nav indicator (B4) | `is-active` class is wired (`header.html:13`); only a 1.5px coral underline — imperceptible | Coral text + 2px underline on active; coral feedback on hover |
| Card hover (B5) | Lift + shadow only | Add coral title on hover (CONTEXT's canonical card hover) |
| Feed heading (B1) | Plain `<h2>Recent Posts</h2>` | Eyebrow + larger heading (optional — see task) |
| Featured first card (B2) | Uniform 3-col grid | Most-recent post spans 2 cols on desktop |
| Pill counts (B3) | `All / R / Python / Julia`, no counts | Muted post counts per pill (optional) |
| About hero (B6) | Avatar forced to 100px, bio 1.0625rem | Avatar ~150px, bio 1.125rem, more gap |
| About Table of Contents | Stray PaperMod ToC widget renders at top of `/about/` | Hidden on the About page |
| Footer (B7) | One `<small>` line | Two-column footer (name+tagline / socials+copyright) on cream |
| `/categories/` terms page | PaperMod default — chips crammed top-left, off-brand | On-brand terms list |

Note: individual category pages (`/categories/<name>/`) already render the on-brand card grid via `_default/list.html` — **leave them alone**. Only the top-level `/categories/` terms index is off-brand.

---

## How to work this plan

1. **Start a fresh Hugo server** before snapping — the default fast-render serves stale markup and will mislead you:
   ```bash
   pkill -f 'hugo server'; cd "/Users/fhb/Documents/My Website" && hugo server -D --disableFastRender
   ```
2. After each task, screenshot and **look** before moving on:
   ```bash
   node ~/.claude/skills/snap-site/snap.mjs --url http://localhost:1313 \
     --paths /,/about/,/blog/,/categories/ --widths 1920,1440,768,375 --out ./.screenshots
   ```
   Then Read the relevant PNGs. For the filter/hover interaction, reuse the click-driver pattern from the audit (`/tmp/filter-test.mjs`).
3. Run `hugo` once at the end and confirm **no build warnings**; confirm **no console errors** in the snap output.
4. **Do not push.** Finn previews locally and pushes manually.
5. Work the tasks in the order below. T1–T3 are low-risk wins; do them first and show Finn.

PaperMod auto-concatenates every file in `assets/css/extended/*.css`, so new CSS files (e.g. `08-footer.css`) load automatically — no import wiring needed.

---

## Task group 1 — low-risk wins (do first, then check in)

### T1 — About page: kill the stray ToC + enlarge hero

**Problem:** `/about/` shows an empty-looking "Table of Contents" widget. Cause: globals `showtoc = true` + `UseHugoToc = true` in `hugo.toml:30,36` apply to every single page. Blog posts *benefit* from a ToC, so fix it per-page, not globally.

**File:** `content/about.md` — front matter (lines 1-6). Add `showToc: false`:
```yaml
---
title: "About"
layout: "single"
url: "/about"
summary: "About Finn-Henrik Barton"
showToc: false
---
```

**File:** `assets/css/extended/06-about.css` — the avatar is pinned to 100px (`06-about.css:12-19`) and the bio is 1.0625rem. Bump them:
```css
.about-hero {
  display: flex;
  gap: var(--space-6);              /* was --space-5 */
  align-items: center;              /* was flex-start */
  padding: var(--space-6) 0;        /* was var(--space-5) 0 var(--space-6) */
  margin-bottom: var(--space-6);    /* was --space-5 */
  border-bottom: 1px solid var(--color-border);
}

.about-hero .about-hero__avatar {
  width: 150px;                     /* was 100px */
  height: 150px;                    /* was 100px */
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
  margin: 0;
}

.about-hero__bio {
  font: 400 1.125rem / var(--lh-body) var(--font-body);   /* was 1.0625rem */
  color: var(--color-text);
  margin: 0;
}
```
The `about.md` markup already requests `width="160" height="160"` (`about.md:9`), and `avatar.png` is a 180px source, so 150px display is a clean downscale — no regeneration needed.

**Verify:** snap `/about/` at 1440 + 375. ToC widget gone; avatar noticeably larger; bio reads one size up; layout still single-column on mobile.

### T2 — Stronger active nav indicator (B4)

**Problem:** the active page's coral underline is 1.5px and easy to miss, so navigating feels unresponsive. CONTEXT allows coral on "active nav underline" — extend it to coral *text* on the active/hover item (still strictly an interactive moment, so scarcity holds).

**File:** `assets/css/extended/03-header.css` — replace the `.site-nav a` block and the hover/active rule (`03-header.css:41-64`):
```css
.site-nav a {
  font-family: var(--font-body);
  font-size: 0.9375rem;
  font-weight: 500;                 /* was 400 */
  color: var(--color-text);
  text-decoration: none;
  position: relative;
  padding-bottom: 3px;              /* was 2px */
  transition: color var(--transition-fast);
}

.site-nav a::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  width: 0;
  height: 2px;                      /* was 1.5px */
  background: var(--color-coral);
  transition: width var(--transition);
}

.site-nav a:hover { color: var(--color-coral); }
.site-nav a.is-active { color: var(--color-coral); }

.site-nav a:hover::after,
.site-nav a.is-active::after {
  width: 100%;
}
```

**Verify:** snap `/blog/` and `/about/`. The current section's nav item is coral with a full-width 2px underline; others are dark. Hover any item → it turns coral and the underline sweeps in.

### T3 — Card hover: coral title (B5)

**Problem:** cards lift on hover but the title doesn't react. CONTEXT's canonical blog-card hover is "4px lift + coral underline on the title." Keep it restrained — coral title colour on hover (an interactive moment).

**File:** `assets/css/extended/04-home.css` — extend the existing hover (`04-home.css:155-158`) and title (`197-201`):
```css
.card {
  background: var(--color-bg-elevated);
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
  overflow: hidden;
  transition: transform var(--transition), box-shadow var(--transition);
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-card-hover);
}

.card__title {
  font: 500 1.375rem / var(--lh-snug) var(--font-display);
  margin: var(--space-2) 0;
  color: var(--color-text);
  transition: color var(--transition-fast);
}

.card:hover .card__title {
  color: var(--color-coral-deep);
}
```
> Do **not** add a coral border to the whole card on hover (the v2 plan floated it) — CONTEXT reserves coral for text/underline moments, and a full coral border reads as ambient fill. Title-colour change is the canonical, scarce treatment.

**Verify:** drive the page (Playwright `hover` on a `.card`, screenshot) or eyeball at `localhost:1313`. Hovered card lifts and its title turns coral; others unchanged.

---

## Task group 2 — homepage feed polish

### T4 — Featured first card spans two columns (B2)

Breaks the grid monotony and signals the most recent post. Desktop only; no template change (the first card is already the newest — `home.html:30` sorts `ByDate.Reverse`).

**File:** `assets/css/extended/04-home.css` — append:
```css
@media (min-width: 901px) {
  .feed__grid .card:first-child {
    grid-column: span 2;
  }
  .feed__grid .card:first-child .card__media img {
    aspect-ratio: 16 / 7;          /* wider crop for the hero card */
  }
  .feed__grid .card:first-child .card__title {
    font-size: 1.625rem;
  }
}
```
The card image is generated at 560×420 with `Center` fill (`card.html:11`); `object-fit: cover` (already on `.card__media img`, `04-home.css:166-172`) handles the wider 16:7 crop without regeneration.

**Verify:** snap `/` at 1920/1440 (first card double-width, wider image) and 768/375 (grid unchanged — featured rule is desktop-only; at ≤900px the existing 2-col/1-col rules win).

### T5 — Feed heading: eyebrow + larger title (B1) — *optional, confirm with Finn*

Current `<h2>Recent Posts</h2>` is acceptable. This is a styling upgrade, not a fix — implement only if Finn wants more editorial hierarchy. If yes:

**File:** `layouts/home.html` — replace line 19 (`<h2 class="feed__title">Recent Posts</h2>`) with:
```html
<div class="feed__heading">
  <span class="eyebrow">Writing</span>
  <h2 class="feed__title">Recent posts</h2>
</div>
```

**File:** `assets/css/extended/04-home.css` — change `.feed__header` (`77-84`) to `align-items: flex-end` and add:
```css
.eyebrow {
  display: block;
  font: 500 var(--fs-meta) / 1 var(--font-body);
  color: var(--color-coral);
  text-transform: uppercase;
  letter-spacing: var(--letter-spacing-caps);
  margin-bottom: var(--space-2);
}

.feed__title {
  font-family: var(--font-display);
  font-size: 2rem;                  /* was --fs-h2 (1.5rem) */
  font-weight: 500;
  margin: 0;
  color: var(--color-text);
}
```
> The eyebrow is the one new coral text moment here; it labels the section (an "important moment"), so it's within the scarcity budget. If Finn finds two coral cues (eyebrow + active pill) noisy in the same band, drop the eyebrow's coral and use `--color-text-subtle`.

**Verify:** snap `/` at 1440. Eyebrow sits above a larger title; pills stay right-aligned to the heading's baseline.

### T6 — Pill counts (B3) — *optional*

Adds a muted count to each language pill. Counts are **build-time** (Hugo), not JS. Keep them muted (never coral) so they don't compete with the active-pill signal.

**File:** `layouts/home.html` — compute counts before the filter block and inject them. Replace the `.feed__filters` block (`home.html:20-25`):
```html
{{- $posts := where site.RegularPages "Type" "blog" }}
{{- $rCount := 0 }}{{- $pyCount := 0 }}{{- $juliaCount := 0 }}
{{- range $posts }}{{- range .Params.tags }}
  {{- $l := lower . }}
  {{- if eq $l "r" }}{{- $rCount = add $rCount 1 }}{{- end }}
  {{- if eq $l "python" }}{{- $pyCount = add $pyCount 1 }}{{- end }}
  {{- if eq $l "julia" }}{{- $juliaCount = add $juliaCount 1 }}{{- end }}
{{- end }}{{- end }}
<div class="feed__filters" role="group" aria-label="Filter posts by language">
  <button class="pill is-active" data-filter="all">All <span class="pill__count">{{ len $posts }}</span></button>
  <button class="pill" data-filter="r">R <span class="pill__count">{{ $rCount }}</span></button>
  <button class="pill" data-filter="python">Python <span class="pill__count">{{ $pyCount }}</span></button>
  <button class="pill" data-filter="julia">Julia <span class="pill__count">{{ $juliaCount }}</span></button>
</div>
```

**File:** `assets/css/extended/04-home.css` — append:
```css
.pill__count {
  margin-left: 0.35em;
  font-size: 0.8em;
  opacity: 0.65;
  font-variant-numeric: tabular-nums;
}
.pill.is-active .pill__count { opacity: 0.9; }   /* white text inherits from active pill */
```

**Verify:** snap `/`. Pills read `All 7 / R 1 / Python 1 / Julia 2`, counts muted. Re-run the filter click-test — counts must not break filtering (they don't change `data-filter`).

---

## Task group 3 — off-brand pages

### T7 — On-brand `/categories/` terms page (new override)

**Problem:** `/categories/` renders via PaperMod's default terms template — chips crammed top-left in a sea of whitespace. Individual category pages are already fine, so this is the only taxonomy fix needed.

**File:** create `layouts/_default/terms.html`:
```html
{{- define "main" }}
<header class="list-header">
  <h1>{{ .Title }}</h1>
  <p>Browse writing by topic.</p>
</header>

<div class="terms">
  {{- $taxo := .Data.Singular }}
  {{- range $name, $pages := .Data.Terms.ByCount }}
  <a class="terms__item" href="{{ (printf "/%s/%s/" $.Data.Plural $name) | urlize | absURL }}">
    <span class="terms__name">{{ $name | title }}</span>
    <span class="terms__count">{{ len $pages }}</span>
  </a>
  {{- end }}
</div>
{{- end }}
```
> Uses `.Data.Terms.ByCount` so the busiest topics lead. `.list-header` already exists (`05-list.css:1-19`), so the heading matches `/blog/`.

**File:** create `assets/css/extended/09-terms.css`:
```css
.terms {
  max-width: var(--max-width-grid);
  margin: 0 auto;
  padding: 0 var(--space-4) var(--space-7);
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
}

.terms__item {
  display: inline-flex;
  align-items: baseline;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-4);
  background: var(--color-bg-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  font: 500 var(--fs-small) / 1 var(--font-body);
  color: var(--color-text);
  text-decoration: none;
  transition: border-color var(--transition-fast), color var(--transition-fast);
}

.terms__item:hover {
  border-color: var(--color-coral);
  color: var(--color-coral);
}

.terms__count {
  font-size: var(--fs-meta);
  color: var(--color-text-subtle);
  font-variant-numeric: tabular-nums;
}
```
> Topic chips = warm-gray surface + dark text, coral border on hover — identical to the card topic-chip language in CONTEXT (no ambient coral).

**Verify:** snap `/categories/` at 1440/375. Topic pills are evenly spaced, ordered by count, with the same wordmark/header rhythm as `/blog/`; hovering a pill shows a coral border. Click one → lands on the already-styled `/categories/<name>/` card grid.

---

## Task group 4 — footer (B7)

### T8 — Two-column footer

**File:** `layouts/_partials/footer.html` — replace lines 1-5:
```html
<footer class="site-footer">
  <div class="site-footer__inner">
    <div class="site-footer__left">
      <p class="site-footer__name">Finn-Henrik Barton</p>
      <p class="site-footer__tag">Economist · environment, urban &amp; spatial</p>
    </div>
    <div class="site-footer__right">
      {{ partial "social_icons.html" (dict) }}
      <small class="site-footer__copy">© {{ now.Year }} · <a href="https://github.com/FinnHB" rel="noopener">GitHub</a> · <a href="https://www.linkedin.com/in/finn-henrik-barton-53193214b/" rel="noopener">LinkedIn</a></small>
    </div>
  </div>
</footer>

{{- partial "extend_footer.html" . }}
```
> `social_icons.html` is PaperMod's partial (already used by the hero, `home.html:12`) and reads `site.Params.socialIcons` from `hugo.toml:62-80` — no new data needed.

**File:** `assets/css/extended/02-base.css` — **delete** the footer block (`02-base.css:58-75`, the `.site-footer`, `.site-footer__inner`, `.site-footer a` rules). It moves to its own file next.

**File:** create `assets/css/extended/08-footer.css`:
```css
.site-footer {
  margin-top: var(--space-8);
  padding: var(--space-6) var(--space-4) var(--space-5);
  border-top: 1px solid var(--color-border);
  background: var(--color-bg-surface);          /* cream, bookends the hero banner */
}

.site-footer__inner {
  max-width: var(--max-width-grid);
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--space-5);
  flex-wrap: wrap;
}

.site-footer__name {
  font: 500 var(--fs-small) / 1.4 var(--font-display);
  text-transform: uppercase;
  letter-spacing: var(--letter-spacing-caps);
  margin: 0 0 var(--space-1) 0;
}

.site-footer__tag {
  font-size: var(--fs-small);
  color: var(--color-text-muted);
  margin: 0;
}

.site-footer__right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: var(--space-2);
}

.site-footer__right .social-icons { display: flex; gap: var(--space-3); }
.site-footer__right .social-icons a { color: var(--color-text-muted); transition: color var(--transition-fast); }
.site-footer__right .social-icons a:hover { color: var(--color-coral); }

.site-footer__copy { font-size: var(--fs-meta); color: var(--color-text-subtle); }
.site-footer__copy a { color: inherit; text-decoration: underline; }
.site-footer__copy a:hover { color: var(--color-coral); }

@media (max-width: 560px) {
  .site-footer__inner { flex-direction: column; }
  .site-footer__right { align-items: flex-start; }
}
```

**Verify:** snap every page at 1440 + 375 (footer is global). Two columns on desktop (name+tag left, social icons + copyright right), cream background, hairline top border; single stacked column on mobile. Confirm social icons render (they pull from `socialIcons` config).

---

## File manifest

**Bold** = new file.

| File | Tasks |
|---|---|
| `content/about.md` | T1 (front-matter `showToc: false`) |
| `assets/css/extended/06-about.css` | T1 (avatar 150px, bio 1.125rem, gap) |
| `assets/css/extended/03-header.css` | T2 (active nav) |
| `assets/css/extended/04-home.css` | T3 (card hover), T4 (featured card), T5 (eyebrow, optional), T6 (pill counts, optional) |
| `layouts/home.html` | T5 (optional), T6 (optional) |
| **`layouts/_default/terms.html`** | T7 (categories terms page) |
| **`assets/css/extended/09-terms.css`** | T7 |
| `layouts/_partials/footer.html` | T8 (two-column footer) |
| `assets/css/extended/02-base.css` | T8 (remove old footer block) |
| **`assets/css/extended/08-footer.css`** | T8 |

No changes to `card.html`, `header.html`, `_default/list.html`, shortcodes, or the post template.

---

## Verification checklist (run at the end)

- [ ] `/about/`: no ToC widget; avatar ~150px; bio one size larger; timeline + contributions intact.
- [ ] Nav: active section is coral + 2px underline; hover turns items coral. Checked on `/blog/` and `/about/`.
- [ ] Card hover: 4px lift + title turns coral; no coral card border.
- [ ] Homepage desktop (≥901px): first card spans 2 columns with a wider image. Tablet/mobile: unchanged 2-col/1-col.
- [ ] (If T5) eyebrow above a larger heading. (If T6) pills show muted counts `7 / 1 / 1 / 2`.
- [ ] Filter still works after T6: All→7, R→1, Python→1, Julia→2 (re-run the click-driver).
- [ ] `/categories/`: on-brand pill list, ordered by count, coral border on hover; click → styled category grid.
- [ ] Footer: two columns + cream + social icons on desktop; stacked on mobile; present on every page.
- [ ] No horizontal scroll at 1920/1440/1024/768/375.
- [ ] `hugo` builds with no warnings; snap output reports no console errors.

---

## Deferred (Phase C — do not build unless Finn asks)

- Related posts on single-post pages (reuse `card.html`).
- Reading time on posts (`.ReadingTime`; `ShowReadingTime` is off in `hugo.toml:23`).
- "What I'm doing now" block on About (needs content from Finn first).

## Doc drift to flag (housekeeping, optional)

`CONTEXT.md` is now slightly out of date and should be reconciled when convenient:
- It describes the hero as "separated from the post grid by a horizontal rule"; Phase A replaced the rule with the cream banner (a deliberate change). Update the "Personality hero" glossary entry.
- It lists a "Research page"; that section was deleted (`content/research/_index.md` removed) and the nav is now Blog / About / CV. Drop the Research row.
