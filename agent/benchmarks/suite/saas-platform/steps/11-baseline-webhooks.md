Implement webhook integration:

1. Webhook model: { id, workspaceId, url, events (array of event types to subscribe to), secret, active (default true), createdAt, updatedAt }
2. CRUD endpoints: POST/GET/PUT/DELETE /workspaces/:id/webhooks (admin+ role required)
3. When an event occurs that matches a webhook's subscribed events:
   - Create delivery payload: { event, data, timestamp, webhookId, deliveryId }
   - Sign payload with HMAC-SHA256 using the webhook's secret
   - POST to webhook URL with payload as JSON body and X-Webhook-Signature header
4. Retry failed deliveries: 3 attempts with exponential backoff (1s, 5s, 25s delays)
5. DeliveryLog model: { id, webhookId, deliveryId, event, statusCode, success, attemptNumber, timestamp }
6. Add GET /workspaces/:id/webhooks/:webhookId/deliveries to view delivery history
7. Skip delivery for inactive webhooks
