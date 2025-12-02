---
title: "Dagger Managed Environments: @dagger.io/dagger"
date: 2025-11-28
topic: dagger-managed-environments
recommendation: "@dagger.io/dagger"
version_researched: "@dagger.io/dagger 0.13.x - 0.14.x"
use_when:
  - Building AI agents that need to execute code safely in isolated containers
  - You need programmatic control over the entire environment stack (OS, deps, filesystem)
  - You require a "lower level" API than pre-packaged environments (like `dagger/container-use`)
  - The agent needs to dynamically construct pipelines based on runtime decisions
avoid_when:
  - You just need a simple `eval()` for JavaScript (use `vm` module or QuickJS)
  - You cannot install the Dagger engine binary on the host machine
  - You need persistent, long-running "stateful" servers (Dagger is optimized for ephemeral build chains)
project_context:
  language: TypeScript
  relevant_dependencies: ["@google/genai", "tsx", "vitest"]
---

## Summary

For programmatically controlling isolated environments with TypeScript, **@dagger.io/dagger** is the standard and most robust choice. It provides a strongly-typed, low-level SDK that allows an agent to construct, manipulate, and execute containers as if they were local objects.

Unlike higher-level abstractions that might give you a "pre-baked" dev environment, using the SDK directly gives your agent "God mode" over the container: it can swap base images, mount specific directories, inject secrets, and execute arbitrary commands, all while keeping the host system completely safe[1].

## Philosophy & Mental Model

The most critical concept for an Agent to understand is **Immutability**.

1.  **Chains, Not Shells**: You don't "open a terminal" and type commands. You take a `Container` object and apply a transformation (like `.withExec()`) to get a *new* `Container` object.
2.  **Lazy Execution**: Defining the pipeline does nothing. The container is only built and commands run when you call a terminal method like `.stdout()`, `.sync()`, or `.export()`.
3.  **State Passing**: To "keep" the state of a session (e.g., after `npm install`), the Agent must hold onto the *resulting* container object and use it as the base for the next command.

**The Mental Model:**
Instead of: `SSH -> Run Command -> Wait -> Run Next Command`
Think: `Base State + Command A = State A`; then `State A + Command B = State B`.

## Setup

The agent needs the NPM package, but the *host* machine must have the Dagger engine installed.

### 1. Install Dagger Engine (Host)

```bash
# On the machine running the agent:
curl -L https://dl.dagger.io/dagger/install.sh | sh
```

### 2. Install SDK

```bash
npm install @dagger.io/dagger
```

## Core Usage Patterns

### Pattern 1: The "Stateful" Session
This simulates a persistent workspace where the agent runs multiple commands in sequence, preserving filesystem changes.

```typescript
import { dag, Container, Directory } from "@dagger.io/dagger";

async function runSession() {
  // 1. Initialize a base container (e.g., Node.js)
  let session: Container = dag
    .container()
    .from("node:22-alpine")
    .withWorkdir("/app");

  // 2. "Write" code (simulated by mounting or creating a file)
  // In a real agent, you might mount a directory from the host
  session = session.withNewFile("index.js", "console.log('Hello from Dagger');");

  // 3. Run a command (State A -> State B)
  // We capture the NEW container state
  session = session.withExec(["node", "index.js"]);

  // 4. Extract output (triggers execution)
  const output = await session.stdout();
  console.log("Agent received:", output); // "Hello from Dagger"

  // 5. Continue the session (State B -> State C)
  session = session.withExec(["touch", "test-passed.txt"]);
  
  // Verify file exists
  const files = await session.directory(".").entries();
  console.log("Files:", files); // ['index.js', 'test-passed.txt']
}
```

### Pattern 2: Dynamic Tool Construction
The agent can build its own tools on the fly. If it needs `ffmpeg` but the container doesn't have it, it installs it.

```typescript
async function executeWithTool(toolName: string, args: string[]) {
  // Agent decides it needs a specific environment
  let ctr = dag.container().from("ubuntu:latest");

  // Dynamically install dependencies
  ctr = ctr
    .withExec(["apt-get", "update"])
    .withExec(["apt-get", "install", "-y", toolName]);

  // Run the requested tool
  ctr = ctr.withExec([toolName, ...args]);

  return await ctr.stdout();
}
```

### Pattern 3: Safe File Extraction
When the agent writes code or artifacts inside the container, retrieve them safely without exposing the host fs directly.

```typescript
async function retrieveArtifact(container: Container, path: string) {
  // Get a reference to the file inside the container
  const file = container.file(path);
  
  // Read content directly into memory (good for text)
  const content = await file.contents();
  return content;
}
```

## Anti-Patterns & Pitfalls

### ❌ Don't: Ignoring the Return Value
Dagger objects are immutable. Modifying them returns a *new* object.

```typescript
// BAD
const ctr = dag.container().from("alpine");
ctr.withExec(["echo", "hello"]); // THIS DOES NOTHING to 'ctr'
await ctr.stdout(); // Error or empty output, because 'ctr' is still just the base image
```

### ✅ Instead: Chain or Reassign
```typescript
// GOOD
let ctr = dag.container().from("alpine");
ctr = ctr.withExec(["echo", "hello"]); // Update the reference
await ctr.stdout();
```

### ❌ Don't: treating `withExec` as "Run Now"
`withExec` configures the *plan*. It does not execute until you await a result.

```typescript
// BAD
ctr.withExec(["long-process"]); // Returns instantly
console.log("Done?"); // Prints immediately, process hasn't run
```

### ✅ Instead: Await a Terminal Operation
```typescript
// GOOD
// .sync() forces execution without returning output data
await ctr.withExec(["long-process"]).sync(); 
console.log("Done!");
```

## Caveats

- **Cold Starts:** Pulling the `from(...)` image takes time on the first run. Cache persists locally, so subsequent runs are fast.
- **Engine Requirement:** This is not a pure Node.js library; it communicates with the Dagger Engine (a distinct binary/service). Your deployment environment must support this.
- **Error Handling:** If a command in `.withExec()` fails (non-zero exit code), the Promise rejects. You must wrap chains in `try/catch` to handle "runtime" errors gracefully.

## References

[1] Dagger TypeScript SDK Reference - [Documentation](https://docs.dagger.io/reference/typescript/)
[2] Dagger API Concepts - [Mental Model](https://docs.dagger.io/api/concepts)
[3] Dagger NPM Package - [npm](https://www.npmjs.com/package/@dagger.io/dagger)
