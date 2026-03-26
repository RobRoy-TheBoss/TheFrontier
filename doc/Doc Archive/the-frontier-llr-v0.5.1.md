# THE FRONTIER
## Low-Level Requirements Document -- Version 0.5.1

**Traces to: HLR v0.5.0 | GDD v8**
**Target: Godot 4.x | GDScript | JSON data**
**March 2026**

> T = Testable | U = Untestable (subjective/emergent)

---

## 1. Core Application

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LCORE-001 | CORE-001 | The project shall use Godot 4.x as its engine. | T |
| LCORE-002 | CORE-001 | The main scene shall be a single main.tscn that loads a WorldEnvironment, the player scene, and a map scene. | T |
| LCORE-003 | CORE-001 | The map scene shall be a separate PackedScene loaded at runtime based on a config JSON file. | T |
| LCORE-004 | CORE-002 | A debug overlay toggled via a key shall display current FPS, draw calls, and node count. | T |
| LCORE-005 | CORE-002 | The project shall set target_fps in Project Settings. | T |
| LCORE-006 | CORE-003 | An InputManager autoload shall load keybindings from user://input_config.json. | T |
| LCORE-007 | CORE-003 | Default keybindings for keyboard/mouse and gamepad shall ship in res://data/default_input.json. | T |
| LCORE-008 | CORE-004 | A SaveManager autoload shall serialize world state to user://saves/<slot>/save.json. | T |
| LCORE-009 | CORE-004 | SaveManager shall auto-save when it receives the sleep_complete signal. | T |
| LCORE-010 | CORE-004 | SaveManager shall support manual save via the pause menu. | T |
| LCORE-011 | CORE-004 | SaveManager shall support N save slots. | T |
| LCORE-012 | CORE-004 | Slot metadata (name, date, playtime, settlement count) shall be stored in user://saves/slots.json. | T |
| LCORE-013 | CORE-005 | A DataLoader autoload shall parse all JSON files from res://data/ at startup. | T |
| LCORE-014 | CORE-005 | DataLoader shall expose typed dictionaries (monsters, items, areas, tiers, disciplines, etc.) accessible by all systems. | T |

---

## 2. Data Layer

### 2.1 JSON Files -- Existence and Parse

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LDATA-001 | DATA-001 | res://data/monsters.json shall exist and be parseable by DataLoader. | T |
| LDATA-002 | DATA-001 | res://data/spawn_tables.json shall exist and be parseable by DataLoader. | T |
| LDATA-003 | DATA-001 | res://data/resources.json shall exist and be parseable by DataLoader. | T |
| LDATA-004 | DATA-001 | res://data/areas.json shall exist and be parseable by DataLoader. | T |
| LDATA-005 | DATA-001 | res://data/settlement_tiers.json shall exist and be parseable by DataLoader. | T |
| LDATA-006 | DATA-001 | res://data/trade_weights.json shall exist and be parseable by DataLoader. | T |
| LDATA-007 | DATA-001 | res://data/export_thresholds.json shall exist and be parseable by DataLoader. | T |
| LDATA-008 | DATA-001 | res://data/disciplines.json shall exist and be parseable by DataLoader. | T |
| LDATA-009 | DATA-001 | res://data/reagents.json shall exist and be parseable by DataLoader. | T |
| LDATA-010 | DATA-001 | res://data/runes.json shall exist and be parseable by DataLoader. | T |
| LDATA-011 | DATA-001 | res://data/items.json shall exist and be parseable by DataLoader. | T |
| LDATA-012 | DATA-001 | res://data/injuries.json shall exist and be parseable by DataLoader. | T |
| LDATA-013 | DATA-001 | res://data/weapons.json shall exist and be parseable by DataLoader. | T |
| LDATA-014 | DATA-001 | res://data/seasons.json shall exist and be parseable by DataLoader. | T |
| LDATA-015 | DATA-001 | res://data/survival.json shall exist and be parseable by DataLoader. | T |
| LDATA-016 | DATA-001 | res://data/recipes.json shall exist and be parseable by DataLoader. | T |
| LDATA-017 | DATA-001 | res://data/manufactured_goods.json shall exist and be parseable by DataLoader. | T |
| LDATA-018 | DATA-001 | res://data/hirelings.json shall exist and be parseable by DataLoader. | T |
| LDATA-019 | DATA-001 | res://data/roads.json shall exist and be parseable by DataLoader. | T |
| LDATA-020 | DATA-001 | res://data/landmarks.json shall exist and be parseable by DataLoader. | T |

### 2.2 Key Schema Requirements

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LDATA-030 | DATA-001 | Each monster entry shall include: id, name, model_path, hp, damage, speed, behavior_type, loot_table, fire_reaction, light_reaction. | T |
| LDATA-031 | DATA-001 | Each area entry shall include: id, region_id, hex_coords{q,r}, neighbors[], resource_tags[], spawn_table_id, difficulty, tags[], edge_features[], settlement_site{}, precursor_site_index. | T |
| LDATA-032 | DATA-001 | Each area edge_feature entry shall include: edge_index (0-5) and type ("river", "cliff", "ford", "rapids"). | T |
| LDATA-033 | DATA-001 | Each settlement_tiers entry shall include: tier, name, score_threshold, required_resources[], suppression_pct, safe_zone_radius, consumption_rate, exploitation{own_pct, adjacent_pct, ring2_pct}, services[], road_budget. | T |
| LDATA-034 | DATA-001 | Each rune entry shall include: id, name, effects{}, slot_types[], rarity, poisson_mean, poisson_min, poisson_max. | T |
| LDATA-035 | DATA-001 | Each item entry shall include: id, name, weight, type, durability, value, rune_slots, noise_level, spoil_timer, tags[]. | T |
| LDATA-036 | DATA-001 | Waterskin items shall have a weight_empty field separate from weight. | T |
| LDATA-037 | DATA-001 | Each injury entry shall include: id, name, debuffs{}, causes[], probability_by_source{}, treatment_tier. | T |
| LDATA-038 | DATA-001 | Each weapon entry shall include: id, name, type, damage, speed, stamina_cost, weight, durability, rune_slots, noise, weapon_category. | T |
| LDATA-039 | DATA-001 | Each discipline entry shall include: id, name, abilities[], xp_triggers[]. | T |
| LDATA-040 | DATA-001 | Each reagent entry shall include: id, name, spell_id, weight, tier, source, buy_price. | T |
| LDATA-041 | DATA-001 | disciplines.json shall contain exactly 9 disciplines and 61 total abilities. | T |
| LDATA-042 | DATA-001 | injuries.json shall contain exactly 7 injury types. | T |

---

## 3. World and Map

### 3.1 Hex Grid

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMAP-001 | MAP-002 | A HexGrid autoload shall convert axial hex coordinates (q,r) to world position. | T |
| LMAP-002 | MAP-002 | HexGrid shall convert world position to axial hex coordinates. | T |
| LMAP-003 | MAP-002 | HexGrid shall provide neighbor lookup for any hex (returns up to 6 neighbors). | T |
| LMAP-004 | MAP-002 | HexGrid shall calculate hex distance between two hexes. | T |
| LMAP-005 | MAP-002 | HexGrid shall provide ring queries (all hexes at distance N from a center). | T |
| LMAP-006 | MAP-002 | HexGrid shall identify shared edges between adjacent hexes by edge index (0-5). | T |

### 3.2 Area Management

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMAP-010 | MAP-003 | An AreaManager autoload shall load areas.json at startup. | T |
| LMAP-011 | MAP-003 | AreaManager shall maintain runtime state per area: discovered_resources[], settlement_id, suppression_pct, map_revealed. | T |
| LMAP-012 | MAP-003 | AreaManager.get_area(pos:Vector3) shall return the area_id for any world position via HexGrid lookup. | T |
| LMAP-013 | MAP-004 | River edges shall be stored as edge_features in areas.json, shared between adjacent hexes. | T |
| LMAP-014 | MAP-007 | Cliff edges shall be stored as edge_features in areas.json. | T |
| LMAP-015 | MAP-004 | AreaManager.is_edge_passable(area_a, area_b) shall return false if the shared edge has a cliff. | T |
| LMAP-016 | MAP-006 | AreaManager.is_edge_passable() shall return false if the shared edge has a river and neither area has a Ford tag and neither has a Town+ settlement. | T |
| LMAP-017 | MAP-006 | AreaManager.is_edge_passable() shall return true for a river edge if either area has a Ford tag. | T |
| LMAP-018 | MAP-006 | AreaManager.is_edge_passable() shall return true for a river edge if the area has a Town+ settlement (bridge). | T |

### 3.3 Time

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMAP-020 | MAP-012 | A TimeManager autoload shall track time_of_day as float 0.0-24.0. | T |
| LMAP-021 | MAP-012 | 30 real-time minutes shall equal 24.0 in-game hours. | T |
| LMAP-022 | MAP-012 | The time-to-real-time ratio shall be configurable in JSON. | T |
| LMAP-023 | MAP-012 | TimeManager shall drive DirectionalLight rotation based on time_of_day. | T |
| LMAP-024 | MAP-013 | TimeManager shall calculate daylight hours by interpolating between season daylight values. | T |
| LMAP-025 | MAP-013 | TimeManager shall emit dawn and dusk signals. | T |

### 3.4 Seasons and Weather

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMAP-030 | MAP-014 | A SeasonManager autoload shall track season_index (0-3) and day_count. | T |
| LMAP-031 | MAP-014 | SeasonManager shall advance season when day_count exceeds the current season's duration from seasons.json. | T |
| LMAP-032 | MAP-014 | SeasonManager shall emit a season_changed signal on season advance. | T |
| LMAP-033 | MAP-014 | Days per season shall be configurable in seasons.json. | T |
| LMAP-034 | MAP-015 | A WeatherManager shall roll against the current season's weather_table on each new day. | T |
| LMAP-035 | MAP-015 | Active weather shall modify fog density. | T |
| LMAP-036 | MAP-015 | Active weather shall toggle rain/snow particle effects. | T |
| LMAP-037 | MAP-015 | Active weather shall modify temperature. | T |
| LMAP-038 | MAP-015 | Rain weather shall increase effective cold level. | T |

### 3.5 Precursors and Landmarks

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMAP-040 | MAP-016 | A PrecursorRandomizer shall run on new game creation. | T |
| LMAP-041 | MAP-016 | PrecursorRandomizer shall use a seeded RandomNumberGenerator. The seed shall be stored in the save file. | T |
| LMAP-042 | MAP-016 | PrecursorRandomizer shall assign at least 18 sites as Places of Power (minimum 2 per discipline). | T |
| LMAP-043 | MAP-016 | Remaining precursor sites shall be assigned ruin types (shelter, lore, materials, navigation). | T |
| LMAP-044 | MAP-016 | Precursor assignments shall be stored in the save as Dict<site_index, assignment>. | T |
| LMAP-045 | MAP-017 | A LandmarkManager shall load landmark definitions from map data. | T |
| LMAP-046 | MAP-017 | On player first entry to a landmark trigger (Area3D), a naming prompt shall appear. | T |
| LMAP-047 | MAP-017 | Player-assigned landmark names shall persist in the save file. | T |
| LMAP-048 | MAP-017 | Named landmarks shall appear on maps in the MapViewer. | T |
| LMAP-049 | MAP-017 | From any point above a configurable elevation threshold, at least 3 landmark meshes shall be visible. | U |

### 3.6 Map Scene

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMAP-050 | MAP-001 | The map shall be a single Godot scene containing terrain meshes, biome materials, water bodies, and vegetation. | T |
| LMAP-051 | MAP-016 | Precursor site markers shall be Node3D nodes in the map scene with area_id metadata. | T |
| LMAP-052 | MAP-012 | Resource indicator meshes shall be placed in the map scene at resource locations. | T |

---

## 4. Player Character

### 4.1 Scene Structure

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LPC-001 | PC-001 | The player scene root shall be a CharacterBody3D. | T |
| LPC-002 | PC-001 | The player scene shall include a CollisionShape3D, Camera3D, HUD (CanvasLayer), and interaction RayCast3D. | T |
| LPC-003 | PC-001 | The player scene shall include a scan RayCast3D for journal scanning. | T |

### 4.2 Movement

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LPC-010 | PC-001 | The player shall have movement states: WALK, SPRINT, CROUCH, SWIM, DISABLED. | T |
| LPC-011 | PC-002 | SPRINT shall drain stamina at a configurable rate per second. | T |
| LPC-012 | PC-003 | When total inventory weight exceeds max_carry, SPRINT shall be disabled. | T |
| LPC-013 | PC-003 | When over-encumbered, WALK speed shall be multiplied by a configurable penalty. | T |
| LPC-014 | PC-001 | Jump shall apply a vertical velocity impulse. | T |
| LPC-015 | PC-001 | CROUCH shall reduce CollisionShape height and reduce speed. | T |
| LPC-016 | PC-001 | SWIM shall be triggered by entering a water volume (Area3D). | T |

### 4.3 Weapon Slots

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LPC-020 | PC-004 | The player shall have exactly 2 weapon slots. | T |
| LPC-021 | PC-004 | A quick-swap input shall swap the active weapon slot. | T |
| LPC-022 | PC-005 | Pistols shall be equippable in the main hand or off-hand. | T |
| LPC-023 | PC-005 | Shields shall be equippable only in the off-hand. | T |
| LPC-024 | PC-005 | Two-handed weapons, bows, and muskets shall require an empty off-hand. | T |

### 4.4 Death

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LPC-030 | PC-006 | On player_died signal, a DroppedItemBag shall be spawned at the death position. | T |
| LPC-031 | PC-006 | The DroppedItemBag shall contain all items from the player's inventory at time of death. | T |
| LPC-032 | PC-008 | On spawning a new DroppedItemBag, any previously existing DroppedItemBag shall be destroyed. | T |
| LPC-033 | PC-006 | On death, the player shall respawn at the last settlement where they rested. | T |
| LPC-034 | PC-006 | On death, the player's inventory shall be cleared. | T |
| LPC-035 | PC-007 | On death, the CampInstance shall NOT be destroyed. | T |
| LPC-036 | PC-007 | On death, all active hirelings shall NOT be dismissed. | T |
| LPC-037 | PC-009 | On death while founding is in progress and not yet reported, founding state shall be cleared. | T |
| LPC-038 | PC-009 | On founding cancellation via death, the Surveyor hireling shall return to its origin settlement. | T |

### 4.5 Health

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LHP-001 | HP-001 | PlayerStats shall track health as a float. | T |
| LHP-002 | HP-001 | PlayerStats shall track max_health as a float. | T |
| LHP-003 | HP-001 | PlayerStats shall emit health_changed when health changes. | T |
| LHP-004 | HP-001 | Health shall regenerate at base_health_regen per second (from survival.json). | T |
| LHP-005 | HP-001 | Health regen rate shall be multiplied by rest_multiplier when at a settlement or camp. | T |
| LHP-006 | HP-001 | When health reaches 0, PlayerStats shall emit player_died. | T |

### 4.6 Stamina

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LHP-010 | HP-002 | PlayerStats shall track stamina as a float. | T |
| LHP-011 | HP-002 | PlayerStats shall track max_stamina as a float. | T |
| LHP-012 | HP-002 | PlayerStats shall emit stamina_changed when stamina changes. | T |
| LHP-013 | HP-002 | Stamina shall regenerate at base_stamina_regen per second when no stamina-consuming action is active. | T |
| LHP-014 | HP-002 | Stamina regen rate shall be multiplied by fatigue_modifier from PlayerSurvival. | T |
| LHP-015 | HP-002 | Stamina regen rate shall be multiplied by hunger_modifier from PlayerSurvival. | T |

### 4.7 Injury

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LINJ-001 | HP-003 | When the player takes damage while health is below injury_threshold, an injury probability roll shall occur. | T |
| LINJ-002 | HP-003 | The injury type shall be selected by weighting against injury probability_by_source for the damage source type. | T |
| LINJ-003 | INJ-001 | Deep Wound shall reduce max_health by a configured amount. | T |
| LINJ-004 | INJ-001 | Cracked Ribs shall multiply all stamina costs by a configured factor. | T |
| LINJ-005 | INJ-001 | Torn Muscle shall multiply attack cooldown by a configured factor. | T |
| LINJ-006 | INJ-001 | Bleeding Gash shall apply a health drain DOT at a configured rate. | T |
| LINJ-007 | INJ-001 | Venom shall apply a health drain DOT and a vision distortion post-process effect. | T |
| LINJ-008 | INJ-001 | Venom shall worsen over time if untreated (DOT rate increases). | T |
| LINJ-009 | INJ-001 | Sprained Ankle shall multiply walk and sprint speed by a configured penalty. | T |
| LINJ-010 | INJ-001 | Gut Sickness shall reduce stamina regen, add periodic vision wobble, reduce hunger restoration from food, and narrow temperature thresholds. | T |
| LINJ-011 | INJ-002 | On sleep, each active injury shall be checked against current rest_tier. If rest_tier >= injury.treatment_tier, the injury shall be removed. | T |
| LINJ-012 | INJ-002 | Healer hireling shall add +1 to rest_tier for injury treatment calculations. | T |

### 4.8 Survival

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSURV-001 | SURV-001 | PlayerSurvival shall track hunger as a float that decreases over time. | T |
| LSURV-002 | SURV-001 | PlayerSurvival shall track thirst as a float that decreases over time. | T |
| LSURV-003 | SURV-001 | PlayerSurvival shall track temperature as a float. | T |
| LSURV-004 | SURV-001 | PlayerSurvival shall track fatigue as a float that increases over time. | T |
| LSURV-005 | SURV-001 | When hunger is below warn_threshold, stamina_regen_mult shall be set to 0.5. | T |
| LSURV-006 | SURV-001 | When hunger is below crit_threshold, a health DOT shall be applied. | T |
| LSURV-007 | SURV-001 | When fatigue exceeds crit_threshold, the player shall be forced to sleep (pass out). | T |
| LSURV-008 | SURV-002 | Temperature shall be calculated as: ambient_temp + altitude_mod + time_mod + weather_mod + rain_cold_bonus + clothing_insulation + discipline_mods. | T |
| LSURV-009 | SURV-002 | Rain weather shall add a configurable cold bonus to temperature calculation. | T |
| LSURV-010 | SURV-003 | Cold weather clothing items shall have weight values defined in items.json. | T |
| LSURV-011 | SURV-003 | Cold weather tents shall have a higher weight value than normal tents in items.json. | T |
| LSURV-012 | SURV-004 | Interacting with a stream shall give the player an unboiled water item. | T |
| LSURV-013 | SURV-004 | Using unboiled water at a campfire shall produce a boiled water item. | T |
| LSURV-014 | SURV-004 | Drinking unboiled water shall trigger a Gut Sickness probability roll. | T |
| LSURV-015 | SURV-004 | Drinking boiled water shall not trigger a Gut Sickness roll. | T |
| LSURV-016 | SURV-004 | Waterskin items shall have weight = 0 when empty. | T |
| LSURV-017 | SURV-004 | Waterskin items shall have weight = water_weight when full. | T |
| LSURV-018 | SURV-004 | Settlement wells shall provide clean (boiled-equivalent) water. | T |
| LSURV-019 | SURV-001 | When total inventory weight exceeds max_carry, the player is over-encumbered. | T |
| LSURV-020 | SURV-001 | Encumbrance calculation shall apply Alchemist Light Load modifier to items tagged "plant" or "potion". | T |
| LSURV-021 | SURV-001 | Encumbrance calculation shall apply Pathfinder Light Provisions modifier to items tagged "food" or "water". | T |

---

## 5. Combat

### 5.1 Melee

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMEL-001 | MEL-001 | Melee attack shall activate a hitbox Area3D during attack animation frames. | T |
| LMEL-002 | MEL-001 | On hitbox body_entered(monster), damage shall be calculated as weapon.damage * player_damage_mult * discipline_mods. | T |
| LMEL-003 | MEL-001 | Melee attacks shall consume stamina equal to weapon.stamina_cost. | T |
| LMEL-004 | MEL-002 | While blocking, incoming damage shall be multiplied by block_reduction. | T |
| LMEL-005 | MEL-003 | Shield block_reduction shall be greater than weapon block_reduction. | T |
| LMEL-006 | MEL-002 | Each blocked hit shall drain stamina. | T |
| LMEL-007 | MEL-002 | Dodge shall trigger an animation with an invulnerability window of N frames. | T |
| LMEL-008 | MEL-002 | Dodge shall consume stamina. | T |
| LMEL-009 | MEL-004 | Equipping a shield shall prevent equipping a two-handed weapon, bow, or musket. | T |
| LMEL-010 | MEL-003 | Shields shall have exactly 1 rune slot. | T |

### 5.2 Bows

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LBOW-001 | BOW-001 | Bows shall have states: IDLE, DRAWING, HELD, RELEASING. | T |
| LBOW-002 | BOW-001 | DRAWING shall increase draw_power over time. | T |
| LBOW-003 | BOW-001 | HELD shall drain stamina. | T |
| LBOW-004 | BOW-001 | RELEASING shall spawn an arrow RigidBody3D projectile with damage proportional to draw_power. | T |
| LBOW-005 | BOW-001 | Aim sway amplitude shall equal base_sway * fatigue_mod * (1.0 - steady_draw_mod). | T |
| LBOW-006 | BOW-001 | Bows shall have exactly 2 rune slots. | T |
| LBOW-007 | BOW-002 | Arrows shall be inventory items with weight. | T |
| LBOW-008 | BOW-002 | Firing a bow shall consume 1 arrow from inventory. | T |
| LBOW-009 | BOW-002 | Arrows that hit the world shall stick (become StaticBody3D). | T |
| LBOW-010 | BOW-003 | Bow firing shall not trigger the monster alert system. | T |
| LBOW-011 | BOW-002 | Without Survivalist Arrow Recovery, stuck arrows shall not be recoverable. | T |

### 5.3 Firearms

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LRNG-001 | RNG-001 | Firearms shall have states: READY, FIRING, RELOADING. | T |
| LRNG-002 | RNG-001 | FIRING shall use hitscan, consume 1 ammo, and play a loud sound. | T |
| LRNG-003 | RNG-001 | RELOADING duration shall equal base_reload * (1.0 - quick_load_mod). | T |
| LRNG-004 | RNG-001 | Muskets shall have exactly 2 rune slots. | T |
| LRNG-005 | RNG-001 | Pistols shall have exactly 1 rune slot. | T |
| LRNG-006 | RNG-002 | On firearm sound, all monsters within alert_radius shall enter ALERT state. | T |
| LRNG-007 | RNG-003 | Ammo crafting recipes shall require mineral powder as an ingredient. | T |
| LRNG-008 | RNG-003 | Mineral powder shall be purchasable at settlement shops. | T |
| LRNG-009 | RNG-003 | Mineral powder shall be craftable only via Artificer Mechanical Insight ability. | T |
| LRNG-010 | RNG-004 | Firearms shall have a condition float (0.0-1.0) that decreases per shot fired. | T |
| LRNG-011 | RNG-004 | When condition is below a threshold, each shot shall have a misfire_chance. | T |
| LRNG-012 | RNG-004 | Firearm condition shall be restorable at a settlement smithy or via Artificer Field Repair. | T |
| LRNG-013 | RNG-001 | Firearm aim sway amplitude shall equal base_sway * fatigue_mod * (1.0 - steady_hands_mod). | T |

### 5.4 Runes

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LRUNE-001 | RUNE-003 | On rune generation, effect_value shall be sampled from a Poisson distribution with mean = rune.poisson_mean. | T |
| LRUNE-002 | RUNE-003 | Effect_value shall be clamped to [poisson_min, poisson_max]. | T |
| LRUNE-003 | RUNE-003 | Higher rarity runes shall have higher poisson_mean values. | T |
| LRUNE-004 | RUNE-004 | Runes with the life_steal tag shall be rejected when socketed into bows, muskets, or pistols. | T |
| LRUNE-005 | RUNE-003 | Each rune instance's rolled effect_value shall be stored in the save file. | T |

### 5.5 Monster AI

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LMAI-001 | MON-004 | MonsterBase shall be a CharacterBody3D with NavigationAgent3D and a StateMachine. | T |
| LMAI-002 | MON-004 | MonsterBase StateMachine states shall include: IDLE, PATROL, ALERT, CHASE, ATTACK, FLEE, DESPAWN. | T |
| LMAI-003 | MON-004 | Territorial behavior: PATROL within home_radius. On player detection: CHASE. At melee range: ATTACK. Below flee_hp: FLEE. | T |
| LMAI-004 | MON-004 | Ambush behavior: IDLE (hidden). On player within trigger_radius: ATTACK burst. Then CHASE or FLEE. | T |
| LMAI-005 | MON-004 | Swarm behavior: shared group aggro. One detects, all CHASE. Below group threshold: remaining FLEE. | T |
| LMAI-006 | MON-004 | Heavy behavior: IDLE. On first provocation: ALERT. On second: CHARGE. | T |
| LMAI-007 | MON-004 | Apex behavior: multi-phase ATTACK with HP thresholds. | T |
| LMAI-008 | MON-004 | Apex monsters shall ignore Ward, Decoy, and Banishment Circle effects. | T |
| LMAI-009 | MON-005 | Monsters with fire_reaction="avoid" shall add campfire positions to navigation avoidance. | T |
| LMAI-010 | MON-005 | Monsters with fire_reaction="attracted" shall pathfind toward campfire positions. | T |
| LMAI-011 | MON-006 | Monsters with light_reaction="attracted" shall pathfind toward active light sources. | T |
| LMAI-012 | MON-006 | Monsters with light_reaction="repelled" shall add light source positions to navigation avoidance. | T |
| LMAI-013 | MON-001 | Monsters beyond despawn_distance from the player shall queue_free. | T |

---

## 6. Spawn System

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSPN-001 | MON-001 | A SpawnManager autoload shall trigger spawns when the player enters an area. | T |
| LSPN-002 | MON-001 | Spawn count shall be weighted by: weight * time_modifier * difficulty_scalar * (1.0 - suppression_pct). | T |
| LSPN-003 | MON-002 | No monsters shall spawn within safe_zone_radius of a settlement_site position. | T |
| LSPN-004 | MON-003 | Suppression percentage shall be read from the settlement's tier data. | T |
| LSPN-005 | MON-001 | Spawn positions shall use Marker3D nodes in the map scene or NavMesh sampling outside safe zone. | T |

---

## 7. Navigation and Exploration

### 7.1 Compass and Map

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LNAV-001 | NAV-002 | A CompassHUD element shall display the cardinal direction the player is facing. | T |
| LNAV-002 | NAV-002 | The compass shall be always visible on the HUD. | T |
| LNAV-003 | NAV-001 | The player's map shall start with zero revealed hexes. | T |
| LNAV-004 | NAV-001 | Hexes shall be revealable by: surveying tools, Cartographer hireling, purchased maps, or Pathfinder Cartography ability. | T |
| LNAV-005 | NAV-009 | The MapViewer shall never render the player's position. | T |

### 7.2 Surveying

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LNAV-010 | NAV-004 | Surveying tools shall reveal hexes in a radius when used above a minimum elevation. | T |
| LNAV-011 | NAV-004 | Naked eye reveal radius shall be 2 hexes. | T |
| LNAV-012 | NAV-004 | Spyglass reveal radius shall be 4 hexes. Purchasable at Trading Post+. | T |
| LNAV-013 | NAV-004 | Theodolite reveal radius shall be 6 hexes. Purchasable at Town+. | T |
| LNAV-014 | NAV-004 | Pathfinder Wayfinder shall multiply surveying radius by 1.5. | T |

### 7.3 Purchased Maps

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LNAV-020 | NAV-005 | Village shops shall sell maps that reveal all hexes within 2-hex radius of the settlement. | T |
| LNAV-021 | NAV-005 | Town shops shall sell maps that reveal 3-hex radius. | T |
| LNAV-022 | NAV-005 | City shops shall sell maps that reveal 4-hex radius. | T |
| LNAV-023 | NAV-005 | Purchased maps shall show biomes, rivers, cliffs, and landmarks within the revealed area. | T |

### 7.4 Revealed Hex Bonus

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LNAV-025 | NAV-006 | When a hex is revealed, all landmarks within 2 hexes beyond the revealed hex shall be added to a visible_landmarks list. | T |
| LNAV-026 | NAV-006 | Visible landmarks from the bonus shall appear on the map without revealing their hex's terrain data. | T |

### 7.5 Map Markers

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LNAV-030 | NAV-008 | The player shall be able to place markers on the MapViewer at hex positions. | T |
| LNAV-031 | NAV-008 | Marker types shall include: fox (hunting), campsite, portage, rapids, and custom. | T |
| LNAV-032 | NAV-008 | The player shall be able to remove placed markers. | T |
| LNAV-033 | NAV-008 | Player markers shall persist in the save file. | T |

### 7.6 Scanning and Journal

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LNAV-040 | NAV-011 | A scan input shall cast the scan RayCast3D. | T |
| LNAV-041 | NAV-011 | If the raycast hits a node in the "scannable" group, a journal entry shall be added for that object. | T |
| LNAV-042 | NAV-011 | Scannable categories shall include: creatures, landmarks, items, and resources. | T |
| LNAV-043 | NAV-011 | Scanning shall provide visual and audio feedback on success. | T |
| LNAV-044 | NAV-013 | Landmarks shall be nameable on first scan or first Area3D trigger entry. | T |

### 7.7 Resource Discovery

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LNAV-050 | NAV-012 | Each resource indicator in the map shall have an Area3D proximity trigger. | T |
| LNAV-051 | NAV-012 | On player entering a resource trigger, the resource_id shall be added to AreaManager.discovered_resources for that area. | T |
| LNAV-052 | NAV-012 | Duplicate discoveries shall be ignored. | T |
| LNAV-053 | NAV-012 | Surveyor hireling shall call AreaManager.discover_all(area_id) on sleep. | T |

---

## 8. Settlement Founding

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LFOUND-001 | FOUND-001 | A FoundingManager shall track founding state. | T |
| LFOUND-002 | FOUND-001 | Founding shall require an active Surveyor hireling. | T |
| LFOUND-003 | FOUND-001 | No flag items shall exist in the game. | T |
| LFOUND-004 | FOUND-002 | On camp placement in an unsettled area with a Surveyor, the game shall display a directional hint toward the settlement site. | U |
| LFOUND-005 | FOUND-002 | Camp setup shall play a 2-second cutscene at the settlement site. | T |
| LFOUND-006 | FOUND-003 | After directing the Surveyor, a timer of 1-2 in-game days (configurable) shall begin. | T |
| LFOUND-007 | FOUND-003 | While the timer is running, the Surveyor shall remain at the camp. | T |
| LFOUND-008 | FOUND-004 | After the Surveyor completes, the player must interact with the mayor NPC at the origin Village. | T |
| LFOUND-009 | FOUND-005 | On the next sleep after reporting, a SettlementInstance shall be created at the settlement_site with tier=1 and trade_score=0. | T |
| LFOUND-010 | FOUND-005 | On founding, the new settlement shall run its initial road evaluation. | T |
| LFOUND-011 | FOUND-006 | If the player dies before reporting, all founding state shall be cleared. | T |
| LFOUND-012 | FOUND-006 | On founding cancellation, the Surveyor shall return to the origin settlement. | T |

---

## 9. Camps and Hirelings

### 9.1 Camps

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LCAMP-001 | CAMP-001 | On camp request, the game shall display a directional hint toward a valid camp spot. | U |
| LCAMP-002 | CAMP-001 | The player shall walk to the camp spot (no teleportation). | T |
| LCAMP-003 | CAMP-001 | On arrival at the camp spot, a 2-second setup cutscene shall play. | T |
| LCAMP-004 | CAMP-001 | After the cutscene, a CampInstance node shall be spawned. | T |
| LCAMP-005 | CAMP-002 | CampfireNode shall have an Area3D with a monster_deterrent_radius. | T |
| LCAMP-006 | CAMP-003 | Campfire position shall be added to navigation avoidance for monsters with fire_reaction="avoid". | T |
| LCAMP-007 | CAMP-003 | Monsters with fire_reaction="attracted" shall pathfind toward campfire position. | T |
| LCAMP-008 | CAMP-002 | CampfireNode shall provide a warmth modifier within its radius. | T |
| LCAMP-009 | CAMP-002 | CampfireNode shall enable cooking interaction. | T |
| LCAMP-010 | CAMP-002 | CampfireNode shall be a light source (OmniLight3D). | T |
| LCAMP-011 | CAMP-005 | An "Abandon Camp" menu option shall dismiss all hirelings and destroy the CampInstance. | T |
| LCAMP-012 | CAMP-005 | On abandon, all camp items shall be destroyed. | T |

### 9.2 Hirelings

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LHIRE-001 | HIRE-001 | HirelingManager shall track active_hirelings as an Array. | T |
| LHIRE-002 | HIRE-001 | Each hireling shall have: type, cost_per_day, origin_settlement. | T |
| LHIRE-003 | HIRE-001 | Hirelings shall spawn tent visuals at the camp. | T |
| LHIRE-004 | HIRE-002 | Hirelings shall be excluded from monster collision/targeting layers. | T |
| LHIRE-005 | HIRE-002 | Hirelings shall play a cower animation when a monster enters ATTACK state near camp. | T |
| LHIRE-006 | HIRE-002 | Hirelings shall not be killable. | T |
| LHIRE-007 | HIRE-003 | Porter shall spawn a PorterBackpack container at camp with capacity from hirelings.json. | T |
| LHIRE-008 | HIRE-003 | PorterBackpack contents shall persist when camp moves. | T |
| LHIRE-009 | HIRE-003 | When at a player home, Porter shall enable a transfer UI between backpack and home storage. | T |
| LHIRE-010 | HIRE-004 | Hunter shall generate food items on sleep. Quantity from hirelings.json. | T |
| LHIRE-011 | HIRE-005 | Guide shall display directional indicators toward POIs within guide_radius. | T |
| LHIRE-012 | HIRE-006 | Surveyor shall call discover_all(current_area_id) on sleep. | T |
| LHIRE-013 | HIRE-006 | Surveyor shall be required for founding (gate check in FoundingManager). | T |
| LHIRE-014 | HIRE-007 | Cartographer shall track area_ids entered while active. | T |
| LHIRE-015 | HIRE-007 | On rest, Cartographer shall generate a MapItem covering tracked areas. | T |
| LHIRE-016 | HIRE-008 | Healer shall set camp rest_tier to 3 (Town equivalent) for injury treatment. | T |
| LHIRE-017 | HIRE-009 | On sleep, cost_per_day shall be deducted per active hireling. | T |
| LHIRE-018 | HIRE-009 | If funds are insufficient for a hireling's cost, that hireling shall depart. | T |

---

## 10. Economy and Settlements

### 10.1 Runtime

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LECO-001 | TIER-001 | A SettlementManager autoload shall maintain a Dict of SettlementState per settlement. | T |
| LECO-002 | TIER-001 | SettlementState shall include: area_id, tier, trade_score, is_port, connections[], road_budget_spent, visual_instance. | T |
| LECO-003 | TIER-006 | On tier change, the settlement visual scene shall be swapped to match the new tier. | T |
| LECO-004 | TIER-001 | NPC scenes shall be instantiated per tier services list. | T |
| LECO-005 | TIER-003 | When a settlement on a River Area reaches tier 3 (Town), adjacent river edges shall be marked passable (bridge). | T |
| LECO-006 | TIER-002 | Trading Post shall exploit resources from own Area only (100%). | T |
| LECO-007 | TIER-002 | Village shall exploit own Area (100%) + adjacent Areas (50%). | T |
| LECO-008 | TIER-002 | Town shall exploit own Area (100%) + adjacent Areas (100%). | T |
| LECO-009 | TIER-002 | City shall exploit own (100%) + adjacent (100%) + ring-2 (25%). | T |
| LECO-010 | TIER-005 | Crestport shall start as a Village (tier 2) in a Deep Water Port Area. | T |

### 10.2 Trade Routing

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LTRADE-001 | PORT-002 | A TradeGraph shall maintain an adjacency list of settlements connected by roads. | T |
| LTRADE-002 | PORT-002 | On sleep, Dijkstra shall be run from each non-port settlement to find the nearest port. | T |
| LTRADE-003 | PORT-002 | The route_path for each settlement shall be stored. | T |
| LTRADE-004 | PORT-003 | On new settlement founded or new road formed, trade_graph_dirty shall be set true. | T |
| LTRADE-005 | PORT-003 | On sleep, if dirty, all routes shall be recalculated. | T |

### 10.3 Consumption and Trade Score

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSCORE-001 | GROW-001 | Local output for a settlement shall be the sum of (resource.richness * exploitation_pct) for own + adjacent + ring-2 per tier. | T |
| LSCORE-002 | GROW-003 | For each source settlement, trace route to port. At each node, remaining_value shall be multiplied by (1.0 - node.consumption_rate). | T |
| LSCORE-003 | GROW-003 | Each node's consumed portion (the amount removed by consumption) shall contribute to that node's trade_score. | T |
| LSCORE-004 | GROW-004 | Consumption shall apply only to raw materials flowing coastward. | T |
| LSCORE-005 | GROW-004 | Manufactured goods availability shall NOT be reduced by consumption. | T |
| LSCORE-006 | GROW-001 | trade_score shall accumulate per sleep: += (local_output * local_weight) + (consumed_passthrough * passthrough_weight) + (diversity_curve[count]) + (connections * connection_bonus). | T |
| LSCORE-007 | GROW-002 | Tier advancement shall require: trade_score >= next_tier.score_threshold. | T |
| LSCORE-008 | GROW-002 | Tier advancement shall require: all required_resources present in flow-through set. | T |
| LSCORE-009 | GROW-002 | On tier advancement, emit tier_changed signal. | T |
| LSCORE-010 | GROW-002 | On tier_changed, trigger road re-evaluation for that settlement. | T |

### 10.4 Export

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LEXPORT-001 | PORT-004 | Global export value shall be the sum of remaining_value at ports across all trade routes. | T |
| LEXPORT-002 | PORT-004 | The highest exceeded threshold in export_thresholds.json shall determine available_goods_tier. | T |
| LEXPORT-003 | PORT-005 | Shop inventories shall filter goods by: (a) export_tier <= global tier, (b) min_settlement_tier <= this settlement tier. | T |

### 10.5 Roads

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LROAD-001 | ROAD-001 | Every settlement shall have a road_budget of 9. | T |
| LROAD-002 | ROAD-002 | Road cost shall equal the hex distance between the two settlements. | T |
| LROAD-003 | ROAD-003 | Road evaluation shall occur on settlement founding. | T |
| LROAD-004 | ROAD-003 | Road evaluation shall occur on settlement tier change. | T |
| LROAD-005 | ROAD-003 | Road evaluation shall NOT occur on every sleep. | T |
| LROAD-006 | ROAD-003 | During evaluation, settlements shall be sorted by trade_score descending. | T |
| LROAD-007 | ROAD-003 | The settlement shall connect to the highest-scoring reachable target it can afford, then the next, until budget is exhausted. | T |
| LROAD-008 | ROAD-004 | Only the initiating settlement shall spend road budget. The target shall receive the connection at no cost. | T |
| LROAD-009 | ROAD-005 | Old roads shall never be deleted on re-evaluation. | T |
| LROAD-010 | ROAD-005 | Available budget on re-evaluation shall be 9 minus the total cost of existing outgoing roads. | T |
| LROAD-011 | ROAD-007 | Road pathfinding shall use A* on the hex grid. | T |
| LROAD-012 | ROAD-007 | Road paths shall not cross cliff edges. | T |
| LROAD-013 | ROAD-007 | Road paths shall not cross river edges unless a Ford exists or the settlement on the river Area is Town+. | T |
| LROAD-014 | ROAD-007 | Road paths shall not pass through Mountain-tagged areas unless they have Mountain Pass. | T |
| LROAD-015 | ROAD-008 | Maximum road length shall be 9 hexes. | T |
| LROAD-016 | ROAD-006 | Road quality shall equal the minimum tier of the two connected settlements. | T |
| LROAD-017 | ROAD-006 | Road quality shall auto-upgrade when either endpoint tiers up. | T |
| LROAD-018 | ROAD-006 | RoadVisual mesh/material shall be selected from roads.json based on quality. | T |
| LROAD-019 | ROAD-006 | A speed zone Area3D along road paths shall apply a speed multiplier to the player. | T |

### 10.6 Shops and Homes

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSHOP-001 | PORT-005 | PlayerStats shall track gold as an integer. | T |
| LSHOP-002 | PORT-005 | Selling items at shop NPCs shall increase gold. | T |
| LSHOP-003 | PORT-005 | Purchasing items shall decrease gold. | T |
| LHOME-001 | HOME-001 | Homes shall be purchasable at Village+ settlements. | T |
| LHOME-002 | HOME-001 | Home storage shall be a single global store shared across all owned homes. | T |
| LHOME-003 | HOME-001 | Home storage capacity shall be unlimited. | T |
| LHOME-004 | HOME-002 | When a Porter hireling is at a player's home, a transfer UI between Porter backpack and home storage shall be available. | T |
| LHOME-005 | HOME-001 | Homes shall include an alchemy workshop interaction. | T |
| LHOME-006 | HOME-001 | Homes shall provide a free bed (no cost to sleep). | T |

---

## 11. Sleep and Batch

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSLEEP-001 | SLEEP-001 | Sleep shall be triggerable at a settlement bed or camp tent. | T |
| LSLEEP-002 | SLEEP-001 | Sleep shall advance the clock to the next morning. | T |
| LSLEEP-003 | SLEEP-002 | Batch step 0: process founding completion (if founding_pending, create settlement). | T |
| LSLEEP-004 | SLEEP-002 | Batch step 1: process resource extraction (accumulate richness values per settlement per exploitation tier). | T |
| LSLEEP-005 | SLEEP-002 | Batch step 2: if trade_graph_dirty, recalculate all trade routes via Dijkstra. | T |
| LSLEEP-006 | SLEEP-002 | Batch step 3: calculate consumption along routes and update per-settlement trade scores. | T |
| LSLEEP-007 | SLEEP-002 | Batch step 4: check tier advancement for all settlements. | T |
| LSLEEP-008 | SLEEP-002 | Batch step 5: update settlement visuals for any tier changes. | T |
| LSLEEP-009 | SLEEP-002 | Batch step 6: run road evaluation for any settlements that tiered up. | T |
| LSLEEP-010 | SLEEP-002 | Batch step 7: recalculate Area suppression percentages. | T |
| LSLEEP-011 | SLEEP-002 | Batch step 8: generate Hunter food if Hunter hireling active. | T |
| LSLEEP-012 | SLEEP-002 | Batch step 9: process Trapper harvests if Trapper traps placed. | T |
| LSLEEP-013 | SLEEP-002 | Batch step 10: deduct hireling daily costs. Dismiss if insufficient funds. | T |
| LSLEEP-014 | SLEEP-002 | Batch step 11: process injury healing based on rest_tier. | T |
| LSLEEP-015 | SLEEP-002 | Batch step 12: reset fatigue to 0. | T |
| LSLEEP-016 | SLEEP-002 | Batch step 13: deduct hunger and thirst for elapsed time. | T |
| LSLEEP-017 | SLEEP-002 | Batch step 14: advance day counter. Check season advancement. | T |
| LSLEEP-018 | SLEEP-002 | Batch step 15: roll new weather. | T |
| LSLEEP-019 | SLEEP-002 | Batch step 16: process Surveyor discovery if active. | T |
| LSLEEP-020 | SLEEP-002 | Batch step 17: process Cartographer map generation if active. | T |
| LSLEEP-021 | SLEEP-002 | Batch step 18: auto-save. | T |
| LSLEEP-022 | SLEEP-003 | An optional SleepSummaryUI shall display events from the batch (tier changes, roads, hirelings departed, injuries healed). | T |

---

## 12. Disciplines

### 12.1 System

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LDSYS-001 | DSYS-002 | DisciplineManager shall track attunements as an Array with max size 3. | T |
| LDSYS-002 | DSYS-002 | Attunements shall be permanent and non-respecable. | T |
| LDSYS-003 | DSYS-004 | Interacting with a Place of Power when attunements < 3 shall show an attunement UI. | T |
| LDSYS-004 | DSYS-004 | On attunement confirm, the discipline shall be added and ability 1 unlocked. | T |
| LDSYS-005 | DSYS-004 | Interacting with a Place of Power when attunements == 3 shall add a journal entry only. | T |
| LDSYS-006 | DSYS-005 | DisciplineManager shall subscribe to SignalBus events matching xp_triggers from disciplines.json. | T |
| LDSYS-007 | DSYS-005 | On matching signal, the corresponding discipline's XP shall increase. | T |
| LDSYS-008 | DSYS-006 | A City Enhancement NPC shall display: available disciplines, current XP, next ability cost. | T |
| LDSYS-009 | DSYS-006 | On enhancement purchase, XP and gold shall be deducted and unlocked_abilities incremented. | T |
| LDSYS-010 | DSYS-007 | Visiting a second Place of Power of the same discipline shall grant bonus XP. | T |

### 12.2 Survivalist Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSURV-A01 | DSYS-008 | Trapper: placing a TrapNode in the world shall be possible via the ability. | T |
| LSURV-A02 | DSYS-008 | Trapper: on sleep, each placed trap shall roll food_chance and add food to inventory on success. | T |
| LSURV-A03 | DSYS-008 | Arrow Recovery: on combat_ended signal, floor(arrows_fired * recovery_pct) arrows shall be added to inventory. | T |
| LSURV-A04 | DSYS-008 | Night Eyes: toggling shall enable a greyscale post-process shader. | T |
| LSURV-A05 | DSYS-008 | Night Eyes: while active, stamina shall drain at night_eyes_drain_rate/sec. | T |
| LSURV-A06 | DSYS-008 | Light Foot: player stealth_modifier shall be set, reducing monster detection_range. | T |
| LSURV-A07 | DSYS-008 | Light Foot: bow attacks on unaware monsters shall deal damage * stealth_mult. | T |
| LSURV-A08 | DSYS-008 | Steady Draw: bow draw_speed shall be multiplied by steady_draw_speed_mult. | T |
| LSURV-A09 | DSYS-008 | Steady Draw: bow aim sway shall be reduced by steady_draw_sway_reduction. | T |
| LSURV-A10 | DSYS-008 | Steady Draw: held draw stamina drain shall be multiplied by steady_draw_drain_mult. | T |
| LSURV-A11 | DSYS-008 | Weatherskin: cold_threshold and heat_threshold shall be widened by weatherskin_range. | T |
| LSURV-A12 | DSYS-008 | Endurance: max_stamina shall be multiplied by 1.25. | T |
| LSURV-A13 | DSYS-008 | Endurance: fatigue stamina penalty shall be multiplied by 0.5. | T |
| LSURV-A14 | DSYS-008 | Ghost Walk: on activation, player shall be invisible to monsters for 10 seconds. | T |
| LSURV-A15 | DSYS-008 | Ghost Walk: shall have a long cooldown timer. | T |
| LSURV-A16 | DSYS-008 | Ghost Walk: shall break on attack or interaction. | T |

### 12.3 Ritualist Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LRIT-A01 | DSYS-008 | Ward: 5-second channel shall be interruptible by damage. | T |
| LRIT-A02 | DSYS-008 | Ward: on completion, spawn a WardZone Area3D at target with 10-foot radius. | T |
| LRIT-A03 | DSYS-008 | Ward: monsters shall not enter the WardZone (added to navigation avoidance). | T |
| LRIT-A04 | DSYS-008 | Ward: WardZone shall last 60 seconds. | T |
| LRIT-A05 | DSYS-008 | Ward: cooldown shall be 15 seconds. | T |
| LRIT-A06 | DSYS-008 | Preserve: all food spoil timers shall be multiplied by preserve_decay_mult (>1.0, slowing decay). | T |
| LRIT-A07 | DSYS-008 | Preserve: weapon and armor durability loss per use shall be multiplied by preserve_durability_mult (<1.0). | T |
| LRIT-A08 | DSYS-008 | Decoy: 5-second channel. On completion, spawn a DecoyCircle at target. | T |
| LRIT-A09 | DSYS-008 | Decoy: after 10-second delay, spawn a visible decoy mesh and AudioStreamPlayer3D that generates noise. | T |
| LRIT-A10 | DSYS-008 | Decoy: non-Apex monsters within detection range shall pathfind toward the decoy. | T |
| LRIT-A11 | DSYS-008 | Decoy: shall persist for 30 seconds before fading. | T |
| LRIT-A12 | DSYS-008 | Enchant: 5-second channel. On completion, apply enchant_damage_bonus to equipped weapon for 60 seconds. | T |
| LRIT-A13 | DSYS-008 | Enchant: shall add a visible glow (OmniLight3D) to the weapon. | T |
| LRIT-A14 | DSYS-008 | Enchant: bonus shall stack with existing rune effects. | T |
| LRIT-A15 | DSYS-008 | Sending Chest: 5-second channel. On completion, spawn an interactable ChestNode. | T |
| LRIT-A16 | DSYS-008 | Sending Chest: on chest close, all contents shall transfer to HomeStorage. | T |
| LRIT-A17 | DSYS-008 | Sending Chest: the chest shall queue_free after transfer. | T |
| LRIT-A18 | DSYS-008 | Sending Chest: shall be usable once per rest. | T |
| LRIT-A19 | DSYS-008 | Banishment Circle: 5-second channel. On completion, spawn a BanishZone Area3D trap. | T |
| LRIT-A20 | DSYS-008 | Banishment Circle: first non-Apex monster to enter BanishZone shall be despawned. | T |
| LRIT-A21 | DSYS-008 | Banishment Circle: BanishZone shall queue_free after triggering. | T |
| LRIT-A22 | DSYS-008 | Banishment Circle: BanishZone shall persist until triggered or next rest. | T |
| LRIT-A23 | DSYS-008 | Anchor part 1: 5-second channel. Store anchor_position in save. | T |
| LRIT-A24 | DSYS-008 | Anchor part 2: 5-second channel from any location. Teleport player to anchor_position. | T |
| LRIT-A25 | DSYS-008 | Anchor: on teleport, anchor_position shall be cleared (one use). | T |

### 12.4 Pathfinder Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LPATH-A01 | DSYS-009 | Wayfinder: surveying_range_mult shall be set to 1.5. | T |
| LPATH-A02 | DSYS-009 | Light Provisions: items tagged "food" or "water" shall have weight multiplied by 0.5. | T |
| LPATH-A03 | DSYS-009 | Cartography: at camp, the player shall be able to generate a MapItem from areas entered since last rest. | T |
| LPATH-A04 | DSYS-009 | Prospect: on activation, display a directional indicator toward the nearest undiscovered resource in the current Area. | T |
| LPATH-A05 | DSYS-009 | Steady Pace: stamina_regen_mult shall be multiplied by 1.3. | T |
| LPATH-A06 | DSYS-009 | Pathsense: precursor sites within pathsense_radius shall render a shimmer VFX when viewed from above elevation threshold. | U |

### 12.5 Warrior Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LWAR-A01 | DSYS-008 | Heavy Hand: melee_damage_mult shall be multiplied by 1.2. | T |
| LWAR-A02 | DSYS-008 | Pack Mule: max_carry shall be multiplied by 1.3. | T |
| LWAR-A03 | DSYS-008 | Pack Mule: over-encumbrance speed penalty shall be reduced. | T |
| LWAR-A04 | DSYS-008 | Ironclad: can_equip_heavy flag shall be set true. | T |
| LWAR-A05 | DSYS-008 | Ironclad: all armor damage_reduction shall be increased by ironclad_bonus. | T |
| LWAR-A06 | DSYS-008 | Stagger: charged attack shall set non-Apex targets to STAGGERED state. | T |
| LWAR-A07 | DSYS-008 | Stagger: shall consume high stamina. | T |
| LWAR-A08 | DSYS-008 | Second Wind: shall only activate when health < 25%. | T |
| LWAR-A09 | DSYS-008 | Second Wind: shall restore 30% stamina and grant 8s damage resistance. | T |
| LWAR-A10 | DSYS-008 | Second Wind: shall be usable once per rest. | T |
| LWAR-A11 | DSYS-008 | Warcry: all non-Apex monsters within 15m shall enter FLINCH state. | T |
| LWAR-A12 | DSYS-008 | Warcry: shall have a moderate cooldown. | T |

### 12.6 Swordsman Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSWD-A01 | DSYS-008 | Riposte: dodging during a monster's attack window shall enable a riposte window. | T |
| LSWD-A02 | DSYS-008 | Riposte: next attack during the window shall deal 2x damage. | T |
| LSWD-A03 | DSYS-008 | Cripple: riposte hits shall apply a cripple debuff (speed reduction or attack disable) lasting 15 seconds. | T |
| LSWD-A04 | DSYS-008 | Read: monster attack telegraph animations shall play slower (configured multiplier). | T |
| LSWD-A05 | DSYS-008 | Read: dodge invulnerability window shall be extended by configured frames. | T |
| LSWD-A06 | DSYS-008 | Off-Hand Mastery (shield): block_reduction shall receive a bonus. | T |
| LSWD-A07 | DSYS-008 | Off-Hand Mastery (shield): block recovery time shall be reduced. | T |
| LSWD-A08 | DSYS-008 | Off-Hand Mastery (pistol): weapon swap time shall be reduced. | T |
| LSWD-A09 | DSYS-008 | Off-Hand Mastery (pistol): aim bonus shall be applied after a melee combo. | T |
| LSWD-A10 | DSYS-008 | Bleed: critical hits shall apply a BleedDOT dealing damage over 10 seconds. | T |
| LSWD-A11 | DSYS-008 | Bleed: shall stack up to 3 times. | T |
| LSWD-A12 | DSYS-008 | Bleed: Swordsman bleeds shall have increased duration and damage vs baseline. | T |
| LSWD-A13 | DSYS-008 | Blade Sense: Bleeding Gash injury probability shall be multiplied by (1.0 - blade_sense_reduction). | T |
| LSWD-A14 | DSYS-008 | Blade Sense: Deep Wound injury probability shall be multiplied by (1.0 - blade_sense_reduction). | T |
| LSWD-A15 | DSYS-008 | Flurry: shall only activate during a riposte window. | T |
| LSWD-A16 | DSYS-008 | Flurry: shall trigger a 3-strike chain animation. | T |
| LSWD-A17 | DSYS-008 | Flurry: shall consume heavy stamina. | T |
| LSWD-A18 | DSYS-008 | Deathmark: cripple_count per monster shall be tracked per encounter. | T |
| LSWD-A19 | DSYS-008 | Deathmark: at 3+ cripples, monster.damage_taken_mult shall be set to 1.3. | T |

### 12.7 Artificer Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LART-A01 | DSYS-008 | Field Repair: at camp, the player shall select a damaged item and consume materials to restore durability. | T |
| LART-A02 | DSYS-008 | Quick Load: reload_time_mult shall be multiplied by 0.7. | T |
| LART-A03 | DSYS-008 | Ammo Smith: at camp, craft ammo from iron + mineral powder per recipe. | T |
| LART-A04 | DSYS-008 | Spike Trap: craft from iron + wood. Place TrapNode in world. | T |
| LART-A05 | DSYS-008 | Spike Trap: on monster enter, deal spike_damage. | T |
| LART-A06 | DSYS-008 | Spike Trap: if not triggered, the trap shall be recoverable via interaction. | T |
| LART-A07 | DSYS-008 | Steady Hands: aim_sway_fatigue_mult shall be multiplied by 0.5. | T |
| LART-A08 | DSYS-008 | Reinforce: at camp, select weapon or armor. Apply temp buff (damage or armor bonus) lasting until next sleep. | T |
| LART-A09 | DSYS-008 | Reinforce: shall consume materials. | T |
| LART-A10 | DSYS-008 | Jury Rig: in the field (no camp required), select a broken item. Restore to temporary durability (~10 uses). | T |
| LART-A11 | DSYS-008 | Jury Rig: shall not require materials. | T |
| LART-A12 | DSYS-008 | Mechanical Insight: player.can_activate_precursor shall be set true. | T |
| LART-A13 | DSYS-008 | Mechanical Insight: precursor mechanism nodes shall check this flag before allowing interaction. | T |
| LART-A14 | DSYS-008 | Mechanical Insight: the player shall be able to disassemble precursor artifacts into rare materials. | T |
| LART-A15 | DSYS-008 | Mechanical Insight: the player shall be able to craft mineral powder. | T |

### 12.8 Alchemist Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LALC-A01 | DSYS-008 | Keen Eye: hidden GatherNodes shall have their visibility set to true. | T |
| LALC-A02 | DSYS-008 | Light Load: items tagged "plant" or "potion" shall have weight multiplied by 0.5. | T |
| LALC-A03 | DSYS-008 | Extended Potency: active potion buff durations shall be multiplied by 1.5. | T |
| LALC-A04 | DSYS-008 | Toxicologist: poison damage received shall be multiplied by 0.5. | T |
| LALC-A05 | DSYS-008 | Toxicologist: Venom injury treatment_tier shall be reduced by 1. | T |
| LALC-A06 | DSYS-008 | Master Brewer: recipes flagged requires_master_brewer in recipes.json shall become available. | T |
| LALC-A07 | DSYS-008 | Master Brewer: firefly jar shall be included in unlockable recipes. | T |
| LALC-A08 | DSYS-008 | Identify: interacting with an unknown material shall reveal its properties in the journal. | T |
| LALC-A09 | DSYS-008 | Identify: examining a material shall unlock associated experimental recipes. | T |
| LALC-A10 | DSYS-008 | Alchemist shall be able to purify unboiled water (removes Gut Sickness risk without campfire boiling). | T |

### 12.9 Scholar Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSCH-A01 | DSYS-010 | Runic Literacy: precursor inscription nodes shall display translated text for Scholar players. | T |
| LSCH-A02 | DSYS-010 | Runic Literacy: non-Scholar players shall see gibberish texture/mesh for the same nodes. | T |
| LSCH-A03 | DSYS-010 | Salvage: loot quantities from precursor sites shall be multiplied by salvage_mult. | T |
| LSCH-A04 | DSYS-010 | Shelter: sleeping at a precursor ruin site shall set rest_tier to 2 (Village equivalent). | T |
| LSCH-A05 | DSYS-010 | Shelter: sleeping at a ruin shall provide weather protection. | T |
| LSCH-A06 | DSYS-010 | Glyph Ward: at precursor sites with glyph nodes, the player shall be able to activate them. | T |
| LSCH-A07 | DSYS-010 | Glyph Ward: activated glyphs shall create a safe zone Area3D with larger radius than Ritualist Ward. | T |
| LSCH-A08 | DSYS-010 | Glyph Ward: safe zone shall last longer than Ritualist Ward. | T |
| LSCH-A09 | DSYS-010 | Glyph Ward: shall only function at precursor sites (not placeable anywhere). | T |
| LSCH-A10 | DSYS-010 | Deep Reading: interacting with a precursor artifact shall reveal related precursor site hex locations on the player's map. | T |
| LSCH-A11 | DSYS-010 | Reactivate: at larger ruins with sustenance_system nodes, the player shall be able to activate the system. | T |
| LSCH-A12 | DSYS-010 | Reactivate: using an active sustenance system shall fully restore hunger and thirst. | T |
| LSCH-A13 | DSYS-010 | Reactivate: each system shall have a configurable max_charges. | T |
| LSCH-A14 | DSYS-010 | Reactivate: each use shall decrement charges by 1. | T |
| LSCH-A15 | DSYS-010 | Reactivate: at 0 charges, the system shall be permanently depleted. | T |
| LSCH-A16 | DSYS-010 | Reactivate: system state (active, charges remaining) shall persist in save. | T |

### 12.10 Wizard Abilities

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LWIZ-A01 | DSYS-008 | Each Wizard spell: on use, check for required reagent in inventory. If absent, display fail message. | T |
| LWIZ-A02 | DSYS-008 | Each Wizard spell: on use, consume 1 of the required reagent from inventory. | T |
| LWIZ-A03 | DSYS-008 | Firebolt: 1-second cast. Spawn fire projectile. On hit: damage + BurnDOT. | T |
| LWIZ-A04 | DSYS-008 | Firebolt: shall consume 1 fire herb. | T |
| LWIZ-A05 | DSYS-008 | Frost Snap: 1-second cast. Raycast target. Apply ROOT state for 5 seconds. No damage. | T |
| LWIZ-A06 | DSYS-008 | Frost Snap: shall consume 1 crystal shard. | T |
| LWIZ-A07 | DSYS-008 | Force Push: instant cast. Cone area. Apply knockback and STAGGER to all monsters in cone. | T |
| LWIZ-A08 | DSYS-008 | Force Push: shall consume 1 mineral powder. | T |
| LWIZ-A09 | DSYS-008 | Lightning Arc: 1.5-second cast. Primary target + chain to up to 2 additional targets within chain_radius. | T |
| LWIZ-A10 | DSYS-008 | Lightning Arc: shall consume 1 charged filament. | T |
| LWIZ-A11 | DSYS-008 | Stone Shield: 1-second cast. Spawn destructible barrier (StaticBody3D with HP). | T |
| LWIZ-A12 | DSYS-008 | Stone Shield: barrier shall absorb incoming damage until HP depleted or 15 seconds elapsed. | T |
| LWIZ-A13 | DSYS-008 | Stone Shield: shall consume 2 mineral powder. | T |
| LWIZ-A14 | DSYS-008 | Ruin: 2-second cast. Raycast target. Apply massive single-target damage. | T |
| LWIZ-A15 | DSYS-008 | Ruin: shall consume 1 precursor core fragment. | T |

---

## 13. Alchemy and Cooking

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LCRAFT-001 | CRAFT-001 | GatherNode: world Node3D with Area3D trigger. On player interact: add item to inventory. | T |
| LCRAFT-002 | CRAFT-001 | Some GatherNodes shall have hidden=true, visible only when Alchemist Keen Eye is active. | T |
| LCRAFT-003 | CRAFT-002 | Cooking at campfire: RecipeUI filtered by station_type="campfire". | T |
| LCRAFT-004 | CRAFT-002 | Eating raw (uncooked) food shall trigger a Gut Sickness probability roll. | T |
| LCRAFT-005 | CRAFT-003 | Alchemy at camp set or home workshop: RecipeUI station_type="alchemy". | T |
| LCRAFT-006 | CRAFT-003 | Master Brewer recipes shall only appear if the ability is unlocked. | T |
| LCRAFT-007 | CRAFT-004 | Firefly jar: on equip/use, spawn OmniLight3D with white color and large radius. | T |
| LCRAFT-008 | CRAFT-004 | Firefly jar light shall be registered as a light source for monster light_reaction checks. | T |
| LCRAFT-009 | CRAFT-005 | Food items with a spoil_timer shall tick down over time. | T |
| LCRAFT-010 | CRAFT-005 | Expired food: eating shall trigger a Gut Sickness probability roll. | T |
| LCRAFT-011 | CRAFT-005 | Ritualist Preserve shall slow spoil_timer decay. | T |
| LCRAFT-012 | CRAFT-003 | Potion buffs: on consume, add BuffInstance {effect_id, duration, magnitude} to PlayerBuffs. | T |
| LCRAFT-013 | CRAFT-003 | Potion buff duration shall be multiplied by Extended Potency modifier if active. | T |

---

## 14. Inventory

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LINV-001 | INV-001 | Inventory shall store items as Array[{item_id, quantity, durability, rune_ids[], spoil_timer, state{}}]. | T |
| LINV-002 | INV-001 | Total weight shall be recalculated on any inventory change. | T |
| LINV-003 | INV-001 | Weight calculation shall apply per-item discipline modifiers (Light Load, Light Provisions, waterskin empty weight). | T |
| LINV-004 | INV-004 | Rune socketing UI: player shall select equipment, view slots, and socket a rune from inventory. | T |
| LINV-005 | INV-004 | On socketing, rune effects shall be applied to the equipment. | T |
| LINV-006 | INV-004 | Socketing a life_steal rune into a ranged weapon shall be rejected. | T |
| LINV-007 | INV-002 | PorterBackpack: separate container at camp with capacity from hirelings.json. | T |
| LINV-008 | INV-003 | HomeStorage: single global Dict<item_id, quantity> accessible at any owned home. | T |
| LINV-009 | INV-003 | HomeStorage: no capacity limit. | T |
| LINV-010 | INV-003 | Sending Chest deposits shall go to HomeStorage. | T |

---

## 15. UI

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LUI-001 | UI-001 | HUD shall include: CompassBar, HealthBar, StaminaBar, EquippedWeaponIcon, QuickSwapIndicator, StatusEffectIcons. | T |
| LUI-002 | UI-001 | Survival warnings shall use audio cues and screen vignette effects (not HUD bars). | T |
| LUI-003 | UI-002 | InventoryScreen shall pause the game (get_tree().paused). | T |
| LUI-004 | UI-002 | InventoryScreen shall show: item grid, equipment slots, encumbrance bar, rune socket button. | T |
| LUI-005 | UI-003 | MapViewer shall render revealed hexes with biome coloring. | T |
| LUI-006 | UI-003 | MapViewer shall display settlement icons at settlement positions. | T |
| LUI-007 | UI-003 | MapViewer shall display player-placed markers. | T |
| LUI-008 | UI-003 | MapViewer shall display named landmarks. | T |
| LUI-009 | UI-005 | JournalScreen shall have tabs: Creatures, Ingredients, Landmarks, Sites, Notes. | T |
| LUI-010 | UI-005 | Notes tab shall support text input (TextEdit). | T |
| LUI-011 | UI-006 | SettlementScreen shall show: tier, resources, trade score, connections, growth progress, consumption rate. | T |
| LUI-012 | UI-007 | DisciplineScreen shall show: 3 attunement slots, ability icons per discipline, XP progress bar, next unlock cost. | T |
| LUI-013 | UI-007 | Locked abilities shall appear grayed out. | T |
| LUI-014 | UI-009 | All UI screens shall be navigable via gamepad D-pad/stick with focus system. | T |
| LUI-015 | UI-009 | Settings menu shall include: resolution, window mode, graphics quality, keybindings editor, audio sliders (master/music/sfx/ambient), gameplay toggles. | T |

---

## 16. Audio

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LAUD-001 | AUD-001 | An AudioManager autoload shall manage AudioBus layout: Master, Music, SFX, Ambient. | T |
| LAUD-002 | AUD-001 | Biome ambient tracks shall crossfade based on current area biome type. | T |
| LAUD-003 | AUD-002 | Each monster type shall have distinct audio for: idle, alert, attack, death. | U |
| LAUD-004 | AUD-002 | Monster audio shall use AudioStreamPlayer3D for 3D positional sound. | T |
| LAUD-005 | AUD-003 | Bow firing audio shall use a short-range AudioStreamPlayer3D. | T |
| LAUD-006 | AUD-003 | Firearm firing audio shall use a large-range AudioStreamPlayer3D. | T |
| LAUD-007 | AUD-003 | Firearm audio shall trigger the monster alert system. Bow audio shall not. | T |
| LAUD-008 | AUD-004 | Survival threshold audio cues shall play as one-shot sounds on signal. | T |
| LAUD-009 | AUD-005 | Settlement ambient audio complexity shall increase with tier. | U |
| LAUD-010 | AUD-005 | Event-driven music shall play on: landmark_discovered, precursor_entered, settlement_grew, first_visit_biome. | U |

---

## 17. Save System

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LSAVE-001 | SAVE-001 | SaveManager.save() shall collect state from all managers into a single Dictionary. | T |
| LSAVE-002 | SAVE-002 | Save state shall include: player position and rotation. | T |
| LSAVE-003 | SAVE-002 | Save state shall include: player health, stamina, and active injuries. | T |
| LSAVE-004 | SAVE-002 | Save state shall include: player survival values (hunger, thirst, temperature, fatigue). | T |
| LSAVE-005 | SAVE-002 | Save state shall include: player inventory (items, quantities, durability, rune instances with rolled values, spoil timers, states). | T |
| LSAVE-006 | SAVE-002 | Save state shall include: player equipment and socketed runes. | T |
| LSAVE-007 | SAVE-002 | Save state shall include: player attunements, XP per discipline, and unlocked abilities. | T |
| LSAVE-008 | SAVE-002 | Save state shall include: player journal entries. | T |
| LSAVE-009 | SAVE-002 | Save state shall include: player currency (gold). | T |
| LSAVE-010 | SAVE-002 | Save state shall include: all settlement states (area_id, tier, trade_score, is_port, connections, road_budget_spent). | T |
| LSAVE-011 | SAVE-002 | Save state shall include: all road data. | T |
| LSAVE-012 | SAVE-002 | Save state shall include: trade routing graph. | T |
| LSAVE-013 | SAVE-002 | Save state shall include: global export value. | T |
| LSAVE-014 | SAVE-002 | Save state shall include: per-area discovered resources and suppression. | T |
| LSAVE-015 | SAVE-002 | Save state shall include: current season, day, time of day, and active weather. | T |
| LSAVE-016 | SAVE-002 | Save state shall include: precursor seed and site assignments. | T |
| LSAVE-017 | SAVE-002 | Save state shall include: landmark names. | T |
| LSAVE-018 | SAVE-002 | Save state shall include: active hirelings and their state. | T |
| LSAVE-019 | SAVE-002 | Save state shall include: camp position and contents (if active). | T |
| LSAVE-020 | SAVE-002 | Save state shall include: owned homes. | T |
| LSAVE-021 | SAVE-002 | Save state shall include: home storage contents. | T |
| LSAVE-022 | SAVE-002 | Save state shall include: dropped item bag position and contents (if exists). | T |
| LSAVE-023 | SAVE-002 | Save state shall include: map reveal state (revealed hexes). | T |
| LSAVE-024 | SAVE-002 | Save state shall include: player map markers. | T |
| LSAVE-025 | SAVE-002 | Save state shall include: founding state (if in progress). | T |
| LSAVE-026 | SAVE-002 | Save state shall include: reactivated ruin states (Scholar Reactivate charges). | T |
| LSAVE-027 | SAVE-002 | Save state shall include: Ritualist anchor position (if set). | T |
| LSAVE-028 | SAVE-003 | Save format shall be JSON. | T |

---

## 18. Project Structure

| LLR | Traces To | Requirement | T/U |
|---|---|---|---|
| LPROJ-001 | CORE-001 | Scene directory: res://scenes/ with subdirs: player/, monsters/, settlements/, camps/, ui/, map/, precursor/. | T |
| LPROJ-002 | CORE-001 | Script directory: res://scripts/ with subdirs: autoloads/, player/, monsters/, ui/, abilities/. | T |
| LPROJ-003 | CORE-001 | Autoloads shall include: DataLoader, SaveManager, InputManager, TimeManager, SeasonManager, WeatherManager, AreaManager, HexGrid, SettlementManager, SpawnManager, DisciplineManager, AudioManager, MusicManager, TradeGraph, FoundingManager, PlayerStats. | T |
| LPROJ-004 | CORE-005 | Data directory: res://data/ containing all JSON files. | T |
| LPROJ-005 | CORE-004 | User data: user://saves/ for save files. user://input_config.json for custom keybindings. | T |

---

*End of Document*
