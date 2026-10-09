# Health check for the skills layout described in SKILL.md. Reports problems
# and changes nothing. Exits 1 if anything needs fixing, 0 otherwise.
#
#   pwsh ./check.ps1
#
# Lines starting FAIL need action and say what to do. Lines starting "note"
# are information. Lines starting "repo" give each repo's git state.

param(
    [string]$AgentsSkills = (Join-Path $HOME '.agents\skills'),
    [string]$ClaudeSkills = (Join-Path $HOME '.claude\skills')
)

$ErrorActionPreference = 'Stop'
$script:problems = 0

function Fail([string]$msg) { $script:problems++; Write-Host "FAIL     $msg" }
function Note([string]$msg) { Write-Host "note     $msg" }
function Ok([string]$msg)   { Write-Host "ok       $msg" }

function Get-LinkTarget($item) {
    $t = @($item.Target)[0]
    if (-not $t) { return $null }
    return ($t -replace '^\\\\\?\\|^\\\?\?\\', '').TrimEnd('\')
}

# Follows a chain of links to the real folder, so two links that reach the
# same folder by different routes (e.g. one the OS manages) compare equal.
function Resolve-Link([string]$path) {
    $p = $path
    for ($i = 0; $i -lt 10; $i++) {
        $it = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        if (-not $it -or -not $it.LinkType) { break }
        $t = Get-LinkTarget $it
        if (-not $t) { break }
        $p = $t
    }
    return $p.TrimEnd('\')
}

# Returns a hashtable of the YAML frontmatter keys, or $null if there is no
# complete frontmatter block. Folded values (key: > or key: |) count as the
# first indented line that follows.
function Get-Frontmatter([string]$file) {
    $lines = @(Get-Content -LiteralPath $file -TotalCount 80)
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return $null }
    $fm = @{}
    $pending = $null
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.Trim() -eq '---') { return $fm }
        if ($pending -and $line -match '^\s+\S') { $fm[$pending] = $line.Trim(); $pending = $null; continue }
        if ($line -match '^([A-Za-z_][\w-]*):\s*(.*)$') {
            $key = $Matches[1]; $value = $Matches[2].Trim()
            if ($value -match '^[>|][+-]?$' -or $value -eq '') { $fm[$key] = ''; $pending = $key }
            else { $fm[$key] = $value; $pending = $null }
        }
    }
    return $null
}

foreach ($folder in $AgentsSkills, $ClaudeSkills) {
    if (-not (Test-Path -LiteralPath $folder)) {
        Fail "$folder does not exist. Run a repo's install script."
    }
}
if ($script:problems) { exit 1 }

# 1. Dead links in both folders
foreach ($folder in $AgentsSkills, $ClaudeSkills) {
    foreach ($item in Get-ChildItem -LiteralPath $folder -Force) {
        if ($item.LinkType -and -not (Test-Path -LiteralPath (Get-LinkTarget $item))) {
            Fail "dead link $($item.FullName) -> $(Get-LinkTarget $item). Run the install script to remove it."
        }
    }
}

# 2. ~/.claude/skills must contain only links back to ~/.agents/skills, plus synced/
foreach ($item in Get-ChildItem -LiteralPath $ClaudeSkills -Directory -Force) {
    if ($item.Name -eq 'synced') { continue }
    if (-not $item.LinkType) {
        Fail "$($item.FullName) is a real folder. Move it into $AgentsSkills, then run the install script."
        continue
    }
    $expected = Join-Path $AgentsSkills $item.Name
    if ((Resolve-Link $item.FullName) -ne (Resolve-Link $expected)) {
        Fail "$($item.FullName) points to $(Get-LinkTarget $item), expected $expected. Run the install script."
    }
}

# 3. Every skill in ~/.agents/skills is mirrored, and 4. has valid frontmatter
$names = @{}      # frontmatter name -> list of installed paths
$repos = @{}      # repo root -> $true
foreach ($item in Get-ChildItem -LiteralPath $AgentsSkills -Directory -Force) {
    $mirror = Join-Path $ClaudeSkills $item.Name
    if (-not (Test-Path -LiteralPath $mirror)) {
        Fail "$($item.Name) is in $AgentsSkills but not in $ClaudeSkills. Run the install script."
    }

    $skillmd = Join-Path $item.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillmd)) {
        Fail "$($item.Name) has no SKILL.md. Agents will not load it."
        continue
    }
    $fm = Get-Frontmatter $skillmd
    if (-not $fm) {
        Fail "$($item.Name)/SKILL.md has no frontmatter block (--- name/description ---)."
        continue
    }
    $bad = $false
    if (-not $fm['name']) { Fail "$($item.Name)/SKILL.md frontmatter has no name."; $bad = $true }
    elseif ($fm['name'] -ne $item.Name) { Fail "$($item.Name)/SKILL.md says name: $($fm['name']), but the folder is $($item.Name). Make them match."; $bad = $true }
    elseif ($fm['name'] -notmatch '^[a-z0-9-]{1,64}$') { Fail "$($item.Name): name must be lowercase letters, digits and hyphens, at most 64 characters."; $bad = $true }
    if (-not $fm['description']) { Fail "$($item.Name)/SKILL.md frontmatter has no description. The agent cannot tell when to use it."; $bad = $true }
    if (-not $bad) { Ok $item.Name }

    if ($fm['name']) {
        if (-not $names.ContainsKey($fm['name'])) { $names[$fm['name']] = @() }
        $names[$fm['name']] += $item.FullName
    }

    # Repo discovery: a link to <repo>/skills/<name> where <repo> has an install script
    if ($item.LinkType) {
        $target = Get-LinkTarget $item
        if ($target) {
            $repo = Split-Path (Split-Path $target -Parent) -Parent
            if ($repo -and (Test-Path -LiteralPath (Join-Path $repo 'install.ps1'))) { $repos[$repo] = $true }
        }
    }
}

# 5. Duplicate names among installed skills
foreach ($n in $names.Keys) {
    if (@($names[$n]).Count -gt 1) { Fail "skill name '$n' is used by more than one installed skill: $($names[$n] -join ', ')" }
}

# 6. Repo skills: installed, unique across repos, install scripts identical
$repoSkills = @{}   # skill name -> list of repos
foreach ($repo in $repos.Keys) {
    $skillsDir = Join-Path $repo 'skills'
    if (-not (Test-Path -LiteralPath $skillsDir)) { continue }
    foreach ($s in Get-ChildItem -LiteralPath $skillsDir -Directory) {
        if (-not $repoSkills.ContainsKey($s.Name)) { $repoSkills[$s.Name] = @() }
        $repoSkills[$s.Name] += $repo
        $link = Get-Item -LiteralPath (Join-Path $AgentsSkills $s.Name) -Force -ErrorAction SilentlyContinue
        if (-not $link) {
            Fail "$repo has skills/$($s.Name) but it is not installed. Run that repo's install script."
        }
        elseif (-not $link.LinkType) {
            Fail "$($link.FullName) is a real folder, so the repo skill $($s.FullName) cannot be linked. Move or rename one of them."
        }
        elseif ((Resolve-Link $link.FullName) -ne $s.FullName.TrimEnd('\')) {
            Fail "$($link.FullName) points to $(Get-LinkTarget $link), not $($s.FullName). Run that repo's install script, or rename the repo skill if the link is OS-managed."
        }
    }
}
foreach ($n in $repoSkills.Keys) {
    if (@($repoSkills[$n]).Count -gt 1) { Fail "skill '$n' exists in more than one repo: $($repoSkills[$n] -join ', '). Only one can be linked." }
}
$repoList = @($repos.Keys | Sort-Object)
if ($repoList.Count -gt 1) {
    foreach ($script in 'install.ps1', 'install.sh') {
        $hashes = @{}
        foreach ($repo in $repoList) {
            $p = Join-Path $repo $script
            if (Test-Path -LiteralPath $p) { $hashes[$repo] = (Get-FileHash -LiteralPath $p).Hash }
        }
        if (@($hashes.Values | Sort-Object -Unique).Count -gt 1) {
            Fail "$script differs between repos ($($hashes.Keys -join ', ')). Copy the newest version to the others."
        }
    }
}

# 7. Name clashes with synced skills from the Claude app
$synced = Join-Path $ClaudeSkills 'synced'
if (Test-Path -LiteralPath $synced) {
    foreach ($account in Get-ChildItem -LiteralPath $synced -Directory) {
        foreach ($s in Get-ChildItem -LiteralPath $account.FullName -Directory) {
            if ($names.ContainsKey($s.Name)) {
                Note "'$($s.Name)' is also a synced skill from the Claude app. Claude Code may show both."
            }
        }
    }
}

# 8. Repo git state (fetch is read-only; skipped silently when offline)
foreach ($repo in $repoList) {
    $parts = @()
    git -C $repo fetch --quiet 2>$null
    $behind = git -C $repo rev-list --count 'HEAD..@{u}' 2>$null
    $ahead = git -C $repo rev-list --count '@{u}..HEAD' 2>$null
    $dirty = @(git -C $repo status --short 2>$null)
    if ($LASTEXITCODE -ne 0) { Note "$repo is not a git repo or git failed."; continue }
    if ($null -eq $behind) { $parts += 'no upstream' }
    else {
        if ([int]$behind -gt 0) { $parts += "$behind behind" }
        if ([int]$ahead -gt 0) { $parts += "$ahead unpushed" }
    }
    if ($dirty.Count -gt 0) { $parts += "$($dirty.Count) uncommitted change(s)" }
    if ($parts.Count -eq 0) { $parts += 'up to date' }
    Write-Host "repo     $repo  ($($parts -join ', '))"
}

if ($script:problems) {
    Write-Host ""
    Write-Host "$($script:problems) problem(s) found."
    exit 1
}
Write-Host ""
Write-Host "No problems found. If a skill still does not trigger, restart the session and check its description."
exit 0
