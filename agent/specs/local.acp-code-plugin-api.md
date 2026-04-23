# Spec: acp-code PluginAPI Contract

**Namespace**: local  
**Version**: 1.0.0  
**Created**: 2026-04-23  
**Last Updated**: 2026-04-23  
**Status**: Draft  

---

## Purpose

Define the contract between the acp-code framework and plugins: the `PluginAPI` capability object received at activation, the `PluginContext` lifecycle object, the four plugin lifecycle hooks, and the guarantees and restrictions each side commits to. Once implemented, a plugin author can write `activate(api, context)` against a stable, testable interface without caring how the framework loads them.

---

## Source

- **Mode**: `design`
- **File**: `agent/design/local.acp-code-design.md`

---

## Scope

### In Scope

- Shape of the `PluginAPI` capability object (attributes, methods, scoping rules)
- Shape of the `PluginContext` lifecycle object
- The four plugin lifecycle hooks: `install`, `activate`, `deactivate`, `uninstall` (signatures, invocation timing, invocation count guarantees)
- Identity binding: how the framework stamps plugin name and version onto writes so plugins cannot forge records as other plugins
- Table namespacing enforcement (`<plugin_name>__<table_name>` prepend)
- Event write path contract (only via `api.events.record`)
- Cross-plugin interop boundary (private tables, commands as the only cross-plugin path)
- Scoped query contract for `api.query_readonly`
- Disposable-based cleanup via `PluginContext.subscriptions`

### Out of Scope

- **Plugin loading mechanics** — how the framework discovers and instantiates plugins from `~/.acp/plugins/`
- **Migration runner behavior** — covered by a separate migration spec (referenced via `api.register_table`)
- **Event schema, `events.jsonl` format, replay semantics** — covered by a separate events-system spec
- **MCP adapter translation** — how `register_command` contributions surface as MCP tools is covered in the adapter spec
- **Plugin author install logic** — what `install()` does internally (brew calls, downloads) is plugin-author concern
- **Core modules (`tasks`, `progress`)** — these are not plugins; their internal contract is out of scope
- **UI / visualizer consumption** — read paths into plugin data belong to `acp-code-viz`, not this contract

---

## Requirements

1. **R1** — Plugins receive a `PluginAPI` instance as the first argument to `install`, `activate`, and `uninstall` hooks. Plugins never construct `PluginAPI` themselves; the framework instantiates it and passes it in.

2. **R2** — The `PluginAPI` instance has immutable `name: str` and `version: str` attributes bound at framework-side construction. Attempting to mutate either raises `AttributeError`.

3. **R3** — `api.db` is a read-write SQLite connection object whose write operations are permitted **only** against tables with physical name `<api.name>__*`. Attempts to `CREATE`, `ALTER`, `DROP`, `INSERT INTO`, `UPDATE`, or `DELETE FROM` any table not matching that prefix raise `PermissionError` from the framework write-wrapper without reaching SQLite.

4. **R4** — `api.query_readonly(sql: str, params: tuple = ()) -> list[Row]` executes read-only queries scoped to the plugin's own tables. Queries referencing any table not matching `<api.name>__*` raise `PermissionError`. The connection underneath is opened with SQLite `mode=ro`.

5. **R5** — `api.register_table(name: str, migrations: list[Migration]) -> None` creates a table whose physical name is `<api.name>__<name>` and applies all supplied migrations in order. The `name` argument is a logical name (e.g. `"tasks"`); the plugin cannot supply a fully-qualified name and cannot bypass the prefix. There is no other API path that executes DDL.

6. **R6** — `api.register_command(name: str, handler: Callable, mcp_description: str) -> None` registers a command addressable across the system as `<api.name>.<name>`. The handler is callable by (a) other plugins via `api.call_command(...)`, (b) the MCP adapter as a tool, (c) the CLI adapter as a subcommand, (d) the REST adapter as an endpoint. Registering the same `name` twice within one plugin raises `ValueError`.

7. **R7** — `api.register_event_handler(event_kind: str, handler: Callable) -> None` subscribes a handler to one of the four closed-enum event kinds (`state_transition`, `edit`, `automation`, `custom`). The handler is invoked synchronously for every event matching the kind, regardless of which plugin emitted the event.

8. **R8** — `api.events.record(kind, entities, op, before, after, meta) -> str` is the **only** write path to `events.jsonl`. The framework auto-stamps `id` (UUIDv7), `ts` (ISO-8601 UTC), `plugin_name` (equal to `api.name`), and `plugin_version` (equal to `api.version`). The returned `str` is the event `id`. Any plugin-supplied values for `id`, `ts`, `plugin_name`, or `plugin_version` (e.g. in `meta`) are ignored and overwritten.

9. **R9** — `api.config.get(key: str, default: Any = None) -> Any` reads plugin-scoped configuration (keyed by `api.name`). Missing keys return `default`. The returned value is never shared across plugins.

10. **R10** — `api.logger` is a `logging.Logger` instance named `acp_code.plugin.<api.name>`. All emitted records include `api.name` in the logger name hierarchy.

11. **R11** — `PluginContext` has a single mutable attribute `subscriptions: list[Disposable]`. Plugins append disposables during `install` / `activate`; the framework calls `.dispose()` on each in **reverse insertion order** during `deactivate` / `uninstall`. A disposable raising during `.dispose()` does not prevent subsequent disposables from being disposed; the exception is logged and collection continues.

12. **R12** — Plugins implement four lifecycle hooks as module-level functions:
    - `install(api: PluginAPI, context: PluginContext) -> None` — called exactly once per install, before any activate.
    - `activate(api: PluginAPI, context: PluginContext) -> None` — called at most once per session, lazily on first invocation of any contributed command or matching event.
    - `deactivate(context: PluginContext) -> None` — called exactly once per session if and only if `activate` completed successfully.
    - `uninstall(api: PluginAPI, context: PluginContext) -> None` — called exactly once per uninstall, after `deactivate` if the plugin is currently active.
    
    Any hook may be omitted; the framework treats a missing hook as a no-op.

13. **R13** — Activation is **lazy**: successful `install` does not trigger `activate`. The first call to any contributed command (`<api.name>.*`) or delivery of any event the plugin subscribed to triggers `activate`; subsequent calls/events find the plugin already activated.

14. **R14** — Registration methods (`register_table`, `register_command`, `register_event_handler`) are only callable during `install` or `activate`. Calling them during `deactivate` or `uninstall`, or from within a command handler after activation has completed, raises `RuntimeError`.

---

## Behavior Table

| # | Scenario | Expected Behavior | Tests |
|---|----------|-------------------|-------|
| 1 | Plugin's `install` hook calls `api.register_table("tasks", migrations=[m1])` | Physical table `myplugin__tasks` exists; migration `m1` recorded as applied | `register-table-creates-namespaced-table`, `register-table-records-migration` |
| 2 | Plugin calls `api.register_command("sync", handler, mcp_description="…")` during `activate` | Command callable as `myplugin.sync` from CLI, MCP, REST, and other plugins | `register-command-available-cross-adapter` |
| 3 | Plugin calls `api.events.record(kind="edit", entities=[...], op="task.update", before=..., after=..., meta={})` | Event appended to `events.jsonl` with framework-stamped `id`, `ts`, `plugin_name=myplugin`, `plugin_version=1.0.0` | `events-record-autostamps-identity`, `events-record-returns-uuid7` |
| 4 | Plugin subscribes to `state_transition` via `register_event_handler`; another plugin emits a matching event | Subscriber handler invoked synchronously with the event | `event-handler-invoked-on-matching-kind` |
| 5 | Plugin calls `api.query_readonly("SELECT * FROM myplugin__tasks")` | Returns rows from its own table | `query-readonly-reads-own-table` |
| 6 | Plugin is first invoked via `@myplugin.foo` after install | `activate()` runs exactly once, then the command handler runs | `lazy-activation-on-first-command`, `activate-not-called-on-install` |
| 7 | Session ends after plugin was activated | `deactivate()` runs exactly once; context subscriptions disposed in LIFO order | `deactivate-runs-once`, `subscriptions-disposed-in-reverse-order` |
| 8 | User runs `@acp.plugin-uninstall myplugin` | `deactivate` runs (if active), then `uninstall`; plugin's tables and subscribed events are cleaned per plugin's hook | `uninstall-after-deactivate`, `uninstall-called-once` |
| 9 | Plugin A calls `api.query_readonly("SELECT * FROM pluginb__tasks")` | Raises `PermissionError` before reaching SQLite | `query-readonly-rejects-cross-plugin-read` |
| 10 | Plugin A issues raw SQL `api.db.execute("INSERT INTO pluginb__tasks VALUES (…)")` | Raises `PermissionError` from the write-wrapper | `db-write-rejects-cross-plugin-write` |
| 11 | Plugin attempts to set `api.name = "otherplugin"` | Raises `AttributeError`; `api.name` unchanged | `plugin-identity-immutable` |
| 12 | Plugin calls `api.events.record(...)` with `meta={"plugin_name": "otherplugin"}` | Event written with `plugin_name=<api.name>`; the meta value is ignored/overwritten | `events-record-rejects-forged-identity` |
| 13 | Plugin calls `api.register_table("valid-name")` where framework builds `myplugin__valid-name` | Table created; physical name is `myplugin__valid-name` | `register-table-creates-namespaced-table` |
| 14 | Plugin executes `api.db.execute("CREATE TABLE myplugin__rogue(…)")` directly via the raw connection | Raises `PermissionError` — DDL is never permitted through `api.db`; `register_table` is the only DDL path | `db-write-rejects-raw-ddl` |
| 15 | Plugin calls `api.register_command` from within a command handler (after activation) | Raises `RuntimeError` — registration is install/activate-phase only | `register-command-rejected-after-activation` |
| 16 | Plugin is installed but never invoked | `install()` ran; `activate()` has NOT been called; no resources held | `activate-not-called-on-install` |
| 17 | `register_command("sync", ...)` called twice within one plugin's activate | Second call raises `ValueError("duplicate command: sync")` | `register-command-rejects-duplicate-name` |
| 18 | Disposable at index 2 of three raises during `.dispose()` | Remaining disposables (index 1, index 0) still have `.dispose()` called; the exception is logged | `disposable-exception-does-not-halt-cleanup` |
| 19 | Plugin's `install` hook raises | Install marked failed; `activate` never called for this plugin; framework reports the error | `install-failure-prevents-activate` |
| 20 | Plugin's `activate` hook raises | `undefined` | → [OQ-1](#open-questions) |
| 21 | Two command invocations race on the first-access of an un-activated plugin | `undefined` | → [OQ-2](#open-questions) |
| 22 | Plugin calls `api.db.execute("INSERT …")` and immediately `api.events.record(...)` and the latter raises | `undefined` — atomicity of DB write + event is not specified | → [OQ-3](#open-questions) |
| 23 | Plugin calls `register_command("Sync", …)` and `register_command("sync", …)` within one plugin | `undefined` — case-sensitivity of command names | → [OQ-4](#open-questions) |
| 24 | Plugin calls `register_table("tasks", migrations=[m1])` in `install`, then again on a later install call with identical args | `undefined` — whether `register_table` is idempotent across invocations | → [OQ-5](#open-questions) |

---

## Interfaces / Data Shapes

```python
# Framework-provided objects (plugins receive, never construct)

class PluginAPI:
    # Immutable identity (frozen dataclass or via __setattr__ guard)
    name: str
    version: str

    # Scoped resources
    db: WriteScopedConnection        # read-write, prefix-enforced
    logger: logging.Logger           # named acp_code.plugin.<name>

    # Read path
    def query_readonly(self, sql: str, params: tuple = ()) -> list[Row]: ...

    # Registration (callable only during install/activate phases)
    def register_table(self, name: str, migrations: list[Migration]) -> None: ...
    def register_command(self, name: str, handler: Callable, mcp_description: str) -> None: ...
    def register_event_handler(self, event_kind: EventKind, handler: Callable) -> None: ...

    # Cross-plugin command invocation
    def call_command(self, qualified_name: str, *args, **kwargs) -> Any: ...
    #   qualified_name matches "<plugin_name>.<command_name>"

    # Nested surfaces
    events: "EventAPI"
    config: "ConfigAPI"


class EventAPI:
    def record(
        self,
        kind: EventKind,                             # "state_transition"|"edit"|"automation"|"custom"
        entities: list[EntityRef],                    # [{"type": str, "id": str}, ...]
        op: str,                                      # e.g. "task.complete"
        before: dict | None,
        after: dict | None,
        meta: dict,
    ) -> str: ...
    # Returns UUIDv7 event id.
    # Framework-stamped fields (id, ts, plugin_name, plugin_version) are overwritten
    # if the plugin supplies them.


class ConfigAPI:
    def get(self, key: str, default: Any = None) -> Any: ...


@dataclass
class PluginContext:
    subscriptions: list[Disposable]                   # plugin appends; framework disposes LIFO


class Disposable(Protocol):
    def dispose(self) -> None: ...


# Plugin-provided hooks (plugins define these at module level)

def install(api: PluginAPI, context: PluginContext) -> None: ...
def activate(api: PluginAPI, context: PluginContext) -> None: ...
def deactivate(context: PluginContext) -> None: ...
def uninstall(api: PluginAPI, context: PluginContext) -> None: ...
```

### `WriteScopedConnection` behavior

A thin wrapper around `sqlite3.Connection`. Before executing any statement, it parses the SQL (using `sqlglot` or equivalent) and verifies every mutated or created table starts with `<plugin_name>__`. Rejection raises `PermissionError` before the statement reaches SQLite. `SELECT` statements through `db.execute()` are permitted on own tables but `query_readonly` is the preferred read path.

### `EventKind` enum

```python
class EventKind(str, Enum):
    STATE_TRANSITION = "state_transition"
    EDIT = "edit"
    AUTOMATION = "automation"
    CUSTOM = "custom"
```

---

## Behavior

1. **Framework load** — framework reads the plugin's `plugin.yaml`, validates manifest, and resolves plugin dependencies.
2. **First install** — framework calls `install(api, context)` with a freshly-constructed `PluginAPI` whose `name`/`version` come from the manifest. The plugin registers tables (migrations run during this call), appends any install-phase disposables to `context.subscriptions`, and performs one-time setup.
3. **Install persistence** — framework records that `install` completed successfully. No `activate` call is made at this point.
4. **Session start** — framework comes up. It does not activate installed plugins.
5. **First contributed-command invocation** — someone calls `<plugin_name>.<command>` (via CLI, MCP, REST, or `api.call_command`). Framework checks: is this plugin activated in this session? If no, call `activate(api, context)` — same `api`/`context` shape as install-phase — then route the call to the registered handler.
6. **First subscribed-event delivery** — same as step 5 but triggered by an event matching a subscribed `event_kind`.
7. **Subsequent invocations** — plugin is already activated; command handlers and event handlers run directly.
8. **`events.record` call** — wrapper constructs the full event (auto-stamping `id`, `ts`, `plugin_name`, `plugin_version`), appends a line to `events.jsonl` (with fsync), writes to the in-memory events mirror used by `query_readonly` callers (not cross-plugin — events table is framework-owned and readable via a separate framework API, not via plugin APIs), and returns the `id`.
9. **Session end** — framework calls `deactivate(context)` for every plugin whose `activate` ran in this session. Disposables dispose in reverse insertion order. Exceptions during individual disposals are logged, not propagated.
10. **Uninstall** — user runs `@acp.plugin-uninstall <name>`. If the plugin is active, framework calls `deactivate(context)` first. Then framework calls `uninstall(api, context)`. After the hook returns, framework removes the plugin's install directory. Dropping plugin-owned tables is the plugin's responsibility in its `uninstall` hook (with user confirmation for irreversible data loss, per the plugin author's discretion).

---

## Acceptance Criteria

- [ ] `PluginAPI.name` and `PluginAPI.version` are immutable — reassignment raises `AttributeError`.
- [ ] `api.register_table("x", [m])` creates a table named exactly `<plugin_name>__x`; the plugin cannot create any table whose name does not start with `<plugin_name>__`.
- [ ] Raw SQL via `api.db.execute` rejecting `CREATE`/`ALTER`/`DROP`/`INSERT`/`UPDATE`/`DELETE` on tables outside the plugin's prefix with `PermissionError` before the statement reaches SQLite.
- [ ] `api.query_readonly` rejects SQL referencing any table outside the plugin's prefix with `PermissionError`.
- [ ] `api.events.record(...)` writes exactly one line to `events.jsonl`; the line is valid JSON with framework-stamped `id` (UUIDv7), `ts` (ISO-8601), `plugin_name` (`== api.name`), and `plugin_version` (`== api.version`), overriding any plugin-supplied values for those fields.
- [ ] `activate(api, context)` is called at most once per session, on first contributed-command invocation or subscribed-event delivery. `activate` is not called during `install`.
- [ ] `deactivate(context)` is called exactly once per session IFF `activate` completed successfully; disposables are disposed in reverse insertion order; a raising disposable is logged and does not prevent subsequent disposals.
- [ ] `uninstall(api, context)` runs after `deactivate` (if plugin was active) and before the install directory is removed.
- [ ] Registration methods raise `RuntimeError` if called outside install/activate phases.
- [ ] `register_command` called twice with the same `name` within one plugin raises `ValueError`.

---

## Tests

### Base Cases

#### Test: register-table-creates-namespaced-table (covers R5, happy path, positive)

**Given**: A fresh project with plugin `myplugin` v1.0.0 installed but not yet activated; `myplugin__tasks` does not exist.  
**When**: Framework calls `install(api, context)`; plugin calls `api.register_table("tasks", migrations=[CreateTasksTable])`.  
**Then** (assertions):
- **physical-table-exists**: SQLite schema contains a table named exactly `myplugin__tasks`.
- **no-unprefixed-table**: No table named `tasks` exists at the bare name.
- **migration-recorded**: Framework's `_migrations` table contains a row with `plugin_name="myplugin"`, `migration_number=1`.

#### Test: register-table-records-migration (covers R5)

**Given**: Plugin `myplugin` with two migrations `[m1, m2]`.  
**When**: Plugin calls `api.register_table("tasks", migrations=[m1, m2])` during install.  
**Then** (assertions):
- **migrations-applied-in-order**: `m1.up` ran before `m2.up`.
- **both-recorded**: `_migrations` table has two rows for `myplugin`, numbers 1 and 2.
- **up-events-emitted**: Two `automation` events recorded with `op="migration.up"`, `plugin_name="myplugin"`.

#### Test: register-command-available-cross-adapter (covers R6, happy path)

**Given**: Plugin `myplugin` registered command `sync` with handler `do_sync` during `activate`.  
**When**:
- CLI invokes `acp myplugin.sync`.
- MCP client invokes tool `myplugin.sync`.
- Peer plugin calls `api.call_command("myplugin.sync")`.

**Then** (assertions):
- **handler-invoked-thrice**: `do_sync` was called exactly three times.
- **mcp-tool-advertised**: The MCP adapter's tool list includes `myplugin.sync` with the `mcp_description` supplied to `register_command`.
- **cli-subcommand-available**: Running `acp myplugin.sync --help` prints the command's description and does not error.

#### Test: events-record-autostamps-identity (covers R8, positive)

**Given**: Plugin `myplugin` v1.0.0 activated.  
**When**: Plugin calls `api.events.record(kind="edit", entities=[{"type":"task","id":"t1"}], op="task.update", before={"status":"todo"}, after={"status":"done"}, meta={"foo":"bar"})`.  
**Then** (assertions):
- **one-line-appended**: `events.jsonl` gains exactly one new line.
- **returned-id-matches**: The returned `str` equals the new line's parsed `id` field.
- **id-is-uuid7**: The parsed `id` is a valid UUIDv7 (version nibble = 7).
- **ts-is-iso8601-utc**: The parsed `ts` is a valid ISO-8601 UTC timestamp within 1 second of the wall clock at call time.
- **plugin-name-matches**: The parsed `plugin_name` equals `"myplugin"`.
- **plugin-version-matches**: The parsed `plugin_version` equals `"1.0.0"`.
- **payload-preserved**: `kind`, `entities`, `op`, `before`, `after`, `meta.foo` round-trip unchanged.

#### Test: events-record-returns-uuid7 (covers R8, positive)

**Given**: Plugin is activated.  
**When**: Plugin calls `api.events.record(...)` three times in rapid succession.  
**Then** (assertions):
- **three-distinct-ids**: The three returned ids are distinct.
- **ids-monotonically-ordered**: Sorting the three ids lexicographically yields the same order as call order (UUIDv7 property).

#### Test: event-handler-invoked-on-matching-kind (covers R7, happy path)

**Given**:
- Plugin `myplugin` subscribed to `event_kind="state_transition"` via `register_event_handler(kind, handler)`.
- Plugin is activated.

**When**: Another plugin emits an `api.events.record(kind="state_transition", ...)`.  
**Then** (assertions):
- **handler-called-once**: `handler` invoked exactly once.
- **handler-received-event**: Argument passed to handler is the full event record (id, ts, plugin_name, plugin_version, kind, entities, op, before, after, meta).
- **unrelated-kinds-not-delivered**: If another plugin emits `kind="edit"`, `handler` is not invoked a second time.

#### Test: query-readonly-reads-own-table (covers R4, happy path)

**Given**: Plugin `myplugin` has table `myplugin__tasks` with two rows.  
**When**: Plugin calls `api.query_readonly("SELECT id, status FROM myplugin__tasks ORDER BY id")`.  
**Then** (assertions):
- **returns-two-rows**: Return value has length 2.
- **columns-match**: Each row contains exactly the two requested columns.

#### Test: lazy-activation-on-first-command (covers R13, happy path)

**Given**: Plugin `myplugin` is installed (install hook ran). `activate` has not been called.  
**When**: Someone invokes `@myplugin.sync` for the first time.  
**Then** (assertions):
- **activate-called-once**: `activate(api, context)` was called exactly once immediately before the handler.
- **handler-called-after-activate**: `handler` for `sync` was invoked after `activate` returned.
- **activate-not-re-called-on-second-invoke**: A second invocation of `@myplugin.sync` runs the handler without calling `activate` again.

#### Test: activate-not-called-on-install (covers R13, negative)

**Given**: Plugin `myplugin` has just been added via `@acp.plugin-install`.  
**When**: `install(api, context)` completes successfully and no contributed command has yet been invoked.  
**Then** (assertions):
- **activate-not-called**: The plugin's `activate` hook was not called. (negative)
- **no-activate-disposables**: `context.subscriptions` contains only disposables appended during `install`, none from `activate`.

#### Test: subscriptions-disposed-in-reverse-order (covers R11, happy path)

**Given**: Plugin's `activate` appends disposables `[d1, d2, d3]` to `context.subscriptions` in that order.  
**When**: Session ends and framework calls `deactivate(context)`.  
**Then** (assertions):
- **dispose-order**: `d3.dispose()`, `d2.dispose()`, `d1.dispose()` invoked in that sequence.
- **deactivate-returned**: Framework's deactivate loop returns only after all three disposals complete.

#### Test: deactivate-runs-once (covers R12, happy path)

**Given**: Plugin `myplugin` activated during session, then session ends.  
**When**: Framework shuts down.  
**Then** (assertions):
- **deactivate-called-once**: `deactivate(context)` invoked exactly once.
- **deactivate-not-called-for-inactive-plugin**: A second plugin that was installed but never activated does NOT receive a `deactivate` call. (negative)

#### Test: uninstall-after-deactivate (covers R12, happy path)

**Given**: Plugin `myplugin` is active in session.  
**When**: User invokes `@acp.plugin-uninstall myplugin`.  
**Then** (assertions):
- **deactivate-first**: `deactivate(context)` called before `uninstall(api, context)`.
- **uninstall-called-once**: `uninstall` invoked exactly once.
- **install-dir-removed-after**: The plugin's install directory is removed AFTER `uninstall` returns, not before.

#### Test: plugin-identity-immutable (covers R2, negative)

**Given**: Plugin `myplugin` v1.0.0 is active; it holds a reference to `api`.  
**When**: Plugin executes `api.name = "otherplugin"`.  
**Then** (assertions):
- **attribute-error-raised**: `AttributeError` is raised.
- **name-unchanged**: Reading `api.name` afterward still returns `"myplugin"`.
- **version-immutable-same**: Repeating the test with `api.version = "2.0.0"` also raises `AttributeError`.

#### Test: events-record-rejects-forged-identity (covers R8, negative)

**Given**: Plugin `myplugin` v1.0.0 is active.  
**When**: Plugin calls `api.events.record(kind="edit", entities=[...], op="x", before=None, after=None, meta={"plugin_name": "otherplugin", "plugin_version": "9.9.9"})`.  
**Then** (assertions):
- **record-succeeds**: Call returns a UUIDv7 id (not an error — forging attempts are silently overridden, not rejected).
- **plugin-name-overridden**: Parsed line has `plugin_name="myplugin"`.
- **plugin-version-overridden**: Parsed line has `plugin_version="1.0.0"`.
- **meta-keys-stripped**: The resulting event's `meta` dict does NOT contain `plugin_name` or `plugin_version` keys. (negative)

### Edge Cases

#### Test: query-readonly-rejects-cross-plugin-read (covers R4, negative, edge)

**Given**: Plugins `myplugin` and `otherplugin` both installed; both have tables.  
**When**: `myplugin` calls `api.query_readonly("SELECT * FROM otherplugin__things")`.  
**Then** (assertions):
- **permission-error-raised**: `PermissionError` raised with a message referencing the out-of-namespace table name.
- **no-sqlite-query-issued**: No query reached SQLite. (negative — verified by instrumenting the connection wrapper)
- **no-event-emitted**: No `events.jsonl` line was written as a side effect. (negative)

#### Test: db-write-rejects-cross-plugin-write (covers R3, negative, edge)

**Given**: Plugin `myplugin` active.  
**When**: `myplugin` calls `api.db.execute("INSERT INTO otherplugin__things (id) VALUES ('x')")`.  
**Then** (assertions):
- **permission-error-raised**: `PermissionError` raised.
- **no-row-inserted**: `otherplugin__things` row count is unchanged after the call. (negative)

#### Test: db-write-rejects-raw-ddl (covers R3, R5, negative, edge)

**Given**: Plugin `myplugin` active.  
**When**: `myplugin` calls `api.db.execute("CREATE TABLE myplugin__rogue (id INTEGER)")`.  
**Then** (assertions):
- **permission-error-raised**: `PermissionError` raised (DDL through `api.db` is not permitted; `register_table` is the only DDL path).
- **no-table-created**: SQLite schema does NOT contain `myplugin__rogue`. (negative)

#### Test: register-command-rejected-after-activation (covers R14, negative, edge)

**Given**: Plugin `myplugin` has completed `activate`; it then runs a command handler that attempts further registration.  
**When**: Inside a command handler, plugin calls `api.register_command("late", handler, "...")`.  
**Then** (assertions):
- **runtime-error-raised**: `RuntimeError` raised with message indicating registration is install/activate-only.
- **command-not-registered**: `myplugin.late` is NOT callable afterward. (negative)

#### Test: register-command-rejects-duplicate-name (covers R6, negative, edge)

**Given**: Plugin `myplugin` in `activate` successfully calls `api.register_command("sync", handler_a, "A")`.  
**When**: Plugin calls `api.register_command("sync", handler_b, "B")` in the same activate.  
**Then** (assertions):
- **value-error-raised**: `ValueError` raised with message `"duplicate command: sync"`.
- **first-handler-retained**: Invoking `myplugin.sync` afterward calls `handler_a`, not `handler_b`.

#### Test: disposable-exception-does-not-halt-cleanup (covers R11, edge)

**Given**: Plugin's `activate` appends disposables `[d1, d2, d3]`; `d2.dispose()` is configured to raise `RuntimeError("boom")`.  
**When**: Framework invokes `deactivate(context)`.  
**Then** (assertions):
- **d3-disposed**: `d3.dispose()` invoked (before d2, per reverse order).
- **d2-raised-logged**: `d2.dispose()` invoked, raised, and the exception was logged (not propagated).
- **d1-disposed**: `d1.dispose()` still invoked after d2 raised.
- **deactivate-completed**: Framework considers deactivate complete (does not retry or abort).

#### Test: install-failure-prevents-activate (covers R12, edge)

**Given**: Plugin `myplugin` has an `install` hook that raises `RuntimeError` after registering one table but before completing.  
**When**: Framework runs `install(api, context)`.  
**Then** (assertions):
- **error-surfaces**: The `@acp.plugin-install` CLI surface reports the install failure.
- **install-marked-failed**: Framework records that `myplugin` is in `install_failed` state.
- **activate-never-called**: No invocation of `myplugin.*` triggers `activate`; it raises `PluginNotInstalledError` instead. (negative)
- **partial-table-state**: Any tables registered before the raise are marked `partially_migrated` in line with the migration spec.

#### Test: empty-plugin-installs-and-idles (covers R12, edge)

**Given**: A plugin with `install(api, context) -> None: pass`, no `activate`, no tables, no commands, no event handlers.  
**When**: `@acp.plugin-install empty-plugin` runs; nothing further.  
**Then** (assertions):
- **install-succeeds**: Install completes without error.
- **no-activate-ever**: No `activate` is ever triggered (no contributed surface to trigger on). (negative)
- **no-tables-created**: No `empty_plugin__*` tables exist. (negative)

#### Test: many-migrations-apply-in-order (covers R5, edge)

**Given**: Plugin has 50 migrations `[m1..m50]` in order.  
**When**: `install` calls `api.register_table("tasks", migrations=[m1..m50])`.  
**Then** (assertions):
- **all-fifty-recorded**: `_migrations` table has 50 rows for this plugin.
- **ordering-preserved**: The `ts` column of those rows is monotonically non-decreasing across numbers 1..50.

#### Test: events-record-meta-cannot-inject-framework-fields (covers R8, edge, negative)

**Given**: Plugin active.  
**When**: Plugin calls `api.events.record(..., meta={"id": "aaaa", "ts": "1970-01-01T00:00:00Z"})`.  
**Then** (assertions):
- **record-succeeds**: Returns a UUIDv7 id.
- **id-not-aaaa**: Parsed event `id` is a valid UUIDv7, not `"aaaa"`. (negative)
- **ts-not-1970**: Parsed event `ts` is within 1 second of wall clock, not epoch-zero. (negative)

---

## Non-Goals

- **Migration file format, numbering, and rollback behavior** — covered in a separate migration spec.
- **Event replay / time-travel semantics** — covered in the events-system spec.
- **Plugin dependency resolution and load ordering** — covered in the plugin-loader spec.
- **Cross-plugin command dispatch implementation details** — this spec covers the contract (`api.call_command`, registration via `register_command`); the dispatch machinery (serialization, error mapping across plugin boundaries) is a separate spec.
- **MCP tool description synthesis** — how `mcp_description` becomes a fully-formed MCP tool schema is the MCP adapter's concern.
- **REST / CLI surface shapes** — the adapters' specs own these.
- **Plugin config schema and loading** — this spec only defines `api.config.get(key, default)`; where the config values come from is configuration-system territory.
- **Sandboxing beyond the scoped connection** — we do not prevent a plugin from importing arbitrary Python modules, reading arbitrary files on disk, or making network calls. The framework enforces data-boundary isolation (tables, events, identity), not process-level isolation.

---

## Open Questions

- [ ] **OQ-1**: What happens when `activate(api, context)` raises? Options: (a) plugin marked `activation_failed` for the rest of the session, subsequent calls to its commands raise; (b) retry on next invocation; (c) the exception is propagated out of the initiating command call, plugin remains in "un-activated" state and the next call retries. Ties to Behavior Table row #20. Design doc did not specify.
- [ ] **OQ-2**: What are the concurrency semantics for first-access? If two threads (or async tasks) invoke `<plugin>.foo` simultaneously on an un-activated plugin, do they both race into `activate`, or does one block while the other activates? A mutex around activation is the obvious answer, but the design doc did not commit. Ties to row #21. Relevant if the MCP adapter becomes multi-threaded.
- [ ] **OQ-3**: Is there a transactional guarantee between `api.db.execute(...)` writes and immediately-following `api.events.record(...)` calls? If the event record fails (e.g., disk full on `events.jsonl` fsync), is the DB write rolled back? Design doc treated events as authoritative but did not specify write-path atomicity. Ties to row #22.
- [ ] **OQ-4**: Are command names case-sensitive, case-insensitive, or case-preserving-but-insensitive? Ties to row #23. Relevant to whether `myplugin.Sync` and `myplugin.sync` collide.
- [ ] **OQ-5**: Is `register_table` idempotent across multiple `install()` invocations? If a plugin is uninstalled and reinstalled, or if `install` is re-run for some recovery reason, should `register_table` with the same name and migrations succeed silently, re-run migrations, or error? Ties to row #24.
- [ ] **OQ-6**: Does `api.call_command("otherplugin.foo", ...)` from within a plugin implicitly trigger `otherplugin`'s `activate` if it is not yet active in this session? Lazy-activation semantics under cross-plugin dispatch. The design implied yes but did not commit.
- [ ] **OQ-7**: What is the behavior when `uninstall` raises? Partial uninstall? Rollback? Plugin stuck in `uninstall_failed` state?

---

## Key Design Decisions

### Isolation model

| Decision | Choice | Rationale |
|---|---|---|
| Cross-plugin data access | Private tables; interop only via registered commands | Hidden schema coupling rots plugin ecosystems; commands are self-describing and stable, schemas drift silently |
| Read path | `api.query_readonly` scoped to own tables only | Same isolation boundary applies to reads; the "ambient joinability" temptation was rejected |
| Identity enforcement | `(name, version)` bound into PluginAPI at framework construction | Plugins structurally cannot forge records as another plugin |

### Lifecycle

| Decision | Choice | Rationale |
|---|---|---|
| Hook count | Four: `install`/`activate`/`deactivate`/`uninstall` | Real plugin needs include both one-time setup (install) and per-session init (activate); collapsing is wrong-shaped |
| Activation timing | Lazy (on first contributed-surface touch) | Fast startup; no cost for unused plugins; failed activations only hit users who try to use them |
| Disposal order | LIFO over `context.subscriptions` | Standard lifecycle-stack semantics; consistent with VSCode and scenecraft |
| Disposable exception | Logged, not propagated; cleanup continues | Partial cleanup is strictly better than aborted cleanup |

### API shape

| Decision | Choice | Rationale |
|---|---|---|
| Two-arg activate | `activate(api: PluginAPI, context: PluginContext)` | Splits "what you can do" (capability) from "what you own" (lifecycle); mirrors VSCode and scenecraft |
| Registration phase restriction | Only during install/activate | Prevents surprise registration during command handlers; makes "what contributes this plugin exposes" statically determinable |
| Table namespacing enforcement | No escape hatch — framework auto-prepends | Stricter than convention; structurally impossible to collide namespaces |
| Event write path | Only `api.events.record`; no raw inserts to `_events` | Single chokepoint where framework stamps identity |

### Principles

| Decision | Choice | Rationale |
|---|---|---|
| Safety vs paternalism | Enforce isolation, identity, namespacing; allow architectural mistakes (cycles, bad command design) | "Let people write bad plugins" — paternalism without safety benefit adds framework complexity without return |
| Sandboxing breadth | Data-boundary only (tables, events, identity); NOT process-level | Process-level sandboxing is 10× the complexity for marginal benefit at plugin-author-trust level |

---

## Related Artifacts

- **Source design**: [`agent/design/local.acp-code-design.md`](../design/local.acp-code-design.md)
- **Source clarification** (already captured into the source design): `clarification-14-acp-code-design.md` (ephemeral; status: Captured)
- **Related future specs**:
  - `local.acp-code-events-system.md` (events.jsonl schema, replay, time-travel) — not yet created
  - `local.acp-code-migration-runner.md` (migration file format, per-plugin numbering, SAVEPOINT execution) — not yet created
  - `local.acp-code-plugin-loader.md` (discovery, manifest validation, dependency resolution, load ordering) — not yet created
  - `local.acp-code-mcp-adapter.md` (how `register_command` contributions become MCP tools) — not yet created

---

**Namespace**: local  
**Spec**: acp-code-plugin-api  
**Version**: 1.0.0  
**Created**: 2026-04-23  
**Last Updated**: 2026-04-23  
**Status**: Draft  
**Author**: Patrick Michaelsen  
