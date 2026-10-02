---
name: manage-skills
description: Use when creating, adding, installing, moving, publishing, syncing, or checking agent skills on this machine — "make a new skill", "add this skill", "install this third-party skill", "make this skill public", "sync my skills", "pull/push my skills", "set up my skills on a new machine", "why isn't my skill showing up", or anything about ~/.agents/skills, ~/.claude/skills, or the user's skills repositories.
---

# Manage Skills

Keep every skill on a machine in one place, `~/.agents/skills`, so any agent
harness can read them. The user's own skills live in git repositories and are
linked in. Skills from anyone else are plain folders that no repository tracks.

## The layout

```
~/code/skills/            PUBLIC repo   — the user's shareable skills    ─┐
~/code/skills-private/    PRIVATE repo  — personal or sensitive skills   ─┼─ linked into
                                                                          ▼
~/.agents/skills/         every skill on this machine:
                            links to the repos' skills/<name> folders
                            plain folders for third-party skills (never committed)
~/.claude/skills/         links mirroring ~/.agents/skills, so Claude Code sees them
                            (synced/ there is managed by the Claude app: never touch it)
~/.claude/agents/         Claude subagent files from a repo's agents/ folder
                            (copied on Windows, symlinked on Mac/Linux)
```

Each repo has:

```
skills/<name>/SKILL.md    one folder per skill
agents/*.md               optional Claude subagent definitions a skill depends on
install.ps1, install.sh   identical in every repo
README.md                 includes a table of the repo's skills
```

**Discover, don't assume.** Repo paths can differ per machine or user. Find the
repos by looking at where the links in `~/.agents/skills` point, and by
checking `~/code/*/install.ps1` or `install.sh`. A repo's visibility comes from
`gh repo view <owner/name> --json visibility` or from its README. A user may
have only the public repo, only a private one, or neither yet.

## The install script

Run the repo's script after any change to the skill set. Always run it from
the repo, not from a copy.

- Windows: `pwsh <repo>/install.ps1` (add `-WhatIf` for a dry run)
- Mac/Linux: `<repo>/install.sh`

It does three things:

1. Links each `skills/<name>` into `~/.agents/skills`.
2. Links everything in `~/.agents/skills` into `~/.claude/skills`.
3. Puts `agents/*.md` into `~/.claude/agents`.

It also removes links whose target is gone. It never deletes a real folder.
Instead it prints `SKIPPED` and leaves the folder alone. Running either repo's
script refreshes step 2 for everything, including third-party skills. After it
runs, tell the user to restart the agent (or start a new session) so it loads
the new skills.

## Tasks

### Create a new skill of the user's own

1. **Decide public or private before writing anything.** Ask the user if it
   is unclear. It must be private if it contains or will accumulate any of:
   - names, contact details, addresses
   - CV, employment history or employer-internal detail
   - credentials, client or customer data
   - anything the user calls personal

   Otherwise default to public.
2. Create `<repo>/skills/<name>/SKILL.md` with `name` and `description`
   frontmatter. The description says *when* to use the skill and lists the
   phrases that should trigger it. If the skill needs a Claude subagent, put
   its definition in `<repo>/agents/`.
3. Add a row to the repo README's skills table.
4. **Public repo only: run the privacy check (below) on the new files.**
5. Run the install script, then commit. Ask before pushing to a public repo
   unless the user already said to publish.

### Add a third-party skill (someone else's)

- Put it in `~/.agents/skills/<name>` as a plain folder. Use the `skills`
  CLI (`npx skills add <github-source>`) if the source supports it, which
  records it in `~/.agents/.skill-lock.json`. Otherwise copy the folder and
  keep its LICENSE.
- **Never put it in either repo.** Don't redistribute someone else's work from
  the user's repo.
- Run any repo's install script so it appears in `~/.claude/skills`.
- To customise a third-party skill and share the change, fork it on GitHub.
  Don't copy it into the user's public repo.

### Move a skill between repos (e.g. private → public)

1. Run the privacy check. Strip or generalise personal parts first. If a
   personal and a generic version are both useful, keep the personal one
   private and create a generic one under a different name.
2. Move the folder with `git mv` inside one repo, or with a move plus a commit
   in each repo when crossing repos. Move the README table row too.
3. Run the install script of the repo that **gained** the skill. Its old link
   becomes dead and is removed, and the new link is created.
4. Commit both repos. Note that git history in the private repo still holds the
   old content, which is fine. Never push private history to the public repo.

### Sync (pull, push, status)

For each repo:

```
git -C <repo> pull --ff-only
git -C <repo> status --short
git -C <repo> log --oneline @{u}..
```

The second command shows uncommitted changes. The third shows commits not yet
pushed. Then run the install script once.

Report per repo: up to date / pulled N commits / has uncommitted changes /
has unpushed commits. Commit and push only when the user asks, or when a skill
instructs it (some skills tell the agent to commit and push their own updates).
If `pull --ff-only` fails because the branches diverged, stop and show the
user. Don't merge or rebase on your own.

### Set up a new machine

```
git clone https://github.com/<owner>/skills.git ~/code/skills
git clone https://github.com/<owner>/skills-private.git ~/code/skills-private
```

Then run each repo's install script.

- **Windows:** use `$HOME\code\...` paths and `pwsh`. Junctions need no admin
  rights.
- **Moving over from an older layout** (e.g. a repo cloned under a different
  folder name): rename or re-clone the folder, then run the install scripts.
  The old links are dead and get removed.
- **A real skill folder sitting in `~/.claude/skills`** (shown as `SKIPPED`):
  move it into `~/.agents/skills`, then re-run the script.

### Health check ("why isn't my skill showing up?")

Check, and report:

- **Dead links** in `~/.agents/skills` or `~/.claude/skills`. The script
  removes these.
- **Real folders in `~/.claude/skills`** other than `synced/`. Move them into
  `~/.agents/skills`.
- **Skills in `~/.agents/skills` with no matching entry in
  `~/.claude/skills`.** Re-run the script.
- **Bad or missing frontmatter:** a `SKILL.md` with no `name`/`description`,
  or a `name` that doesn't match the folder.
- **Repos behind their remote, or with unpushed work.**
- **Duplicate skill names** across repos and third-party folders. Only one can
  be linked.

Skills load at session start. A skill added mid-session may need a restart.

## Privacy check (before anything goes public)

Search the files being published for:

- the user's name, email addresses, phone numbers, street addresses
- employer or client names and internal project names
- CV or job-application content
- tokens, keys, `.env` values
- absolute paths that reveal private folder names

Also check the commit diff, not only the final files, and look at
`git log -p` if the files came from a private repo. If anything is found,
stop and show the user before committing or pushing. A public push can be
cached or indexed even if it is reverted later.

## Rules

- `~/.agents/skills` is the source of truth for what is installed.
  `~/.claude/skills` only mirrors it.
- Only the user's own skills go in the repos. Third-party skills never do.
- Never delete a real skill folder to make room for a link. Move it and tell
  the user.
- Never touch `~/.claude/skills/synced`.
- Keep `install.ps1` and `install.sh` identical across the user's repos. If you
  fix one, copy the fix to the others.
- Ask before creating a GitHub repo, changing a repo's visibility, or pushing
  to a public repo.
