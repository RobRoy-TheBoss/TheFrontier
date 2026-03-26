# Proposed Requirement Changes
## Items requiring design decisions before tests can be written or code implemented

---

### PRC-001 — LMAI-002: FLEE and DESPAWN as enum states vs. methods
**Status: RESOLVED**
FLEE and DESPAWN added to Monster.State enum as first-class states: `enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, FLEE, DESPAWN, DEAD }`. LLR-v0.7.1 LMAI-002 text should be updated to say these are first-class enum states.

---

### PRC-002 — LSHOP-001 / LHOME-001: Canonical gold storage location
**Status: RESOLVED**
`PlayerStats.gold` deprecated and removed. `PlayerInventory.currency` is now the single source of truth for player currency. LSHOP-001/002/003 tests rewritten to use `PlayerInventory` directly.

---

### PRC-003 — LDSYS-006/007 and all passives: `effect_data` nesting in disciplines.json
**Status: RESOLVED**
`get_passive_effect()` now returns `ab.get("effect_data", ab)` — falls back to the ability dict itself when no nested `effect_data` key exists, so all flat JSON passive values are read correctly.

---

### PRC-004 — LRNG-004/005: Misfire and hangfire implementation
**Status: RESOLVED**
`PlayerCombat._try_fire()` is now async and implements: (a) condition loss per shot via `condition_loss_per_shot`, (b) misfire probability = `(misfire_threshold - condition) / misfire_threshold` when below threshold, (c) hangfire delay of `randf_range(0.3, 0.8)` seconds before resolving. Misfire deals 20 damage and inflicts `bleeding_gash` to the player.

---

### PRC-005 — LINJ-002: Injury probability — global weight vs. per-source table
**Status: RESOLVED**
Per-monster `injury_chances` dictionaries added to all 9 monster entries in `monsters.json`. `PlayerHealth.try_combat_injury_roll()` now accepts `attacker_id: String = ""` and uses the monster's `injury_chances` table when available, falling back to the global weight-based `_try_inflict_random_injury()`. Monster.gd passes `monster_id` to the call.

---

### PRC-006 — LECO-005: `bridge_rivers` — data-driven vs. hardcoded tier index
**Status: RESOLVED**
`bridge_rivers` removed from all 5 tier entries in `settlement_tiers.json` (was dead data). `AreaManager.TOWN_TIER_INDEX` corrected from 2 to 3 (matching the actual town tier index in the tiers array).

---

### PRC-007 — LHOME-004/005: `services` field — Array vs. Dictionary
**Status: RESOLVED**
`services` is an Array of strings in `settlement_tiers.json`. `has_service()` uses the `in` operator which is correct for Arrays. No code change needed.

---

### PRC-008 — LNAV-014: `pathfinder` discipline and `wayfinder` ability
**Status: RESOLVED**
`pathfinder` discipline is post-launch, out of scope. Test `test_wayfinder_radius_mult_lnav014` marked as skipped with `return` at top and a PRC-008 comment.

---

### PRC-009 — LROAD-007: `road_budget` — data-driven vs. hardcoded
**Status: RESOLVED**
`road_budget = 9` accepted as a code constant in DataLoader. No change needed.

---

### PRC-010 — LRUNE-004: `life_steal` rune ID and `allowed_slot_types` validation
**Status: RESOLVED**
`PlayerInventory.socket_rune()` now validates the rune's `allowed_slot_types` array against the equipped item's `type` field. If `allowed_slot_types` is non-empty and the item type is not in it, socketing is rejected. `life_steal` is the canonical rune ID; `allowed_slot_types` is the confirmed field name.

---

## Resolution Summary

### Resolved (all 10 PRCs)

| PRC | Title | Resolution |
|-----|-------|------------|
| PRC-001 | FLEE/DESPAWN enum states | Added to `Monster.State` enum as first-class states |
| PRC-002 | Canonical gold storage | `PlayerStats.gold` removed; `PlayerInventory.currency` is sole source of truth |
| PRC-003 | `effect_data` nesting | `get_passive_effect()` falls back to ability dict via `ab.get("effect_data", ab)` |
| PRC-004 | Misfire and hangfire | `_try_fire()` made async; condition degradation, hangfire delay, misfire damage implemented |
| PRC-005 | Source-dependent injury | Per-monster `injury_chances` added to all 9 monsters; `try_combat_injury_roll(attacker_id)` routes accordingly |
| PRC-006 | `bridge_rivers` / tier index | `bridge_rivers` removed from JSON; `TOWN_TIER_INDEX` corrected to 3 |
| PRC-007 | `services` Array vs Dictionary | Confirmed Array; `in` operator is correct; no change needed |
| PRC-008 | `pathfinder` discipline scope | Post-launch; LNAV-014 test skipped |
| PRC-009 | `road_budget` constant | Accepted as code constant; no change needed |
| PRC-010 | Rune slot-type validation | `socket_rune()` validates `allowed_slot_types` against equipped item type |

### Pending

None — all PRCs resolved.
