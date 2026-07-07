# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root, or
- **`CONTEXT-MAP.md`** at the repo root if it exists — it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The producer skill (`/grill-with-docs`) creates them lazily when terms or decisions actually get resolved.

## File structure

Single-context repo (most repos):

```
/ 
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-....md
│   └── ...
└── src/ (or equivalent)
```

Multi-context repo (presence of `CONTEXT-MAP.md` at the root):

```
/ 
├── CONTEXT-MAP.md
├── docs/adr/                          ← system-wide decisions
└── src/
    ├── <context1>/
    │   ├── CONTEXT.md
    │   └── docs/adr/                  ← context-specific decisions
    └── <context2>/
        ├── CONTEXT.md
        └── docs/adr/
```

## Current layout for this repo (single-context)

- Current design spec: `docs/compose/specs/2026-06-12-perler-bead-game-design.md`（Unity 版本描述较完整的游戏愿景；原生 iOS 版本是同一主线的轻量首版实现，尚未有独立 spec 文档）。
- Planning history: `docs/compose/plans/2026-06-12-perler-bead-game-plan.md`（已标记为废弃）。
- No `CONTEXT.md` or `docs/adr/` yet (proceed silently if referenced).
- Current lightweight delivery track: `BeadWorksNative/` (native SwiftUI iOS project, primary track). Unity implementation `BeadWorksUnity/` (Unity C# game project) is paused but kept in the repo.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
