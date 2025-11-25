---
name: nano-banana-imagegen
description: Generate and edit images using Google's Nano Banana (Gemini image models). Use this skill when the user asks to create, generate, make, or edit images with AI. Supports text-to-image, image editing, style transfer, and multi-image composition. Automatically enhances prompts with best practices unless user quotes their prompt for exact usage. Tracks conversation context to enable "tweak this" / "change that" editing flows.
---

# Nano Banana Image Generation

Generate and edit images using Google GenAI's Gemini image models (Nano Banana).

## Quick Start

```bash
# Generate a new image
npx nano-banana "a red panda eating bamboo" --output red_panda.png

# Edit an image (pass previous image with --file)
npx nano-banana "make the background blue" --file red_panda.png --output red_panda_v2.png

# List available models
npx nano-banana --list-models
```

## CLI Options

```
Usage: nano-banana <prompt> [--file <image>] [--output <file>] [--flash]
       nano-banana --prompt-file <path> [--file <image>] [--output <file>]
       nano-banana --list-models

Options:
  <prompt>              Prompt text (positional argument)
  --file <image>        Input image for editing (ALWAYS pass previous image path for edits)
  --output <file>       Output filename (ALWAYS use this to control where the file is saved)
  --flash               Use the Flash model for faster generation
  --prompt-file <path>  Read prompt from file
  --list-models         List available image models
```

## CRITICAL: Always Use --output

**You MUST always specify `--output <filename>` to control where generated images are saved.** This ensures predictable file locations and proper tracking for edits.

## CRITICAL: Tracking Images for Edits

**You MUST track the output path of every generated image.** When the user asks to edit/modify/change the image, pass the previous image path using `--file`.

**Use the user's EXACT wording** for edit prompts. Don't rephrase or embellish - pass their request directly to the model.

### Pattern:
```bash
# First generation - remember the output path
npx nano-banana "a wizard cat" --output wizard_cat.png
# Output: ./wizard_cat.png  <-- TRACK THIS PATH

# Any edit - pass the tracked path with --file
npx nano-banana "add a purple cloak" --file wizard_cat.png --output wizard_cat_v2.png
# Output: ./wizard_cat_v2.png  <-- UPDATE TRACKED PATH

# Next edit - use the NEW path
npx nano-banana "make it wider 16:9" --file wizard_cat_v2.png --output wizard_cat_v3.png
```

## When to Pass --file (Previous Image)

**ALWAYS pass `--file <previous_image>` when:**
- User references the previous image in ANY way
- User asks to change, modify, adjust, or tweak anything
- User asks for a different style, color, aspect ratio, or variation
- User says "make it...", "add...", "remove...", "change..."
- User asks for "the same but..." or "like that but..."
- User gives feedback like "too dark", "more colorful", "less busy"
- User asks to "redo", "try again", or "another version"
- ANY follow-up request after generating an image (unless explicitly asking for something completely different)

**Only skip `--file` when:**
- First image generation in conversation (no previous image exists)
- User explicitly asks for a "new image" of something unrelated
- User provides a completely different subject (e.g., went from "cat" to "sunset over mountains")

### Edit Detection Examples

| User says | Pass --file? | Why |
|-----------|--------------|-----|
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

> npx nano-banana "a cartoon cat" --output cat.png
# Track: cat.png

User: make it wider for a desktop wallpaper

> npx nano-banana "make it wider for a desktop wallpaper" --file cat.png --output cat_wide.png
# Track: cat_wide.png  (USE EXACT WORDING)

User: add some stars in the background

> npx nano-banana "add some stars in the background" --file cat_wide.png --output cat_stars.png
# Track: cat_stars.png  (USE EXACT WORDING)

User: make the colors more pastel

> npx nano-banana "make the colors more pastel" --file cat_stars.png --output cat_pastel.png
# Track: cat_pastel.png  (USE EXACT WORDING)
```

### Example 2: Style Transfer
```
User: generate a portrait of a dog

> npx nano-banana "a portrait of a dog" --output dog.png
# Track: dog.png

User: make it look like a watercolor painting

> npx nano-banana "make it look like a watercolor painting" --file dog.png --output dog_watercolor.png
# Track: dog_watercolor.png  (USE EXACT WORDING)

User: now oil painting style

> npx nano-banana "now oil painting style" --file dog_watercolor.png --output dog_oil.png
# Track: dog_oil.png  (USE EXACT WORDING)
```

### Example 3: Aspect Ratio Changes
```
User: create an image of a mountain landscape

> npx nano-banana "a mountain landscape" --output mountain.png
# Track: mountain.png

User: I need it in portrait orientation for my phone

> npx nano-banana "I need it in portrait orientation for my phone" --file mountain.png --output mountain_portrait.png
# Track: mountain_portrait.png  (USE EXACT WORDING)
```

### Example 4: New Image (No --file)
```
User: make me a wizard cat

> npx nano-banana "a wizard cat" --output wizard_cat.png
# Track: wizard_cat.png

User: actually, I want a picture of the Eiffel Tower instead

> npx nano-banana "a picture of the Eiffel Tower" --output eiffel.png
# Track: eiffel.png (new subject, no --file)
```

### Example 5: Using Flash Model
```
User: quickly generate a simple icon

> npx nano-banana "a simple icon" --flash --output icon.png
# Track: icon.png
```

## Models

| Model | Best For |
|-------|----------|
| Default (Pro) | Text rendering, infographics, 4K output, complex composition |
| Flash (`--flash`) | Fast generation, simple edits, iteration |

## API Key Resolution

The tool checks in order:
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
