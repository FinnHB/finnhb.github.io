# Context

Personal portfolio and blog at fhbarton.com — built with Hugo + PaperMod, plain-Markdown blog posts. Acts as a digital CV without being formal: it should help people researching Finn-Henrik confirm they have the right person, host weekend writing, and build digital presence for future ventures.

## Glossary

### Isabella design
The visual identity inherited from the original (pre-PaperMod) version of the site, themed off the hugo-academic fork by Isabella. Defined by a coral pink primary accent (`#F57A7A`), cream secondary surface, a grainy noise overlay (`otis-redding.png`), `Calistoga` display type and `Work Sans` body. The current direction is **Refined Isabella**: keep the coral identity, drop the noise overlay, swap typography to **Fraunces** (display) + **Inter** (body), and apply coral as a scarce accent rather than an ambient tint.

### Coral
The brand accent color, `#F57A7A`. Used **only on interactive or important moments**: inline links, hover states, active nav underline, active filter pill, current-role dot on the About timeline. Never as ambient fill on chips, headings, or section dividers — scarcity preserves its signal.

### Personality hero
The block at the top of the homepage. Composition: small circular avatar on the left, name in Fraunces, a 2–3 sentence bio paragraph covering day job + weekend writing, inline social icons. Separated from the post grid by a horizontal rule. Optimized for someone arriving cold from a search result.

### Wordmark
The site identity in the top nav: `FINN-HENRIK BARTON` in Fraunces, letter-spaced small caps. Persistent across every page; carries the brand even on deep-linked blog posts. The nav itself is sticky with a translucent background on scroll. Active page gets a thin coral underline.

### Blog card
A single post tile in the homepage grid. Composition (top to bottom): featured image at 4:3 aspect ratio (`featured.jpg` in the post bundle), one small topic chip, Fraunces title, 1–2 line Inter summary, small right-aligned date. Hover state: 4px lift + coral underline on the title. Grid is 3 columns desktop, 2 tablet, 1 mobile.

### Language pills
The primary filter row above the homepage grid: `All / R / Python / Julia`. Filters by the post's language tag (lowercase `julia`, `python`, `r`). Active pill is coral-filled; inactive pills are warm-gray-outlined. Posts without a language tag (essays, opinion pieces) only appear under `All`.

### Topic chip
The single colored label on each blog card. Sourced from the post's primary topic tag (`Environment`, `Carbon Accounting`, `Urban`, `AI`, etc.). Default state: soft warm gray background, dark text. Hover: thin coral border. Clicking filters the homepage grid by that topic — provides a second navigation axis without adding a second filter row.

### Experience timeline
The Experience section on the About page. Layout: dates left-aligned in the margin, a vertical thin line connecting entries, role/company/description flush right. The current role gets a filled coral dot; prior roles get hollow gray dots. The rest of the About page (Education, Skills) stays as plain prose — visual restraint everywhere else.

## Decisions, in one place

| Area | Decision |
|---|---|
| Aesthetic | Refined Isabella: coral on near-white, no noise texture |
| Palette | `#FAFAF7` base, `#F57A7A` coral accent (scarce), warm gray surfaces |
| Typography | Fraunces (display, variable) + Inter (body/UI) |
| Dark mode | None (light only) |
| Top nav | Wordmark, sticky, coral underline on active/hover |
| Homepage hero | Avatar + name + 2–3 sentence bio + social icons + horizontal rule |
| Homepage grid | 3-col editorial cards (4:3 image, topic chip, title, summary, date) |
| Filters | Primary: language pills (All/R/Python/Julia). Secondary: clickable topic chip on each card |
| About page | Avatar + bio at top; Experience as timeline (coral dot on current role); Education + Skills as plain prose |
| Research page | Plain prose, styled via global type system (no special layout) |
| Build approach | Override PaperMod templates + `assets/css/extended/custom.css`; PaperMod stays a submodule |
