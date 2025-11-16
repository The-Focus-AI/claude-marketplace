# The Focus API — Integration Guide

This guide shows how a remote Focus app (e.g., video.thefocus.ai) signs in via Clerk at account.thefocus.ai, obtains a token, checks wallet/credits, and creates/settles jobs.

## Prereqs
- Clerk project configured for thefocus.ai with cookie domain set to ".thefocus.ai" and SameSite=None; Secure
- account.thefocus.ai is reachable from your app

## 0) CLI Login (device code) — recommended for scripts/automation
Use the Focus CLI to authenticate once and obtain a long‑lived personal access token (PAT) for API calls.

```
# From the repo workspace
pnpm --filter @thefocus/focus-cli dev -- login
# This prints a code and opens https://account.thefocus.ai/device
# After confirming in the browser, your PAT is stored locally

# Verify
pnpm --filter @thefocus/focus-cli dev -- print-token
pnpm --filter @thefocus/focus-cli dev -- whoami
```

Notes:
- PATs are valid ~90 days and can be used as Authorization: Bearer <token>.
- All protected endpoints accept either a Clerk JWT (browser/app context) or a PAT (CLI/automation).

## 1) Sign in (choose one mode)

### A) Redirect to shared sign-in at account.thefocus.ai
Redirect the browser to the shared sign-in, then return to your app.

```js
// In your app (e.g., video.thefocus.ai)
const back = window.location.href;
window.location.href = `https://account.thefocus.ai/signin?redirect_to=${encodeURIComponent(back)}`;
```

On return, your landing URL may include a `token` query param containing a Clerk JWT. You can also fetch a session token from the backend using cookies:

```js
// Get a Clerk session JWT via API using cookies
await fetch("https://account.thefocus.ai/api/sessionToken", {
  method: "GET",
  credentials: "include",
});
// If unauthenticated this returns 401 with a signin_url you can redirect to
```

### B) Use Clerk directly in your app (no redirect)
Initialize Clerk in your app and sign users in there. Then pass the Clerk token as a bearer token on Focus API requests.

```js
// Using @clerk/nextjs in your app
import { useAuth } from "@clerk/nextjs";

const { isSignedIn, getToken } = useAuth();
// Ensure the user is signed in via your app's UI
const token = await getToken(); // Clerk JWT to send as Authorization: Bearer
```

With this mode, include the token on each request to `account.thefocus.ai`. You do not need to rely on shared cookies, though cookies are supported if you prefer (`credentials: 'include'`).

## 2) Call the Wallet API
Use either:
- Clerk cookies / Clerk JWT (browser/app)
- PAT from the CLI (automation/servers)

```js
// Using @clerk/nextjs in your app
import { useAuth } from "@clerk/nextjs";

const { getToken } = useAuth();
const token = await getToken();

// OPTION A: Upsert account only (no app grant)
await fetch("https://account.thefocus.ai/api/wallet", {
  method: "GET",
  credentials: "include",
  headers: { Authorization: `Bearer ${token}` },
});

// OPTION B: Upsert your app and receive starter credits once per account+app
await fetch("https://account.thefocus.ai/api/wallet?app=video", {
  method: "GET",
  credentials: "include",
  headers: { Authorization: `Bearer ${token}` },
});
```

Response shape:

```json
{
  "account": { "id": "uuid", "clerk_id": "string", "plan": "free", "credits": 123 },
  "apps": [
    { "slug": "video", "starter_credits": 20, "granted": true, "granted_at": "2025-10-28T...Z" }
  ],
  "app_grant": { "slug": "video", "starter_credits": 20, "granted": true }
}
```

## 3) Create a Job (reserve credits)

```js
const token = await getToken();
const res = await fetch("https://account.thefocus.ai/api/jobs", {
  method: "POST",
  credentials: "include",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
  body: JSON.stringify({
    app: "video",
    action: "render",
    cost_estimate: 5,
    metadata: {
      description: "Render preview clip",
      previewUrl: "https://video.example.com/previews/abc123.jpg",
      example: true,
    },
  }),
});
const { job_id } = await res.json();
```

Recommended metadata fields (optional):

- **description**: short, human-readable summary of the job
- **previewUrl**: URL for a thumbnail, preview image, or result link

Errors: 402 if insufficient credits; 401 if auth missing/invalid.

## 4) Complete or Fail the Job

```js
// Complete and settle cost (refunds any unused reserve or charges overage)
await fetch("https://account.thefocus.ai/api/jobs/complete", {
  method: "POST",
  credentials: "include",
  headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
  body: JSON.stringify({
    job_id,
    actual_cost: 3,
    // New metadata is merged into existing job metadata (new keys win)
    metadata: {
      description: "Render completed (1080p)",
      previewUrl: "https://video.example.com/previews/abc123-final.jpg",
      durationMs: 1200,
    },
  }),
});

// Fail and optionally refund (default true)
await fetch("https://account.thefocus.ai/api/jobs/fail", {
  method: "POST",
  credentials: "include",
  headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
  body: JSON.stringify({ job_id, refund: true }),
});
```

## 5) List Jobs (optional)

```js
await fetch("https://account.thefocus.ai/api/jobs?app=video&status=started&limit=50", {
  method: "GET",
  credentials: "include",
  headers: { Authorization: `Bearer ${token}` },
});
```

## 6) Device-code & PAT endpoints (for custom clients)
- `POST /api/device/start` → `{ device_code, user_code, verification_uri, expires_in, interval }`
- `POST /api/device/complete` (browser, requires Clerk session) → `{ ok: true }`
- `GET /api/device/poll?device_code=…` → `202` pending, or `{ token }` (PAT) when ready

Use the returned `token` (PAT) as `Authorization: Bearer <token>` in subsequent API calls.

## 6) OAuth token helpers (optional)
- `GET /api/xToken` → returns your X/Twitter OAuth access token via Clerk
- `GET /api/oauthToken/{provider}` → same for an arbitrary provider slug

Use `GET /api/xMe` to proxy to `https://api.twitter.com/2/users/me` with your Twitter bearer token (set `Authorization: Bearer <twitter_token>`).

## Errors & CORS
- 401: Missing/invalid auth. `GET /api/sessionToken` returns a `signin_url` for redirects when unauthenticated.
- 402: Insufficient credits on job creation.
- Cross-origin: include credentials when relying on cookies. Bearer tokens also supported.

## References
- API Docs: https://account.thefocus.ai/api/docs
- OpenAPI JSON: https://account.thefocus.ai/api/openapi.json
 - CLI: `focus login`, `focus print-token`, `focus whoami`, `focus jobs …`
