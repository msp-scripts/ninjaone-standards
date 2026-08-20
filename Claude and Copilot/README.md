# NinjaOne Scripts: AI Assistance for GitHub Copilot and Claude Code

This directory is an installable context pack that teaches **GitHub Copilot** and **Claude
Code** the NinjaOne RMM platform: seven agent skills, an expert agent, and a PowerShell
instructions file. Once installed, both tools give NinjaOne-aware suggestions, correct
type-conversion helpers, working API patterns, and valid WYSIWYG formatting.

The skills follow the [Agent Skills](https://agentskills.io) open standard, so one set of
files serves Copilot CLI, Copilot in VS Code, and Claude Code - there is a single source of
truth in version control, and `install.ps1` places it wherever each tool looks.

---

## Contents

```
.github/
  skills/                                           # Canonical skills
    ninjaone-api/SKILL.md                           # REST API v2
    ninjaone-environment-variables/SKILL.md         # $env:NINJA_* variables
    ninjaone-script-variables/SKILL.md              # Type conversion, ConvertTo-TypedValue
    ninjaone-custom-fields/SKILL.md                 # Get-NinjaProperty / Set-NinjaProperty
    ninjaone-cli/SKILL.md                           # ninjarmm-cli and legacy cmdlets
    ninjaone-wysiwyg/SKILL.md                       # HTML/CSS for WYSIWYG fields
    ninjaone-tags/SKILL.md                          # Device tagging
  agents/
    ninjaone-expert.agent.md                        # Expert agent - Copilot format
  instructions/
    ninjaone-scripting-guidelines.instructions.md   # Auto-applied to *.ps1 / *.psm1

.claude/
  agents/
    ninjaone-expert.md                              # Expert agent - Claude Code format

CLAUDE.md                                           # Claude Code project instructions
install.ps1                                         # Installer for both tools
```

This is the pack's **source** layout, which is not identical to the installed layout. Two
things are tool-specific:

- **Skills.** Copilot CLI and Copilot in VS Code read `.github/skills/`, `.claude/skills/`,
  and `.agents/skills/`. Claude Code reads `.claude/skills/` only. The canonical copies live
  under `.github/skills/` alongside the agent and instructions; installing for Claude Code
  copies them to `.claude/skills/` so there is one source of truth in version control rather
  than two directories to keep in sync.
- **Agents.** Claude Code reads `.claude/agents/*.md`; Copilot reads `.github/agents/*.agent.md`.
  Both files ship. The Claude version is self-contained; the Copilot version is a lean router
  that delegates to the same seven skills.

---

## Available skills

| Skill | What it covers |
|-------|----------------|
| `ninjaone-api` | REST API v2: OAuth2, pagination, device filters (`df=`), bulk operations, rate limiting |
| `ninjaone-environment-variables` | All `$env:NINJA_*` agent-provided variables - org name, node ID, data path, and more |
| `ninjaone-script-variables` | Script parameter types, wire formats, and the `ConvertTo-TypedValue` type conversion helper |
| `ninjaone-custom-fields` | `Get-NinjaProperty` / `Set-NinjaProperty` with all field types; GUID vs friendly name for dropdowns |
| `ninjaone-cli` | `ninjarmm-cli` commands, documentation template access, legacy `Ninja-Property-*` cmdlets |
| `ninjaone-wysiwyg` | Allowed HTML/CSS, NinjaOne CSS classes, Charts.css, Bootstrap 5, Font Awesome 6 |
| `ninjaone-tags` | Device tagging via PowerShell module and CLI; automation-only constraints |

Every tool loads these same seven files, so answers are consistent regardless of which one
you use.

---

## Install

Run `install.ps1`. Pick **project** scope to share the pack with everyone working in one
repository, or **personal** scope to have it available in every repository you touch. You can
do both. Add `-WhatIf` to preview without writing anything.

```powershell
# Into a scripting repository, for both tools
.\install.ps1 -Scope Project -Path C:\repos\NinjaOne-Scripts

# Into your home directory, Copilot only
.\install.ps1 -Scope Personal -Tool Copilot
```

`-Tool` accepts `Copilot`, `Claude`, or `Both` (default). The script is idempotent, needs no
administrator rights, and exits `0` on success, `2` on a bad `-Path`, `1` on a copy failure.

Personal scope skips the instructions file by default. Its `applyTo` is `**/*.ps1`, so
installing it globally would apply NinjaOne guidance to every PowerShell file you edit, not
just NinjaOne scripts. Pass `-IncludeInstructions` if you want it anyway. Project scope always
installs it, because there the repository already defines the scope.

### What lands where

**Project scope** - commit these alongside your scripts:

| Component | Path in your repo | Picked up by |
|-----------|-------------------|--------------|
| 7 skills | `.github/skills/` | Copilot CLI, Copilot in VS Code |
| 7 skills | `.claude/skills/` | Claude Code |
| Expert agent | `.github/agents/ninjaone-expert.agent.md` | Copilot CLI, Copilot in VS Code |
| Expert agent | `.claude/agents/ninjaone-expert.md` | Claude Code |
| Instructions | `.github/instructions/*.instructions.md` | Copilot CLI, Copilot in VS Code |
| Project context | `CLAUDE.md` | Claude Code |

**Personal scope** - applies to every repository you open:

| Component | Copilot | Claude Code |
|-----------|---------|-------------|
| 7 skills | `~/.copilot/skills/` | `~/.claude/skills/` |
| Expert agent | `~/.copilot/agents/ninjaone-expert.agent.md` | `~/.claude/agents/ninjaone-expert.md` |
| Instructions | `~/.copilot/instructions/` (opt in with `-IncludeInstructions`) | not applicable |

On Windows, `~` is `C:\Users\<you>`. If a skill or agent of the same name exists in both
scopes, the personal copy wins.

### Installing by hand

If you would rather not run the script, copy `.github/` and, for Claude Code, `.claude/` plus
`CLAUDE.md` into your repository root - then additionally copy the contents of
`.github/skills/` into `.claude/skills/`, since Claude Code will not find them under
`.github/`.

### Verify the install

Installation is not picked up until the tool reloads.

- **Copilot CLI** - run `/skills reload`, then `/skills info ninjaone-api` to confirm the
  skill loaded. Restart the CLI to pick up the new agent, then run `/agent` and check that
  `ninjaone-expert` is listed.
- **Copilot in VS Code** - reload the window. Type `/skills` in chat to open the Configure
  Skills menu and confirm the seven `ninjaone-*` skills appear. Agent Skills may require the
  `chat.useAgentSkills` setting to be enabled.
- **Claude Code** - restart the session, then ask it to list available skills.

---

## Using it

### Skills load themselves

You do not need to attach or manually reference a skill file. Each `SKILL.md` has a
`description` in its frontmatter that tells the tool when the skill is relevant, and the tool
loads it on demand. Just ask the question:

```
How do I query all offline Windows servers in org 123?
How do I convert a checkbox script variable to a boolean?
Generate an HTML status card for a service health report.
```

You can also name a skill explicitly when you want to force it:

```
Use the ninjaone-wysiwyg skill to build a service health report card.
```

### The instructions file applies automatically

`ninjaone-scripting-guidelines.instructions.md` targets `**/*.ps1` and `**/*.psm1` via its
`applyTo` frontmatter, so Copilot applies it whenever you edit a NinjaOne PowerShell script -
no action needed. It contains:

- A standard script template with `ConvertTo-TypedValue` usage
- Quick-reference tables for all `$env:NINJA_*` variables and script variable wire formats
- A 16-item best practices summary

### The `ninjaone-expert` agent

Use the agent for multi-domain work - for example, reading a dropdown custom field *and*
writing a WYSIWYG report - where you want one persona that reaches across several skills and
keeps that work in its own context window.

**Copilot CLI:**

```
copilot --agent ninjaone-expert --prompt "Write a script that reads a Dropdown field and generates a WYSIWYG status report"
```

Or interactively: enter `/agent`, pick `ninjaone-expert`, then prompt. Copilot will also
select it automatically when a prompt matches its description.

**Claude Code:**

```
Use the ninjaone-expert agent to read a Dropdown field and generate a WYSIWYG status report
```

Questions well-suited to the agent:

- "Write a script that reads a Dropdown field and generates a WYSIWYG status report"
- "What environment variables does NinjaOne inject, and how do I use the node ID in an API call?"
- "How do I handle a secure field safely in an automation script?"

---

## Tips

- **Start simple** - for most scripts the auto-applied instructions file is enough. Skills
  load on their own when a question actually needs deep reference.
- **Use the standard template** - ask either tool to "use the standard NinjaOne script
  template" when starting a new script. Both produce the same `ConvertTo-TypedValue`-based
  shape.
- **Keep skills up to date** - when NinjaOne ships new platform features, update the relevant
  `SKILL.md` under `.github/skills/`, then re-run `install.ps1` to push it to the installed
  locations. Run `/skills reload` afterwards.
- **Scripts target Windows PowerShell 5.1** - NinjaOne runs them under 5.1 by default, so no
  ternary `? :` or null-coalescing `??` in generated code.
- **Character limits to remember** - Text: 200 chars, MultiLine: 10,000, Secure: 200-10,000,
  WYSIWYG: 200,000.
