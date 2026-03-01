Add a comprehensive test suite for the entire order processing system.

Install a test framework (Jest or Mocha) and supertest. Add a `test` script to package.json.

**Product tests:**
- Create product with valid data (201)
- Create product with missing name (400)
- Create product with negative price (400)
- List all products
- Get product by ID
- Get non-existent product (404)

**Inventory tests:**
- Set stock level for a product
- Get stock level
- Set stock to 0 (valid)
- Set negative stock (400)
- Get stock for non-existent product (404)

**Cart tests:**
- Create a new cart
- Add item to cart
- Add item with insufficient stock (400)
- Add same product twice (quantity should increment)
- Remove item from cart
- Get cart with correct total price calculation

**Order tests:**
- Create order from cart (stock decremented, cart cleared)
- Create order from empty cart (400)
- Create order with insufficient stock (400)
- Cannot reuse a cart for a second order

**State machine tests:**
- Valid transition sequence: pending → confirmed → processing → shipped → delivered
- Invalid skip: pending → shipped (400)
- Invalid backward: shipped → processing (400)
- Cancel from pending (no inventory change)
- Cancel from processing (inventory restored)
- Cannot cancel after shipped (400)
- Cannot transition from delivered (400)

**Edge cases:**
- Order from cart where stock changed between cart add and order creation
- Multiple orders reducing inventory correctly

All tests must pass. Run the test suite to verify.