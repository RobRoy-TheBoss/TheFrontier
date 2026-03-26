# Proposed Requirement Changes
## Items requiring design decisions before tests can be written or code implemented

---

### PRC-001 — LMAI-002: FLEE and DESPAWN as enum states vs. methods
**Current LLR text:** "States: IDLE, PATROL, ALERT, CHASE, ATTACK, FLEE, DESPAWN"
**Issue:** `Monster.gd` defines `{ IDLE, PATROL, ALERT, CHASE, ATTACK, DEAD }`. FLEE is implemented as a method `flee_from()` that sets state to PATROL. DESPAWN is implemented as `force_despawn()`. There are no `State.FLEE` or `State.DESPAWN` enum values.
**Decision needed:** Should FLEE and DESPAWN be promoted to first-class enum states in Monster.State (allowing `_state == State.FLEE` checks), or should the LLR be updated to reflect that flee and despawn are method-driven sub-behaviours?

---

### PRC-002 — LSHOP-001 / LHOME-001: Canonical gold storage location
**Current LLR text:** "Player gold tracked as integer."
**Issue:** Two competing sources exist: `PlayerInventory.currency: int = 50` (starting silver) and `PlayerStats.gold: int = 0`. Shop tests use `PlayerStats.gold`; the player starts with `PlayerInventory.currency`. There is no synchronisation between them.
**Decision needed:** Which property is the single source of truth for player currency? Recommend deprecating `PlayerStats.gold` and using `PlayerInventory.currency` exclusively, since `PlayerInventory` already tracks starting currency and the shop `spend_gold()` method is on `Player`.

---

### PRC-003 — LDSYS-006/007 and all passives: `effect_data` nesting in disciplines.json
**Current LLR text:** "Passive ability effects applied automatically."
**Issue:** All passive ability effect values in `disciplines.json` are stored as flat fields directly on the ability dict (e.g., `"melee_damage_multiplier": 1.2`). However, `DisciplineManager.get_passive_effect()` returns `ab.get("effect_data", {})`, looking for a nested sub-dict that does not exist anywhere in the JSON. As a result, every passive ability in the game silently falls back to hardcoded defaults — the JSON values are never read.
**Decision needed:** Either (A) add an `"effect_data": { ... }` sub-object to every passive ability in `disciplines.json` containing the effect values, or (B) change `DisciplineManager.get_passive_effect()` to return the ability dict directly. Option B is simpler and requires no data changes.

---

### PRC-004 — LRNG-004/005: Misfire and hangfire implementation
**Current LLR text:** "Misfire chance increases as condition falls below misfire_threshold. Hangfire: delayed 0.3–0.8s before firing or misfiring."
**Issue:** `PlayerCombat._try_fire()` does not check `condition` or implement misfire probability. The `misfire_threshold` and `condition_loss_per_shot` fields exist in weapon data but are not read anywhere in the implementation.
**Decision needed:** Confirm the misfire mechanic is in scope for the current build and provide the exact formula: (a) what triggers condition loss, (b) the probability curve below `misfire_threshold`, (c) whether hangfire is a random delay or always 0.3–0.8s.

---

### PRC-005 — LINJ-002: Injury probability — global weight vs. per-source table
**Current LLR text:** "Injury type weighted by probability_by_source (monster hit, fall, cold, etc.)"
**Issue:** `PlayerHealth._try_inflict_random_injury()` uses a single `probability_weight` float per injury. There is no per-damage-source table in the data or code. The field `probability_by_source` does not exist in `injuries.json`.
**Decision needed:** Is source-dependent injury weighting required? If yes, add `probability_by_source: { "melee": float, "fall": float, "cold": float }` to each injury entry and update `try_combat_injury_roll()` to pass the source type. If no, update the LLR to reference `probability_weight` instead.

---

### PRC-006 — LECO-005: `bridge_rivers` — data-driven vs. hardcoded tier index
**Current LLR text:** "Town tier enables river crossing (bridge_rivers = true)."
**Issue:** `AreaManager` uses `TOWN_TIER_INDEX = 2` as a hardcoded constant for river-crossing logic. It does not read `bridge_rivers` from `settlement_tiers.json`, even though that field exists there.
**Decision needed:** Should `bridge_rivers` be the authoritative source (requiring `AreaManager` to read it from tier data), or is `TOWN_TIER_INDEX = 2` the implementation (in which case remove `bridge_rivers` from the JSON as it is misleading dead data)?

---

### PRC-007 — LHOME-004/005: `services` field — Array vs. Dictionary
**Current LLR text:** "Settlement tier defines available services (porter, alchemy_workshop, etc.)"
**Issue:** Tests use `assert_has(tier["services"], "porter")`. If `services` is a Dictionary, `assert_has` checks key existence; if it is an Array, it checks element containment. The correct structure is ambiguous.
**Decision needed:** Confirm whether `services` in `settlement_tiers.json` is an Array of service-name strings or a Dictionary mapping service names to configuration. The test will work either way but the code that reads it must be consistent.

---

### PRC-008 — LNAV-014: `pathfinder` discipline and `wayfinder` ability
**Current LLR text:** "Wayfinder ability increases survey radius by 1.5×."
**Issue:** The `pathfinder` discipline may not be authored in `disciplines.json`. The test asserts a `wayfinder` ability with `survey_radius_mult == 1.5` exists inside the `pathfinder` discipline, but if `pathfinder` is not a launch-day discipline the test will fail.
**Decision needed:** Confirm whether `pathfinder` is a launch-day discipline. If yes, author the discipline and its `wayfinder` ability in `disciplines.json`. If no, mark LNAV-014 as out-of-scope for the current version and skip or remove the test.

---

### PRC-009 — LROAD-007: `road_budget` — data-driven vs. hardcoded
**Current LLR text:** "Road-building budget configurable."
**Issue:** `road_budget = 9` is set as a hardcoded assignment in `DataLoader._load_all()`, not read from a JSON file. Changing it requires a code edit.
**Decision needed:** Should `road_budget` be moved to a JSON data file (e.g., `roads.json`) to be truly configurable per the LLR, or is it acceptable as a code constant? If data-driven, specify which file and key.

---

### PRC-010 — LRUNE-004: `life_steal` rune ID and `allowed_slot_types` validation
**Current LLR text:** "Life Steal rune restricted to melee slots only."
**Issue:** The test assumes a rune with ID `life_steal` exists in `runes.json` with a `"ranged"` not in `allowed_slot_types`. Neither the rune ID nor the slot-type validation logic in `PlayerInventory.socket_rune()` is confirmed to exist.
**Decision needed:** (a) Confirm `life_steal` is the canonical rune ID. (b) Confirm `allowed_slot_types` is the correct field name. (c) Confirm that `socket_rune()` validates slot type against this field and rejects invalid sockets.
