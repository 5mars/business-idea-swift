# Requirements: Abimo

**Defined:** 2026-03-21
**Core Value:** Users actually complete their micro-actions because the experience is engaging, rewarding, and fun — not another abandoned to-do list.

## v1.4 Requirements

Requirements for Custom Tab Bar milestone. Each maps to roadmap phases.

### Custom Tab Bar

- [x] **TBAR-01**: Custom flat bottom tab bar replaces the system TabView chrome — no native tab bar visible
- [x] **TBAR-02**: 4 tabs with SF Symbol icons only (no text labels): Ideas, Record, Actions, Profile
- [x] **TBAR-03**: Plain colors — selected icon is brand color, unselected is gray. No gradients.
- [x] **TBAR-04**: Haptic feedback fires on every tab switch (HapticEngine.selection)
- [x] **TBAR-05**: Selected icon plays a shake/bounce animation (Telegram/Duolingo-style)
- [x] **TBAR-06**: Subtle filled circle or pill indicator behind the selected icon

### Naming

- [x] **NAME-02**: "Notes" tab renamed to "Ideas" throughout the app (tab label, view titles, any references)

## Future Requirements

### Deferred from v1.1

- **DISC-04**: "Pick this next" bubble on unchosen/locked nodes as ordering entry point
- **CELB-04**: Voice note CTA ("What's next" edge function) — Supabase not ready

## Out of Scope

| Feature | Reason |
|---------|--------|
| XP/points system | Adds complexity without clear value |
| Sound effects | Adds bundle size, may annoy users |
| Text labels on tabs | User wants icon-only, Duolingo-style |
| Gradient tab bar background | User specified plain colors, no gradients |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TBAR-01 | Phase 14 | Complete |
| TBAR-02 | Phase 14 | Complete |
| TBAR-03 | Phase 14 | Complete |
| TBAR-04 | Phase 14 | Complete |
| TBAR-05 | Phase 14 | Complete |
| TBAR-06 | Phase 14 | Complete |
| NAME-02 | Phase 14 | Complete |

**Coverage:**
- v1.4 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-03-21*
