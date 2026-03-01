Implement an order state machine with the following lifecycle:

**States and valid transitions:**
```
pending → confirmed → processing → shipped → delivered
pending → cancelled
confirmed → cancelled
processing → cancelled (must restore inventory)
```

**Invalid transitions** (should return 400):
- Cannot skip states (e.g., pending → shipped)
- Cannot go backwards (e.g., shipped → processing)
- Cannot transition from delivered or cancelled (terminal states)
- Cannot cancel after shipped or delivered

**API:**

- `PUT /orders/:id/status` — Transition an order to a new state. Body: `{ "status": "confirmed" }`.
  - Validates the transition is allowed from the current state.
  - Records a timestamp for each transition.
  - If cancelling an order that was confirmed or processing, restore the inventory quantities.
  - Returns the updated order.
  - Returns 400 for invalid transitions with a clear error message explaining why.
  - Returns 404 if order not found.

- `GET /orders/:id` — Update this endpoint to include a `statusHistory` array showing all transitions with timestamps:
  ```json
  {
    "id": "...",
    "status": "processing",
    "statusHistory": [
      { "status": "pending", "timestamp": "..." },
      { "status": "confirmed", "timestamp": "..." },
      { "status": "processing", "timestamp": "..." }
    ],
    "items": [...],
    "total": 99.99
  }
  ```

Requirements:
- State transitions must be validated strictly
- Inventory restoration on cancellation must be accurate
- Each transition must be timestamped