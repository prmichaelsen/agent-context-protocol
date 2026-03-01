Add shopping cart and order modules to the application.

**1. Shopping Cart**

- `POST /cart` — Create a new empty cart. Returns `{ "cartId": "...", "items": [], "total": 0 }` with status 201.
- `POST /cart/:cartId/items` — Add an item to cart. Body: `{ "productId": "...", "quantity": N }`.
  - Validate: product must exist, quantity must be > 0, product must have sufficient inventory.
  - If product is already in cart, increment the quantity.
  - Returns updated cart with items and calculated total price.
  - Returns 400 if validation fails, 404 if cart or product not found.
- `GET /cart/:cartId` — Get cart contents with items and total price. Returns 404 if cart not found.
- `DELETE /cart/:cartId/items/:productId` — Remove an item from cart. Returns updated cart. Returns 404 if cart or item not found.

**2. Orders**

- `POST /orders` — Create an order from a cart. Body: `{ "cartId": "..." }`.
  - Validate: cart must exist and not be empty.
  - For each item in cart: validate inventory is still sufficient, then decrement stock.
  - Create order with items, total, and status "pending".
  - Clear the cart after successful order creation.
  - Returns the created order with status 201.
  - Returns 400 if cart is empty or insufficient stock.
- `GET /orders/:id` — Get order details. Returns 404 if not found.
- `GET /orders` — List all orders.

Requirements:
- Cart total should be calculated from product prices * quantities
- Inventory must be decremented atomically when order is placed
- A cart cannot be used to create a second order after it has been used