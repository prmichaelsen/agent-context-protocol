Add a notification service that listens to events and a retry mechanism for failed handlers.

**1. Notification service**

Create a notification module that subscribes to events and stores notifications:

- On `order.created` — Store notification: `"Order {orderId} received, total: ${total}"`
- On `order.status.changed` to `shipped` — Store notification: `"Order {orderId} has shipped"`
- On `order.status.changed` to `delivered` — Store notification: `"Order {orderId} delivered"`
- On `order.status.changed` to `cancelled` — Store notification: `"Order {orderId} cancelled, inventory restored"`

**2. Notification API**

- `GET /notifications` — List all notifications, newest first. Each notification should have: `id`, `message`, `timestamp`, `eventName`.

**3. Retry logic in EventBus**

Enhance the EventBus to support retry on handler failure:
- If a handler throws an error, retry up to 3 times
- Use exponential backoff: 100ms, 200ms, 400ms between retries
- After 3 failed retries, log the failure and continue (don't crash)
- Add a `GET /events/failures` endpoint showing failed event handlers with error messages

**4. Tests**

Add tests for:
- Notifications are created when orders are placed and status changes
- GET /notifications returns correct notifications in order
- Retry logic: create a handler that fails twice then succeeds (verify it retries)
- Retry exhaustion: handler that always fails (verify it doesn't crash, failure is logged)

All existing tests must still pass.