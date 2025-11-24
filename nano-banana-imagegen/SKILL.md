---
name: nano-banana-imagegen
description: Generate and edit images using Google's Nano Banana (Gemini image models). Use this skill when the user asks to create, generate, make, or edit images with AI. Supports text-to-image, image editing, style transfer, and multi-image composition. Automatically enhances prompts with best practices unless user quotes their prompt for exact usage. Tracks conversation context to enable "tweak this" / "change that" editing flows.
---

# Nano Banana Image Generation

Generate and edit images using Google GenAI's Gemini image models (Nano Banana).

## Skill Location

This skill is installed at: `$SKILL_DIR` (e.g., `~/.claude/skills/nano-banana-imagegen` or wherever configured)

**IMPORTANT**: Always run `go run` with the full path to `main.go` so the working directory doesn't change. This allows output files to be created in the user's current directory.

## Quick Start

```bash
# Generate a new image (use full path to main.go)
go run $SKILL_DIR/scripts/main.go -p "a red panda eating bamboo" -o red_panda.png

# Edit an image (pass previous image with -i)
go run $SKILL_DIR/scripts/main.go -i red_panda.png -p "make the background blue" -o red_panda_v2.png

# List available models
go run $SKILL_DIR/scripts/main.go -l
```

## CLI Options

```
Options:
  -p string     Prompt text (required)
  -i string     Input image for editing (ALWAYS pass previous image path for edits)
  -o string     Output filename (default: output.png)
  -m string     Model to use (see -l for list)
  -f string     Read prompt from file
  -l            List available image models
  -reset        Reset saved API key and model
```

## CRITICAL: Tracking Images for Edits

**You MUST track the output path of every generated image.** When the user asks to edit/modify/change the image, pass the previous image path using `-i`.

**Use the user's EXACT wording** for edit prompts. Don't rephrase or embellish - pass their request directly to the model.

### Pattern:
```bash
# First generation - remember the output path
go run $SKILL_DIR/scripts/main.go -p "a wizard cat" -o wizard_cat.png
# Output: ./wizard_cat.png  <-- TRACK THIS PATH

# Any edit - pass the tracked path with -i
go run $SKILL_DIR/scripts/main.go -i wizard_cat.png -p "add a purple cloak" -o wizard_cat_v2.png
# Output: ./wizard_cat_v2.png  <-- UPDATE TRACKED PATH

# Next edit - use the NEW path
go run $SKILL_DIR/scripts/main.go -i wizard_cat_v2.png -p "make it wider 16:9" -o wizard_cat_v3.png
```

## When to Pass -i (Previous Image)

**ALWAYS pass `-i <previous_image>` when:**
- User references the previous image in ANY way
- User asks to change, modify, adjust, or tweak anything
- User asks for a different style, color, aspect ratio, or variation
- User says "make it...", "add...", "remove...", "change..."
- User asks for "the same but..." or "like that but..."
- User gives feedback like "too dark", "more colorful", "less busy"
- User asks to "redo", "try again", or "another version"
- ANY follow-up request after generating an image (unless explicitly asking for something completely different)

**Only skip `-i` when:**
- First image generation in conversation (no previous image exists)
- User explicitly asks for a "new image" of something unrelated
- User provides a completely different subject (e.g., went from "cat" to "sunset over mountains")

### Edit Detection Examples

| User says | Pass -i? | Why |
|-----------|----------|-----|
| "make it wider" | YES | Modifying the image |
| "change the background to blue" | YES | Editing existing image |
| "same thing but in 16:9" | YES | Variation of current image |
| "add a hat" | YES | Adding to current image |
| "make it more vibrant" | YES | Style adjustment |
| "try a different pose" | YES | Variation request |
| "that's too dark" | YES | Feedback = edit request |
| "now make a sunset" | MAYBE | Could be new, ask if unsure |
| "create a logo for my company" | NO | Completely new subject |

## Workflow Examples

### Example 1: Iterative Refinement
```
User: make me a cartoon cat

> go run $SKILL_DIR/scripts/main.go -p "a cartoon cat" -o cat.png
# Track: cat.png

User: make it wider for a desktop wallpaper

> go run $SKILL_DIR/scripts/main.go -i cat.png -p "make it wider for a desktop wallpaper" -o cat_wide.png
# Track: cat_wide.png  (USE EXACT WORDING)

User: add some stars in the background

> go run $SKILL_DIR/scripts/main.go -i cat_wide.png -p "add some stars in the background" -o cat_stars.png
# Track: cat_stars.png  (USE EXACT WORDING)

User: make the colors more pastel

> go run $SKILL_DIR/scripts/main.go -i cat_stars.png -p "make the colors more pastel" -o cat_pastel.png
# Track: cat_pastel.png  (USE EXACT WORDING)
```

### Example 2: Style Transfer
```
User: generate a portrait of a dog

> go run $SKILL_DIR/scripts/main.go -p "a portrait of a dog" -o dog.png
# Track: dog.png

User: make it look like a watercolor painting

> go run $SKILL_DIR/scripts/main.go -i dog.png -p "make it look like a watercolor painting" -o dog_watercolor.png
# Track: dog_watercolor.png  (USE EXACT WORDING)

User: now oil painting style

> go run $SKILL_DIR/scripts/main.go -i dog_watercolor.png -p "now oil painting style" -o dog_oil.png
# Track: dog_oil.png  (USE EXACT WORDING)
```

### Example 3: Aspect Ratio Changes
```
User: create an image of a mountain landscape

> go run $SKILL_DIR/scripts/main.go -p "a mountain landscape" -o mountain.png
# Track: mountain.png

User: I need it in portrait orientation for my phone

> go run $SKILL_DIR/scripts/main.go -i mountain.png -p "I need it in portrait orientation for my phone" -o mountain_portrait.png
# Track: mountain_portrait.png  (USE EXACT WORDING)
```

### Example 4: New Image (No -i)
```
User: make me a wizard cat

> go run $SKILL_DIR/scripts/main.go -p "a wizard cat" -o wizard_cat.png
# Track: wizard_cat.png

User: actually, I want a picture of the Eiffel Tower instead

> go run $SKILL_DIR/scripts/main.go -p "a picture of the Eiffel Tower" -o eiffel.png
# Track: eiffel.png (new subject, no -i)
```

## Models

| Model | Best For |
|-------|----------|
| `gemini-2.5-flash-image` | Fast generation, simple edits, iteration |
| `gemini-3-pro-image-preview` | Text rendering, infographics, 4K output, complex composition |

On first run, the tool lists available models and prompts you to select one. Your choice is cached for future runs.

## API Key Resolution

The script checks in order:
1. `GEMINI_API_KEY` environment variable
2. `GOOGLE_API_KEY` environment variable
3. `.env` file in current directory or parent directories

### Setting up .env file

```bash
GEMINI_API_KEY=your-api-key-here
```

## Prompting Tips

**For edits**: Use the user's exact words. Don't rephrase, enhance, or add details - the model works best with natural language.

```
User: "make it blue"
Prompt: "make it blue"  ✓  (not "change the background color to a vibrant blue")

User: "wider"
Prompt: "wider"  ✓  (not "convert to 16:9 widescreen aspect ratio")
```

## Reference

For detailed prompting strategies, see `$SKILL_DIR/references/prompting_guide.md`.
