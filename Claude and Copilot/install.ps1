<#
.SYNOPSIS
    Installs the NinjaOne AI context pack for GitHub Copilot and/or Claude Code.

.DESCRIPTION
    Copies the seven NinjaOne agent skills, the expert agent, and the PowerShell
    instructions file into the locations each tool actually discovers.

    The canonical skills live in this pack at .github/skills/. Copilot CLI and Copilot in
    VS Code read that path directly. Claude Code only discovers skills under .claude/skills/,
    so this script copies them there for the Claude target rather than duplicating them in
    source control.

.PARAMETER Tool
    Which assistant to install for. Both is the default.

.PARAMETER Scope
    Project installs into a target repository so the whole team gets the pack.
    Personal installs into your home directory so it applies to every repository.

.PARAMETER Path
    Root of the target repository. Required for Project scope, ignored for Personal.

.EXAMPLE
    .\install.ps1 -Scope Project -Path C:\repos\NinjaOne-Scripts

.EXAMPLE
    .\install.ps1 -Scope Personal -Tool Copilot -WhatIf

.NOTES
    Idempotent. Safe to re-run - existing files are overwritten with the current version.
    Requires Windows PowerShell 5.1 or later. No administrator rights needed.

    Exit codes:
      0 - success
      1 - unexpected failure during copy
      2 - invalid target path
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Copilot', 'Claude', 'Both')]
    [string]$Tool = 'Both',

    [ValidateSet('Project', 'Personal')]
    [string]$Scope = 'Project',

    [string]$Path
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Copy-Payload {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [switch]$Contents
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing source path: $Source"
    }

    $parent = $Destination
    if (-not $Contents) { $parent = Split-Path -Parent $Destination }

    if ($PSCmdlet.ShouldProcess($Destination, 'Install')) {
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        if ($Contents) {
            Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
        }
        else {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force
        }
    }
    Write-Host "  -> $Destination"
}

#region Validate target
$packRoot = $PSScriptRoot
$skillSource = Join-Path $packRoot '.github\skills'

if ($Scope -eq 'Project') {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Warning 'Project scope requires -Path pointing at the target repository root.'
        exit 2
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Warning "Target path does not exist or is not a directory: $Path"
        exit 2
    }
    $target = (Resolve-Path -LiteralPath $Path).Path
}
else {
    $target = $env:USERPROFILE
}

Write-Step "Installing NinjaOne context pack ($Tool, $Scope scope)"
Write-Host "  target: $target"
#endregion

#region Install
try {
    $doCopilot = ($Tool -eq 'Copilot') -or ($Tool -eq 'Both')
    $doClaude = ($Tool -eq 'Claude') -or ($Tool -eq 'Both')

    if ($doCopilot) {
        Write-Step 'GitHub Copilot'
        if ($Scope -eq 'Project') {
            Copy-Payload -Source $skillSource -Destination (Join-Path $target '.github\skills') -Contents
            Copy-Payload -Source (Join-Path $packRoot '.github\agents\ninjaone-expert.agent.md') `
                -Destination (Join-Path $target '.github\agents\ninjaone-expert.agent.md')
            Copy-Payload -Source (Join-Path $packRoot '.github\instructions\ninjaone-scripting-guidelines.instructions.md') `
                -Destination (Join-Path $target '.github\instructions\ninjaone-scripting-guidelines.instructions.md')
        }
        else {
            Copy-Payload -Source $skillSource -Destination (Join-Path $target '.copilot\skills') -Contents
            Copy-Payload -Source (Join-Path $packRoot '.github\agents\ninjaone-expert.agent.md') `
                -Destination (Join-Path $target '.copilot\agents\ninjaone-expert.agent.md')
            Copy-Payload -Source (Join-Path $packRoot '.github\instructions\ninjaone-scripting-guidelines.instructions.md') `
                -Destination (Join-Path $target '.copilot\instructions\ninjaone-scripting-guidelines.instructions.md')
        }
    }

    if ($doClaude) {
        Write-Step 'Claude Code'
        if ($Scope -eq 'Project') {
            Copy-Payload -Source $skillSource -Destination (Join-Path $target '.claude\skills') -Contents
            Copy-Payload -Source (Join-Path $packRoot '.claude\agents\ninjaone-expert.md') `
                -Destination (Join-Path $target '.claude\agents\ninjaone-expert.md')
            Copy-Payload -Source (Join-Path $packRoot 'CLAUDE.md') -Destination (Join-Path $target 'CLAUDE.md')
        }
        else {
            Copy-Payload -Source $skillSource -Destination (Join-Path $target '.claude\skills') -Contents
            Copy-Payload -Source (Join-Path $packRoot '.claude\agents\ninjaone-expert.md') `
                -Destination (Join-Path $target '.claude\agents\ninjaone-expert.md')
        }
    }
}
catch {
    Write-Warning "Install failed: $($_.Exception.Message)"
    exit 1
}
#endregion

Write-Step 'Done.'
Write-Host '  Copilot CLI:  run /skills reload, then restart to pick up the agent.'
Write-Host '  VS Code:      reload the window.'
Write-Host '  Claude Code:  restart the session.'
exit 0
