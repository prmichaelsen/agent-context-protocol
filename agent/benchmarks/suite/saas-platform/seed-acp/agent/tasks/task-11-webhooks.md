# Task 11: Webhook Integration

**Status:** not_started
**Milestone:** M3 — Production Hardening
**Estimated Hours:** 3
**Depends On:** task-8

## Objective

Implement a webhook system that allows workspaces to register external
URLs to receive event notifications. Includes HMAC signature verification,
retry logic, and delivery tracking.

## Requirements

- Create Webhook model:
  - Fields: id, workspaceId, url, secret, events (array of event types), active, createdAt, updatedAt
  - Secret auto-generated on creation for HMAC signing
- Implement Webhook CRUD:
  - POST /workspaces/:id/webhooks — Register webhook (admin+ only)
  - GET /workspaces/:id/webhooks — List webhooks (admin+ only)
  - GET /workspaces/:id/webhooks/:webhookId — Get webhook details
  - PUT /workspaces/:id/webhooks/:webhookId — Update webhook
  - DELETE /workspaces/:id/webhooks/:webhookId — Delete webhook
- Event delivery:
  - Listen to EventBus for matching events
  - POST event payload to registered webhook URL
  - Include HMAC-SHA256 signature in X-Webhook-Signature header
  - Sign the raw JSON body with the webhook secret
  - Include X-Webhook-Event header with event type
  - Include X-Webhook-Delivery header with unique delivery ID
- Retry with exponential backoff:
  - Retry on non-2xx responses or network errors
  - Max 3 retries with delays: 10s, 60s, 300s
  - Mark webhook as inactive after consecutive failures (e.g., 10)
- Create WebhookDelivery model:
  - Fields: id, webhookId, event, payload, statusCode, responseBody (truncated), success, attempts, deliveredAt
  - GET /workspaces/:id/webhooks/:webhookId/deliveries — Delivery log (paginated)

## Key Files

- `src/models/webhook.js` — New webhook model
- `src/models/webhook-delivery.js` — New delivery log model
- `src/services/webhook-service.js` — Webhook delivery, signing, retries
- `src/routes/webhooks.js` — Webhook management endpoints
- `src/services/event-bus.js` — Hook into event system

## Acceptance Criteria

- [ ] Webhook CRUD endpoints functional (admin+ only)
- [ ] Events delivered to registered URLs via HTTP POST
- [ ] HMAC-SHA256 signature included and verifiable
- [ ] Failed deliveries retried with exponential backoff
- [ ] Webhook auto-disabled after consecutive failures
- [ ] Delivery log tracks all attempts with status codes
- [ ] Only subscribed event types trigger delivery

## References

- `agent/design/webhook-system.md` — Webhook design and signing spec
- `agent/patterns/event-patterns.md` — Event types and payloads
