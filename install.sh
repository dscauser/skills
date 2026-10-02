#!/usr/bin/env sh
# Mac and Linux version of install.ps1. Links every skill in this repository
# into ~/.agents/skills, then mirrors everything in ~/.agents/skills into
# ~/.claude/skills, using symlinks. If the repository has an agents/ folder,
# its subagent files are linked into ~/.claude/agents.
#
#   sh ./install.sh
#
# Safe to run again. A real folder is never deleted. Links whose target has
# gone are removed.

set -eu
repo="$(cd "$(dirname "$0")" && pwd)"
agents_skills="$HOME/.agents/skills"
claude_skills="$HOME/.claude/skills"
claude_agents="$HOME/.claude/agents"

set_link() { # set_link <link> <target>
  if [ -L "$1" ]; then
    if [ "$(readlink "$1")" = "$2" ]; then echo "ok       $1"; return; fi
    rm "$1"
  elif [ -e "$1" ]; then
    echo "SKIPPED  $1 is a real file or folder, not a link. Move or delete it yourself, then run this again." >&2
    return
  fi
  ln -s "$2" "$1"
  echo "linked   $1"
}

remove_dead_links() { # remove_dead_links <folder>
  for item in "$1"/* "$1"/.[!.]*; do
    if [ -L "$item" ] && [ ! -e "$item" ]; then rm "$item"; echo "removed  $item (target gone)"; fi
  done
}

mkdir -p "$agents_skills" "$claude_skills"

# 1. This repo's skills -> ~/.agents/skills
remove_dead_links "$agents_skills"
for skill in "$repo"/skills/*/; do
  skill="${skill%/}"
  set_link "$agents_skills/$(basename "$skill")" "$skill"
done

# 2. Everything in ~/.agents/skills -> ~/.claude/skills
remove_dead_links "$claude_skills"
for skill in "$agents_skills"/*/; do
  skill="${skill%/}"
  set_link "$claude_skills/$(basename "$skill")" "$agents_skills/$(basename "$skill")"
done

# 3. Claude subagent definitions -> ~/.claude/agents
if [ -d "$repo/agents" ]; then
  mkdir -p "$claude_agents"
  for file in "$repo"/agents/*.md; do
    [ -e "$file" ] || continue
    set_link "$claude_agents/$(basename "$file")" "$file"
  done
fi
