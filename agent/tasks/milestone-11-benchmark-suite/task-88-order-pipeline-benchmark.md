# Task 88: Event-Driven Order Pipeline Benchmark Task

**Milestone**: M11 - ACP Benchmark Suite  
**Estimated Time**: 4-6 hours  
**Dependencies**: Task 79 (runner must support multi-turn steps)  
**Status**: Not Started  

---

## Objective

Create the `order-pipeline` benchmark task — a 7-step benchmark that builds an order processing system, then requires a mid-stream architectural pivot from synchronous to event-driven. This tests whether ACP's planning approach helps agents make better architectural decisions and manage complex refactors that invalidate earlier assumptions.

---

## Context

This benchmark is designed to test architectural decision-making under evolving requirements. The agent starts by building a straightforward synchronous order system, then is asked to refactor it to event-driven — a common real-world scenario where initial architecture doesn't scale. The pivot step is intentionally disruptive: it forces rethinking module boundaries, data flow, and error handling.

Key challenge areas:
- State machine design (order lifecycle)
- Multiple interacting modules (catalog, cart, orders, inventory, notifications)
- Concurrency concerns (inventory race conditions)
- Architectural pivot mid-project (sync → event-driven)
- Error recovery and retry logic
- Integration testing across modules

---

## Steps

### 1. Create Directory Structure
```
agent/benchmarks/suite/order-pipeline/
├── config.yaml
├── steps/
│   ├── 01-catalog-inventory.md
│   ├── 02-cart-orders.md
│   ├── 03-order-state-machine.md
│   ├── 04-tests.md
│   ├── 05-event-driven-refactor.md
│   ├── 06-notifications-retry.md
│   └── 07-integration-docs.md
└── expected/
    └── structure.yaml
```

### 2. Define config.yaml
- name: order-pipeline
- description: Build an order processing pipeline, then refactor from synchronous to event-driven architecture
- complexity: complex
- domain: backend/architecture
- timeout_minutes: 60
- max_turns: 50
- 7 steps with phases

### 3. Write Step Prompts

- **01-catalog-inventory.md**: "Build a Node.js/Express application with two modules: 1) Product Catalog — GET /products (list all), GET /products/:id (get one), POST /products (create with name, price, description). 2) Inventory — tracks stock quantities per product, GET /inventory/:productId (check stock), PUT /inventory/:productId (set stock level). Use an in-memory store. Include input validation."

- **02-cart-orders.md**: "Add shopping cart and order modules: 1) Cart — POST /cart (create cart, returns cartId), POST /cart/:cartId/items (add item with productId and quantity), GET /cart/:cartId (get cart with items and total price), DELETE /cart/:cartId/items/:productId (remove item). Cart should validate that products exist and have sufficient inventory. 2) Orders — POST /orders (create order from cartId — validates inventory, decrements stock, clears cart, returns order with total). GET /orders/:id (get order details)."

- **03-order-state-machine.md**: "Implement an order state machine with these states: pending → confirmed → processing → shipped → delivered. Also support: pending → cancelled, processing → cancelled (with inventory restoration). Add: PUT /orders/:id/status (transition to next state with validation — can't skip states, can't go backwards). Each transition should be timestamped. GET /orders/:id should show full status history."

- **04-tests.md**: "Add comprehensive tests for the entire system: product CRUD, inventory management, cart operations (add/remove/validate stock), order creation (stock decrement, cart clearing), state machine transitions (valid and invalid), and edge cases (order from empty cart, insufficient stock, double-order same cart, cancel after shipping). All tests must pass."

- **05-event-driven-refactor.md**: "The synchronous architecture won't scale. Refactor to an event-driven architecture: 1) Create an EventBus module (in-process pub/sub with subscribe/publish/unsubscribe). 2) Order creation should now publish 'order.created' event. 3) Inventory decrement should happen via an event handler listening for 'order.created', not inline. 4) State transitions should publish 'order.status.changed' events. 5) All existing API endpoints must still work identically. 6) Add GET /events/log (returns recent events for debugging)."

- **06-notifications-retry.md**: "Add a notification service that listens to events: 1) On 'order.created' — log/store a notification: 'Order {id} received'. 2) On 'order.status.changed' to 'shipped' — notification: 'Order {id} has shipped'. 3) On 'order.status.changed' to 'cancelled' — notification: 'Order {id} cancelled, stock restored'. 4) Add GET /notifications (list all notifications). 5) Add retry logic: if a handler throws, retry up to 3 times with exponential backoff. Add a test for retry behavior."

- **07-integration-docs.md**: "Add: 1) Integration tests that test the full flow end-to-end: create products → set inventory → build cart → place order → transition through states → verify notifications at each stage. 2) A README.md with: architecture overview, event flow diagram (text/ASCII), all API endpoints, setup instructions, and a section explaining the sync-to-event-driven migration and why it was done."

### 4. Define Expected Structure
- Expected dirs: src/ or routes/, events/ or eventbus/, models/ or store/, notifications/, tests/
- Expected files: package.json, event bus module, notification service, tests/, README.md
- Key: EventBus module must exist (proves refactor happened)

### 5. Add Verification to verify.sh
- Add `verify_order_pipeline()` function
- Checks: structure_match, tests_pass, server_starts, product_crud_works, order_flow_works, event_bus_exists, notifications_work, readme_exists

---

## Verification

- [ ] config.yaml valid with 7 steps
- [ ] Step prompts build progressively and introduce architectural pivot at step 5
- [ ] Step 5 explicitly requires maintaining API compatibility post-refactor
- [ ] Event-driven architecture requires non-trivial design decisions
- [ ] Retry logic in step 6 tests error handling sophistication
- [ ] Integration test in step 7 validates the full pipeline
- [ ] expected/structure.yaml covers event-driven modules
- [ ] verify.sh has verify_order_pipeline() function

---

**Related Design Docs**: agent/design/local.benchmark-suite.md  
