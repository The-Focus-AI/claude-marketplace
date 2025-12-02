# Distill Service Framework Specification

## Overview

The Distill project is a suite of microservices that collect, process, and summarize content from various platforms (Twitter/X, Email, GitHub, YouTube, etc.) into personalized feeds. Each service operates independently while conforming to common interface standards that enable AI-driven orchestration.

### Core Architecture Principles

1. **Service Independence**: Each service handles its own scheduling, rate limiting, storage, and processing logic
2. **AI-Native Discovery**: Services self-document in LLM-optimized formats for dynamic composition
3. **JWT-Based Auth**: User identity flows via JWT tokens from a central authentication service (Clerk)
4. **Local Processing**: Services store and process data locally to simplify development and testing
5. **Explicit Lifecycle**: Services only monitor users explicitly registered via watch/unwatch endpoints

## Authentication

### JWT Requirements

All endpoints (except `/api`, `/capabilities`, and `/health`) require a valid JWT bearer token.

**Required JWT Claims:**
```json
{
  "user_id": "user_123",
  "email": "user@example.com",
  "credits_available": true,
  "iat": 1704890400,
  "exp": 1704894000
}
```

**Authentication Header:**
```
Authorization: Bearer <jwt_token>
```

### Token Validation

Services should validate JWTs using Clerk's public keys. Invalid or expired tokens return:
```json
{
  "error": "authentication_failed",
  "message": "Invalid or expired authentication token",
  "user_action_required": true,
  "action_url": "https://auth.yourapp.com/login"
}
```

## Standard Endpoints

Every Distill service MUST implement these endpoints:

### GET /api
**Purpose**: Service documentation for LLM and human consumption  
**Authentication**: None required  
**Response**: 
```json
{
  "service": "platform-feeder",
  "version": "1.0.0",
  "description": "Collects and processes content from [Platform]",
  "authentication": "Bearer JWT required with user_id claim",
  
  "endpoints": {
    "/watch": {
      "method": "POST",
      "description": "Start monitoring this user's [Platform] account. Service begins periodic syncing.",
      "returns": {
        "status": "watching|already_watching",
        "since": "ISO 8601 timestamp"
      },
      "errors": ["no_platform_auth", "insufficient_credits"]
    },
    
    "/unwatch": {
      "method": "POST",
      "description": "Stop monitoring this user's account and clean up resources.",
      "returns": {
        "status": "unwatched|not_watching"
      }
    },
    
    "/sync": {
      "method": "POST",
      "description": "Trigger immediate sync for this user. Useful for on-demand updates.",
      "parameters": {
        "force": "boolean - Bypass rate limit checks (default: false)"
      },
      "returns": {
        "status": "syncing|rate_limited|completed",
        "next_sync": "ISO 8601 timestamp"
      }
    },
    
    "/metadata": {
      "method": "GET",
      "description": "Discover what data endpoints are available for this user.",
      "returns": "Dynamic list of available data endpoints with descriptions"
    }
  },
  
  "usage_example": "First POST /watch to start monitoring. GET /metadata to discover available data. GET specific endpoints like /content/recent for actual data.",
  
  "rate_limits": {
    "sync_frequency": "Every 30 minutes",
    "api_calls": "100 per minute per user"
  }
}
```

### GET /capabilities
**Purpose**: Describe what this service can do (potential features)  
**Authentication**: None required  
**Response**:
```json
{
  "service": "platform-feeder",
  "version": "1.0.0",
  
  "supported_data_types": [
    {
      "type": "content/recent",
      "path_pattern": "/content/recent",
      "description": "Recent content from the last N hours",
      "parameters": {
        "hours": {
          "type": "integer",
          "default": 24,
          "min": 1,
          "max": 168,
          "description": "How many hours of history to return"
        }
      }
    },
    {
      "type": "content/summary/daily",
      "path_pattern": "/content/summary/daily",
      "description": "AI-generated daily digest of important content",
      "parameters": {
        "date": {
          "type": "date",
          "format": "YYYY-MM-DD",
          "description": "Specific date for summary"
        }
      },
      "requirements": "Requires at least 24 hours of collected data"
    }
  ],
  
  "platform_requirements": {
    "oauth_scopes": ["read", "list_management"],
    "token_type": "OAuth2",
    "refresh_supported": true
  },
  
  "data_retention": {
    "raw_data": "7 days",
    "summaries": "30 days",
    "metadata": "indefinite"
  },
  
  "sync_behavior": {
    "frequency": "Every 30 minutes when watching",
    "backfill": "Up to 7 days on initial watch",
    "incremental": true
  }
}
```

### POST /watch
**Purpose**: Register a user for monitoring  
**Authentication**: Required  
**Request Body**: 
```json
{
  "options": {
    "backfill_days": 7,
    "sync_frequency": "30m"
  }
}
```
**Response (201 Created)**:
```json
{
  "status": "watching",
  "since": "2024-01-10T10:00:00Z",
  "next_sync": "2024-01-10T10:30:00Z",
  "backfill_status": "queued"
}
```
**Response (200 OK - already watching)**:
```json
{
  "status": "already_watching",
  "since": "2024-01-09T08:00:00Z",
  "last_sync": "2024-01-10T10:00:00Z",
  "next_sync": "2024-01-10T10:30:00Z"
}
```

### POST /unwatch
**Purpose**: Stop monitoring a user  
**Authentication**: Required  
**Response (200 OK)**:
```json
{
  "status": "unwatched",
  "watched_duration": "2 days, 3 hours",
  "data_retention": "Data will be retained for 7 days"
}
```

### POST /sync
**Purpose**: Trigger immediate synchronization  
**Authentication**: Required  
**Request Body**:
```json
{
  "force": false,
  "types": ["content/recent"]  // Optional: specific data types to sync
}
```
**Response (202 Accepted)**:
```json
{
  "status": "syncing",
  "job_id": "sync_abc123",
  "estimated_completion": "2024-01-10T10:05:00Z"
}
```
**Response (429 Too Many Requests)**:
```json
{
  "error": "rate_limited",
  "message": "Platform API rate limit active",
  "retry_after": "2024-01-10T11:00:00Z",
  "user_action_required": false
}
```

### GET /metadata
**Purpose**: Discover available data for the authenticated user  
**Authentication**: Required  
**Response**:
```json
{
  "user_status": {
    "watching": true,
    "since": "2024-01-09T08:00:00Z",
    "last_sync": "2024-01-10T10:00:00Z",
    "last_sync_status": "partial",
    "next_sync": "2024-01-10T10:30:00Z"
  },
  
  "available_endpoints": [
    {
      "path": "/content/recent",
      "method": "GET",
      "description": "Recent content from the last 24 hours",
      "data_freshness": "2024-01-10T10:00:00Z",
      "item_count": 47,
      "completeness": 1.0
    },
    {
      "path": "/content/summary/daily",
      "method": "GET",
      "description": "AI-generated daily summaries",
      "available_dates": ["2024-01-10", "2024-01-09", "2024-01-08"],
      "latest_summary": "2024-01-10"
    },
    {
      "path": "/content/search",
      "method": "POST",
      "description": "Search through collected content",
      "searchable_fields": ["text", "author", "tags"],
      "date_range": {
        "start": "2024-01-03T00:00:00Z",
        "end": "2024-01-10T10:00:00Z"
      }
    }
  ],
  
  "statistics": {
    "total_items": 523,
    "storage_used": "12.5 MB",
    "summaries_generated": 3
  }
}
```

### GET /health
**Purpose**: Service health check  
**Authentication**: None required  
**Response (200 OK)**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": "2 days, 3:24:15",
  "active_users": 42,
  "platform_api_status": "operational",
  "last_sync_cycle": "2024-01-10T10:00:00Z"
}
```

## Dynamic Data Endpoints

Based on `/metadata` discovery, services expose data endpoints following these patterns:

### GET /content/recent
**Purpose**: Retrieve recent content  
**Query Parameters**:
- `hours` (integer): Hours of history (default: 24, max: 168)
- `limit` (integer): Maximum items to return (default: 100)
- `include_raw` (boolean): Include original platform data (default: false)

**Response**:
```json
{
  "data": [
    {
      "id": "item_123",
      "platform_id": "tweet_989898",
      "timestamp": "2024-01-10T09:45:00Z",
      "content": "Processed content here...",
      "author": "username",
      "metrics": {
        "engagement": 45,
        "reach": 1200
      },
      "ai_tags": ["technology", "announcement"],
      "raw_data": {}  // If requested
    }
  ],
  "metadata": {
    "query_time": "2024-01-10T10:15:00Z",
    "freshness": "2024-01-10T10:00:00Z",
    "completeness": 0.95,
    "warnings": ["some_data_delayed"],
    "count": 47,
    "has_more": false
  }
}
```

### GET /content/summary/{period}
**Purpose**: Retrieve AI-generated summaries  
**Path Parameters**:
- `period`: "daily", "weekly", or specific date "2024-01-10"

**Response**:
```json
{
  "summary": {
    "period": "daily",
    "date": "2024-01-10",
    "generated_at": "2024-01-10T10:05:00Z",
    "content": {
      "highlights": [
        "Key point 1 from your feed...",
        "Important update about..."
      ],
      "sections": {
        "trending": "Multiple accounts discussing...",
        "mentions": "You were mentioned in...",
        "important": "Don't miss this thread about..."
      }
    },
    "statistics": {
      "items_processed": 127,
      "sources": 34,
      "time_range": {
        "start": "2024-01-10T00:00:00Z",
        "end": "2024-01-10T23:59:59Z"
      }
    }
  },
  "metadata": {
    "model_used": "gpt-4",
    "processing_time": "2.3s",
    "confidence": 0.92
  }
}
```

## Error Response Format

All errors follow this structure:

```json
{
  "error": "error_code",
  "message": "Human-readable error message",
  "details": {
    "field": "Additional context"
  },
  "retry_after": "2024-01-10T11:00:00Z",  // If applicable
  "user_action_required": false,
  "action_url": "https://..."  // If user action needed
}
```

### Standard Error Codes

| Code | HTTP Status | Description | User Action Required |
|------|-------------|-------------|----------------------|
| `not_watching` | 404 | User not registered for monitoring | No |
| `no_platform_auth` | 403 | Platform credentials missing/invalid | Yes |
| `token_expired` | 401 | Platform token needs refresh | Yes |
| `rate_limited` | 429 | Platform API rate limit hit | No |
| `insufficient_credits` | 402 | User out of credits | Yes |
| `sync_in_progress` | 409 | Sync already running | No |
| `platform_error` | 502 | Platform API error | No |
| `internal_error` | 500 | Service error | No |

## Implementation Guidelines

### Storage Patterns

Services may choose their storage based on needs:

1. **Filesystem**: Simple, good for prototyping
```
/data/users/{user_id}/
  raw/
    2024-01-10/
      content.json
  processed/
    summaries/
      daily_2024-01-10.json
  metadata.json
```

2. **PostgreSQL**: Better for complex queries
```sql
CREATE TABLE user_content (
  user_id VARCHAR(255),
  platform_id VARCHAR(255),
  collected_at TIMESTAMP,
  content JSONB,
  processed BOOLEAN DEFAULT false
);
```

3. **Redis**: Excellent for rate limiting and caching
```
rate_limit:{user_id} → remaining requests
last_sync:{user_id} → timestamp
cache:{user_id}:recent → serialized recent items
```

### OAuth Token Management

Services request tokens from central auth service:

```http
GET https://auth.internal/tokens/{platform}/{user_id}
Authorization: Bearer <service_jwt>

Response:
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": "2024-01-10T12:00:00Z",
  "scopes": ["read", "write"]
}
```

### Sync Scheduling Patterns

Each service implements its own scheduler:

```python
# Example: Simple interval-based
while True:
    active_users = get_active_users()  # Call central auth
    for user_id in active_users:
        if should_sync(user_id):  # Check last sync time
            try:
                sync_user(user_id)
            except RateLimitError:
                backoff(user_id)
    sleep(check_interval)
```

### Rate Limiting Strategies

Platform-specific approaches:

1. **Token Bucket**: For per-second limits
2. **Sliding Window**: For requests per time period  
3. **Adaptive**: Start aggressive, backoff on errors
4. **Quota Allocation**: Pre-calculate requests per user

## Example Service Implementation Flow

### User Onboarding
1. Central auth completes OAuth flow for platform
2. Central auth calls service's `POST /watch` endpoint
3. Service begins monitoring, optionally backfills data
4. Service processes and stores initial content

### Regular Operation
1. Service scheduler checks with central auth for active users
2. For each active user with credits:
   - Fetch latest content from platform
   - Store raw data locally
   - Process/summarize as configured
   - Update metadata
3. UI server queries `/metadata` to discover available data
4. UI server fetches specific endpoints based on user needs

### User Query Flow
1. User asks UI: "What are the highlights from Twitter today?"
2. UI server LLM reads service `/api` documentation
3. LLM calls `/metadata` to check available data
4. LLM fetches `/content/summary/daily`
5. LLM formats response for user

## Testing Requirements

Each service should provide:

1. **Mock Mode**: Can run without real platform credentials
2. **Test Data**: Sample responses for all endpoints
3. **Health Monitoring**: Metrics exposed at `/health`
4. **Error Simulation**: Can trigger specific error conditions

## Security Considerations

1. **Never log tokens or sensitive data**
2. **Validate JWT signatures on every request**
3. **Sanitize data from external platforms**
4. **Rate limit incoming requests per user**
5. **Encrypt stored platform credentials**
6. **Implement request timeouts**

## Future Considerations

The framework is designed to support:

- WebSocket endpoints for real-time updates
- Batch operations across multiple users
- Export endpoints for data portability
- Webhook endpoints for platform push updates
- Federation between Distill instances

---

This specification defines the minimum viable framework for Distill services. Services may extend these patterns for platform-specific needs while maintaining compatibility with the core interface.