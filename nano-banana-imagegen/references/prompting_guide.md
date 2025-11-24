# Nano Banana Prompting Guide

Best practices for image generation with Gemini's Nano Banana models.

## Core Principle

**Describe the scene, don't list keywords.** The model excels at understanding natural language. A narrative paragraph produces better results than disconnected terms.

## Prompt Structure Template

```
A [style] [shot type] of [subject] [action/pose], set in [environment].
The scene is illuminated by [lighting]. [Camera/lens details if photorealistic].
[Key details: textures, colors, mood]. [Aspect ratio].
```

## Style Keywords

### Photography
- photorealistic, studio-lit, natural light, golden hour
- wide-angle, macro, close-up, portrait, aerial view
- 85mm lens, shallow depth of field, bokeh
- high contrast, soft focus, dramatic shadows

### Illustration
- kawaii-style, cartoon, anime, hand-drawn
- watercolor, oil painting, digital art
- minimalist, flat design, vector art
- vintage, retro, modern, futuristic

### Product/Commercial
- product photograph, mockup, e-commerce
- three-point lighting, softbox, white background
- clean, professional, polished

## Use Case Examples

### Product Shot
```
A high-resolution, studio-lit product photograph of a minimalist ceramic 
coffee mug in matte black, on a polished concrete surface. Three-point 
softbox lighting with soft shadows. Elevated 45-degree angle. Sharp focus 
on steam rising from coffee. Square format.
```

### Portrait
```
A photorealistic close-up portrait of [subject] with [distinctive features].
Soft, natural window light from the left creating gentle shadows. Shot with 
85mm portrait lens, shallow depth of field. Warm, intimate mood.
```

### Sticker/Icon
```
A kawaii-style sticker of a [subject] with [expression/action]. Bold, clean 
outlines, simple cel-shading, vibrant colors. White background.
```

### Logo
```
A modern, minimalist logo for [brand] with the text "[text]" in a clean,
[font style] font. [Color scheme]. Simple, memorable, scalable design.
```

### Infographic (use pro model)
```
A vibrant infographic explaining [topic]. Include [key elements]. Style 
should be [aesthetic]. Clear, legible text labels. [Dimensions].
```

## Editing Prompts

### Adding Elements
```
Using the provided image, add [element] to [location]. Match the existing 
lighting and style. Keep everything else unchanged.
```

### Style Transfer
```
Apply the style of [reference] to this image. Preserve the subject's 
identity and pose. Keep the original composition.
```

### Inpainting
```
Change only the [specific element] to [new description]. Keep everything 
else exactly the same, preserving original style, lighting, and composition.
```

## Model Selection Triggers

### Use Flash (gemini-2.5-flash-image)
- Simple generations, single subject
- Quick iterations and experiments
- Standard aspect ratios at 1024px
- Most editing tasks

### Use Pro (gemini-3-pro-image-preview)
- Complex text rendering (logos, infographics, posters)
- Multi-image composition (2+ input images)
- Sequential art (comics, storyboards)
- High-resolution output (2K, 4K)
- Search-grounded imagery (current events, real data)
- Complex reasoning about scene composition

## Tips

1. **Be specific**: "fluffy orange tabby cat" beats "cat"
2. **Describe lighting**: This single element dramatically changes mood
3. **Mention camera**: For realism, specify lens and angle
4. **Include textures**: "worn leather", "brushed metal", "soft wool"
5. **Set the mood**: "cozy", "dramatic", "ethereal", "playful"
6. **Iterate conversationally**: Start simple, refine in follow-ups
