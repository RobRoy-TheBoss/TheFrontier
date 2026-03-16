# THE FRONTIER
## Game Design Document -- Version 8

**PC | Single Player | Godot 4 (GDScript) | Pure Sandbox**
**March 2026**

> "Chart the unknown. Hold the line. Bring civilization to a land that has never known it."

---

# 1. Vision Statement

***The Frontier*** is a first-person low-fantasy survival exploration sandbox. Across the sea from the civilized Old World lies a resource-rich landmass infested with monsters. No colony has survived more than a season. A chartered trading company has established a fortified beachhead on the eastern coast. You play as a surveyor-adventurer sent inland to chart the unknown, locate resources, and found fortified settlements. There is no main quest. The continent is the quest.

## Core Pillars

| Pillar | Description |
|---|---|
| Exploration First | The unknown drives everything. Discovery is the primary reward. |
| Infrastructure as Progress | Settlements and roads are the progression system. Each creates a local island of safety. |
| The Mercantilist Loop | Raw materials flow coastward. Manufactured goods flow inland. Settlements grow based on resource diversity and export value. |
| Earned Safety | Settlement areas are safe. Gaps are not. Western territory is deadlier. Gear progression trivializes the east. |
| No Hand-Holding | No quest markers, no GPS. Navigate by compass, landmarks, and dead reckoning. Map starts empty and is filled through exploration, surveying, or purchase. |

## The Setting

Low fantasy. Humans only. No known magic in the Old World. An extinct precursor civilization left ruins and Places of Power on the landmass. The monsters may be connected to the precursors. The Old World is 17th-18th century analog: sailing ships, black powder, mechanical clocks. The Company has no narrative presence beyond being your employer.

---

# 2. The Player Character

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
| Cracked Ribs | Blunt trauma, heavy fall, or crushing attack | Increased stamina cost on all actions. Breathing hurts. | Town: doctor sets and binds the ribs |
| Torn Muscle | Overexertion during combat, bad dodge, heavy weapon swing at low health | Increased attack cooldown. Swings are slower, reloads clumsy. | Town: doctor, rest + poultice |
| Bleeding Gash | Claw rake, blade cut, or thorn trap | Ongoing health drain. Leaves a blood trail. | Field: bandage stops the bleeding. Full heal at camp rest. |
| Venom | Bite or sting from venomous creature | Health drain + vision distortion. Gets worse if untreated. | Field: antidote (if you have the right one). Otherwise Town alchemist. |
| Sprained Ankle | Bad landing, uneven terrain at speed, dodge into a rock | Walk and sprint speed reduced. Limping. | Camp: rest + splint. Full recovery at Village+. |
| Gut Sickness | Spoiled food, contaminated water, prolonged temperature excess | General debuffs: reduced stamina regen, nausea (periodic vision wobble), reduced hunger restoration from food. Temperature sensitivity narrowed (cold feels colder, heat feels hotter). | Village+: rest + medicine. Healer hireling can treat at camp. |

## Survival Needs

| Need | Effect When Low | Managed By |
|---|---|---|
| Hunger | Reduced stamina regen, eventual health drain | Hunted game, foraged food, cooked meals, rations, Hunter hireling |
| Thirst | Accelerated fatigue, reduced carry weight | Waterskins (no weight when empty). Stream water must be boiled at a campfire before drinking or risk Gut Sickness. Wells at settlements provide clean water. Alchemist can purify water. |
| Temperature | Hypothermia/heat exhaustion; impaired movement, illness, injury risk. Rain increases cold. Cold weather clothes have weight. | Clothing (cold clothes are heavy), campfire, shelter, seasonal awareness |
| Fatigue | Reduced stamina regen, impaired aim, risk of passing out | Sleep at camp or settlement |
| Encumbrance | Hard carry limit. Over-limit: no sprint, slow walk. | Inventory management; Porter hireling backpack; Warrior discipline |

---

# 4. Combat and Equipment

## Melee

First-person stamina-based. Weapon types: one-handed blades, two-handed blades, blunt. Block and dodge consume stamina. Monsters telegraph attacks. Positioning and timing matter.

## Bows

Silent ranged weapon. Draw speed and aim stability poor without Survivalist discipline. Arrows are purchased weighted items; without Survivalist Arrow Recovery, spent arrows are lost. Bows do not attract nearby monsters.

## Firearms

Pistol, musket. High damage, slow multi-step reload, limited accuracy, aim sway from fatigue. Ammo is weighted. Firearms are loud and attract nearby monsters. Without Artificer Quick Load/Steady Hands, firearms are an opening shot, not a primary weapon. Mineral powder (for ammunition) can only be purchased at shops or crafted by an Artificer.

## Weapon Slots

Player has two weapon slots and can quick-swap with a button press. Pistols and shields are off-hand items. Off-hand options: shield, pistol, or empty (two-handed weapon/bow/musket requires empty off-hand).

## Shields

Off-hand defensive equipment. Blocking with a shield provides superior damage reduction compared to weapon-blocking, at a stamina cost. Shields have 1 rune slot. The Swordsman discipline gains bonuses when using shields or off-hand weapons (see Section 9).

## Rune System

Weapons and armor have rune slots. Runes found throughout the world (ruins, caches, monster drops). Never crafted. Socketing grants powerful, build-defining bonuses.

| Equipment | Rune Slots |
|---|---|
| Heavy Armor (5 pieces) | 3 slots per piece |
| Medium Armor (5 pieces) | 2 slots per piece |
| Light Armor (5 pieces) | 1 slot per piece |
| Two-Handed Melee Weapons | 2 slots |
| One-Handed Melee Weapons | 1 slot |
| Shields (off-hand) | 1 slot |
| Bows | 2 slots |
| Muskets | 2 slots |
| Pistols (main or off-hand) | 1 slot |

**Rune Properties:** Runes have types and rarities. Effect values are random based on a Poisson distribution with a long tail. Higher rarities have higher mean effect values. Ranged weapons cannot have life steal runes.

Weapons and armor are bought at settlements. Runes are found by exploring.

---

# 5. Monsters

- **Area-Based Spawns:** Each hex Area has a spawn table. Difficulty increases east to west.
- **Settlement Safe Zone:** Monsters never spawn or enter the immediate area around settlement buildings.
- **Area Spawn Suppression:** Trading Post ~25%, Village ~50%, Town ~75%, City 100% (fully pacified).
- **Escalating Strangeness:** Eastern = comprehensible. Western = stranger, larger, alien.
- **Fire and Light Behavior:**
  - Most monsters avoid campfires.
  - **Fire-attracted:** River reptiles and brightly colored mountain birds. Players should clear these before camping, or risk night ambush.
  - Some monsters attracted to light (lantern, torch, firefly jar). Some repelled by light.

| Category | Examples | Combat Behavior |
|---|---|---|
| Territorial | Ridge stalkers, oversized wolves, marsh drakes | Patrol, engage on sight |
| Ambush | Burrow lurkers, canopy droppers, fog crawlers | Hidden until close, high burst, vulnerable after |
| Swarm | Scuttle packs, hive borers | Weak solo, dangerous in numbers |
| Heavy | Ironhide grazers, plains striders | Passive until provoked, devastating charges |
| Apex | Deep-west megafauna | Rare, enormous, complex patterns, endgame |

Monsters drop runes, monster materials (trade, alchemy, Wizard reagents), and loot per data tables.

---

# 6. Exploration and Navigation

## Navigation

**The player starts with an empty map.** The map is filled through personal surveying, hireling cartography, or purchased maps.

- **Compass:** Always available. Cardinal direction.
- **Empty Map:** Player starts with a blank map. Explored hexes are filled in.
- **Surveying:** Use surveying tools from high points to fill in map hexes. Naked eye (short), Spyglass (medium, Trading Post+), Theodolite (long, Town+).
- **Purchased Maps:** Village sells 2-hex radius map. Town sells 3-hex radius. City sells 4-hex radius. Maps show biomes, rivers, cliffs, and landmarks.
- **Revealed Hex Bonus:** A hex revealed by any method shows landmarks up to 2 hexes beyond its border without providing additional terrain data.
- **Cartographer Hireling:** Creates maps of hexes explored while active.
- **Player Map Markers:** Player can place custom symbols/pins: fox (good hunting), campsite, portage, rapids, custom notes.
- **No Player Position Dot.** Dead reckoning from landmarks and compass.
- **No Minimap, No GPS, No Waypoints.**

## Landmarks

Landmarks are large, visible geographic features for navigation. Types include: Precursor Towers, Lonely Mountains, Waterfalls, Needle Mountains, Seagull Flocks, Tall Trees, and other distinctive features. Density: approximately 1 landmark per 20-30 Areas. From any high point, the player should be able to see a minimum of 3 landmarks. Deep Water Ports are indicated by Whales and Seagull Flocks.

## Scanning and Journal

The journal auto-populates when the player scans objects. The player actively scans monsters, landmarks, items, and resources to add entries. The journal has sections for creatures, ingredients, precursor sites, landmarks, and freeform notes.

## Resource Discovery

Resources (ore, timber, soil, game) are visually present. Logged to the Area on player proximity. Partial exploration = partial extraction. Surveyor hireling discovers all resources in an Area without manual proximity.

## The World

Handcrafted open map. Interwoven biomes. East-to-west difficulty gradient. Resources by geography.

### Hex Grid and Areas

- **Hexagonal Areas.** All Areas are hexagons.
- **Launch map:** ~600 Areas (30 wide x 20 deep). ~25 Areas per Region. ~25 Regions.
- **Vertical slice prototype:** 1 Region, 4x6 = 24 hexes.
- **Area boundaries** follow natural features (rivers, ridgelines, cliffs) and are invisible to the player as game abstractions, but visible as terrain.

### Area Tags

| Tag | Effect |
|---|---|
| River | Runs along Area edge (between hexes). Area has river access. |
| Ford | River crossing point. Adjacent Area must also have Ford. Road can cross. |
| Rapids | Dangerous river section. Adjacent must also have Rapids. |
| Portage | Required if two non-adjacent neighboring Areas both have River tag. |
| Cliff | Impassable elevation change along Area edge. |
| Mountain | No road can pass through. |
| Mountain Pass | Mountain Area that permits a road. |
| Deep Water Port | Natural harbor. Settlement can export directly. Indicated by whales + seagulls. |

### River and Road Interaction

- A river without a Ford or Portage blocks roads through that Area.
- At Town tier, a settlement on a River Area automatically builds bridges into adjacent Areas.
- This means road networks change over time as settlements grow: a route blocked by a river at Village tier opens up when a Town builds a bridge.

### Movement Timing

| Activity | Time |
|---|---|
| Cross a wild Area | ~3 minutes |
| Cross an empty Area (no monsters) | ~1 minute |
| Fully explore an Area | ~2-3 minutes |
| Cross a Region going west | ~10 minutes |

### Time and Seasons

| Parameter | Value | Notes |
|---|---|---|
| Real-time per in-game day | 30 minutes | Configurable |
| Summer daylight | ~22 minutes | ~18 min usable before needing camp |
| Winter daylight | ~12 minutes | ~10 min usable |
| Days per season | 10 | Configurable |
| Real-time per season | 5 hours | |
| Real-time per year | 20 hours | |
| Areas explored per summer day | 4-6 (safe), 2-3 (dangerous) | |
| Areas explored per winter day | 2-3 (safe), 1-2 (dangerous) | |

All time values configurable in JSON.

### Precursor Sites

~1 per 10 Areas, so roughly 60 sites on launch map. Types randomized per playthrough: some become Places of Power (min 2 per discipline = 14 minimum), rest become non-power ruins (shelter, lore, materials, navigation). Unknown until visited.

---

# 7. Camps, Hirelings, and Settlement Founding

## Player Camps

When the player decides to make camp, the game nudges them toward an appropriate campsite: "You think there may be a good spot to camp north of here." The player walks to the indicated location. On arrival, a 2-second setup cutscene plays showing camp being established. No teleportation.

Camp equipment (carried as inventory items with weight):
- **Tent:** Shelter for sleeping. Cold weather tents are heavier.
- **Campfire:** Warmth, cooking, light, monster deterrent. Some monsters attracted to fire or light.
- **Alchemy Set:** Portable brewing station.

Camps are temporary: packable and movable. No spawn suppression. No trade network. Player can abandon camp via menu (hirelings dismissed, camp items destroyed).

## Light Sources

| Source | Color | Coverage | Monster Interaction |
|---|---|---|---|
| Lantern / Torch | Orange | Medium area | Some attracted, some repelled |
| Campfire | Orange/warm | Large area | Most repelled, river reptiles + mountain birds attracted |
| Dark Vision (Survivalist) | Greyscale | Player vision only | No monster interaction |
| Firefly Jar (Alchemist) | White, full color | Large area | Some attracted, some repelled |

## Hirelings

Hired at settlements via NPC interaction. They stay at your camp (do not travel with you). Hirelings bring their own tents. They never draw aggro, cannot be killed, but will cower/flee when monsters attack camp. Expensive: mid-game afford 1, late-game 2-3.

| Type | Available At | Function |
|---|---|---|
| Porter | Village+ | Drops backpack at camp (container with capacity). Picks up at next camp. At home: talk to transfer to/from home storage. |
| Hunter | Village+ | Automatically brings back food at camp. |
| Guide | Town+ | Points toward nearby POIs from camp. |
| Surveyor | Town+ | Discovers Area resources without manual exploration. **Required for founding settlements.** |
| Cartographer | Town+ | Creates maps of explored Areas. |
| Healer | Town+ | Treats up to Town-tier injuries at camp. |

## Settlement Founding

Founding requires a Surveyor hireling (Village+ hire). The process:

1. **Hire Surveyor** at a Village or higher.
2. **Travel to target Area** with Surveyor at camp.
3. **Make camp.** Game nudges you to the pre-designed settlement site. 2-second setup cutscene.
4. **Direct the Surveyor** to mark out the settlement site.
5. **Wait 1-2 in-game days** (Surveyor works while you can explore nearby Areas, but Surveyor stays at camp).
6. **Surveyor completes marking.**
7. **Return to the Village** where you hired the Surveyor and report to the mayor.
8. **Settlement appears** after the next sleep following your report.

**Risk:** If you die before reporting, the founding is cancelled. The Surveyor returns to the Village. You must repeat the process.

**Founding replaces the flag system entirely.** There are no settlement flags.

---

# 8. Settlements and Economy

## Settlement Tiers

| Tier | Name | Services | Suppression | Resource Exploitation |
|---|---|---|---|---|
| 1 | Trading Post | Basic trade, sleep/eat | ~25% | Own Area only |
| 2 | Village | Consumables, Porter/Hunter hire, Surveyor hire, buy home, sell maps (2-hex radius) | ~50% | Own + adjacent at 50% |
| 3 | Town | Doctor, alchemist, uncommon goods, Guide/Cartographer/Healer hire, home, sell maps (3-hex), auto-bridge on River Areas | ~75% | Own + adjacent at 100% |
| 4 | City | Top-tier Old World goods, discipline enhancement, sell maps (4-hex), all services | 100% | Own + adjacent at 100%, ring-2 at 25% |

Crestport starts as a Village in a Deep Water Port Area (providing initial access to Surveyor hirelings for founding).
All tiers have an inner safe zone where monsters never enter.
Settlements on River Areas automatically build bridges into adjacent Areas at Town tier.

## Per-Settlement Growth

Growth is per-node. Each settlement accumulates its own trade score:

| Factor | Effect |
|---|---|
| Local resource output | Area's discovered resources (and exploited adjacent Areas per tier). This is the primary growth driver. |
| Pass-through traffic | Other settlements routing trade through this node to a port. Secondary bonus. |
| Resource diversity | More distinct types flowing through = multiplier |
| Connection count | More roads = more throughput |

### Trade Route Consumption

Each settlement consumes a percentage of raw materials flowing through it toward a port. This consumption is a consequence of settlement size -- larger settlements have larger populations that consume more resources in transit.

| Tier | Consumption Rate | Effect |
|---|---|---|
| Trading Post | ~5% | Negligible. Almost everything passes through. |
| Village | ~15% | Noticeable reduction to downstream flow. |
| Town | ~30% | Significant. Settlements beyond a Town grow slower. |
| City | ~50% | Massive. A City is a gravity well. Very little passes through to nodes beyond it. |

Consumption applies to raw materials flowing coastward only. Manufactured goods flow freely inland (gear availability is based on global export value, not reduced by intermediary settlements).

What arrives at the port after all consumption along the route determines that source's contribution to global export value. Settlements with high pass-through consumption grow partly from what they consume, but local production is the primary driver.

**First-mover advantage:** At a junction, whichever settlement grows first starts consuming more, starving competitors at the same junction. Founding order at strategic locations matters.

### Exponential Tier Thresholds

Tier advancement requires trade score exceeding exponentially increasing thresholds:

| Tier | Score Threshold | Resource Requirements | Practical Meaning |
|---|---|---|---|
| Trading Post | 0 | Founded | Automatic on founding. |
| Village | 100 | Food + timber | Easy. Most settlements reach this. |
| Town | 500 | Food + timber + iron | Moderate. Requires good location, diverse resources, trade connections. |
| City | 5,000 | Food + timber + iron + one additional | Very hard. Only the highest-throughput nodes with sustained trade over a long period. |

The 10x jump from Town to City means Cities are rare by design. The consumption model means a City actively suppresses nearby nodes from also reaching City, because it eats their throughput. 

### Expected Settlement Distribution (Mature Map)

| Tier | Expected Count | Where |
|---|---|---|
| Trading Post | 50+ | Everywhere you founded them |
| Village | 30-40 | Anywhere with food + timber access |
| Town | 10-15 | Good locations with iron + strong trade flow |
| City | 2-5 | Exceptional chokepoints: major portages, river junctions, Deep Water Ports, rare western resource concentrations |

**East vs. West dynamics:** Eastern settlements benefit from more connections, more pass-through, and earlier founding. The east will have more Towns. But western Areas have rarer, more valuable resources (gold, exotic furs, rare minerals). A western settlement at a gold-rich portage can hit City on the strength of its enormous local production even with fewer connections. Eastern settlements have more nodes but a smaller share of the total value pie. The map designer's resource placement is the primary lever for where Cities emerge.

Thresholds and consumption rates are all configurable in JSON.

## Roads

Roads are built automatically by settlements using a budget system:

- **Budget:** Every settlement gets 9 road budget regardless of tier.
- **Cost:** Each road costs budget equal to its hex distance (a 3-hex road costs 3 budget).
- **Evaluation timing:** A settlement evaluates and places roads when it is founded (initial placement) and again each time it tiers up. Roads are NOT re-evaluated every sleep.
- **Targeting:** On evaluation, the settlement sorts all reachable settlements (within 9 hex, no impassable terrain blocking) by trade score descending. It connects to the highest-scoring target it can afford, then the next, until budget is exhausted.
- **One-directional cost:** Only the initiating settlement spends budget. The target gets the connection for free.
- **Persistence:** Old roads from previous evaluations persist even if they wouldn't be chosen again. Roads are never deleted. New roads from a tier-up are placed in addition to existing roads (using any remaining or newly available budget).
- **Road quality:** Scales with the minimum tier of the connected pair (trail/game trail/dirt/cobblestone).

**Road Constraints:**
- Roads cannot pass through River Areas unless there is a Ford, or the settlement on the River Area is Town+ (bridge).
- Roads cannot pass through Mountain Areas unless they have a Mountain Pass tag.
- Maximum single road length: 9 hexes.
- Road quality upgrades automatically as either endpoint grows.

**Emergent behavior:** A settlement founded in a gap between two established nodes may spend its own budget connecting to both, creating a shortcut that reroutes trade through itself on the next sleep. But established neighbors won't connect back to the new settlement until they tier up and re-evaluate. Some settlements will be well-connected hubs; others will be "forgotten" nodes with only their own outgoing roads. Founding timing relative to neighbor tier-ups matters.

## Deep Water Ports

Some Areas have the Deep Water Port tag (indicated by whales and seagull flocks). Settlements there export directly. Trade routes to nearest connected port (shortest path). New ports redirect trade, potentially stagnating inland nodes. Settlements never tier down.

## Export Value

Global counter: total luxury/export goods reaching any port **after consumption along the route**. A gold mine producing 100 value that routes through a City (50% consumption) and a Village (15%) delivers only ~42 to the port. Settlements along the route consumed the rest. This determines Old World goods quality.

| Export Value | Goods Available |
|---|---|
| Low | Basic tools, compass, simple weapons, arrows |
| Moderate | Spyglass, steel weapons, basic medicine, bow upgrades |
| High | Firearms, ammunition, advanced medicine, theodolite |
| Very High | Top-tier weapons/armor, fortification materials, books |

Money buys what's available. Export value determines what's available.

## Player Homes

Village+. Personal storage (infinite, shared across all owned homes), alchemy workshop, free bed. Porter at home: transfer to/from home storage via conversation.

---

# 9. Places of Power and Disciplines

## Precursor Randomization

~60 precursor sites on launch map (~1 per 10 Areas). On new game: 18+ become Places of Power (min 2 per discipline), rest become ruins. Types randomized (seed in save). Unknown until visited.

## Attunement and Progression

9 disciplines. Max 3 attunements (permanent, no respec). 84 possible builds.

- **Attunement:** Visit a Place of Power, attune, receive Ability 1.
- **Discipline XP:** Earned passively through use. Each discipline has specific XP triggers.
- **Enhancement:** Visit a City, spend XP + small currency cost to unlock next ability in sequence.
- **Deeper Places of Power:** Second site of same discipline grants bonus XP or capstone unlock.

### Survivalist (8 abilities)
*Wilderness self-sufficiency and bow mastery.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Trapper | A | Place snare traps. Check after sleep for food. |
| 2 | Arrow Recovery | P | Recover % of fired arrows after combat. |
| 3 | Night Eyes | A | Toggleable greyscale dark vision. Stamina drain. |
| 4 | Light Foot | P | Reduced monster detection range. Stealth bow shots deal bonus damage. |
| 5 | Steady Draw | P | Faster bow draw, reduced sway, held draw drains less stamina. |
| 6 | Weatherskin | P | Temperature thresholds widened. Cold/heat affect you less. |
| 7 | Endurance | P | Stamina +25%. Fatigue penalty halved. |
| 8 | Ghost Walk | A | 10s full stealth. Long cooldown. Breaks on attack. |

### Ritualist (7 abilities)
*Precursor channeler. Everything is a circle or a channel that manipulates space and objects. Ward excludes. Decoy attracts. Banishment Circle removes. Sending Chest teleports loot. Anchor teleports you. All rituals 5-second channel.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Ward | A | 5s channel. 10-foot ward circle at target. Monsters cannot enter. 60s duration. 15s cooldown. |
| 2 | Preserve | P | All decay rates reduced. Food spoils slower, weapon/armor durability degrades slower, potion potency lasts longer in inventory. |
| 3 | Decoy | A | 5s channel. Place a ritual circle. After 10 seconds, an illusionary decoy appears and makes noise, attracting nearby monsters to the circle. Use to pull monsters out of your path, bait them into a Banishment Circle, or draw them away from camp. |
| 4 | Enchant | A | 5s channel. Infuse your equipped weapon with precursor energy. +damage and a visual glow for 60s. Stacks with runes. |
| 5 | Sending Chest | A | 5s channel. Conjure a magical chest. Place items inside. On closing, contents teleport to home storage. One use per rest. |
| 6 | Banishment Circle | A | 5s channel. Place a circle trap on the ground. First non-Apex monster to step inside is instantly despawned. Persists until triggered or next rest. |
| 7 | Anchor | A | Two-part. 5s set anchor. 5s teleport to anchor from anywhere. One-way, one-use. |

### Pathfinder (6 abilities)
*You read the land better than anyone. Travel lighter, recover faster, find what others need hirelings to locate. The discipline for players who want to push deep into the unknown on a budget.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Wayfinder | P | Surveying tools reveal hexes at increased range (~+50%). You read terrain faster and further. |
| 2 | Light Provisions | P | Food and water items weigh 50% less. You pack efficiently and waste nothing. |
| 3 | Cartography | A | At camp, produce a map of all hexes entered since last rest. Replicates Cartographer hireling function. |
| 4 | Prospect | A | Activates a sense that directs you toward the closest undiscovered resource in the current Area. You feel where the land is richest. |
| 5 | Steady Pace | P | Stamina regeneration rate increased (+30%). You just keep going. Where Warrior has burst stamina (larger pool), Pathfinder has endurance (faster recovery). |
| 6 | Pathsense | P | Precursor ruins and Places of Power within a moderate radius appear as a faint shimmer on the horizon from high ground. You feel the old roads. |

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

### Swordsman (8 abilities)
*Precision and finesse. Exploit openings, cripple through technique. Master of the blade on both sides -- you know how to make cuts that bleed and how to avoid them. Gains bonuses with shields and off-hand weapons.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Riposte | A | Dodge during attack window = 2x damage counter. |
| 2 | Cripple | P | Ripostes apply cripple debuff (speed/attack disable, 15s). |
| 3 | Read | P | Enhanced telegraphs. Widened dodge window. |
| 4 | Off-Hand Mastery | P | Bonuses when using shield (increased block reduction, faster block recovery) or off-hand pistol (reduced swap time, aim bonus after melee combo). |
| 5 | Bleed | P | Crits (ripostes, backstabs) apply bleed DOT. Stacks 3x. Bleeds applied by the Swordsman are more severe and last longer than baseline. |
| 6 | Blade Sense | P | Reduced probability of suffering Bleeding Gash and Deep Wound injuries. You understand edge weapons and know how to roll with a cut. |
| 7 | Flurry | A | Post-riposte 3-strike chain. High burst. Heavy stamina. |
| 8 | Deathmark | P | 3+ cripples in one fight = target takes 30% more from all sources. |

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
| 5 | Master Brewer | A | Advanced recipes (mega-heal, temp immunity, repellent, firefly jar). Requires rare ingredients. |
| 6 | Identify | A | Examine unknown materials. Learn properties. Unlock experimental recipes. |

**Firefly Jar:** Alchemist-crafted light source. White light, full color, large area. Alternative to orange lantern/torch light. Some monsters react differently to different light colors.

### Scholar (6 abilities)
*You study the precursors where others merely use their power. Ruins become shelter, sustenance, and a library. The deeper you go, the more the continent gives back. Where the Ritualist channels precursor energy, you understand it.*

| # | Name | P/A | Description |
|---|---|---|---|
| 1 | Runic Literacy | P | Precursor inscriptions become readable. They reveal hints about site layout, hazards, and contents. Others see gibberish. |
| 2 | Salvage | P | Increased yield from precursor sites. You recognize valuable materials others overlook. Ruin loot tables improved. |
| 3 | Shelter | P | Sleeping in a precursor ruin counts as settlement-tier rest (Village equivalent). Injuries treatable, full fatigue recovery, weather protection. Ruins become your camps. |
| 4 | Glyph Ward | A | Activate dormant precursor glyphs found in ruins. Creates a large safe zone (bigger than Ritualist Ward, longer duration, but fixed to glyph location). Only works at precursor sites. |
| 5 | Deep Reading | A | Study a precursor artifact to reveal the locations of related precursor sites on your map. Connecting the network. |
| 6 | Reactivate | A | Restore a dormant precursor sustenance system found in larger ruins. While active, fully restores hunger and thirst when used. Persists across visits. Limited number of charges before the system depletes permanently. |

*XP earned by: reading inscriptions, studying artifacts, sleeping in ruins, reactivating systems, looting precursor materials.*

*The Scholar's progression arc: early you can read inscriptions and get better loot from ruins. Mid game, ruins become viable rest stops (Shelter) and you can lock down sections with Glyph Ward. Late game, Deep Reading maps the entire precursor network and Reactivate turns major ruins into supply depots. A Scholar who has mapped and activated several ruins across the continent has a personal infrastructure network that doesn't require settlements, roads, or hirelings. Scholar + Ritualist is the precursor master: one understands, the other channels. Scholar + Pathfinder covers the continent fast and lives off ruins entirely.*

### Wizard (6 abilities)
*Reagent-consuming combat magic. 1-2s casts. Each spell needs a specific material.*

| # | Name | Cast | Reagent | Description |
|---|---|---|---|---|
| 1 | Firebolt | 1s | Fire herb | Moderate fire damage + burn DOT. |
| 2 | Frost Snap | 1s | Crystal shard | Root 5s. No damage. |
| 3 | Force Push | Instant | Mineral powder | Cone knockback/stagger. |
| 4 | Lightning Arc | 1.5s | Charged filament | Chain 3 targets. High damage. |
| 5 | Stone Shield | 1s | Mineral powder x2 | Absorb barrier ~15s. |
| 6 | Ruin | 2s | Precursor core fragment | Massive single-target damage. |

Reagent tiers: Common (fire herb, mineral powder -- buyable Town+), Uncommon (crystal shard, charged filament -- occasional at Cities, mainly found), Rare (core fragment -- Cities but very expensive, found via exploration). Mineral powder can only be purchased or crafted by Artificer.

---

# 10. Alchemy and Cooking

- **Cooking:** Campfire cooking restores hunger + buffs. Raw food = illness risk. Settlement meals superior.
- **Gathering:** Plants from the world. Alchemist sees hidden nodes.
- **Field Alchemy:** Portable set at camp or home workshop.
- **Settlement Alchemy:** Town alchemists sell and brew advanced recipes.
- **Monster Ingredients:** Some potions and Wizard reagents use monster parts.
- **Recipes:** Known, discovered (scanning + Identify), or learned. All in data.

---

# 11. Seasons

| Season | Daylight | Exploration | Economy | Monsters |
|---|---|---|---|---|
| Spring | ~17 min | Floods, mud | Planting, construction | Aggressive (breeding) |
| Summer | ~22 min | Best travel, heat risk | Peak trade, settlers | Most active |
| Autumn | ~17 min | Passes closing | Harvest, stocking | Migration |
| Winter | ~12 min | Cold, short days | Trade slows, stores consumed | Many dormant; some descend |

Rain increases cold level. Temperature excess causes illness.

---

# 12. Progression Arc

**Early:** Crestport (Village). Empty map. Compass. Explore nearby Areas, scan everything. Hire a Surveyor, found your first Trading Post. Survive camping in hostile territory. Find a Place of Power.

**Mid:** Several settlements. Roads forming. Villages upgrading. Buy maps at settlements. Unlock abilities 2-4 at Cities. Steel weapons, bows, maybe firearms. Hire a porter. Push west. Commission Cartographer maps.

**Late:** Broad network, multiple ports. Cities in east, Towns pushing west. All 3 attunements with most abilities unlocked. Rune-socketed gear. Deep west apex territory. Game does not end.

---

# 13. Scoping: Launch vs. Post-Launch

| Feature | Launch | Post-Launch |
|---|---|---|
| Players | Single player | Co-op (2-4) |
| Map | ~600 hex Areas, ~25 Regions | Additional maps |
| Map tools | Data-driven internals | Community editor, Workshop |
| Settlements | 4 tiers, auto roads, river bridges | Building variants, settlement attacks |
| Disciplines | 9 (61 abilities) | Additional disciplines |
| Roads | Auto-form, tier-scaled, river/mountain constraints | Bandits |
| Navigation | Empty map, surveying, purchased maps, Cartographer | Player-drawn annotations improvements |
| Modding | JSON data files | Editor tools, documentation |
| Hirelings | 6 types, camp-based, generic | Named hirelings, skill improvement, travel companions |
| Dungeons | Not at launch | Separately instanced dungeons |

---

# 14. Technical Notes

- **Engine:** Godot 4, GDScript.
- **Data:** All definitions in JSON. All time/balance values configurable.
- **Hex Grid:** All Areas are hexagons. Area tags (River, Ford, Rapids, Portage, Cliff, Mountain, Mountain Pass, Deep Water Port) drive road routing and movement.
- **Batch on Sleep:** Founding progress, growth (per-node trade score), trade routing (shortest path to port), road quality, suppression, hireling costs all on sleep.
- **Economy:** Per-settlement trade score (local production is primary driver + pass-through + diversity + connections). Trade route consumption: each node consumes a % of raw materials passing through (TP 5%, Village 15%, Town 30%, City 50%). Manufactured goods flow freely inland. Exponential tier thresholds (Village 100, Town 500, City 5000). First-mover advantage at junctions. Export value = what reaches ports after consumption. All rates/thresholds in JSON.
- **Spawns:** Per-Area tables + east-west scalar. Two-ring: safe zone (always clear) + Area suppression by tier.
- **Precursor Randomization:** ~60 sites, types assigned on new game. Seed in save.
- **Discipline Progression:** Attune = ability 1. XP via use. Spend XP at Cities for abilities 2+.
- **Navigation:** Empty map filled by exploration/surveying/purchase. No position dot. Landmarks visible at distance.
- **Light System:** Lantern (orange), torch (orange), dark vision (greyscale), firefly jar (white). Monsters react to fire and light differently by type.
- **Death:** Respawn at last settlement. Items drop. Camp persists. Previous drops destroyed.
- **Founding:** Surveyor hireling (Village+ hire) + camp at site + 1-2 day wait + report to Village. Crestport starts as Village (enables initial Surveyor hire).
- **Roads:** Budget system (9 per settlement). Cost = hex distance. Targets highest trade-score settlements first. Initiator pays, target gets free connection. Evaluated on founding and tier-up only (not every sleep). Old roads persist on tier-up, never deleted. Quality = min(tier). Blocked by rivers (unless ford/bridge) and mountains (unless pass).
- **Time:** 30 min/day, 10 days/season, all configurable.
- **Save:** Settlements, roads, routing, inventory, journal, attunements + XP + unlocks, injuries, runes (with random effect values), discovered resources/Area, season/day, precursor seed, homes, camps, hirelings, dropped items, map reveal state, player markers. JSON.

---

*End of Document*
