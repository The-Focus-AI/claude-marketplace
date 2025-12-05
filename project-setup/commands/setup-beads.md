---
description: Initialize beads issue tracking in current project
---

# Setup Beads Issue Tracker

You are setting up the Beads (bd) issue tracking system for this project. Run the following commands in sequence to configure the environment.

## Setup Steps

### Step 1: Install Required Tools

Run these commands to set up the runtime and tools using mise:

```bash
mise use node
mise use npm:@anthropic-ai/claude-code
mise use npm:@beads/bd
```

### Step 2: Initialize Beads

Initialize the beads database in the project. Use `mise exec` since bd was just installed:

```bash
mise exec -- bd init
```

### Step 3: Configure Claude Integration

Set up beads for use with Claude Code:

```bash
mise exec -- bd setup claude --project
```

### Step 4: Update CLAUDE.md

Add the onboarding reminder to the project's CLAUDE.md file:

```bash
echo "\nBEFORE ANYTHING ELSE: run 'bd onboard' and follow the instructions" >> CLAUDE.md
```

## After Setup

Once complete, inform the user that:

1. Beads is now configured for this project
2. Issue tracking files are in `.beads/`
3. They should run `bd onboard` to learn how to use the system
4. They can use `bd help` to see available commands

## User Arguments

$ARGUMENTS
