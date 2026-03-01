# Webhook System

## Overview

The webhook system enables workspace administrators to configure external HTTP endpoints that receive event notifications. When events occur, the system delivers signed JSON payloads to registered URLs with HMAC-SHA256 verification and retry logic for failed deliveries.

## Data Model

### Webhook

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| workspaceId | string (UUID) | References Workspace.id |
| url | string | Required, valid HTTPS URL |
| events | array of strings | Required, non-empty; event types to subscribe to |
| secret | string | Required, min 16 chars; used for HMAC-SHA256 (write-only, never returned) |
| active | boolean | Default: `true` |
| createdAt | string (ISO8601) | Auto-set on creation |
| updatedAt | string (ISO8601) | Auto-set on mutation |

### DeliveryLog

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| webhookId | string (UUID) | References Webhook.id |
| deliveryId | string (UUID) | Groups retry attempts for one delivery |
| event | string | Event type that triggered delivery |
| statusCode | number or null | HTTP response status; null if request failed |
| success | boolean | `true` if statusCode is 2xx |
| attemptNumber | number | 1, 2, or 3 |
| error | string or null | Error message on failure |
| timestamp | string (ISO8601) | When this attempt was made |

## Subscribable Events

`task.created`, `task.updated`, `task.deleted`, `task.status_changed`, `comment.created`, `member.joined`, `member.left`. Use `["*"]` to subscribe to all.

## API Endpoints

### GET /workspaces/:id/webhooks
- **Auth**: `admin` or `owner`. Returns all webhooks (excluding `secret`).

### POST /workspaces/:id/webhooks
- **Auth**: `admin` or `owner`.
- **Body**: `{ "url": "https://...", "events": ["task.created"], "secret": "min16chars..." }`
- **Response**: `201 Created`. **Errors**: `400` for invalid URL/events/secret.

### PUT /workspaces/:id/webhooks/:webhookId
- **Auth**: `admin` or `owner`. Partial update of `url`, `events`, `secret`, `active`.

### DELETE /workspaces/:id/webhooks/:webhookId
- **Auth**: `admin` or `owner`. Returns `204`. DeliveryLog records are preserved.

### GET /workspaces/:id/webhooks/:webhookId/deliveries
- **Auth**: `admin` or `owner`. Query: `event`, `success`, `page`, `limit`.
- **Response**: Paginated list of delivery log entries.

## Delivery Mechanism

### Payload
```json
{ "event": "task.created", "data": { }, "timestamp": "ISO8601", "webhookId": "uuid", "deliveryId": "uuid" }
```

### Signature
`X-Webhook-Signature: sha256=<hex_digest>` — HMAC-SHA256 of the JSON body using the webhook's `secret`.

### Retry Strategy

| Attempt | Delay | Total Elapsed |
|---------|-------|---------------|
| 1 | Immediate | 0s |
| 2 | 1 second | 1s |
| 3 | 5 seconds | 6s |

A `2xx` response is success. Non-2xx or network errors trigger retries. After 3 failures, delivery is permanently failed. Each attempt creates a DeliveryLog record with the same `deliveryId`.

### Delivery Flow

1. Event occurs in workspace.
2. Query active webhooks subscribed to the event type.
3. For each match: generate `deliveryId`, build payload, compute signature, POST to URL.
4. Log result. If failed, schedule retry with backoff.

## Relationships

```
Workspace 1──* Webhook (workspaceId)
Webhook 1──* DeliveryLog (webhookId)
```

## Dependencies

- Webhooks consume events from the EventBus (see realtime-events.md).
- Only `admin`/`owner` can manage webhooks (see rbac-system.md).
- Webhook CRUD is recorded in the audit log (see audit-logging.md).

## Edge Cases

- Inactive webhooks (`active: false`) skip delivery entirely; no DeliveryLog created.
- Unreachable URLs after 3 attempts are not auto-deactivated; admins must monitor.
- Payloads exclude sensitive data. The `secret` is never returned in API responses.
- Deleting a webhook preserves its DeliveryLog records.
- Maximum 10 webhooks per workspace.
