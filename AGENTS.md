# Agents

This file configures agentic engineering skills for the repo.

## Project

BeadWorks (拼豆工坊) — iOS Perler Beads / fuse bead game. Current lightweight delivery track is a native SwiftUI app in `BeadWorksNative/` (open `BeadWorksNative/BeadWorks.xcodeproj`, `Cmd+R` to run — no third-party deps, iOS 17+). The Unity (URP + C#) project in `BeadWorksUnity/` is paused but kept in the repo, not deleted or blocked.

Current authoritative design: `docs/compose/specs/2026-06-12-perler-bead-game-design.md` (Unity version — still describes the fuller game vision; the native app implements a lighter first slice of the same two main flows: free creation and photo-to-pattern import).

## Agent skills

### Issue tracker

GitHub (https://github.com/TAOMA-06/bubble.git). See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the standard vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. Design specs live in `docs/compose/`. See `docs/agents/domain.md`.

## Notes

- Design history: `docs/compose/specs/2026-06-12-perler-bead-game-design.md` and plan.
- Current code: `BeadWorksNative/` (native SwiftUI, primary lightweight track — free creation, photo import, pegboard editor, ironing, gallery). `BeadWorksUnity/` (Unity vertical slice — workshop, tools, ironing, gallery, iOS simulator export) is paused.
- When reviewing code, prefer the two-axis (Standards + Spec) process and consult the docs in `docs/agents/`.
