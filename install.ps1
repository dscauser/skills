# Links every skill in this repository into ~/.agents/skills, then mirrors
# everything in ~/.agents/skills into ~/.claude/skills, using directory
# junctions (no admin rights needed). If the repository has an agents/ folder,
# its subagent files are copied into ~/.claude/agents.
#
#   pwsh ./install.ps1            link and copy
#   pwsh ./install.ps1 -WhatIf    show what would happen, change nothing
#
# ~/.agents/skills is the one folder that holds every skill on this machine:
# links to this repo, links to other skill repos, and plain folders for skills
# downloaded or copied from elsewhere. Only the linked ones are tracked by git.
#
# Safe to run again. A link that already points to the right place is left
# alone. A real folder is never deleted: the script skips it and tells you.
# Links whose target has gone (e.g. a skill was renamed) are removed.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$AgentsSkills = (Join-Path $HOME '.agents\skills'),
    [string]$ClaudeSkills = (Join-Path $HOME '.claude\skills'),
    [string]$ClaudeAgents = (Join-Path $HOME '.claude\agents')
)

$ErrorActionPreference = 'Stop'

function Get-LinkTarget($item) {
    $t = @($item.Target)[0]
    if (-not $t) { return $null }
    return ($t -replace '^\\\\\?\\|^\\\?\?\\', '').TrimEnd('\')
}

function Set-Link([string]$link, [string]$target) {
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if (-not $existing.LinkType) {
            Write-Warning "SKIPPED  $link is a real folder, not a link. Move or delete it yourself, then run this again."
            return
        }
        if ((Get-LinkTarget $existing) -eq $target.TrimEnd('\')) {
            Write-Host "ok       $link"
            return
        }
        if ($PSCmdlet.ShouldProcess($link, "repoint link (was $(Get-LinkTarget $existing))")) {
            [System.IO.Directory]::Delete($link, $false)   # removes the link only
        }
    }
    if ($PSCmdlet.ShouldProcess($link, "link to $target")) {
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null
        Write-Host "linked   $link"
    }
}

function Remove-DeadLinks([string]$folder) {
    foreach ($item in Get-ChildItem -LiteralPath $folder -Force) {
        if ($item.LinkType -and -not (Test-Path -LiteralPath (Get-LinkTarget $item))) {
            if ($PSCmdlet.ShouldProcess($item.FullName, 'remove dead link')) {
                [System.IO.Directory]::Delete($item.FullName, $false)
                Write-Host "removed  $($item.FullName) (target gone)"
            }
        }
    }
}

foreach ($folder in $AgentsSkills, $ClaudeSkills) {
    if (-not (Test-Path $folder)) {
        if ($PSCmdlet.ShouldProcess($folder, 'create folder')) {
            New-Item -ItemType Directory -Force -Path $folder | Out-Null
        }
    }
}

# 1. This repo's skills -> ~/.agents/skills
Remove-DeadLinks $AgentsSkills
foreach ($skill in Get-ChildItem -Path (Join-Path $PSScriptRoot 'skills') -Directory) {
    Set-Link (Join-Path $AgentsSkills $skill.Name) $skill.FullName
}

# 2. Everything in ~/.agents/skills -> ~/.claude/skills
Remove-DeadLinks $ClaudeSkills
foreach ($skill in Get-ChildItem -LiteralPath $AgentsSkills -Directory -Force) {
    Set-Link (Join-Path $ClaudeSkills $skill.Name) $skill.FullName
}

# 3. Claude subagent definitions -> ~/.claude/agents (copied; file links need admin on Windows)
$agentsDir = Join-Path $PSScriptRoot 'agents'
if (Test-Path $agentsDir) {
    if (-not (Test-Path $ClaudeAgents) -and $PSCmdlet.ShouldProcess($ClaudeAgents, 'create folder')) {
        New-Item -ItemType Directory -Force -Path $ClaudeAgents | Out-Null
    }
    foreach ($file in Get-ChildItem -Path $agentsDir -Filter '*.md' -File) {
        $dest = Join-Path $ClaudeAgents $file.Name
        if ((Test-Path $dest) -and ((Get-FileHash $dest).Hash -eq (Get-FileHash $file.FullName).Hash)) {
            Write-Host "ok       $dest"
        }
        elseif ($PSCmdlet.ShouldProcess($dest, "copy from $($file.FullName)")) {
            Copy-Item $file.FullName $dest -Force
            Write-Host "copied   $dest"
        }
    }
}
