Create a Node.js/Express application scaffold with the following:

Requirements:
- Initialize a new Node.js project with `npm init -y`
- Install Express and any basic middleware you need (e.g., body-parser/express.json)
- Create the following directory structure:
  ```
  src/
  ├── index.js          # Main entry point, Express app setup
  ├── middleware/        # Custom middleware directory
  └── routes/           # Route handlers directory
  ```

Endpoints (all public for now):
1. `GET /health` — Returns `{ "status": "ok" }` with status 200
2. `GET /public` — Returns `{ "message": "This is a public endpoint" }` with status 200

Server configuration:
- Listen on port 3000 (or `process.env.PORT`)
- Use `express.json()` middleware for parsing JSON bodies
- Add a simple request logger middleware that logs `METHOD PATH` for each request

Add scripts to package.json:
- `"start": "node src/index.js"`

Start the server and verify both endpoints work with curl.
