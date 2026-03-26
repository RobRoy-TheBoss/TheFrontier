# THE FRONTIER
## Game Design Document -- Version 0.7.0

**PC | Single Player | Godot 4 (GDScript) | Pure Sandbox**
**March 2026**

> "Chart the unknown. Hold the line. Bring civilization to a land that has never known it."

---

# 1. Vision Statement

***The Frontier*** is a third-person low-fantasy survival exploration sandbox. Across the sea from the civilized Old World lies a resource-rich landmass infested with monsters. No colony has survived more than a season. A chartered trading company has established a fortified beachhead on the eastern coast. You play as a surveyor-adventurer sent inland to chart the unknown, locate resources, and found fortified settlements. There is no main quest. The continent is the quest.

## Core Pillars

| Pillar | Description |
|---|---|
| Exploration First | The unknown drives everything. Discovery is the primary reward. |
| Infrastructure as Progress | Settlements and roads are the progression system. Each creates a local island of safety. |
| The Mercantilist Loop | Raw materials flow coastward. Manufactured goods flow inland. Settlements grow based on resource diversity and export value. |
| Earned Safety | Settlement areas are safe. Gaps are not. Western territory is deadlier. Gear progression trivializes the east. |
| No Hand-Holding | No quest markers, no GPS. Navigate by compass, landmarks, and dead reckoning. Map starts empty and is filled through exploration, surveying, or purchase. |

## The Setting

Low fantasy. Humans only. No known magic in the Old World. An extinct precursor civilization left ruins and Places of Power on the landmass. The monsters may be connected to the precursors. The Old World is 17th-18th century analog: sailing ships, black powder, mechanical clocks.

---

# 2. The Player Character

Third-person camera (over-the-shoulder, adjustable distance). The player character is visible at all times -- armor, weapons, runes glowing, enchant effects all readable. Character model required.

- **Surveyor:** Chart terrain, identify resources, mark locations. Compass and journal are primary tools.
- **Adventurer:** Navigate dangerous terrain, survive weather, carry what you can.
- **Fighter:** Monsters range from trivial game animals to terrifying apex predators. You read the situation.
- **Manager:** Decide where settlements go and how they connect. Company handles staffing.

## Death and Respawn

At zero health: respawn at last settlement rested at. All items dropped at death location. Camp and hirelings persist. Previous death drops are destroyed (only the latest drop bag exists). Founding-in-progress is cancelled if the player has not yet reported back.

---

# 3. Health, Stamina, and Injury

## Health and Stamina

Numeric Health and Stamina pools (HUD bars). Health lost to attacks, falls, hazards; regenerates slowly, faster at rest. Stamina consumed by sprint, attack, dodge, block; regenerates when idle. When health is below a threshold, each hit risks inflicting an Injury.

## Injury System

| Injury | Cause | Effect | Treatment |
|---|---|---|---|
| Deep Wound | Severe slash or puncture at low health | Max health pool reduced until healed | City: long rest with a surgeon |
| Cracked Ribs | Blunt trauma, heavy fall, or crushing attack | Increased stamina cost on all actions | Town: doctor |
| Torn Muscle | Overexertion during combat, bad dodge | Increased attack cooldown | Town: doctor |
| Bleeding Gash | Claw rake, blade cut, or thorn trap | Ongoing health drain | Field: bandage. Full heal at camp rest. |
| Venom | Bite or sting from venomous creature | Health drain + vision distortion | Field: antidote. Otherwise Town alchemist. |
| Sprained Ankle | Bad landing, uneven terrain at speed | Walk and sprint speed reduced | Camp: rest + splint. Full recovery at Village+. |
| Gut Sickness | Spoiled food, unboiled water, temperature excess | Reduced stamina regen, nausea, reduced food restoration, narrowed temperature sensitivity | Village+: rest + medicine. Healer hireling can treat at camp. |

## Survival Needs

| Need | Effect When Low | Managed By |
|---|---|---|
| Hunger | Reduced stamina regen, eventual health drain | Rations (purchased, best: half-day stamina regen + carry buff), cooked meat/fish (campfire), foraged berries (safe but minimal), Hunter hireling |
| Thirst | Accelerated fatigue, reduced carry weight | Waterskins (no weight empty). Stream water must be boiled at campfire or risk Gut Sickness. Settlement wells clean. Alchemist can purify. |
| Temperature | Movement debuffs, Gut Sickness risk. Rain increases cold. | Clothing (cold clothes heavy), campfire, shelter, seasonal awareness |
| Fatigue | Reduced stamina regen, impaired aim, pass-out risk | Sleep at camp or settlement |
| Encumbrance | Hard limit. Over = no sprint, slow walk. | Inventory management; Porter backpack; Warrior discipline |

---

# 4. Combat and Equipment

## Camera

Third-person over-the-shoulder. Adjustable zoom. Camera collides with terrain. Zooms to closer over-shoulder during aiming (bow/firearm).

## Melee

Third-person stamina-based. Weapon types: one-handed blades, two-handed blades, blunt. Block (weapon-blocking) and dodge-roll consume stamina. Monsters telegraph attacks. Dodge rolls are visible and readable. Positioning and timing matter.

## Bows

Silent ranged weapon. Over-shoulder aim. Draw speed and aim stability poor without Survivalist discipline. Arrows are purchased weighted items; without Survivalist Arrow Recovery, spent arrows are lost. Bows do not attract nearby monsters.

## Firearms

Pistol, musket. High damage, slow multi-step reload, limited accuracy, aim sway from fatigue. Ammo is weighted. Firearms are loud and attract nearby monsters. Without Artificer Quick Load/Steady Hands, firearms are an opening shot, not a primary weapon. Mineral powder (for ammunition) can only be purchased at shops or crafted by an Artificer.

## Weapon Slots

Player has two weapon slots and can quick-swap with a button press. No off-hand system at launch (shields and off-hand pistols are post-launch).

## Rune System

Weapons and armor have rune slots. Runes found throughout the world (ruins, caches, monster drops). Never crafted. Socketing grants powerful, build-defining bonuses. Rune effects visible on character model (glow, particle effects).

| Equipment | Rune Slots |
|---|---|
| Heavy Armor (5 pieces) | 3 slots per piece |
| Medium Armor (5 pieces) | 2 slots per piece |
| Light Armor (5 pieces) | 1 slot per piece |
| Two-Handed Melee Weapons | 2 slots |
| One-Handed Melee Weapons | 1 slot |
| Bows | 2 slots |
| Muskets | 2 slots |
| Pistols | 1 slot |

**Rune Properties:** Runes have types and rarities. Effect values are random based on a Poisson distribution with a long tail. Higher rarities have higher mean effect values. Ranged weapons cannot have life steal runes.

## Field Tools

| Tool | Weight | Function |
|---|---|---|
| Axe | Moderate | Chop trees for wood. Wood is heavy. Required for building campfire kit. |
| Pickaxe | Moderate | Mine ore deposits (iron, minerals, crystal). |
| Fishing Rod | Light (lighter than bow) | Catch fish at rivers/streams. Food source alternative to hunting. |

---

# 5. Monsters

- **Area-Based Spawns:** Each hex Area has a spawn table. Difficulty increases east to west.
- **Settlement Safe Zone:** Monsters never spawn or enter the immediate area around settlement buildings.
- **Area Spawn Suppression:** Trading Post ~25%, Village ~50%, Town ~75%, City 100% (fully pacified).
- **Escalating Strangeness:** Eastern = comprehensible. Western = stranger, larger, alien.
- **Fire and Light Behavior:**
  - Most monsters avoid campfires.
  - **Fire-attracted:** River reptiles and brightly colored mountain birds. Clear these before camping or risk night ambush.
  - Some monsters attracted to light, some repelled. Per-type in JSON.

| Category | Examples | Combat Behavior |
|---|---|---|
| Territorial | Ridge stalkers, oversized wolves, marsh drakes | Patrol, engage on sight |
| Ambush | Burrow lurkers, canopy droppers, fog crawlers | Hidden until close, high burst, vulnerable after |
| Swarm | Scuttle packs, hive borers | Weak solo, dangerous in numbers |
| Heavy | Ironhide grazers, plains striders | Passive until provoked, devastating charges |
| Docile | Rabbits, game birds, deer | Flee on detection. Meat source. Require ranged weapon to hunt. |
| Apex | Deep-west megafauna | Rare, enormous, complex patterns, endgame |

Monsters drop runes, monster materials (trade, alchemy, Wizard reagents), and loot per data tables. Docile animals drop meat that must be cooked.

---

# 6. Exploration and Navigation

## Navigation

**The player starts with an empty map.** Filled through surveying, purchased maps, or hireling cartography (post-launch).

- **Compass:** Always available. Cardinal direction.
- **Surveying:** Use surveying tools from high points. Naked eye (short), Spyglass (medium, Trading Post+), Theodolite (long, Town+).
- **Purchased Maps (post-launch):** Village 2-hex radius, Town 3-hex, City 4-hex.
- **Revealed Hex Bonus:** A revealed hex shows landmarks up to 2 hexes beyond without terrain data.
- **Player Map Markers:** Fox (hunting), campsite, portage, rapids, custom.
- **No Player Position Dot.** Dead reckoning only.
- **No Minimap, No GPS, No Waypoints.**

## Landmarks

Large visible geographic features for navigation. Types: Precursor Towers, Lonely Mountains, Waterfalls, Needle Mountains, Seagull Flocks, Tall Trees. Density: ~1 per 20-30 Areas. From high points, 3+ landmarks visible. Deep Water Ports indicated by Whales and Seagull Flocks.

## Scanning and Journal

The player approaches an object and uses a scan interaction (proximity-based, not camera raycast). Scanned monsters, landmarks, items, and resources are added to the journal. Journal has sections for creatures, ingredients, precursor sites, landmarks, and freeform notes.

## Resource Discovery

Resources (ore, timber, soil, game) are visually present. Logged to the Area on player proximity. Partial exploration = partial extraction. Surveyor hireling discovers all resources in an Area without manual proximity.

## The World

Handcrafted open map built from modular hex templates. Interwoven biomes. East-to-west difficulty gradient. Resources by geography.

### Hex Grid and Areas

- **Hexagonal Areas.** All Areas are hexagons.
- **Launch map:** 200-300 Areas. Exact dimensions TBD based on template library size.
- **Horizontal slice prototype:** 1 Region, 6 wide x 4 deep = 24 hexes.
- **Area boundaries** follow natural features and are invisible to the player.

### Modular Hex Templates

The map is assembled from a library of reusable hex templates. Each template is a pre-built terrain chunk for a specific biome type (forest clearing, river valley, mountain ridge, coastal bluff, plains, swamp, etc.). Templates include terrain mesh, vegetation, resource placement zones, spawn point markers, and a settlement site.

To build the map: place templates on the hex grid, hand-tweak connections between adjacent hexes (blending terrain at edges), customize unique features (precursor sites, landmarks, boss arenas), and assign per-hex data (resource tags, difficulty, tags). Target: 15-20 templates per biome, 80% template coverage, 20% hand-customized. AI-assisted template generation is an explicit part of the production plan.

### Area Tags

| Tag | Effect |
|---|---|
| River | Runs along Area edge (between hexes). |
| Ford | River crossing point. Adjacent must also have Ford. Road can cross. |
| Rapids | Dangerous river section. Adjacent must also have Rapids. |
| Portage | Required if two non-adjacent neighbors both have River tag. |
| Cliff | Impassable elevation change along Area edge. |
| Mountain | No road can pass through. |
| Mountain Pass | Mountain Area that permits a road. |
| Deep Water Port | Natural harbor. Indicated by whales + seagulls. |

### River and Road Interaction

- A river without a Ford or Portage blocks roads through that Area.
- At Town tier, a settlement on a River Area automatically builds bridges.
- Road networks change over time as settlements grow.

### Movement Timing

| Activity | Time |
|---|---|
| Cross a wild Area | ~3 minutes |
| Cross an empty Area (no monsters) | ~1 minute |
| Fully explore an Area | ~2-3 minutes |

### Time

| Parameter | Value | Notes |
|---|---|---|
| Real-time per in-game day | 30 minutes | Configurable |
| Days per season | 10 | Configurable |

**Launch:** Day/night cycle with fixed daylight (~17 minutes). No seasons. No weather.
**First major patch:** Seasons (summer ~22 min daylight, winter ~12 min), weather (rain increases cold), seasonal economy effects.

All time values configurable in JSON.

### Precursor Sites

~1 per 10 Areas on launch map. Types randomized per playthrough: some become Places of Power (min 2 per launch discipline = 8 minimum), rest become non-power ruins. Unknown until visited.

---

# 7. Camps, Hirelings, and Settlement Founding

## Player Camps

When the player decides to camp, the game nudges toward an appropriate site: "You think there may be a good spot north of here." Player walks there. 2-second setup cutscene. No teleportation. Player can only pack up camp items while at the campsite.

**One camp at a time.** The player cannot own more than one tent. Settlement shops refuse tent sale if the player has a tent in inventory or an active camp exists. Only after abandoning an existing camp can a new tent be purchased.

**Abandoning camp** destroys all camp items (tent, campfire kit, cooking kit, alchemy set, camp chest) and dismisses all hirelings. If founding is in progress, abandoning camp cancels founding and the Surveyor is teleported to the origin settlement.

### Camp Equipment

All separate weighted inventory items:

| Item | Weight | Source | Function |
|---|---|---|---|
| Tent | Moderate | Purchased (one at a time) | Required to set up camp. Shelter for sleeping. Cold tents heavier (post-launch with seasons). |
| Campfire Kit | Heavy | Built from wood (axe + trees) | Warmth, light, boil water, monster deterrent. Does NOT enable cooking meat. |
| Cooking Kit | Heavy | Purchased | Enables cooking meat/fish at a campfire. Requires campfire kit to be present. |
| Alchemy Set | Heavy | Purchased | Portable brewing station. Requires campfire kit. |
| Camp Chest | Moderate | Purchased | Storage container at camp. Items inside destroyed on abandon. |

**Building a campfire:** Chop trees with axe to get wood (wood is heavy). Use wood to build a campfire kit at your campsite. Campfire kits can also be found or purchased but are heavy to carry.

**Without a campfire:** You can sleep (tent only) but cannot cook, boil water, or get warmth. You're living on berries and rations.

**Without a cooking kit:** You can boil water and get warmth from a campfire, but cannot cook meat or fish.

### Light Sources

| Source | Color | Coverage | Monster Interaction |
|---|---|---|---|
| Campfire | Orange/warm | Large area | Most repelled, river reptiles + mountain birds attracted |
| Lantern / Torch | Orange | Medium area | Some attracted, some repelled |
| Dark Vision (Survivalist) | Greyscale world effect | Player area | No monster interaction |
| Firefly Jar (Alchemist, post-launch) | White, full color | Large area | Some attracted, some repelled |

Camp persists on death. Player can abandon camp via menu (hirelings dismissed, camp items destroyed).

## Hirelings (Launch: 3 types)

Hired at settlements. Stay at camp. Do not travel with player. Bring own tents. Never draw aggro, cannot be killed, cower when attacked. Expensive: mid-game afford 1, late-game 2.

| Type | Available At | Function |
|---|---|---|
| Porter | Village+ | Drops backpack at camp (container with capacity). At home: transfer to/from home storage. |
| Hunter | Village+ | Auto-generates food at camp on sleep. |
| Surveyor | Town+ | Discovers Area resources. **Required for founding settlements.** |

**Post-launch hirelings:** Guide (Town+, POI indicators), Cartographer (Town+, maps), Healer (Town+, camp injuries).

## Settlement Founding

Founding requires a Surveyor hireling (Village+ hire):

1. **Hire Surveyor** at a Village or higher.
2. **Travel to target Area** with Surveyor at camp.
3. **Make camp.** Game nudges to settlement site. 2-second cutscene.
4. **Direct the Surveyor** to mark out the site.
5. **Wait 1-2 in-game days** (Surveyor works, player can explore nearby).
6. **Surveyor completes.**
7. **Return to the Village** and report to the mayor.
8. **Settlement appears** after next sleep following report.

**Risk:** Death before reporting cancels founding. Surveyor returns to Village.

---

# 8. Settlements and Economy

## Settlement Tiers

| Tier | Name | Services | Suppression | Resource Exploitation |
|---|---|---|---|---|
| 1 | Trading Post | Basic trade, sleep/eat | ~25% | Own Area only |
| 2 | Village | Consumables, Porter/Hunter hire, Surveyor hire, buy home | ~50% | Own + adjacent at 50% |
| 3 | Town | Doctor, alchemist, uncommon goods, home, auto-bridge on Rivers | ~75% | Own + adjacent at 100% |
| 4 | City | Top-tier Old World goods, discipline enhancement, all services | 100% | Own + adjacent 100%, ring-2 at 25% |

Crestport starts as a Village in a Deep Water Port Area.
All tiers have an inner safe zone.
Settlements on River Areas auto-build bridges at Town tier.

### Exploitation Overlap

When multiple settlements exploit the same hex, the highest-tier settlement wins exclusive rights. Lower tiers get nothing from that hex. Ties broken by trade score. Dense placement is penalized.

## Per-Settlement Growth

| Factor | Effect |
|---|---|
| Local resource output | Primary driver. Own Area + exploited adjacent per tier. |
| Pass-through traffic | Secondary. Other settlements routing through this node. |
| Resource diversity | More distinct types = multiplier. |
| Connection count | More roads = more throughput. |

### Trade Route Consumption

| Tier | Consumption Rate |
|---|---|
| Trading Post | ~5% |
| Village | ~15% |
| Town | ~30% |
| City | ~50% |

Consumption applies to raw materials flowing coastward only. Manufactured goods flow freely inland. First-mover advantage at junctions.

### Exponential Tier Thresholds

| Tier | Score Threshold | Resource Requirements |
|---|---|---|
| Trading Post | 0 | Founded |
| Village | 100 | Food + timber |
| Town | 500 | Food + timber + iron |
| City | 5,000 | Food + timber + iron + one additional |

Expected mature map: TP 30+, Village 20-30, Town 8-12, City 2-4.

## Roads

Budget system:

- **Budget:** 9 per settlement regardless of tier.
- **Cost:** Hex distance.
- **Evaluation:** On founding and on tier-up only.
- **Targeting:** Sort reachable settlements by trade score descending. Connect to best affordable, then next.
- **One-directional cost:** Initiator pays. Target gets free connection.
- **Persistence:** Old roads never deleted. New roads added on re-evaluation.
- **Quality:** Min tier of pair (trail/game trail/dirt/cobblestone).

**Constraints:** Rivers block unless Ford or Town+ bridge. Mountains block unless Pass. Max 9 hexes.

## Deep Water Ports

Settlements export directly. Trade routes to nearest port (shortest path). New ports redirect trade.

## Export Value

Global counter: luxury goods reaching any port after consumption. Determines Old World goods available.

| Export Value | Goods Available |
|---|---|
| Low | Basic tools, compass, simple weapons, arrows |
| Moderate | Spyglass, steel weapons, basic medicine |
| High | Firearms, ammunition, advanced medicine, theodolite |
| Very High | Top-tier weapons/armor, fortification materials |

## Player Homes

Village+. Infinite storage shared across all homes. Alchemy workshop. Free bed. Porter transfer at home.

---

# 9. Places of Power and Disciplines

## Precursor Randomization

Precursor sites on launch map (~1 per 10 Areas). On new game: 8+ become Places of Power (min 2 per launch discipline), rest become ruins. Seed in save.

## Attunement and Progression

**Launch: 4 disciplines.** Max 3 attunements (permanent, no respec). 4 possible builds at launch.

- **Attunement:** Visit Place of Power, attune, receive Ability 1.
- **Discipline XP:** Earned through use.
- **Enhancement:** Visit a City, spend XP + currency to unlock next ability.

### Survivalist (8 abilities)
*Wilderness self-sufficiency and bow mastery.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Field Dressing | P | Butchering docile animals yields significantly more meat. |
| 2 | Arrow Recovery | P | Recover % of fired arrows after combat. |
| 3 | Night Eyes | A | Toggleable dark vision. Greyscale world effect. Stamina drain. |
| 4 | Light Foot | P | Reduced monster detection range. Stealth bow shots deal bonus damage. |
| 5 | Steady Draw | P | Faster bow draw, reduced sway, held draw drains less stamina. |
| 6 | Weatherskin | P | Temperature thresholds widened. |
| 7 | Endurance | P | Stamina +25%. Fatigue penalty halved. |
| 8 | Ghost Walk | A | 10s full stealth. Long cooldown. Breaks on attack. |

### Warrior (6 abilities)
*Direct combat power and physical resilience.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Heavy Hand | P | Melee damage +20%. |
| 2 | Pack Mule | P | Carry weight +30%. Reduced over-encumbrance penalty. |
| 3 | Ironclad | P | Heavy armor equippable. All armor DR increased. |
| 4 | Stagger | A | Charged heavy attack. Staggers non-Apex. High stamina. |
| 5 | Second Wind | A | Below 25% HP: instant 30% stamina + 8s damage resist. Once per rest. |
| 6 | Warcry | A | 15m AoE flinch on non-Apex. Moderate cooldown. |

### Artificer (8 abilities)
*Mobile blacksmith and master gunman.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Field Repair | A | Repair weapons/armor at camp with raw materials. |
| 2 | Quick Load | P | Firearm reload -30%. |
| 3 | Ammo Smith | A | Craft bullets/powder at camp from iron + mineral powder. |
| 4 | Spike Trap | A | Craft/place from iron+wood. Significant damage. Recoverable. |
| 5 | Steady Hands | P | Aim sway from fatigue -50%. Range accuracy improved. |
| 6 | Reinforce | A | Temp boost weapon/armor until next sleep. Consumes materials. |
| 7 | Jury Rig | A | Emergency repair without materials. ~10 uses. |
| 8 | Mechanical Insight | P | Activate precursor mechanisms. Open locked chambers. Disassemble artifacts. Craft mineral powder. |

### Alchemist (6 abilities)
*Botanical mastery. See what others miss, brew what others cannot.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Keen Eye | P | Hidden gathering nodes visible. Rare ingredients. |
| 2 | Light Load | P | Plants and potions weigh 50% less. |
| 3 | Extended Potency | P | Potion durations +50%. |
| 4 | Toxicologist | P | Poison/venom 50% less effective. Poisoning injuries downgraded one tier. |
| 5 | Master Brewer | A | Advanced recipes (mega-heal, temp immunity, repellent). Rare ingredients. |
| 6 | Identify | A | Examine unknown materials. Learn properties. Unlock recipes. |

### Post-Launch Disciplines (5)

| Discipline | Category | Identity |
|---|---|---|
| Ritualist | Logistics | Spatial manipulation: wards, decoy, banishment circle, enchant, sending chest, preserve, anchor |
| Swordsman | Combat | Riposte, cripple, bleed, blade sense, off-hand mastery, flurry, deathmark |
| Wizard | Combat | Reagent-consuming combat spells (firebolt, frost snap, force push, lightning arc, stone shield, ruin) |
| Pathfinder | Exploration | Extended surveying, cartography, prospect, light provisions, steady pace, pathsense |
| Scholar | Exploration | Runic literacy, salvage, shelter in ruins, glyph ward, deep reading, reactivate sustenance |

Post-launch disciplines bring total to 9 disciplines, 61 abilities, 84 possible builds (still max 3 attunements).

---

# 10. Food, Alchemy, and Cooking

## Food Hierarchy

| Source | How | Hunger Restore | Buff | Spoil Time | Notes |
|---|---|---|---|---|---|
| Berries | Forage (no tool) | Minimal | None | Long | Safe raw. Supplements, doesn't sustain. |
| Fish | Fishing rod at water | Good (cooked) | None | ~2 days | Must cook. Fishing rod lighter than bow. |
| Small Game Meat | Kill rabbit/bird (ranged weapon), butcher at corpse | Good (cooked) | None | ~2 days | Must cook. Butchering takes time. |
| Rations | Purchase at settlement | Best | Half-day stamina regen + carry capacity buff | Long | Premium exploration fuel. Costs money. |
| Hunter Hireling | Auto at camp on sleep | Good | None | N/A | Eliminates need to hunt. Costs gold/day. |
| Settlement Meals | Eat at Village+ | Best | Superior buffs | N/A | Only at settlements. |

**Design intent:** Half a day of foraging/hunting yields ~1 day of food. Cooked meat lasts ~2 in-game days. Rations are the optimal choice for pushing deep. Running out forces you to slow down and hunt, costing daylight.

**Ration buff stacking:** Eating a new ration resets the buff timer. Buffs do not stack. One ration = one half-day buff period.

**Fishing:** 1-second interaction with animation at a water body. Requires fishing rod. Yields 1 fish. Interruptible by damage (animation cancels, no fish).

**Butchering:** 1-second interaction with animation at a docile animal corpse. Yields base meat (more with Survivalist Field Dressing). Interruptible by damage (animation cancels, no meat).

**Raw meat** risks Gut Sickness. **Unboiled water** risks Gut Sickness.

**Cooking requires:** Campfire kit (built from wood via axe) + Cooking kit (purchased). Without both, you cannot cook.

## Alchemy

- **Gathering:** Plants from the world. Alchemist sees hidden nodes.
- **Field Alchemy:** Alchemy set at camp (requires campfire kit).
- **Settlement Alchemy:** Town alchemists sell and brew.
- **Monster Ingredients:** Some potions use monster parts.
- **Recipes:** All in JSON data.

---

# 11. Progression Arc

**Early:** Crestport (Village). Empty map. Compass. Explore nearby Areas, scan everything. Chop trees, build campfire, hunt rabbits. Hire a Surveyor, found your first Trading Post. Find a Place of Power.

**Mid:** Several settlements. Roads forming. Villages upgrading. Unlock abilities 2-4 at Cities. Better weapons, bows, maybe firearms. Hire a porter. Push west.

**Late:** Broad network, multiple ports. Cities emerging at chokepoints. All 3 attunements with most abilities unlocked. Rune-socketed gear. Deep west apex territory. Game does not end.

---

# 12. Scoping: Launch vs. Post-Launch

| Feature | Launch | Post-Launch |
|---|---|---|
| Perspective | Third-person | -- |
| Players | Single player | Co-op (2-4) |
| Map | 200-300 hex Areas, modular templates | Expand to 400-600 |
| Map tools | Data-driven, template library | Community editor, Workshop |
| Settlements | 4 tiers, auto roads, river bridges | Building variants, settlement attacks |
| Disciplines | 4 (28 abilities) | +5 more (total 9, 61 abilities) |
| Combat | Melee (1h/2h/blunt), bow, firearms. No off-hand. | Shields, off-hand pistol, off-hand system |
| Roads | Budget system, full constraints | Bandits |
| Navigation | Compass, surveying, empty map, scanning | Purchased maps, Cartographer hireling, player annotations |
| Hirelings | Porter, Hunter, Surveyor | Guide, Cartographer, Healer |
| Time | Day/night cycle, fixed daylight | Seasons, weather, variable daylight |
| Modding | JSON data files | Editor tools, documentation |
| Dungeons | Not at launch | Separately instanced |

---

# 13. Technical Notes

- **Engine:** Godot 4, GDScript. Third-person camera rig.
- **Terrain:** Terrain3D plugin (C++ GDExtension). Modular hex templates assembled into map.
- **Data:** All definitions in JSON. All balance values configurable.
- **Hex Grid:** Axial coordinates. Area tags drive road routing and movement.
- **Batch on Sleep:** Founding, growth, trade routing, road quality, suppression, hireling costs.
- **Economy:** Per-settlement trade score with consumption (5/15/30/50%). Exponential thresholds. Road budget (9, hex distance cost, evaluated on founding/tier-up only).
- **Exploitation Overlap:** Highest tier wins. Ties by trade score.
- **Spawns:** Per-Area tables + east-west scalar. Two-ring suppression.
- **Precursor Randomization:** Sites assigned on new game. Seed in save.
- **Discipline Progression:** Attune = ability 1. XP via use. Spend at Cities.
- **Navigation:** Empty map filled by surveying. No position dot.
- **Light System:** Campfire (orange), lantern (orange), dark vision (greyscale). Monster reactions per type.
- **Death:** Respawn at settlement. Items drop. Camp persists. Previous drops destroyed.
- **Founding:** Surveyor + camp at site + 1-2 day wait + report to Village.
- **Roads:** Budget system. Initiator pays. Old roads persist. Quality = min(tier).
- **Time:** 30 min/day. Launch: fixed daylight. Post-launch: seasons.
- **Camp:** Tent required. Campfire built from wood (axe). Cooking kit separate. Pack up at site only.
- **Save:** Complete world state. JSON format.

---

*End of Document*
