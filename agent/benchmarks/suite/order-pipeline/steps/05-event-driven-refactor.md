The synchronous architecture won't scale. Refactor the application to use an event-driven architecture.

**1. Create an EventBus module**

Create an in-process publish/subscribe event bus (no external dependencies needed):
- `publish(eventName, data)` — Emit an event to all subscribers
- `subscribe(eventName, handler)` — Register a handler for an event
- `unsubscribe(eventName, handler)` — Remove a handler
- The EventBus should maintain a log of all published events (for debugging)

**2. Refactor order creation to use events**

When an order is created:
- Publish an `order.created` event with the order data
- Inventory decrement should happen via an event handler that listens for `order.created`, NOT inline in the order creation code
- The order route should publish the event, and the inventory module should subscribe to it

**3. Refactor state transitions to use events**

When an order status changes:
- Publish an `order.status.changed` event with `{ orderId, fromStatus, toStatus, timestamp }`
- Inventory restoration on cancellation should happen via an event handler for `order.status.changed`, not inline

**4. Add event log endpoint**

- `GET /events/log` — Returns the list of recent events (last 100) with timestamps, event names, and data

**5. API compatibility**

All existing API endpoints MUST still work identically. The refactor changes internal architecture only — external behavior is unchanged. All existing tests must still pass.

Requirements:
- EventBus must be a separate module (e.g., `events/event-bus.js`)
- Handlers must be registered during app startup
- Event log must persist in memory for debugging
- No external event libraries — implement the pub/sub pattern from scratch