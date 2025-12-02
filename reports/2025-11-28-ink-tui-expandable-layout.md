---
title: "Ink TUI: Building Expandable Layouts with Fixed Footer"
date: 2025-11-28
topic: ink-tui-layout
recommendation: ink + custom components
version_researched: "6.5.1"
use_when:
  - Building interactive CLI tools with React patterns
  - Need familiar Flexbox-based layouts in terminal
  - Want component-based, testable CLI architecture
  - Building tools similar to Claude Code, Gatsby CLI, or Prisma
avoid_when:
  - Simple scripts with minimal interactivity
  - Need complex native scrolling (Ink's scrolling is limited)
  - Performance-critical apps with thousands of items (no virtual scrolling built-in)
project_context:
  language: TypeScript
  relevant_dependencies: ["@google/genai", "@tavily/core"]
---

## Summary

Ink (v6.5.1) is the definitive React-based library for building terminal UIs in Node.js[1]. It uses Yoga (Facebook's Flexbox engine) to provide CSS-like layout capabilities in the terminal. Ink has 28k+ GitHub stars, is actively maintained (last release 7 days ago), and is used by major tools including GitHub Copilot CLI, Gatsby, Prisma, and Shopify[2].

For your specific use case—viewing diffs with expandable/collapsible tool calls and a fixed chat window with stats at the bottom—Ink provides the foundation but requires custom components for expand/collapse behavior. The companion library `@inkjs/ui` provides pre-built components but lacks accordion/collapsible components, so you'll build these yourself using Ink's state management[3].

The key architectural pattern for your layout: use a fullscreen wrapper with alternate screen buffer, a flex column layout with `flexGrow={1}` for the scrollable content area, and a fixed-height footer for stats.

## Philosophy & Mental Model

Ink treats the terminal as a React render target. Every component is a Flexbox container by default (like having `display: flex` on every div). Key concepts:

1. **Box**: The `<div>` equivalent—a Flexbox container for layout
2. **Text**: Required wrapper for all text content (cannot put raw text in Box)
3. **Static**: Renders content that persists above dynamic content—useful for logs that don't change
4. **useInput**: Hook to capture keyboard input (arrow keys, enter, etc.)
5. **useFocus**: Hook for managing focus between interactive elements
6. **useStdout**: Hook to access terminal dimensions for responsive layouts[4]

Mental model: Think of your CLI as a single-page React app where the terminal is your viewport. You re-render the entire visible state on each update, but Ink efficiently diffs and only redraws what changed.

## Setup

```bash
pnpm add ink ink-spinner react
pnpm add -D @types/react
```

For TypeScript, ensure your `tsconfig.json` has:

```json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "esModuleInterop": true
  }
}
```

## Core Usage Patterns

### Pattern 1: Fullscreen Layout with Fixed Footer

This is the foundation for your TUI—fullscreen with a fixed stats bar at the bottom:

```tsx
import React, { useEffect } from 'react';
import { render, Box, Text, useStdout } from 'ink';

// Alternate screen buffer for fullscreen apps (like vim/htop)
const enterAltScreen = '\x1b[?1049h';
const leaveAltScreen = '\x1b[?1049l';

function FullScreen({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    process.stdout.write(enterAltScreen);
    return () => {
      process.stdout.write(leaveAltScreen);
    };
  }, []);
  return <>{children}</>;
}

function App() {
  const { stdout } = useStdout();
  const height = stdout?.rows ?? 24;

  return (
    <FullScreen>
      <Box flexDirection="column" height={height}>
        {/* Main scrollable content area */}
        <Box flexDirection="column" flexGrow={1} overflow="hidden">
          <Text>Your content here...</Text>
        </Box>

        {/* Fixed footer - stats bar */}
        <Box
          borderStyle="single"
          borderColor="gray"
          paddingX={1}
        >
          <Text color="cyan">Tokens: 1,234</Text>
          <Text> | </Text>
          <Text color="green">Cost: $0.02</Text>
        </Box>
      </Box>
    </FullScreen>
  );
}

render(<App />);
```

### Pattern 2: Expandable/Collapsible Component

Build a custom collapsible for tool calls and diffs:

```tsx
import React, { useState } from 'react';
import { Box, Text, useInput } from 'ink';

interface CollapsibleProps {
  title: string;
  children: React.ReactNode;
  defaultExpanded?: boolean;
  isFocused?: boolean;
}

function Collapsible({
  title,
  children,
  defaultExpanded = false,
  isFocused = false
}: CollapsibleProps) {
  const [expanded, setExpanded] = useState(defaultExpanded);

  useInput((input, key) => {
    if (isFocused && (key.return || input === ' ')) {
      setExpanded(e => !e);
    }
  }, { isActive: isFocused });

  const icon = expanded ? '▼' : '▶';
  const borderColor = isFocused ? 'cyan' : 'gray';

  return (
    <Box flexDirection="column">
      <Box>
        <Text color={borderColor}>{icon} </Text>
        <Text bold={isFocused}>{title}</Text>
      </Box>
      {expanded && (
        <Box marginLeft={2} flexDirection="column">
          {children}
        </Box>
      )}
    </Box>
  );
}
```

### Pattern 3: Tool Call Display with Diff

Show tool calls with expandable results:

```tsx
import React from 'react';
import { Box, Text } from 'ink';

interface ToolCallProps {
  name: string;
  args: Record<string, unknown>;
  result?: string;
  expanded: boolean;
}

function ToolCall({ name, args, result, expanded }: ToolCallProps) {
  return (
    <Box flexDirection="column" borderStyle="round" borderColor="yellow" marginY={1}>
      <Box paddingX={1}>
        <Text color="yellow" bold>{name}</Text>
        <Text dimColor> ({Object.keys(args).join(', ')})</Text>
      </Box>

      {expanded && (
        <Box flexDirection="column" paddingX={1}>
          {/* Arguments */}
          <Box marginTop={1}>
            <Text dimColor>Args: </Text>
            <Text>{JSON.stringify(args, null, 2)}</Text>
          </Box>

          {/* Result/Diff */}
          {result && (
            <Box marginTop={1} flexDirection="column">
              <Text dimColor>Result:</Text>
              <Box borderStyle="single" borderColor="green" marginTop={1}>
                <Text>{result}</Text>
              </Box>
            </Box>
          )}
        </Box>
      )}
    </Box>
  );
}
```

### Pattern 4: Scrollable List with Keyboard Navigation

Since Ink's native scrolling is limited, implement virtual scrolling manually:

```tsx
import React, { useState } from 'react';
import { Box, Text, useInput, useStdout } from 'ink';

interface ScrollableListProps<T> {
  items: T[];
  renderItem: (item: T, index: number, isSelected: boolean) => React.ReactNode;
  maxVisible?: number;
}

function ScrollableList<T>({
  items,
  renderItem,
  maxVisible
}: ScrollableListProps<T>) {
  const { stdout } = useStdout();
  const visibleCount = maxVisible ?? Math.min(10, (stdout?.rows ?? 20) - 5);

  const [selectedIndex, setSelectedIndex] = useState(0);
  const [scrollOffset, setScrollOffset] = useState(0);

  useInput((_, key) => {
    if (key.upArrow) {
      setSelectedIndex(i => {
        const newIndex = Math.max(0, i - 1);
        if (newIndex < scrollOffset) {
          setScrollOffset(newIndex);
        }
        return newIndex;
      });
    }
    if (key.downArrow) {
      setSelectedIndex(i => {
        const newIndex = Math.min(items.length - 1, i + 1);
        if (newIndex >= scrollOffset + visibleCount) {
          setScrollOffset(newIndex - visibleCount + 1);
        }
        return newIndex;
      });
    }
  });

  const visibleItems = items.slice(scrollOffset, scrollOffset + visibleCount);
  const showScrollUp = scrollOffset > 0;
  const showScrollDown = scrollOffset + visibleCount < items.length;

  return (
    <Box flexDirection="column">
      {showScrollUp && <Text dimColor>  ↑ {scrollOffset} more above</Text>}
      {visibleItems.map((item, i) => (
        <Box key={scrollOffset + i}>
          {renderItem(item, scrollOffset + i, scrollOffset + i === selectedIndex)}
        </Box>
      ))}
      {showScrollDown && (
        <Text dimColor>  ↓ {items.length - scrollOffset - visibleCount} more below</Text>
      )}
    </Box>
  );
}
```

### Pattern 5: Complete TUI Layout for Your Use Case

Putting it all together:

```tsx
import React, { useState, useEffect } from 'react';
import { render, Box, Text, useInput, useStdout } from 'ink';

// Types
interface Message {
  role: 'user' | 'assistant';
  content: string;
  toolCalls?: ToolCallData[];
}

interface ToolCallData {
  id: string;
  name: string;
  args: Record<string, unknown>;
  result?: string;
}

interface Stats {
  inputTokens: number;
  outputTokens: number;
  cost: number;
}

// Fullscreen wrapper
function FullScreen({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    process.stdout.write('\x1b[?1049h');
    return () => process.stdout.write('\x1b[?1049l');
  }, []);
  return <>{children}</>;
}

// Main App
function ChatTUI() {
  const { stdout } = useStdout();
  const height = stdout?.rows ?? 24;

  const [messages, setMessages] = useState<Message[]>([]);
  const [expandedTools, setExpandedTools] = useState<Set<string>>(new Set());
  const [focusedIndex, setFocusedIndex] = useState(0);
  const [stats, setStats] = useState<Stats>({ inputTokens: 0, outputTokens: 0, cost: 0 });

  // Get all tool calls for navigation
  const allToolCalls = messages.flatMap(m => m.toolCalls ?? []);

  useInput((input, key) => {
    if (key.upArrow) {
      setFocusedIndex(i => Math.max(0, i - 1));
    }
    if (key.downArrow) {
      setFocusedIndex(i => Math.min(allToolCalls.length - 1, i + 1));
    }
    if (key.return && allToolCalls[focusedIndex]) {
      const id = allToolCalls[focusedIndex].id;
      setExpandedTools(prev => {
        const next = new Set(prev);
        if (next.has(id)) next.delete(id);
        else next.add(id);
        return next;
      });
    }
    if (input === 'q') {
      process.exit(0);
    }
  });

  return (
    <FullScreen>
      <Box flexDirection="column" height={height}>
        {/* Header */}
        <Box borderStyle="single" borderColor="blue" paddingX={1}>
          <Text bold color="blue">Agent Chat</Text>
          <Text> - Press ↑↓ to navigate, Enter to expand/collapse, q to quit</Text>
        </Box>

        {/* Main content area */}
        <Box flexDirection="column" flexGrow={1} overflow="hidden" paddingX={1}>
          {messages.map((msg, msgIdx) => (
            <Box key={msgIdx} flexDirection="column" marginY={1}>
              <Text color={msg.role === 'user' ? 'green' : 'cyan'} bold>
                {msg.role === 'user' ? 'You' : 'Assistant'}:
              </Text>
              <Text wrap="wrap">{msg.content}</Text>

              {msg.toolCalls?.map((tc, tcIdx) => {
                const globalIdx = messages
                  .slice(0, msgIdx)
                  .reduce((acc, m) => acc + (m.toolCalls?.length ?? 0), 0) + tcIdx;
                const isExpanded = expandedTools.has(tc.id);
                const isFocused = globalIdx === focusedIndex;

                return (
                  <Box
                    key={tc.id}
                    flexDirection="column"
                    borderStyle={isFocused ? 'double' : 'single'}
                    borderColor={isFocused ? 'cyan' : 'yellow'}
                    marginY={1}
                  >
                    <Box paddingX={1}>
                      <Text>{isExpanded ? '▼' : '▶'} </Text>
                      <Text color="yellow" bold>{tc.name}</Text>
                    </Box>
                    {isExpanded && (
                      <Box paddingX={2} flexDirection="column">
                        <Text dimColor>Args: {JSON.stringify(tc.args)}</Text>
                        {tc.result && (
                          <Box marginTop={1}>
                            <Text>{tc.result}</Text>
                          </Box>
                        )}
                      </Box>
                    )}
                  </Box>
                );
              })}
            </Box>
          ))}
        </Box>

        {/* Fixed footer with stats */}
        <Box
          borderStyle="single"
          borderColor="gray"
          paddingX={1}
          justifyContent="space-between"
        >
          <Text>
            <Text color="cyan">Input: {stats.inputTokens.toLocaleString()}</Text>
            <Text> | </Text>
            <Text color="magenta">Output: {stats.outputTokens.toLocaleString()}</Text>
          </Text>
          <Text color="green" bold>${stats.cost.toFixed(4)}</Text>
        </Box>
      </Box>
    </FullScreen>
  );
}

render(<ChatTUI />);
```

## Anti-Patterns & Pitfalls

### Don't: Put raw text in Box

```tsx
// BAD - will throw error
<Box>Hello world</Box>
```

**Why it's wrong:** Ink requires all text to be wrapped in `<Text>` components.

### Instead: Always wrap text

```tsx
// GOOD
<Box><Text>Hello world</Text></Box>
```

---

### Don't: Nest Box inside Text

```tsx
// BAD - will throw error
<Text>
  Hello <Box><Text>world</Text></Box>
</Text>
```

**Why it's wrong:** Text components can only contain text nodes and other Text components, not layout components.

### Instead: Keep layout and text separate

```tsx
// GOOD
<Box>
  <Text>Hello </Text>
  <Text bold>world</Text>
</Box>
```

---

### Don't: Expect native scrolling to work automatically

```tsx
// BAD - content just gets cut off
<Box height={10} overflow="hidden">
  {/* 100 items here... */}
</Box>
```

**Why it's wrong:** Ink's `overflow="hidden"` only clips content—it doesn't provide scrolling. You must implement virtual scrolling manually[5].

### Instead: Implement virtual scrolling

```tsx
// GOOD - slice items based on scroll position
const visibleItems = items.slice(scrollOffset, scrollOffset + visibleCount);
```

---

### Don't: Use percentage dimensions without parent constraints

```tsx
// BAD - percentage of what?
<Box width="50%">
  <Text>Content</Text>
</Box>
```

**Why it's wrong:** Percentages need a parent with explicit dimensions to calculate against.

### Instead: Set explicit dimensions on parent or use flexGrow

```tsx
// GOOD
<Box height={process.stdout.rows} flexDirection="row">
  <Box width="50%"><Text>Left</Text></Box>
  <Box width="50%"><Text>Right</Text></Box>
</Box>
```

---

### Don't: Forget cleanup for alternate screen buffer

```tsx
// BAD - terminal left in broken state on crash
useEffect(() => {
  process.stdout.write('\x1b[?1049h');
}, []);
```

**Why it's wrong:** If the app crashes, the terminal stays in alternate buffer mode.

### Instead: Always return cleanup function

```tsx
// GOOD
useEffect(() => {
  process.stdout.write('\x1b[?1049h');
  return () => process.stdout.write('\x1b[?1049l');
}, []);
```

## Caveats

- **No built-in virtual scrolling:** For large lists (hundreds of items), you must implement windowing yourself. Consider using a virtualized approach that only renders visible items[5].

- **Overflow clips but doesn't scroll:** `overflow="hidden"` hides content but doesn't provide scrolling—you need manual scroll state management[6].

- **Terminal dimensions:** Use `useStdout()` to get terminal size and listen for resize, but be aware that `stdout.rows` can be `undefined` in non-TTY environments.

- **Static component is for logs, not headers:** `<Static>` renders content that persists above dynamic content but is designed for completed/immutable content (like test results), not for fixed headers[1].

- **No diff rendering built-in:** For syntax-highlighted diffs, you'll need a library like `diff` for computing diffs and custom rendering logic with colored Text components.

- **React 18+ required:** Ink 4+ requires React 18 with the new root API.

## References

[1] [Ink GitHub Repository](https://github.com/vadimdemedes/ink) - Official docs, component API, and examples

[2] [LogRocket: Using Ink UI with React](https://blog.logrocket.com/using-ink-ui-react-build-interactive-custom-clis/) - Tutorial on Ink UI components and who uses Ink

[3] [Ink UI GitHub](https://github.com/vadimdemedes/ink-ui) - Companion component library (Select, Spinner, etc.)

[4] [Ink fullscreen discussion #263](https://github.com/vadimdemedes/ink/issues/263) - Alternate screen buffer pattern for fullscreen apps

[5] [Ink scrolling issue #222](https://github.com/vadimdemedes/ink/issues/222) - Discussion of scrolling limitations and workarounds

[6] [Ink overflow/scrolling issue #432](https://github.com/vadimdemedes/ink/issues/432) - Technical details on overflow behavior

[7] [DEV.to: Building Reactive CLIs with Ink](https://dev.to/skirianov/building-reactive-clis-with-ink-react-cli-library-4jpa) - Tutorial with file explorer example

[8] [developerlife.com Ink Reference](https://developerlife.com/2021/11/25/ink-v3-advanced-ui-components/) - Advanced component patterns
