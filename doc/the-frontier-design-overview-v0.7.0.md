# THE FRONTIER
## Design Overview -- Version 0.7.0

**Third-person low-fantasy survival exploration sandbox**
**PC | Single Player | Godot 4**
**March 2026**

---

## The Premise

A chartered trading company has established a beachhead on the eastern coast of an uncharted continent. Previous colonies failed because the continent is infested with monsters. You play as a surveyor-adventurer sent inland to chart the unknown, locate resources, and decide where civilization takes root. There is no main quest. The continent is the quest.

The Old World is 17th-18th century analog: sailing ships, black powder firearms, mechanical clocks. The continent has ruins from an extinct precursor civilization. Some of those ruins still function. The monsters may be connected to the precursors. No one knows.

---

## The Core Loop

1. **Prepare** at a settlement. Buy rations, repair gear, hire help.
2. **Explore** unknown territory. Navigate by compass and landmarks. Set up camp. Hunt for food or fish in rivers.
3. **Discover** resources, ruins, and places of power.
4. **Found** a settlement by hiring a surveyor, camping at a promising site, and reporting back.
5. **Connect** your settlements with roads. Trade flows. Settlements grow.
6. **Push deeper** west, where the monsters are stranger and the rewards are greater.

Every settlement you establish makes the next expedition possible. Better gear flows inland from the Old World as your trade network grows. The continent transforms behind you from wilderness into civilization, area by area.

---

## The Map

The world is divided into roughly 200-300 hexagonal areas. The map is handcrafted from a library of modular terrain templates, giving each area a distinct feel while keeping production manageable. Biomes interweave rather than forming rigid bands. Difficulty increases east to west.

Rivers run along hex edges and block road construction until a settlement grows large enough to build a bridge. Mountains and cliffs create impassable barriers unless a pass exists. Deep water ports along the coast let settlements export goods directly.

The player starts with a blank map. There is no minimap, no GPS, and no position indicator. You fill in the map by surveying from high ground using tools of increasing range: naked eye, spyglass, and theodolite. Landmarks -- precursor towers, lonely mountains, waterfalls -- are your reference points. You learn the land by walking it.

---

## Settlements and the Economy

The game's progression system is infrastructure, not experience points. You decide where settlements go and how they connect. The company handles the building.

### Founding

To found a settlement, you hire a surveyor at an existing village, travel to a promising location, set up camp, and wait while the surveyor marks out the site. Then you return and report. A trading post appears. If you die before reporting, the founding is lost.

### Growth

Settlements grow through trade, not player construction. Each settlement extracts resources from its surrounding hexes and routes them coastward to a port. Raw materials flow east, manufactured goods flow west. The more valuable the trade flowing through a settlement, the faster it grows.

There are four tiers: Trading Post, Village, Town, and City. Each tier unlocks better services: Villages offer basic shops and hirelings. Towns have doctors, alchemists, and better gear. Cities offer the best equipment and the ability to upgrade your discipline abilities.

The tier thresholds are exponential. Villages are common. Towns take effort. Cities are rare achievements that require excellent placement -- a mature map might have only 2-4. Each one reshapes the economy around it.

### Consumption

This is the system that makes placement strategic. Each settlement consumes a portion of trade passing through it. A Trading Post barely touches the flow. A City eats half of everything. This means a City actively starves settlements beyond it. Founding too many settlements in a line creates diminishing returns. Founding at a junction where multiple routes converge creates a natural economic center.

Where you build, in what order, and how you connect your network determines which settlements thrive and which stagnate. The player who scouts carefully before committing is rewarded. The player who rushes to plant settlements everywhere pays for it later.

### Roads

Settlements automatically build roads toward the most valuable trade partners they can reach. Roads are blocked by rivers (until a town builds a bridge), mountains (unless a pass exists), and cliffs. Road quality improves as the connected settlements grow, and better roads let you travel faster.

---

## Survival and the Wilderness

You can explore indefinitely. Food doesn't stop you from pushing west -- half a day of hunting or fishing yields enough for a full day of travel. What stops you is attrition.

**Injuries accumulate.** Every fight risks injury, and the worst ones -- deep wounds, cracked ribs, venom -- need a Town or City to treat. The further you are from one, the more debuffs you're carrying. A sprained ankle from a bad fall slows you down. A torn muscle makes your attacks sluggish. Stack two or three injuries and you're limping through apex predator territory at half effectiveness.

**Equipment degrades.** Weapons and armor lose durability with use. Without the Artificer discipline, you need a settlement smithy to repair them. A broken sword deep in the west is a death sentence.

**Death is expensive.** When you die, you respawn at the last settlement you rested at -- with nothing. Your gear is in a bag at your death location. Getting back to it means navigating through dangerous territory without a position marker on your map (because there is no position marker), buying replacement gear with whatever gold you have, and fighting through the same monsters that killed you. If you die deep in the west, you might not find your bag again. Your best runes were in that bag.

**Food is a speed control, not a wall.** Foraging berries keeps you alive but barely. Hunting small game or fishing takes time you could spend exploring. Purchased rations are the premium option: best hunger restoration plus a temporary stamina and carry capacity buff. When rations run out, you don't starve -- you slow down. Half your daylight goes to hunting instead of exploring.

**Water** from streams must be boiled at a campfire or you risk illness. Settlement wells are clean.

**Temperature** extremes slow you down or drain your stamina. Sustained exposure risks illness.

**Encumbrance** is a hard limit. Everything has weight: weapons, armor, food, water, tools, camp equipment. Deciding what to carry is a real decision on every expedition.

---

## Camp

Your camp is your forward operating base. Setting one up requires a tent. Beyond that, every addition is a separate piece of heavy equipment you carry:

- A **campfire kit** (built from wood you chop with an axe) provides warmth, light, and the ability to boil water. It also deters most monsters.
- A **cooking kit** lets you cook meat and fish at the campfire.
- An **alchemy set** lets you brew potions.
- A **camp chest** gives you extra storage.

Without a campfire, you can sleep but you can't cook, boil water, or stay warm. Without a cooking kit, you can boil water but can't cook meat. Every item has weight. A fully equipped camp is heavy. A light camp is fast but limited.

You can only have one camp at a time. Abandoning a camp destroys everything in it.

---

## Combat

Third-person, stamina-based. You see your character and the monster simultaneously, making timing readable and fair.

**Melee** weapons come in three types: one-handed blades, two-handed blades, and blunt weapons. You can block with your weapon or dodge-roll out of danger. Monsters telegraph their attacks.

**Bows** are silent. They reward patience and don't attract nearby monsters. Without the Survivalist discipline, bows are inaccurate and slow to draw.

**Firearms** (pistol and musket) hit hard but reload slowly and the sound attracts every monster in the area. Without the Artificer discipline, firearms are an opening shot, not a primary weapon.

**Weapons and armor have rune slots.** Runes are found in ruins, hidden caches, and monster drops. They are never crafted. Each rune's power is randomly rolled, so finding a high-roll rare rune is a significant event. You can see the effects on your character: glowing weapons, enchanted armor.

**Monsters** range from docile game animals (rabbits, birds) that flee on sight, to territorial predators that attack when you enter their range, to ambush hunters that strike from hiding, to apex predators that require endgame gear and careful preparation. Some monsters are attracted to fire. Some are repelled by it. Learning which is which before you camp for the night matters.

---

## Disciplines

Scattered across the continent are precursor Places of Power. Each grants a permanent attunement to a discipline. You choose three over the course of the game. The choices are permanent and define your playstyle. Nine disciplines exist across three categories.

### Exploration

**Survivalist** -- Bow mastery, dark vision, stealth, and the ability to get more meat from hunted game. The deep-range explorer who lives off the land.

**Pathfinder** *(post-launch)* -- Extended surveying range, self-cartography, resource sensing, and stamina recovery. Cover more ground on less.

**Scholar** *(post-launch)* -- Read precursor inscriptions, sleep in ruins as if they were a village, and reactivate ancient sustenance systems. The ruins become your infrastructure.

### Combat

**Warrior** -- Melee damage, heavy armor access, increased carry weight, and a charging stagger attack. The straightforward fighter who can take punishment and carry more gear.

**Swordsman** *(post-launch)* -- Riposte, cripple, bleed, and off-hand mastery. Precision combat that exploits openings and punishes monsters through technique.

**Wizard** *(post-launch)* -- Six spells, each consuming a specific reagent. Devastating when supplied, helpless when empty. Pack your loadout before the expedition.

### Logistics

**Artificer** -- Mobile blacksmith and gun specialist. Repair gear in the field, craft ammunition, lay traps, and activate precursor mechanisms. Your camp becomes a workshop.

**Alchemist** -- See hidden plants, brew advanced potions, resist poison, and purify water without a campfire. A walking pharmacy.

**Ritualist** *(post-launch)* -- Place wards that block monsters, decoys that lure them, circles that banish them. Enchant weapons. Teleport loot home. Teleport yourself home. Everything is a circle or a channel.

Four disciplines ship at launch (Survivalist, Warrior, Artificer, Alchemist), giving 4 possible builds. Post-launch expands to all nine, giving 84 possible builds. Abilities are unlocked by earning experience through use and spending it at a City. Cities are progression gates -- you need a strong enough trade network to produce one before you can unlock your most powerful abilities.

---

## Hirelings

You can hire NPCs at settlements to support your expeditions. They stay at your camp, bring their own tents, and never fight.

**Launch hirelings:**

**Porter** *(Village+)* -- Provides a backpack container at camp for extra carry capacity. At your home, transfers items to and from home storage.

**Hunter** *(Village+)* -- Generates food automatically when you sleep at camp. Eliminates the need to hunt entirely.

**Surveyor** *(Town+)* -- Discovers all resources in an area and is required for founding new settlements. The gatekeeper of expansion.

**Post-launch hirelings:**

**Guide** *(Town+)* -- Points you toward nearby points of interest. Useful in unfamiliar territory.

**Cartographer** *(Town+)* -- Creates maps of areas you explore together. Fills in your map without surveying.

**Healer** *(Town+)* -- Treats injuries at camp that would normally require a Town. Extends your range by reducing the need to trek back for medical care.

Hirelings are expensive. Maintaining a retinue deep in the west creates real economic pressure to keep your trade network profitable.

---

## Progression Arc

**Early game:** You start at Crestport, the only settlement, with a compass and an empty map. You explore nearby, scan everything into your journal, chop trees for campfires, hunt rabbits for dinner. You hire a surveyor and found your first trading post. You find a Place of Power and choose your first discipline.

**Mid game:** Several settlements connected by roads. Villages upgrading to Towns. You unlock abilities 2-4 at your first City. Better weapons, maybe firearms. You hire a porter and push west into harder territory.

**Late game:** A broad network spanning the continent. Multiple ports. Cities at strategic chokepoints. All three attunements with most abilities unlocked. Rune-socketed gear. You're exploring the deep west where apex predators roam and the precursor ruins hold the best loot. The game does not end.

---

## What Makes It Different

**You are on the ground, not above it.** Every settlement exists because you walked there first. This is not a city builder. It's a survival game where your survival infrastructure scales from a tent and a campfire to a continent-spanning trade network.

**The world transforms behind you.** Early areas that were terrifying become safe as settlements grow. You can look east from a western ridge and see the civilization you built.

**Preparation is gameplay.** Do you bring an axe for campfires, or a fishing rod for food? Do you push west with a light pack and risk running out of supplies, or go heavy with a full camp and move slowly? Every inventory slot matters, and every expedition is a calculated risk.

**No hand-holding.** No quest markers, no GPS, no auto-map. Getting lost is real. Preparation matters. The game rewards patience and punishes overextension.

---

## Platform and Scope

**Platform:** PC (Windows)
**Engine:** Godot 4
**Players:** Single player at launch. Co-op (2-4) post-launch.
**Development:** Solo indie, AI-assisted, with contracted art assets.

The game ships lean: 200-300 hex areas from modular templates, four of nine disciplines, three of six hirelings, day/night cycle without seasons. Core loop proven, then expanded.

---

*The Frontier occupies an identified gap: a third-person exploration game where your decisions about where to build civilization on a monster-haunted continent drive an economic system that visibly transforms the world.*
