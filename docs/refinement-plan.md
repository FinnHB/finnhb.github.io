# Refinement Plan — Refined Isabella v2

**Owner:** Sonnet (implementing). **Reviewer:** Finn.
**Predecessor:** [`docs/implementation-plan.md`](./implementation-plan.md) — Phases 1–9 of the v1 plan are built and committed in the working tree. Don't redo them.
**Source-of-truth:** [`/CONTEXT.md`](../CONTEXT.md). Design language ("Refined Isabella": coral on near-white, Fraunces + Inter, wordmark nav, editorial cards) is unchanged. This plan layers visual and interaction fixes on top.

---

## What's already built (don't redo)

```
layouts/
├── home.html                          # personality hero + filter + card grid
├── _default/list.html                 # section list pages (/blog/, /categories/)
├── _partials/
│   ├── header.html                    # wordmark sticky nav
│   ├── footer.html                    # minimal footer
│   ├── extend_head.html               # Google Fonts (Fraunces, Inter)
│   ├── extend_footer.html             # filter + nav-toggle JS
│   └── card.html                      # card markup
└── _shortcodes/
    ├── timeline.html                  # <div class="timeline">
    └── role.html                      # entries inside timeline

assets/css/
├── extended/01-tokens.css             # :root design tokens
├── extended/02-base.css               # body, headings, links, hr, code
├── extended/03-header.css             # site-header, wordmark, nav
├── extended/04-home.css               # hero, feed, pills, cards
├── extended/05-list.css               # list-header, pagination
├── extended/06-about.css              # about-hero, timeline
├── extended/07-post.css               # post-title, prose, code blocks
└── includes/chroma-styles.css         # github-dark chroma override

content/_index.md                      # tagline + bio in front matter
content/about.md                       # about-hero HTML + timeline shortcode
hugo.toml                              # profileMode disabled, no theme toggle, github-dark
```

Hugo dev server expected to be already running. If not: `hugo server -D`.

---

## Feedback received (verbatim, paraphrased)

> "Everything seems quite squeezed together in the middle, especially on landscape mode on a wider screen. What I'd ideally like would be for it to be spread out a bit more and really utilise the area of the screen."

> "In particular, when it comes to the writing section below, the text underneath is really quite squeezed together."

> "I don't feel like there's a great separation between the top part, where there's kind of the hero with my picture and a brief description, and the section below. I don't know if we can have some sort of banner style where there's a background on the top to really separate those two sections."

> "The selector [All R Python Julia] for the writing part below is not actually [working], so that banner doesn't do anything."

> "When selecting between 'Blog', 'Research', 'About', and 'CV', those buttons on the top don't seem to do anything either."

---

## Root-cause analysis

| Symptom | Real cause |
|---|---|
| Squeezed layout everywhere | **PaperMod's `.main` is capped at `calc(--main-width + --gap*2) = 720px + 48px = 768px`** in `themes/PaperMod/assets/css/common/main.css`. Our 1180px-grid sections get crushed inside that. The v1 plan missed this. |
| No hero/writing separation | Hero and writing share `--color-bg`. The `<hr class="hero-rule">` is too subtle. |
| Card text cramped | Combination of the 768px wrapper above + small body padding + small summary font-size. Once `.main` is unblocked the cards have room, but they still need more internal breathing room. |
| Filter pills "do nothing" | JS sets `card.hidden = true`. Browser default for `[hidden]` is `display: none`, but on a CSS Grid child this can be over-specified by `.card`'s class-level styles. **No explicit `[hidden]` rule** in our CSS — relies on browser default that PaperMod's reset may neutralise. |
| Nav "does nothing" | Links work — they navigate. But all pages render at 768px-wide and look near-identical, so the page change isn't perceived. Once F1 (width) is fixed each page will look distinct and this symptom resolves itself. **No code change needed here.** Adding a stronger active state is still desirable polish. |

---

## Critical fixes (must-have) — Phase A

### A1 — Unblock PaperMod's `.main` width cap

**File:** `assets/css/extended/02-base.css`
**Where:** at the very top, before existing rules.

```css
/* Reset PaperMod's 768px main-width cap so our sections can claim the viewport */
.main {
  max-width: none;
  padding: 0;
  width: 100%;
  min-height: calc(100vh - var(--nav-height) - 200px);
}
```

> Why not `!important`? Project `assets/css/extended/*.css` loads AFTER theme's `common/main.css` in the concatenated stylesheet (`themes/PaperMod/layouts/_partials/head.html` line 58–59). Specificity is equal, source-order wins. Verified by reading the head partial.

### A2 — Widen the grid

**File:** `assets/css/extended/01-tokens.css`
**Change:** bump `--max-width-grid` from `1180px` to `1280px`. Add a separate token for the writing area so it can go wider:

```css
--max-width-grid:      1280px;     /* hero, about, list-headers */
--max-width-feed:      1320px;     /* writing grid — slightly wider for breathing room */
```

Then in `04-home.css` switch `.feed`'s `max-width` to `var(--max-width-feed)`.

### A3 — Hero banner background

**File:** `assets/css/extended/04-home.css`
**Replace the existing `.hero` block** with:

```css
.hero {
  background: var(--color-bg-surface);   /* warm cream banner */
  border-bottom: 1px solid var(--color-border);
  padding: var(--space-8) var(--space-4) var(--space-7);
  width: 100%;
}

.hero__inner {
  display: flex;
  gap: var(--space-6);                   /* was --space-5 */
  align-items: center;
  max-width: var(--max-width-grid);
  margin: 0 auto;
}
```

**File:** `layouts/home.html`
Remove the `<hr class="hero-rule">` line entirely — the background change owns the separation now. Also remove the corresponding `.hero-rule` block from `04-home.css`.

> **Why warm cream (`#F4F1EC`), not coral?** Coral is reserved as the scarce interactive accent ([CONTEXT.md#Coral](../CONTEXT.md)). A warm cream surface keeps the hero distinct without burning the brand colour on a non-interactive zone.

### A4 — Card text breathing room + filter fix

**File:** `assets/css/extended/04-home.css`

```css
/* Filter-hidden cards MUST disappear in the grid */
.card[hidden] {
  display: none !important;
}

/* Grid — more breathing between cards */
.feed__grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-6) var(--space-5);    /* row-gap 3rem, col-gap 2rem */
}

/* Card body — more padding */
.card__body {
  padding: var(--space-5);               /* was --space-4 */
}

/* Summary text — readable size instead of fs-small */
.card__summary {
  color: var(--color-text-muted);
  font-size: var(--fs-body);             /* was --fs-small (14px). Now 16px. */
  line-height: var(--lh-body);
  margin: var(--space-2) 0 var(--space-4) 0;
}

.card__title {
  font: 500 1.375rem / var(--lh-snug) var(--font-display);    /* explicit 22px */
  margin: var(--space-2) 0;
}
```

> Why this works: cards were narrow because `.main` clamped them. Once A1 lifts the clamp, three cards across at 1320px = ~410px each. The body needs to look proportional — `--space-5` padding and 16px body text fit that scale.

---

## Design polish (should-have) — Phase B

These don't fix bugs, they raise the design's pulling-power. Use established editorial patterns: clear hierarchy, asymmetric rhythm, scarce accent colour, visible micro-feedback.

### B1 — Eyebrow text + stronger Writing header

**File:** `layouts/home.html`
Replace `<h2 class="feed__title">Writing</h2>` with:
```html
<div class="feed__heading">
  <span class="eyebrow">Recent posts</span>
  <h2 class="feed__title">Writing</h2>
</div>
```

**File:** `assets/css/extended/04-home.css`
```css
.feed {
  max-width: var(--max-width-feed);
  padding: var(--space-7) var(--space-4) var(--space-8);
  margin: 0 auto;
}

.feed__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;                 /* was baseline */
  margin-bottom: var(--space-6);         /* was --space-5 */
  flex-wrap: wrap;
  gap: var(--space-4);
}

.eyebrow {
  display: block;
  font: 500 var(--fs-meta) / 1 var(--font-body);
  color: var(--color-coral);
  text-transform: uppercase;
  letter-spacing: var(--letter-spacing-caps);
  margin-bottom: var(--space-2);
}

.feed__title {
  font: 500 2rem / var(--lh-tight) var(--font-display);     /* was 1.5rem */
  margin: 0;
}
```

### B2 — Featured first card (desktop only)

Visually signals what's most recent and breaks the grid monotony.

**File:** `assets/css/extended/04-home.css`
```css
@media (min-width: 901px) {
  .feed__grid .card:first-child {
    grid-column: span 2;
  }
  .feed__grid .card:first-child .card__media {
    aspect-ratio: 16 / 7;
    overflow: hidden;
  }
  .feed__grid .card:first-child .card__media img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    aspect-ratio: unset;
  }
  .feed__grid .card:first-child .card__title {
    font-size: 1.75rem;
  }
}
```

No template changes needed — first card is whichever post is most recent by date (already sorted in `home.html`).

### B3 — Filter pill counts (UX feedback)

When `.feed__filters` is rendered, the JS already knows which cards belong to which language. Adding a count makes the pills feel responsive even before clicked.

**File:** `layouts/home.html`
Generate counts at build time using Hugo:
```html
{{- $posts := where site.RegularPages "Type" "blog" }}
{{- $rCount := 0 }}{{- $pyCount := 0 }}{{- $juliaCount := 0 }}
{{- range $posts }}
  {{- range .Params.tags }}
    {{- if eq (lower .) "r" }}{{- $rCount = add $rCount 1 }}{{- end }}
    {{- if eq (lower .) "python" }}{{- $pyCount = add $pyCount 1 }}{{- end }}
    {{- if eq (lower .) "julia" }}{{- $juliaCount = add $juliaCount 1 }}{{- end }}
  {{- end }}
{{- end }}
<div class="feed__filters" role="group" aria-label="Filter posts by language">
  <button class="pill is-active" data-filter="all">All <span class="pill__count">{{ len $posts }}</span></button>
  <button class="pill" data-filter="r">R <span class="pill__count">{{ $rCount }}</span></button>
  <button class="pill" data-filter="python">Python <span class="pill__count">{{ $pyCount }}</span></button>
  <button class="pill" data-filter="julia">Julia <span class="pill__count">{{ $juliaCount }}</span></button>
</div>
```

**File:** `assets/css/extended/04-home.css`
```css
.pill__count {
  display: inline-block;
  margin-left: 0.4em;
  font-size: 0.75em;
  opacity: 0.7;
  font-variant-numeric: tabular-nums;
}
.pill.is-active .pill__count { opacity: 0.85; }
```

### B4 — Stronger active nav indicator

The current underline grows on hover/active. Make the active state immediately distinct so page changes feel "snappy".

**File:** `assets/css/extended/03-header.css`
```css
.site-nav a {
  font: 500 0.9375rem / 1 var(--font-body);   /* was 400 */
  color: var(--color-text);
  text-decoration: none;
  position: relative;
  padding-bottom: 4px;                         /* was 2px */
  transition: color var(--transition-fast);
}
.site-nav a::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  width: 0;
  height: 2px;                                 /* was 1.5px */
  background: var(--color-coral);
  transition: width var(--transition);
}
.site-nav a:hover { color: var(--color-coral); }
.site-nav a:hover::after { width: 100%; }
.site-nav a.is-active { color: var(--color-coral); }
.site-nav a.is-active::after { width: 100%; }
```

### B5 — Card hover refinement

Replace the title-underline-on-hover with a subtler whole-card lift + coral border.

**File:** `assets/css/extended/04-home.css` — modify the existing `.card` and `.card__title` blocks:
```css
.card {
  background: var(--color-bg-elevated);
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
  overflow: hidden;
  transition: transform var(--transition), box-shadow var(--transition), border-color var(--transition);
}
.card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-card-hover);
  border-color: rgba(245, 122, 122, 0.4);    /* faint coral border */
}
/* Remove the background-image / background-size animation from .card__title — too noisy when combined with the lift */
.card__title {
  font: 500 1.375rem / var(--lh-snug) var(--font-display);
  margin: var(--space-2) 0;
  color: var(--color-text);
  /* no background-image animation */
}
.card:hover .card__title {
  color: var(--color-coral-deep);
}
```

### B6 — About page polish

**File:** `assets/css/extended/06-about.css`
```css
.about-hero {
  display: flex;
  gap: var(--space-6);                       /* was --space-5 */
  align-items: center;
  max-width: var(--max-width-grid);
  margin: 0 auto var(--space-6) auto;
  padding: var(--space-7) var(--space-4) var(--space-3);
}
.about-hero__avatar {
  width: 160px;                              /* was 120px */
  height: 160px;
}
.about-hero__bio {
  font: 400 1.125rem / var(--lh-body) var(--font-body);   /* was 1.0625rem */
}
```

About-page prose (`## Experience`, `## Education`, etc.) currently inherits PaperMod's narrow constraints. Add a wrapper inside `02-base.css`:

```css
/* About / single-page prose width */
.main .post-content,
.main > article {
  max-width: var(--max-width-prose);
  margin: 0 auto;
  padding: 0 var(--space-4);
}
```

> Tradeoff: prose stays at 720px (good for reading) while the homepage uses 1280px+. Different content, different widths.

### B7 — Footer presence

Currently one line. Add a top hairline, more vertical space, and the social icons.

**File:** `layouts/_partials/footer.html`
```html
<footer class="site-footer">
  <div class="site-footer__inner">
    <div class="site-footer__left">
      <p class="site-footer__name">Finn-Henrik Barton</p>
      <p class="site-footer__tag">Economist · environment, urban, spatial</p>
    </div>
    <div class="site-footer__right">
      {{ partial "social_icons.html" (dict) }}
      <small class="site-footer__copy">© {{ now.Year }} · <a href="https://github.com/FinnHB" rel="noopener">GitHub</a> · <a href="https://www.linkedin.com/in/finn-henrik-barton-53193214b/" rel="noopener">LinkedIn</a></small>
    </div>
  </div>
</footer>
{{- partial "extend_footer.html" . }}
```

**File:** create `assets/css/extended/08-footer.css`:
```css
.site-footer {
  margin-top: var(--space-8);
  padding: var(--space-6) var(--space-4) var(--space-5);
  border-top: 1px solid var(--color-border);
  background: var(--color-bg-surface);
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
.site-footer__right .social-icons { gap: var(--space-3); }
.site-footer__right .social-icons a { color: var(--color-text-muted); }
.site-footer__right .social-icons a:hover { color: var(--color-coral); }
.site-footer__copy {
  font-size: var(--fs-meta);
  color: var(--color-text-subtle);
}
.site-footer__copy a {
  color: inherit;
  text-decoration: underline;
}
.site-footer__copy a:hover { color: var(--color-coral); }

@media (max-width: 560px) {
  .site-footer__inner { flex-direction: column; }
  .site-footer__right { align-items: flex-start; }
}
```

**File:** `assets/css/extended/02-base.css`
Delete the existing `.site-footer*` block from this file (now lives in 08-footer.css) to avoid duplication.

---

## Bonus polish (nice-to-have) — Phase C

Only do these after Finn has reviewed Phases A+B.

### C1 — "What I'm doing now" block on About
Above `## Experience`, a short bullet list of current activities (3–4 items). Pulls people in who want a snapshot rather than a CV.
Source content from Finn before implementing.

### C2 — Related posts on single-post pages
Show 2–3 cards at the bottom of every blog post, picked from same category. Reuses `card.html`. Override PaperMod's `single.html` minimally — add only at the bottom.

### C3 — Reading time on posts
Hugo has `.ReadingTime` built in. Add to the post header in PaperMod's single.html override.

These three are deferred unless Finn explicitly asks.

---

## File-by-file change manifest

For Sonnet's quick reference. **Bold** = new file, others modified.

| File | What changes |
|---|---|
| `assets/css/extended/01-tokens.css` | Bump `--max-width-grid` to `1280px`, add `--max-width-feed: 1320px` |
| `assets/css/extended/02-base.css` | Add `.main` reset at top; add prose-width rule; remove footer block |
| `assets/css/extended/03-header.css` | Stronger nav active/hover (B4) |
| `assets/css/extended/04-home.css` | Hero banner bg (A3), card breathing (A4), `.card[hidden]` rule (A4), feed header polish (B1), featured first card (B2), pill counts (B3), card hover (B5) |
| `assets/css/extended/06-about.css` | About-hero polish (B6) |
| **`assets/css/extended/08-footer.css`** | New file — footer styles (B7) |
| `layouts/home.html` | Remove `<hr class="hero-rule">`, add eyebrow markup (B1), add filter counts (B3) |
| `layouts/_partials/footer.html` | Multi-column footer (B7) |

No template changes for header, list, card, shortcodes, about, post.

---

## Verification checklist

Open `http://localhost:1313` and verify at each step:

### Phase A (critical)
- [ ] At 1920px viewport: homepage hero spans full width with cream background
- [ ] At 1920px: writing grid is ~1320px wide, 3 columns, clearly wider than before
- [ ] Click "Python" pill → only Python-tagged posts visible (Anki post)
- [ ] Click "Julia" → 2 posts visible
- [ ] Click "All" → all 7 posts return
- [ ] Click "Blog" in nav → goes to `/blog/` with a list-header "Blog" and same card grid
- [ ] Click "About" → goes to `/about/` with the timeline rendered, current role coral
- [ ] No horizontal scrollbar at 1920px, 1440px, 1024px, 768px, 375px

### Phase B (polish)
- [ ] Eyebrow text "Recent posts" appears above "Writing" h2
- [ ] At 1024px+, the first (most recent) card spans 2 columns
- [ ] Filter pills show counts: "All 7", "R 1", "Python 1", "Julia 2"
- [ ] Active nav item is coral-coloured AND underlined
- [ ] Card hover: lifts 4px, border becomes faint coral, title becomes coral
- [ ] About hero avatar is 160px, bio text is larger
- [ ] About prose (Education, Skills) is at 720px reading width, centred
- [ ] Footer has two columns: name+tag left, socials+copyright right; warm-cream background

### Cross-cutting
- [ ] No console errors (`F12` → Console)
- [ ] No Hugo build warnings (`hugo` should complete without warns)
- [ ] Mobile (375px): grid collapses to single column, nav hamburger works
- [ ] Tablet (768px): grid is 2 columns
- [ ] Keyboard nav: Tab through nav, filter pills, social icons — visible focus rings

---

## Implementation order for Sonnet

1. Read this file and `docs/implementation-plan.md` so you have context.
2. **Phase A first** — A1, A2, A3, A4. Verify each before moving on. Filter pills should now work. Layout should breathe.
3. Show Finn for a check-in. Don't proceed to B without his nod.
4. **Phase B** — B1 → B7 in order. Run the verification after each.
5. **Don't touch Phase C** unless Finn explicitly asks.
6. **Don't push to GitHub** at any point. Finn will preview and push manually.

---

## Decisions baked in (don't relitigate)

- Hero banner uses `--color-bg-surface: #F4F1EC` (warm cream), NOT coral. Coral stays as the interactive accent.
- Featured first card spans 2 columns on desktop only — not 3, and not 2 on mobile.
- Filter counts live in Hugo template (build-time), not JS (would have to refilter on every click).
- Body width: 1280px for editorial sections, 1320px specifically for the writing grid, 720px for prose. Three different widths is intentional.
- Footer has a background (warm cream) to bookend the hero — matching banner top and bottom.
- No analytics, no search, no comments, no dark mode. Still deferred per v1.

---

## Open questions Sonnet may surface if blocked

These have sensible defaults; ask only if the answer dramatically changes the work.

- **A "Currently" block on about (C1)** — only build if Finn provides 3–4 bullet points of content.
- **Topic chip colour scheme** — currently one warm-gray bg + coral border on hover. If Finn asks for per-topic colours, propose a palette first, don't pick on the fly.
- **Hero photo** — `/img/avatar.png` is the existing 180px source. If it looks pixelated at 160px display, generate a 2× via Hugo image processing rather than hand-picking a new image.
