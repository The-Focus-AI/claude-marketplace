---
title: "LLM Tracing & Agent Tuning: LangFuse"
date: 2025-11-28
topic: llm-tracing-tuning
recommendation: "langfuse"
version_researched: "langfuse 3.x/4.x"
use_when:
  - Building AI agents in TypeScript without a heavy framework like LangChain
  - You need to turn logs into datasets for fine-tuning (RLHF / supervised fine-tuning)
  - You want a self-hostable option or a generous free tier (hobbyist friendly)
  - You need to capture complex nested traces (tool calls, reasoning steps)
avoid_when:
  - You are already deeply invested in the LangChain ecosystem (use LangSmith)
  - You need strictly zero-latency overhead (use purely async/fire-and-forget logging to a raw DB)
  - You are building a simple "stateless" chat app where basic logging suffices
project_context:
  language: TypeScript
  relevant_dependencies: ["@google/genai", "tsx"]
---

## Summary

**LangFuse** is the recommended solution for capturing LLM traces and enabling agent tuning in this project. It provides a lightweight TypeScript SDK that integrates cleanly with `@google/genai` without requiring framework lock-in.

Its standout feature for "agent tuning" is the **Datasets** workflow: you can tag specific high-quality traces (or user-rated interactions) and export them directly as JSONL/CSV formatted for Gemini fine-tuning. It has gained significant popularity (2.5k+ GitHub stars) and offers a "store everything" approach that is critical for debugging complex agentic loops[1].

## Philosophy & Mental Model

Treat observability as your **dataset pipeline**. In traditional software, logs are for debugging errors. In AI engineering, logs (traces) are the *source code* for your next model iteration.

- **Trace**: The root object representing a single execution (e.g., a user request).
- **Span**: A unit of work within a trace (e.g., "retrieve_context", "execute_tool").
- **Generation**: A specialized span for LLM calls that captures token counts, model names, and prompt/completion pairs.
- **Score**: A quality metric attached to a trace (e.g., user thumb-up/down, or model-based eval), crucial for filtering data for tuning[2].

## Setup

Install the SDK:

```bash
pnpm add langfuse
```

Configure environment variables (get these from [cloud.langfuse.com](https://cloud.langfuse.com) or your self-hosted instance):

```bash
# .env
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_HOST=https://cloud.langfuse.com # or your host
```

## Core Usage Patterns

### Pattern 1: Manual Instrumentation (Recommended)

Since `@google/genai` is a newer SDK, manual instrumentation provides the most reliable data capture.

```typescript
import { Langfuse } from "langfuse";
import { GoogleGenAI } from "@google/genai";

const langfuse = new Langfuse();
const genai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function runAgent(prompt: string) {
  // 1. Start a trace
  const trace = langfuse.trace({
    name: "cli-agent-run",
    input: { prompt },
    metadata: { env: "dev" }
  });

  try {
    // 2. Create a generation span for the LLM call
    const generation = trace.generation({
      name: "gemini-pro-call",
      model: "gemini-1.5-pro",
      input: prompt
    });

    const result = await genai.models.generateContent({
      model: "gemini-1.5-pro",
      contents: [{ role: "user", parts: [{ text: prompt }] }]
    });

    const outputText = result.response.text();

    // 3. End generation with usage stats
    generation.end({
      output: outputText,
      usage: {
        input: result.response.usageMetadata?.promptTokenCount,
        output: result.response.usageMetadata?.candidatesTokenCount
      }
    });

    // 4. Update trace status
    trace.update({ output: outputText });
    return outputText;
  } catch (error) {
    trace.update({ level: "ERROR", statusMessage: String(error) });
    throw error;
  } finally {
    // 5. FLUSH - Critical for CLI tools!
    await langfuse.shutdownAsync();
  }
}
```

### Pattern 2: The "Observe" Decorator

For simpler functions, you can wrap them to auto-create spans.

```typescript
import { observe } from "langfuse";

const cleanOutput = observe(async (text: string) => {
  return text.trim();
}, { name: "clean-output" }); // Creates a span named "clean-output"

// Usage inside a trace context
// Note: This requires AsyncLocalStorage context propagation 
// which LangFuse handles if you use their `observe` API correctly.
```

### Pattern 3: Dataset Creation for Tuning

This is the key workflow for agent tuning. You programmatically add good examples to a dataset.

```typescript
async function markForFineTuning(traceId: string, correction: string) {
  // Retrieve the trace (conceptually) or just add the data directly
  await langfuse.createDatasetItem({
    datasetName: "gemini-tuning-v1",
    input: { role: "user", content: "..." }, // data from trace
    expectedOutput: { role: "model", content: correction }
  });
}
```

## Anti-Patterns & Pitfalls

### ❌ Don't: Forget to Flush in CLI

In long-running servers, LangFuse batches events in the background. In a CLI tool (like this project), the process might exit before logs are sent.

```typescript
// ❌ WRONG
await runAgent();
process.exit(0); // Logs likely lost
```

### ✅ Instead: Always Shutdown

```typescript
// ✅ CORRECT
await runAgent();
await langfuse.shutdownAsync(); // Forces flush
process.exit(0);
```

### ❌ Don't: Rely on Auto-Instrumentation for Bleeding Edge SDKs

While packages like `opentelemetry-instrumentation-google-genai` exist, they often lag behind the official `@google/genai` releases. Manual `generation()` calls are robust and future-proof.

## Caveats

- **Latency**: Adding `await` to tracing calls (if not using the async background queue) can slow down the agent. LangFuse SDK is async by default, but ensuring reliability in serverless/CLI requires care.
- **Data Privacy**: If using LangFuse Cloud, you are sending prompts to their servers (US/EU). For strict enterprise data boundaries, use the Docker self-hosted version.

## References

[1] [LangFuse Documentation](https://langfuse.com/docs) - Core concepts and SDK reference
[2] [LangFuse Datasets](https://langfuse.com/docs/datasets) - Guide to using traces for evaluation and fine-tuning
[3] [Gemini SDK Instrumentation](https://langfuse.com/integrations/model-providers/google-gemini) - specific examples for Google models
