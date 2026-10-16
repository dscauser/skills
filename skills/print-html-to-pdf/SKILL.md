---
name: print-html-to-pdf
description: Designs a page in HTML and CSS (plain or Tailwind) and prints it to a real vector PDF with headless Chromium via Playwright, so text stays selectable, searchable and editable instead of a flattened image. Writes print-ready HTML (@page size and margins, page breaks, page numbers, SVG charts), runs a script that finishes animations, loads scroll-triggered content and warns about anything that will not survive print, then checks the pages. Use whenever the user wants a new designed PDF of any kind (report, brochure, one-pager, flyer, poster, handout, invoice, quote, certificate, menu, CV), even if they never mention HTML; asks to convert or export an HTML page or URL to PDF; is building PDFs with Playwright or Puppeteer page.pdf; wants a PDF that is "not just an image", editable or searchable, or complains that an HTML-to-PDF export came out blank, cut off, blurry or broken across pages.
---

# Print HTML to PDF

Models design well in HTML and badly in PDF libraries. So design in HTML,
then let Chromium's print engine make the PDF. Its output is vector: real
text with embedded fonts, CSS shapes and SVG as paths. What goes wrong is
screen-only design (full-height heroes, sticky navs, scroll animations,
canvas charts), not the conversion. Design for paper from the start.

## Workflow

1. **Load the context.** Look for `pdf-context.md` in the workspace, then
   `context.md` next to this SKILL.md; the first one found wins. If found,
   read it and follow it: its colours, fonts, logo (paths are relative to
   the file), page defaults and voice override the design defaults, and
   its "never" list overrides everything except the user's brief. If it
   only says not to ask, carry on without one.

   If neither exists and this is a new designed document, ask once, in the
   same message as any other questions, whether to set one up: (a) answer
   a few questions now, (b) point to a source (brand guidelines PDF,
   website, an existing document or deck) to extract colours, fonts and
   rules from, (c) skip for now, or (d) never ask again. For (a) or (b),
   build `context.md` from [context.example.md](context.example.md),
   keeping only fields with real answers; never guess hex values or font
   names. Show it to the user before saving. For (d), save a `context.md`
   containing only `No brand context. Do not ask.` Logo and font files go
   in `brand/` next to it. Both stay out of git in the skills repo.

2. **Settle the page.** Paper size and orientation (A4 unless the user is in
   the US or says otherwise), paginated document or a single tall page
   (`--single-page`, for posters and one-pagers shown on screen), and
   whether anyone will print it on paper. Ask only if it is unclear and
   changes the build.

3. **Plan the design** (new documents). Read
   [references/design.md](references/design.md). Name the genre, the reader
   and how they read it. Take colours, type and rules from the context file
   where it sets them, and plan only the rest. Write a short plan: 4 to 6
   colours, one or two typefaces with a `pt` scale, a grid in `mm`, and the
   one memorable element. Check the plan against the list of generated-page defaults
   there and change anything you would have produced for any brief.

4. **Write the HTML for print.** For a new document, copy
   [assets/print-starter.html](assets/print-starter.html) and keep its PRINT
   BASE block: `@page` size, margins and page numbers, colour-exact
   printing, break rules. Follow
   [references/print-rules.md](references/print-rules.md), which lists what
   does not survive print and what to use instead. Tailwind is fine. In
   short:
   - Size in `mm` and `pt`, never `vh`. Keep every block shorter than the
     usable page height.
   - `break-inside: avoid` on cards, figures and rows; `break-before: page`
     for new sections.
   - No fixed or sticky elements, scroll reveals, animations, canvas charts,
     backdrop blur, blend modes, tabs or closed accordions. Charts as inline
     SVG. All content visible by default.
   - Real text everywhere, never text inside images.

   For an existing HTML page the user wants as a PDF, convert it first
   (step 5), then fix what the warnings and the check (step 6) show. Add a
   `@media print { ... }` block rather than rewriting the screen design.

5. **Convert.** Needs `pip install playwright`. It uses Playwright's
   Chromium if installed, otherwise Edge or Chrome, so
   `python -m playwright install chromium` is only needed when neither
   browser exists.

   ```
   python scripts/html_to_pdf.py page.html [out.pdf]
   ```

   Options: `--format Letter`, `--landscape`, `--margin 15mm` (only used
   when the page has no `@page` rule), `--single-page --width 1200`,
   `--media screen`, `--wait 1000`, `--wait-for <selector>`, `--dark`,
   `--strict` (exit 2 on warnings). It accepts a URL as input.

   The script forces animations to their end state, scrolls through the page
   to trigger lazy images and scroll reveals, waits for fonts and images,
   then prints with backgrounds, CSS page size, tags and heading bookmarks.

6. **Read the warnings and check the pages.** Each `WARN` line names the
   elements to fix (canvas, blur, sticky, still-invisible text, `vh`,
   missing `@page`, broken images or fonts, closed `<details>`, content
   wider than the page). Fix the HTML and convert again. Then:
   - Render the pages to images (`pdftoppm -r 50 -png out.pdf p`, or
     `pypdfium2` where poppler is missing) and look at every page: blocks
     split across pages, near-empty pages, clipped edges, missing
     backgrounds. Then critique the design as a set (end of the design
     reference): made for this subject, one focal point a page, one thing
     removed.
   - Extract the text (`pdftotext out.pdf -` or pypdf) to confirm it is real
     text, not an image.
   - If the PDF will be edited, list the fonts (`pdffonts out.pdf`, or each
     page's `/Resources /Font` in pypdf). `Type 3` means awkward to edit.

7. **Deliver** the PDF path and page count, plus the HTML source so the user
   can edit and convert again. Say what was not checked.

## Gotchas

- A block taller than the page's usable height (page height minus `@page`
  top and bottom margins) splits or pushes onto a blank page. Count padding
  with `box-sizing: border-box`.
- Without `print-color-adjust: exact`, background colours disappear.
- Some fonts are embedded as Type 3: selectable but awkward to edit in a PDF
  editor. This covers fonts with CFF outlines (most `.otf`) and some web
  fonts (Inter from Google Fonts, for example; Lato and Roboto embed fine).
  When the user wants to edit the PDF, check the font types (step 6) and
  swap any Type 3 font for a TrueType one.
- The Tailwind Play CDN and web fonts need network access during
  conversion. Offline, use a compiled stylesheet and local font files.
- Table-of-contents page numbers, running chapter titles and footnotes need
  Paged.js: see the last section of the print rules.
- HTML form fields print as static boxes. Fillable PDF forms need a PDF
  library afterwards.
- If the user wants to keep editing the content itself, a Word document or a
  doc may suit them better than a PDF. Say so once.
