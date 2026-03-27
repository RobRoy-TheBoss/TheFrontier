# The Frontier

A first-person survival sandbox built in **Godot 4.6.1 / GDScript**.

Explore a procedurally-driven frontier, found settlements, manage survival needs, master disciplines, and fight monsters — all in a data-driven world with no hardcoded gameplay values.

---

## Requirements

- **Godot 4.6.1** (stable) — [download](https://godotengine.org/download)
- No additional plugins needed — the GUT test addon is included in `addons/gut/`

---

## Getting Started

1. Clone the repo
2. Open Godot 4.6.1, click **Import**, and select the `project.godot` file
3. Press **F5** (or the Play button) to run from the main scene

The player spawns in the Eastern Frontier near Crestport. Press **E** to interact, **Tab** for inventory, **Escape** to pause.

---

## Controls

| Key | Action |
|-----|--------|
| W A S D | Move |
| Double-tap W/A/S/D | Sprint |
| Left Shift | Crouch |
| Space | Jump |
| Mouse | Look |
| Scroll wheel | Zoom |
| E | Interact |
| Tab | Inventory |
| M | Map |
| J | Field Journal |
| F | Plant settlement flag |
| Escape | Pause menu |

---

## Running Tests

### GUT (in-engine runtime tests)
1. Open the project in Godot
2. Go to **Project → Tools → GUT** (or the GUT panel at the bottom)
3. Click **Run All**

Tests live in `tests/gut/`. Each file is traced to an LLR requirement ID.

### Python static tests
These run without Godot and check data files and script structure:

```bash
pip install pytest
pytest tests/ -q
```

---

## Project Structure

```
data/           JSON data files — all gameplay values live here
scenes/         .tscn scene files
scripts/
  autoloads/    Singletons (GameData, GameState, SettlementManager, etc.)
  player/       Player subsystems (movement, health, inventory, combat)
  monsters/     Monster AI
  world/        World objects (camps, chests, landmarks, beds)
  ui/           All UI screens
  disciplines/  Ability system
  alchemy/      Crafting
  navigation/   Field journal, surveying
  settlement/   Roads, flags, settlement logic
tests/
  gut/          GUT runtime tests (require Godot editor)
  python/       Static data/structure tests (pytest)
doc/            Design documents (GDD, HLR, LLR)
addons/gut/     GUT test framework (included)
```

---

## Design Documents

Full requirements are in `doc/`:
- `the-frontier-gdd-v0.7.0.md` — Game Design Document
- `the-frontier-hlr-v0.7.0.md` — High-Level Requirements
- `the-frontier-llr-v0.7.1.md` — Low-Level Requirements (traced to tests)
- `Proposed-Requirement-Changes.md` — Design decisions log (all resolved)
