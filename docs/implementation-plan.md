# Implementation Plan — Refined Isabella redesign

**Owner:** Sonnet (implementing). **Reviewer:** Finn.
**Design source of truth:** [`/CONTEXT.md`](../CONTEXT.md). Read it first — this plan does not re-derive the design choices.

## Goal

Translate the locked design (Refined Isabella: coral on near-white, Fraunces + Inter, sticky wordmark nav, editorial 3-col homepage with language filtering, Experience timeline on About) into actual code, built as PaperMod overrides + extended CSS. No PaperMod fork; PaperMod stays as a submodule.

## Non-goals for v1

- Dark mode (explicitly dropped)
- Custom logo/mark in the nav (wordmark only)
- Per-topic chip colors (single warm-gray bg, coral border on hover)
- Search (skip — 7 posts doesn't need it)
- Comments (skip — same reason)
- Math rendering changes (PaperMod's KaTeX path stays as-is)
- Quarto authoring pipeline (deferred per earlier decision)

## Constraints / gotchas

- **Hugo lookup paths:** PaperMod uses Hugo v0.146+ layouts with `_partials/`, `_shortcodes/`, `_markup/` directories. To override a partial, mirror the path: theme's `layouts/_partials/header.html` is overridden by project's `layouts/_partials/header.html`. **Do not use legacy `layouts/partials/`** — those won't be picked up under the new convention.
- **Home page:** PaperMod uses `list.html` for the home (gated on `profileMode.enabled`). Create `layouts/home.html` (Hugo's home-specific kind) — that wins over `list.html` for the home only, leaving section list pages (e.g. `/blog/`, `/categories/foo/`) on PaperMod's default `list.html` until we explicitly override them.
- **Sticky header math:** PaperMod's existing header CSS uses flex. Our wordmark version replaces the markup, so we own the height. Pin to `--nav-height: 64px` and offset `main` accordingly (or use `scroll-margin-top` for anchor links).
- **JS budget:** Filter logic is vanilla JS, no framework. Target ≤80 lines. Inject via `extend_footer.html`.
- **Font loading:** Google Fonts CDN for v1 (lower complexity). If we hit Lighthouse-perf issues, swap to self-hosted later — not v1 scope.
- **Don't touch the `themes/PaperMod` submodule.** All work lives in project root or `assets/` / `layouts/` / `content/`.

## Reference: design tokens

These are the canonical values. Put them in `:root` in `custom.css`. Don't hand-pick alternates — if a value isn't here, it's a default Inter/Fraunces value or it doesn't matter.

```css
:root {
  /* Color */
  --color-bg:            #FAFAF7;            /* near-white, slightly warm */
  --color-bg-surface:    #F4F1EC;            /* warm gray chip / surface */
  --color-bg-elevated:   #FFFFFF;            /* card background */
  --color-text:          #1A1A1A;            /* primary text */
  --color-text-muted:    #6B6B68;            /* meta, dates, captions */
  --color-text-subtle:   #9A9A95;            /* tertiary (timeline dots, hr) */
  --color-border:        #E5E3DE;            /* hairlines, card edges */
  --color-coral:         #F57A7A;            /* primary accent */
  --color-coral-deep:    #E96C6C;            /* hover-darker coral */
  --color-coral-soft:    rgba(245, 122, 122, 0.12);  /* tints (active pill bg if needed) */

  /* Type */
  --font-display:        'Fraunces', Georgia, 'Times New Roman', serif;
  --font-body:           'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono:           'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, monospace;

  --fs-display:          clamp(2.5rem, 6vw, 3.75rem);   /* hero name */
  --fs-h1:               clamp(2rem, 4.5vw, 2.75rem);   /* page H1 */
  --fs-h2:               1.5rem;                         /* section heading, card title */
  --fs-h3:               1.125rem;                       /* subheads */
  --fs-body:             1rem;                           /* 16px */
  --fs-small:            0.875rem;                       /* 14px */
  --fs-meta:             0.75rem;                        /* 12px, uppercase often */

  --lh-tight:            1.15;
  --lh-snug:             1.4;
  --lh-body:             1.65;

  /* Space */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 1rem;
  --space-4: 1.5rem;
  --space-5: 2rem;
  --space-6: 3rem;
  --space-7: 5rem;
  --space-8: 8rem;

  /* Misc */
  --radius:              6px;
  --radius-sm:           3px;
  --radius-pill:         999px;
  --transition:          200ms ease;
  --transition-fast:     120ms ease;
  --shadow-card:         0 1px 3px rgba(20, 20, 20, 0.05);
  --shadow-card-hover:   0 6px 18px rgba(20, 20, 20, 0.09);
  --max-width-prose:     720px;                /* single post body */
  --max-width-grid:      1180px;               /* homepage/list page max */
  --nav-height:          64px;
  --letter-spacing-caps: 0.18em;               /* wordmark, filter labels */
}
```

---

## Phase 1 — Foundation: fonts, tokens, base typography

**Goal:** Site loads Fraunces + Inter; tokens are available everywhere; default typography looks right even without any other changes.

**Files:**

1. **Create `layouts/_partials/extend_head.html`** — adds Google Fonts links. Use `display=swap` and preconnect.
   ```html
   <link rel="preconnect" href="https://fonts.googleapis.com">
   <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
   <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,300;9..144,400;9..144,500;9..144,600&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
   ```

2. **Create `assets/css/extended/01-tokens.css`** — only the `:root` block from the design-tokens table above. (Numeric prefix forces load order; PaperMod includes alphabetically.)

3. **Create `assets/css/extended/02-base.css`** — global base styles:
   - Apply `font-family: var(--font-body)` to `body`.
   - Apply `font-family: var(--font-display)` to `h1, h2, h3, h4, .display`.
   - Set body bg/text/line-height from tokens.
   - Inline links: coral with a 1px coral underline at 0.85 opacity, 100% opacity on hover.
   - `hr` styled as a thin `--color-border` line with vertical margin `--space-5`.
   - `pre, code` get `--font-mono`.
   - Apply `scroll-margin-top: calc(var(--nav-height) + var(--space-3))` to `h1, h2, h3, h4` for anchor links under sticky nav.

4. **Replace existing `assets/scss/custom.scss`** with the comment line "Moved to assets/css/extended/. Kept as placeholder so Hugo SCSS pipeline doesn't complain." (Or remove the file — verify the project doesn't reference it from any template after the layout cleanup.)

**Verification:** Run `hugo server`. Pages still render, but text is now in Inter, headings in Fraunces. No console errors. View source — Google Fonts request is in `<head>`.

---

## Phase 2 — Hugo config trim

**Goal:** Turn off PaperMod features we explicitly dropped; remove cruft.

**File:** `hugo.toml`

Apply these changes (don't blanket-rewrite; minimum diff):

- `[params]`: add `disableThemeToggle = true` and `defaultTheme = "light"`. Remove `ShowReadingTime`, `ShowCodeCopyButtons`, `ShowBreadCrumbs` if you want them off (recommended off for a small blog — less clutter; turn back on later if desired).
- `[params.profileMode]`: set `enabled = false`. Keep the rest of the block; it's ignored when disabled.
- Remove `[params.homeInfoParams]` block entirely — our custom homepage owns the hero, this would render twice otherwise.
- Confirm `[markup.goldmark.renderer]` still has `unsafe = true` (we use raw HTML in posts for `<small>` footers).

**Verification:** `hugo --logLevel info` — no warnings about unrecognized params; no theme toggle in nav (you'll redo the nav in Phase 3 but the toggle should already be gone).

---

## Phase 3 — Header: wordmark nav

**Goal:** Replace PaperMod's flex header with a sticky wordmark + menu, coral underline on active/hover.

**Files:**

1. **`layouts/_partials/header.html`** (override):
   - Markup outline:
     ```html
     <header class="site-header" id="site-header">
       <div class="site-header__inner">
         <a class="site-wordmark" href="{{ "" | absLangURL }}">
           Finn-Henrik Barton
         </a>
         <nav class="site-nav" aria-label="Primary">
           <ul>
             {{- range site.Menus.main }}
             {{- $url := cond (strings.HasSuffix .URL "/") .URL (printf "%s/" .URL) | absLangURL }}
             {{- $current := $.Permalink | absLangURL }}
             <li>
               <a href="{{ .URL | absLangURL }}"
                  class="{{ if eq $url $current }}is-active{{ end }}">
                 {{ .Name }}
               </a>
             </li>
             {{- end }}
           </ul>
         </nav>
         <button class="nav-toggle" aria-label="Toggle menu" aria-expanded="false">
           <span></span><span></span><span></span>
         </button>
       </div>
     </header>
     ```
   - Keep the menu config from `hugo.toml` driving the items.
   - The `<button class="nav-toggle">` is for mobile only; CSS hides it ≥768px.

2. **`assets/css/extended/03-header.css`** — sticky positioning, wordmark styling, hover/active states:
   - `.site-header`: `position: sticky; top: 0; z-index: 50; background: rgba(250,250,247,0.85); backdrop-filter: saturate(150%) blur(8px);`. Height `var(--nav-height)`. Bottom hairline `--color-border`.
   - `.site-header__inner`: flex, `justify-content: space-between`, `align-items: center`, `max-width: var(--max-width-grid)`, horizontal padding `--space-4`, full nav height.
   - `.site-wordmark`: `font-family: var(--font-display); text-transform: uppercase; letter-spacing: var(--letter-spacing-caps); font-weight: 500; font-size: 0.875rem; color: var(--color-text); text-decoration: none;`. On `:hover` no special treatment (it's a logo, not a menu item).
   - `.site-nav ul`: flex, gap `--space-5`, list-style none.
   - `.site-nav a`: `font-family: var(--font-body); font-size: 0.9375rem; color: var(--color-text); text-decoration: none; position: relative; padding-bottom: 2px;`.
   - `.site-nav a::after`: pseudo-element bottom underline, `background: var(--color-coral)`, `width: 0`, `transition: width var(--transition)`. On `:hover` and `.is-active`, set `width: 100%`.
   - Mobile (`@media (max-width: 767px)`):
     - `.site-nav` collapses to off-canvas (slide-in from right) or simple stacked dropdown
     - `.nav-toggle` is visible; toggles `data-nav-open` attribute on `<header>`
     - Simplest: stacked dropdown that slides down under header when open; the toggle just toggles a class
   - Add a tiny inline script (5–10 lines) or include in the unified `99-app.js` later (Phase 5) to wire up the toggle.

**Verification:** Nav stays at top on scroll. Wordmark renders in Fraunces caps. Active page underlines in coral. Hover on inactive items animates coral underline in. Mobile shows hamburger; tapping opens menu.

---

## Phase 4 — Homepage: hero + filter + card grid

**Goal:** Replace the default home with personality hero + language filter row + 3-col blog card grid.

**Files:**

1. **`content/_index.md`** — update front matter to feed the hero (don't put the bio in the body anymore; the layout will pull it from front-matter params for cleaner separation).
   ```yaml
   ---
   title: "Finn-Henrik Barton"
   tagline: "Economist · Policy & Data · Environment, Urban & Spatial"
   bio: "I'm an economist working on portfolio quality at AIIB in Beijing. On weekends I write here about environmental economics, urban policy, and code I'm tinkering with."
   ---
   ```
   (Leave the body empty or just a hidden comment. The layout reads `.Params.tagline` and `.Params.bio`.)

2. **`layouts/home.html`** — full custom homepage. Outline:
   ```html
   {{ define "main" }}
   <section class="hero">
     <div class="hero__inner">
       <img class="hero__avatar"
            src="/img/avatar.png"
            alt="Portrait of Finn-Henrik Barton"
            width="140" height="140" loading="eager">
       <div class="hero__text">
         <h1 class="hero__name">{{ .Title }}</h1>
         <p class="hero__bio">{{ .Params.bio }}</p>
         <ul class="hero__socials" aria-label="Social links">
           {{- range site.Params.socialIcons }}
           <li>
             <a href="{{ .url }}" aria-label="{{ .name }}" rel="noopener">
               {{ partial "social_icon.html" .name }}
             </a>
           </li>
           {{- end }}
         </ul>
       </div>
     </div>
   </section>

   <hr class="hero-rule">

   <section class="feed" id="feed">
     <header class="feed__header">
       <h2 class="feed__title">Writing</h2>
       <div class="feed__filters" role="group" aria-label="Filter posts by language">
         <button class="pill is-active" data-filter="all">All</button>
         <button class="pill" data-filter="r">R</button>
         <button class="pill" data-filter="python">Python</button>
         <button class="pill" data-filter="julia">Julia</button>
       </div>
     </header>

     <div class="feed__grid" data-grid>
       {{- $posts := where site.RegularPages "Type" "blog" }}
       {{- $posts = $posts.ByDate.Reverse }}
       {{- range $posts }}
         {{- partial "card.html" . }}
       {{- end }}
     </div>
   </section>
   {{ end }}
   ```

3. **`layouts/_partials/card.html`** — single card markup:
   ```html
   {{- $lang := "" }}
   {{- range .Params.tags }}
     {{- $l := lower . }}
     {{- if in (slice "r" "python" "julia") $l }}{{- $lang = $l }}{{- end }}
   {{- end }}
   {{- $topic := "" }}
   {{- with .Params.categories }}{{- $topic = index . 0 }}{{- end }}
   {{- $topicSlug := $topic | urlize }}
   {{- $imgPath := "" }}
   {{- with .Resources.GetMatch "featured.*" }}
     {{- $img := .Fill "560x420 q85 Center" }}
     {{- $imgPath = $img.RelPermalink }}
   {{- end }}

   <article class="card" data-lang="{{ $lang }}" data-topic="{{ $topicSlug }}">
     <a class="card__link" href="{{ .Permalink }}" aria-label="{{ .Title }}">
       {{- if $imgPath }}
       <div class="card__media">
         <img src="{{ $imgPath }}" alt="" loading="lazy" width="560" height="420">
       </div>
       {{- end }}
       <div class="card__body">
         {{- if $topic }}
         <span class="card__chip"
               data-topic-link="{{ $topicSlug }}">{{ $topic | title }}</span>
         {{- end }}
         <h3 class="card__title">{{ .Title }}</h3>
         <p class="card__summary">{{ .Params.subtitle | default .Summary | plainify | truncate 130 }}</p>
         <time class="card__date" datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "Jan 2006" }}</time>
       </div>
     </a>
   </article>
   ```
   Notes:
   - `Fill "560x420"` crops to 4:3 at retina-friendly resolution.
   - `data-lang` empty means non-language post (only visible under "All").
   - The whole card is wrapped in `<a>` for one click target; the topic chip's click-through to `/categories/{slug}/` is handled in JS (preventDefault on `.card__chip`, then navigate). This keeps the card a single accessibility target while still allowing chip-as-filter behavior.

4. **`assets/css/extended/04-home.css`** — hero, filters, grid, card.
   - `.hero`: padding `--space-7 --space-4`, max-width `--max-width-grid`, centered.
   - `.hero__inner`: flex, gap `--space-5`, `align-items: center`. Stack to column at <640px.
   - `.hero__avatar`: 140×140, `border-radius: 50%`, `object-fit: cover`.
   - `.hero__name`: `font: 500 var(--fs-display)/var(--lh-tight) var(--font-display)`, margin 0 0 var(--space-2) 0.
   - `.hero__bio`: `font: 400 1.0625rem/var(--lh-body) var(--font-body)`, color `--color-text`, max-width 56ch.
   - `.hero__socials`: flex, gap `--space-3`, list-style none, margin-top `--space-3`. Icons inherit `currentColor`; hover → coral.
   - `.hero-rule`: full-width `--color-border` hairline, max-width `--max-width-grid`, margin `var(--space-5) auto`.
   - `.feed`: max-width `--max-width-grid`, padding `0 --space-4 --space-7`.
   - `.feed__header`: flex, `justify-content: space-between`, `align-items: baseline`, margin-bottom `--space-5`.
   - `.feed__title`: `font-family: var(--font-display); font-size: var(--fs-h2); font-weight: 500;`.
   - `.feed__filters`: flex, gap `--space-2`.
   - `.pill`: `border: 1px solid var(--color-border); background: transparent; border-radius: var(--radius-pill); padding: 0.375rem 0.875rem; font: 500 var(--fs-small)/1 var(--font-body); color: var(--color-text-muted); cursor: pointer; transition: var(--transition-fast);`.
   - `.pill:hover`: `border-color: var(--color-coral); color: var(--color-coral);`.
   - `.pill.is-active`: `background: var(--color-coral); border-color: var(--color-coral); color: white;`.
   - `.feed__grid`: CSS grid, `grid-template-columns: repeat(3, 1fr); gap: var(--space-5);`. At ≤900px → `repeat(2, 1fr)`; at ≤560px → `1fr`.
   - `.card`: `background: var(--color-bg-elevated); border: 1px solid var(--color-border); border-radius: var(--radius); overflow: hidden; transition: transform var(--transition), box-shadow var(--transition);`.
   - `.card__link`: `display: block; color: inherit; text-decoration: none;`.
   - `.card__media img`: `width: 100%; height: auto; display: block; aspect-ratio: 4/3; object-fit: cover;`.
   - `.card__body`: padding `--space-4`.
   - `.card__chip`: inline-block, `background: var(--color-bg-surface); padding: 0.25rem 0.625rem; border-radius: var(--radius-pill); font: 500 var(--fs-meta)/1 var(--font-body); text-transform: uppercase; letter-spacing: 0.04em; color: var(--color-text-muted); border: 1px solid transparent; transition: var(--transition-fast);`.
   - `.card__chip:hover`: `border-color: var(--color-coral); color: var(--color-coral);`.
   - `.card__title`: `font: 500 var(--fs-h2)/var(--lh-snug) var(--font-display); margin: var(--space-2) 0 var(--space-2); color: var(--color-text); position: relative; display: inline; background-image: linear-gradient(var(--color-coral), var(--color-coral)); background-size: 0% 1.5px; background-position: 0 100%; background-repeat: no-repeat; transition: background-size var(--transition);`.
   - `.card:hover .card__title`: `background-size: 100% 1.5px;`.
   - `.card:hover`: `transform: translateY(-4px); box-shadow: var(--shadow-card-hover);`.
   - `.card__summary`: `color: var(--color-text-muted); font-size: var(--fs-small); line-height: var(--lh-body); margin-bottom: var(--space-3);`.
   - `.card__date`: `display: block; font-size: var(--fs-meta); color: var(--color-text-subtle); text-align: right; text-transform: uppercase; letter-spacing: 0.04em;`.

5. **`layouts/_partials/extend_footer.html`** — inject filter JS:
   ```html
   <script>
   (function(){
     const grid = document.querySelector('[data-grid]');
     if (!grid) return;
     const pills = document.querySelectorAll('.feed__filters .pill');
     pills.forEach(pill => {
       pill.addEventListener('click', () => {
         const filter = pill.dataset.filter;
         pills.forEach(p => p.classList.toggle('is-active', p === pill));
         grid.querySelectorAll('.card').forEach(card => {
           const lang = card.dataset.lang || '';
           card.hidden = filter !== 'all' && lang !== filter;
         });
       });
     });

     // Topic chip click → navigate to /categories/{slug}/
     grid.querySelectorAll('[data-topic-link]').forEach(chip => {
       chip.addEventListener('click', (e) => {
         e.preventDefault();
         e.stopPropagation();
         window.location.href = '/categories/' + chip.dataset.topicLink + '/';
       });
     });

     // Mobile nav toggle
     const navToggle = document.querySelector('.nav-toggle');
     const header = document.getElementById('site-header');
     if (navToggle && header) {
       navToggle.addEventListener('click', () => {
         const open = header.toggleAttribute('data-nav-open');
         navToggle.setAttribute('aria-expanded', open);
       });
     }
   })();
   </script>
   ```

**Verification:**
- Home page shows hero (avatar + name + bio + socials), horizontal rule, "Writing" heading + filter pills, 3-col grid of 7 cards.
- Click "Julia" — only the Julia-tagged posts remain (cruising-for-parking, optimal-firm-abatement).
- Click "All" — all 7 reappear.
- Hover a card — lifts 4px, title gets coral underline.
- Click "Carbon Accounting" chip on a card — navigates to `/categories/carbon-accounting/`.
- Resize to 600px — grid collapses to 1 column.
- Lighthouse: no console errors.

---

## Phase 5 — Section list pages (`/blog/`, `/categories/*/`, `/tags/*/`)

**Goal:** When a visitor follows a topic chip (`/categories/carbon-accounting/`) or visits `/blog/`, they get the same card grid layout — not PaperMod's default list.

**Files:**

1. **`layouts/_default/list.html`** — override. Pseudocode:
   ```html
   {{ define "main" }}
   {{ if not .IsHome }}
   <header class="list-header">
     <h1>{{ .Title }}</h1>
     {{ with .Description }}<p>{{ . | markdownify }}</p>{{ end }}
   </header>
   {{ end }}

   <div class="feed__grid">
     {{- range (.Paginate .RegularPages).Pages }}
       {{- partial "card.html" . }}
     {{- end }}
   </div>

   {{- /* simple prev/next pagination */ -}}
   {{ end }}
   ```
   - Reuses the same `card.html` partial — single source of truth for card markup.
   - The home page is NOT covered by this file (we have `home.html` for that).

2. **`assets/css/extended/05-list.css`** — minor styling for the list header (`.list-header h1`: Fraunces, `--fs-h1`, margin), reuse `.feed__grid` styling from Phase 4 (it's already in `04-home.css`).

**Verification:** Visit `/blog/` — card grid. Visit `/categories/environment/` — card grid filtered to environment posts.

---

## Phase 6 — About page: timeline

**Goal:** Render the Experience section as a timeline; the rest stays plain prose.

**Approach:** Two clean options:
- **(A) Shortcode** — write `{{< timeline >}}...{{< /timeline >}}` blocks in `about.md`. Most flexible for ongoing editing.
- **(B) Custom layout** — `layouts/_default/single.html` with conditional logic for the about page. More magical, less editable.

**Recommendation: A (shortcode).** Editing experience entries stays in markdown.

**Files:**

1. **`layouts/_shortcodes/timeline.html`** — the wrapping shortcode (vertical line container):
   ```html
   <div class="timeline">
     {{ .Inner | markdownify }}
   </div>
   ```

2. **`layouts/_shortcodes/role.html`** — single role entry. Used inside `{{< timeline >}}`. Takes named params.
   ```html
   <div class="timeline__entry{{ if eq (.Get "current") "true" }} is-current{{ end }}">
     <div class="timeline__date">{{ .Get "year" }}</div>
     <div class="timeline__body">
       <h3 class="timeline__role">{{ .Get "title" }}</h3>
       <div class="timeline__company">{{ .Get "company" }} · {{ .Get "location" }}</div>
       <div class="timeline__period">{{ .Get "period" }}</div>
       <p class="timeline__desc">{{ .Inner | markdownify }}</p>
     </div>
   </div>
   ```

3. **Update `content/about.md`** — replace the prose Experience section with shortcode usage:
   ```markdown
   ## Experience

   {{< timeline >}}
   {{< role year="2024" title="Policy & Data Associate — Portfolio Quality" company="AIIB" location="Beijing" period="April 2024 – present" current="true" >}}
   Coordinating the Bank's internal ESG efforts; supporting policy assurance for environmental and social safeguards; providing analytical and data support for AIIB's Policy unit.
   {{< /role >}}

   {{< role year="2022" title="Data Scientist" company="Carbon Trust" location="London" period="July 2022 – April 2024" >}}
   Pioneered development of regional and temporal EEIO models for scope 3 GHG accounting. ...
   {{< /role >}}

   {{< role year="2020" title="Economic Modeller" company="Cambridge Econometrics" location="Cambridge / Brussels" period="September 2020 – July 2022" >}}
   ...
   {{< /role >}}

   {{< role year="2019" title="Research & Teaching Assistant" company="NOVA SBE" location="Lisbon" period="February 2019 – September 2020" >}}
   ...
   {{< /role >}}
   {{< /timeline >}}
   ```

4. **`assets/css/extended/06-about.css`** — timeline styling:
   - `.timeline`: `position: relative; padding-left: 6rem;` (room for date column).
   - `.timeline::before`: pseudo vertical line at `left: 5rem`, `top: 0`, `bottom: 0`, `width: 1px`, `background: var(--color-border);`.
   - `.timeline__entry`: relative, padding-bottom `--space-6`, last-child `padding-bottom: 0`.
   - `.timeline__entry::before`: dot at `left: -1.25rem; top: 0.4rem; width: 10px; height: 10px; border-radius: 50%; background: var(--color-bg); border: 2px solid var(--color-text-subtle);` (hollow dot for past).
   - `.timeline__entry.is-current::before`: `background: var(--color-coral); border-color: var(--color-coral);` (filled coral for current).
   - `.timeline__date`: position absolute, `left: -6rem`, top 0, font Inter 500, color `--color-text-muted`, width 4rem, text-align right.
   - `.timeline__role`: Fraunces 500, `--fs-h3`, margin 0.
   - `.timeline__company`: Inter, `--fs-small`, color `--color-text-muted`.
   - `.timeline__period`: Inter, `--fs-meta`, color `--color-text-subtle`, uppercase, letter-spacing 0.04em.
   - `.timeline__desc`: Inter, normal, margin-top `--space-3`.
   - Mobile (`@media (max-width: 560px)`): collapse the absolute-positioned date column; render year inline above the role; remove left padding; vertical line stays.

5. **Hero block at top of About page** — within `about.md`, render the avatar + bio at the top. Either:
   - Use raw HTML at the top of the markdown (PaperMod's goldmark `unsafe = true` allows it).
   - Or have it appear as a generic `about-hero` partial called from a custom about layout. **Recommend the HTML-in-markdown approach for simplicity** — one less template file.

   Suggested top of `about.md`:
   ```markdown
   <div class="about-hero">
     <img src="/img/avatar.png" alt="" class="about-hero__avatar" width="160" height="160">
     <div class="about-hero__text">
       <p class="about-hero__bio">Policy &amp; Data Associate at AIIB in Beijing, working on portfolio quality. Previously at Carbon Trust and Cambridge Econometrics on scope-3 carbon accounting and net-zero macroeconomic modelling. Interests: environmental economics, urban policy, and applied data.</p>
     </div>
   </div>
   ```

6. **Add to `06-about.css`** — styles for `.about-hero` (similar to homepage hero but slightly larger avatar).

**Verification:** Visit `/about/` — avatar + bio at top, then "Experience" with the timeline (current role in coral, others gray), then Education + Skills as plain prose.

---

## Phase 7 — Single post styling

**Goal:** Blog posts use the design system; titles are Fraunces, body is Inter at comfortable reading width, code blocks look clean.

**Approach:** No template override. PaperMod's `single.html` is fine — we just style its classes via CSS.

**Files:**

1. **`assets/css/extended/07-post.css`**:
   - `.post-title`: `font-family: var(--font-display); font-size: var(--fs-h1); font-weight: 500; line-height: var(--lh-tight); margin-bottom: var(--space-3);`.
   - `.post-meta`: `font-size: var(--fs-meta); color: var(--color-text-muted); text-transform: uppercase; letter-spacing: 0.04em; margin-bottom: var(--space-5);`.
   - `.post-content`: max-width `--max-width-prose`, margin 0 auto, font-size `--fs-body`, line-height `--lh-body`.
   - `.post-content h2`: Fraunces, `--fs-h2`, font-weight 500, margin-top `--space-6`, margin-bottom `--space-3`.
   - `.post-content h3`: Fraunces, `--fs-h3`, margin-top `--space-5`.
   - `.post-content p, .post-content ul, .post-content ol`: margin-bottom `--space-3`.
   - `.post-content a`: coral underlined links (already covered by base styles).
   - `.post-content img`: `width: 100%; height: auto; border-radius: var(--radius); margin: var(--space-4) 0;`.
   - `.post-content blockquote`: `border-left: 3px solid var(--color-coral); padding-left: var(--space-4); color: var(--color-text-muted); font-style: italic; margin: var(--space-4) 0;`.
   - `.post-content pre`: `background: #1A1A1A; color: #F5F5F2; border-radius: var(--radius); padding: var(--space-3) var(--space-4); overflow-x: auto; font-size: 0.875rem; line-height: 1.6;`.
   - `.post-content code:not(pre code)`: inline code — `background: var(--color-bg-surface); padding: 0.1rem 0.35rem; border-radius: 3px; font-size: 0.9em; color: var(--color-coral-deep);`.
   - **PaperMod also uses a generated highlight stylesheet** via the `chroma` setting in hugo.toml. The current value (`style = "github"`) produces a *light* code theme that will clash with the dark `pre` block above. Two options: (a) change `style` to a dark scheme (`monokai`, `dracula`, `nord`) to match; (b) keep `style = "github"` and make `pre` light-themed too. **Recommend (a) — `style = "github-dark"`** for visual punch in long code-heavy posts.

**Verification:** Open `/blog/optimal-firm-abatement/` — title in Fraunces, body in Inter at 720px max, code blocks in dark theme with syntax highlighting. Math (LaTeX) still renders via KaTeX.

---

## Phase 8 — Research page

**Goal:** Use the global type system; no structural changes.

**Files:** None new. The existing `content/research/_index.md` will pick up Fraunces headings and Inter body automatically once Phase 1's `02-base.css` is in.

**Optional polish:** Add a one-line "·" separator between author lists and publication titles using inline span classes if it reads too dense — defer until you see the rendered result.

**Verification:** Visit `/research/` — typography matches the rest of the site, no specific layout work required.

---

## Phase 9 — Footer

**Goal:** Minimal footer; not styled by PaperMod by default in a way we want.

**Files:**

1. **`layouts/_partials/footer.html`** — override PaperMod's footer.
   ```html
   <footer class="site-footer">
     <div class="site-footer__inner">
       <small>© {{ now.Year }} Finn-Henrik Barton · <a href="https://github.com/FinnHB">GitHub</a> · <a href="https://www.linkedin.com/in/finn-henrik-barton-53193214b/">LinkedIn</a></small>
     </div>
   </footer>
   ```

2. **Add to `02-base.css`** (or a new `08-footer.css`):
   - `.site-footer`: margin-top `--space-8`, padding `--space-5 --space-4`, border-top `1px solid var(--color-border)`.
   - `.site-footer__inner`: max-width `--max-width-grid`, margin 0 auto, color `--color-text-muted`, font-size `--fs-small`.
   - `.site-footer a`: color inherit, underline.

**Verification:** Every page now ends with the minimal footer.

---

## Phase 10 — QA pass

Open each in browser at the running `hugo server`. Mark each item as it passes:

- [ ] Home: hero displays correctly with avatar, name, bio, socials
- [ ] Home: horizontal rule sits between hero and grid
- [ ] Home: filter pills work (All / R / Python / Julia toggle cards)
- [ ] Home: card hover shows 4px lift and coral title underline
- [ ] Home: clicking a topic chip navigates to `/categories/{slug}/`
- [ ] Home: 7 cards visible under "All"; counts under each language match what's expected
- [ ] Home: responsive — 3 → 2 → 1 columns
- [ ] Nav: wordmark renders in Fraunces small-caps
- [ ] Nav: sticky on scroll; active page underlined coral
- [ ] Nav: mobile hamburger toggles menu
- [ ] About: avatar + bio at top, Experience as timeline (current role coral), Education + Skills as plain prose
- [ ] Research: lists all 6 publications in clean type
- [ ] Single post (`/blog/spend-ef-intro/`): Fraunces title, Inter body, math renders (KaTeX), code blocks dark
- [ ] Single post (`/blog/optimal-firm-abatement/`): same, plus Julia code highlights properly
- [ ] Categories page (`/categories/environment/`): card grid (not PaperMod default)
- [ ] Tags page (`/tags/featured/`): card grid
- [ ] Footer: minimal copyright + links on every page
- [ ] Lighthouse (dev): no console errors, no accessibility AA violations
- [ ] Mobile (responsive 360px): everything readable, no horizontal scroll
- [ ] Tablet (responsive 768px): 2-col grid, full nav

---

## Commit + push checklist

Once Phase 10 passes:

1. `git status` — review what changed. Expected changes:
   - New: `layouts/home.html`, `layouts/_default/list.html`, `layouts/_partials/header.html`, `layouts/_partials/footer.html`, `layouts/_partials/extend_head.html`, `layouts/_partials/extend_footer.html`, `layouts/_partials/card.html`, `layouts/_shortcodes/timeline.html`, `layouts/_shortcodes/role.html`
   - New: `assets/css/extended/*.css` files (01-tokens, 02-base, 03-header, 04-home, 05-list, 06-about, 07-post)
   - Modified: `hugo.toml`, `content/_index.md`, `content/about.md`
   - Removed: `assets/scss/custom.scss` (if you chose to delete rather than empty)
2. Commit message suggestion:
   ```
   Apply Refined Isabella redesign

   Custom homepage with personality hero + language filter + 3-col card
   grid. Wordmark sticky nav in Fraunces. Experience timeline on About.
   Drops dark mode; coral applied as scarce interactive accent.

   Implementation per docs/implementation-plan.md. Design tokens and
   decisions in CONTEXT.md.

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   ```
3. `git push origin main` — only after Finn approves the local preview.

---

## What's deliberately deferred (don't build in this pass)

- View transitions / SPA-like navigation
- Search
- Comments (utterances/giscus)
- Self-hosted fonts (revisit if Lighthouse perf < 90)
- Per-post custom cover images at higher resolution
- Dark mode (we said no)
- RSS feed styling (Hugo's default is fine for v1)
- Analytics

---

## Open decisions Sonnet may need to make in flight

These are small enough to decide on the fly. If unclear, pick the simplest option and note it in the commit.

- **Topic-chip → category navigation**: if a post's primary category doesn't have a populated `/categories/{slug}/` page (e.g. spelling mismatch), the navigation will 404. Mitigation: log the topic slugs from all posts; verify category pages exist after build. If not, normalize the categories in front matter.
- **Avatar source**: `/static/img/avatar.png` is what we have; if it looks low-res at 140px display (avatar is currently being served at much smaller), generate a 320px version for retina via Hugo image processing within the home.html partial.
- **Bio paragraph wording on home**: the placeholder text in `_index.md` Phase 4 is a draft. Sonnet should propose tightening it to ≤2 sentences during implementation; show options to Finn before final commit.
- **Footer link list**: kept to GitHub + LinkedIn for v1. Adding email / RSS / Twitter is fine; just don't add a 4-column footer.
