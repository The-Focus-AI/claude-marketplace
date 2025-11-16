---
name: distill-backend-service
description: Build Distill microservices that collect, process, and summarize content from platforms (Twitter/X, Email, GitHub, YouTube). Use when implementing watch/unwatch lifecycle, sync endpoints, AI-generated summaries, or service discovery patterns. Trigger when user needs to create a content aggregation service, implement standard API patterns, or build LLM-optimized service interfaces.
---

# Distill Backend Service Framework

Build microservices for the Distill content aggregation platform following standard patterns for service discovery, authentication, and data synchronization.

## When to Use This Skill

Use this skill when:
- Creating a new Distill service for a content platform
- Implementing watch/unwatch user lifecycle management
- Building AI-powered content summaries and feeds
- Adding standard API endpoints for service discovery
- Implementing JWT-based authentication with Clerk
- Setting up sync scheduling and rate limiting

## Core Architecture

Distill services are independent microservices that:
1. Collect content from external platforms (Twitter, Email, GitHub, YouTube, etc.)
2. Process and store data locally
3. Generate AI summaries and insights
4. Expose LLM-optimized discovery endpoints

## Quick Start

### Required Endpoints

Every Distill service MUST implement:

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api` | GET | None | Service documentation for LLMs |
| `/capabilities` | GET | None | Service features and requirements |
| `/health` | GET | None | Health check |
| `/watch` | POST | JWT | Start monitoring user |
| `/unwatch` | POST | JWT | Stop monitoring user |
| `/sync` | POST | JWT | Trigger immediate sync |
| `/metadata` | GET | JWT | Discover available data |

### Authentication

All protected endpoints require JWT bearer token:
```
Authorization: Bearer <jwt_token>
```

Required JWT claims:
```json
{
  "user_id": "user_123",
  "email": "user@example.com",
  "credits_available": true
}
```

## Implementation Workflow

1. **Set up service structure**
   - Create standard endpoint handlers
   - Configure JWT validation with Clerk
   - Set up local storage (filesystem, PostgreSQL, or Redis)

2. **Implement user lifecycle**
   - `POST /watch`: Register user for monitoring
   - `POST /unwatch`: Stop monitoring and cleanup
   - Track user status and sync history

3. **Build sync logic**
   - Scheduler for periodic syncs
   - Rate limiting for platform APIs
   - Incremental data collection
   - Error handling and backoff

4. **Add data endpoints**
   - `/content/recent`: Latest content
   - `/content/summary/{period}`: AI-generated summaries
   - `/content/search`: Search collected content

5. **Generate AI summaries**
   - Process collected content
   - Generate daily/weekly digests
   - Tag and categorize content

## Standard Response Formats

### Service Documentation (`GET /api`)
```json
{
  "service": "platform-feeder",
  "version": "1.0.0",
  "description": "Collects and processes content from [Platform]",
  "authentication": "Bearer JWT required",
  "endpoints": { ... },
  "usage_example": "...",
  "rate_limits": { ... }
}
```

### Watch Response
```json
{
  "status": "watching",
  "since": "2024-01-10T10:00:00Z",
  "next_sync": "2024-01-10T10:30:00Z",
  "backfill_status": "queued"
}
```

### Metadata Response
```json
{
  "user_status": {
    "watching": true,
    "since": "...",
    "last_sync": "...",
    "next_sync": "..."
  },
  "available_endpoints": [
    {
      "path": "/content/recent",
      "method": "GET",
      "description": "...",
      "item_count": 47
    }
  ],
  "statistics": { ... }
}
```

### Error Response
```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "retry_after": "2024-01-10T11:00:00Z",
  "user_action_required": false
}
```

## Standard Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `not_watching` | 404 | User not registered |
| `no_platform_auth` | 403 | Platform credentials missing |
| `token_expired` | 401 | Platform token needs refresh |
| `rate_limited` | 429 | Platform API rate limit |
| `insufficient_credits` | 402 | User out of credits |
| `sync_in_progress` | 409 | Sync already running |

## Storage Patterns

Choose based on needs:

**Filesystem** (simple, good for prototyping):
```
/data/users/{user_id}/
  raw/
    2024-01-10/content.json
  processed/
    summaries/daily_2024-01-10.json
  metadata.json
```

**PostgreSQL** (complex queries):
```sql
CREATE TABLE user_content (
  user_id VARCHAR(255),
  platform_id VARCHAR(255),
  collected_at TIMESTAMP,
  content JSONB,
  processed BOOLEAN DEFAULT false
);
```

**Redis** (rate limiting, caching):
```
rate_limit:{user_id} → remaining requests
last_sync:{user_id} → timestamp
cache:{user_id}:recent → serialized items
```

## Security Requirements

1. Never log tokens or sensitive data
2. Validate JWT signatures on every request
3. Sanitize data from external platforms
4. Rate limit incoming requests per user
5. Encrypt stored platform credentials
6. Implement request timeouts

## Quality Checklist

Before deploying a Distill service:

- [ ] All standard endpoints implemented (`/api`, `/capabilities`, `/health`, `/watch`, `/unwatch`, `/sync`, `/metadata`)
- [ ] JWT authentication properly configured
- [ ] Service self-documentation is LLM-friendly
- [ ] Error responses follow standard format
- [ ] Rate limiting implemented for platform APIs
- [ ] Sync scheduling handles failures gracefully
- [ ] Data retention policies enforced
- [ ] Security best practices followed
- [ ] Mock mode available for testing
- [ ] Health monitoring exposed

## Reference Documentation

For complete specification including all endpoint schemas, implementation examples, and advanced patterns, see:
- [REFERENCE.md](REFERENCE.md) - Full Distill Service Framework Specification
