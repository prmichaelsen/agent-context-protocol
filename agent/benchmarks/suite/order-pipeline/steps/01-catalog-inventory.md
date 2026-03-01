Build a Node.js/Express application for an e-commerce order processing system. Start with two modules:

**1. Product Catalog**

- `POST /products` — Create a product with `name` (string, required), `price` (number, required, > 0), and `description` (string, optional). Returns the created product with a generated `id`. Status 201.
- `GET /products` — List all products. Returns an array.
- `GET /products/:id` — Get a single product by ID. Returns 404 if not found.

**2. Inventory**

- `GET /inventory/:productId` — Check stock for a product. Returns `{ "productId": "...", "quantity": N }`. Returns 404 if product doesn't exist.
- `PUT /inventory/:productId` — Set stock level. Body: `{ "quantity": N }`. Quantity must be >= 0. Returns updated inventory. Returns 404 if product doesn't exist.

Requirements:
- Use in-memory stores (no database needed)
- Add input validation: reject missing required fields with 400 status
- Price must be a positive number
- Quantity must be a non-negative integer
- Add `GET /health` endpoint returning `{ "status": "ok" }`
- Structure the code with separate route files (e.g., `routes/products.js`, `routes/inventory.js`)
- Add a `start` script to package.json

Initialize the project with `npm init -y` and install Express.