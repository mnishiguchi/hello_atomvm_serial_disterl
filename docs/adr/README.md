<!--
SPDX-FileCopyrightText: 2026 Masatoshi Nishiguchi

SPDX-License-Identifier: Apache-2.0
-->

## Architecture Decision Records

We keep architecture decisions as Markdown ADRs in the repository.

### Basic rules

- Write an ADR when a decision changes long-term architecture, transport model, node identity rules, deployment model, or externally visible distributed behavior.
- Keep one ADR focused on one decision.
- Use stable statuses:
  - `Proposed`
  - `Accepted`
  - `Superseded`
  - `Deprecated`
- Use `Accepted` consistently once a decision is agreed.
- When a decision moves from `Proposed` to `Accepted`, update the same ADR file in place.
- Create a new ADR only when a later decision changes or replaces the earlier one.
- When that happens, keep the old ADR and mark it `Superseded`.
- Cross-reference related ADRs when one builds on or replaces another.

### Scope guidance

Use ADRs for decisions such as:

- serial or network transport choices
- distributed Erlang startup and naming rules
- persistence and provisioning strategy
- module responsibility splits
- compatibility and rollout policy

Do not use ADRs for routine implementation details, temporary checklists, or ordinary task tracking.

### Naming

Recommended file naming:

```text
docs/adr/YYYY-MM-DD-short-title.md
```

Examples:

- `docs/adr/2026-04-24-use-serial-dist-for-two-esp32-demo.md`

### Minimal ADR template

```markdown
# ADR YYYY-MM-DD: Title

## Status

Proposed

## Context

## Decision

## Rationale

## Consequences

### Positive

### Negative

## Rejected alternatives

## Follow-up implications
```
