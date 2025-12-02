---
title: "Chrome Automation: Chrome DevTools Protocol (CDP) Direct"
date: 2025-11-28
topic: chrome-cdp-direct
recommendation: Chrome DevTools Protocol via WebSocket
version_researched: CDP tot (tip-of-tree)
use_when:
  - You want minimal dependencies and full control
  - Building lightweight automation scripts
  - Need bash/shell-based browser control
  - Learning how browser automation actually works
  - Your use case is Chrome/Chromium only
avoid_when:
  - You need cross-browser support (Firefox, Safari)
  - Building complex test suites with assertions
  - Need auto-waiting and retry logic built-in
  - Want higher-level abstractions for productivity
project_context:
  language: TypeScript/Node.js (ES modules)
  relevant_dependencies: []
---

## Summary

The Chrome DevTools Protocol (CDP) is the low-level protocol that powers Chrome DevTools and serves as the foundation for libraries like Puppeteer and Playwright[1]. It communicates over WebSocket, allowing direct control of Chromium-based browsers through JSON-RPC messages[2]. While higher-level libraries provide convenience, using CDP directly gives you complete control with zero abstraction overhead.

For your use case (general automation, single browser, Chrome-only), CDP direct is a viable choice. It's particularly interesting because it can be driven from **bash scripts** using tools like `websocat`[3], making it accessible without any Node.js dependencies. The protocol is well-documented and stable for common operations like navigation, screenshots, and PDF generation[4].

Key metrics: CDP is the official protocol maintained by the Chrome DevTools team at Google. It's used internally by Puppeteer (90.3k GitHub stars, 6M+ weekly npm downloads) and Playwright (77k+ GitHub stars, 22M+ weekly npm downloads)[5][6].

## Philosophy & Mental Model

CDP operates on a **domains and commands** model[1]:

- **Domains**: Logical groupings of functionality (Page, DOM, Runtime, Network, etc.)
- **Commands**: Methods you call that return results (synchronous request/response)
- **Events**: Notifications pushed from the browser (asynchronous)

The mental model is simple: you're sending JSON messages over a WebSocket and receiving JSON responses. Every command has:
- `id`: A unique integer you choose (responses echo this back)
- `method`: The domain and command (e.g., `Page.navigate`)
- `params`: Optional parameters object

```
Browser <--WebSocket--> Your Script
         JSON-RPC messages
```

Key abstractions:
1. **Browser**: The top-level Chrome process, has its own WebSocket endpoint
2. **Targets**: Things you can debug (pages, workers, service workers)
3. **Sessions**: Connections to specific targets (each page gets a session)

## Setup

### Option 1: Bash with websocat (Zero Dependencies)

Install websocat (WebSocket client for command line):

```bash
# macOS
brew install websocat

# Linux (download binary)
wget https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl
chmod +x websocat.x86_64-unknown-linux-musl
sudo mv websocat.x86_64-unknown-linux-musl /usr/local/bin/websocat

# Or with cargo
cargo install websocat
```

You also need `jq` for JSON parsing:

```bash
# macOS
brew install jq

# Linux
apt install jq
```

### Option 2: Node.js/TypeScript

No special libraries needed—just the built-in `ws` package:

```bash
pnpm add ws
pnpm add -D @types/ws
```

### Launch Chrome with Remote Debugging

```bash
# macOS
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-debug

# Linux
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug

# Headless mode
google-chrome --headless --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug

# New headless (Chrome 112+) - recommended
google-chrome --headless=new --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
```

## Core Usage Patterns

### Pattern 1: Bash - Get WebSocket URL and Navigate

```bash
#!/bin/bash
set -e

# Start Chrome headless (background)
google-chrome --headless=new --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-cdp &
CHROME_PID=$!
sleep 2  # Wait for Chrome to start

# Get the WebSocket URL for a new page
PAGE_INFO=$(curl -s http://127.0.0.1:9222/json/new)
WS_URL=$(echo "$PAGE_INFO" | jq -r '.webSocketDebuggerUrl')
echo "WebSocket URL: $WS_URL"

# Navigate to a page
echo '{"id":1,"method":"Page.navigate","params":{"url":"https://example.com"}}' | \
  websocat -n1 "$WS_URL"

# Wait for page to load
sleep 2

# Clean up
kill $CHROME_PID
```

### Pattern 2: Bash - Take a Screenshot

```bash
#!/bin/bash
set -e

WS_URL="$1"  # Pass WebSocket URL as argument

# Capture screenshot (returns base64)
RESPONSE=$(echo '{"id":1,"method":"Page.captureScreenshot","params":{"format":"png"}}' | \
  websocat -n1 "$WS_URL")

# Extract base64 data and decode to file
echo "$RESPONSE" | jq -r '.result.data' | base64 -d > screenshot.png

echo "Screenshot saved to screenshot.png"
```

### Pattern 3: Bash - Get Page HTML

```bash
#!/bin/bash
set -e

WS_URL="$1"

# Get the document root node
DOC_RESPONSE=$(echo '{"id":1,"method":"DOM.getDocument","params":{"depth":-1}}' | \
  websocat -n1 "$WS_URL")

ROOT_NODE_ID=$(echo "$DOC_RESPONSE" | jq -r '.result.root.nodeId')

# Get outer HTML of the entire document
HTML_RESPONSE=$(echo "{\"id\":2,\"method\":\"DOM.getOuterHTML\",\"params\":{\"nodeId\":$ROOT_NODE_ID}}" | \
  websocat -n1 "$WS_URL")

echo "$HTML_RESPONSE" | jq -r '.result.outerHTML'
```

### Pattern 4: Bash - Run JavaScript (evaluate)

```bash
#!/bin/bash
set -e

WS_URL="$1"
JS_EXPRESSION="$2"

# Enable Runtime domain first (required for evaluate)
echo '{"id":1,"method":"Runtime.enable"}' | websocat -n1 "$WS_URL" > /dev/null

# Run JavaScript expression
RESPONSE=$(echo "{\"id\":2,\"method\":\"Runtime.evaluate\",\"params\":{\"expression\":\"$JS_EXPRESSION\",\"returnByValue\":true}}" | \
  websocat -n1 "$WS_URL")

echo "$RESPONSE" | jq '.result.result.value'
```

Usage:
```bash
./evaluate.sh "$WS_URL" "document.title"
./evaluate.sh "$WS_URL" "document.querySelectorAll('a').length"
./evaluate.sh "$WS_URL" "Array.from(document.querySelectorAll('h1')).map(h => h.textContent)"
```

### Pattern 5: Bash - Generate PDF

```bash
#!/bin/bash
set -e

WS_URL="$1"
OUTPUT="${2:-output.pdf}"

# Generate PDF (returns base64)
RESPONSE=$(echo '{"id":1,"method":"Page.printToPDF","params":{"printBackground":true,"format":"A4"}}' | \
  websocat -n1 "$WS_URL")

# Decode and save
echo "$RESPONSE" | jq -r '.result.data' | base64 -d > "$OUTPUT"

echo "PDF saved to $OUTPUT"
```

### Pattern 6: Bash - Query Selectors

```bash
#!/bin/bash
set -e

WS_URL="$1"
SELECTOR="$2"

# Get document first
DOC=$(echo '{"id":1,"method":"DOM.getDocument"}' | websocat -n1 "$WS_URL")
ROOT_ID=$(echo "$DOC" | jq -r '.result.root.nodeId')

# Query selector
QUERY=$(echo "{\"id\":2,\"method\":\"DOM.querySelector\",\"params\":{\"nodeId\":$ROOT_ID,\"selector\":\"$SELECTOR\"}}" | \
  websocat -n1 "$WS_URL")

NODE_ID=$(echo "$QUERY" | jq -r '.result.nodeId')

if [ "$NODE_ID" = "0" ] || [ "$NODE_ID" = "null" ]; then
  echo "Element not found"
  exit 1
fi

# Get the HTML of the matched element
HTML=$(echo "{\"id\":3,\"method\":\"DOM.getOuterHTML\",\"params\":{\"nodeId\":$NODE_ID}}" | \
  websocat -n1 "$WS_URL")

echo "$HTML" | jq -r '.result.outerHTML'
```

### Pattern 7: TypeScript - Full Example

```typescript
import WebSocket from 'ws';

interface CDPResponse {
  id: number;
  result?: Record<string, unknown>;
  error?: { code: number; message: string };
}

class CDPClient {
  private ws: WebSocket;
  private messageId = 0;
  private pending = new Map<number, {
    resolve: (value: CDPResponse) => void;
    reject: (error: Error) => void;
  }>();

  private constructor(ws: WebSocket) {
    this.ws = ws;
    this.ws.on('message', (data) => {
      const msg = JSON.parse(data.toString()) as CDPResponse;
      if (msg.id !== undefined) {
        const handler = this.pending.get(msg.id);
        if (handler) {
          this.pending.delete(msg.id);
          if (msg.error) {
            handler.reject(new Error(msg.error.message));
          } else {
            handler.resolve(msg);
          }
        }
      }
    });
  }

  static async connect(wsUrl: string): Promise<CDPClient> {
    const ws = new WebSocket(wsUrl);
    await new Promise<void>((resolve, reject) => {
      ws.once('open', resolve);
      ws.once('error', reject);
    });
    return new CDPClient(ws);
  }

  async send(method: string, params: Record<string, unknown> = {}): Promise<CDPResponse> {
    const id = ++this.messageId;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    this.ws.close();
  }
}

// Usage
async function main() {
  // Get WebSocket URL from Chrome's JSON endpoint
  const response = await fetch('http://127.0.0.1:9222/json/new');
  const { webSocketDebuggerUrl } = await response.json();

  const client = await CDPClient.connect(webSocketDebuggerUrl);

  // Navigate
  await client.send('Page.navigate', { url: 'https://example.com' });
  await new Promise(r => setTimeout(r, 2000)); // Wait for load

  // Take screenshot
  const screenshot = await client.send('Page.captureScreenshot', { format: 'png' });
  const imageData = Buffer.from(screenshot.result!.data as string, 'base64');
  await Bun.write('screenshot.png', imageData); // or fs.writeFileSync

  // Get HTML via evaluate (simpler than DOM methods)
  const html = await client.send('Runtime.evaluate', {
    expression: 'document.documentElement.outerHTML',
    returnByValue: true
  });
  console.log('HTML length:', (html.result!.result as any).value.length);

  // Run any JavaScript
  const title = await client.send('Runtime.evaluate', {
    expression: 'document.title',
    returnByValue: true
  });
  console.log('Title:', (title.result!.result as any).value);

  // Generate PDF
  const pdf = await client.send('Page.printToPDF', {
    printBackground: true,
    format: 'A4'
  });
  const pdfData = Buffer.from(pdf.result!.data as string, 'base64');
  await Bun.write('page.pdf', pdfData);

  client.close();
}

main().catch(console.error);
```

### Pattern 8: Complete Bash Automation Script

```bash
#!/bin/bash
# chrome-automate.sh - Complete browser automation in bash
set -e

CHROME_PORT=9222
CHROME_PID=""
WS_URL=""

# Start Chrome
start_chrome() {
  local headless="${1:-true}"
  local url="${2:-about:blank}"

  local headless_flag=""
  if [ "$headless" = "true" ]; then
    headless_flag="--headless=new"
  fi

  google-chrome $headless_flag \
    --remote-debugging-port=$CHROME_PORT \
    --user-data-dir=/tmp/chrome-cdp-$$ \
    --no-first-run \
    --no-default-browser-check \
    "$url" &
  CHROME_PID=$!

  # Wait for CDP to be ready
  for i in {1..30}; do
    if curl -s "http://127.0.0.1:$CHROME_PORT/json/version" > /dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
}

# Get WebSocket URL for first page
get_page_ws() {
  curl -s "http://127.0.0.1:$CHROME_PORT/json/list" | jq -r '.[0].webSocketDebuggerUrl'
}

# Create new page and get its WebSocket URL
new_page() {
  curl -s "http://127.0.0.1:$CHROME_PORT/json/new" | jq -r '.webSocketDebuggerUrl'
}

# Send CDP command
cdp() {
  local ws_url="$1"
  local method="$2"
  local params="${3:-{}}"

  local id=$RANDOM
  echo "{\"id\":$id,\"method\":\"$method\",\"params\":$params}" | websocat -n1 "$ws_url"
}

# Navigate to URL
navigate() {
  local ws_url="$1"
  local url="$2"
  cdp "$ws_url" "Page.navigate" "{\"url\":\"$url\"}"
}

# Wait for page load (simple version)
wait_load() {
  sleep "${1:-2}"
}

# Take screenshot
screenshot() {
  local ws_url="$1"
  local output="${2:-screenshot.png}"
  local format="${output##*.}"

  cdp "$ws_url" "Page.captureScreenshot" "{\"format\":\"$format\"}" | \
    jq -r '.result.data' | base64 -d > "$output"
}

# Generate PDF
pdf() {
  local ws_url="$1"
  local output="${2:-page.pdf}"

  cdp "$ws_url" "Page.printToPDF" '{"printBackground":true}' | \
    jq -r '.result.data' | base64 -d > "$output"
}

# Get page HTML
get_html() {
  local ws_url="$1"
  cdp "$ws_url" "Runtime.evaluate" '{"expression":"document.documentElement.outerHTML","returnByValue":true}' | \
    jq -r '.result.result.value'
}

# Run JavaScript
evaluate() {
  local ws_url="$1"
  local expression="$2"
  cdp "$ws_url" "Runtime.evaluate" "{\"expression\":$(echo "$expression" | jq -Rs .),\"returnByValue\":true}" | \
    jq -r '.result.result.value'
}

# Query selector and get text
query_text() {
  local ws_url="$1"
  local selector="$2"
  evaluate "$ws_url" "document.querySelector('$selector')?.textContent"
}

# Close browser
close_chrome() {
  if [ -n "$CHROME_PID" ]; then
    kill "$CHROME_PID" 2>/dev/null || true
  fi
}

# Cleanup on exit
trap close_chrome EXIT

# ============ EXAMPLE USAGE ============
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "Starting Chrome..."
  start_chrome true

  WS_URL=$(get_page_ws)
  echo "WebSocket: $WS_URL"

  echo "Navigating to example.com..."
  navigate "$WS_URL" "https://example.com"
  wait_load 2

  echo "Page title: $(evaluate "$WS_URL" 'document.title')"

  echo "Taking screenshot..."
  screenshot "$WS_URL" "example.png"

  echo "Generating PDF..."
  pdf "$WS_URL" "example.pdf"

  echo "Getting HTML..."
  get_html "$WS_URL" > example.html

  echo "Done! Created: example.png, example.pdf, example.html"
fi
```

## Anti-Patterns & Pitfalls

### Don't: Forget to Wait for Navigation

```bash
# BAD - screenshot might capture blank page
navigate "$WS_URL" "https://example.com"
screenshot "$WS_URL" "bad.png"
```

**Why it's wrong:** `Page.navigate` returns immediately when navigation starts, not when the page is loaded.

### Instead: Wait for Load Event or Use Timeout

```bash
# GOOD - wait for page to load
navigate "$WS_URL" "https://example.com"
sleep 2  # Simple but effective
screenshot "$WS_URL" "good.png"

# BETTER - wait for specific condition via evaluate
while [ "$(evaluate "$WS_URL" 'document.readyState')" != "complete" ]; do
  sleep 0.1
done
```

### Don't: Use DOM Methods for Simple HTML Extraction

```bash
# BAD - complex chain of commands
cdp "$WS_URL" "DOM.getDocument" '{"depth":-1}'
# Then extract nodeId, then getOuterHTML...
```

**Why it's wrong:** DOM methods require multiple round trips and node ID management.

### Instead: Use Runtime.evaluate

```bash
# GOOD - single command
evaluate "$WS_URL" "document.documentElement.outerHTML"
evaluate "$WS_URL" "document.querySelector('h1').textContent"
```

### Don't: Hardcode Message IDs in Production

```bash
# BAD - will break with concurrent requests
echo '{"id":1,"method":"Page.navigate"...}'
echo '{"id":1,"method":"Page.captureScreenshot"...}'  # Same ID!
```

**Why it's wrong:** If you send concurrent requests with the same ID, you can't match responses.

### Instead: Generate Unique IDs

```bash
# GOOD
cdp() {
  local id=$RANDOM  # Or use incrementing counter
  echo "{\"id\":$id,\"method\":\"$method\"...}"
}
```

### Don't: Forget Error Handling

```bash
# BAD - ignores errors
RESPONSE=$(cdp "$WS_URL" "Page.navigate" '{"url":"invalid"}')
echo "Success!"
```

### Instead: Check for Errors

```bash
# GOOD
RESPONSE=$(cdp "$WS_URL" "Page.navigate" '{"url":"https://example.com"}')
ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
if [ -n "$ERROR" ]; then
  echo "Error: $ERROR" >&2
  exit 1
fi
```

### Don't: Leave Chrome Processes Running

```bash
# BAD - orphaned Chrome process
start_chrome
navigate "$WS_URL" "https://example.com"
# Script ends without cleanup
```

### Instead: Use Trap for Cleanup

```bash
# GOOD
trap close_chrome EXIT
start_chrome
# ... do work ...
# Chrome is automatically killed on exit
```

## Caveats

- **No Auto-Wait**: Unlike Puppeteer/Playwright, CDP doesn't wait for elements. You must implement waiting logic yourself (polling `Runtime.evaluate` or listening for events).

- **Protocol Stability**: The "tot" (tip-of-tree) protocol can change. For stability, reference a specific Chrome version's protocol or stick to well-established commands like `Page.navigate`, `Page.captureScreenshot`, and `Runtime.evaluate`[4].

- **Headless Mode**: Chrome's new headless mode (`--headless=new`, Chrome 112+) behaves identically to headed Chrome. The old headless (`--headless` or `--headless=old`) is a separate implementation with some differences[7].

- **Session Management**: For complex scenarios with multiple tabs, you need to manage sessions explicitly. Each `Target.attachToTarget` creates a session with its own message ID namespace[2].

- **Event Handling in Bash**: The bash approach works well for sequential scripts but handling async events (like network requests) is awkward. For event-driven automation, use Node.js/TypeScript.

- **PDF Generation**: `Page.printToPDF` only works in headless mode. In headed mode, it will fail[4].

- **Base64 Size**: Screenshots and PDFs are returned as base64, which is ~33% larger than binary. For large pages, responses can be several MB of JSON.

## References

[1] [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/) - Official protocol documentation

[2] [Getting Started With Chrome DevTools Protocol](https://github.com/aslushnikov/getting-started-with-cdp) - Excellent tutorial by Puppeteer maintainer

[3] [Chrome DevTools Remote Control Using Linux Bash](https://bijan.binaee.com/2022/05/chrome-devtools-remote-control-using-linux-bash/) - Bash + websocat examples

[4] [CDP Page Domain](https://chromedevtools.github.io/devtools-protocol/tot/Page/) - Navigate, screenshot, PDF commands

[5] [Puppeteer npm](https://www.npmjs.com/package/puppeteer) - npm package stats

[6] [Playwright npm trends](https://npmtrends.com/playwright) - npm download stats

[7] [Chrome Headless Mode](https://developer.chrome.com/docs/chromium/headless) - Official headless documentation

[8] [websocat GitHub](https://github.com/vi/websocat) - WebSocket CLI tool

[9] [CDP Runtime Domain](https://chromedevtools.github.io/devtools-protocol/tot/Runtime/) - JavaScript evaluation

[10] [CDP DOM Domain](https://chromedevtools.github.io/devtools-protocol/tot/DOM/) - DOM manipulation commands
