---
name: focus-account-integration
description: Integrate applications with Focus API for authentication, wallet/credits, and job management. Use when implementing Clerk JWT auth, device-code flow for CLI tools, credit reservation and settlement, or job lifecycle (create/complete/fail). Trigger when building apps that connect to account.thefocus.ai or need to manage user credits and jobs.
---

# Focus Account Integration

Connect your application to the Focus API for authentication, credit management, and job tracking.

## When to Use This Skill

Use this skill when:
- Integrating a new app with Focus authentication
- Implementing device-code flow for CLI tools
- Managing user credits and wallet operations
- Creating, completing, or failing jobs with cost tracking
- Setting up shared sign-in via account.thefocus.ai

## Quick Start

### Authentication Methods

Choose based on your use case:

1. **CLI/Automation**: Device-code flow for PAT (Personal Access Token)
2. **Browser Apps**: Redirect to shared sign-in at account.thefocus.ai
3. **Direct Integration**: Use Clerk directly in your app

### Device-Code Flow (CLI)

```bash
# Get a PAT for automation
pnpm --filter @thefocus/focus-cli dev -- login
# Opens browser for confirmation
# PAT stored locally (~90 days validity)

# Verify token
pnpm --filter @thefocus/focus-cli dev -- whoami
```

Use PAT as: `Authorization: Bearer <token>`

### Browser Redirect Flow

```javascript
// Redirect to shared sign-in
const returnUrl = window.location.href;
window.location.href = `https://account.thefocus.ai/signin?redirect_to=${encodeURIComponent(returnUrl)}`;

// On return, get session token
const response = await fetch("https://account.thefocus.ai/api/sessionToken", {
  method: "GET",
  credentials: "include",
});
// Returns 401 with signin_url if unauthenticated
```

### Direct Clerk Integration

```javascript
import { useAuth } from "@clerk/nextjs";

const { getToken } = useAuth();
const token = await getToken();

// Use token for API calls
await fetch("https://account.thefocus.ai/api/wallet", {
  headers: { Authorization: `Bearer ${token}` },
  credentials: "include",
});
```

## Core API Operations

### 1. Check Wallet and Credits

```javascript
// Basic wallet check
const wallet = await fetch("https://account.thefocus.ai/api/wallet", {
  headers: { Authorization: `Bearer ${token}` },
  credentials: "include",
});

// With app grant (receive starter credits once per app)
const wallet = await fetch("https://account.thefocus.ai/api/wallet?app=video", {
  headers: { Authorization: `Bearer ${token}` },
  credentials: "include",
});
```

Response:
```json
{
  "account": {
    "id": "uuid",
    "clerk_id": "string",
    "plan": "free",
    "credits": 123
  },
  "apps": [
    {
      "slug": "video",
      "starter_credits": 20,
      "granted": true,
      "granted_at": "2025-10-28T..."
    }
  ],
  "app_grant": {
    "slug": "video",
    "starter_credits": 20,
    "granted": true
  }
}
```

### 2. Create Job (Reserve Credits)

```javascript
const response = await fetch("https://account.thefocus.ai/api/jobs", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
  credentials: "include",
  body: JSON.stringify({
    app: "video",
    action: "render",
    cost_estimate: 5,
    metadata: {
      description: "Render preview clip",
      previewUrl: "https://video.example.com/previews/abc123.jpg",
    },
  }),
});

const { job_id } = await response.json();
```

**Errors**: 402 (insufficient credits), 401 (auth missing/invalid)

### 3. Complete Job (Settle Cost)

```javascript
await fetch("https://account.thefocus.ai/api/jobs/complete", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
  credentials: "include",
  body: JSON.stringify({
    job_id,
    actual_cost: 3,  // Refunds unused reserve or charges overage
    metadata: {
      description: "Render completed (1080p)",
      previewUrl: "https://video.example.com/final.jpg",
      durationMs: 1200,
    },
  }),
});
```

### 4. Fail Job (Optional Refund)

```javascript
await fetch("https://account.thefocus.ai/api/jobs/fail", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
  credentials: "include",
  body: JSON.stringify({
    job_id,
    refund: true,  // Default: true
  }),
});
```

### 5. List Jobs

```javascript
await fetch("https://account.thefocus.ai/api/jobs?app=video&status=started&limit=50", {
  headers: { Authorization: `Bearer ${token}` },
  credentials: "include",
});
```

## Device-Code Endpoints (Custom Clients)

For building your own CLI tools:

1. **Start flow**: `POST /api/device/start`
   ```json
   {
     "device_code": "...",
     "user_code": "ABCD-1234",
     "verification_uri": "https://account.thefocus.ai/device",
     "expires_in": 900,
     "interval": 5
   }
   ```

2. **Complete (browser)**: `POST /api/device/complete`
   - Requires Clerk session
   - Returns `{ ok: true }`

3. **Poll for token**: `GET /api/device/poll?device_code=...`
   - Returns `202` while pending
   - Returns `{ token }` (PAT) when ready

## OAuth Token Helpers

```javascript
// Get X/Twitter OAuth token
await fetch("https://account.thefocus.ai/api/xToken", {
  headers: { Authorization: `Bearer ${token}` },
});

// Get token for any provider
await fetch("https://account.thefocus.ai/api/oauthToken/{provider}", {
  headers: { Authorization: `Bearer ${token}` },
});

// Proxy to Twitter API
await fetch("https://account.thefocus.ai/api/xMe", {
  headers: { Authorization: `Bearer ${twitter_token}` },
});
```

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 401 | Missing/invalid auth | Redirect to `signin_url` |
| 402 | Insufficient credits | Show credit purchase UI |
| 429 | Rate limited | Retry after delay |

### Session Token Check

```javascript
const response = await fetch("https://account.thefocus.ai/api/sessionToken", {
  credentials: "include",
});

if (response.status === 401) {
  const { signin_url } = await response.json();
  window.location.href = signin_url;
}
```

## Implementation Workflow

1. **Choose auth method**
   - CLI tools: Device-code flow
   - Browser apps: Redirect or direct Clerk
   - Servers: Use PAT from environment

2. **Register your app**
   - Define app slug (e.g., "video")
   - Set starter credits amount
   - Configure app metadata

3. **Implement credit flow**
   - Check wallet before operations
   - Create job with cost estimate
   - Complete/fail job with actual cost
   - Handle insufficient credits gracefully

4. **Add job metadata**
   - `description`: Human-readable summary
   - `previewUrl`: Thumbnail or result link
   - Custom fields for your app

## Quality Checklist

Before deploying Focus-integrated app:

- [ ] Authentication method chosen and implemented
- [ ] Wallet check integrated before expensive operations
- [ ] Job creation reserves appropriate credits
- [ ] Job completion settles actual cost
- [ ] Job failure handles refunds
- [ ] Insufficient credits error handled gracefully
- [ ] Auth errors redirect to sign-in
- [ ] Cross-origin requests include credentials
- [ ] PAT securely stored (not in client code)
- [ ] Job metadata provides useful context

## Reference Documentation

For complete API specification, endpoint details, and advanced patterns, see:
- [REFERENCE.md](REFERENCE.md) - Full Focus API Integration Guide
- API Docs: https://account.thefocus.ai/api/docs
- OpenAPI JSON: https://account.thefocus.ai/api/openapi.json
