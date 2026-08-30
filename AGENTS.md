# Agents

This file configures agentic engineering skills for the repo.

## Project

BeadWorks (拼豆工坊) — iOS Perler Beads / fuse bead game. Current lightweight delivery track is a native SwiftUI app in `BeadWorksNative/` (open `BeadWorksNative/BeadWorks.xcodeproj`, `Cmd+R` to run — no third-party deps, iOS 17+). The Unity (URP + C#) project in `BeadWorksUnity/` is paused but kept in the repo, not deleted or blocked.

Current authoritative design for the native track: `docs/compose/specs/2026-08-30-beadworks-ios-mvp.md`. The Unity vision remains in `docs/compose/specs/2026-06-12-perler-bead-game-design.md` (paused). The native app implements free creation, photo-to-pattern import, sample-pattern replica, ironing, gallery, and share.

## Agent skills

### Issue tracker

GitHub (https://github.com/TAOMA-06/bubble.git). See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the standard vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. Design specs live in `docs/compose/`. See `docs/agents/domain.md`.

## Notes

- Design history: `docs/compose/specs/2026-08-30-beadworks-ios-mvp.md` (native MVP) and `docs/compose/specs/2026-06-12-perler-bead-game-design.md` (Unity vision).
- Current code: `BeadWorksNative/` (native SwiftUI, primary track — free creation, photo import, sample patterns, pegboard editor, ironing, gallery, share). `BeadWorksUnity/` is paused.
- When reviewing code, prefer the two-axis (Standards + Spec) process and consult the docs in `docs/agents/`.
