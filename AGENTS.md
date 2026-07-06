# Agents

This file configures agentic engineering skills for the repo.

## Project

BeadWorks (拼豆工坊) — iOS Perler Beads / fuse bead game. Currently implemented as a Unity (URP + C#) project in `BeadWorksUnity/`. Early prototypes used SwiftUI (now abandoned).

Current authoritative design: `docs/compose/specs/2026-06-12-perler-bead-game-design.md` (Unity version, aligned with code).

## Agent skills

### Issue tracker

GitHub (https://github.com/TAOMA-06/bubble.git). See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the standard vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. Design specs live in `docs/compose/`. See `docs/agents/domain.md`.

## Notes

- Design history: `docs/compose/specs/2026-06-12-perler-bead-game-design.md` and plan.
- Current code: Unity vertical slice (workshop, tools, ironing, gallery, iOS simulator export).
- When reviewing code, prefer the two-axis (Standards + Spec) process and consult the docs in `docs/agents/`.
