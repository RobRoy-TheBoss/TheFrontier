# THE FRONTIER
## High-Level Requirements Document -- Version 0.5.0

**Companion to: GDD v8 | Godot 4 / GDScript / JSON**
**March 2026**

> MUST = Required for 1.0 | SHOULD = Desired, can ship without | POST = Post-launch

---

## 1. Core Application

| ID | Requirement | Priority |
|---|---|---|
| CORE-001 | Single-player first-person 3D game. Godot 4, GDScript. PC (Windows). | MUST |
| CORE-002 | Minimum 30 FPS on mid-range hardware. | MUST |
| CORE-003 | Keyboard/mouse and gamepad with rebindable controls. | MUST |
| CORE-004 | Auto-save on sleep. Manual save at any time. Multiple save files. | MUST |
| CORE-005 | All gameplay data in external JSON files. | MUST |
| CORE-006 | Pure sandbox. No main quest or scripted narrative. | MUST |

---

## 2. World and Map

| ID | Requirement | Priority |
|---|---|---|
| MAP-001 | Single handcrafted 3D open-world map. | MUST |
| MAP-002 | Map divided into hexagonal Areas (~600 on launch, 30x20). ~25 Areas per Region. ~25 Regions. | MUST |
| MAP-003 | Each Area: resource tags, richness values, spawn table ref, east-west difficulty, tags (River, Ford, Rapids, Portage, Cliff, Mountain, Mountain Pass, Deep Water Port), one pre-designed Settlement Site. | MUST |
| MAP-004 | Rivers run along Area edges (between hexes), not through Areas. | MUST |
| MAP-005 | River Areas: if two non-adjacent neighbors both have River tag, the Area must have Portage tag. | MUST |
| MAP-006 | A River Area without Ford or Portage blocks roads unless the settlement on it is Town+ (bridge auto-built). | MUST |
| MAP-007 | Cliff tag: impassable elevation change along Area edge. | MUST |
| MAP-008 | Mountain tag: no road through. Mountain Pass tag: road permitted. | MUST |
| MAP-009 | Deep Water Port Areas indicated by whale and seagull flock landmarks. | MUST |
| MAP-010 | Minimum 3 biome types with transitional blending. | MUST |
| MAP-011 | Continuous east-to-west difficulty scalar applied to spawn tables. | MUST |
| MAP-012 | Day/night cycle. 30 real-time minutes = 1 in-game day. All time values configurable. | MUST |
| MAP-013 | Summer daylight ~22 min, Winter ~12 min. Spring/Autumn intermediate. | MUST |
| MAP-014 | Four seasons, 10 days each. Configurable. | MUST |
| MAP-015 | Dynamic weather driven by seasonal probability tables. Rain increases cold. | MUST |
| MAP-016 | ~60 precursor sites (~1 per 10 Areas). Types randomized on new game (seed in save). | MUST |
| MAP-017 | Landmarks: ~1 per 20-30 Areas. Types: Precursor Towers, Lonely Mountains, Waterfalls, Needle Mountains, Seagull Flocks, Tall Trees. From high points, 3+ landmarks visible. | MUST |
| MAP-018 | ~3 minutes to cross wild Area, ~1 minute empty Area, ~2-3 minutes to fully explore. | MUST |
| MAP-019 | Map format documented for additional maps without code changes. | MUST |
| MAP-020 | Vertical slice prototype: 1 Region, 4x6 = 24 hexes. | MUST |

---

## 3. Player Character

### 3.1 Movement and Death

| ID | Requirement | Priority |
|---|---|---|
| PC-001 | First-person: walk, sprint, jump, crouch, swim. | MUST |
| PC-002 | Sprint consumes stamina. | MUST |
| PC-003 | Hard carry-weight limit. Over = no sprint, reduced speed. | MUST |
| PC-004 | Two weapon slots. Quick-swap button. | MUST |
| PC-005 | Pistols equippable in main or off-hand. | MUST |
| PC-006 | At zero health: respawn at last settlement. All items dropped at death location. | MUST |
| PC-007 | Camp and hirelings persist on death. | MUST |
| PC-008 | Previous death drops destroyed (only latest bag exists). | MUST |
| PC-009 | Founding-in-progress cancelled if player dies before reporting. | MUST |

### 3.2 Health and Stamina

| ID | Requirement | Priority |
|---|---|---|
| HP-001 | Numeric Health pool (HUD bar). Reduced by attacks, falls, hazards, DOTs. Slow regen, faster at rest. | MUST |
| HP-002 | Numeric Stamina pool (HUD bar). Consumed by sprint, attack, dodge, block. Regen when idle. Rate reduced by fatigue/hunger. | MUST |
| HP-003 | Below health threshold: each hit has probability of Injury. | MUST |

### 3.3 Injury

| ID | Requirement | Priority |
|---|---|---|
| INJ-001 | 7 injury types: Deep Wound (max health reduced), Cracked Ribs (increased stamina cost), Torn Muscle (increased attack cooldown), Bleeding Gash (health DOT + blood trail), Venom (health DOT + vision distortion), Sprained Ankle (movement speed reduced), Gut Sickness (general debuffs + temperature sensitivity narrowed, from spoiled food or temperature excess). | MUST |
| INJ-002 | Each injury: debuffs, treatment tier (field/camp/village/town/city). Healer hireling treats up to town-tier at camp. | MUST |
| INJ-003 | All injury definitions in JSON. | MUST |

### 3.4 Survival

| ID | Requirement | Priority |
|---|---|---|
| SURV-001 | Track: Hunger, Thirst, Temperature, Fatigue, Encumbrance. | MUST |
| SURV-002 | Rain increases effective cold level. | MUST |
| SURV-003 | Cold weather clothes have weight and inventory space cost. Cold weather tents heavier than normal. | MUST |
| SURV-004 | Stream water must be boiled at a campfire before drinking or risk Gut Sickness. Waterskins store water. Waterskins have no weight when empty. Settlement wells provide clean water. Alchemist can purify water. | MUST |
| SURV-005 | All rates/thresholds in JSON. | MUST |

---

## 4. Combat

### 4.1 Melee

| ID | Requirement | Priority |
|---|---|---|
| MEL-001 | Melee weapons: one-handed blade, two-handed blade, blunt. Stamina-based. | MUST |
| MEL-002 | Block and dodge-roll. Stamina cost. Monsters telegraph attacks. | MUST |
| MEL-003 | Shields: off-hand equipment. Superior block damage reduction vs. weapon-blocking. 1 rune slot. | MUST |
| MEL-004 | Off-hand options: shield, pistol, or empty. Two-handed weapons/bows/muskets require empty off-hand. | MUST |

### 4.2 Bows

| ID | Requirement | Priority |
|---|---|---|
| BOW-001 | Bows: silent ranged. Poor draw/aim without Survivalist. 2 rune slots. | MUST |
| BOW-002 | Arrows: purchased weighted items. Without Survivalist Arrow Recovery, spent arrows lost. | MUST |
| BOW-003 | Bows do not attract nearby monsters. | MUST |

### 4.3 Firearms

| ID | Requirement | Priority |
|---|---|---|
| RNG-001 | Pistol (1 rune slot, main/off-hand), musket (2 rune slots). High damage, slow reload, loud. | MUST |
| RNG-002 | Firearms attract nearby monsters on firing. | MUST |
| RNG-003 | Mineral powder for ammo: purchased at shops or Artificer-crafted only. | MUST |
| RNG-004 | Firearm condition/durability. Degraded = misfire. | SHOULD |

### 4.4 Rune System

| ID | Requirement | Priority |
|---|---|---|
| RUNE-001 | Rune slots: heavy armor 3/piece, medium 2/piece, light 1/piece (5 pieces). Two-hand melee 2, one-hand 1, shields 1, bows 2, muskets 2, pistols 1. | MUST |
| RUNE-002 | Runes found in world (ruins, caches, drops). Never crafted. | MUST |
| RUNE-003 | Rune effect values: random Poisson distribution with long tail. Higher rarity = higher mean. | MUST |
| RUNE-004 | Ranged weapons cannot have life steal runes. | MUST |
| RUNE-005 | Weapons/armor primarily purchased at settlements. | MUST |
| RUNE-006 | Rune definitions and placements in JSON. | MUST |

---

## 5. Monsters

| ID | Requirement | Priority |
|---|---|---|
| MON-001 | Per-Area hex spawn tables in JSON. East-to-west scalar. | MUST |
| MON-002 | Inner safe zone around settlements (no monsters ever). | MUST |
| MON-003 | Area suppression: TP ~25%, Village ~50%, Town ~75%, City 100%. Configurable. | MUST |
| MON-004 | Behavior types: territorial, ambush, swarm, heavy, apex. | MUST |
| MON-005 | Fire behavior: most avoid campfire. River reptiles and bright mountain birds attracted to fire. | MUST |
| MON-006 | Light behavior: some monsters attracted to light sources (lantern, torch, firefly jar), some repelled. Per-type in JSON. | MUST |
| MON-007 | Monster definitions in JSON: stats, behavior, loot (runes, materials, reagents), fire/light reaction. | MUST |
| MON-008 | Minimum 8 types at launch across all categories. | SHOULD |

---

## 6. Navigation and Exploration

| ID | Requirement | Priority |
|---|---|---|
| NAV-001 | Player starts with empty map. Map filled by surveying, Cartographer hireling, or purchase. | MUST |
| NAV-002 | Compass: persistent HUD, cardinal direction. | MUST |
| NAV-003 | No minimap, no position indicator, no waypoints, no quest markers. | MUST |
| NAV-004 | Surveying tools: naked eye (start), spyglass (TP+), theodolite (Town+). Fill in map hexes from high points. | MUST |
| NAV-005 | Village sells 2-hex radius map. Town 3-hex. City 4-hex. Maps show biomes, rivers, cliffs, landmarks. | MUST |
| NAV-006 | Revealed hex shows landmarks up to 2 hexes beyond without additional data. | MUST |
| NAV-007 | Cartographer hireling creates maps of explored hexes. | MUST |
| NAV-008 | Player can place custom map markers: fox (hunting), campsite, portage, rapids, custom. | MUST |
| NAV-009 | No player position dot on any map. | MUST |
| NAV-010 | Landmarks: ~1 per 20-30 Areas. 3+ visible from high points. Deep Water Ports indicated by whales + seagulls. | MUST |
| NAV-011 | Journal auto-populates via player scanning (monsters, landmarks, items, resources). Active scan action required. | MUST |
| NAV-012 | Resource discovery: visual indicators, logged on proximity. Surveyor hireling discovers all in Area. | MUST |
| NAV-013 | Named landmarks. Player assigns names on discovery. Names appear on maps. | MUST |

---

## 7. Camps, Hirelings, and Founding

### 7.1 Camps

| ID | Requirement | Priority |
|---|---|---|
| CAMP-001 | On deciding to camp, game nudges player toward appropriate site ("good spot north"). Player walks there. 2-second setup cutscene. No teleportation. | MUST |
| CAMP-002 | Camp equipment: tent, campfire, alchemy set. All weighted items. Cold tents heavier. | MUST |
| CAMP-003 | Campfire: warmth, cooking, light, monster deterrent. Some types attracted to fire/light. | MUST |
| CAMP-004 | Camps temporary: packable, no suppression, no trade. | MUST |
| CAMP-005 | Player can abandon camp via menu (hirelings dismissed, camp items destroyed). | MUST |
| CAMP-006 | Camp and hirelings persist on player death. | MUST |

### 7.2 Hirelings

| ID | Requirement | Priority |
|---|---|---|
| HIRE-001 | Hired at settlements. Stay at camp. Do not travel with player. Bring own tents. Generic at launch. | MUST |
| HIRE-002 | Hirelings never draw aggro, cannot be killed, cower/flee when monsters attack. | MUST |
| HIRE-003 | Porter (Village+): drops backpack container at camp. Transfers to/from home storage when at player's home. | MUST |
| HIRE-004 | Hunter (Village+): auto food at camp. | MUST |
| HIRE-005 | Guide (Town+): nearby POI indicators from camp. | MUST |
| HIRE-006 | Surveyor (Town+): discovers Area resources. Required for founding. | MUST |
| HIRE-007 | Cartographer (Town+): maps of explored Areas. | MUST |
| HIRE-008 | Healer (Town+): town-tier injuries at camp. | MUST |
| HIRE-009 | Mid-game ~1 affordable, late-game 2-3. Costs in JSON. | MUST |
| HIRE-010 | Hireling skill improvement over time. | POST |

### 7.3 Settlement Founding

| ID | Requirement | Priority |
|---|---|---|
| FOUND-001 | Founding requires Surveyor hireling (hired at Village+). No flag system. | MUST |
| FOUND-002 | Player travels to Area with Surveyor. Makes camp (game nudges to settlement site). | MUST |
| FOUND-003 | Player directs Surveyor to mark site. Surveyor works for 1-2 in-game days (stays at camp). | MUST |
| FOUND-004 | After Surveyor completes, player returns to hiring Village and reports to mayor. | MUST |
| FOUND-005 | Settlement appears at pre-designed site after next sleep following report. Tier 1 (Trading Post). | MUST |
| FOUND-006 | If player dies before reporting, founding cancelled. Surveyor returns to Village. | MUST |

---

## 8. Settlements and Economy

### 8.1 Tiers

| ID | Requirement | Priority |
|---|---|---|
| TIER-001 | 4 tiers: Trading Post, Village, Town, City. Services per GDD v8 Section 8. | MUST |
| TIER-002 | Resource exploitation: TP own Area. Village +adjacent 50%. Town +adjacent 100%. City +adjacent 100% +ring-2 25%. | MUST |
| TIER-003 | Town+ on River Area auto-builds bridges into adjacent Areas. | MUST |
| TIER-004 | Village+ sells maps (2/3/4 hex radius by tier). | MUST |
| TIER-005 | Crestport starts as Village in Deep Water Port Area (enables initial Surveyor hire for founding). | MUST |
| TIER-006 | Tiers never decrease. Visual per tier. Transitions on sleep. | MUST |

### 8.2 Per-Settlement Growth and Consumption

| ID | Requirement | Priority |
|---|---|---|
| GROW-001 | Per-settlement trade score: local output (own + exploited adjacent per tier) as primary driver, pass-through traffic as secondary bonus, diversity multiplier, connection count. | MUST |
| GROW-002 | Exponential tier thresholds: Village ~100, Town ~500, City ~5000. Plus resource type requirements (Village: food+timber; Town: +iron; City: +one more). All configurable in JSON. | MUST |
| GROW-003 | Trade route consumption: each settlement consumes a percentage of raw materials flowing through it toward a port. Rates per tier: TP ~5%, Village ~15%, Town ~30%, City ~50%. Configurable in JSON. | MUST |
| GROW-004 | Consumption applies to raw materials flowing coastward only. Manufactured goods flow freely inland. | MUST |
| GROW-005 | Export value contribution from a source settlement = its raw output minus cumulative consumption at each node along the route to port. | MUST |
| GROW-006 | First-mover advantage: at a junction, the settlement that grows first consumes more, reducing throughput available to competing nodes. No artificial balancing. | MUST |
| GROW-007 | Factor weights and consumption rates configurable in JSON. | MUST |

### 8.3 Roads

| ID | Requirement | Priority |
|---|---|---|
| ROAD-001 | Every settlement gets 9 road budget regardless of tier. | MUST |
| ROAD-002 | Road cost = hex distance between settlements. | MUST |
| ROAD-003 | Road evaluation occurs on founding (initial placement) and on each tier-up only. Not re-evaluated every sleep. | MUST |
| ROAD-004 | Only initiating settlement spends budget. Target gets connection free. | MUST |
| ROAD-005 | On tier-up: re-evaluate roads. New roads placed (bridges if Town+). Old roads from previous tiers persist and are never deleted. | MUST |
| ROAD-006 | Quality = min tier of pair (trail/game trail/dirt/cobblestone). Speed bonus per quality. Auto-upgrades as settlements grow. | MUST |
| ROAD-007 | Roads blocked by River (unless Ford or Town+ bridge), Mountain (unless Pass), Cliff (always impassable). | MUST |
| ROAD-008 | Maximum single road length: 9 hexes. | MUST |
| ROAD-009 | Road pathing must respect hex edge constraints. | MUST |

### 8.4 Ports and Export

| ID | Requirement | Priority |
|---|---|---|
| PORT-001 | Deep Water Port tag. Settlement exports directly. | MUST |
| PORT-002 | Trade routes to nearest connected port (shortest path). | MUST |
| PORT-003 | New ports trigger reroute. Stagnation possible. Tiers never decrease. | MUST |
| PORT-004 | Global Export Value: sum of export goods reaching any port after consumption along each trade route. Thresholds gate Old World goods. | MUST |
| PORT-005 | Player earns currency selling. Spends on gear, hirelings, maps, homes, discipline enhancement, reagents. | MUST |

### 8.5 Homes

| ID | Requirement | Priority |
|---|---|---|
| HOME-001 | Village+. Storage (infinite, shared across all homes), alchemy workshop, free bed. | MUST |
| HOME-002 | Porter at home: talk to transfer to/from home storage. | MUST |

---

## 9. Disciplines

| ID | Requirement | Priority |
|---|---|---|
| DSYS-001 | 9 disciplines: Survivalist, Ritualist, Pathfinder, Warrior, Swordsman, Artificer, Alchemist, Scholar, Wizard. | MUST |
| DSYS-002 | Max 3 attunements. Permanent. No respec. 84 possible builds. | MUST |
| DSYS-003 | ~60 precursor sites randomized on new game. 18+ Places of Power (2/discipline). Seed in save. | MUST |
| DSYS-004 | Attunement at Place of Power grants Ability 1. | MUST |
| DSYS-005 | Discipline XP earned through use (triggers in JSON). | MUST |
| DSYS-006 | Abilities 2+ unlocked at Cities: spend XP + small currency. | MUST |
| DSYS-007 | Second Place of Power of same discipline: bonus XP or capstone. | MUST |
| DSYS-008 | All 61 abilities as specified in GDD v8 Section 9. Each ability defined in JSON. | MUST |
| DSYS-009 | Pathfinder abilities: Wayfinder (survey range +50%), Light Provisions (food/water weight -50%), Cartography (produce map at camp), Prospect (sense nearest undiscovered resource in Area), Steady Pace (stamina regen +30%), Pathsense (sense precursor sites from high ground). | MUST |
| DSYS-010 | Scholar abilities: Runic Literacy (read precursor inscriptions), Salvage (improved ruin loot), Shelter (sleep in ruins as Village-tier rest), Glyph Ward (activate dormant glyphs for large safe zone at ruin sites), Deep Reading (study artifact to reveal related precursor sites on map), Reactivate (restore sustenance systems in ruins, restores hunger/thirst, limited charges). | MUST |
| DSYS-011 | Alchemist Master Brewer includes firefly jar recipe (white light, full color, large area). | MUST |
| DSYS-012 | Wizard reagent: mineral powder purchasable or Artificer-crafted only. Other reagents per GDD. | MUST |

---

## 10. Alchemy and Cooking

| ID | Requirement | Priority |
|---|---|---|
| CRAFT-001 | Gather plants. Alchemist reveals hidden nodes. | MUST |
| CRAFT-002 | Cook at campfire: hunger + buffs. Raw food = illness risk. Settlement meals superior. | MUST |
| CRAFT-003 | Potions at camp alchemy set, home workshop, or Town alchemist. | MUST |
| CRAFT-004 | Firefly jar: Alchemist-crafted. White light, full color, large area. Light/monster interactions. | MUST |
| CRAFT-005 | All recipes in JSON. | MUST |

---

## 11. Sleep and Batch

| ID | Requirement | Priority |
|---|---|---|
| SLEEP-001 | Sleep at settlement or camp with tent. Advances clock. | MUST |
| SLEEP-002 | Batch order: (1) founding progress, (2) resource extraction, (3) trade routing, (4) per-settlement trade score, (5) tier checks, (6) visual updates, (7) road formation/quality, (8) Area suppression recalc, (9) Hunter food, (10) Trapper harvest, (11) hireling costs, (12) injury healing, (13) fatigue reset, (14) hunger/thirst cost, (15) day/season advance, (16) weather roll, (17) auto-save. | MUST |
| SLEEP-003 | Optional post-sleep summary. | SHOULD |

---

## 12. Inventory

| ID | Requirement | Priority |
|---|---|---|
| INV-001 | Weight-based inventory. All items weighted including camp gear, cold clothes, tents. | MUST |
| INV-002 | Porter backpack: container at camp with capacity. Transfers between camps. | MUST |
| INV-003 | Home storage: infinite, shared across all owned homes. | MUST |
| INV-004 | Rune socketing interface. | MUST |
| INV-005 | Maps, runes, arrows, ammo, reagents: all inventory items. | MUST |

---

## 13. Seasons

| ID | Requirement | Priority |
|---|---|---|
| SEA-001 | Four seasons. Modify temperature, movement, spawns, extraction, visuals, daylight. | MUST |
| SEA-002 | All values in JSON. Configurable. | MUST |

---

## 14. UI

| ID | Requirement | Priority |
|---|---|---|
| UI-001 | HUD: compass, weapon, Health bar, Stamina bar, status effects. Survival via audio/visual cues. | MUST |
| UI-002 | Inventory with rune socketing. | MUST |
| UI-003 | Map viewer (empty, fills in). Settlement markers. Player custom pins. No position dot. | MUST |
| UI-004 | Scan action for journal. | MUST |
| UI-005 | Journal: creatures, ingredients, landmarks, sites, notes. Auto-populated via scan. | MUST |
| UI-006 | Settlement screen: tier, resources, trade score, connections, growth. | MUST |
| UI-007 | Discipline screen: attunements, unlocks, XP, next cost. | MUST |
| UI-008 | Quick-swap weapon indicator. | MUST |
| UI-009 | Gamepad support. Settings menu. | MUST |

---

## 15. Audio

| ID | Requirement | Priority |
|---|---|---|
| AUD-001 | 3D positional audio. Biome ambience crossfade. | MUST |
| AUD-002 | Monster audio cues: learnable, distinct. | MUST |
| AUD-003 | Bow = quiet. Firearm = loud (attracts). Light sources have ambient sound. | MUST |
| AUD-004 | Survival cues at thresholds. | MUST |
| AUD-005 | Settlement layers by tier. Event-driven music. | SHOULD |

---

## 16. Save

| ID | Requirement | Priority |
|---|---|---|
| SAVE-001 | Complete world state restoration. | MUST |
| SAVE-002 | State: player, inventory, equipment+runes (with random values), HP/stamina/injuries, survival, attunements+XP+unlocks, journal, landmarks, settlements (tier/score/port), roads, routing, export value, Area states (discovered resources, suppression), season/day/time, precursor seed+assignments, hirelings, camp, homes, dropped items (latest only), map reveal state, player markers. | MUST |
| SAVE-003 | Auto-save on sleep. Manual anytime. JSON format. | MUST |

---

## 17. Data Architecture

All JSON files:

| ID | Requirement | Priority |
|---|---|---|
| DATA-001 | monsters.json, spawn_tables.json, resources.json, areas.json (hex grid + tags + settlement sites), settlement_tiers.json (including consumption rates per tier and exponential score thresholds), trade_weights.json, export_thresholds.json, manufactured_goods.json, disciplines.json (9 disciplines, 61 abilities, XP triggers, costs), reagents.json, runes.json (types, rarities, Poisson params), recipes.json, items.json, injuries.json (7 types), survival.json, seasons.json (with daylight curves), weapons.json (with noise, rune slots), hirelings.json, roads.json (with hex constraints), landmarks.json. | MUST |

---

## 18. Post-Launch

| ID | Requirement | Priority |
|---|---|---|
| POST-001 | Co-op (2-4 players, shared world). | POST |
| POST-002 | Community map editor, Workshop. | POST |
| POST-003 | Bandits / road vulnerability. | POST |
| POST-004 | Named hirelings, skill improvement, travel companions. | POST |
| POST-005 | Additional settlement tiers/variants. Settlement attacks. | POST |
| POST-006 | Additional disciplines. | POST |
| POST-007 | Separately instanced dungeons. | POST |
| POST-008 | Console ports. | POST |

---

*End of Document*
