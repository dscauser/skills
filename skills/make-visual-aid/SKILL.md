---
name: make-visual-aid
description: Turns talk notes, bullet points or an existing deck into a single-file, click-through HTML visual aid for a live talk or screenshare, with lean text, one moving visual per slide, click-grouped animations and an optional company theme. Asks up to 3 numbered questions, each with a recommended answer, then builds and checks the file. Use when the user asks for a visual aid, presentation aid, talk slides in HTML, something to click through while presenting or demoing, or to turn notes or slides into an interactive or animated presentation, even if they do not name the skill.
---

# Making a visual aid

A visual aid supports a person who is talking. It is not a document to read.
The presenter speaks; each slide shows a few words and one visual that builds
as they click. Everything here comes from rehearsing real talks: follow the
rules in [references/design-rules.md](references/design-rules.md) closely,
because each one fixes a problem a presenter hit.

## Workflow

1. **Load the theme.** Look for `visual-aid-context.md` in the workspace, then
   `context.md` next to this SKILL.md. If found, read it: brand colours,
   wordmark, footer text, audience, tools people use, things not to name. If
   neither exists, use the template's neutral theme. The template for a
   context file is [context.example.md](context.example.md).

2. **Read the material.** Notes, bullet points, slide screenshots, a script.
   Work out the talk's sections, the one idea each section must land, the
   time slot, and where live demos sit. Look up facts you would otherwise ask
   for (product names, what a tool's screen shows) from the files or the web.

3. **Ask, in one message, at most 3 numbered questions**, only about gaps that
   change the result. Always cover the slide plan unless the user already
   gave one. Format:

   ```
   1. [Question]?
      - A) ...
      - B) ...
      → Recommend A: [one-line reason]
   ```

   Good questions: the slide plan (show it as a short table: slide, its one
   idea, clicks), theme (context file or neutral, recommend the context file
   when one exists), whether it will be shared afterwards (if yes, each slide
   needs one line that stands without the speaker). End with: Reply like
   `1B, 2A`, add notes, or say yes to take all recommendations.

4. **Build** from [assets/template.html](assets/template.html). It is a
   working gallery of slide patterns. Copy it to the workspace, keep the
   patterns that fit, delete the rest, replace the content, and set the
   theme in `:root` only. Pattern catalogue and the build attributes:
   [references/build-patterns.md](references/build-patterns.md).

5. **Check it in a browser** if one is available. Click through every slide
   in order, then backwards. Confirm: no console errors, every slide reaches
   its full state, nothing from the previous slide lingers into the next,
   auto sequences finish, and text fits at 1920×1080 and at 1366×768. Read
   state from the DOM when screenshots lag.

6. **Deliver** the file path, the click count per slide, and the keys (→,
   Space or clicker to advance; ← to undo the last click; F fullscreen;
   B blank screen; dots jump to a slide). Say what was not checked.

## Revising after a rehearsal

Presenters come back with notes after a practice run. Expect and fix these
without arguing: a title or label that reads ambiguously, an example that
does not fit the audience, text that changes before it can be read, too many
clicks, numbering that disagrees with the slide counter, anything that
lingers between slides. Re-check the slide in the browser after each fix.
