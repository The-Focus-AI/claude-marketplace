---
title: "TypeScript CLI Project Setup: tsx + Vitest"
date: 2025-11-28
topic: typescript-project-setup
recommendation: tsx + vitest
version_researched: tsx 4.20.6, vitest 4.0.14, Node.js 22+
use_when:
  - Building CLI tools or backend services in TypeScript
  - You want zero-config TypeScript execution
  - You need fast, modern testing with Jest-compatible API
  - Using mise for environment management
avoid_when:
  - Building frontend applications (use Vite directly)
  - You need to publish a library to npm (add tsdown for bundling)
  - You require experimental TypeScript features like decorators
project_context:
  language: TypeScript
  relevant_dependencies: [node via mise]
---

## Summary

For a modern, simple TypeScript CLI project in late 2025, the winning combination is **tsx** for TypeScript execution and **Vitest** for testing. This setup requires minimal configuration while providing excellent developer experience.

**tsx** (11.6k GitHub stars, 1,838 dependent projects)[1] is a zero-config TypeScript runner built on esbuild. It "just works" without requiring a `tsconfig.json`, handles ESM/CJS seamlessly, and supports watch mode out of the box. While Node.js 22+ now has native TypeScript support via type stripping[2], tsx remains the better choice for CLI development because native support has significant limitations: no enums without extra flags, no tsconfig features like path aliases, and the native approach is still considered experimental for production[3].

**Vitest** (15.4k GitHub stars, ~18.5M weekly downloads)[4] has become the de facto standard for TypeScript testing. It offers native TypeScript/ESM support, Jest-compatible APIs, and runs 10-20x faster than Jest in watch mode[5]. For Node.js CLI applications, Vitest provides a cleaner experience than Node's built-in test runner, which lacks TypeScript documentation and requires additional loader configuration[6].

## Philosophy & Mental Model

The core philosophy is **separation of concerns with minimal tooling**:

1. **tsx** handles execution only—it transpiles and runs TypeScript instantly without type checking. This is a feature, not a limitation: you get instant feedback during development.

2. **tsc** (TypeScript compiler) handles type checking as a separate step. Run it in CI or as a pre-commit hook. This separation means you're never blocked by type errors during iteration.

3. **Vitest** handles testing with the same fast, esbuild-powered transpilation approach as tsx.

4. **mise** orchestrates everything through tasks, replacing npm scripts with a more powerful task runner that includes environment management.

The mental model: **Write TypeScript → Run instantly with tsx → Test with Vitest → Type-check with tsc before committing**.

## Setup

### Step 1: Initialize the project with mise

Update your `mise.toml` to include tasks and the node_modules bin path:

```toml
[env]
_.path = ["./node_modules/.bin"]

[tools]
node = "22"

[tasks.dev]
description = "Run in development mode with watch"
run = "tsx watch src/index.ts"

[tasks.test]
description = "Run tests"
run = "vitest"

[tasks.test-run]
description = "Run tests once"
run = "vitest run"

[tasks.typecheck]
description = "Type check with tsc"
run = "tsc --noEmit"

[tasks.build]
description = "Build for production"
run = "tsdown src/index.ts"
```

### Step 2: Initialize npm and install dependencies

```bash
npm init -y
npm install -D typescript tsx vitest @types/node
```

### Step 3: Create tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "noEmit": true,
    "outDir": "dist",
    "rootDir": "src",
    "declaration": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Step 4: Create vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.test.ts', 'tests/**/*.test.ts'],
  },
})
```

### Step 5: Create project structure

```bash
mkdir -p src tests
```

Create `src/index.ts`:

```typescript
export function main(): void {
  console.log('Hello from CLI!')
}

main()
```

Create `src/example.test.ts`:

```typescript
import { describe, it, expect } from 'vitest'

describe('example', () => {
  it('should work', () => {
    expect(1 + 1).toBe(2)
  })
})
```

### Step 6: Update package.json

Add the type field and basic scripts as fallback:

```json
{
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "test": "vitest",
    "typecheck": "tsc --noEmit"
  }
}
```

## Core Usage Patterns

### Pattern 1: Running TypeScript Files

```bash
# Run a file directly
tsx src/index.ts

# Run with watch mode (restarts on changes)
tsx watch src/index.ts

# Or use mise tasks
mise run dev
```

### Pattern 2: Writing Tests

```typescript
// src/utils.ts
export function parseArgs(args: string[]): Record<string, string> {
  const result: Record<string, string> = {}
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i]?.replace(/^--/, '')
    const value = args[i + 1]
    if (key && value) {
      result[key] = value
    }
  }
  return result
}

// src/utils.test.ts
import { describe, it, expect } from 'vitest'
import { parseArgs } from './utils.js'

describe('parseArgs', () => {
  it('parses key-value pairs', () => {
    const result = parseArgs(['--name', 'alice', '--age', '30'])
    expect(result).toEqual({ name: 'alice', age: '30' })
  })

  it('handles empty input', () => {
    expect(parseArgs([])).toEqual({})
  })
})
```

### Pattern 3: Watch Mode Testing

```bash
# Interactive watch mode (default)
vitest

# Run once and exit
vitest run

# Run specific test file
vitest run src/utils.test.ts

# With coverage
vitest run --coverage
```

### Pattern 4: Type Checking Separately

```bash
# Check types without emitting files
tsc --noEmit

# Watch mode type checking
tsc --noEmit --watch

# Use mise task
mise run typecheck
```

### Pattern 5: CLI Entry Point Pattern

```typescript
// src/cli.ts
import { parseArgs } from 'node:util'

interface Options {
  help: boolean
  version: boolean
  config?: string
}

export function cli(args: string[]): void {
  const { values } = parseArgs({
    args,
    options: {
      help: { type: 'boolean', short: 'h', default: false },
      version: { type: 'boolean', short: 'v', default: false },
      config: { type: 'string', short: 'c' },
    },
    strict: true,
  })

  if (values.help) {
    console.log('Usage: mycli [options]')
    return
  }

  if (values.version) {
    console.log('1.0.0')
    return
  }

  // Main logic here
}

// Run if this is the entry point
cli(process.argv.slice(2))
```

## Anti-Patterns & Pitfalls

### Don't: Use relative imports without `.js` extension

```typescript
// Bad - may cause issues with ESM
import { helper } from './helper'
```

**Why it's wrong:** ESM requires explicit file extensions. TypeScript's module resolution uses `.js` even for `.ts` files because that's what they compile to.

### Instead: Always use `.js` extensions in imports

```typescript
// Good - works correctly with ESM
import { helper } from './helper.js'
```

---

### Don't: Mix tsx and tsc for execution

```typescript
// Bad workflow
tsc && node dist/index.js  // Slow, unnecessary for development
```

**Why it's wrong:** You lose the instant feedback of tsx, and you're maintaining compiled output unnecessarily during development.

### Instead: Use tsx for development, tsc only for type checking

```bash
# Development
tsx src/index.ts

# Type check in CI or pre-commit
tsc --noEmit
```

---

### Don't: Use Jest-style globals without configuring Vitest

```typescript
// Bad - will fail without globals: true in config
describe('test', () => {  // Error: describe is not defined
  it('works', () => {})
})
```

**Why it's wrong:** Vitest doesn't inject globals by default.

### Instead: Either import from vitest or enable globals

```typescript
// Option 1: Explicit imports (recommended for clarity)
import { describe, it, expect } from 'vitest'

// Option 2: Enable globals in vitest.config.ts
// test: { globals: true }
```

---

### Don't: Put test files in a separate tests/ directory by default

```
// Anti-pattern structure
src/
  utils.ts
tests/
  utils.test.ts  // Far from the code it tests
```

**Why it's problematic:** Tests become disconnected from the code they test, making refactoring harder.

### Instead: Colocate tests with source files

```
// Better structure
src/
  utils.ts
  utils.test.ts  // Right next to the code
```

---

### Don't: Skip type checking entirely

```bash
# Bad - no type safety verification
tsx src/index.ts && npm publish
```

**Why it's wrong:** tsx doesn't type check. You could ship code with type errors.

### Instead: Add type checking to your CI/pre-commit

```bash
# In CI or pre-commit hook
tsc --noEmit && vitest run
```

## Caveats

- **No bundling included**: This setup is for development and running TypeScript directly. If you need to distribute a compiled CLI (e.g., to npm), add `tsdown` for bundling: `npm install -D tsdown`[7].

- **tsx doesn't type check**: This is by design for speed, but means you must run `tsc --noEmit` separately to catch type errors. Always include this in CI.

- **ESM is the default**: With `"type": "module"` in package.json, all `.ts` files are treated as ESM. Use `.cts` extension or `"type": "commonjs"` if you need CommonJS.

- **Node.js native TypeScript is not recommended yet**: While Node 22+ supports TypeScript natively via `--experimental-strip-types`, it has limitations (no enums, no path aliases, no tsconfig features) and is still considered experimental for production[8].

- **Vitest's frontend focus**: Most Vitest documentation assumes frontend/Vite usage. For pure Node.js CLI testing, ignore the DOM/browser-related features[9].

- **Watch mode memory**: Both tsx and Vitest watch modes keep processes running. For large projects, this can consume significant memory.

## References

[1] [tsx GitHub Repository](https://github.com/privatenumber/tsx) - GitHub stars, feature overview, and documentation

[2] [Node.js Running TypeScript Natively](https://nodejs.org/en/learn/typescript/run-natively) - Official Node.js TypeScript documentation

[3] [Node.js TypeScript API Documentation](https://nodejs.org/api/typescript.html) - Recommended tsconfig settings and feature limitations

[4] [Vitest GitHub Repository](https://github.com/vitest-dev/vitest) - GitHub stars and release information

[5] [Vitest vs Jest Comparison](https://betterstack.com/community/guides/scaling-nodejs/vitest-vs-jest/) - Performance benchmarks and feature comparison

[6] [Node Test Runner vs Vitest Discussion](https://github.com/vitest-dev/vitest/discussions/4631) - Community discussion on native test runner limitations

[7] [tsdown Introduction](https://tsdown.dev/guide/) - Modern TypeScript bundler replacing tsup, built on Rolldown

[8] [Node's Built-in TypeScript Support](https://2ality.com/2025/01/nodejs-strip-type.html) - Dr. Axel Rauschmayer's analysis of limitations

[9] [Vitest Getting Started](https://vitest.dev/guide/) - Official documentation, note frontend-focused examples

[10] [mise Node.js Cookbook](https://mise.jdx.dev/mise-cookbook/nodejs.html) - Task configuration examples for Node.js projects

[11] [TypeScript in 2025 ESM/CJS Publishing](https://lirantal.com/blog/typescript-in-2025-with-esm-and-cjs-npm-publishing) - Best practices for TypeScript library publishing
