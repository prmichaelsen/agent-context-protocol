# ACP Progress Visualizer

**Concept**: Browser-based read-only dashboard for visualizing progress.yaml project data  
**Created**: 2026-03-14  
**Status**: Design Specification  

---

## Overview

A standalone TanStack Start application that renders ACP `progress.yaml` files as an interactive admin dashboard. The visualizer provides table, tree, kanban, and Gantt views of milestones and tasks, with search, filtering, and auto-refresh capabilities. It runs locally during development and can be deployed to Cloudflare Workers for hosted access.

The tool lives in a separate repository (`agent-context-protocol-visualizer`) and is designed for personal use by project owners who want a visual overview of their ACP project status.

---

## Problem Statement

ACP's `progress.yaml` files grow large (1800+ lines for the core ACP project) and are difficult to navigate in a text editor. The existing text-based status commands (`@acp.status`, `@acp.report`) provide useful summaries but lack:

- Visual milestone/task hierarchy with expandable detail
- Filterable views (e.g., show only in-progress items)
- Search across milestones, tasks, and activity logs
- Progress charts and completion metrics
- A persistent dashboard that auto-updates as work progresses

Without a visual tool, project owners must mentally parse large YAML files or rely on text command output to understand project state.

---

## Solution

Build a TanStack Start web application that:

1. Reads `progress.yaml` from the local filesystem (P0) or a GitHub repo URL (P1)
2. Parses YAML into structured data
3. Renders multiple visualization views with priority-tiered rollout
4. Provides search via fuse.js and status-based filtering
5. Auto-refreshes when the source file changes

### Alternative Approaches Considered

- **Single HTML file**: Rejected — user confirmed this will be a "heavy project" needing proper build tooling
- **Static site generator**: Rejected — dynamic runtime YAML loading preferred for auto-refresh
- **Integration into agentbase.me**: Rejected — standalone tool preferred
- **Monorepo subfolder in ACP core**: Rejected — ACP core is pure bash; mixing in a full JS/TS app would complicate CI and bloat the repo

---

## Implementation

### Architecture

```
agent-context-protocol-visualizer/
├── app/
│   ├── routes/
│   │   ├── __root.tsx          # Root layout (sidebar, header)
│   │   ├── index.tsx           # Dashboard home (project overview)
│   │   ├── milestones.tsx      # Milestone views (table/tree/kanban/gantt)
│   │   ├── tasks.tsx           # Task detail views
│   │   ├── activity.tsx        # Recent work timeline (P1)
│   │   └── search.tsx          # Global search results
│   ├── components/
│   │   ├── MilestoneTable.tsx      # P0: @tanstack/react-table view
│   │   ├── MilestoneTree.tsx       # P0: Expandable/collapsible tree
│   │   ├── MilestoneKanban.tsx     # P1: Status-column kanban
│   │   ├── MilestoneGantt.tsx      # P2: Timeline/Gantt chart
│   │   ├── TaskList.tsx            # Expandable task list per milestone
│   │   ├── ProgressBar.tsx         # Overall completion percentage
│   │   ├── StatusBadge.tsx         # Color-coded status indicators
│   │   ├── SearchBar.tsx           # Fuse.js-powered search
│   │   ├── FilterBar.tsx           # Status filter controls
│   │   └── NextSteps.tsx           # Next steps display
│   └── lib/
│       ├── yaml-loader.ts          # YAML parsing and data normalization
│       ├── data-source.ts          # Filesystem vs GitHub data source abstraction
│       └── search.ts               # Fuse.js index configuration
├── server/
│   ├── routes/
│   │   └── api/
│   │       └── progress.ts         # Server route: read progress.yaml from disk
│   └── lib/
│       └── file-watcher.ts         # File change detection for auto-refresh
├── app.config.ts
├── package.json
├── tailwind.config.ts
└── tsconfig.json
```

### Data Model

The YAML is parsed into TypeScript interfaces:

```typescript
interface ProgressData {
  project: ProjectMetadata;
  milestones: Record<string, Milestone>;  // keyed by milestone ID (e.g. "M1", "M2")
  tasks: Record<string, Task[]>;  // keyed by milestone ID (e.g. "M1", "M2")
  recent_work: WorkEntry[];
  next_steps: string[];
  notes: string[];
}

interface ProjectMetadata {
  name: string;
  version: string;
  started: string;
  status: 'in_progress' | 'completed' | 'not_started';
  current_milestone: string;
  description: string;
}

interface Milestone {
  name: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  status: 'completed' | 'in_progress' | 'not_started';
  progress: number;
  started: string | null;
  completed: string | null;
  estimated_weeks: string;
  tasks_completed: number;
  tasks_total: number;
  notes: string;
}

interface Task {
  id: string;
  name: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  status: 'completed' | 'in_progress' | 'not_started';
  started: string | null;            // ISO 8601 timestamp
  file: string;
  estimated_hours: string;
  actual_hours: number | null;       // auto-computed from started/completed_date
  completed_date: string | null;     // ISO 8601 timestamp
  notes: string;
}

interface WorkEntry {
  date: string;
  description: string;
  items: string[];
}
```

### Data Loading

**P0 — Local filesystem**:
- TanStack Start server route reads `progress.yaml` via `fs.readFileSync`
- Path configurable via environment variable or CLI argument
- File watcher triggers SSE/WebSocket push for auto-refresh

**P1 — GitHub remote**:
- Fetch via GitHub API: `GET /repos/{owner}/{repo}/contents/agent/progress.yaml`
- Support public repos without auth; private repos require GitHub token
- Poll-based refresh (configurable interval)

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | TanStack Start (React) |
| Styling | Tailwind CSS |
| Table | @tanstack/react-table |
| Search | fuse.js |
| YAML parsing | js-yaml or yaml |
| Charts (P1) | recharts |
| Build | Vite |
| Deployment (P1) | Cloudflare Workers |

### Visual Design

- Minimal, compact admin dashboard (Linear/Vercel style)
- Monospace fonts for data values
- Neutral gray palette with status accent colors:
  - Green: completed
  - Blue: in_progress
  - Gray: not_started
- Desktop-optimized layout (no mobile responsiveness unless minimal lift)
- High information density

---

## Priority Tiers

### P0 — MVP

| Feature | Description |
|---------|-------------|
| Project metadata display | Name, version, status, dates, current milestone |
| Milestone table view | @tanstack/react-table with sortable columns |
| Milestone tree view | Expandable milestones → tasks hierarchy |
| Task list | Expandable/collapsible tasks within each milestone |
| Status badges | Color-coded completed/in-progress/not-started |
| Overall completion % | Progress bar across all milestones |
| Next steps display | Rendered from next_steps array |
| Status filtering | Show only in-progress, completed, or not-started items |
| Search | Fuse.js across milestones, tasks |
| Local filesystem loading | Server route reads progress.yaml from disk |
| Auto-refresh | File watcher triggers reload on YAML change |
| Local dev server | `npm run dev` starts Vite dev server |

### P1 — Enhanced

| Feature | Description |
|---------|-------------|
| Kanban board view | Columns by status (not_started → in_progress → completed) |
| Recent work timeline | Activity feed from recent_work entries |
| Notes display | Project notes rendered |
| Burndown/velocity chart | recharts-based completion over time |
| GitHub remote loading | Fetch progress.yaml from public/private GitHub repos |
| Multi-project support | View multiple projects from ~/.acp/projects.yaml |
| Hosted deployment | Cloudflare Workers via wrangler deploy |

### P2 — Future

| Feature | Description |
|---------|-------------|
| Gantt/timeline view | Horizontal timeline with date-based positioning |
| Task dependencies | Dependency graph visualization |

### P3 — Deferred

| Feature | Description |
|---------|-------------|
| Multi-project aggregation | Cross-project overview dashboard |

---

## Benefits

- **Immediate visibility**: See project status at a glance instead of parsing 1800-line YAML
- **Searchable**: Find any milestone, task, or activity entry instantly
- **Filterable**: Focus on in-progress work without scrolling past completed items
- **Auto-updating**: Dashboard reflects progress.yaml changes in real time
- **Reusable patterns**: Leverages existing acp-tanstack-cloudflare patterns for deployment

---

## Trade-offs

- **Separate repo**: Requires cross-repo coordination for progress.yaml schema changes (mitigated by stable schema)
- **Heavy stack**: Full TanStack Start app is significant infrastructure for what starts as a YAML viewer (justified by P1+ features and user's explicit preference for "proper app")
- **Desktop-only**: No mobile support unless trivial to add (acceptable per requirements — users develop on laptops)

---

## Dependencies

- TanStack Start (React)
- @tanstack/react-table
- Tailwind CSS
- js-yaml or yaml
- fuse.js
- recharts (P1)
- wrangler (P1, for Cloudflare Workers deployment)
- Existing `acp-tanstack-cloudflare` patterns for deployment patterns

---

## Testing Strategy

- **Unit tests**: YAML parsing, data normalization, search index building
- **Component tests**: Table rendering, tree expand/collapse, filter logic
- **Integration tests**: Server route reads real progress.yaml and returns correct data
- **E2E tests**: Full page load, search, filter, view switching

---

## Migration Path

No migration needed — this is a greenfield project in a new repository.

1. Create `agent-context-protocol-visualizer` repo
2. Initialize TanStack Start project with Tailwind
3. Implement P0 features
4. Register in `~/.acp/projects.yaml`
5. Create `@acp.visualize` command as an ACP package command

---

## Key Design Decisions

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Read/write mode | Read-only | Dashboard is for viewing, not editing YAML |
| Target audience | Project owner (personal use) | P0 is local dev tool, not team-facing |
| Standalone vs integrated | Standalone tool in separate repo | ACP core is pure bash; JS/TS app doesn't belong there |
| Repository | `agent-context-protocol-visualizer` | Clean separation of concerns, independent versioning |

### Architecture

| Decision | Choice | Rationale |
|---|---|---|
| Framework | TanStack Start (React) | User preference; existing patterns in acp-tanstack-cloudflare |
| App type | Proper app with build tooling | Will be a "heavy project" per user; not suitable for single HTML file |
| Data loading | Dynamic runtime YAML parsing | Supports auto-refresh and multiple data sources |
| Styling | Tailwind CSS, admin dashboard pattern | Minimal, compact, Linear/Vercel style |

### Views & Features

| Decision | Choice | Rationale |
|---|---|---|
| P0 views | Table + Tree | Fastest to build, most data-dense, maps to YAML structure |
| P1 views | Kanban | Good visual overview, moderate build effort |
| P2 views | Gantt/Timeline | Most complex, many milestones lack precise dates |
| Search library | fuse.js | User preference, lightweight fuzzy search |
| Task dependencies | P2 | Nice-to-have, not needed for MVP |
| Responsive/mobile | Desktop-only | Users develop on laptops; mobile adds complexity for no value |

### Data Sources

| Decision | Choice | Rationale |
|---|---|---|
| P0 data source | Local filesystem via server route | Simple, fast, supports file watcher auto-refresh |
| P1 data source | GitHub API | Enables hosted dashboard viewing remote repos |
| Auto-refresh | Yes, via file watcher | Real-time updates as agents modify progress.yaml |

### Hosting

| Decision | Choice | Rationale |
|---|---|---|
| P0 hosting | Local dev server | `npm run dev`, personal use |
| P1 hosting | Cloudflare Workers | Existing patterns, official TanStack Start support |
| @acp.visualize command | Yes | Shell script to start dev server and open browser |
| Auto-generate via @acp.report | No | Visualizer is separate, on-demand tool |

### Multi-Project

| Decision | Choice | Rationale |
|---|---|---|
| Multi-project aggregation | P3 (deferred) | Single project is P0; aggregation is low priority |
| Multi-project page structure | Each project gets own page | When implemented, keeps views focused |

---

## Future Considerations

- **@acp.visualize command**: Package command that starts the local server and opens the dashboard
- **progress.yaml schema documentation**: Formal schema definition to enable cross-repo validation
- **Dark mode toggle**: Natural extension of the admin dashboard pattern
- **Export to PDF/PNG**: Snapshot reports for stakeholders
- **WebSocket-based refresh**: Replace file polling with WebSocket push for lower latency

---

**Status**: Design Specification  
**Recommendation**: Create new repository `agent-context-protocol-visualizer`, initialize TanStack Start project, implement P0 features  
**Related Documents**: clarification-10-progress-visualizer.md  
