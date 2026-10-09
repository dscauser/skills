#!/usr/bin/env sh
# Mac and Linux version of check.ps1. Health check for the skills layout
# described in SKILL.md. Reports problems and changes nothing. Exits 1 if
# anything needs fixing, 0 otherwise.
#
#   sh ./check.sh
#
# Lines starting FAIL need action and say what to do. Lines starting "note"
# are information. Lines starting "repo" give each repo's git state.

agents_skills="${AGENTS_SKILLS:-$HOME/.agents/skills}"
claude_skills="${CLAUDE_SKILLS:-$HOME/.claude/skills}"
problems=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { problems=$((problems + 1)); echo "FAIL     $1"; }
note() { echo "note     $1"; }
ok()   { echo "ok       $1"; }

phys() { # phys <dir>  prints the resolved physical path, empty if it cannot be entered
  (cd "$1" 2>/dev/null && pwd -P)
}

has_frontmatter() { # has_frontmatter <file>
  [ "$(head -n 1 "$1")" = "---" ] && tail -n +2 "$1" | head -n 80 | grep -q '^---$'
}

fm_value() { # fm_value <file> <key>  (folded "key: >" values take the next indented line)
  awk -v k="$2" '
    NR > 1 && $0 == "---" { exit }
    pending && /^[ \t]+[^ \t]/ { sub(/^[ \t]+/, ""); print; exit }
    pending { pending = 0 }
    NR > 1 && index($0, k ":") == 1 {
      v = substr($0, length(k) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      if (v == "" || v ~ /^[>|][+-]?$/) { pending = 1; next }
      print v; exit
    }' "$1"
}

for folder in "$agents_skills" "$claude_skills"; do
  [ -d "$folder" ] || fail "$folder does not exist. Run a repo's install script."
done
[ "$problems" -eq 0 ] || exit 1

# 1. Dead links in both folders
for folder in "$agents_skills" "$claude_skills"; do
  for item in "$folder"/* "$folder"/.[!.]*; do
    if [ -L "$item" ] && [ ! -e "$item" ]; then
      fail "dead link $item -> $(readlink "$item"). Run the install script to remove it."
    fi
  done
done

# 2. ~/.claude/skills must contain only links back to ~/.agents/skills, plus synced/
for item in "$claude_skills"/*/; do
  [ -d "$item" ] || continue
  item="${item%/}"; name="$(basename "$item")"
  [ "$name" = "synced" ] && continue
  if [ ! -L "$item" ]; then
    fail "$item is a real folder. Move it into $agents_skills, then run the install script."
  elif [ "$(phys "$item")" != "$(phys "$agents_skills/$name")" ]; then
    fail "$item points to $(readlink "$item"), expected $agents_skills/$name. Run the install script."
  fi
done

# 3. Every skill in ~/.agents/skills is mirrored, and 4. has valid frontmatter
: > "$tmp/names"   # lines: <name> <path>
: > "$tmp/repos"   # lines: <repo>
for item in "$agents_skills"/*/; do
  [ -d "$item" ] || continue
  item="${item%/}"; name="$(basename "$item")"
  [ -e "$claude_skills/$name" ] || fail "$name is in $agents_skills but not in $claude_skills. Run the install script."

  skillmd="$item/SKILL.md"
  if [ ! -f "$skillmd" ]; then fail "$name has no SKILL.md. Agents will not load it."; continue; fi
  if ! has_frontmatter "$skillmd"; then fail "$name/SKILL.md has no frontmatter block (--- name/description ---)."; continue; fi
  fm_name="$(fm_value "$skillmd" name)"
  fm_desc="$(fm_value "$skillmd" description)"
  bad=0
  if [ -z "$fm_name" ]; then fail "$name/SKILL.md frontmatter has no name."; bad=1
  elif [ "$fm_name" != "$name" ]; then fail "$name/SKILL.md says name: $fm_name, but the folder is $name. Make them match."; bad=1
  elif ! printf '%s' "$fm_name" | grep -Eq '^[a-z0-9-]{1,64}$'; then fail "$name: name must be lowercase letters, digits and hyphens, at most 64 characters."; bad=1
  fi
  if [ -z "$fm_desc" ]; then fail "$name/SKILL.md frontmatter has no description. The agent cannot tell when to use it."; bad=1; fi
  [ "$bad" -eq 0 ] && ok "$name"
  [ -n "$fm_name" ] && echo "$fm_name $item" >> "$tmp/names"

  # Repo discovery: a link to <repo>/skills/<name> where <repo> has an install script
  if [ -L "$item" ]; then
    repo="$(dirname "$(dirname "$(readlink "$item")")")"
    [ -f "$repo/install.sh" ] && echo "$repo" >> "$tmp/repos"
  fi
done
sort -u "$tmp/repos" -o "$tmp/repos"

# 5. Duplicate names among installed skills
cut -d' ' -f1 "$tmp/names" | sort | uniq -d > "$tmp/dups"
while read -r n; do
  fail "skill name '$n' is used by more than one installed skill: $(grep "^$n " "$tmp/names" | cut -d' ' -f2- | tr '\n' ' ')"
done < "$tmp/dups"

# 6. Repo skills: installed, unique across repos, install scripts identical
: > "$tmp/repo_skills"   # lines: <name> <repo>
while read -r repo; do
  [ -d "$repo/skills" ] || continue
  for s in "$repo"/skills/*/; do
    [ -d "$s" ] || continue
    s="${s%/}"; n="$(basename "$s")"
    echo "$n $repo" >> "$tmp/repo_skills"
    link="$agents_skills/$n"
    if [ ! -e "$link" ] && [ ! -L "$link" ]; then
      fail "$repo has skills/$n but it is not installed. Run that repo's install script."
    elif [ ! -L "$link" ]; then
      fail "$link is a real folder, so the repo skill $s cannot be linked. Move or rename one of them."
    elif [ "$(phys "$link")" != "$(phys "$s")" ]; then
      case "$(readlink "$link")" in
        /usr/*|/opt/*|/nix/*) fail "$link is an OS-managed skill, so the repo skill $s cannot be linked. Rename the repo skill." ;;
        *) fail "$link points to $(readlink "$link"), not $s. Run that repo's install script." ;;
      esac
    fi
  done
done < "$tmp/repos"
cut -d' ' -f1 "$tmp/repo_skills" | sort | uniq -d > "$tmp/dups"
while read -r n; do
  fail "skill '$n' exists in more than one repo: $(grep "^$n " "$tmp/repo_skills" | cut -d' ' -f2- | tr '\n' ' '). Only one can be linked."
done < "$tmp/dups"
if [ "$(wc -l < "$tmp/repos")" -gt 1 ]; then
  for script in install.ps1 install.sh; do
    distinct="$(while read -r repo; do [ -f "$repo/$script" ] && cksum < "$repo/$script"; done < "$tmp/repos" | sort -u | wc -l)"
    [ "$distinct" -le 1 ] || fail "$script differs between repos ($(tr '\n' ' ' < "$tmp/repos")). Copy the newest version to the others."
  done
fi

# 7. Name clashes with synced skills from the Claude app
if [ -d "$claude_skills/synced" ]; then
  for s in "$claude_skills"/synced/*/*/; do
    [ -d "$s" ] || continue
    n="$(basename "${s%/}")"
    grep -q "^$n " "$tmp/names" && note "'$n' is also a synced skill from the Claude app. Claude Code may show both."
  done
fi

# 8. Repo git state (fetch is read-only; skipped silently when offline)
while read -r repo; do
  git -C "$repo" fetch --quiet 2>/dev/null
  if ! dirty="$(git -C "$repo" status --short 2>/dev/null)"; then note "$repo is not a git repo or git failed."; continue; fi
  parts=""
  if behind="$(git -C "$repo" rev-list --count 'HEAD..@{u}' 2>/dev/null)"; then
    ahead="$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null)"
    [ "$behind" -gt 0 ] && parts="$parts, $behind behind"
    [ "$ahead" -gt 0 ] && parts="$parts, $ahead unpushed"
  else
    parts="$parts, no upstream"
  fi
  if [ -n "$dirty" ]; then parts="$parts, $(printf '%s\n' "$dirty" | wc -l | tr -d ' ') uncommitted change(s)"; fi
  [ -n "$parts" ] || parts=", up to date"
  echo "repo     $repo  (${parts#, })"
done < "$tmp/repos"

if [ "$problems" -gt 0 ]; then
  echo; echo "$problems problem(s) found."; exit 1
fi
echo; echo "No problems found. If a skill still does not trigger, restart the session and check its description."
exit 0
