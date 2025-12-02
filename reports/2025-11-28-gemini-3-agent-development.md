---
title: "Gemini 3 Agent Development: @google/genai SDK"
date: 2025-11-28
topic: gemini-3-agent-sdk
recommendation: "@google/genai"
version_researched: "@google/genai 1.30.0, Gemini 3 Pro Preview, Imagen 4 Ultra"
use_when:
  - Building agentic CLI tools with multi-turn conversations
  - Need streaming responses for real-time user feedback
  - Generating photorealistic images with Imagen 4 Ultra
  - Generating videos with Veo 3.1
  - Require function calling for tool use
avoid_when:
  - Legacy codebases using @google/generative-ai (migrate first)
  - Browser-only apps without server-side API key management
  - Need Gemini 1.x compatibility (deprecated)
project_context:
  language: TypeScript
  relevant_dependencies: [tsx, vitest, node 22+]
---

## Summary

For building a software writing agent with Gemini 3, use the **`@google/genai`** SDK (v1.30.0)[1]. This is Google's official, production-ready TypeScript/JavaScript SDK that replaced the deprecated `@google/generative-ai` package. The old package will lose all support on August 31, 2025[2].

**Gemini 3 Pro** (model: `gemini-3-pro-preview`) was released November 25, 2025[3]. It offers state-of-the-art reasoning with a 1M token context window, 64K token output, and scores 54.2% on Terminal-Bench 2.0 for tool use[4]. Pricing is $2/M input tokens and $12/M output tokens for prompts under 200K tokens[3].

**Gemini 2.5 Flash** (model: `gemini-2.5-flash`) is the recommended "quick" model for high-speed, low-cost tasks.

**Imagen 4 Ultra** (model: `imagen-4.0-ultra-generate-001`) is Google's strongest image generation model, excelling at photorealism and text rendering. **Veo 3.1** (model: `veo-3.1-generate-preview`) generates 8-second video clips with native audio from text or image prompts[6].

## Philosophy & Mental Model

The `@google/genai` SDK provides a unified interface for all Gemini capabilities:

1. **`ai.models`** - Direct content generation with `generateContent` and `generateContentStream`
2. **`ai.chats`** - Stateful multi-turn conversations that automatically manage history and thought signatures
3. **`ai.files`** - Upload and reference files for multimodal prompts
4. **`ai.operations`** - Poll async operations (video generation)
5. **`ai.live`** - Real-time interactions with audio/video

**Key Gemini 3 concepts:**

- **Thought Signatures**: Encrypted representations of the model's reasoning state. Required for function calling to maintain context across tool invocations. The SDK handles these automatically when using `ai.chats`[7].
- **Thinking Levels**: Control reasoning depth via `thinking_level` parameter. Higher levels improve complex task quality but increase latency and cost[3].
- **Response Modalities**: Specify `['TEXT', 'IMAGE']` to receive both text and generated images in responses.

**Mental model for agents**: Use `ai.chats.create()` for your agent loop. The chat object maintains conversation history, handles thought signatures automatically, and supports streaming with `sendMessageStream()`. Define tools via `functionDeclarations` for the model to invoke your agent's capabilities.

## Setup

### Step 1: Install the SDK

```bash
npm install @google/genai
```

### Step 2: Configure environment

Add to your `mise.toml`:

```toml
[env]
GEMINI_API_KEY = "{{env.GEMINI_API_KEY}}"
```

Or set directly:

```bash
export GEMINI_API_KEY="your-api-key-from-ai-studio"
```

Get your API key from [Google AI Studio](https://aistudio.google.com/apikey).

### Step 3: Create the client

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
```

For Vertex AI (enterprise):

```typescript
const ai = new GoogleGenAI({
  vertexai: true,
  project: process.env.GOOGLE_CLOUD_PROJECT,
  location: process.env.GOOGLE_CLOUD_LOCATION || "us-central1",
});
```

## Core Usage Patterns

### Pattern 1: Streaming Text Generation

For responsive CLI output, use streaming to display tokens as they arrive:

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function streamResponse(prompt: string): Promise<string> {
  const response = await ai.models.generateContentStream({
    model: "gemini-3-pro-preview",
    contents: prompt,
  });

  let fullText = "";
  for await (const chunk of response) {
    const text = chunk.text;
    if (text) {
      process.stdout.write(text);
      fullText += text;
    }
  }
  return fullText;
}
```

### Pattern 2: Multi-Turn Chat with Streaming

Use `ai.chats` for agent conversations. History and thought signatures are managed automatically:

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function runAgentLoop() {
  const chat = ai.chats.create({
    model: "gemini-3-pro-preview",
    config: {
      systemInstruction: "You are a software engineering assistant...",
    },
  });

  // First turn
  const stream1 = await chat.sendMessageStream({
    message: "Help me refactor this function to use async/await",
  });
  for await (const chunk of stream1) {
    process.stdout.write(chunk.text ?? "");
  }

  // Second turn - history is maintained automatically
  const stream2 = await chat.sendMessageStream({
    message: "Now add error handling",
  });
  for await (const chunk of stream2) {
    process.stdout.write(chunk.text ?? "");
  }

  // Access conversation history if needed
  const history = chat.getHistory(true); // curated history
}
```

### Pattern 3: Function Calling for Agent Tools

Define tools the model can invoke. The SDK handles thought signatures automatically:

```typescript
import { GoogleGenAI, Type } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const readFileTool = {
  name: "read_file",
  description: "Read the contents of a file from the filesystem",
  parameters: {
    type: Type.OBJECT,
    properties: {
      path: {
        type: Type.STRING,
        description: "The absolute path to the file to read",
      },
    },
    required: ["path"],
  },
};

const writeFileTool = {
  name: "write_file",
  description: "Write content to a file",
  parameters: {
    type: Type.OBJECT,
    properties: {
      path: { type: Type.STRING, description: "File path" },
      content: { type: Type.STRING, description: "Content to write" },
    },
    required: ["path", "content"],
  },
};

// Simple logging helper with timestamp
function log(message: string) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

async function agentWithTools() {
  const chat = ai.chats.create({
    model: "gemini-3-pro-preview",
    config: {
      tools: [{ functionDeclarations: [readFileTool, writeFileTool] }],
    },
  });

  const response = await chat.sendMessage({
    message: "Read the file at /src/index.ts and add error handling",
  });

  // Check if model wants to call a function
  if (response.functionCalls && response.functionCalls.length > 0) {
    const functionCall = response.functionCalls[0];
    log(`Tool requested: ${functionCall.name}`);
    log(`Args: ${JSON.stringify(functionCall.args)}`);

    // Execute the tool and send result back
    const result = await executeFunction(functionCall.name, functionCall.args);

    const followUp = await chat.sendMessage({
      message: [{ functionResponse: { name: functionCall.name, response: { result } } }],
    });
  }
}
```

### Pattern 4: Image Generation with Imagen 4 Ultra

Generate high-quality images. Use `gemini-2.5-flash` for speed (if text-only) or `imagen-4.0-ultra-generate-001` for strongest image generation:

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function generateImage(prompt: string, outputPath: string) {
  const response = await ai.models.generateContent({
    model: "imagen-4.0-ultra-generate-001",
    contents: prompt,
    config: {
      // responseModalities: ["IMAGE"], // For Imagen models, often implicit or specific config
      // Check specific Imagen 4 Ultra config requirements
    },
  });

  // Depending on the model, the response structure might vary slightly, 
  // but generally follows the candidate parts pattern.
  for (const part of response.candidates[0].content.parts) {
     if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync(outputPath, buffer);
      console.log(`[${new Date().toISOString()}] Image saved to ${outputPath}`);
    }
  }
}
```

### Pattern 5: Multi-Turn Image Editing

Refine images conversationally (Note: specific editing capabilities depend on model support, `gemini-3-pro-image-preview` is often better for *conversational* multimodal editing, but `imagen-4.0-ultra` is strongest for generation):

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function iterativeImageEditing() {
  // Using Gemini 3 Pro for conversational editing as it supports text+image modalities well
  const chat = ai.chats.create({
    model: "gemini-3-pro-preview", // or gemini-3-pro-image-preview if available for this
    config: {
      responseModalities: ["TEXT", "IMAGE"],
    },
  });

  // Generate initial image
  let response = await chat.sendMessage({
    message: "Create a diagram showing microservices architecture",
  });
  saveImage(response, "diagram-v1.png");

  // Refine it
  response = await chat.sendMessage({
    message: "Add a message queue between the services",
    config: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: { aspectRatio: "16:9", imageSize: "2K" },
    },
  });
  saveImage(response, "diagram-v2.png");
}

function saveImage(response: any, filename: string) {
  for (const part of response.candidates[0].content.parts) {
    if (part.inlineData) {
      fs.writeFileSync(filename, Buffer.from(part.inlineData.data, "base64"));
      console.log(`[${new Date().toISOString()}] Image saved to ${filename}`);
    }
  }
}
```

### Pattern 6: Video Generation with Veo 3.1

Video generation is async - submit a request, poll for completion, then download:

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function generateVideo(prompt: string, outputPath: string) {
  // Submit generation request
  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt: prompt,
    config: {
      aspectRatio: "16:9",
      negativePrompt: "low quality, blurry, distorted",
    },
  });

  // Poll until complete
  while (!operation.done) {
    console.log(`[${new Date().toISOString()}] Generating video...`);
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  // Download the video
  await ai.files.download({
    file: operation.response.generatedVideos[0].video,
    downloadPath: outputPath,
  });
  console.log(`[${new Date().toISOString()}] Video saved to ${outputPath}`);
}
```

### Pattern 7: Image-to-Video Pipeline

Generate an image first, then animate it:

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function imageToVideo(description: string, outputPath: string) {
  // Step 1: Generate image with Imagen 4 Ultra
  const imageResponse = await ai.models.generateContent({
    model: "imagen-4.0-ultra-generate-001",
    contents: description,
  });

  const imageData = imageResponse.candidates[0].content.parts[0].inlineData;

  // Step 2: Animate with Veo
  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt: description,
    image: {
      imageBytes: imageData.data,
      mimeType: imageData.mimeType,
    },
  });

  while (!operation.done) {
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response.generatedVideos[0].video,
    downloadPath: outputPath,
  });
}
```

## Anti-Patterns & Pitfalls

### Don't: Use the deprecated @google/generative-ai package

```typescript
// Bad - deprecated, loses support August 2025
import { GoogleGenerativeAI } from "@google/generative-ai";
```

**Why it's wrong:** The old SDK won't receive Gemini 3 features and will be completely unsupported after August 31, 2025[2].

### Instead: Use @google/genai

```typescript
// Good - actively maintained, supports all Gemini 3 features
import { GoogleGenAI } from "@google/genai";
```

---

### Don't: Lower temperature for Gemini 3

```typescript
// Bad - degrades reasoning quality
const response = await ai.models.generateContent({
  model: "gemini-3-pro-preview",
  contents: prompt,
  config: { temperature: 0.2 },
});
```

**Why it's wrong:** Gemini 3's reasoning engine is optimized for temperature 1.0. Lowering it may cause looping or degraded performance on complex tasks[7].

### Instead: Keep temperature at 1.0 (default)

```typescript
// Good - let the model reason optimally
const response = await ai.models.generateContent({
  model: "gemini-3-pro-preview",
  contents: prompt,
  // temperature defaults to 1.0
});
```

---

### Don't: Manually manage thought signatures when using ai.chats

```typescript
// Bad - unnecessary complexity
const response = await chat.sendMessage({ message: "..." });
const signature = response.candidates[0].content.parts[0].thoughtSignature;
// manually tracking signatures...
```

**Why it's wrong:** The SDK handles thought signatures automatically when using `ai.chats`. Manual management is error-prone and unnecessary[8].

### Instead: Let the SDK handle it

```typescript
// Good - SDK manages signatures automatically
const chat = ai.chats.create({ model: "gemini-3-pro-preview" });
await chat.sendMessage({ message: "first message" });
await chat.sendMessage({ message: "follow up" }); // signatures handled
```

---

### Don't: Use lowercase for imageSize

```typescript
// Bad - will be rejected
config: {
  imageConfig: { imageSize: "2k" }  // lowercase fails!
}
```

**Why it's wrong:** The API requires uppercase "K" in image sizes[9].

### Instead: Always use uppercase

```typescript
// Good
config: {
  imageConfig: { imageSize: "2K" }  // uppercase required
}
```

---

### Don't: Forget to poll video generation

```typescript
// Bad - returns immediately without the video
const operation = await ai.models.generateVideos({
  model: "veo-3.1-generate-preview",
  prompt: "...",
});
// operation.response is undefined here!
```

**Why it's wrong:** Video generation is asynchronous. The initial response is just an operation handle.

### Instead: Poll until done

```typescript
// Good - wait for completion
let operation = await ai.models.generateVideos({ model: "veo-3.1-generate-preview", prompt: "..." });
while (!operation.done) {
  await new Promise(r => setTimeout(r, 10000));
  operation = await ai.operations.getVideosOperation({ operation });
}
// Now operation.response.generatedVideos is available
```

---

### Don't: Expose API keys in client-side code

```typescript
// Bad - exposes key to users
const ai = new GoogleGenAI({ apiKey: "AIza..." }); // hardcoded in frontend
```

**Why it's wrong:** Anyone can extract the key from your JavaScript bundle and abuse it.

### Instead: Use server-side proxy

```typescript
// Good - key stays on server
// Server: handles auth, proxies to Gemini API
// Client: calls your server endpoint
```

## Caveats

- **Gemini 3 Pro is in Preview**: Model name is `gemini-3-pro-preview`. Expect potential changes before GA[3].

- **Imagen 4 Ultra has no free tier**: High-end image generation requires a billing-enabled API key[5].

- **Video generation is slow**: Veo 3.1 takes 1-5 minutes to generate 8-second clips. Plan your UX accordingly with progress indicators[6].

- **All generated images have SynthID watermarks**: Google embeds invisible watermarks in all AI-generated images for provenance tracking[9].

- **1M token context, but costs add up**: While Gemini 3 supports 1M tokens input, you're charged per token. For agents, consider summarizing history periodically.

- **Thought signature bypass string**: If migrating conversations from other models, use `"thoughtSignature": "context_engineering_is_the_way_to_go"` to bypass validation[7].

- **Function calling requires strict mode**: Gemini 3 validates thought signatures strictly for function calls. Missing signatures return 400 errors[7].

## References

[1] [@google/genai - npm](https://www.npmjs.com/package/@google/genai) - Official SDK package, v1.30.0, 723 dependents

[2] [@google/generative-ai - npm](https://www.npmjs.com/package/@google/generative-ai) - Deprecation notice, support ends August 31, 2025

[3] [New Gemini API updates for Gemini 3 - Google Developers Blog](https://developers.googleblog.com/new-gemini-api-updates-for-gemini-3/) - Gemini 3 release announcement, November 25, 2025

[4] [Gemini 3 Pro - Google DeepMind](https://deepmind.google/models/gemini/pro/) - Model specifications and benchmarks

[5] [Nano Banana Pro: Gemini 3 Pro Image - Google Blog](https://blog.google/technology/ai/nano-banana-pro/) - Nano Banana Pro announcement, November 20, 2025

[6] [Generate videos with Veo 3.1 - Google AI Developers](https://ai.google.dev/gemini-api/docs/video) - Veo 3.1 API documentation and code examples

[7] [Thought Signatures - Google AI Developers](https://ai.google.dev/gemini-api/docs/thought-signatures) - Thought signature handling requirements

[8] [Chat Class - @google/genai](https://googleapis.github.io/js-genai/release_docs/classes/chats.Chat.html) - Chat API reference, automatic signature handling

[9] [Image generation with Gemini - Google AI Developers](https://ai.google.dev/gemini-api/docs/image-generation) - Nano Banana documentation, configuration options

[10] [GitHub - googleapis/js-genai](https://github.com/googleapis/js-genai) - SDK source code and samples

[11] [Gemini 3 Developer Guide - Google AI Developers](https://ai.google.dev/gemini-api/docs/gemini-3) - Comprehensive Gemini 3 developer documentation

[12] [Function calling with the Gemini API - Google AI Developers](https://ai.google.dev/gemini-api/docs/function-calling) - Function calling patterns and examples
