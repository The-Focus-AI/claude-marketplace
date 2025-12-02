---
title: "Local Agent Tracing: Firebase Genkit"
date: 2025-11-28
topic: local-agent-tracing
recommendation: "Firebase Genkit"
version_researched: "Genkit 1.x (Node.js)"
use_when:
  - You need a **purely local** tracing UI that runs in Node.js (no Docker, no Python required)
  - You are already using `@google/genai` and want first-class integration
  - You want to evaluate and curate datasets on your local machine
  - You prefer a "batteries-included" developer experience over stitching together libraries
avoid_when:
  - You need to aggregate traces from a distributed production system (use LangFuse/LangSmith)
  - You strictly cannot adopt a "framework" structure (requires wrapping code in Flows)
  - You are using Python (use Arize Phoenix instead)
project_context:
  language: TypeScript
  relevant_dependencies: ["@google/genai", "tsx"]
---

## Summary

**Firebase Genkit** is the best recommendation for "purely local" tracing in a TypeScript/Google GenAI project. Unlike other tools that require running Docker containers (LangFuse) or Python servers (Arize Phoenix), Genkit provides a rich **Developer UI** that runs directly in your Node.js environment via `npx genkit start`.

While Genkit is a full framework, you can use it minimally as a "wrapper" around your agent to gain instant access to trace visualization, input/output inspection, and dataset curation tools—all locally[1].

## Philosophy & Mental Model

Genkit models your application as a set of **Flows**. A Flow is just a function with a schema.
- **Observability by Default**: Anything inside a Flow is automatically traced.
- **Local-First Developer Experience**: The `genkit start` tool is the center of the universe. It acts as a debugger, trace viewer, and playground.
- **Reflection**: The UI inspects your code (via TypeScript reflection/schema) to generate test interfaces.

## Setup

Install the Genkit CLI and core packages:

```bash
npm install -g genkit
npm install genkit @genkit-ai/googleai
```

Initialize a minimal config (no need for Firebase Cloud project for local use):

```bash
# Initialize in current directory
genkit init
# Select "Local" mode when prompted
```

## Core Usage Patterns

### Pattern 1: The "Wrapper" Flow

To get tracing without rewriting your entire agent, wrap your entry point in a `defineFlow`. This captures the top-level inputs/outputs and any internal steps.

```typescript
import { genkit, z } from 'genkit';
import { googleAI, gemini15Flash } from '@genkit-ai/googleai';

const ai = genkit({
  plugins: [googleAI()],
  model: gemini15Flash, // Sets default model
});

// Wrap your existing agent logic
export const runAgent = ai.defineFlow(
  {
    name: 'runAgent',
    inputSchema: z.object({ prompt: z.string() }),
    outputSchema: z.string(),
  },
  async (input) => {
    // Your existing @google/genai code can go here
    // Or use the Genkit 'generate' helper for auto-instrumentation
    const result = await ai.generate({
      prompt: input.prompt,
    });
    
    return result.text;
  }
);
```

### Pattern 2: The Local Developer UI

This is where the "Agent Tuning" magic happens. You don't read logs; you inspect traces.

```bash
npx genkit start --watch
```

This launches `http://localhost:4000`. You can:
1. **Run** your agent with various inputs.
2. **View Traces**: See every step (retrieval, tool call, generation).
3. **Rate & Curate**: Mark runs as "positive/negative" (store locally).
4. **Export**: Save high-quality traces to JSON for fine-tuning.

### Pattern 3: Manual Steps (Spans)

If you have complex logic (e.g., a loop) inside the flow, use `run` to create sub-spans in the trace.

```typescript
// inside the flow
const context = await ai.run('retrieve-context', async () => {
  return await myVectorStore.search(input.prompt);
});
```

## Anti-Patterns & Pitfalls

### ❌ Don't: Use Production Tracing Locally

Don't configure the Google Cloud Trace exporter when running locally. It adds latency and requires credentials. Stick to the default local trace store (filesystem based).

### ✅ Instead: Use the Dev UI

Rely on `genkit start` for all local debugging. It reads from the `.genkit/` directory where traces are stored.

### ❌ Don't: Mix `@google/genai` and Genkit indiscriminately

While possible, you get better traces if you use `ai.generate()` (Genkit's API) instead of raw `genai.generateContent()`. Genkit's wrapper automatically logs token usage, model parameters, and safety settings to the trace.

## Caveats

- **Framework Buy-in**: Genkit is opinionated. You must use `defineFlow` to get the benefits. It's not just a "logger" you drop in.
- **Node.js Only**: The best tooling is currently for Node.js (perfect for this project).
- **Storage**: Local traces are stored in a temporary or file-based queue. For long-term history, you eventually need a backend (but for "Agent Tuning" sessions, local is fine).

## References

[1] [Firebase Genkit Documentation](https://firebase.google.com/docs/genkit) - Official docs
[2] [Genkit Local Observability](https://firebase.google.com/docs/genkit/local-observability) - Details on the Developer UI
[3] [@genkit-ai/googleai](https://www.npmjs.com/package/@genkit-ai/googleai) - NPM package
