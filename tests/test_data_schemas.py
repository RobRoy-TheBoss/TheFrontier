"""
test_data_schemas.py
Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
Section 2: Data Layer — LDATA-001 through LDATA-044

Tests that all required JSON data files exist under res://data/ (flat layout),
are valid JSON, and conform to the field schemas required by the LLR.

NOTE: Tests marked FAIL are expected failures reflecting the current project state
      where data files live in subdirectories (data/monsters/monsters.json) rather
      than the flat layout specified in LLR v0.5.1 (data/monsters.json).
      These tests document the gap and should be fixed when data is reorganised.
"""
import json
import pathlib
import pytest

DATA_DIR = pathlib.Path(__file__).parent.parent / "data"


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

def _load(filename: str):
    """Load a JSON file from the flat data/ directory."""
    path = DATA_DIR / filename
    assert path.exists(), (
        f"FAIL: {filename} not found at {path}. "
        "LLR v0.6.0 requires all data files directly under res://data/."
    )
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _has_fields(entry: dict, required: list[str], context: str = ""):
    missing = [k for k in required if k not in entry]
    assert not missing, f"Entry missing fields {missing} in {context}: {entry.get('id', entry)}"


# ---------------------------------------------------------------------------
# LDATA-001 to LDATA-020 — file existence and parseability
# ---------------------------------------------------------------------------

REQUIRED_DATA_FILES = [
    ("monsters.json",           "LDATA-001"),
    ("spawn_tables.json",       "LDATA-002"),
    ("resources.json",          "LDATA-003"),
    ("areas.json",              "LDATA-004"),
    ("settlement_tiers.json",   "LDATA-005"),
    ("trade_weights.json",      "LDATA-006"),
    ("export_thresholds.json",  "LDATA-007"),
    ("disciplines.json",        "LDATA-008"),
    ("reagents.json",           "LDATA-009"),
    ("runes.json",              "LDATA-010"),
    ("items.json",              "LDATA-011"),
    ("injuries.json",           "LDATA-012"),
    ("weapons.json",            "LDATA-013"),
    ("seasons.json",            "LDATA-014"),
    ("survival.json",           "LDATA-015"),
    ("recipes.json",            "LDATA-016"),
    ("manufactured_goods.json", "LDATA-017"),
    ("hirelings.json",          "LDATA-018"),
    ("roads.json",              "LDATA-019"),
    ("landmarks.json",          "LDATA-020"),
    ("hex_templates.json",      "LDATA-044"),
]


@pytest.mark.parametrize("filename,llr_id", REQUIRED_DATA_FILES)
def test_data_file_exists_and_parseable(filename, llr_id):
    """[LDATA-001..020] Each required JSON data file shall exist and be parseable."""
    path = DATA_DIR / filename
    assert path.exists(), (
        f"[{llr_id}] {filename} missing from {DATA_DIR}. "
        "All data files must be flat under res://data/."
    )
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data is not None, f"[{llr_id}] {filename} parsed to None"


# ---------------------------------------------------------------------------
# LDATA-030 — monsters.json schema
# ---------------------------------------------------------------------------

def test_monsters_schema_ldata030():
    """[LDATA-030] Each monster entry shall include required fields."""
    data = _load("monsters.json")
    monsters = data if isinstance(data, list) else data.get("monsters", [])
    assert len(monsters) > 0, "monsters.json has no entries"
    required = ["id", "name", "model_path", "hp", "damage", "speed",
                "behavior_type", "loot_table", "fire_reaction", "light_reaction"]
    for m in monsters:
        _has_fields(m, required, "monsters.json")


# ---------------------------------------------------------------------------
# LDATA-031 — areas.json schema
# ---------------------------------------------------------------------------

def test_areas_schema_ldata031():
    """[LDATA-031] Each area entry shall include required fields including hex_coords."""
    data = _load("areas.json")
    areas = data if isinstance(data, list) else data.get("areas", [])
    assert len(areas) > 0, "areas.json has no entries"
    required = ["id", "region_id", "hex_coords", "neighbors", "resource_tags",
                "spawn_table_id", "difficulty", "tags", "edge_features",
                "settlement_site", "precursor_site_index"]
    for a in areas:
        _has_fields(a, required, "areas.json")
        hc = a["hex_coords"]
        assert "q" in hc and "r" in hc, f"hex_coords missing q/r in area {a.get('id')}"


# ---------------------------------------------------------------------------
# LDATA-032 — edge_feature entries
# ---------------------------------------------------------------------------

def test_edge_features_schema_ldata032():
    """[LDATA-032] Each area edge_feature shall include edge_index and type."""
    data = _load("areas.json")
    areas = data if isinstance(data, list) else data.get("areas", [])
    valid_types = {"river", "cliff", "ford", "rapids"}
    for a in areas:
        for ef in a.get("edge_features", []):
            assert "edge_index" in ef, f"edge_feature missing edge_index in area {a.get('id')}"
            assert "type" in ef, f"edge_feature missing type in area {a.get('id')}"
            assert isinstance(ef["edge_index"], int) and 0 <= ef["edge_index"] <= 5, \
                f"edge_index must be 0-5, got {ef['edge_index']} in area {a.get('id')}"
            assert ef["type"] in valid_types, \
                f"Invalid edge type '{ef['type']}' in area {a.get('id')}"


# ---------------------------------------------------------------------------
# LDATA-033 — settlement_tiers.json schema
# ---------------------------------------------------------------------------

def test_settlement_tiers_schema_ldata033():
    """[LDATA-033] Each settlement tier entry shall include required fields."""
    data = _load("settlement_tiers.json")
    tiers = data if isinstance(data, list) else data.get("tiers", [])
    assert len(tiers) > 0, "settlement_tiers.json has no entries"
    required = ["tier", "name", "score_threshold", "required_resources",
                "suppression_pct", "safe_zone_radius", "consumption_rate",
                "exploitation", "services", "road_budget"]
    for t in tiers:
        _has_fields(t, required, "settlement_tiers.json")
        exp = t["exploitation"]
        assert "own_pct" in exp and "adjacent_pct" in exp and "ring2_pct" in exp, \
            f"exploitation missing own_pct/adjacent_pct/ring2_pct in tier {t.get('tier')}"


# ---------------------------------------------------------------------------
# LDATA-034 — runes.json schema
# ---------------------------------------------------------------------------

def test_runes_schema_ldata034():
    """[LDATA-034] Each rune entry shall include required fields including Poisson params."""
    data = _load("runes.json")
    runes = data if isinstance(data, list) else data.get("runes", [])
    assert len(runes) > 0, "runes.json has no entries"
    required = ["id", "name", "effects", "slot_types", "rarity",
                "poisson_mean", "poisson_min", "poisson_max"]
    for r in runes:
        _has_fields(r, required, "runes.json")
        assert r["poisson_min"] <= r["poisson_mean"] <= r["poisson_max"], \
            f"Rune {r['id']}: poisson_min <= mean <= max violated"


# ---------------------------------------------------------------------------
# LDATA-035 — items.json schema
# ---------------------------------------------------------------------------

def test_items_schema_ldata035():
    """[LDATA-035] Each item entry shall include required fields."""
    data = _load("items.json")
    items = data if isinstance(data, list) else data.get("items", [])
    assert len(items) > 0, "items.json has no entries"
    required = ["id", "name", "weight", "type", "durability", "value",
                "rune_slots", "noise_level", "spoil_timer", "tags"]
    for item in items:
        _has_fields(item, required, "items.json")


# ---------------------------------------------------------------------------
# LDATA-036 — waterskin weight_empty field
# ---------------------------------------------------------------------------

def test_waterskin_weight_empty_ldata036():
    """[LDATA-036] Waterskin items shall have a weight_empty field."""
    data = _load("items.json")
    items = data if isinstance(data, list) else data.get("items", [])
    waterskins = [i for i in items if "waterskin" in i.get("id", "").lower()]
    assert len(waterskins) > 0, "No waterskin items found in items.json"
    for ws in waterskins:
        assert "weight_empty" in ws, \
            f"Waterskin '{ws['id']}' missing weight_empty field [LDATA-036]"


# ---------------------------------------------------------------------------
# LDATA-037 — injuries.json schema
# ---------------------------------------------------------------------------

def test_injuries_schema_ldata037():
    """[LDATA-037] Each injury entry shall include required fields."""
    data = _load("injuries.json")
    injuries = data if isinstance(data, list) else data.get("injuries", [])
    assert len(injuries) > 0, "injuries.json has no entries"
    required = ["id", "name", "debuffs", "causes", "probability_by_source", "treatment_tier"]
    for inj in injuries:
        _has_fields(inj, required, "injuries.json")


# ---------------------------------------------------------------------------
# LDATA-038 — weapons.json schema
# ---------------------------------------------------------------------------

def test_weapons_schema_ldata038():
    """[LDATA-038] Each weapon entry shall include required fields."""
    data = _load("weapons.json")
    weapons = data if isinstance(data, list) else data.get("weapons", [])
    assert len(weapons) > 0, "weapons.json has no entries"
    required = ["id", "name", "type", "damage", "speed", "stamina_cost",
                "weight", "durability", "rune_slots", "noise", "weapon_category"]
    for w in weapons:
        _has_fields(w, required, "weapons.json")


# ---------------------------------------------------------------------------
# LDATA-039 — disciplines.json schema
# ---------------------------------------------------------------------------

def test_disciplines_schema_ldata039():
    """[LDATA-039] Each discipline entry shall include id, name, abilities[], xp_triggers[]."""
    data = _load("disciplines.json")
    disciplines = data if isinstance(data, list) else data.get("disciplines", [])
    assert len(disciplines) > 0, "disciplines.json has no entries"
    required = ["id", "name", "abilities", "xp_triggers"]
    for d in disciplines:
        _has_fields(d, required, "disciplines.json")
        assert isinstance(d["abilities"], list), \
            f"Discipline {d['id']}: abilities must be a list"
        assert isinstance(d["xp_triggers"], list), \
            f"Discipline {d['id']}: xp_triggers must be a list"


# ---------------------------------------------------------------------------
# LDATA-040 — reagents.json schema
# ---------------------------------------------------------------------------

def test_reagents_schema_ldata040():
    """[LDATA-040] Each reagent entry shall include required fields."""
    data = _load("reagents.json")
    reagents = data if isinstance(data, list) else data.get("reagents", [])
    assert len(reagents) > 0, "reagents.json has no entries"
    required = ["id", "name", "spell_id", "weight", "tier", "source", "buy_price"]
    for r in reagents:
        _has_fields(r, required, "reagents.json")


# ---------------------------------------------------------------------------
# LDATA-041 — disciplines.json: exactly 9 disciplines, 61 total abilities
# ---------------------------------------------------------------------------

def test_discipline_count_ldata041():
    """[LDATA-041] disciplines.json shall contain exactly 4 launch disciplines."""
    data = _load("disciplines.json")
    disciplines = data if isinstance(data, list) else data.get("disciplines", [])
    assert len(disciplines) == 4, \
        f"[LDATA-041] Expected 4 launch disciplines, found {len(disciplines)}"


def test_ability_count_ldata041():
    """[LDATA-041] disciplines.json shall contain exactly 28 total launch abilities."""
    data = _load("disciplines.json")
    disciplines = data if isinstance(data, list) else data.get("disciplines", [])
    total = sum(len(d.get("abilities", [])) for d in disciplines)
    assert total == 28, \
        f"[LDATA-041] Expected 28 total launch abilities, found {total}"


# ---------------------------------------------------------------------------
# LDATA-042 — injuries.json: exactly 7 injury types
# ---------------------------------------------------------------------------

def test_injury_count_ldata042():
    """[LDATA-042] injuries.json shall contain exactly 7 injury types."""
    data = _load("injuries.json")
    injuries = data if isinstance(data, list) else data.get("injuries", [])
    assert len(injuries) == 7, \
        f"[LDATA-042] Expected 7 injury types, found {len(injuries)}"


# ---------------------------------------------------------------------------
# Additional schema checks — trade_weights.json (LDATA-006)
# ---------------------------------------------------------------------------

def test_trade_weights_schema():
    """[LDATA-006] trade_weights.json shall exist and contain weighting keys."""
    data = _load("trade_weights.json")
    required_keys = ["local_weight", "passthrough_weight", "connection_bonus"]
    for k in required_keys:
        assert k in data, f"trade_weights.json missing key '{k}'"


# ---------------------------------------------------------------------------
# Additional schema checks — export_thresholds.json (LDATA-007)
# ---------------------------------------------------------------------------

def test_export_thresholds_schema():
    """[LDATA-007] export_thresholds.json shall contain tier threshold entries."""
    data = _load("export_thresholds.json")
    # Should be a dict of tier_name -> numeric threshold
    assert isinstance(data, dict) and len(data) > 0, \
        "export_thresholds.json must be a non-empty dict"
    for k, v in data.items():
        assert isinstance(v, (int, float)), \
            f"export_thresholds entry '{k}' value must be numeric, got {type(v)}"


# ---------------------------------------------------------------------------
# Additional schema checks — seasons.json (LDATA-014)
# ---------------------------------------------------------------------------

def test_seasons_schema():
    """[LDATA-014] seasons.json shall contain season entries with duration and weather_table."""
    data = _load("seasons.json")
    seasons = data if isinstance(data, list) else data.get("seasons", [])
    assert len(seasons) == 4, f"Expected 4 seasons, found {len(seasons)}"
    for s in seasons:
        assert "name" in s, f"Season entry missing 'name': {s}"
        assert "duration_days" in s or "days" in s, \
            f"Season '{s.get('name')}' missing duration field"
        assert "weather_table" in s, \
            f"Season '{s.get('name')}' missing weather_table"


# ---------------------------------------------------------------------------
# Additional schema checks — survival.json (LDATA-015)
# ---------------------------------------------------------------------------

def test_survival_schema():
    """[LDATA-015] survival.json shall contain base health and stamina regen values."""
    data = _load("survival.json")
    required = ["base_health_regen", "base_stamina_regen", "max_carry",
                "sprint_stamina_drain"]
    for k in required:
        assert k in data, f"survival.json missing key '{k}'"


# ---------------------------------------------------------------------------
# Additional schema checks — hirelings.json (LDATA-018)
# ---------------------------------------------------------------------------

def test_hirelings_schema():
    """[LDATA-018] Each hireling entry shall include type, cost_per_day, and capabilities."""
    data = _load("hirelings.json")
    hirelings = data if isinstance(data, list) else data.get("hirelings", [])
    assert len(hirelings) > 0, "hirelings.json has no entries"
    required = ["id", "type", "cost_per_day", "capabilities"]
    for h in hirelings:
        _has_fields(h, required, "hirelings.json")


# ---------------------------------------------------------------------------
# Additional schema checks — roads.json (LDATA-019)
# ---------------------------------------------------------------------------

def test_roads_schema():
    """[LDATA-019] roads.json shall contain road quality visual definitions."""
    data = _load("roads.json")
    # roads.json maps quality levels to mesh/material paths
    assert isinstance(data, (dict, list)) and len(data) > 0, \
        "roads.json must be non-empty"


# ---------------------------------------------------------------------------
# Additional schema checks — manufactured_goods.json (LDATA-017)
# ---------------------------------------------------------------------------

def test_manufactured_goods_schema():
    """[LDATA-017] Each manufactured good shall include export and settlement tier fields."""
    data = _load("manufactured_goods.json")
    goods = data if isinstance(data, list) else data.get("manufactured_goods", [])
    assert len(goods) > 0, "manufactured_goods.json has no entries"
    required = ["id", "name", "export_threshold_tier", "weight",
                "base_price", "min_settlement_tier"]
    for g in goods:
        _has_fields(g, required, "manufactured_goods.json")


# ---------------------------------------------------------------------------
# Rune slot count checks (LBOW-006, LRNG-004, LRNG-005, LMEL-010)
# ---------------------------------------------------------------------------

def test_bows_have_2_rune_slots_lbow006():
    """[LBOW-006] Bows shall have exactly 2 rune slots."""
    data = _load("weapons.json")
    weapons = data if isinstance(data, list) else data.get("weapons", [])
    bows = [w for w in weapons if w.get("weapon_category") == "bow"
            or w.get("type") in ("bow", "longbow", "hunting_bow")]
    assert len(bows) > 0, "No bows found in weapons.json"
    for b in bows:
        assert b["rune_slots"] == 2, \
            f"[LBOW-006] Bow '{b['id']}' has {b['rune_slots']} rune slots, expected 2"


def test_muskets_have_2_rune_slots_lrng004():
    """[LRNG-004] Muskets shall have exactly 2 rune slots."""
    data = _load("weapons.json")
    weapons = data if isinstance(data, list) else data.get("weapons", [])
    muskets = [w for w in weapons if w.get("weapon_category") == "musket"
               or w.get("id") == "musket"]
    assert len(muskets) > 0, "No muskets found in weapons.json"
    for m in muskets:
        assert m["rune_slots"] == 2, \
            f"[LRNG-004] Musket '{m['id']}' has {m['rune_slots']} rune slots, expected 2"


def test_pistols_have_1_rune_slot_lrng005():
    """[LRNG-005] Pistols shall have exactly 1 rune slot."""
    data = _load("weapons.json")
    weapons = data if isinstance(data, list) else data.get("weapons", [])
    pistols = [w for w in weapons if w.get("weapon_category") == "pistol"
               or w.get("id") == "pistol"]
    assert len(pistols) > 0, "No pistols found in weapons.json"
    for p in pistols:
        assert p["rune_slots"] == 1, \
            f"[LRNG-005] Pistol '{p['id']}' has {p['rune_slots']} rune slots, expected 1"


def test_shields_have_1_rune_slot_lmel010():
    """[LMEL-010] Shields shall have exactly 1 rune slot."""
    data = _load("weapons.json")
    weapons = data if isinstance(data, list) else data.get("weapons", [])
    shields = [w for w in weapons if w.get("weapon_category") == "shield"
               or w.get("type") == "shield"]
    # Shields may not exist in weapons.json yet — if they do, enforce slot count
    for s in shields:
        assert s["rune_slots"] == 1, \
            f"[LMEL-010] Shield '{s['id']}' has {s['rune_slots']} rune slots, expected 1"


# ---------------------------------------------------------------------------
# LMEL-005 — Shield block_reduction > weapon block_reduction
# ---------------------------------------------------------------------------

def test_shield_block_reduction_greater_lmel005():
    """[LMEL-005] Shield block_reduction shall be greater than weapon block_reduction."""
    data = _load("weapons.json")
    weapons = data if isinstance(data, list) else data.get("weapons", [])
    shields = [w for w in weapons if w.get("weapon_category") == "shield"]
    non_shields = [w for w in weapons if w.get("weapon_category") != "shield"
                   and "block_reduction" in w]
    if shields and non_shields:
        min_shield_br = min(s.get("block_reduction", 0) for s in shields)
        max_weapon_br = max(w.get("block_reduction", 0) for w in non_shields)
        assert min_shield_br > max_weapon_br, \
            f"[LMEL-005] Smallest shield block_reduction ({min_shield_br}) must exceed " \
            f"largest weapon block_reduction ({max_weapon_br})"


# ---------------------------------------------------------------------------
# LRUNE-003 — Higher rarity runes have higher poisson_mean
# ---------------------------------------------------------------------------

RARITY_ORDER = {"common": 1, "uncommon": 2, "rare": 3, "legendary": 4}


def test_rune_rarity_poisson_mean_lrune003():
    """[LRUNE-003] Higher rarity runes shall have higher poisson_mean values."""
    data = _load("runes.json")
    runes = data if isinstance(data, list) else data.get("runes", [])
    rarity_means: dict[str, list] = {}
    for r in runes:
        rar = r.get("rarity", "common")
        rarity_means.setdefault(rar, []).append(r["poisson_mean"])

    # Check that average mean increases with rarity
    known_rarities = [r for r in RARITY_ORDER if r in rarity_means]
    for i in range(len(known_rarities) - 1):
        low_rar = known_rarities[i]
        high_rar = known_rarities[i + 1]
        avg_low = sum(rarity_means[low_rar]) / len(rarity_means[low_rar])
        avg_high = sum(rarity_means[high_rar]) / len(rarity_means[high_rar])
        assert avg_high >= avg_low, (
            f"[LRUNE-003] {high_rar} rune avg poisson_mean ({avg_high:.2f}) "
            f"is not >= {low_rar} avg ({avg_low:.2f})"
        )


# ---------------------------------------------------------------------------
# LRUNE-004 — life_steal runes have correct slot_types restriction
# ---------------------------------------------------------------------------

def test_life_steal_rune_slot_types_lrune004():
    """[LRUNE-004] Runes with the life_steal tag shall not include bow/musket/pistol in slot_types."""
    data = _load("runes.json")
    runes = data if isinstance(data, list) else data.get("runes", [])
    ranged_categories = {"bow", "musket", "pistol"}
    for r in runes:
        if "life_steal" in r.get("effects", {}):
            bad = ranged_categories & set(r.get("slot_types", []))
            assert not bad, (
                f"[LRUNE-004] Rune '{r['id']}' has life_steal but allows "
                f"ranged slot_types: {bad}"
            )


# ---------------------------------------------------------------------------
# LSURV-016/017 — waterskin weight=0 when empty, weight=water_weight when full
# ---------------------------------------------------------------------------

def test_waterskin_empty_weight_lsurv016():
    """[LSURV-016] Waterskin items shall have weight_empty = 0."""
    data = _load("items.json")
    items = data if isinstance(data, list) else data.get("items", [])
    waterskins = [i for i in items if "waterskin" in i.get("id", "").lower()]
    assert waterskins, "No waterskin items found"
    for ws in waterskins:
        assert ws.get("weight_empty", -1) == 0, \
            f"[LSURV-016] Waterskin '{ws['id']}' weight_empty is not 0"


def test_waterskin_full_weight_lsurv017():
    """[LSURV-017] Waterskin items shall have a positive weight (when full)."""
    data = _load("items.json")
    items = data if isinstance(data, list) else data.get("items", [])
    waterskins = [i for i in items if "waterskin" in i.get("id", "").lower()]
    for ws in waterskins:
        assert ws.get("weight", 0) > 0, \
            f"[LSURV-017] Waterskin '{ws['id']}' full weight must be > 0"


# ---------------------------------------------------------------------------
# LSURV-010/011 — cold weather clothing and tent weights
# ---------------------------------------------------------------------------

def test_cold_weather_clothing_weight_lsurv010():
    """[LSURV-010] Cold weather clothing items shall have weight values defined."""
    data = _load("items.json")
    items = data if isinstance(data, list) else data.get("items", [])
    cold_clothing = [i for i in items if "cold" in i.get("tags", [])]
    assert len(cold_clothing) > 0, \
        "[LSURV-010] No items with 'cold' tag found in items.json"
    for item in cold_clothing:
        assert item.get("weight", 0) > 0, \
            f"[LSURV-010] Cold clothing '{item['id']}' has no weight"


def test_cold_tent_heavier_lsurv011():
    """[LSURV-011] Cold weather tents shall have a higher weight than normal tents."""
    data = _load("items.json")
    items = data if isinstance(data, list) else data.get("items", [])
    tents = {i["id"]: i for i in items if "tent" in i.get("id", "").lower()}
    if len(tents) >= 2:
        normal = tents.get("tent")
        cold = tents.get("cold_weather_tent") or next(
            (t for t in tents.values() if "cold" in t.get("id", "")), None
        )
        if normal and cold:
            assert cold["weight"] > normal["weight"], \
                f"[LSURV-011] Cold tent weight ({cold['weight']}) must exceed " \
                f"normal tent weight ({normal['weight']})"


# ---------------------------------------------------------------------------
# LROAD-001 — road_budget = 9 for all tiers
# ---------------------------------------------------------------------------

def test_road_budget_is_9_lroad001():
    """[LROAD-001] Every settlement tier shall have road_budget of 9."""
    data = _load("settlement_tiers.json")
    tiers = data if isinstance(data, list) else data.get("tiers", [])
    for t in tiers:
        assert t.get("road_budget") == 9, \
            f"[LROAD-001] Tier '{t.get('name')}' road_budget is {t.get('road_budget')}, expected 9"


# ---------------------------------------------------------------------------
# LECO-006 to LECO-009 — exploitation percentages per tier
# ---------------------------------------------------------------------------

def test_exploitation_percentages_leco006_to_009():
    """[LECO-006..009] Settlement tiers shall have correct exploitation percentages."""
    data = _load("settlement_tiers.json")
    tiers = data if isinstance(data, list) else data.get("tiers", [])
    tier_by_index = {t["tier"]: t for t in tiers}

    # Trading Post (tier 1): own=100%, adjacent=0%, ring2=0%
    if 1 in tier_by_index:
        exp = tier_by_index[1]["exploitation"]
        assert exp["own_pct"] == 1.0, "[LECO-006] Trading Post own_pct must be 1.0"
        assert exp["adjacent_pct"] == 0.0, "[LECO-006] Trading Post adjacent_pct must be 0.0"

    # Village (tier 2): own=100%, adjacent=50%
    if 2 in tier_by_index:
        exp = tier_by_index[2]["exploitation"]
        assert exp["own_pct"] == 1.0, "[LECO-007] Village own_pct must be 1.0"
        assert exp["adjacent_pct"] == 0.5, "[LECO-007] Village adjacent_pct must be 0.5"

    # Town (tier 3): own=100%, adjacent=100%
    if 3 in tier_by_index:
        exp = tier_by_index[3]["exploitation"]
        assert exp["own_pct"] == 1.0, "[LECO-008] Town own_pct must be 1.0"
        assert exp["adjacent_pct"] == 1.0, "[LECO-008] Town adjacent_pct must be 1.0"

    # City (tier 4): own=100%, adjacent=100%, ring2=25%
    if 4 in tier_by_index:
        exp = tier_by_index[4]["exploitation"]
        assert exp["own_pct"] == 1.0, "[LECO-009] City own_pct must be 1.0"
        assert exp["adjacent_pct"] == 1.0, "[LECO-009] City adjacent_pct must be 1.0"
        assert exp["ring2_pct"] == 0.25, "[LECO-009] City ring2_pct must be 0.25"


# ---------------------------------------------------------------------------
# LDATA-043 — behavior_type values
# ---------------------------------------------------------------------------

VALID_BEHAVIOR_TYPES = {"territorial", "ambush", "swarm", "heavy", "docile", "apex"}


def test_behavior_type_ldata043():
    """[LDATA-043] Each monster entry shall have behavior_type from the allowed set."""
    data = _load("monsters.json")
    monsters = data if isinstance(data, list) else data.get("monsters", [])
    assert len(monsters) > 0, "monsters.json has no entries"
    for m in monsters:
        bt = m.get("behavior_type")
        assert bt is not None, \
            f"[LDATA-043] Monster '{m.get('id')}' missing behavior_type"
        assert bt in VALID_BEHAVIOR_TYPES, \
            f"[LDATA-043] Monster '{m.get('id')}' has invalid behavior_type '{bt}'; " \
            f"must be one of {VALID_BEHAVIOR_TYPES}"


# ---------------------------------------------------------------------------
# LDATA-044 — hex_templates.json schema
# ---------------------------------------------------------------------------

def test_hex_templates_schema_ldata044():
    """[LDATA-044] hex_templates.json shall list entries with template_id, biome_type, scene_path."""
    data = _load("hex_templates.json")
    templates = data if isinstance(data, list) else data.get("templates", [])
    assert len(templates) > 0, "hex_templates.json has no entries"
    required = ["template_id", "biome_type", "scene_path"]
    for t in templates:
        _has_fields(t, required, "hex_templates.json")
        assert isinstance(t["template_id"], str) and t["template_id"], \
            f"template_id must be a non-empty string: {t}"
        assert isinstance(t["scene_path"], str) and t["scene_path"].endswith(".tscn"), \
            f"scene_path must point to a .tscn file: {t.get('template_id')}"


# ---------------------------------------------------------------------------
# LDATA-045 — monsters.json: at least 8 monster types (MON-009)
# ---------------------------------------------------------------------------

def test_monster_count_at_least_8_ldata045():
    """[LDATA-045] monsters.json shall contain at least 8 monster entries."""
    data = _load("monsters.json")
    monsters = data if isinstance(data, list) else data.get("monsters", [])
    assert len(monsters) >= 8, \
        f"[LDATA-045] Expected >= 8 monster types, found {len(monsters)}"


# ---------------------------------------------------------------------------
# LSPN-006 — suppression_pct exact values per tier
# ---------------------------------------------------------------------------

def test_suppression_pct_values_lspn006():
    """[LSPN-006] settlement_tiers.json shall define exact suppression_pct per tier."""
    data = _load("settlement_tiers.json")
    tiers = data if isinstance(data, list) else data.get("tiers", [])
    tier_by_index = {t["tier"]: t for t in tiers}
    expected = {1: 0.25, 2: 0.50, 3: 0.75, 4: 1.00}
    for tier_num, expected_pct in expected.items():
        if tier_num in tier_by_index:
            actual = tier_by_index[tier_num].get("suppression_pct")
            assert actual == expected_pct, \
                f"[LSPN-006] Tier {tier_num} suppression_pct: expected {expected_pct}, got {actual}"


# ---------------------------------------------------------------------------
# LSURV-028 — survival.json threshold sub-objects (SURV-005)
# ---------------------------------------------------------------------------

def test_survival_json_has_threshold_objects_lsurv028():
    """[LSURV-028] survival.json shall define hunger, thirst, temperature, fatigue sub-objects
    each with at least a low/warn threshold and a critical threshold."""
    data = _load("survival.json")
    for section in ("hunger", "thirst", "temperature", "fatigue"):
        assert section in data, \
            f"[LSURV-028] survival.json missing '{section}' sub-object"
        obj = data[section]
        # Must have some form of critical threshold
        has_crit = any(k for k in obj if "critical" in k or "crit" in k)
        assert has_crit, \
            f"[LSURV-028] survival.json['{section}'] missing a critical threshold key"
        # Must have some form of warn / low threshold
        has_warn = any(k for k in obj if "warn" in k or "low" in k or "threshold" in k)
        assert has_warn, \
            f"[LSURV-028] survival.json['{section}'] missing a warn/low threshold key"


# ---------------------------------------------------------------------------
# LCRAFT-027 — campfire_kit recipe requires wood (CAMP-003)
# ---------------------------------------------------------------------------

def test_campfire_kit_recipe_has_wood_lcraft027():
    """[LCRAFT-027] A campfire_kit recipe shall exist in recipes.json with wood as an ingredient."""
    data = _load("recipes.json")
    recipes = data if isinstance(data, list) else data.get("recipes", [])
    campfire = next((r for r in recipes if r.get("id") == "campfire_kit"), None)
    assert campfire is not None, \
        "[LCRAFT-027] No 'campfire_kit' recipe found in recipes.json"
    ingredients = campfire.get("ingredients", [])
    ingredient_ids = [i.get("item_id", "") for i in ingredients]
    has_wood = any("wood" in iid for iid in ingredient_ids)
    assert has_wood, \
        f"[LCRAFT-027] campfire_kit recipe has no wood ingredient; found: {ingredient_ids}"


# ---------------------------------------------------------------------------
# LCRAFT-028 — cooked food items have positive spoil_timer (CRAFT-005)
# ---------------------------------------------------------------------------

def test_cooked_food_has_spoil_timer_lcraft028():
    """[LCRAFT-028] Cooked meat and cooked fish shall have a positive spoil_timer in items.json."""
    data = _load("items.json")
    items = data if isinstance(data, list) else data.get("items", [])
    items_by_id = {i["id"]: i for i in items}

    for item_id in ("cooked_meat", "cooked_fish"):
        assert item_id in items_by_id, \
            f"[LCRAFT-028] '{item_id}' not found in items.json"
        spoil = items_by_id[item_id].get("spoil_timer", 0)
        assert spoil > 0, \
            f"[LCRAFT-028] '{item_id}' spoil_timer must be > 0, got {spoil}"


# ---------------------------------------------------------------------------
# LSCORE-007 — tier score thresholds are present and ascending in JSON
# ---------------------------------------------------------------------------

def test_score_thresholds_ascending_lscore007():
    """[LSCORE-007] settlement_tiers.json score_threshold values shall be ascending by tier."""
    data = _load("settlement_tiers.json")
    tiers = data if isinstance(data, list) else data.get("tiers", [])
    sorted_tiers = sorted(tiers, key=lambda t: t["tier"])
    thresholds = [t.get("score_threshold", 0) for t in sorted_tiers]
    for i in range(len(thresholds) - 1):
        assert thresholds[i] <= thresholds[i + 1], \
            f"[LSCORE-007] score_threshold not ascending: tier {i+1} ({thresholds[i]}) " \
            f">= tier {i+2} ({thresholds[i+1]})"
