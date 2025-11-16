---
name: twitter-oauth-cli
description: Build CLI tools that authenticate with Twitter/X OAuth 2.0 using PKCE flow. Use when creating command-line apps that need Twitter tokens, implementing device-code style auth for scripts, or building automation tools that post to Twitter. Trigger when user needs Twitter API access from terminal, wants to build a tweet poster, or needs OAuth 2.0 PKCE implementation.
---

# Twitter OAuth 2.0 CLI Tool

Build command-line applications that authenticate with Twitter/X using OAuth 2.0 PKCE flow.

## When to Use This Skill

Use this skill when:
- Creating CLI tools that need Twitter API access
- Building automation scripts that post tweets
- Implementing OAuth 2.0 PKCE for terminal applications
- Storing Twitter tokens for offline/automated use
- Building tweet schedulers or social media tools

## Quick Start

### 1. Twitter Developer Portal Setup

**CRITICAL**: Configure your app correctly FIRST.

1. Go to Developer Portal → Settings → User authentication settings
2. Set **App type**: "Web App, Automated App or Bot"
3. Set **App permissions**: "Read and Write"
4. Set **Callback URI**: `http://127.0.0.1:3000/callback`

   ⚠️ **IMPORTANT**: Do NOT use `localhost`! Twitter rejects it with a cryptic "Something went wrong" error. Use one of:
   - `http://127.0.0.1:3000/callback` (recommended)
   - `http://www.localhost:3000/callback`

5. Set **Website URL**: `http://127.0.0.1:3000`
6. Save settings
7. Go to "Keys and tokens" tab → Copy **Client ID** and **Client Secret**

### 2. Required OAuth Scopes

```typescript
const SCOPES = [
  'tweet.read',
  'tweet.write',
  'users.read',
  'offline.access'  // CRITICAL for refresh tokens!
].join(' ');
```

**Why `offline.access` is critical**: Without it, your token expires in 2 hours. With it, you get a refresh token and can stay authenticated indefinitely.

### 3. Project Setup

```bash
mkdir twitter-cli && cd twitter-cli
pnpm init
pnpm add express open
pnpm add -D typescript @types/express @types/node
```

**package.json**:
```json
{
  "type": "module",
  "scripts": {
    "auth": "tsx src/auth.ts",
    "post": "tsx src/post.ts"
  }
}
```

### 4. PKCE Flow Implementation

```typescript
// src/auth.ts
import crypto from 'crypto';
import express from 'express';
import open from 'open';
import fs from 'fs';

const CLIENT_ID = process.env.TWITTER_CLIENT_ID!;
const CLIENT_SECRET = process.env.TWITTER_CLIENT_SECRET!;
const PORT = 3000;
const CALLBACK_URL = `http://127.0.0.1:${PORT}/callback`;

const SCOPES = [
  'tweet.read',
  'tweet.write',
  'users.read',
  'offline.access'
].join(' ');

// Generate PKCE challenge
const codeVerifier = crypto.randomBytes(32).toString('base64url');
const codeChallenge = crypto
  .createHash('sha256')
  .update(codeVerifier)
  .digest('base64url');

const state = crypto.randomBytes(16).toString('hex');

async function main() {
  const app = express();

  // Build OAuth URL
  const authUrl = new URL('https://twitter.com/i/oauth2/authorize');
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('client_id', CLIENT_ID);
  authUrl.searchParams.set('redirect_uri', CALLBACK_URL);
  authUrl.searchParams.set('scope', SCOPES);
  authUrl.searchParams.set('state', state);
  authUrl.searchParams.set('code_challenge', codeChallenge);
  authUrl.searchParams.set('code_challenge_method', 'S256');

  // Handle callback
  app.get('/callback', async (req, res) => {
    const { code, state: returnedState } = req.query;

    if (returnedState !== state) {
      res.send('State mismatch! Possible CSRF attack.');
      process.exit(1);
    }

    // Exchange code for tokens
    const tokenResponse = await fetch('https://api.twitter.com/2/oauth2/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64')}`
      },
      body: new URLSearchParams({
        code: code as string,
        grant_type: 'authorization_code',
        redirect_uri: CALLBACK_URL,
        code_verifier: codeVerifier
      })
    });

    const tokens = await tokenResponse.json();

    if (tokens.error) {
      res.send(`Error: ${tokens.error_description}`);
      process.exit(1);
    }

    // Save tokens
    fs.writeFileSync('.twitter-tokens.json', JSON.stringify({
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      expires_at: Date.now() + (tokens.expires_in * 1000)
    }, null, 2));

    res.send('Authentication successful! You can close this window.');
    console.log('✅ Tokens saved to .twitter-tokens.json');
    process.exit(0);
  });

  const server = app.listen(PORT, () => {
    console.log(`Opening browser for authentication...`);
    console.log(`If browser doesn't open, visit: ${authUrl.toString()}`);
    open(authUrl.toString());
  });
}

main().catch(console.error);
```

### 5. Token Management

```typescript
// src/tokens.ts
import fs from 'fs';

interface Tokens {
  access_token: string;
  refresh_token: string;
  expires_at: number;
}

export function loadTokens(): Tokens {
  if (!fs.existsSync('.twitter-tokens.json')) {
    throw new Error('No tokens found. Run auth first.');
  }
  return JSON.parse(fs.readFileSync('.twitter-tokens.json', 'utf-8'));
}

export async function refreshTokens(tokens: Tokens): Promise<Tokens> {
  const response = await fetch('https://api.twitter.com/2/oauth2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64')}`
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: tokens.refresh_token
    })
  });

  const newTokens = await response.json();

  const updated = {
    access_token: newTokens.access_token,
    refresh_token: newTokens.refresh_token,
    expires_at: Date.now() + (newTokens.expires_in * 1000)
  };

  fs.writeFileSync('.twitter-tokens.json', JSON.stringify(updated, null, 2));
  return updated;
}

export async function getValidToken(): Promise<string> {
  let tokens = loadTokens();

  // Refresh if expired (with 5 minute buffer)
  if (tokens.expires_at < Date.now() + 300000) {
    console.log('Token expired, refreshing...');
    tokens = await refreshTokens(tokens);
  }

  return tokens.access_token;
}
```

### 6. Posting Tweets

```typescript
// src/post.ts
import { getValidToken } from './tokens.js';

async function postTweet(text: string) {
  const token = await getValidToken();

  const response = await fetch('https://api.twitter.com/2/tweets', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ text })
  });

  const result = await response.json();

  if (result.errors) {
    throw new Error(result.errors[0].message);
  }

  console.log(`✅ Tweet posted: https://twitter.com/i/status/${result.data.id}`);
  return result.data;
}

// CLI usage
const text = process.argv.slice(2).join(' ');
if (!text) {
  console.error('Usage: pnpm post "Your tweet text"');
  process.exit(1);
}

postTweet(text).catch(console.error);
```

## Environment Variables

```bash
# .env (add to .gitignore!)
TWITTER_CLIENT_ID=your_client_id
TWITTER_CLIENT_SECRET=your_client_secret
```

Load with:
```typescript
import 'dotenv/config';
// or use shell: export $(cat .env | xargs)
```

## Security Best Practices

1. **Never commit tokens**: Add `.twitter-tokens.json` to `.gitignore`
2. **Store credentials securely**: Use environment variables or secret managers
3. **Validate state parameter**: Prevents CSRF attacks
4. **Use HTTPS in production**: `127.0.0.1` is fine for local dev only
5. **Implement token rotation**: Always use refresh tokens before expiry

## Common Pitfalls

### "Something went wrong" Error
**Cause**: Using `localhost` instead of `127.0.0.1` in callback URL
**Fix**: Use `http://127.0.0.1:3000/callback`

### Token Expires After 2 Hours
**Cause**: Missing `offline.access` scope
**Fix**: Add `offline.access` to scopes array

### "Invalid redirect_uri"
**Cause**: Mismatch between code and Developer Portal setting
**Fix**: Ensure exact match including port and path

### "Unauthorized" on API Calls
**Cause**: Expired token not refreshed
**Fix**: Use `getValidToken()` which auto-refreshes

### Rate Limiting
**Cause**: Too many requests
**Fix**: Implement exponential backoff

## Extended Features

### User Info

```typescript
async function getMe(token: string) {
  const response = await fetch('https://api.twitter.com/2/users/me', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return response.json();
}
```

### Tweet with Media

```typescript
// Requires additional scopes and media upload endpoint
// See Twitter API v2 documentation for media upload flow
```

### Reading Timeline

```typescript
async function getTimeline(token: string) {
  const user = await getMe(token);
  const response = await fetch(
    `https://api.twitter.com/2/users/${user.data.id}/tweets`,
    { headers: { 'Authorization': `Bearer ${token}` } }
  );
  return response.json();
}
```

## Integration with Focus.AI

Use Focus Account Integration skill to:
1. Store tokens via Focus API (encrypted)
2. Share tokens across Focus apps
3. Use `GET /api/xToken` for retrieved tokens

## Quality Checklist

Before deploying your Twitter CLI tool:

- [ ] Callback URL uses `127.0.0.1`, not `localhost`
- [ ] All required scopes included (especially `offline.access`)
- [ ] State parameter validated to prevent CSRF
- [ ] Tokens stored securely (not in repo)
- [ ] Auto-refresh before token expiry
- [ ] `.gitignore` includes token files and .env
- [ ] Error handling for API failures
- [ ] Rate limiting respected
- [ ] PKCE code verifier is cryptographically random
- [ ] Client credentials stored in environment variables

## Full Example

See the complete working implementation pattern:
1. Run `pnpm auth` to authenticate
2. Browser opens, authorize the app
3. Callback captures code, exchanges for tokens
4. Tokens saved locally
5. Use `pnpm post "Hello Twitter!"` to post
6. Auto-refresh handles token expiry

This pattern works for any OAuth 2.0 PKCE CLI application, not just Twitter!
