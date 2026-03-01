Add end-to-end integration tests and comprehensive documentation.

**1. Integration tests**

Create an integration test file that tests the complete order lifecycle:

1. Create 2 products (Widget $10, Gadget $25)
2. Set inventory (Widget: 100, Gadget: 50)
3. Create a cart
4. Add 3 Widgets and 2 Gadgets to cart
5. Verify cart total is $80
6. Place an order from the cart
7. Verify inventory decremented (Widget: 97, Gadget: 48)
8. Verify cart is cleared
9. Transition order: pending → confirmed → processing → shipped → delivered
10. Verify each status transition creates a notification
11. Verify GET /notifications shows all expected notifications
12. Verify GET /events/log shows all published events

Also test the cancellation flow:
1. Create another order
2. Transition to confirmed
3. Cancel the order
4. Verify inventory is restored
5. Verify cancellation notification exists

**2. README.md**

Create a comprehensive README with:
- Project description (order processing pipeline)
- Setup instructions (`npm install`, `npm start`, `npm test`)
- Architecture overview explaining the event-driven design
- Event flow diagram in ASCII/text showing how events connect modules
- Complete API documentation for all endpoints (products, inventory, cart, orders, notifications, events)
- A section titled "Architecture Evolution" explaining:
  - The original synchronous design
  - Why it was refactored to event-driven
  - Benefits of the new architecture (decoupling, extensibility, debugging via event log)
  - How the EventBus works internally

All tests (unit + integration) must pass.