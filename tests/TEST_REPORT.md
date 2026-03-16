# The Frontier — Test Report

**LLR Version:** v0.5.1
**HLR Version:** v0.5.0
**GDD Version:** v8
**Git Commit:** 7cf61e8 (Add active ability system, all UI screens, NPC/camp/audio/road systems)
**Test Run Date:** 2026-03-16
**Test Suite:** pytest (Python) + GUT stubs (Godot runtime)

---

## Summary

| Category | Total LLRs | Testable (T) | Untestable (U) | Python Tests | GUT Stubs |
|---|---|---|---|---|---|
| LCORE | 14 | 10 | 4 | 4 | 6 |
| LDATA | 42 | 42 | 0 | 42 | 0 |
| LMAP | 52 | 49 | 3 | 12 | 37 |
| LPC | 38 | 36 | 2 | 0 | 38 |
| LHP | 15 | 15 | 0 | 4 | 15 |
| LINJ | 12 | 12 | 0 | 2 | 12 |
| LSURV | 21 | 21 | 0 | 4 | 21 |
| LMEL | 10 | 10 | 0 | 1 | 10 |
| LBOW | 11 | 11 | 0 | 0 | 11 |
| LRNG | 13 | 13 | 0 | 0 | 13 |
| LRUNE | 5 | 5 | 0 | 4 | 5 |
| LMAI | 13 | 13 | 0 | 0 | 13 |
| LSPN | 5 | 5 | 0 | 3 | 5 |
| LNAV | 44 | 44 | 0 | 0 | 44 |
| LFOUND | 12 | 11 | 1 | 0 | 12 |
| LCAMP | 12 | 11 | 1 | 0 | 12 |
| LHIRE | 18 | 18 | 0 | 2 | 18 |
| LECO | 10 | 10 | 0 | 3 | 10 |
| LTRADE | 5 | 5 | 0 | 3 | 5 |
| LSCORE | 10 | 10 | 0 | 7 | 10 |
| LEXPORT | 3 | 3 | 0 | 3 | 3 |
| LROAD | 19 | 19 | 0 | 5 | 19 |
| LSHOP | 3 | 3 | 0 | 0 | 3 |
| LHOME | 6 | 6 | 0 | 0 | 6 |
| LSLEEP | 22 | 22 | 0 | 5 | 22 |
| LDSYS | 10 | 10 | 0 | 1 | 10 |
| LSURV-A | 16 | 16 | 0 | 0 | 16 |
| LRIT-A | 25 | 25 | 0 | 2 | 25 |
| LPATH-A | 6 | 5 | 1 | 0 | 6 |
| LWAR-A | 12 | 12 | 0 | 2 | 12 |
| LSWD-A | 19 | 19 | 0 | 2 | 19 |
| LART-A | 15 | 15 | 0 | 0 | 15 |
| LALC-A | 10 | 10 | 0 | 0 | 10 |
| LSCH-A | 16 | 16 | 0 | 0 | 16 |
| LWIZ-A | 15 | 15 | 0 | 0 | 15 |
| LINV | 10 | 10 | 0 | 1 | 10 |
| LCRAFT | 13 | 13 | 0 | 0 | 13 |
| LUI | 15 | 15 | 0 | 0 | 15 |
| LAUD | 10 | 7 | 3 | 1 | 7 |
| LSAVE | 28 | 28 | 0 | 1 | 28 |
| LPROJ | 5 | 5 | 0 | 5 | 0 |
| **TOTAL** | **~456** | **~440** | **~16** | **~119** | **~456** |

---

## Python Test Results (pytest — Runnable in Container)

> Run with: `cd /workspace && python3 -m pytest tests/test_data_schemas.py tests/test_project_structure.py tests/test_game_logic.py -v`

### test_data_schemas.py

| Test | LLR | Result | Notes |
|---|---|---|---|
| test_data_file_exists_and_parseable[monsters.json] | LDATA-001 | **FAIL** | File is at `data/monsters/monsters.json`, not flat `data/monsters.json` |
| test_data_file_exists_and_parseable[spawn_tables.json] | LDATA-002 | **FAIL** | File does not exist |
| test_data_file_exists_and_parseable[resources.json] | LDATA-003 | **FAIL** | File does not exist |
| test_data_file_exists_and_parseable[areas.json] | LDATA-004 | **FAIL** | File is at `data/areas/area_format.json`, not flat `data/areas.json` |
| test_data_file_exists_and_parseable[settlement_tiers.json] | LDATA-005 | **FAIL** | File is at `data/settlements/settlement_tiers.json` |
| test_data_file_exists_and_parseable[trade_weights.json] | LDATA-006 | **FAIL** | File does not exist |
| test_data_file_exists_and_parseable[export_thresholds.json] | LDATA-007 | **FAIL** | Embedded in `manufactured_goods.json`, no dedicated file |
| test_data_file_exists_and_parseable[disciplines.json] | LDATA-008 | **FAIL** | File is at `data/disciplines/disciplines.json` |
| test_data_file_exists_and_parseable[reagents.json] | LDATA-009 | **FAIL** | File is at `data/reagents/reagents.json` |
| test_data_file_exists_and_parseable[runes.json] | LDATA-010 | **FAIL** | File is at `data/runes/runes.json` |
| test_data_file_exists_and_parseable[items.json] | LDATA-011 | **FAIL** | File is at `data/items/items.json` |
| test_data_file_exists_and_parseable[injuries.json] | LDATA-012 | **FAIL** | File is at `data/injuries/injuries.json` |
| test_data_file_exists_and_parseable[weapons.json] | LDATA-013 | **FAIL** | File is at `data/weapons/weapons.json` |
| test_data_file_exists_and_parseable[seasons.json] | LDATA-014 | **FAIL** | File is at `data/seasons/seasons.json` |
| test_data_file_exists_and_parseable[survival.json] | LDATA-015 | **FAIL** | File is at `data/survival/survival_params.json` |
| test_data_file_exists_and_parseable[recipes.json] | LDATA-016 | **FAIL** | File is at `data/recipes/recipes.json` |
| test_data_file_exists_and_parseable[manufactured_goods.json] | LDATA-017 | **FAIL** | File is at `data/settlements/manufactured_goods.json` |
| test_data_file_exists_and_parseable[hirelings.json] | LDATA-018 | **FAIL** | File is at `data/hirelings/hirelings.json` |
| test_data_file_exists_and_parseable[roads.json] | LDATA-019 | **FAIL** | File does not exist at flat path |
| test_data_file_exists_and_parseable[landmarks.json] | LDATA-020 | **FAIL** | File does not exist |
| test_monsters_schema_ldata030 | LDATA-030 | **SKIP** | Blocked by LDATA-001 file location |
| test_areas_schema_ldata031 | LDATA-031 | **SKIP** | Blocked by LDATA-004; `area_format.json` is reference doc, not data |
| test_edge_features_schema_ldata032 | LDATA-032 | **SKIP** | Blocked by LDATA-004 |
| test_settlement_tiers_schema_ldata033 | LDATA-033 | **SKIP** | Blocked by LDATA-005 flat path |
| test_runes_schema_ldata034 | LDATA-034 | **SKIP** | Blocked by LDATA-010 flat path |
| test_items_schema_ldata035 | LDATA-035 | **SKIP** | Blocked by LDATA-011 flat path |
| test_waterskin_weight_empty_ldata036 | LDATA-036 | **SKIP** | Blocked by LDATA-011 flat path |
| test_injuries_schema_ldata037 | LDATA-037 | **SKIP** | Blocked by LDATA-012 flat path |
| test_weapons_schema_ldata038 | LDATA-038 | **SKIP** | Blocked by LDATA-013 flat path |
| test_disciplines_schema_ldata039 | LDATA-039 | **SKIP** | Blocked by LDATA-008 flat path |
| test_reagents_schema_ldata040 | LDATA-040 | **SKIP** | Blocked by LDATA-009 flat path |
| test_discipline_count_ldata041 | LDATA-041 | **SKIP** | Blocked by flat path; current file has 7 disciplines (needs 9) |
| test_ability_count_ldata041 | LDATA-041 | **SKIP** | Blocked by flat path; needs 61 abilities total |
| test_injury_count_ldata042 | LDATA-042 | **SKIP** | Blocked by flat path; current file has 7 injuries ✓ (when accessible) |
| test_trade_weights_schema | LDATA-006 | **FAIL** | File does not exist |
| test_export_thresholds_schema | LDATA-007 | **FAIL** | No dedicated `export_thresholds.json` |
| test_seasons_schema | LDATA-014 | **SKIP** | Blocked by flat path |
| test_survival_schema | LDATA-015 | **SKIP** | Blocked by flat path |
| test_hirelings_schema | LDATA-018 | **SKIP** | Blocked by flat path |
| test_roads_schema | LDATA-019 | **FAIL** | `data/roads/` directory is empty |
| test_manufactured_goods_schema | LDATA-017 | **SKIP** | Blocked by flat path |
| test_bows_have_2_rune_slots_lbow006 | LBOW-006 | **SKIP** | Blocked by flat path |
| test_muskets_have_2_rune_slots_lrng004 | LRNG-004 | **SKIP** | Blocked by flat path |
| test_pistols_have_1_rune_slot_lrng005 | LRNG-005 | **SKIP** | Blocked by flat path |
| test_shields_have_1_rune_slot_lmel010 | LMEL-010 | **SKIP** | Blocked by flat path |
| test_shield_block_reduction_greater_lmel005 | LMEL-005 | **SKIP** | Blocked by flat path |
| test_rune_rarity_poisson_mean_lrune003 | LRUNE-003 | **SKIP** | Blocked by flat path |
| test_life_steal_rune_slot_types_lrune004 | LRUNE-004 | **SKIP** | Blocked by flat path |
| test_waterskin_empty_weight_lsurv016 | LSURV-016 | **SKIP** | Blocked by flat path |
| test_waterskin_full_weight_lsurv017 | LSURV-017 | **SKIP** | Blocked by flat path |
| test_cold_weather_clothing_weight_lsurv010 | LSURV-010 | **SKIP** | Blocked by flat path |
| test_cold_tent_heavier_lsurv011 | LSURV-011 | **SKIP** | Blocked by flat path |
| test_road_budget_is_9_lroad001 | LROAD-001 | **SKIP** | Blocked by flat path |
| test_exploitation_percentages_leco006_to_009 | LECO-006..009 | **SKIP** | Blocked by flat path |

### test_project_structure.py

| Test | LLR | Result | Notes |
|---|---|---|---|
| test_project_godot_exists_lcore001 | LCORE-001 | **PASS** | `project.godot` exists |
| test_godot_version_is_4x_lcore001 | LCORE-001 | **PASS** | config_version=5 present |
| test_target_fps_set_lcore005 | LCORE-005 | **PASS** | target_fps set in project.godot |
| test_default_input_json_exists_lcore007 | LCORE-007 | **FAIL** | `data/default_input.json` not found |
| test_scene_subdirectory[player] | LPROJ-001 | **PASS** | `scenes/player/` exists |
| test_scene_subdirectory[monsters] | LPROJ-001 | **PASS** | `scenes/monsters/` exists |
| test_scene_subdirectory[settlements] | LPROJ-001 | **FAIL** | `scenes/settlements/` not found (has `scenes/settlement/`) |
| test_scene_subdirectory[camps] | LPROJ-001 | **FAIL** | `scenes/camps/` not found (has `scenes/camp/`) |
| test_scene_subdirectory[ui] | LPROJ-001 | **PASS** | `scenes/ui/` exists |
| test_scene_subdirectory[map] | LPROJ-001 | **FAIL** | `scenes/map/` not found |
| test_scene_subdirectory[precursor] | LPROJ-001 | **FAIL** | `scenes/precursor/` not found |
| test_script_subdirectory[autoloads] | LPROJ-002 | **PASS** | exists |
| test_script_subdirectory[player] | LPROJ-002 | **PASS** | exists |
| test_script_subdirectory[monsters] | LPROJ-002 | **PASS** | exists |
| test_script_subdirectory[ui] | LPROJ-002 | **PASS** | exists |
| test_script_subdirectory[abilities] | LPROJ-002 | **FAIL** | `scripts/abilities/` not found (has `scripts/disciplines/`) |
| test_autoload_script_exists[DataLoader] | LPROJ-003 | **FAIL** | `scripts/autoloads/DataLoader.gd` not found (has `GameData.gd`) |
| test_autoload_script_exists[SaveManager] | LPROJ-003 | **PASS** | exists |
| test_autoload_script_exists[InputManager] | LPROJ-003 | **FAIL** | not found |
| test_autoload_script_exists[TimeManager] | LPROJ-003 | **FAIL** | not found (time in GameState.gd) |
| test_autoload_script_exists[SeasonManager] | LPROJ-003 | **FAIL** | not found (in GameState.gd) |
| test_autoload_script_exists[WeatherManager] | LPROJ-003 | **FAIL** | not found (in GameState.gd) |
| test_autoload_script_exists[AreaManager] | LPROJ-003 | **FAIL** | not found (has WorldManager.gd) |
| test_autoload_script_exists[HexGrid] | LPROJ-003 | **FAIL** | not found |
| test_autoload_script_exists[SettlementManager] | LPROJ-003 | **PASS** | exists |
| test_autoload_script_exists[SpawnManager] | LPROJ-003 | **FAIL** | not in autoloads/ (in monsters/) |
| test_autoload_script_exists[DisciplineManager] | LPROJ-003 | **PASS** | exists |
| test_autoload_script_exists[AudioManager] | LPROJ-003 | **FAIL** | not in autoloads/ (in world/) |
| test_autoload_script_exists[MusicManager] | LPROJ-003 | **FAIL** | not found |
| test_autoload_script_exists[TradeGraph] | LPROJ-003 | **FAIL** | not found (logic in EconomyManager) |
| test_autoload_script_exists[FoundingManager] | LPROJ-003 | **FAIL** | not found |
| test_autoload_script_exists[PlayerStats] | LPROJ-003 | **FAIL** | not found (logic spread across player scripts) |
| test_autoload_registered_in_project_godot[*] | LPROJ-003 | **FAIL** | Most new autoloads not registered |
| test_data_directory_exists_lproj004 | LPROJ-004 | **PASS** | `data/` exists |
| test_main_scene_exists_lcore002 | LCORE-002 | **PASS** | `scenes/main/Main.tscn` exists |
| test_main_scene_has_world_environment | LCORE-002 | **PASS** | WorldEnvironment in Main.tscn |
| test_player_scene_root_is_character_body_3d | LPC-001 | **PASS** | CharacterBody3D in Player.tscn |
| test_player_scene_has_collision_camera_hud | LPC-002 | **PASS** | All node types present |
| test_monster_base_has_navigation_agent | LMAI-001 | **FAIL** | MonsterBase.tscn lacks NavigationAgent3D |
| test_camp_has_omni_light | LCAMP-010 | **PASS** | OmniLight3D in camp scene |
| test_data_file_is_flat[*] | LPROJ-004 | **FAIL** | All 20 files in subdirs, not flat |

### test_game_logic.py

| Test | LLR | Result | Notes |
|---|---|---|---|
| test_hex_to_world_and_back | LMAP-001,002 | **PASS** | Pure math |
| test_hex_neighbor_count | LMAP-003 | **PASS** | |
| test_hex_neighbors_are_distance_1 | LMAP-003 | **PASS** | |
| test_hex_distance_symmetric | LMAP-004 | **PASS** | |
| test_hex_distance_zero_for_self | LMAP-004 | **PASS** | |
| test_hex_ring_count | LMAP-005 | **PASS** | |
| test_hex_ring_all_at_correct_distance | LMAP-005 | **PASS** | |
| test_shared_edge_index | LMAP-006 | **PASS** | |
| test_time_ratio_lmap021 | LMAP-021 | **PASS** | 48x ratio confirmed |
| test_precursor_min_pop_sites | LMAP-042 | **PASS** | ≥18 PoP sites |
| test_precursor_min_2_per_discipline | LMAP-042 | **PASS** | Min 2 per discipline |
| test_rune_effect_value_clamped | LRUNE-001,002 | **PASS** | Poisson clamp logic correct |
| test_higher_rarity_higher_mean | LRUNE-003 | **PASS** | |
| test_trade_score_increases_with_output | LSCORE-006 | **PASS** | |
| test_trade_score_increases_with_connections | LSCORE-006 | **PASS** | |
| test_trade_score_increases_with_diversity | LSCORE-006 | **PASS** | |
| test_tier_advancement_requires_score | LSCORE-007 | **PASS** | |
| test_local_output_trading_post | LSCORE-001,LECO-006 | **PASS** | Own area only |
| test_local_output_village_includes_adjacent | LSCORE-001,LECO-007 | **PASS** | 50% adjacent |
| test_local_output_city_includes_ring2 | LSCORE-001,LECO-009 | **PASS** | 25% ring-2 |
| test_consumption_reduces_remaining | LSCORE-002 | **PASS** | |
| test_consumption_only_raw_materials | LSCORE-004 | **PASS** | |
| test_dijkstra_finds_nearest_port | LTRADE-002 | **PASS** | |
| test_dijkstra_hop_count_edge_weight | LTRADE-002 | **PASS** | 1 hop per edge |
| test_dijkstra_stores_route_path | LTRADE-003 | **PASS** | |
| test_export_threshold_low | LEXPORT-001,002 | **PASS** | All thresholds correct |
| test_export_global_value_is_sum | LEXPORT-001 | **PASS** | |
| test_export_thresholds_json_structure | LDATA-007 | **SKIP** | File missing |
| test_road_budget_is_9 | LROAD-001 | **SKIP** | settlement_tiers.json at wrong path |
| test_road_cost_equals_hex_distance | LROAD-002 | **PASS** | Pure math |
| test_road_max_length | LROAD-015 | **PASS** | |
| test_road_budget_remaining | LROAD-010 | **PASS** | |
| test_road_target_not_charged | LROAD-008 | **PASS** | |
| test_road_quality_is_min_tier | LROAD-016 | **PASS** | |
| test_spawn_weight_formula | LSPN-002 | **PASS** | |
| test_spawn_weight_zero_in_safe_zone | LSPN-003 | **PASS** | |
| test_spawn_weight_no_suppression | LSPN-002 | **PASS** | |
| test_batch_step_count | LSLEEP-003..021 | **PASS** | 19 steps |
| test_batch_steps_are_ordered | LSLEEP-003..021 | **PASS** | Steps 0-18 in order |
| test_founding_is_step_0 | LSLEEP-003 | **PASS** | |
| test_trade_route_after_extraction | LSLEEP-004,005 | **PASS** | |
| test_tier_check_after_trade_score | LSLEEP-006,007 | **PASS** | |
| test_auto_save_is_last | LSLEEP-021 | **PASS** | |
| test_hireling_cost_deducted | LHIRE-017 | **PASS** | |
| test_hireling_dismissed_if_insufficient | LHIRE-018 | **PASS** | |
| test_health_regen_base | LHP-004 | **PASS** | |
| test_health_regen_rest_multiplier | LHP-005 | **PASS** | |
| test_hunger_warn_threshold_stamina_penalty | LSURV-005 | **PASS** | |
| test_hunger_above_warn_no_penalty | LSURV-005 | **PASS** | |
| test_injury_threshold_triggers_roll | LINJ-001 | **PASS** | |
| test_injury_above_threshold_no_roll | LINJ-001 | **PASS** | |
| test_deathmark_activates_at_3 | LSWD-A19 | **PASS** | |
| test_deathmark_not_active_below_3 | LSWD-A19 | **PASS** | |
| test_ward_duration_and_cooldown | LRIT-A04,05 | **PASS** | |
| test_save_format_is_json | LSAVE-028 | **PASS** | SaveManager.gd uses JSON |
| test_max_attunements_is_3 | LDSYS-001 | **PASS** | |

---

## GUT Tests (Godot Runtime — NOT EXECUTABLE IN CONTAINER)

All tests in `tests/gut/*.gd` are stub functions requiring a running Godot 4 instance with GUT installed.

**Status for all GUT tests: NOT TESTABLE IN CONTAINER**

To run: Open project in Godot Editor → install GUT plugin → run GUT panel.

Files:
- `tests/gut/test_player_movement.gd` — LPC-010..016
- `tests/gut/test_player_health_survival.gd` — LHP-001..015, LINJ-001..012, LSURV-001..021
- `tests/gut/test_combat.gd` — LMEL-001..010, LBOW-001..011, LRNG-001..013, LRUNE-001..005
- `tests/gut/test_monster_ai_spawn.gd` — LMAI-001..013, LSPN-001..005
- `tests/gut/test_disciplines.gd` — LDSYS-001..010, all ability LLRs (LSURV-A, LRIT-A, LPATH-A, LWAR-A, LSWD-A, LART-A, LALC-A, LSCH-A, LWIZ-A)
- `tests/gut/test_economy_settlements.gd` — LECO, LTRADE, LSCORE, LEXPORT, LROAD, LSHOP, LHOME, LSLEEP, LUI, LSAVE
- `tests/gut/test_navigation_founding_camps.gd` — LNAV, LFOUND, LCAMP, LHIRE, LINV, LCRAFT, LUI

---

## Gap Analysis — Work Required to Pass All Tests

### Critical (blocks all schema tests)
1. **Restructure data/ to flat layout** — Move all JSON files to `data/filename.json` directly. Rename as needed:
   - `data/survival/survival_params.json` → `data/survival.json`
   - `data/areas/area_format.json` → `data/areas.json` (real data, not just format doc)
   - All other files move from subdirectory to flat
2. **Create missing data files**: `spawn_tables.json`, `resources.json`, `trade_weights.json`, `export_thresholds.json`, `landmarks.json`, `roads.json`, `default_input.json`

### High Priority (structure gaps)
3. **Rename/create autoload scripts** per LPROJ-003:
   - `GameData.gd` → `DataLoader.gd`
   - `WorldManager.gd` → `AreaManager.gd`
   - `GameState.gd` → split into `TimeManager.gd`, `SeasonManager.gd`, `WeatherManager.gd`
   - New: `InputManager.gd`, `HexGrid.gd`, `MusicManager.gd`, `TradeGraph.gd`, `FoundingManager.gd`, `PlayerStats.gd`
4. **Rename scene directories**: `scenes/settlement/` → `scenes/settlements/`, `scenes/camp/` → `scenes/camps/`
5. **Add new scene directories**: `scenes/map/`, `scenes/precursor/`
6. **Rename script directory**: `scripts/disciplines/` → `scripts/abilities/`
7. **Add NavigationAgent3D to MonsterBase.tscn** (LMAI-001)

### Data Schema Updates
8. **Discipline count** — disciplines.json currently has 7 disciplines, needs 9 (add Pathfinder, Scholar)
9. **Ability count** — needs 61 total abilities
10. **monsters.json** — add `model_path` and `light_reaction` fields
11. **areas.json** — add `hex_coords`, `neighbors[]`, `edge_features[]`, `precursor_site_index`, `spawn_table_id`
12. **items.json** — add `durability`, `value`, `rune_slots`, `noise_level`, `spoil_timer`, `tags[]`, `weight_empty` for waterskins
13. **settlement_tiers.json** — add `exploitation{}`, `consumption_rate`, `road_budget`
14. **runes.json** — add `poisson_mean`, `poisson_min`, `poisson_max`, `slot_types[]`
15. **weapons.json** — add `stamina_cost`, `speed`, `durability`, `weapon_category`
16. **reagents.json** — add `spell_id`, `tier`, `source`
17. **injuries.json** — add `causes[]`, `probability_by_source{}`
