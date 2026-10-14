# Design rules

## Content

- **One idea per slide.** A headline of a few words, then one visual. About
  25 words of on-screen text at most, excluding mock-up content.
- **Fewer slides than you think.** Budget about 45 to 60 seconds per slide.
  Leave the live demo its own time. Merge slides that make the same point.
- **Examples must fit the room.** Match the audience's day-to-day work, not
  the most senior person present. A finance director example confuses a room
  of team champions; a new-starter welcome email or a team huddle note does
  not. Read the context file's audience notes.
- **Show the change, side by side.** For a before → after point, keep the
  "before" on screen and bring the "after" in next to it. Never swap text in
  place: the presenter is still reading it aloud when it changes.
- **Make the payoff explicit.** End an example with a short line saying what
  it proves, for example "You never listed these rules. The reason covered
  them."
- **No ambiguous symbols or quoting.** A "+" between two quoted phrases reads
  as a sum; quote marks around an instruction read as dialogue. Show a prompt
  as a labelled card ("Your prompt") with plain text.
- **Titles must make sense alone.** "Start from real mistakes" leaves the
  listener asking "start what?". Prefer "Write a skill that works".
- **Do not repeat a word across list items** that are meant to be different
  ("real mistakes" and "real examples" blur together).
- **No section numbers in labels.** The bottom counter is the only number;
  "07 · How to write one" on slide 8 confuses the presenter.
- **No job titles or bios** unless asked. The room knows who is talking.
- **Name tools carefully.** Lead with what most of the audience has. Group
  the rest as "+ other AI tools" rather than naming tools people should not be
  using at work.
- **Cite sources quietly.** A small "Source" link at the slide's bottom-left,
  not a footnote paragraph.
- **Mock-ups, not screenshots.** Redraw product screens in HTML (sharp over
  screenshare, can animate), based on the user's own screenshots when given,
  and label them "Illustration".

## Choosing the visual

Start from the idea, not the pattern list. Ask what the audience should see
change on screen, then show exactly that. Some starting points:

| The idea is… | Show it as… | Template pattern |
|---|---|---|
| Stop doing X | Items struck through | `strike-list` |
| Good vs bad version | Weak swaps to strong, parts colour-coded | `weak-to-strong` |
| Adding Y changes the result | Setup + addition → before → after | `cause-effect` |
| How to tell it's done or right | Criteria ticking in | `checklist` |
| Results, growth, performance (SEO, PPC, sales) | Numbers counting up, bars growing | `metrics` |
| Where it lives in a tool | Redrawn screens, click by click | `ui-walkthrough` |
| What's inside a file, page or ad | Parts highlighted in turn with a callout | `anatomy` |
| A repeatable process | Ring filling with a step list | `cycle` |
| Introducing a live demo | In → process → out | `pipeline` |
| Funnel, hierarchy, timeline, map, ranking | Write a new pattern (stacked bars, a funnel, a timeline that draws, a mock search results page) | none yet |

If no pattern fits, write a new one rather than forcing the idea into the
nearest pattern. Two slides in a row using the same pattern is a sign the
talk needs a different visual.

## Look

- **Light theme by default.** Dark backgrounds and fine detail suffer most from
  screenshare compression. Off-white page, white cards, dark text.
- **No constant background motion.** Particle fields and moving gradients
  blur over Teams and Zoom. Put motion in slide transitions and builds.
- **Brand from the context file**, sampled from real assets when possible
  (pixel-sample a slide screenshot rather than guessing a hex). A bottom bar
  in the primary colour with the progress line in the accent works well.
- **Big type.** Headlines at least 36px at 1366 wide; body at least 20px.

## Clicks

Default to fewer clicks. Group steps that belong together into one click with
`data-auto`; keep a click wherever the presenter needs to talk before moving
on.

- **One click, auto-play the rest:** a list being struck through, ticks
  appearing, a ring filling, highlights colour-coding a sentence that just
  appeared.
- **Keep separate clicks:** the screen changes completely (one mock-up screen
  to another), a new block of text arrives that needs reading, a before
  followed by an after.
- **Zero clicks:** a closing "Questions?" or anything decorative can play on
  arrival.
- Auto delays: 650 to 900 ms for short items, 1300 to 1500 ms where the eye
  must follow something (a cursor, a modal).
- A click during a running sequence finishes that sequence, never skips the
  slide. ← undoes the whole last click group. The template does both.

A 10-slide talk built this way needs roughly 20 to 25 clicks, not 40.

## Engineering

- **One file, no external dependencies.** No CDN scripts, fonts or images;
  corporate networks block them and the talk breaks. Inline CSS, inline SVG,
  Web Animations API, a canvas for sparkles. System font stack.
- **Never use `transition: all`** on elements inside a slide. It animates
  `visibility` too, so the element stays visible for the transition's length
  after its slide is hidden. List the properties.
- **Clear auto timers on every navigation**, and cancel running slide
  animations before starting new ones (the template does this).
- Respect `prefers-reduced-motion`.
