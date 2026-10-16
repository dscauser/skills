# Print rules for HTML that becomes a PDF

Chromium prints HTML to vector PDF: text stays text, CSS shapes and SVG stay
vector. What breaks is screen-only design. Each rule below fixes a failure
seen when converting AI-made pages.

## Page setup

- Set size and margins with `@page { size: A4; margin: 18mm 16mm 20mm; }`.
  Use `A4 landscape`, `Letter`, or explicit sizes like `210mm 297mm`.
- Page numbers and running text go in `@page` margin boxes, which Chromium
  supports: `@bottom-right { content: counter(page) " / " counter(pages); }`.
  Use `@page :first { ... content: none; }` to hide them on a cover.
- Size things in `mm` and `pt`. Usable height is page height minus top and
  bottom margins (A4 with 18mm + 20mm margins = 259mm). A block taller than
  that splits or spills onto a blank page. Use `box-sizing: border-box` so
  padding counts inside a block's height.
- Add `print-color-adjust: exact` (and `-webkit-print-color-adjust: exact`)
  on `html`, or background colours and fills are dropped.

## Pagination

- `break-inside: avoid` on cards, figures, tables rows, callouts, images and
  SVGs. `break-after: avoid` on headings so they are not stranded at the foot
  of a page.
- `break-before: page` to start a section on a new page (the starter uses a
  `.page-break` class).
- `thead { display: table-header-group; }` repeats table headers on each page.
- `orphans: 3; widows: 3;` on paragraphs.
- Grid and flex containers taller than a page can break badly. Keep them to
  rows that fit; let long content flow in normal blocks.

## Things that do not survive print

| Avoid | Why | Use instead |
|---|---|---|
| `100vh`, `h-screen`, `min-h-screen` | The viewport is not a page | Fixed `mm` heights or natural height |
| `position: fixed` / `sticky` (navs, headers, `fixed`, `sticky` in Tailwind) | Repeats on every page or overlaps text | Static elements; `@page` margin boxes for running headers |
| Scroll-reveal (start at `opacity-0`, shown by a scroll observer) | Nothing scrolls during print, so it prints blank | Visible by default; no reveal on print pages |
| Animations and transitions | Print captures one frame | Static final state |
| `<canvas>` charts (Chart.js, ECharts canvas mode) | Prints as an image | Inline SVG or an SVG chart library (D3, Recharts, Vega SVG) |
| `backdrop-filter`, `filter: blur`, `mix-blend-mode`, glassmorphism | Rasterised: blurry, not editable | Solid or semi-transparent fills |
| Text inside images, icon fonts for words | Not selectable or editable | Real text; inline SVG icons |
| Tabs, accordions, carousels, closed `<details>` | Only the visible state prints | Show all content; `<details open>` |
| Hover-only content and tooltips | Never shown | Put the content on the page |
| Dark backgrounds full-bleed | Heavy ink, `@page` margins stay white | Light background; colour in accents |
| Huge box-shadows | Can rasterise or look muddy | Borders or subtle shadows |

## Fonts

- Text is selectable and searchable with any font. For text that edits
  cleanly in Acrobat or Affinity, the font must embed as TrueType (CID
  TrueType / Type 0). Fonts with CFF outlines (most `.otf` files) and some
  web fonts embed as Type 3, which is awkward to edit. Tested: Lato, Roboto,
  Georgia and Segoe UI embed as TrueType; Inter from Google Fonts embeds as
  Type 3. Check with `pdffonts` or pypdf rather than assuming.
- Load web fonts with `<link>` or `@font-face`; the script waits for
  `document.fonts.ready`. Always give a system fallback.

## Tailwind

- Fine to use. The Play CDN (`<script src="https://cdn.tailwindcss.com">`)
  builds CSS in the browser, so the conversion needs network access; a
  compiled stylesheet works offline.
- Useful utilities: `print:hidden`, `print:block`, `break-inside-avoid`,
  `break-before-page`, `break-after-avoid`.
- Put `@page` rules and `print-color-adjust` in a `<style>` block after
  Tailwind; there are no utilities for them.
- Avoid `h-screen`, `min-h-screen`, `fixed`, `sticky`, `backdrop-blur-*`,
  `blur-*`, `mix-blend-*` and `dark:` variants that follow the system theme.

## Links and structure

- Links stay clickable, including `#anchor` links within the document. Use
  them for a table of contents.
- The script asks for a tagged PDF with bookmarks built from headings, so use
  a real heading hierarchy (`h1` > `h2` > `h3`).
- HTML form fields print as static boxes, not fillable PDF fields.

## When CSS paged media is not enough

Chromium does not support `target-counter()` (page numbers in a table of
contents), named strings for running chapter titles, or footnotes. For
those, add Paged.js (`pagedjs` on npm/unpkg, `paged.polyfill.js`) to the
page and convert with `--wait-for .pagedjs_pages --wait 500`.

## One-page designs

Posters, one-pagers and infographics designed for the screen can skip
pagination: `--single-page` prints the whole document as one tall page at
`--width` using screen styles. Text stays vector. Use it when page breaks
would cut the design, not for documents people will print on paper.
