---
title: "Web Search for LLMs: Tavily Search API"
date: 2025-11-28
topic: web-search-llm
recommendation: "@tavily/core"
version_researched: "@tavily/core latest (2025)"
use_when:
  - Building AI agents that need to search for code examples, API docs, or technical content
  - Need LLM-ready search results without building a scraping pipeline
  - Want a single API call that searches AND extracts relevant content
  - Free tier (1,000 credits/month) is sufficient for development and light usage
avoid_when:
  - Need raw Google SERP data for SEO analysis or competitive research
  - Require access to Google Images, Maps, Shopping, or Scholar verticals
  - High-volume production use exceeds budget (consider Serper at $0.001/search)
  - Need fine-grained control over which Google features to scrape
project_context:
  language: TypeScript
  relevant_dependencies: ["@google/genai", "tsx", "vitest"]
---

## Summary

For adding web search to your LLM agent, use **Tavily** (`@tavily/core`)[1]. Unlike traditional SERP APIs (Serper, SerpAPI) that just return search result metadata, Tavily searches AND extracts content from pages in a single call, returning text optimized for LLM context windows[2].

**Key metrics**: Tavily is used by LangChain as their default search integration[3]. The free tier provides 1,000 API credits/month—enough for ~500-1000 searches depending on settings[4]. For comparison, Serper offers 2,500 free Google searches but returns only titles/snippets, requiring you to build separate content extraction[5].

**Why Tavily wins for your use case**: You need code/API lookup with minimal configuration. Tavily's `include_answer` parameter can even return an LLM-generated summary of results[1]. One API call does what would require 3-4 calls with Serper (search → get URLs → fetch pages → extract content).

## Philosophy & Mental Model

Tavily is designed as "the web access layer for AI agents"[2]. The mental model:

1. **Search + Extract = One Call**: Traditional flow requires: SERP API → URLs → HTTP fetch → HTML parse → clean text. Tavily does all of this internally and returns clean, relevant content snippets.

2. **Relevance Scoring**: Results include a `score` field (0-1) indicating relevance. Use this to decide how many results to include in your LLM context.

3. **Depth Control**: `search_depth: "basic"` (1 credit) returns snippets. `search_depth: "advanced"` (2 credits) retrieves more sources and enables chunking[1].

4. **Content Budget**: The `max_results` and `chunks_per_source` parameters let you control how much content you're injecting into your prompt. More isn't always better—aim for focused, relevant context.

**Key abstractions**:
- `search()` - Main search function returning results with content
- `extract()` - Fetch and parse content from specific URLs (1 credit per 5 URLs)
- `crawl()` - Site-wide crawling with natural language goals (beta)

## Setup

### Step 1: Get API Key

1. Go to [tavily.com](https://www.tavily.com/)
2. Sign up (no credit card required)
3. Copy your API key (starts with `tvly-`)

### Step 2: Install the SDK

```bash
npm install @tavily/core
```

### Step 3: Configure Environment

Add to `mise.toml`:

```toml
[env]
TAVILY_API_KEY = "{{env.TAVILY_API_KEY}}"
```

Or set directly:

```bash
export TAVILY_API_KEY="tvly-your-api-key"
```

### Step 4: Create Client

```typescript
import { tavily } from "@tavily/core";

const tvly = tavily({ apiKey: process.env.TAVILY_API_KEY });
```

## Core Usage Patterns

### Pattern 1: Basic Search for LLM Context

The simplest pattern—search and get content ready for your LLM:

```typescript
import { tavily } from "@tavily/core";

const tvly = tavily({ apiKey: process.env.TAVILY_API_KEY });

async function searchForContext(query: string): Promise<string> {
  const response = await tvly.search(query, {
    searchDepth: "basic",
    maxResults: 5,
  });

  // Format results for LLM context
  return response.results
    .map((r) => `### ${r.title}\nSource: ${r.url}\n\n${r.content}`)
    .join("\n\n---\n\n");
}

// Usage
const context = await searchForContext("TypeScript zod validation examples");
```

### Pattern 2: Search with LLM-Generated Answer

Get Tavily to summarize results for you (uses their LLM internally):

```typescript
async function searchWithAnswer(query: string) {
  const response = await tvly.search(query, {
    includeAnswer: "advanced", // "basic" for shorter, "advanced" for detailed
    maxResults: 5,
  });

  return {
    answer: response.answer, // Direct answer to include in your response
    sources: response.results.map((r) => ({ title: r.title, url: r.url })),
  };
}

// Usage
const { answer, sources } = await searchWithAnswer(
  "How do I set up ESLint with TypeScript in 2025?"
);

console.log("Answer:", answer);
console.log("Sources:", sources);
```

### Pattern 3: Code/Documentation Search with Raw Content

When you need the full page content (e.g., documentation pages):

```typescript
async function searchDocs(query: string) {
  const response = await tvly.search(query, {
    searchDepth: "advanced", // Required for better content extraction
    includeRawContent: "markdown", // Get full page as markdown
    maxResults: 3, // Fewer results since each has more content
    includeDomains: [
      "developer.mozilla.org",
      "nodejs.org",
      "typescriptlang.org",
      "docs.github.com",
    ],
  });

  return response.results.map((r) => ({
    title: r.title,
    url: r.url,
    snippet: r.content,
    fullContent: r.rawContent, // Full markdown content
    relevance: r.score,
  }));
}
```

### Pattern 4: News/Recent Content Search

For finding recent updates, releases, or announcements:

```typescript
async function searchRecentNews(query: string) {
  const response = await tvly.search(query, {
    topic: "news", // Optimized for recent content
    timeRange: "week", // "day", "week", "month", "year"
    maxResults: 5,
  });

  return response.results.map((r) => ({
    title: r.title,
    url: r.url,
    content: r.content,
    publishedDate: r.publishedDate, // Only available with topic: "news"
  }));
}

// Usage
const releases = await searchRecentNews("Node.js release 2025");
```

### Pattern 5: Integration with Gemini Agent

Combine Tavily search with your Gemini agent as a function tool:

```typescript
import { GoogleGenAI, Type } from "@google/genai";
import { tavily } from "@tavily/core";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const tvly = tavily({ apiKey: process.env.TAVILY_API_KEY });

// Define search tool for Gemini
const webSearchTool = {
  name: "web_search",
  description:
    "Search the web for current information, documentation, code examples, or recent news",
  parameters: {
    type: Type.OBJECT,
    properties: {
      query: {
        type: Type.STRING,
        description: "The search query",
      },
      searchType: {
        type: Type.STRING,
        enum: ["general", "news", "docs"],
        description: "Type of search: general, news (recent), or docs (technical)",
      },
    },
    required: ["query"],
  },
};

// Execute search when Gemini calls the tool
async function executeWebSearch(
  query: string,
  searchType: string = "general"
): Promise<string> {
  const options: any = {
    maxResults: 5,
    includeAnswer: "basic",
  };

  if (searchType === "news") {
    options.topic = "news";
    options.timeRange = "week";
  } else if (searchType === "docs") {
    options.searchDepth = "advanced";
    options.includeDomains = [
      "developer.mozilla.org",
      "docs.python.org",
      "typescriptlang.org",
      "nodejs.org",
    ];
  }

  const response = await tvly.search(query, options);

  // Format for LLM consumption
  let result = "";
  if (response.answer) {
    result += `## Summary\n${response.answer}\n\n`;
  }
  result += "## Sources\n";
  result += response.results
    .map((r) => `### ${r.title}\n${r.url}\n\n${r.content}`)
    .join("\n\n");

  return result;
}

// Use in agent loop
async function runAgent() {
  const chat = ai.chats.create({
    model: "gemini-3-pro-preview",
    config: {
      tools: [{ functionDeclarations: [webSearchTool] }],
      systemInstruction: `You are a helpful coding assistant. Use web_search to find current documentation, code examples, or news when needed.`,
    },
  });

  const response = await chat.sendMessage({
    message: "How do I use the new Bun test runner?",
  });

  if (response.functionCalls?.length) {
    const call = response.functionCalls[0];
    const searchResult = await executeWebSearch(
      call.args.query as string,
      call.args.searchType as string
    );

    // Send search results back to Gemini
    const finalResponse = await chat.sendMessage({
      message: [
        {
          functionResponse: {
            name: call.name,
            response: { result: searchResult },
          },
        },
      ],
    });

    console.log(finalResponse.text);
  }
}
```

### Pattern 6: Extract Content from Specific URLs

When you already have URLs and need to extract content:

```typescript
async function extractContent(urls: string[]) {
  // Costs 1 credit per 5 successful URLs
  const response = await tvly.extract(urls);

  return response.results.map((r) => ({
    url: r.url,
    content: r.rawContent,
    success: !r.error,
  }));
}

// Usage: Extract from GitHub README or docs pages
const content = await extractContent([
  "https://github.com/anthropics/anthropic-sdk-python",
  "https://docs.anthropic.com/claude/docs/intro-to-claude",
]);
```

## Anti-Patterns & Pitfalls

### Don't: Use advanced depth for simple queries

```typescript
// Bad - wastes credits on simple lookups
const response = await tvly.search("what is typescript", {
  searchDepth: "advanced", // 2 credits instead of 1
  includeRawContent: true, // Even more processing
  maxResults: 20, // Overkill
});
```

**Why it's wrong:** Basic search is sufficient for most queries. Advanced depth is only worth it when you need deeper content extraction or chunking. You're paying double for marginal benefit.

### Instead: Match depth to need

```typescript
// Good - basic search for simple queries
const simple = await tvly.search("what is typescript", {
  searchDepth: "basic",
  maxResults: 3,
});

// Good - advanced only when you need full content
const detailed = await tvly.search("typescript discriminated unions tutorial", {
  searchDepth: "advanced",
  includeRawContent: "markdown",
  maxResults: 3,
});
```

---

### Don't: Request more results than you'll use

```typescript
// Bad - 20 results but LLM context can only fit 3-5
const response = await tvly.search(query, {
  maxResults: 20,
  includeRawContent: true,
});

// Then only using first 3...
const context = response.results.slice(0, 3);
```

**Why it's wrong:** You're paying for content extraction on results you won't use. More results also slow down the API response.

### Instead: Request what you need

```typescript
// Good - request only what fits your context window
const response = await tvly.search(query, {
  maxResults: 5,
  includeRawContent: true,
});
```

---

### Don't: Ignore the relevance score

```typescript
// Bad - blindly using all results
const context = response.results.map((r) => r.content).join("\n\n");
```

**Why it's wrong:** Low-relevance results add noise to your LLM context and can hurt response quality.

### Instead: Filter by score

```typescript
// Good - only use highly relevant results
const relevantResults = response.results.filter((r) => r.score > 0.5);

const context = relevantResults.map((r) => r.content).join("\n\n");
```

---

### Don't: Hardcode API key

```typescript
// Bad - exposed in source control
const tvly = tavily({ apiKey: "tvly-abc123xyz" });
```

**Why it's wrong:** API keys in code get leaked via git history, logs, or bundle inspection.

### Instead: Use environment variables

```typescript
// Good
const tvly = tavily({ apiKey: process.env.TAVILY_API_KEY });

// Even better - fail fast if missing
const apiKey = process.env.TAVILY_API_KEY;
if (!apiKey) throw new Error("TAVILY_API_KEY environment variable required");
const tvly = tavily({ apiKey });
```

---

### Don't: Use Tavily for raw SERP data

```typescript
// Bad - Tavily abstracts away SERP structure
const response = await tvly.search("best laptops 2025");
// No access to: knowledge graphs, featured snippets, shopping results, image carousels
```

**Why it's wrong:** Tavily is optimized for LLM consumption, not SERP analysis. It doesn't expose Google's rich SERP features.

### Instead: Use Serper for SERP analysis

```typescript
// Good - use Serper when you need raw Google data
const response = await fetch("https://google.serper.dev/search", {
  method: "POST",
  headers: {
    "X-API-KEY": process.env.SERPER_API_KEY,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ q: "best laptops 2025" }),
});

const data = await response.json();
// Access: data.knowledgeGraph, data.peopleAlsoAsk, data.shopping, etc.
```

## Caveats

- **Free tier is generous but limited**: 1,000 credits/month = ~500-1000 searches. Fine for development, but production agents may need a paid plan ($30/month for 4,000 credits)[4].

- **Not a Google replacement**: Tavily uses its own search index plus web crawling. Results may differ from Google. For SEO research or SERP analysis, use Serper ($0.001/search) or SerpAPI instead[5][6].

- **No image/video/shopping verticals**: Tavily focuses on text content. For image search, maps, or shopping results, use Serper's specialized endpoints[5].

- **Rate limits apply**: Free tier has lower rate limits than paid plans. The API returns 429 errors when exceeded[1].

- **Content extraction isn't perfect**: Some sites block crawlers or have complex JavaScript rendering. `rawContent` may be empty or incomplete for dynamic sites.

- **`include_answer` adds latency**: The LLM-generated answer takes extra time. Skip it if you're already using your own LLM to process results.

## Alternative: Serper (When You Need Raw Google Data)

If you need actual Google SERP data (knowledge graphs, featured snippets, People Also Ask), use Serper instead:

```typescript
async function googleSearch(query: string) {
  const response = await fetch("https://google.serper.dev/search", {
    method: "POST",
    headers: {
      "X-API-KEY": process.env.SERPER_API_KEY!,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      q: query,
      num: 10,
    }),
  });

  const data = await response.json();

  return {
    knowledgeGraph: data.knowledgeGraph,
    organic: data.organic, // { title, link, snippet, position }[]
    peopleAlsoAsk: data.peopleAlsoAsk,
    relatedSearches: data.relatedSearches,
  };
}
```

**Serper pricing**: 2,500 free searches, then $50/month for 50,000 searches ($0.001 each)[5].

## References

[1] [Tavily Search API Reference](https://docs.tavily.com/documentation/api-reference/endpoint/search) - Official API documentation with full parameter and response schemas

[2] [Tavily Homepage](https://www.tavily.com/) - "The Web Access Layer for AI Agents"

[3] [Tavily vs Serper API Comparison](https://searchmcp.io/blog/tavily-vs-serper-search-api) - Detailed comparison of output formats and use cases

[4] [Tavily Credits & Pricing](https://docs.tavily.com/documentation/api-credits) - Credit costs and plan tiers

[5] [Serper.dev](https://serper.dev/) - Fast and cheap Google Search API, 2,500 free queries

[6] [The Complete Guide to Web Search APIs for AI Applications in 2025](https://www.firecrawl.dev/blog/top_web_search_api_2025) - Comprehensive comparison of search API options

[7] [Tavily JavaScript SDK Quick Start](https://docs.tavily.com/sdk/javascript/quick-start) - Official SDK setup and examples

[8] [@tavily/core on npm](https://www.npmjs.com/package/@tavily/core) - Official npm package

[9] [7 Free Web Search APIs for AI Agents](https://www.kdnuggets.com/7-free-web-search-apis-for-ai-agents) - Overview of free tier options

[10] [Beyond Tavily - AI Search APIs in 2025](https://websearchapi.ai/blog/tavily-alternatives) - Alternative options and when to use them
