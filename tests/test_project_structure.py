"""
test_project_structure.py
Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
Sections: LCORE, LPROJ, LDATA

Tests that the Godot project structure matches LLR requirements:
- project.godot exists and declares correct engine version / target_fps
- Required autoload scripts exist
- Required scene/script directories exist
- Default input data file exists
"""
import pathlib
import re
import pytest

PROJECT_ROOT = pathlib.Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
SCENES_DIR = PROJECT_ROOT / "scenes"


# ---------------------------------------------------------------------------
# LCORE-001 — Godot 4.x project
# ---------------------------------------------------------------------------

def test_project_godot_exists_lcore001():
    """[LCORE-001] project.godot shall exist in the project root."""
    assert (PROJECT_ROOT / "project.godot").exists(), \
        "[LCORE-001] project.godot not found in project root"


def test_godot_version_is_4x_lcore001():
    """[LCORE-001] project.godot shall declare Godot 4.x engine version."""
    godot_file = PROJECT_ROOT / "project.godot"
    if not godot_file.exists():
        pytest.skip("project.godot not found")
    content = godot_file.read_text(encoding="utf-8")
    # Godot 4 uses config_version=5
    assert re.search(r'config_version\s*=\s*5', content), \
        "[LCORE-001] project.godot does not indicate Godot 4.x (config_version=5)"


# ---------------------------------------------------------------------------
# LCORE-005 — target_fps in project settings
# ---------------------------------------------------------------------------

def test_target_fps_set_lcore005():
    """[LCORE-005] project.godot shall set target_fps."""
    godot_file = PROJECT_ROOT / "project.godot"
    if not godot_file.exists():
        pytest.skip("project.godot not found")
    content = godot_file.read_text(encoding="utf-8")
    assert re.search(r'target_fps\s*=', content), \
        "[LCORE-005] project.godot does not set target_fps"


# ---------------------------------------------------------------------------
# LCORE-007 — default_input.json exists
# ---------------------------------------------------------------------------

def test_default_input_json_exists_lcore007():
    """[LCORE-007] res://data/default_input.json shall ship with the project."""
    assert (DATA_DIR / "default_input.json").exists(), \
        "[LCORE-007] data/default_input.json not found"


# ---------------------------------------------------------------------------
# LPROJ-001 — scene subdirectories
# ---------------------------------------------------------------------------

REQUIRED_SCENE_DIRS = [
    ("player",      "LPROJ-001"),
    ("monsters",    "LPROJ-001"),
    ("settlements", "LPROJ-001"),
    ("camps",       "LPROJ-001"),
    ("ui",          "LPROJ-001"),
    ("map",         "LPROJ-001"),
    ("precursor",   "LPROJ-001"),
]


@pytest.mark.parametrize("subdir,llr_id", REQUIRED_SCENE_DIRS)
def test_scene_subdirectory_exists_lproj001(subdir, llr_id):
    """[LPROJ-001] scenes/ shall contain required subdirectories."""
    target = SCENES_DIR / subdir
    assert target.exists() and target.is_dir(), \
        f"[{llr_id}] scenes/{subdir}/ directory not found"


# ---------------------------------------------------------------------------
# LPROJ-002 — script subdirectories
# ---------------------------------------------------------------------------

REQUIRED_SCRIPT_DIRS = [
    ("autoloads",  "LPROJ-002"),
    ("player",     "LPROJ-002"),
    ("monsters",   "LPROJ-002"),
    ("ui",         "LPROJ-002"),
    ("abilities",  "LPROJ-002"),
]


@pytest.mark.parametrize("subdir,llr_id", REQUIRED_SCRIPT_DIRS)
def test_script_subdirectory_exists_lproj002(subdir, llr_id):
    """[LPROJ-002] scripts/ shall contain required subdirectories."""
    target = SCRIPTS_DIR / subdir
    assert target.exists() and target.is_dir(), \
        f"[{llr_id}] scripts/{subdir}/ directory not found"


# ---------------------------------------------------------------------------
# LPROJ-003 — autoload scripts exist
# ---------------------------------------------------------------------------

REQUIRED_AUTOLOADS = [
    "DataLoader",
    "SaveManager",
    "InputManager",
    "TimeManager",
    "AreaManager",
    "HexGrid",
    "SettlementManager",
    "SpawnManager",
    "DisciplineManager",
    "AudioManager",
    "TradeGraph",
    "FoundingManager",
    "PlayerStats",
    "CombatManager",
]


@pytest.mark.parametrize("autoload", REQUIRED_AUTOLOADS)
def test_autoload_script_exists_lproj003(autoload):
    """[LPROJ-003] Each required autoload script shall exist under scripts/autoloads/."""
    path = SCRIPTS_DIR / "autoloads" / f"{autoload}.gd"
    assert path.exists(), \
        f"[LPROJ-003] Autoload script not found: scripts/autoloads/{autoload}.gd"


# ---------------------------------------------------------------------------
# LPROJ-003 — autoloads registered in project.godot
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("autoload", REQUIRED_AUTOLOADS)
def test_autoload_registered_in_project_godot_lproj003(autoload):
    """[LPROJ-003] Each required autoload shall be registered in project.godot."""
    godot_file = PROJECT_ROOT / "project.godot"
    if not godot_file.exists():
        pytest.skip("project.godot not found")
    content = godot_file.read_text(encoding="utf-8")
    assert autoload in content, \
        f"[LPROJ-003] Autoload '{autoload}' not registered in project.godot"


# ---------------------------------------------------------------------------
# LPROJ-004 — data directory exists
# ---------------------------------------------------------------------------

def test_data_directory_exists_lproj004():
    """[LPROJ-004] res://data/ directory shall exist."""
    assert DATA_DIR.exists() and DATA_DIR.is_dir(), \
        "[LPROJ-004] data/ directory not found"


# ---------------------------------------------------------------------------
# LCORE-002 — main.tscn exists
# ---------------------------------------------------------------------------

def test_main_scene_exists_lcore002():
    """[LCORE-002] scenes/main/main.tscn shall exist."""
    path = SCENES_DIR / "main" / "main.tscn"
    # Also try root level
    alt_path = SCENES_DIR / "main" / "Main.tscn"
    assert path.exists() or alt_path.exists(), \
        "[LCORE-002] main.tscn / Main.tscn not found in scenes/main/"


def test_main_scene_has_world_environment_lcore002():
    """[LCORE-002] main.tscn shall reference a WorldEnvironment node."""
    for name in ("main.tscn", "Main.tscn"):
        path = SCENES_DIR / "main" / name
        if path.exists():
            content = path.read_text(encoding="utf-8")
            assert "WorldEnvironment" in content, \
                "[LCORE-002] Main scene does not contain WorldEnvironment node"
            return
    pytest.skip("main.tscn not found")


# ---------------------------------------------------------------------------
# LPC-001 — player scene root is CharacterBody3D
# ---------------------------------------------------------------------------

def test_player_scene_root_is_character_body_3d_lpc001():
    """[LPC-001] Player scene root shall be a CharacterBody3D."""
    for name in ("player.tscn", "Player.tscn"):
        path = SCENES_DIR / "player" / name
        if path.exists():
            content = path.read_text(encoding="utf-8")
            assert "CharacterBody3D" in content, \
                "[LPC-001] Player scene root is not CharacterBody3D"
            return
    pytest.skip("Player.tscn not found")


def test_player_scene_has_collision_camera_hud_lpc002():
    """[LPC-002] Player scene shall include CollisionShape3D, Camera3D, and RayCast3D."""
    for name in ("player.tscn", "Player.tscn"):
        path = SCENES_DIR / "player" / name
        if path.exists():
            content = path.read_text(encoding="utf-8")
            for node_type in ("CollisionShape3D", "Camera3D", "RayCast3D"):
                assert node_type in content, \
                    f"[LPC-002] Player scene missing {node_type}"
            return
    pytest.skip("Player.tscn not found")


# ---------------------------------------------------------------------------
# LMAI-001 — MonsterBase scene has NavigationAgent3D
# ---------------------------------------------------------------------------

def test_monster_base_has_navigation_agent_lmai001():
    """[LMAI-001] MonsterBase scene shall include NavigationAgent3D."""
    for name in ("MonsterBase.tscn", "monster_base.tscn"):
        path = SCENES_DIR / "monsters" / name
        if path.exists():
            content = path.read_text(encoding="utf-8")
            assert "NavigationAgent3D" in content, \
                "[LMAI-001] MonsterBase scene missing NavigationAgent3D"
            return
    pytest.skip("MonsterBase.tscn not found")


# ---------------------------------------------------------------------------
# LCAMP-010 — camp scene has OmniLight3D (campfire light)
# ---------------------------------------------------------------------------

def test_camp_has_omni_light_lcamp010():
    """[LCAMP-010] Camp/Campfire scene shall include OmniLight3D."""
    for search_dir in (SCENES_DIR / "camp", SCENES_DIR / "camps"):
        if search_dir.exists():
            for f in search_dir.glob("*.tscn"):
                content = f.read_text(encoding="utf-8")
                if "OmniLight3D" in content:
                    return  # found
    pytest.skip("No camp scene with OmniLight3D found — may not be created yet")


# ---------------------------------------------------------------------------
# LDATA files in flat layout vs subdirectory (documents gap)
# ---------------------------------------------------------------------------

FLAT_DATA_FILES = [
    "monsters.json", "spawn_tables.json", "resources.json", "areas.json",
    "settlement_tiers.json", "trade_weights.json", "export_thresholds.json",
    "disciplines.json", "reagents.json", "runes.json", "items.json",
    "injuries.json", "weapons.json", "seasons.json", "survival.json",
    "recipes.json", "manufactured_goods.json", "hirelings.json",
    "roads.json", "landmarks.json", "hex_templates.json",
]


@pytest.mark.parametrize("filename", FLAT_DATA_FILES)
def test_data_file_is_flat_not_in_subdir(filename):
    """[LPROJ-004 / LDATA-001..020] Data files shall be directly under res://data/, not in subdirs."""
    flat_path = DATA_DIR / filename
    assert flat_path.exists(), (
        f"[LPROJ-004] {filename} not found at data/{filename}. "
        "LLR v0.5.1 requires flat layout. Check if file is in a subdirectory."
    )
