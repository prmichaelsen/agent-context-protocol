# Agent Context Protocol: an agent harness for software development

_by Claude Opus 4.7, direction by Patrick Michaelsen <patrickazusa@gmail.com>_

## Abstract

AI coding agents fail predictably on long unattended runs — not because the models are weak, but because two structural problems recur: context loss across sessions and spec gaps the agent silently fills. **Agent harnesses** are an emerging category of tooling that addresses both by imposing structure on the development workflow the agent participates in.

This document introduces the category through one specific harness, the **Agent Context Protocol** (ACP), used as a worked example of what a heavyweight harness looks like in practice. ACP enforces a fixed five-stage pipeline — clarify, design, spec, plan, execute — through executable markdown command files an LLM can run end to end. Each stage produces one authoritative artifact, iterated in place until signoff. The spec stage uses a Behavior Table to surface every scenario the system will handle (including unresolved ones, marked `undefined`), so disagreements surface before code is written rather than after. Once approved, autonomous milestone runs become *safe* multi-hour runs because all decisions were already made.

The document covers ACP's enforcement mechanism, methodology, supporting infrastructure (package management, project registry, agent-agnostic bootstrap via `AGENT.md`), and honest tradeoffs about when *not* to adopt a harness this opinionated.

---

## Problem Statement

If you've watched an AI agent build code unattended for more than an hour, you've probably watched it confidently build the wrong thing. Hour one is great. By hour three, somehow half the codebase uses Postgres and the other half uses SQLite, and the agent doesn't remember why. The model didn't get dumber — its state did.

This document introduces **agent harnesses** — the category of tooling that exists to solve this, and one most developers haven't heard of — and uses one specific harness, the **Agent Context Protocol** (ACP), as a concrete example of what one is and what it's for.

---

## Part I — Why agents go off the rails

Long agent sessions degrade for two reliable reasons.

**Context loss.** LLMs don't have continuity. Sessions end, contexts compact, sub-agents spawn, and decisions made earlier evaporate. By hour three, the agent that "agreed" to use Postgres has forgotten the agreement.

**Spec gaps the agent silently fills.** When a requirement is ambiguous, the model picks plausibly and moves on. Most "agent failures" are actually spec failures the agent confidently filled in. As ACP's own README puts it: *"The more gaps you leave in your clarification, the more likely your agent will make implementation decisions you would not make yourself."*

A whole category of tooling has emerged to address these — Aider's repo maps, Cursor rules, `CLAUDE.md`, ACP. They differ in how, but they converge on the same insight: give the agent **durable, structured state**.

---

## Part II — What an agent harness is

### The category

An **agent harness** is structure imposed on the development workflow your agent participates in — conventions for what to produce, in what order, with what artifacts. Chatting with Claude is freeform. Running an agent inside a harness follows a fixed pipeline that any agent (and any human) can pick up mid-stream.

Harnesses live on a spectrum of ambition. Cursor rules and `CLAUDE.md` sit at the light end — ambient prompts that flavor the agent's responses. ACP sits at the heavy end: it doesn't just inform the agent, it dictates the steps.

### How ACP enforces the structure

For a workflow to actually shape agent behavior, the agent has to follow it reliably. ACP's enforcement mechanism is **executable markdown**.

Every stage of the workflow is invoked as `@acp.<stage>` — `@acp.clarification-create`, `@acp.spec`, `@acp.proceed`, and so on. Each command is a markdown file with numbered steps. A hardened directive at the top of every file flips the model into "follow these steps" mode rather than "interpret loosely" mode:

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-spec` has been invoked. ... This is who you are until you finish reading this document.

Self-administered prompt injection, in service of determinism. The same workflow could in principle be enforced by a CLI or a state machine — markdown is just the simplest substrate that works inside an LLM's natural execution mode.

### The thesis

> **ACP gives your agent a development workflow — clarify, design, spec, plan, execute — and uses executable markdown to make that workflow stick.**

The rest of this document is the workflow itself, because that's what you're actually adopting when you adopt ACP. Everything else — the package manager, the registry, the indexing — is supporting infrastructure.

---

## Part III — The workflow

### The pipeline

ACP defines a fixed five-stage pipeline:

```
clarification → design → spec → plan → proceed
```

Each stage has a corresponding `@acp.*` command. Each stage produces **one authoritative artifact** that gets iterated on in place until you sign off — then the next stage begins. The model isn't "redo work," it's "thicken the same document until it's airtight."

This sounds heavy. In practice it's five documents that grow denser, with you as proofreader at each handoff. The whole pipeline is structured to push effort as far left as possible — by the time code is written, all decisions are already made. The README ranks effort accordingly: clarifications #1, planning #2, implementation called *"the final and easiest step."*

### Stage 1: clarification

`@acp.clarification-create` produces a structured Q&A document focused on gaps in your requirements, ambiguous specs, and open questions. The agent generates the questions; you answer them on lines marked `>`.

You can answer with **directives** instead of just answers: *"explore the codebase to answer this yourself,"* *"research this on the web,"* *"recommend the best tradeoff."* You then run `@acp.clarification-address`, which executes those directives and writes its analysis back into the same document inside `<!-- HTML comment blocks -->`. Original questions and answers are preserved verbatim; the agent's research thickens the doc around them.

Iteration happens *in place* on one document. Large features may need ten passes; small ones might need one. The "ten passes" is depth on a single doc, not breadth across ten.

### Stage 2: design

A design captures **what** and **why** — architecture, tradeoffs, alternatives rejected. Designs are settled before specs begin; if scope is still open, you're still in clarification or design.

`@acp.design-create --from clar` automatically pulls every decided answer from the clarification into a "Key Design Decisions" appendix, so rationale travels forward with the design.

### Stage 3: spec — the proofing surface

Where a design captures **what/why**, a spec captures **how** — concrete interfaces, data shapes, and *every observable behavior the system will exhibit*. From the `@acp.spec` command itself: *"A reader who knows nothing about the implementation should be able to predict, from the spec alone, what the system does for any reasonable input."*

The spec's load-bearing innovation is the **Behavior Table** — one row per scenario, including `undefined` rows for behaviors the source artifacts didn't resolve:

| # | Scenario | Expected Behavior | Tests |
|---|----------|-------------------|-------|
| 1 | Valid login with correct password | Returns 200 with session token | `accepts-valid-login` |
| 2 | Login with wrong password | Returns 401 with generic error | `rejects-bad-password`, `no-user-enumeration` |
| 3 | Login during maintenance window | `undefined` | → [OQ-3](#open-questions) |

The agent is *forbidden* from guessing. Undecided behavior surfaces as `undefined`, never as a silently-invented test. From the spec command: *"Guessing in a test silently locks in an implementation decision the user never made."*

You proof the spec by reading the table top to bottom and flagging rows where Expected Behavior doesn't match what you want. `undefined` rows are the highest-value rows — they're exactly where your judgment is needed. Once approved, implementation becomes mechanical: every test maps directly to a test function in any framework. No design decisions happen during coding.

### Stage 4: plan and proceed

Once the spec is signed off, `@acp.plan` proposes a milestone and task breakdown; you approve or iterate. Planning artifacts are *self-contained* — each task file embeds every piece of context the agent needs, so context loss across sessions doesn't break it.

`@acp.proceed --yolo` then implements the entire milestone unattended. Atomic commits per task, start and end timestamps in `progress.yaml`, verification gates between tasks. From the README: *"Play with dog at dog park (if vibecoding remotely)."*

This is what the upstream investment buys: a four-hour autonomous run becomes a *safe* four-hour autonomous run.

---

## Part IV — The system around the workflow

### Anatomy of an ACP project

For the workflow to scale beyond a single feature, ACP needs durable state on disk. Everything ACP knows about your project lives in the `agent/` tree alongside your code:

```
agent/
├── commands/          # the workflow's executable steps
├── clarifications/    # Q&A documents per feature
├── design/            # what & why
├── specs/             # how (with Behavior Tables)
├── milestones/        # phase-level groupings
├── tasks/             # self-contained task capsules
├── patterns/          # reusable conventions
├── index/             # weighted "must-read" file lists
└── progress.yaml      # the project's heartbeat
```

`progress.yaml` records milestone status, task completion, timestamps, recent work — all human-readable. It's the file the agent consults to know "where am I, what's next?"

It does introduce a non-zero rate of merge conflicts when multiple agents or branches are in flight — a single growing YAML file that ACP actively encourages parallel work against. But conflicts are unusually agent-friendly: the schema is fixed, most edits are append-only or status updates, and an LLM can reason cleanly about which side is "more advanced." There's no special merge command; resolution is just normal agent reasoning applied to a structured file. The conflicts are the cost of durable shared state, and that cost is dramatically lower when the resolver is an LLM than when it's a human reading 1,800 lines of diff.

### Agent-agnostic, by design

For the workflow to scale beyond a single project, ACP ships package management (commands and patterns distribute as portable, versioned packages with SHA tracking), a global project registry at `~/.acp/projects.yaml`, and a **key file index** that forces agents to load critical files before making decisions.

Most importantly, **ACP is agent-agnostic**. Bootstrap docs live in `AGENT.md` — vendor-neutral, not `CLAUDE.md` or `.cursorrules`. But the more important convention is this: **each session should begin with `@acp.init`**, which loads project context from `progress.yaml`, the key file index, and any designs and specs relevant to current work. Any agent capable of reading markdown and following numbered steps can run that command and pick up the workflow from there.

The README is candid that Claude is the most reliable runtime — the model most likely to honor the prompt-as-script directive on first read — but ACP itself runs on any agent. The practical implication: your investment in clarifications, designs, specs, and `progress.yaml` is portable. If you switch agents next year, the workflow comes with you. The artifacts are markdown and YAML; nothing is locked behind a vendor's prompt format.

---

## Part V — Reality check

### When not to use it

ACP has real overhead. The methodology only pays back at scale and over time. The README is upfront about its anti-patterns: trivial scripts (<100 lines), one-off prototypes, throwaway code.

The bottleneck moves from typing to thinking. The cost isn't producing many documents — it's iterating *deeply* on one until every ambiguity is closed. A non-trivial feature might run through ten chained `@acp.clarification-address` passes on the same file. That's hours of focused proofing before the first commit.

ACP also assumes the agent is capable enough — what it lacks is a watertight spec. If your task is "I don't know what I want yet," you're not ready for ACP, you're ready for chat.

### Where it fits in the landscape

The clearest way to place ACP is by asking: **how much of the dev process does the harness own?**

- **Cursor rules / `CLAUDE.md`** — *ambient context*. Tells the agent what to know; doesn't tell it what to do next.
- **Aider** — *workflow inside a single edit cycle*. Strong opinions about how the agent reads and writes code; no opinion about how features are specified or planned.
- **ACP** — *workflow across a feature's full lifecycle*. From "I have an idea" to "milestone is shipped."

These are complementary, not competitive. You can run ACP in a project that also has `CLAUDE.md` and Cursor rules. The axis they differ on is scope of ownership over the dev process.

---

## Part VI — Try it

One-line install:

```bash
curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash
```

Pair it with `npx @prmichaelsen/acp-visualizer` to watch milestones tick in real time during autonomous runs.

Try it on your next ≥1-month project. You'll know within the first clarification pass whether the methodology fits the way you think — and the cost to bail is low, since it's just markdown files alongside your code.

---

## Conclusion

The agent harness category exists because long-running agents need durable, structured state. ACP's bet — among harnesses — is that the bulk of that structure should live in the workflow itself, not in ambient hints to the model.

That bet rests on a deeper one: **the bottleneck in agent-driven development is not the agent's capability — it's the human's clarity.** When an autonomous agent ships the wrong thing, it's almost always because nobody specified the right thing precisely enough. ACP front-loads almost all of its machinery against that bottleneck — clarification documents, designs, specs with Behavior Tables, planning artifacts that are self-contained capsules — so that by the time `@acp.proceed` runs, the agent is executing a contract, not improvising.

This reframes the AI-coding debate productively. *"Is my agent good enough?"* becomes *"is my spec good enough?"* — a question developers have been answering, with steadily improving tools, for half a century. Agent harnesses are the next move in that tradition. ACP is one opinionated answer to what that move should look like.

---

## Footnote

As laid out in the prophetic *Office Space*, software is primarily a function of translating customer requirements into a hardened spec, and then translating that spec into machine-executable scripts:

> **Bob Slydell**: *"What you do at Initech is you take the specifications from the customer and bring them down to the software engineers?"*
>
> **Tom**: *"Yes, yes that's right."*

> **Bob Porter**: *"Well then I just have to ask, why can't the customers take them directly to the software people?"*
>
> **Tom**: *"Well, I'll tell you why, because... engineers are not good at dealing with customers."*

> **Tom**: *"I deal with the gosh darn customers so the engineers don't have to! I have people skills! I am good at dealing with people! Can't you understand that?! What the heck is wrong with you people?!"*

Twenty-seven years on, an agent harness defines a modern requirements translation workflow — and the agent is the engineer who is handed the spec. From there, the task is context-loss-proof orchestration.
