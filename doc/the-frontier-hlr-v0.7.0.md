# THE FRONTIER
## High-Level Requirements Document -- Version 0.7.0

**Companion to: GDD v0.7.0 | Godot 4 / GDScript / JSON**
**March 2026**

> MUST = Required for 1.0 | SHOULD = Desired, can ship without | POST = Post-launch

---

## 1. Core Application

| ID | Requirement | Priority |
|---|---|---|
| CORE-001 | Third-person 3D game. Godot 4, GDScript. PC (Windows). | MUST |
| CORE-002 | Minimum 30 FPS on mid-range hardware. | MUST |
| CORE-003 | Keyboard/mouse and gamepad with rebindable controls. | MUST |
| CORE-004 | Auto-save on sleep. Manual save anytime. Multiple slots. | MUST |
| CORE-005 | All gameplay data in external JSON files. | MUST |
| CORE-006 | Pure sandbox. No main quest. | MUST |
| CORE-007 | New game: player spawns at Crestport (Village). Compass in inventory. Map empty. Precursor sites randomized. | MUST |

---

## 2. World and Map

| ID | Requirement | Priority |
|---|---|---|
| MAP-001 | Single handcrafted 3D open-world map assembled from modular hex templates. | MUST |
| MAP-002 | 200-300 hexagonal Areas at launch. | MUST |
| MAP-003 | Each Area: resource tags, richness, spawn table, difficulty, tags (River/Ford/Rapids/Portage/Cliff/Mountain/Mountain Pass/Deep Water Port), settlement site. | MUST |
| MAP-004 | Rivers run along Area edges, not through Areas. | MUST |
| MAP-005 | Portage required if two non-adjacent neighbors both have River tag. | MUST |
| MAP-006 | River without Ford/Portage blocks roads unless Town+ bridge. | MUST |
| MAP-007 | Cliff: impassable elevation change along edge. | MUST |
| MAP-008 | Mountain: no road. Mountain Pass: road permitted. | MUST |
| MAP-009 | Deep Water Port indicated by whale + seagull landmarks. | MUST |
| MAP-010 | Minimum 3 biome types with transitional blending. | MUST |
| MAP-011 | East-to-west difficulty scalar. | MUST |
| MAP-012 | Day/night cycle. 30 real-time minutes = 1 in-game day. Configurable. | MUST |
| MAP-013 | Launch: fixed daylight (~17 min). Variable daylight with seasons post-launch. | MUST |
| MAP-014 | Seasons (4, 10 days each, configurable). | POST |
| MAP-015 | Dynamic weather. Rain increases cold. | POST |
| MAP-016 | Precursor sites (~1 per 10 Areas). Randomized on new game. Seed in save. | MUST |
| MAP-017 | Landmarks: ~1 per 20-30 Areas. 3+ visible from high points. | MUST |
| MAP-018 | ~3 min to cross wild Area. ~1 min empty. ~2-3 min to explore. | MUST |
| MAP-019 | Modular hex template library: 15-20 per biome. 80% template, 20% custom. AI-assisted generation. | MUST |
| MAP-020 | Horizontal slice prototype: 6x4 = 24 hexes. | MUST |

---

## 3. Player Character

### 3.1 Camera and Movement

| ID | Requirement | Priority |
|---|---|---|
| PC-001 | Third-person over-the-shoulder camera. Adjustable distance. Terrain collision. | MUST |
| PC-002 | Walk, sprint, jump, crouch, swim. | MUST |
| PC-003 | Sprint consumes stamina. | MUST |
| PC-004 | Hard carry-weight limit. Over = no sprint, slow walk. | MUST |
| PC-005 | Two weapon slots. Quick-swap button. No off-hand at launch. | MUST |
| PC-006 | Character model visible with armor, weapons, rune effects. | MUST |

### 3.2 Death

| ID | Requirement | Priority |
|---|---|---|
| PC-010 | At zero health: respawn at last settlement. Items dropped at death location. | MUST |
| PC-011 | Camp and hirelings persist on death. | MUST |
| PC-012 | Previous death drops destroyed (only latest bag). | MUST |
| PC-014 | Death drop bag is interactable. Player can reclaim items from it. | MUST |
| PC-013 | Founding cancelled if player dies before reporting. | MUST |

### 3.3 Health and Stamina

| ID | Requirement | Priority |
|---|---|---|
| HP-001 | Numeric Health pool. Slow regen. | MUST |
| HP-002 | Numeric Stamina pool. Regen when idle. Rate reduced by fatigue/hunger. | MUST |
| HP-003 | Below health threshold: each hit has injury probability. | MUST |

### 3.4 Injury

| ID | Requirement | Priority |
|---|---|---|
| INJ-001 | 7 injury types per GDD v0.7.0 Section 3. | MUST |
| INJ-002 | Each injury: debuffs, treatment tier. Healer hireling (post-launch) treats town-tier at camp. | MUST |
| INJ-003 | All injury definitions in JSON. | MUST |

### 3.5 Survival

| ID | Requirement | Priority |
|---|---|---|
| SURV-001 | Track: Hunger, Thirst, Temperature, Fatigue, Encumbrance. | MUST |
| SURV-002 | Rain increases cold. | POST |
| SURV-003 | Cold clothes have weight. Cold tents heavier. | POST |
| SURV-004 | Stream water must be boiled at campfire or risk Gut Sickness. Waterskins no weight empty. Settlement wells clean. | MUST |
| SURV-006 | Alchemist can purify unboiled water without campfire (no Gut Sickness risk). | MUST |
| SURV-005 | All rates/thresholds in JSON. | MUST |

---

## 4. Combat

### 4.1 Melee

| ID | Requirement | Priority |
|---|---|---|
| MEL-001 | One-handed blade, two-handed blade, blunt. Stamina-based. Third-person dodge rolls. | MUST |
| MEL-002 | Block (weapon-blocking) and dodge-roll. Stamina cost. Telegraphed attacks. | MUST |

### 4.1b Armor

| ID | Requirement | Priority |
|---|---|---|
| ARM-001 | Three armor weight classes: light (1 rune slot/piece), medium (2), heavy (3). 5 pieces each. | MUST |
| ARM-002 | Heavy armor equippable only with Warrior Ironclad ability. | MUST |
| ARM-003 | Armor provides damage reduction. Values in JSON. | MUST |

### 4.2 Bows

| ID | Requirement | Priority |
|---|---|---|
| BOW-001 | Silent ranged. Over-shoulder aim. Poor draw/aim without Survivalist. 2 rune slots. | MUST |
| BOW-002 | Arrows: purchased weighted items. Without Arrow Recovery, spent arrows lost. | MUST |
| BOW-003 | Bows do not attract monsters. | MUST |

### 4.3 Firearms

| ID | Requirement | Priority |
|---|---|---|
| RNG-001 | Pistol (1 rune slot), musket (2 rune slots). High damage, slow reload, loud. | MUST |
| RNG-002 | Firearms attract nearby monsters. | MUST |
| RNG-003 | Mineral powder: purchased or Artificer-crafted only. | MUST |
| RNG-004 | Firearm condition/durability. Degraded = misfire. | SHOULD |

### 4.3b Durability

| ID | Requirement | Priority |
|---|---|---|
| DUR-001 | All weapons and armor have durability. Degrades with use. At zero: item breaks (no function until repaired). | MUST |
| DUR-002 | Repair at settlement smithy or via Artificer Field Repair. | MUST |

### 4.4 Rune System

| ID | Requirement | Priority |
|---|---|---|
| RUNE-001 | Rune slots per GDD v0.7.0 Section 4. | MUST |
| RUNE-002 | Runes found in world. Never crafted. | MUST |
| RUNE-003 | Poisson distribution for effect values. Higher rarity = higher mean. | MUST |
| RUNE-004 | Ranged weapons cannot have life steal. | MUST |
| RUNE-005 | Rune effects visible on character model. | MUST |
| RUNE-006 | All rune definitions in JSON. | MUST |

### 4.5 Field Tools

| ID | Requirement | Priority |
|---|---|---|
| TOOL-001 | Axe: chop trees for wood. Wood is heavy. | MUST |
| TOOL-002 | Pickaxe: mine ore deposits. | MUST |
| TOOL-003 | Fishing rod: catch fish at rivers/streams. Lighter than bow. | MUST |

### 4.6 Off-Hand System

| ID | Requirement | Priority |
|---|---|---|
| MEL-003 | Shields: off-hand, 1 rune slot, superior block. | POST |
| MEL-004 | Off-hand pistol. | POST |

---

## 5. Monsters

| ID | Requirement | Priority |
|---|---|---|
| MON-001 | Per-Area hex spawn tables. East-to-west scalar. | MUST |
| MON-002 | Inner safe zone around settlements: zero spawns, monsters cannot enter. | MUST |
| MON-003 | Area-wide spawn density reduction: TP ~25%, Village ~50%, Town ~75%, City 100%. Separate from inner safe zone. | MUST |
| MON-004 | Behavior types: territorial, ambush, swarm, heavy, docile, apex. | MUST |
| MON-005 | Fire behavior: most avoid. River reptiles + mountain birds attracted. | MUST |
| MON-006 | Light behavior: some attracted, some repelled. Per-type in JSON. | MUST |
| MON-007 | Monster definitions in JSON: stats, behavior, loot, fire/light reaction. | MUST |
| MON-008 | Docile animals (rabbits, birds, deer): flee, drop meat on kill. | MUST |
| MON-009 | Minimum 8 monster types at launch across all categories. | SHOULD |
| MON-010 | Monster shall telegraph attacks. | MUST |

---

## 6. Navigation and Exploration

| ID | Requirement | Priority |
|---|---|---|
| NAV-001 | Player starts with empty map. Filled by surveying. | MUST |
| NAV-002 | Compass: persistent HUD. | MUST |
| NAV-003 | No minimap, no position indicator, no waypoints. | MUST |
| NAV-004 | Surveying tools: naked eye, spyglass (TP+), theodolite (Town+). | MUST |
| NAV-005 | Purchased maps (Village 2-hex, Town 3-hex, City 4-hex). | POST |
| NAV-006 | Revealed hex shows landmarks 2 hexes beyond. | MUST |
| NAV-007 | Cartographer hireling creates maps. | POST |
| NAV-008 | Player map markers: fox, campsite, portage, rapids, custom. | MUST |
| NAV-009 | No player position dot. | MUST |
| NAV-010 | Landmarks per GDD v0.7.0. Deep Water Ports = whales + seagulls. | MUST |
| NAV-011 | Journal auto-populates via proximity scan (third-person interaction, not raycast). | MUST |
| NAV-012 | Resource discovery on proximity. Surveyor discovers all in Area. | MUST |
| NAV-013 | Named landmarks on first scan. Persist in save. | MUST |

---

## 7. Camps, Hirelings, and Founding

### 7.1 Camps

| ID | Requirement | Priority |
|---|---|---|
| CAMP-001 | Game nudges toward camp site. Player walks. 2s cutscene. No teleport. | MUST |
| CAMP-002 | Tent: required, purchased, weighted. One tent at a time -- shops refuse sale if tent exists in inventory or camp is active. | MUST |
| CAMP-003 | Campfire kit: built from wood (axe + trees). Heavy. Warmth, light, boil water. | MUST |
| CAMP-004 | Cooking kit: purchased, heavy. Enables meat/fish cooking. Requires campfire. | MUST |
| CAMP-005 | Alchemy set: purchased, heavy. Requires campfire. | MUST |
| CAMP-006 | Pack up camp items only at campsite. | MUST |
| CAMP-007 | Abandon camp via menu: destroys all camp items, dismisses hirelings. If founding in progress, cancels founding and Surveyor teleports to origin. | MUST |
| CAMP-008 | Camp and hirelings persist on death. | MUST |
| CAMP-009 | One camp at a time. Cannot set up a second camp. | MUST |
| CAMP-010 | Camp chest: purchasable storage container at camp. Contents destroyed on abandon. | MUST |

### 7.2 Hirelings (Launch)

| ID | Requirement | Priority |
|---|---|---|
| HIRE-001 | 3 types at launch: Porter, Hunter, Surveyor. Stay at camp. Own tents. Never aggro. Cannot be killed. | MUST |
| HIRE-002 | Porter (Village+): backpack container at camp. Transfer to/from home storage at home. | MUST |
| HIRE-003 | Hunter (Village+): auto food at camp on sleep. | MUST |
| HIRE-004 | Surveyor (Town+): discovers Area resources. Required for founding. | MUST |
| HIRE-005 | Hireling daily costs deducted on sleep. Dismiss if insufficient. | MUST |
| HIRE-006 | Guide (Town+), Cartographer (Town+), Healer (Town+). | POST |

### 7.3 Founding

| ID | Requirement | Priority |
|---|---|---|
| FOUND-001 | Founding requires Surveyor hireling. No flags. | MUST |
| FOUND-002 | Camp at settlement site (game nudges). Surveyor marks 1-2 days. | MUST |
| FOUND-003 | Report to origin Village mayor. Settlement on next sleep. Tier 1. | MUST |
| FOUND-004 | Death before report cancels founding. Surveyor returns. | MUST |

---

## 8. Settlements and Economy

### 8.1 Tiers

| ID | Requirement | Priority |
|---|---|---|
| TIER-001 | 4 tiers per GDD v0.7.0. | MUST |
| TIER-002 | Exploitation: TP own. Village +adj 50%. Town +adj 100%. City +adj 100% +ring-2 25%. | MUST |
| TIER-003 | Town+ on River auto-bridges. | MUST |
| TIER-004 | Crestport starts as Village in Deep Water Port. | MUST |
| TIER-005 | Tiers never decrease. Visual per tier on sleep. | MUST |
| TIER-006 | Exploitation overlap: highest tier wins. Ties by trade score. | MUST |

### 8.2 Growth and Consumption

| ID | Requirement | Priority |
|---|---|---|
| GROW-001 | Per-settlement trade score: local output primary, pass-through secondary, diversity, connections. | MUST |
| GROW-002 | Exponential thresholds (100/500/5000) + resource type requirements. Configurable. | MUST |
| GROW-003 | Consumption per tier (5/15/30/50%). Raw materials coastward only. Goods flow freely inland. | MUST |
| GROW-004 | First-mover advantage at junctions. | MUST |
| GROW-005 | All weights and rates in JSON. | MUST |

### 8.3 Roads

| ID | Requirement | Priority |
|---|---|---|
| ROAD-001 | Budget 9 per settlement. Cost = hex distance. | MUST |
| ROAD-002 | Evaluate on founding and tier-up only. Not every sleep. | MUST |
| ROAD-003 | Target by trade score descending. Greedy. | MUST |
| ROAD-004 | Initiator pays. Target free. | MUST |
| ROAD-005 | Old roads never deleted. | MUST |
| ROAD-006 | Quality = min tier. Speed bonus per quality. | MUST |
| ROAD-007 | Blocked by river (unless ford/bridge), mountain (unless pass), cliff. Max 9 hex. | MUST |

### 8.4 Ports and Export

| ID | Requirement | Priority |
|---|---|---|
| PORT-001 | Deep Water Port exports directly. | MUST |
| PORT-002 | Trade routes to nearest port. Dijkstra. | MUST |
| PORT-003 | New ports trigger reroute. Stagnation possible. | MUST |
| PORT-004 | Export value: goods reaching port after consumption. Thresholds gate goods. | MUST |

### 8.5 Homes

| ID | Requirement | Priority |
|---|---|---|
| HOME-001 | Village+. Infinite storage shared across all homes. Alchemy workshop. Free bed. | MUST |
| HOME-002 | Porter transfer at home. | MUST |

### 8.6 Shops and Currency

| ID | Requirement | Priority |
|---|---|---|
| SHOP-001 | Gold currency. Buy/sell at settlement shop NPCs. | MUST |
| SHOP-002 | Shop inventory filtered by: export tier (global) AND settlement tier (local). Higher tiers unlock better goods. | MUST |
| SHOP-003 | Settlement meals at Village+ tavern NPC: best buffs, costs gold. | MUST |

---

## 9. Disciplines

| ID | Requirement | Priority |
|---|---|---|
| DSYS-001 | Launch: 4 disciplines (Survivalist, Warrior, Artificer, Alchemist). 28 abilities. | MUST |
| DSYS-002 | Max 3 attunements. Permanent. No respec. | MUST |
| DSYS-003 | Precursor sites randomized. 8+ Places of Power (2/discipline). Seed in save. | MUST |
| DSYS-004 | Attunement grants Ability 1. | MUST |
| DSYS-005 | XP earned through use (triggers in JSON). | MUST |
| DSYS-006 | Abilities 2+ at Cities: XP + currency. | MUST |
| DSYS-007 | All 28 launch abilities per GDD v0.7.0. Each in JSON. | MUST |
| DSYS-008 | Post-launch: +5 disciplines (Ritualist, Swordsman, Wizard, Pathfinder, Scholar). Total 9, 61 abilities, 84 builds. | POST |

---

## 10. Food, Alchemy, and Cooking

| ID | Requirement | Priority |
|---|---|---|
| CRAFT-001 | Food hierarchy per GDD v0.7.0 Section 10. Berries, fish, meat, rations, Hunter, settlement meals. | MUST |
| CRAFT-002 | Raw meat and unboiled water risk Gut Sickness. | MUST |
| CRAFT-003 | Cooking requires campfire kit + cooking kit. | MUST |
| CRAFT-004 | Rations: best hunger + half-day stamina regen + carry capacity buff. Eating a new ration resets timer, buffs do not stack. | MUST |
| CRAFT-005 | Cooked meat/fish spoils in ~2 in-game days. | MUST |
| CRAFT-009 | Items with spoil_timer tick down over time. Expired food: Gut Sickness risk on consumption or auto-destroyed. | MUST |
| CRAFT-010 | Fishing: 1-second interaction with animation at water. Requires rod. Yields 1 fish. Interruptible by damage. | MUST |
| CRAFT-011 | Butchering: 1-second interaction with animation at docile corpse. Yields base meat (more with Field Dressing). Interruptible by damage. | MUST |
| CRAFT-009 | Items with spoil_timer tick down over time. Expired food: Gut Sickness risk on consumption or auto-destroyed. | MUST |
| CRAFT-006 | Alchemy at camp set or home. Town alchemists sell/brew. | MUST |
| CRAFT-007 | Gathering plants. Alchemist sees hidden nodes. | MUST |
| CRAFT-008 | All recipes in JSON. | MUST |

---

## 11. Sleep and Batch

| ID | Requirement | Priority |
|---|---|---|
| SLEEP-001 | Sleep at settlement bed or camp tent. Advances clock. | MUST |
| SLEEP-002 | Batch: founding, extraction, routing, trade score, consumption, tier checks, visuals, roads, suppression, Hunter food, hireling costs, injury healing, fatigue reset, hunger/thirst cost, day advance, auto-save. | MUST |
| SLEEP-003 | Optional post-sleep summary. | SHOULD |

---

## 12. Inventory

| ID | Requirement | Priority |
|---|---|---|
| INV-001 | Weight-based. Camp gear, tools, food, water all weighted. | MUST |
| INV-002 | Porter backpack container at camp. | MUST |
| INV-003 | Home storage: infinite, shared. | MUST |
| INV-004 | Rune socketing interface. | MUST |

---

## 13. UI

| ID | Requirement | Priority |
|---|---|---|
| UI-001 | HUD: compass, weapon, Health/Stamina bars, status effects. | MUST |
| UI-002 | Inventory with rune socketing. | MUST |
| UI-003 | Map viewer (fills in). Settlement markers. Player pins. No position dot. | MUST |
| UI-004 | Scan interaction for journal. | MUST |
| UI-005 | Journal: creatures, ingredients, landmarks, sites, notes. | MUST |
| UI-006 | Settlement screen. | MUST |
| UI-007 | Discipline screen. | MUST |
| UI-008 | Quick-swap indicator. | MUST |
| UI-009 | Pause menu: Resume, Save, Settings, Abandon Camp, Quit. | MUST |
| UI-010 | Gamepad support. Settings menu. | MUST |

---

## 14. Audio

| ID | Requirement | Priority |
|---|---|---|
| AUD-001 | 3D positional audio. Biome ambience crossfade. | MUST |
| AUD-002 | Monster audio cues: learnable, distinct. | MUST |
| AUD-003 | Bow = quiet. Firearm = loud. | MUST |
| AUD-004 | Survival cues at thresholds. | MUST |
| AUD-005 | Settlement layers by tier. Event-driven music. | SHOULD |

---

## 15. Save

| ID | Requirement | Priority |
|---|---|---|
| SAVE-001 | Complete world state restoration. | MUST |
| SAVE-002 | State per GDD v0.7.0 Section 13 technical notes. | MUST |
| SAVE-003 | Auto-save on sleep. Manual anytime. JSON. | MUST |

---

## 16. Data Architecture

| ID | Requirement | Priority |
|---|---|---|
| DATA-001 | All JSON files per GDD v0.7.0: monsters, spawns, resources, areas (hex + templates), tiers (consumption + thresholds + exploitation), trade weights, export thresholds, goods, disciplines (4 launch, 28 abilities), runes (Poisson), items (tools + camp gear + food + waterskins), injuries (7), survival, weapons (noise, slots), hirelings (3 launch), roads, landmarks, recipes. | MUST |

---

## 17. Post-Launch

| ID | Requirement | Priority |
|---|---|---|
| POST-001 | Co-op (2-4). | POST |
| POST-002 | Community map editor, Workshop. | POST |
| POST-003 | Bandits / road vulnerability. | POST |
| POST-004 | Named hirelings, skill improvement, travel companions. | POST |
| POST-005 | +3 hirelings (Guide, Cartographer, Healer). | POST |
| POST-006 | +5 disciplines (Ritualist, Swordsman, Wizard, Pathfinder, Scholar). | POST |
| POST-007 | Shields, off-hand pistol, off-hand system. | POST |
| POST-008 | Seasons, weather, variable daylight. | POST |
| POST-009 | Purchased maps. Cartographer hireling maps. | POST |
| POST-010 | Separately instanced dungeons. | POST |
| POST-011 | Map expansion to 400-600 hexes. | POST |
| POST-012 | Console ports. | POST |
| POST-013 | Firefly jar (Alchemist). | POST |
| POST-014 | Cold weather clothes/tents. | POST |

---

*End of Document*
