#!/usr/bin/env python3
"""Render an HTML file or URL to a vector PDF with headless Chromium (Playwright).

Text stays real text (selectable, searchable, editable in a PDF editor), and
CSS shapes and SVG stay vector. Before printing it finishes animations, scrolls
the page so scroll-triggered and lazy content loads, waits for fonts and
images, and prints warnings for things that will not survive print.

  python html_to_pdf.py page.html                  -> page.pdf, paginated, @page size or A4
  python html_to_pdf.py page.html out.pdf --format Letter --landscape
  python html_to_pdf.py poster.html --single-page  -> one tall page, screen styles
  python html_to_pdf.py https://example.com site.pdf --media screen

Needs: pip install playwright. If no Playwright browser is installed it falls
back to installed Edge, then Chrome, so `playwright install chromium` is optional.
Exit code: 0 = PDF written, 1 = failed, 2 = PDF written with warnings (with --strict).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    sys.exit("Playwright is not installed. Run: pip install playwright")

# Jump every animation to its end state and drop transitions, so nothing is
# caught half-faded or still at opacity 0 when the page is printed.
FINISH_MOTION_CSS = """
*, *::before, *::after {
  animation-duration: 0s !important;
  animation-delay: 0s !important;
  animation-iteration-count: 1 !important;
  transition: none !important;
  scroll-behavior: auto !important;
}
"""

SCROLL_THROUGH_JS = """
async () => {
  document.querySelectorAll('img[loading="lazy"]').forEach(i => { i.loading = 'eager'; });
  const step = Math.max(200, Math.floor(window.innerHeight * 0.8));
  for (let y = 0; y < document.documentElement.scrollHeight; y += step) {
    window.scrollTo(0, y);
    await new Promise(r => setTimeout(r, 60));
  }
  window.scrollTo(0, document.documentElement.scrollHeight);
  await new Promise(r => setTimeout(r, 150));
  window.scrollTo(0, 0);
}
"""

SETTLE_JS = """
async () => {
  if (document.fonts && document.fonts.ready) await document.fonts.ready;
  await Promise.all([...document.images].filter(i => !i.complete).map(i =>
    new Promise(r => { i.addEventListener('load', r, {once: true}); i.addEventListener('error', r, {once: true}); })));
  await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
}
"""

# Single-page mode: while printing, vh resolves against the PDF page, so an
# h-screen hero would grow to the full document height and push the rest off
# the page. Pin vh heights to their on-screen pixel size first.
FREEZE_VH_JS = r"""
() => {
  const hits = [];
  const scan = rules => { for (const r of rules) {
    if (r.cssRules) scan(r.cssRules);
    if (!r.style || !r.selectorText) continue;
    const props = ['height', 'min-height'].filter(p => /\d(\.\d+)?(s|l|d)?vh\b/.test(r.style.getPropertyValue(p)));
    if (props.length) hits.push([r.selectorText, props]);
  }};
  for (const sheet of document.styleSheets) { try { scan(sheet.cssRules); } catch (e) {} }
  const els = [...document.querySelectorAll('[style*="vh"]')].map(el => [el, ['height', 'min-height']]);
  for (const [sel, props] of hits) { try { document.querySelectorAll(sel).forEach(el => els.push([el, props])); } catch (e) {} }
  const sized = els.map(([el, props]) => [el, props, el.getBoundingClientRect().height]);
  for (const [el, props, h] of sized) {
    el.style.setProperty('min-height', h + 'px', 'important');
    if (props.includes('height')) el.style.setProperty('height', 'auto', 'important');
  }
}
"""

# Read-only checks for things that print badly. Returns a list of strings.
LINT_JS = r"""
() => {
  const out = [];
  const label = el => {
    let s = el.tagName.toLowerCase();
    if (el.id) s += '#' + el.id;
    const cls = (typeof el.className === 'string' ? el.className : '').trim().split(/\s+/).filter(Boolean).slice(0, 3);
    if (cls.length) s += '.' + cls.join('.');
    return s;
  };
  const sample = els => els.slice(0, 4).map(label).join(', ') + (els.length > 4 ? ` (+${els.length - 4} more)` : '');
  const all = [...document.body.querySelectorAll('*')];
  const visible = el => { const r = el.getBoundingClientRect(); return r.width > 0 && r.height > 0; };

  const canvases = all.filter(el => el.tagName === 'CANVAS' && visible(el));
  if (canvases.length) out.push(`${canvases.length} <canvas> element(s) will print as images, not vector: ${sample(canvases)}. Use an SVG chart instead.`);

  const raster = [], fixed = [], hidden = [];
  for (const el of all) {
    const cs = getComputedStyle(el);
    if ((cs.backdropFilter && cs.backdropFilter !== 'none') || (cs.filter && cs.filter !== 'none') || cs.mixBlendMode !== 'normal') raster.push(el);
    if (cs.position === 'fixed' || cs.position === 'sticky') fixed.push(el);
    if (cs.opacity === '0' && el.textContent.trim().length > 20 && visible(el)) hidden.push(el);
  }
  if (raster.length) out.push(`${raster.length} element(s) use filter, backdrop-filter or blend modes and may be rasterised (blurry, not editable): ${sample(raster)}`);
  if (fixed.length) out.push(`${fixed.length} fixed or sticky element(s) may repeat on every page or overlap content: ${sample(fixed)}. Make them static in print.`);
  if (hidden.length) out.push(`${hidden.length} element(s) with text are still opacity 0 and will print blank: ${sample(hidden)}. Make print/default state visible.`);

  const vh = new Set();
  const scan = rules => { for (const r of rules) {
    if (r.cssRules) scan(r.cssRules);
    if (r.style && r.selectorText && /\d(\.\d+)?(s|l|d)?vh\b/.test(r.style.cssText)) vh.add(r.selectorText);
  }};
  let hasPage = false;
  const findPage = rules => { for (const r of rules) { if (r.type === CSSRule.PAGE_RULE) hasPage = true; if (r.cssRules) findPage(r.cssRules); } };
  for (const sheet of document.styleSheets) { try { scan(sheet.cssRules); findPage(sheet.cssRules); } catch (e) {} }
  const vhUsed = [...vh].filter(sel => { try { return document.querySelector(sel); } catch (e) { return false; } });
  if (vhUsed.length) out.push(`viewport units (vh) used by: ${vhUsed.slice(0, 4).join(', ')}${vhUsed.length > 4 ? ' ...' : ''}. 100vh is not a page height in print; use mm or remove.`);
  if (!hasPage) out.push('no @page rule found: page size and margins come from the --format and --margin options.');

  const broken = [...document.images].filter(i => i.complete && i.naturalWidth === 0 && i.getAttribute('src'));
  if (broken.length) out.push(`${broken.length} image(s) failed to load: ${broken.slice(0, 3).map(i => i.getAttribute('src')).join(', ')}`);
  if (document.fonts) {
    const bad = [...document.fonts].filter(f => f.status === 'error').map(f => f.family);
    if (bad.length) out.push(`font(s) failed to load: ${[...new Set(bad)].join(', ')}`);
  }

  const closed = document.querySelectorAll('details:not([open])').length;
  if (closed) out.push(`${closed} closed <details> element(s): their content will not print. Add the open attribute.`);

  const de = document.documentElement;
  if (de.scrollWidth > de.clientWidth + 2) {
    const wide = all.filter(el => el.getBoundingClientRect().right > de.clientWidth + 2 && visible(el));
    out.push(`content is wider than the page (${de.scrollWidth}px > ${de.clientWidth}px) and will be clipped: ${sample(wide)}`);
  }
  return out;
}
"""


def launch(p, browser: str):
    order = {"auto": [None, "msedge", "chrome"], "chromium": [None], "msedge": ["msedge"], "chrome": ["chrome"]}[browser]
    errors = []
    for channel in order:
        try:
            b = p.chromium.launch(channel=channel) if channel else p.chromium.launch()
            print(f"browser: {channel or 'playwright chromium'} {b.version}")
            return b
        except Exception as e:  # browser not installed: try the next one
            errors.append(f"{channel or 'playwright chromium'}: {str(e).splitlines()[0]}")
    sys.exit("Could not start a Chromium browser.\n  " + "\n  ".join(errors)
             + "\nRun: python -m playwright install chromium")


def count_pages(pdf: Path) -> int | None:
    try:
        from pypdf import PdfReader
        return len(PdfReader(str(pdf)).pages)
    except Exception:
        data = pdf.read_bytes()
        n = len(re.findall(rb"/Type\s*/Page[^s]", data))
        return n or None


def main() -> int:
    ap = argparse.ArgumentParser(description="Render HTML to a vector PDF with headless Chromium.")
    ap.add_argument("input", help="HTML file path or http(s) URL")
    ap.add_argument("output", nargs="?", help="PDF path (default: input name with .pdf)")
    ap.add_argument("--format", default="A4", help="paper size when the page has no @page size (default A4)")
    ap.add_argument("--landscape", action="store_true", help="landscape when the page has no @page size")
    ap.add_argument("--margin", default="0", help="margin when the page has no @page margin, e.g. 15mm (default 0)")
    ap.add_argument("--media", choices=["print", "screen"], default="print",
                    help="CSS media to render with (default print)")
    ap.add_argument("--width", type=int, default=1280, help="viewport width in px (default 1280)")
    ap.add_argument("--single-page", action="store_true",
                    help="one page sized to the whole document at --width, screen styles (posters, one-pagers)")
    ap.add_argument("--wait", type=int, default=0, help="extra milliseconds to wait before printing")
    ap.add_argument("--wait-for", help="CSS selector to wait for before printing, e.g. .pagedjs_pages")
    ap.add_argument("--keep-motion", action="store_true", help="do not force animations to their end state")
    ap.add_argument("--no-scroll", action="store_true", help="do not scroll through the page first")
    ap.add_argument("--dark", action="store_true", help="render with prefers-color-scheme: dark (default light)")
    ap.add_argument("--browser", choices=["auto", "chromium", "msedge", "chrome"], default="auto")
    ap.add_argument("--strict", action="store_true", help="exit 2 if there are warnings")
    a = ap.parse_args()

    is_url = re.match(r"^https?://", a.input) is not None
    if is_url:
        url = a.input
        out = Path(a.output or (re.sub(r"\W+", "-", a.input.split("//", 1)[1]).strip("-")[:60] + ".pdf"))
    else:
        src = Path(a.input).resolve()
        if not src.is_file():
            sys.exit(f"Not found: {src}")
        url = src.as_uri()
        out = Path(a.output) if a.output else src.with_suffix(".pdf")
    out = out.resolve()
    out.parent.mkdir(parents=True, exist_ok=True)

    media = "screen" if a.single_page else a.media
    with sync_playwright() as p:
        browser = launch(p, a.browser)
        page = browser.new_page(viewport={"width": a.width, "height": 900},
                                color_scheme="dark" if a.dark else "light")
        console_errors: list[str] = []
        page.on("pageerror", lambda e: console_errors.append(str(e).splitlines()[0]))
        try:
            page.goto(url, wait_until="load", timeout=60_000)
        except Exception as e:
            sys.exit(f"Could not load {url}: {e}")
        if not a.keep_motion:
            page.add_style_tag(content=FINISH_MOTION_CSS)
        if not a.no_scroll:
            page.evaluate(SCROLL_THROUGH_JS)
        try:
            page.wait_for_load_state("networkidle", timeout=15_000)
        except Exception:
            pass
        if a.wait_for:
            page.wait_for_selector(a.wait_for, state="attached", timeout=60_000)
        page.emulate_media(media=media)
        page.evaluate(SETTLE_JS)
        if a.wait:
            page.wait_for_timeout(a.wait)

        warnings = page.evaluate(LINT_JS)
        if a.single_page:
            warnings = [w for w in warnings if not any(s in w for s in ("no @page", "viewport units", "fixed or sticky"))]
        warnings += [f"page script error: {m}" for m in console_errors[:5]]

        opts = dict(path=str(out), print_background=True)
        if a.single_page:
            page.evaluate(FREEZE_VH_JS)
            height = page.evaluate("Math.ceil(document.documentElement.scrollHeight)")
            opts.update(width=f"{a.width}px", height=f"{height + 1}px", page_ranges="1",
                        margin={"top": "0", "right": "0", "bottom": "0", "left": "0"})
        else:
            m = a.margin
            opts.update(format=a.format, landscape=a.landscape, prefer_css_page_size=True,
                        margin={"top": m, "right": m, "bottom": m, "left": m})
        try:
            page.pdf(**opts, tagged=True, outline=True)  # accessible tags + bookmarks from headings
        except TypeError:  # older Playwright without tagged/outline
            page.pdf(**opts)
        browser.close()

    pages = count_pages(out)
    print(f"wrote {out} ({out.stat().st_size // 1024} KB, {pages if pages else '?'} page(s))")
    for w in warnings:
        print(f"WARN  {w}")
    if not warnings:
        print("no print warnings")
    return 2 if (a.strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
