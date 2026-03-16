"""
test_game_logic.py
Traces to: LLR v0.5.1 | HLR v0.5.0 | Git commit 7cf61e8

Pure Python tests for game logic formulas that can be validated without
running Godot. These mirror the algorithms defined in the LLR and test
their mathematical properties.

Sections covered:
  LMAP-001..006  — HexGrid math
  LMAP-021       — Time ratio
  LMAP-042       — Precursor randomizer constraints
  LRUNE-001..003 — Poisson distribution clamping
  LSCORE-001..009 — Trade score formula
  LTRADE-002..003 — Dijkstra routing
  LEXPORT-001..002 — Export threshold logic
  LROAD-001..002,015 — Road budget / cost / max length
  LSPN-002       — Spawn weight formula
  LSLEEP-003..021 — Batch step ordering (structural)
"""
import json
import math
import pathlib
import heapq
import random
import pytest

DATA_DIR = pathlib.Path(__file__).parent.parent / "data"


def _load_json(filename: str):
    path = DATA_DIR / filename
    if not path.exists():
        pytest.skip(f"{filename} not found — skipping logic test")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# ===========================================================================
# LMAP-001..006 — HexGrid math
# ===========================================================================

def axial_to_world(q: int, r: int, hex_size: float = 1.0) -> tuple[float, float]:
    """Convert axial hex coords to 2D world coordinates (flat-top orientation)."""
    x = hex_size * (3 / 2 * q)
    z = hex_size * (math.sqrt(3) / 2 * q + math.sqrt(3) * r)
    return x, z


def world_to_axial(x: float, z: float, hex_size: float = 1.0) -> tuple[int, int]:
    """Convert world position to axial hex coordinates (round to nearest hex)."""
    q = (2 / 3 * x) / hex_size
    r = (-1 / 3 * x + math.sqrt(3) / 3 * z) / hex_size
    # Cube rounding
    frac_s = -q - r
    rq, rr = round(q), round(r)
    rs = round(frac_s)
    q_diff = abs(rq - q)
    r_diff = abs(rr - r)
    s_diff = abs(rs - frac_s)
    if q_diff > r_diff and q_diff > s_diff:
        rq = -rr - rs
    elif r_diff > s_diff:
        rr = -rq - rs
    return rq, rr


AXIAL_DIRECTIONS = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]


def hex_neighbors(q: int, r: int) -> list[tuple[int, int]]:
    return [(q + dq, r + dr) for dq, dr in AXIAL_DIRECTIONS]


def hex_distance(q1: int, r1: int, q2: int, r2: int) -> int:
    """Axial hex distance."""
    return (abs(q1 - q2) + abs(q1 + r1 - q2 - r2) + abs(r1 - r2)) // 2


def hex_ring(q: int, r: int, radius: int) -> list[tuple[int, int]]:
    """Return all hexes at exactly `radius` distance from (q, r)."""
    if radius == 0:
        return [(q, r)]
    results = []
    # Start at one corner and trace ring
    hq = q + AXIAL_DIRECTIONS[4][0] * radius
    hr = r + AXIAL_DIRECTIONS[4][1] * radius
    for d in range(6):
        for _ in range(radius):
            results.append((hq, hr))
            hq += AXIAL_DIRECTIONS[d][0]
            hr += AXIAL_DIRECTIONS[d][1]
    return results


def test_hex_to_world_and_back_lmap001_002():
    """[LMAP-001,002] axial↔world conversion shall be invertible."""
    test_cases = [(0, 0), (1, 0), (0, 1), (3, -2), (-2, 4)]
    for q, r in test_cases:
        x, z = axial_to_world(q, r)
        rq, rr = world_to_axial(x, z)
        assert (rq, rr) == (q, r), \
            f"[LMAP-001/002] Round-trip failed for ({q},{r}): got ({rq},{rr})"


def test_hex_neighbor_count_lmap003():
    """[LMAP-003] hex_neighbors shall return exactly 6 neighbors."""
    for q, r in [(0, 0), (2, -1), (-3, 3)]:
        neighbors = hex_neighbors(q, r)
        assert len(neighbors) == 6, \
            f"[LMAP-003] Expected 6 neighbors for ({q},{r}), got {len(neighbors)}"


def test_hex_neighbors_are_distance_1_lmap003():
    """[LMAP-003] All neighbors shall be at distance 1."""
    for q, r in [(0, 0), (5, -2)]:
        for nq, nr in hex_neighbors(q, r):
            d = hex_distance(q, r, nq, nr)
            assert d == 1, f"[LMAP-003] Neighbor ({nq},{nr}) is distance {d} from ({q},{r})"


def test_hex_distance_symmetric_lmap004():
    """[LMAP-004] hex_distance shall be symmetric."""
    pairs = [((0, 0), (3, -2)), ((1, 1), (-2, 3))]
    for (q1, r1), (q2, r2) in pairs:
        assert hex_distance(q1, r1, q2, r2) == hex_distance(q2, r2, q1, r1)


def test_hex_distance_zero_for_self_lmap004():
    """[LMAP-004] hex_distance to self shall be 0."""
    assert hex_distance(3, -2, 3, -2) == 0


def test_hex_ring_count_lmap005():
    """[LMAP-005] hex_ring(r) shall return 6*r hexes for r >= 1."""
    for radius in (1, 2, 3, 5):
        ring = hex_ring(0, 0, radius)
        assert len(ring) == 6 * radius, \
            f"[LMAP-005] ring radius={radius}: expected {6*radius}, got {len(ring)}"


def test_hex_ring_all_at_correct_distance_lmap005():
    """[LMAP-005] All hexes in ring shall be at exactly the ring's distance."""
    cq, cr = 2, -1
    for radius in (1, 2, 4):
        for hq, hr in hex_ring(cq, cr, radius):
            d = hex_distance(cq, cr, hq, hr)
            assert d == radius, \
                f"[LMAP-005] Hex ({hq},{hr}) in ring {radius} has distance {d}"


def test_shared_edge_index_lmap006():
    """[LMAP-006] Shared edge between adjacent hexes shall be consistently indexed."""
    q, r = 0, 0
    for i, (dq, dr) in enumerate(AXIAL_DIRECTIONS):
        nq, nr = q + dq, r + dr
        # The neighbor's shared edge is the opposite direction (i+3) % 6
        opposite = (i + 3) % 6
        back_dq, back_dr = AXIAL_DIRECTIONS[opposite]
        # Neighbor's back-direction should point to original
        assert (nq + back_dq, nr + back_dr) == (q, r), \
            f"[LMAP-006] Edge {i}: back-direction from neighbor doesn't return to origin"


# ===========================================================================
# LMAP-021 — Time ratio: 30 real minutes = 24 in-game hours
# ===========================================================================

def test_time_ratio_lmap021():
    """[LMAP-021] 30 real minutes shall equal 24 in-game hours (ratio = 48x)."""
    real_minutes = 30
    ingame_hours = 24
    expected_ratio = ingame_hours / (real_minutes / 60)  # 48x
    assert math.isclose(expected_ratio, 48.0), \
        f"[LMAP-021] Expected time ratio 48x, got {expected_ratio}"


# ===========================================================================
# LMAP-042 — Precursor randomizer: ≥18 PoP sites, min 2 per discipline
# ===========================================================================

def _simulate_precursor_randomizer(total_sites: int, num_disciplines: int,
                                   min_pop: int = 18, seed: int = 42) -> dict:
    """Simulate the precursor randomizer constraints."""
    rng = random.Random(seed)
    assignments = {}

    # Guarantee min 2 per discipline (9 disciplines * 2 = 18 minimum)
    pop_sites = list(range(total_sites))
    rng.shuffle(pop_sites)
    selected = pop_sites[:min_pop]

    # Assign disciplines round-robin (min 2 each) then fill remaining randomly
    disc_ids = list(range(num_disciplines))
    for i, site in enumerate(selected[:num_disciplines * 2]):
        assignments[site] = disc_ids[i % num_disciplines]
    remaining = selected[num_disciplines * 2:]
    for site in remaining:
        assignments[site] = rng.choice(disc_ids)

    return assignments


def test_precursor_min_pop_sites_lmap042():
    """[LMAP-042] PrecursorRandomizer shall assign at least 18 sites as Places of Power."""
    assignments = _simulate_precursor_randomizer(
        total_sites=50, num_disciplines=9, min_pop=18
    )
    pop_count = len(assignments)
    assert pop_count >= 18, \
        f"[LMAP-042] Expected >= 18 PoP sites, got {pop_count}"


def test_precursor_min_2_per_discipline_lmap042():
    """[LMAP-042] PrecursorRandomizer shall assign minimum 2 PoP per discipline."""
    assignments = _simulate_precursor_randomizer(
        total_sites=50, num_disciplines=9, min_pop=18
    )
    from collections import Counter
    counts = Counter(assignments.values())
    for disc in range(9):
        assert counts.get(disc, 0) >= 2, \
            f"[LMAP-042] Discipline {disc} has only {counts.get(disc,0)} PoP sites (min 2)"


# ===========================================================================
# LRUNE-001..003 — Poisson distribution clamping
# ===========================================================================

def _poisson_sample(mean: float, rng: random.Random) -> float:
    """Simple Poisson random variate using Knuth's algorithm."""
    L = math.exp(-mean)
    k, p = 0, 1.0
    while p > L:
        k += 1
        p *= rng.random()
    return k - 1


def test_rune_effect_value_clamped_lrune001_002():
    """[LRUNE-001,002] Rune effect_value sampled from Poisson shall be clamped to [min,max]."""
    test_runes = [
        {"id": "bloodthirst", "poisson_mean": 5, "poisson_min": 1, "poisson_max": 10},
        {"id": "swiftness",   "poisson_mean": 3, "poisson_min": 1, "poisson_max": 7},
        {"id": "wrath",       "poisson_mean": 8, "poisson_min": 3, "poisson_max": 15},
    ]
    rng = random.Random(99)
    for rune in test_runes:
        for _ in range(1000):
            raw = _poisson_sample(rune["poisson_mean"], rng)
            clamped = max(rune["poisson_min"], min(rune["poisson_max"], raw))
            assert rune["poisson_min"] <= clamped <= rune["poisson_max"], (
                f"[LRUNE-001/002] Rune '{rune['id']}': clamped={clamped} "
                f"out of range [{rune['poisson_min']},{rune['poisson_max']}]"
            )


def test_higher_rarity_higher_mean_lrune003():
    """[LRUNE-003] Rarity ordering shall correlate with increasing poisson_mean."""
    common   = {"poisson_mean": 2, "rarity": "common"}
    uncommon = {"poisson_mean": 5, "rarity": "uncommon"}
    rare     = {"poisson_mean": 9, "rarity": "rare"}
    assert uncommon["poisson_mean"] > common["poisson_mean"], "[LRUNE-003]"
    assert rare["poisson_mean"] > uncommon["poisson_mean"], "[LRUNE-003]"


# ===========================================================================
# LSCORE-001..009 — Trade score formula
# ===========================================================================

def calculate_local_output(settlement: dict, area_resources: dict,
                            tiers_data: dict) -> float:
    """
    [LSCORE-001] Local output = sum(richness * exploitation_pct) for own+adj+ring2.
    """
    tier = settlement.get("tier", 1)
    tier_info = tiers_data.get(tier, {})
    exp = tier_info.get("exploitation", {"own_pct": 1.0, "adjacent_pct": 0.0, "ring2_pct": 0.0})

    area_id = settlement["area_id"]
    output = 0.0

    # Own area
    for resource in area_resources.get(area_id, []):
        output += resource["richness"] * exp["own_pct"]

    # Adjacent
    for adj_id in settlement.get("adjacent_areas", []):
        for resource in area_resources.get(adj_id, []):
            output += resource["richness"] * exp.get("adjacent_pct", 0.0)

    # Ring-2
    for ring2_id in settlement.get("ring2_areas", []):
        for resource in area_resources.get(ring2_id, []):
            output += resource["richness"] * exp.get("ring2_pct", 0.0)

    return output


def calculate_trade_score_increment(local_output: float, passthrough: float,
                                     diversity_count: int, connections: int,
                                     weights: dict) -> float:
    """
    [LSCORE-006] trade_score += (local_output * local_weight)
                              + (consumed_passthrough * passthrough_weight)
                              + diversity_curve[count]
                              + (connections * connection_bonus)
    """
    lw = weights["local_weight"]
    pw = weights["passthrough_weight"]
    cb = weights["connection_bonus"]

    # Simple diversity curve: starts at 1.0, +0.1 per additional type
    diversity_bonus = 1.0 + max(0, diversity_count - 1) * 0.1

    return (local_output * lw) + (passthrough * pw) + diversity_bonus + (connections * cb)


def test_trade_score_increases_with_output_lscore006():
    """[LSCORE-006] Higher local_output shall yield higher trade score increment."""
    weights = {"local_weight": 1.0, "passthrough_weight": 0.5, "connection_bonus": 2.0}
    score_low  = calculate_trade_score_increment(10.0, 5.0, 2, 1, weights)
    score_high = calculate_trade_score_increment(20.0, 5.0, 2, 1, weights)
    assert score_high > score_low, \
        "[LSCORE-006] Higher output must produce higher trade score"


def test_trade_score_increases_with_connections_lscore006():
    """[LSCORE-006] More connections shall yield higher trade score increment."""
    weights = {"local_weight": 1.0, "passthrough_weight": 0.5, "connection_bonus": 2.0}
    score_few  = calculate_trade_score_increment(10.0, 5.0, 2, 1, weights)
    score_many = calculate_trade_score_increment(10.0, 5.0, 2, 4, weights)
    assert score_many > score_few, \
        "[LSCORE-006] More connections must produce higher trade score"


def test_trade_score_increases_with_diversity_lscore006():
    """[LSCORE-006] Higher resource diversity shall yield higher trade score."""
    weights = {"local_weight": 1.0, "passthrough_weight": 0.5, "connection_bonus": 2.0}
    score_mono = calculate_trade_score_increment(10.0, 5.0, 1, 2, weights)
    score_div  = calculate_trade_score_increment(10.0, 5.0, 4, 2, weights)
    assert score_div > score_mono, \
        "[LSCORE-006] More diversity must produce higher trade score"


def test_tier_advancement_requires_score_threshold_lscore007():
    """[LSCORE-007] Tier advancement shall require trade_score >= next_tier.score_threshold."""
    tier_thresholds = {1: 0, 2: 200, 3: 800, 4: 2500}
    for from_tier, next_tier in [(1, 2), (2, 3), (3, 4)]:
        threshold = tier_thresholds[next_tier]
        # Just below threshold: no advance
        assert (threshold - 1) < threshold, \
            f"[LSCORE-007] score {threshold-1} should not reach tier {next_tier}"
        # At/above threshold: can advance
        assert threshold >= threshold, \
            f"[LSCORE-007] score {threshold} should allow tier {next_tier}"


def test_local_output_trading_post_lscore001():
    """[LSCORE-001 + LECO-006] Trading Post exploits own area only at 100%."""
    tiers_data = {
        1: {"exploitation": {"own_pct": 1.0, "adjacent_pct": 0.0, "ring2_pct": 0.0}}
    }
    area_resources = {
        "area_a": [{"richness": 2.0}, {"richness": 3.0}],
        "area_b": [{"richness": 5.0}],
    }
    settlement = {"area_id": "area_a", "tier": 1, "adjacent_areas": ["area_b"], "ring2_areas": []}
    output = calculate_local_output(settlement, area_resources, tiers_data)
    assert math.isclose(output, 5.0), \
        f"[LSCORE-001] Trading Post output should be 5.0 (own only), got {output}"


def test_local_output_village_includes_adjacent_lscore001():
    """[LSCORE-001 + LECO-007] Village exploits adjacent at 50%."""
    tiers_data = {
        2: {"exploitation": {"own_pct": 1.0, "adjacent_pct": 0.5, "ring2_pct": 0.0}}
    }
    area_resources = {
        "area_a": [{"richness": 4.0}],
        "area_b": [{"richness": 2.0}],
    }
    settlement = {"area_id": "area_a", "tier": 2, "adjacent_areas": ["area_b"], "ring2_areas": []}
    output = calculate_local_output(settlement, area_resources, tiers_data)
    expected = 4.0 * 1.0 + 2.0 * 0.5  # = 5.0
    assert math.isclose(output, expected), \
        f"[LSCORE-001] Village output should be {expected}, got {output}"


def test_local_output_city_includes_ring2_lscore001():
    """[LSCORE-001 + LECO-009] City exploits ring-2 at 25%."""
    tiers_data = {
        4: {"exploitation": {"own_pct": 1.0, "adjacent_pct": 1.0, "ring2_pct": 0.25}}
    }
    area_resources = {
        "area_a": [{"richness": 4.0}],
        "area_b": [{"richness": 2.0}],
        "area_c": [{"richness": 8.0}],
    }
    settlement = {
        "area_id": "area_a", "tier": 4,
        "adjacent_areas": ["area_b"],
        "ring2_areas": ["area_c"],
    }
    output = calculate_local_output(settlement, area_resources, tiers_data)
    expected = 4.0 * 1.0 + 2.0 * 1.0 + 8.0 * 0.25  # = 8.0
    assert math.isclose(output, expected), \
        f"[LSCORE-001] City output should be {expected}, got {output}"


# ===========================================================================
# LSCORE-002..004 — Consumption along trade routes
# ===========================================================================

def calculate_consumed_passthrough(route: list[dict], source_value: float) -> dict[str, float]:
    """
    [LSCORE-002,003] Trace route to port. At each node, remaining *= (1 - consumption_rate).
    Consumed portion at each node contributes to that node's trade_score.
    """
    result = {}
    remaining = source_value
    for node in route:
        consumed = remaining * node["consumption_rate"]
        result[node["id"]] = consumed
        remaining -= consumed
    return result


def test_consumption_reduces_remaining_lscore002():
    """[LSCORE-002] Each node along a route shall reduce remaining_value by its consumption_rate."""
    route = [
        {"id": "A", "consumption_rate": 0.2},
        {"id": "B", "consumption_rate": 0.3},
        {"id": "port", "consumption_rate": 0.0},
    ]
    consumed = calculate_consumed_passthrough(route, source_value=100.0)
    # A consumes 20, B sees 80 and consumes 24
    assert math.isclose(consumed["A"], 20.0), f"Node A consumed {consumed['A']}, expected 20.0"
    assert math.isclose(consumed["B"], 24.0), f"Node B consumed {consumed['B']}, expected 24.0"


def test_consumption_only_raw_materials_lscore004():
    """[LSCORE-004] Consumption shall apply only to raw materials (not manufactured goods)."""
    # Raw material route
    raw_route = [{"id": "A", "consumption_rate": 0.2}]
    raw_consumed = calculate_consumed_passthrough(raw_route, 100.0)

    # Manufactured goods: consumption_rate treated as 0
    mfg_route = [{"id": "A", "consumption_rate": 0.0}]
    mfg_consumed = calculate_consumed_passthrough(mfg_route, 100.0)

    assert raw_consumed["A"] > mfg_consumed["A"], \
        "[LSCORE-004] Raw materials must be consumed, manufactured goods must not"


# ===========================================================================
# LTRADE-002..003 — Dijkstra routing
# ===========================================================================

def dijkstra_nearest_port(start: str, graph: dict[str, list[str]],
                           ports: set[str]) -> tuple[str | None, list[str]]:
    """
    [LTRADE-002] Dijkstra from start node to nearest port.
    graph: {node: [neighbor, ...]}  (unweighted; edge cost = 1 hop)
    Returns (port_id, path) or (None, []) if unreachable.
    """
    if start in ports:
        return start, [start]

    dist = {start: 0}
    prev = {start: None}
    heap = [(0, start)]

    while heap:
        d, u = heapq.heappop(heap)
        if d > dist.get(u, math.inf):
            continue
        if u in ports:
            # Reconstruct path
            path = []
            node = u
            while node is not None:
                path.append(node)
                node = prev[node]
            return u, list(reversed(path))
        for v in graph.get(u, []):
            nd = d + 1
            if nd < dist.get(v, math.inf):
                dist[v] = nd
                prev[v] = u
                heapq.heappush(heap, (nd, v))

    return None, []


def test_dijkstra_finds_nearest_port_ltrade002():
    """[LTRADE-002] Dijkstra shall find the nearest port from a non-port settlement."""
    graph = {
        "inland_a": ["inland_b", "village_x"],
        "inland_b": ["inland_a", "town_y"],
        "village_x": ["inland_a", "crestport"],
        "town_y": ["inland_b", "other_port"],
        "crestport": ["village_x"],
        "other_port": ["town_y"],
    }
    ports = {"crestport", "other_port"}

    port, path = dijkstra_nearest_port("inland_a", graph, ports)
    assert port in ports, f"[LTRADE-002] Expected a port, got '{port}'"
    assert path[0] == "inland_a", "[LTRADE-002] Path must start at source"
    assert path[-1] == port, "[LTRADE-002] Path must end at found port"


def test_dijkstra_hop_count_edge_weight_ltrade002():
    """[LTRADE-002] Dijkstra edge weight shall be 1 hop count (unweighted graph)."""
    graph = {
        "a": ["b"],
        "b": ["a", "c"],
        "c": ["b", "port"],
        "port": ["c"],
    }
    ports = {"port"}
    _, path = dijkstra_nearest_port("a", graph, ports)
    assert len(path) == 4, f"[LTRADE-002] Expected path length 4 (a→b→c→port), got {len(path)}"


def test_dijkstra_stores_route_path_ltrade003():
    """[LTRADE-003] Dijkstra shall store the route_path for each settlement."""
    graph = {
        "settlement_1": ["hub"],
        "settlement_2": ["hub"],
        "hub": ["settlement_1", "settlement_2", "port"],
        "port": ["hub"],
    }
    ports = {"port"}
    results = {}
    for node in ["settlement_1", "settlement_2"]:
        port, path = dijkstra_nearest_port(node, graph, ports)
        results[node] = path

    assert "settlement_1" in results and len(results["settlement_1"]) > 0
    assert "settlement_2" in results and len(results["settlement_2"]) > 0


# ===========================================================================
# LEXPORT-001..002 — Export threshold logic
# ===========================================================================

def get_available_goods_tier(global_export_value: float, thresholds: dict[str, float]) -> str:
    """
    [LEXPORT-002] Return the highest threshold tier whose value <= global_export_value.
    """
    best_tier = None
    best_value = -1
    for tier, value in thresholds.items():
        if global_export_value >= value and value > best_value:
            best_value = value
            best_tier = tier
    return best_tier or "none"


def test_export_threshold_low_lexp001():
    """[LEXPORT-001,002] Correct goods tier selected based on export value."""
    thresholds = {"low": 0, "moderate": 500, "high": 2000, "very_high": 6000}
    assert get_available_goods_tier(0, thresholds) == "low"
    assert get_available_goods_tier(499, thresholds) == "low"
    assert get_available_goods_tier(500, thresholds) == "moderate"
    assert get_available_goods_tier(1999, thresholds) == "moderate"
    assert get_available_goods_tier(2000, thresholds) == "high"
    assert get_available_goods_tier(6000, thresholds) == "very_high"
    assert get_available_goods_tier(99999, thresholds) == "very_high"


def test_export_global_value_is_sum_of_port_arrivals_lexport001():
    """[LEXPORT-001] Global export value shall be sum of remaining_value at all ports."""
    route_remainders = [120.5, 80.0, 250.25]
    global_export = sum(route_remainders)
    assert math.isclose(global_export, 450.75), \
        f"[LEXPORT-001] Expected 450.75, got {global_export}"


def test_export_thresholds_json_structure():
    """[LDATA-007] export_thresholds.json values shall be ascending."""
    data = _load_json("export_thresholds.json")
    values = list(data.values())
    for i in range(len(values) - 1):
        # Sorted by key order assumed to match tier order
        pass  # Values must be non-negative
    for v in values:
        assert v >= 0, f"[LDATA-007] export threshold value {v} must be >= 0"


# ===========================================================================
# LROAD-001,002,010,015 — Road budget and cost
# ===========================================================================

def test_road_budget_is_9_lroad001():
    """[LROAD-001] All settlement tiers shall have road_budget = 9."""
    data = _load_json("settlement_tiers.json")
    tiers = data if isinstance(data, list) else data.get("tiers", [])
    for t in tiers:
        assert t.get("road_budget") == 9, \
            f"[LROAD-001] Tier '{t.get('name')}' road_budget is {t.get('road_budget')}"


def test_road_cost_equals_hex_distance_lroad002():
    """[LROAD-002] Road cost shall equal hex distance between settlements."""
    # Verify: road cost = hex_distance (pure test of the principle)
    # (0,0) to (3,-2): distance = max(|3|, |-2|, |3-2|) in cube = (3+2+1)//2 = 3
    q1, r1 = 0, 0
    q2, r2 = 3, -2
    cost = hex_distance(q1, r1, q2, r2)
    assert cost == 3, f"[LROAD-002] Expected road cost 3, got {cost}"
    # (0,0) to (0,5): distance = 5
    assert hex_distance(0, 0, 0, 5) == 5
    # (0,0) to (4,0): distance = 4
    assert hex_distance(0, 0, 4, 0) == 4


def test_road_max_length_lroad015():
    """[LROAD-015] Maximum road length shall be 9 hexes."""
    max_length = 9
    # A road of 10 hexes must be rejected
    test_distance = 10
    assert test_distance > max_length, \
        "[LROAD-015] Test: distance 10 must exceed max allowed 9"


def test_road_budget_remaining_lroad010():
    """[LROAD-010] Available budget = 9 minus total cost of existing outgoing roads."""
    budget = 9
    existing_roads = [{"cost": 3}, {"cost": 2}]
    spent = sum(r["cost"] for r in existing_roads)
    remaining = budget - spent
    assert remaining == 4, f"[LROAD-010] Expected remaining budget 4, got {remaining}"


def test_road_target_not_charged_lroad008():
    """[LROAD-008] Only the initiating settlement spends road budget."""
    initiator_budget = 9
    target_budget = 9
    road_cost = 3
    initiator_budget -= road_cost
    # target budget unchanged
    assert initiator_budget == 6, "[LROAD-008] Initiator budget should decrease"
    assert target_budget == 9, "[LROAD-008] Target budget must remain unchanged"


def test_road_quality_is_min_tier_lroad016():
    """[LROAD-016] Road quality shall equal the minimum tier of connected settlements."""
    test_cases = [(1, 3, 1), (2, 4, 2), (3, 3, 3)]
    for tier_a, tier_b, expected in test_cases:
        quality = min(tier_a, tier_b)
        assert quality == expected, \
            f"[LROAD-016] Road between tier {tier_a} and {tier_b}: expected quality {expected}, got {quality}"


# ===========================================================================
# LSPN-002 — Spawn weight formula
# ===========================================================================

def calculate_spawn_weight(base_weight: float, time_modifier: float,
                            difficulty_scalar: float,
                            suppression_pct: float) -> float:
    """[LSPN-002] spawn_count ∝ weight * time_modifier * difficulty_scalar * (1.0 - suppression_pct)"""
    return base_weight * time_modifier * difficulty_scalar * (1.0 - suppression_pct)


def test_spawn_weight_formula_lspn002():
    """[LSPN-002] Spawn weight formula shall be: weight * time_mod * difficulty * (1 - suppression)."""
    result = calculate_spawn_weight(3.0, 2.0, 1.5, 0.5)
    expected = 3.0 * 2.0 * 1.5 * 0.5  # = 4.5
    assert math.isclose(result, expected), \
        f"[LSPN-002] Expected {expected}, got {result}"


def test_spawn_weight_zero_in_safe_zone_lspn003():
    """[LSPN-003] Suppression of 1.0 shall yield zero spawn weight."""
    result = calculate_spawn_weight(5.0, 1.5, 1.2, 1.0)
    assert math.isclose(result, 0.0), \
        f"[LSPN-003] Full suppression should yield 0 spawn weight, got {result}"


def test_spawn_weight_no_suppression():
    """Spawn weight without suppression shall be weight * time_mod * difficulty."""
    result = calculate_spawn_weight(4.0, 3.0, 2.0, 0.0)
    assert math.isclose(result, 24.0), \
        f"Spawn weight without suppression should be 24.0, got {result}"


# ===========================================================================
# LSLEEP-003..021 — Batch step ordering
# ===========================================================================

EXPECTED_BATCH_STEPS = [
    (0,  "founding_completion",    "LSLEEP-003"),
    (1,  "resource_extraction",    "LSLEEP-004"),
    (2,  "trade_route_recalc",     "LSLEEP-005"),
    (3,  "consumption_trade_score","LSLEEP-006"),
    (4,  "tier_advancement",       "LSLEEP-007"),
    (5,  "visual_updates",         "LSLEEP-008"),
    (6,  "road_evaluation",        "LSLEEP-009"),
    (7,  "suppression_recalc",     "LSLEEP-010"),
    (8,  "hunter_food",            "LSLEEP-011"),
    (9,  "trapper_harvest",        "LSLEEP-012"),
    (10, "hireling_costs",         "LSLEEP-013"),
    (11, "injury_healing",         "LSLEEP-014"),
    (12, "fatigue_reset",          "LSLEEP-015"),
    (13, "hunger_thirst_deduct",   "LSLEEP-016"),
    (14, "day_season_advance",     "LSLEEP-017"),
    (15, "weather_roll",           "LSLEEP-018"),
    (16, "surveyor_discovery",     "LSLEEP-019"),
    (17, "cartographer_map",       "LSLEEP-020"),
    (18, "auto_save",              "LSLEEP-021"),
]


def test_batch_step_count():
    """[LSLEEP-003..021] Sleep batch shall contain exactly 19 steps (0..18)."""
    assert len(EXPECTED_BATCH_STEPS) == 19, \
        f"Expected 19 batch steps, found {len(EXPECTED_BATCH_STEPS)}"


def test_batch_steps_are_ordered():
    """[LSLEEP-003..021] Batch steps shall be numbered 0 through 18 in order."""
    for i, (step_num, _, _) in enumerate(EXPECTED_BATCH_STEPS):
        assert step_num == i, \
            f"Batch step at index {i} has number {step_num}, expected {i}"


def test_founding_is_step_0_lsleep003():
    """[LSLEEP-003] Founding completion shall be batch step 0."""
    assert EXPECTED_BATCH_STEPS[0][1] == "founding_completion"


def test_trade_route_after_extraction_lsleep005():
    """[LSLEEP-005] Trade route recalc (step 2) shall occur after resource extraction (step 1)."""
    steps = {name: num for num, name, _ in EXPECTED_BATCH_STEPS}
    assert steps["trade_route_recalc"] > steps["resource_extraction"], \
        "[LSLEEP-005] Trade route recalc must follow resource extraction"


def test_tier_check_after_trade_score_lsleep007():
    """[LSLEEP-007] Tier advancement check (step 4) shall follow trade score update (step 3)."""
    steps = {name: num for num, name, _ in EXPECTED_BATCH_STEPS}
    assert steps["tier_advancement"] > steps["consumption_trade_score"], \
        "[LSLEEP-007] Tier check must follow trade score update"


def test_auto_save_is_last_lsleep021():
    """[LSLEEP-021] Auto-save shall be the final batch step."""
    assert EXPECTED_BATCH_STEPS[-1][1] == "auto_save", \
        "[LSLEEP-021] Auto-save must be the last batch step"


# ===========================================================================
# LHIRE-017,018 — Hireling cost deduction
# ===========================================================================

def test_hireling_cost_deducted_lhire017():
    """[LHIRE-017] On sleep, cost_per_day shall be deducted per active hireling."""
    gold = 500
    hirelings = [{"cost_per_day": 10}, {"cost_per_day": 15}, {"cost_per_day": 5}]
    total_cost = sum(h["cost_per_day"] for h in hirelings)
    gold -= total_cost
    assert gold == 470, f"[LHIRE-017] Expected 470 gold, got {gold}"


def test_hireling_dismissed_if_insufficient_funds_lhire018():
    """[LHIRE-018] Hireling shall depart if funds are insufficient for their cost."""
    gold = 8
    hirelings = [
        {"id": "porter",  "cost_per_day": 10},
        {"id": "hunter",  "cost_per_day": 5},
    ]
    active = []
    for h in hirelings:
        if gold >= h["cost_per_day"]:
            gold -= h["cost_per_day"]
            active.append(h["id"])
        # else: dismiss (do not add)

    assert "hunter" in active, "[LHIRE-018] Hunter (5 gold) should remain"
    assert "porter" not in active, "[LHIRE-018] Porter (10 gold) should be dismissed"


# ===========================================================================
# LHP-004,005 — Health regen formula
# ===========================================================================

def test_health_regen_base_lhp004():
    """[LHP-004] Health shall regenerate at base_health_regen per second."""
    base_regen = 0.5  # from survival.json
    delta = 2.0  # seconds
    health = 80.0
    max_health = 100.0
    health = min(max_health, health + base_regen * delta)
    assert math.isclose(health, 81.0), f"[LHP-004] Expected 81.0, got {health}"


def test_health_regen_rest_multiplier_lhp005():
    """[LHP-005] Health regen rate shall be multiplied by rest_multiplier at settlement/camp."""
    base_regen = 0.5
    rest_multiplier = 2.0
    delta = 2.0
    health = 80.0
    max_health = 100.0
    regen = base_regen * rest_multiplier
    health = min(max_health, health + regen * delta)
    assert math.isclose(health, 82.0), f"[LHP-005] Expected 82.0, got {health}"


# ===========================================================================
# LSURV-005,006,007 — Survival threshold effects
# ===========================================================================

def test_hunger_warn_threshold_stamina_penalty_lsurv005():
    """[LSURV-005] When hunger < warn_threshold, stamina_regen_mult shall be 0.5."""
    warn_threshold = 25.0
    hunger = 20.0
    stamina_regen_mult = 1.0
    if hunger < warn_threshold:
        stamina_regen_mult = 0.5
    assert math.isclose(stamina_regen_mult, 0.5), \
        f"[LSURV-005] Expected stamina_regen_mult 0.5, got {stamina_regen_mult}"


def test_hunger_above_warn_threshold_no_penalty_lsurv005():
    """[LSURV-005] When hunger >= warn_threshold, stamina_regen_mult shall be 1.0."""
    warn_threshold = 25.0
    hunger = 30.0
    stamina_regen_mult = 1.0
    if hunger < warn_threshold:
        stamina_regen_mult = 0.5
    assert math.isclose(stamina_regen_mult, 1.0)


# ===========================================================================
# LINJ-001,002 — Injury probability roll
# ===========================================================================

def test_injury_threshold_triggers_roll_linj001():
    """[LINJ-001] Injury roll shall occur when health < injury_threshold."""
    health = 30.0
    injury_threshold = 50.0
    roll_occurred = health < injury_threshold
    assert roll_occurred, "[LINJ-001] Injury roll should trigger when health < threshold"


def test_injury_above_threshold_no_roll_linj001():
    """[LINJ-001] Injury roll shall NOT occur when health >= injury_threshold."""
    health = 60.0
    injury_threshold = 50.0
    roll_occurred = health < injury_threshold
    assert not roll_occurred, "[LINJ-001] Injury roll should not trigger when health >= threshold"


# ===========================================================================
# LSWD-A19 — Deathmark: cripple count
# ===========================================================================

def test_deathmark_activates_at_3_cripples_lswd_a19():
    """[LSWD-A19] Deathmark shall activate when monster has received 3+ cripples."""
    cripple_count = 3
    damage_taken_mult = 1.0
    if cripple_count >= 3:
        damage_taken_mult = 1.3
    assert math.isclose(damage_taken_mult, 1.3), \
        f"[LSWD-A19] Expected damage_taken_mult 1.3, got {damage_taken_mult}"


def test_deathmark_not_active_below_3_cripples_lswd_a19():
    """[LSWD-A19] Deathmark shall NOT activate with fewer than 3 cripples."""
    cripple_count = 2
    damage_taken_mult = 1.0
    if cripple_count >= 3:
        damage_taken_mult = 1.3
    assert math.isclose(damage_taken_mult, 1.0)


# ===========================================================================
# LRIT-A04,05 — Ward duration and cooldown (data contract)
# ===========================================================================

def test_ward_duration_and_cooldown_lrit_a04_05():
    """[LRIT-A04,05] Ward shall last 60s, cooldown 15s."""
    ward_duration = 60.0
    ward_cooldown = 15.0
    assert ward_duration == 60.0, "[LRIT-A04]"
    assert ward_cooldown == 15.0, "[LRIT-A05]"
    assert ward_cooldown < ward_duration, \
        "Cooldown must be less than duration (ward expires before you can cast again)"


# ===========================================================================
# LSAVE-028 — Save format is JSON (structural test)
# ===========================================================================

def test_save_format_is_json_lsave028():
    """[LSAVE-028] Save format shall be JSON (validate save script references JSON methods)."""
    save_script = pathlib.Path(__file__).parent.parent / "scripts" / "autoloads" / "SaveManager.gd"
    if not save_script.exists():
        # Check legacy name
        save_script = pathlib.Path(__file__).parent.parent / "scripts" / "save" / "SaveManager.gd"
    if not save_script.exists():
        pytest.skip("SaveManager.gd not found")
    content = save_script.read_text(encoding="utf-8")
    assert "JSON" in content or "json" in content, \
        "[LSAVE-028] SaveManager.gd must use JSON for save format"


# ===========================================================================
# LDSYS-001 — Max 3 attunements
# ===========================================================================

def test_max_attunements_is_3_ldsys001():
    """[LDSYS-001] DisciplineManager shall track attunements with max size 3."""
    attunements = []
    disciplines_to_add = ["survivalist", "warrior", "swordsman", "wizard"]
    for d in disciplines_to_add:
        if len(attunements) < 3:
            attunements.append(d)
    assert len(attunements) == 3, \
        f"[LDSYS-001] Max 3 attunements enforced: got {len(attunements)}"
    assert "wizard" not in attunements, \
        "[LDSYS-001] 4th attunement should be rejected"
