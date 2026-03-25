# THE FRONTIER
## High-Level Requirements — World Initialisation Revision (Option B)
### Data-Driven Settlement and Area Bootstrapping

**Companion to: HLR v0.6.0 | GDD v9**
**Scheduled: Post-horizontal-slice (after world geometry exists)**

> MUST = Required for this revision | SHOULD = Desired, can ship revision without | DEFER = Later revision

---

## Overview

This revision replaces the hardcoded `Crestport` scene node in `Main.tscn` with a
fully data-driven world initialisation pipeline. On new game or load, all pre-existing
settlements, area boundaries, and starting biome audio are derived from `areas.json`
and `data/settlements/`. No settlement should exist as a static node in a scene file.

---

## 1. Area Data

| ID | Requirement | Priority |
|---|---|---|
| WINIT-001 | Every entry in `areas.json` MUST include a `biome` field matching a key in `AudioManager.BIOME_AMBIENCE`. | MUST |
| WINIT-002 | Every entry in `areas.json` MUST include a `world_position` object `{ "x": float, "z": float }` giving the Area node's world-space origin. | MUST |
| WINIT-003 | Every entry in `areas.json` MUST include an `area_bounds` object `{ "x": float, "y": float, "z": float }` defining the AreaTrigger BoxShape3D half-extents. | MUST |
| WINIT-004 | `settlement_site` entries that have `has_settlement: true` MUST include a `settlement_id` string and a `world_position` object for the settlement node placement. | MUST |
| WINIT-005 | Area data MUST remain the single source of truth for which areas contain pre-existing settlements. No settlement IDs hardcoded anywhere in GDScript or scene files. | MUST |
| WINIT-006 | Area `difficulty`, `spawn_table_id`, and `resource_tags` fields already present in `areas.json` require no schema change. | MUST |

---

## 2. SettlementManager Bootstrapping

| ID | Requirement | Priority |
|---|---|---|
| WINIT-010 | `SettlementManager._ready()` MUST scan `DataLoader.areas` on startup and instantiate `Settlement.tscn` for every area whose `settlement_site.has_settlement == true`. | MUST |
| WINIT-011 | Each auto-instantiated Settlement MUST have its `settlement_id` and `area_id` set before `add_child()` so `_ready()` initialises correctly. | MUST |
| WINIT-012 | Auto-instantiated Settlements MUST be placed at the world position specified in `areas.json → settlement_site.world_position`. | MUST |
| WINIT-013 | `SettlementManager` MUST NOT instantiate a settlement that already exists in the scene tree (guard against double-instantiation on load). | MUST |
| WINIT-014 | On `load_game()`, `SettlementManager.apply_save_data()` MUST restore tier, population, trade inventory, and road connections rather than re-bootstrapping from `areas.json`. The bootstrap path runs only on new game. | MUST |
| WINIT-015 | `SettlementManager` SHOULD expose a `get_settlement_for_area(area_id)` helper returning the SettlementData for a given area, or null. | SHOULD |

---

## 3. WorldManager Area Registration

| ID | Requirement | Priority |
|---|---|---|
| WINIT-020 | Each Area node MUST read its `world_position` and `area_bounds` from `DataLoader.get_area(area_id)` at `_ready()` if not manually overridden via `@export`. | MUST |
| WINIT-021 | `Area._ready()` MUST set `global_position` from `world_position` data when the value is non-zero, so Area nodes can be placed by data without editor intervention. | MUST |
| WINIT-022 | Area nodes MUST be instantiated into the scene before `SettlementManager` bootstraps, so settlement nodes can be parented to or placed near their Area. The recommended order: WorldManager loads areas → SettlementManager bootstraps settlements. | MUST |
| WINIT-023 | `WorldManager` SHOULD expose `get_area_for_position(world_pos: Vector3) -> String` that returns the `area_id` of whichever active area contains the given position, enabling biome detection without an explicit trigger event. | SHOULD |

---

## 4. Area Instantiation Pipeline

| ID | Requirement | Priority |
|---|---|---|
| WINIT-030 | A new autoload or `WorldManager` method MUST iterate `DataLoader.areas` at new-game startup and instantiate one `Area.tscn` per entry, parented under `World` in the scene tree. | MUST |
| WINIT-031 | The `Main.tscn` `World` node MUST contain zero pre-placed Area or Settlement nodes after this revision. All are runtime-instantiated. | MUST |
| WINIT-032 | Area instantiation MUST complete before the player node's `_ready()` fires, so `on_player_enter()` can be called correctly for the starting area. To guarantee ordering, defer player spawn until `WorldManager` emits an `areas_ready` signal. | MUST |
| WINIT-033 | Area scene instantiation SHOULD be pooled or streamed rather than created all at once if the area count exceeds 50, to avoid a startup hitch. | SHOULD |

---

## 5. Starting Area and Respawn

| ID | Requirement | Priority |
|---|---|---|
| WINIT-040 | On new game, the player MUST be placed at the world position of the area whose `settlement_site.settlement_id == "crestport"`. | MUST |
| WINIT-041 | `GameState.current_area_id` MUST be set to `"crestport_bay"` at new game start, triggering `on_player_enter()` immediately so ambient audio and resource discovery fire correctly from frame 1. | MUST |
| WINIT-042 | On respawn after death, the player MUST be placed at the world position of the last visited settlement with a tier of village or above, read from `SettlementManager`. | MUST |

---

## 6. Removal of Hardcoded Crestport Node

| ID | Requirement | Priority |
|---|---|---|
| WINIT-050 | The `Crestport` node (`instance=Settlement.tscn`, `settlement_id="crestport"`) MUST be removed from `Main.tscn` as part of this revision. | MUST |
| WINIT-051 | Any script that references `$World/Crestport` by node path MUST be updated to use `SettlementManager.get_settlement("crestport")` instead. | MUST |
| WINIT-052 | All GUT tests that currently pass with the hardcoded Crestport node MUST continue to pass after the node is removed. No tests may be rewritten to accommodate the transition — fix the implementation. | MUST |

---

## 7. Dependencies and Prerequisites

This revision MUST NOT begin until all of the following are complete:

- World geometry exists (terrain meshes or at minimum placeholder collision geometry per area), so `world_position` values in `areas.json` refer to real locations in the scene.
- `Area.tscn` collision shapes are sized and tested against real terrain (WINIT-002/003 depend on this).
- The horizontal-slice prototype (MAP-020) is playable, providing real world positions for the 6 Eastern Frontier areas.

Attempting this revision against a placeholder `World` node without geometry will require a second pass to correct world positions, wasting effort.
