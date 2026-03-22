# The Frontier — Test Report

**LLR Version:** v0.6.0
**HLR Version:** v0.6.0
**GDD Version:** v9
**Git Commit:** 877c2cf (Implement global HomeStorage, scan input action, and sending_chest item)
**Test Run Date:** 2026-03-17
**Test Suite:** pytest (Python) + GUT stubs (Godot runtime)

---

## Summary

| Suite | Collected | Pass | Fail | Skip |
|---|---|---|---|---|
| test_data_schemas.py | 67 | 64 | 3 | 0 |
| test_project_structure.py | 62 | 58 | 4 | 0 |
| test_game_logic.py | 82 | 82 | 0 | 2 (skip — data) |
| **TOTAL** | **211** | **204** | **7** | **~2** |

> Run with: `cd /workspace && python3 -m pytest tests/test_data_schemas.py tests/test_project_structure.py tests/test_game_logic.py -v`

---

## Failing Tests (7)

| Test | LLR | Failure Reason |
|---|---|---|
| `test_data_file_exists_and_parseable[hex_templates.json]` | LDATA-044 | `data/hex_templates.json` does not exist yet |
| `test_hex_templates_schema_ldata044` | LDATA-044 | blocked by above |
| `test_data_file_is_flat_not_in_subdir[hex_templates.json]` | LPROJ-004 | blocked by above |
| `test_discipline_count_ldata041` | LDATA-041 | disciplines.json has **9** disciplines; v0.6.0 requires **4** launch |
| `test_ability_count_ldata041` | LDATA-041 | disciplines.json has **61** abilities; v0.6.0 requires **28** launch |
| `test_autoload_script_exists[CombatManager]` | LPROJ-003 | `scripts/autoloads/CombatManager.gd` does not exist yet |
| `test_autoload_registered_in_project_godot[CombatManager]` | LPROJ-003 | not in project.godot autoload list |

---

## Passing Tests — test_data_schemas.py (64/67)

| Test | LLR | Result |
|---|---|---|
| test_data_file_exists_and_parseable[monsters.json] | LDATA-001 | **PASS** |
| test_data_file_exists_and_parseable[spawn_tables.json] | LDATA-002 | **PASS** |
| test_data_file_exists_and_parseable[resources.json] | LDATA-003 | **PASS** |
| test_data_file_exists_and_parseable[areas.json] | LDATA-004 | **PASS** |
| test_data_file_exists_and_parseable[settlement_tiers.json] | LDATA-005 | **PASS** |
| test_data_file_exists_and_parseable[trade_weights.json] | LDATA-006 | **PASS** |
| test_data_file_exists_and_parseable[export_thresholds.json] | LDATA-007 | **PASS** |
| test_data_file_exists_and_parseable[disciplines.json] | LDATA-008 | **PASS** |
| test_data_file_exists_and_parseable[reagents.json] | LDATA-009 | **PASS** |
| test_data_file_exists_and_parseable[runes.json] | LDATA-010 | **PASS** |
| test_data_file_exists_and_parseable[items.json] | LDATA-011 | **PASS** |
| test_data_file_exists_and_parseable[injuries.json] | LDATA-012 | **PASS** |
| test_data_file_exists_and_parseable[weapons.json] | LDATA-013 | **PASS** |
| test_data_file_exists_and_parseable[seasons.json] | LDATA-014 | **PASS** |
| test_data_file_exists_and_parseable[survival.json] | LDATA-015 | **PASS** |
| test_data_file_exists_and_parseable[recipes.json] | LDATA-016 | **PASS** |
| test_data_file_exists_and_parseable[manufactured_goods.json] | LDATA-017 | **PASS** |
| test_data_file_exists_and_parseable[hirelings.json] | LDATA-018 | **PASS** |
| test_data_file_exists_and_parseable[roads.json] | LDATA-019 | **PASS** |
| test_data_file_exists_and_parseable[landmarks.json] | LDATA-020 | **PASS** |
| test_data_file_exists_and_parseable[hex_templates.json] | LDATA-044 | **FAIL** |
| test_monsters_schema_ldata030 | LDATA-030 | **PASS** |
| test_areas_schema_ldata031 | LDATA-031 | **PASS** |
| test_edge_features_schema_ldata032 | LDATA-032 | **PASS** |
| test_settlement_tiers_schema_ldata033 | LDATA-033 | **PASS** |
| test_runes_schema_ldata034 | LDATA-034 | **PASS** |
| test_items_schema_ldata035 | LDATA-035 | **PASS** |
| test_waterskin_weight_empty_ldata036 | LDATA-036 | **PASS** |
| test_injuries_schema_ldata037 | LDATA-037 | **PASS** |
| test_weapons_schema_ldata038 | LDATA-038 | **PASS** |
| test_disciplines_schema_ldata039 | LDATA-039 | **PASS** |
| test_reagents_schema_ldata040 | LDATA-040 | **PASS** |
| test_discipline_count_ldata041 | LDATA-041 | **FAIL** — has 9, needs 4 |
| test_ability_count_ldata041 | LDATA-041 | **FAIL** — has 61, needs 28 |
| test_injury_count_ldata042 | LDATA-042 | **PASS** — 7 injuries ✓ |
| test_behavior_type_ldata043 | LDATA-043 | **PASS** |
| test_hex_templates_schema_ldata044 | LDATA-044 | **FAIL** — file missing |
| test_trade_weights_schema | LDATA-006 | **PASS** |
| test_export_thresholds_schema | LDATA-007 | **PASS** |
| test_seasons_schema | LDATA-014 | **PASS** |
| test_survival_schema | LDATA-015 | **PASS** |
| test_hirelings_schema | LDATA-018 | **PASS** |
| test_roads_schema | LDATA-019 | **PASS** |
| test_manufactured_goods_schema | LDATA-017 | **PASS** |
| test_bows_have_2_rune_slots_lbow006 | LBOW-006 | **PASS** |
| test_muskets_have_2_rune_slots_lrng004 | LRNG-004 | **PASS** |
| test_pistols_have_1_rune_slot_lrng005 | LRNG-005 | **PASS** |
| test_shields_have_1_rune_slot_lmel010 | LMEL-010 | **PASS** |
| test_shield_block_reduction_greater_lmel005 | LMEL-005 | **PASS** |
| test_rune_rarity_poisson_mean_lrune003 | LRUNE-003 | **PASS** |
| test_life_steal_rune_slot_types_lrune004 | LRUNE-004 | **PASS** |
| test_waterskin_empty_weight_lsurv016 | LSURV-016 | **PASS** |
| test_waterskin_full_weight_lsurv017 | LSURV-017 | **PASS** |
| test_cold_weather_clothing_weight_lsurv010 | LSURV-010 | **PASS** |
| test_cold_tent_heavier_lsurv011 | LSURV-011 | **PASS** |
| test_road_budget_is_9_lroad001 | LROAD-001 | **PASS** |
| test_exploitation_percentages_leco006_to_009 | LECO-006..009 | **PASS** |

---

## Passing Tests — test_project_structure.py (58/62)

| Test | LLR | Result |
|---|---|---|
| test_project_godot_exists_lcore001 | LCORE-001 | **PASS** |
| test_godot_version_is_4x_lcore001 | LCORE-001 | **PASS** |
| test_target_fps_set_lcore005 | LCORE-005 | **PASS** |
| test_default_input_json_exists_lcore007 | LCORE-007 | **PASS** |
| test_scene_subdirectory[player] | LPROJ-001 | **PASS** |
| test_scene_subdirectory[monsters] | LPROJ-001 | **PASS** |
| test_scene_subdirectory[settlements] | LPROJ-001 | **PASS** |
| test_scene_subdirectory[camps] | LPROJ-001 | **PASS** |
| test_scene_subdirectory[ui] | LPROJ-001 | **PASS** |
| test_scene_subdirectory[map] | LPROJ-001 | **PASS** |
| test_scene_subdirectory[precursor] | LPROJ-001 | **PASS** |
| test_script_subdirectory[autoloads] | LPROJ-002 | **PASS** |
| test_script_subdirectory[player] | LPROJ-002 | **PASS** |
| test_script_subdirectory[monsters] | LPROJ-002 | **PASS** |
| test_script_subdirectory[ui] | LPROJ-002 | **PASS** |
| test_script_subdirectory[abilities] | LPROJ-002 | **PASS** |
| test_autoload_script_exists[DataLoader] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[SaveManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[InputManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[TimeManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[AreaManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[HexGrid] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[SettlementManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[SpawnManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[DisciplineManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[AudioManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[TradeGraph] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[FoundingManager] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[PlayerStats] | LPROJ-003 | **PASS** |
| test_autoload_script_exists[CombatManager] | LPROJ-003 | **FAIL** — not created yet |
| test_autoload_registered_in_project_godot[DataLoader] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[SaveManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[InputManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[TimeManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[AreaManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[HexGrid] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[SettlementManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[SpawnManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[DisciplineManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[AudioManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[TradeGraph] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[FoundingManager] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[PlayerStats] | LPROJ-003 | **PASS** |
| test_autoload_registered_in_project_godot[CombatManager] | LPROJ-003 | **FAIL** — not registered |
| test_data_directory_exists_lproj004 | LPROJ-004 | **PASS** |
| test_main_scene_exists_lcore002 | LCORE-002 | **PASS** |
| test_main_scene_has_world_environment | LCORE-002 | **PASS** |
| test_player_scene_root_is_character_body_3d | LPC-001 | **PASS** |
| test_player_scene_has_collision_camera_hud | LPC-002 | **PASS** |
| test_monster_base_has_navigation_agent | LMAI-001 | **PASS** |
| test_camp_has_omni_light | LCAMP-009 | **PASS** |
| test_data_file_is_flat[monsters.json] | LPROJ-004 | **PASS** |
| test_data_file_is_flat[…all 20 existing files…] | LPROJ-004 | **PASS** |
| test_data_file_is_flat[hex_templates.json] | LPROJ-004 | **FAIL** — file missing |

---

## Passing Tests — test_game_logic.py (82/82)

All 82 logic tests pass. Sections covered:

| Section | LLR IDs | Tests | Result |
|---|---|---|---|
| HexGrid math | LMAP-001..006 | 8 | **PASS** |
| Edge/area passability | LMAP-015..020 | 7 | **PASS** |
| Time ratio | LMAP-031 | 1 | **PASS** |
| Precursor randomizer | LMAP-047 | 2 | **PASS** |
| Poisson/rune clamping | LRUNE-001..003 | 2 | **PASS** |
| Trade score formula | LSCORE-001..009 | 8 | **PASS** |
| Consumption along routes | LSCORE-002..004 | 2 | **PASS** |
| Dijkstra routing | LTRADE-002..003 | 3 | **PASS** |
| Export threshold logic | LEXPORT-001..002 | 3 | **PASS** |
| Resource claim conflict | LECO-011..013 | 4 | **PASS** |
| Road budget/cost | LROAD-001..016 | 6 | **PASS** |
| Spawn weight formula | LSPN-002..003 | 3 | **PASS** |
| Batch step ordering | LSLEEP-003..023 | 7 | **PASS** |
| Survival thresholds | LSURV-005,022..027 | 10 | **PASS** |
| Injury roll | LINJ-001 | 2 | **PASS** |
| Combat state | LCBT-001..004 | 4 | **PASS** |
| Deathmark logic | LSWD-A19 | 2 | **PASS** |
| Ward timing | LRIT-A04,05 | 1 | **PASS** |
| Hireling costs | LHIRE-017..018 | 2 | **PASS** |
| Health regen | LHP-004..005 | 2 | **PASS** |
| Attunement cap | LDSYS-001 | 1 | **PASS** |
| Save format | LSAVE-028 | 1 | **PASS** |

---

## GUT Tests (Godot Runtime — NOT EXECUTABLE IN CONTAINER)

All tests in `tests/gut/*.gd` are stub functions requiring a running Godot 4 instance with GUT installed.

To run: Open project in Godot Editor → install GUT plugin → run GUT panel.

---

## Remaining Gaps (3 items)

| # | Gap | LLR | Fix |
|---|---|---|---|
| 1 | `data/hex_templates.json` does not exist | LDATA-044 | Create file listing template_id, biome_type, scene_path per hex template |
| 2 | `disciplines.json` has 9 disciplines / 61 abilities; needs 4 / 28 | LDATA-041 | Trim to 4 launch disciplines (Survivalist, Warrior, Artificer, Alchemist) with 7 abilities each, or restructure per v0.6.0 spec |
| 3 | `CombatManager.gd` autoload does not exist | LPROJ-003 | Create `scripts/autoloads/CombatManager.gd` and register in project.godot |
