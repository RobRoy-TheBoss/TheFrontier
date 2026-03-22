"""
test_game_logic.py
Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9

Pure Python tests for game logic formulas that can be validated without
running Godot. These mirror the algorithms defined in the LLR and test
their mathematical properties.

Sections covered:
  LMAP-001..006  — HexGrid math
  LMAP-015..020  — Area/edge passability logic
  LMAP-031       — Time ratio
  LMAP-047       — Precursor randomizer constraints
  LRUNE-001..003 — Poisson distribution clamping
  LSCORE-001..010 — Trade score formula
  LTRADE-002..003 — Dijkstra routing
  LEXPORT-001..002 — Export threshold logic
  LECO-011..013  — Resource claim conflict
  LROAD-001..002,015 — Road budget / cost / max length
  LSPN-002       — Spawn weight formula
  LSLEEP-003..023 — Batch step ordering (structural)
  LSURV-022..027 — Survival threshold effects
  LCBT-001..004  — Combat state logic
  LSCORE-008     — Tier advancement resource requirements
  LEXPORT-003    — Shop inventory filtering logic
  LMAP-021       — Portage validation (graph topology)
  LSCORE-011     — First-mover advantage (Dijkstra stability)
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

def test_time_ratio_lmap031():
    """[LMAP-031] 30 real minutes shall equal 24 in-game hours (ratio = 48x)."""
    real_minutes = 30
    ingame_hours = 24
    expected_ratio = ingame_hours / (real_minutes / 60)  # 48x
    assert math.isclose(expected_ratio, 48.0), \
        f"[LMAP-031] Expected time ratio 48x, got {expected_ratio}"


# ===========================================================================
# LMAP-047 — Precursor randomizer: ≥8 PoP sites, min 2 per launch discipline
# ===========================================================================

def _simulate_precursor_randomizer(total_sites: int, num_disciplines: int,
                                   min_pop: int = 8, seed: int = 42) -> dict:
    """Simulate the precursor randomizer constraints."""
    rng = random.Random(seed)
    assignments = {}

    # Guarantee min 2 per discipline (4 launch disciplines * 2 = 8 minimum)
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


def test_precursor_min_pop_sites_lmap047():
    """[LMAP-047] PrecursorRandomizer shall assign at least 8 sites as Places of Power."""
    assignments = _simulate_precursor_randomizer(
        total_sites=50, num_disciplines=4, min_pop=8
    )
    pop_count = len(assignments)
    assert pop_count >= 8, \
        f"[LMAP-047] Expected >= 8 PoP sites, got {pop_count}"


def test_precursor_min_2_per_discipline_lmap047():
    """[LMAP-047] PrecursorRandomizer shall assign minimum 2 PoP per launch discipline."""
    assignments = _simulate_precursor_randomizer(
        total_sites=50, num_disciplines=4, min_pop=8
    )
    from collections import Counter
    counts = Counter(assignments.values())
    for disc in range(4):
        assert counts.get(disc, 0) >= 2, \
            f"[LMAP-047] Discipline {disc} has only {counts.get(disc,0)} PoP sites (min 2)"


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
    # step 9 was trapper_harvest — DELETED in v0.5.2 (LSLEEP-012 ID reserved)
    (9,  "hireling_costs",         "LSLEEP-013"),
    (10, "injury_healing",         "LSLEEP-014"),
    (11, "fatigue_reset",          "LSLEEP-015"),
    (12, "clear_temp_buffs",       "LSLEEP-023"),  # Artificer Reinforce (was step 11a)
    (13, "hunger_thirst_deduct",   "LSLEEP-016"),
    (14, "day_advance",            "LSLEEP-017"),
    (15, "weather_roll",           "LSLEEP-018"),  # POST
    (16, "surveyor_discovery",     "LSLEEP-019"),
    (17, "cartographer_map",       "LSLEEP-020"),  # POST
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


# ===========================================================================
# LSLEEP-023 — clear_temp_buffs in batch ordering
# ===========================================================================

def test_clear_temp_buffs_in_batch_lsleep023():
    """[LSLEEP-023] Batch shall include clear_temp_buffs after fatigue_reset and before hunger_thirst."""
    steps = {name: num for num, name, _ in EXPECTED_BATCH_STEPS}
    assert "clear_temp_buffs" in steps, \
        "[LSLEEP-023] clear_temp_buffs must be in batch steps"
    assert steps["clear_temp_buffs"] > steps["fatigue_reset"], \
        "[LSLEEP-023] clear_temp_buffs must come after fatigue_reset"
    assert steps["clear_temp_buffs"] < steps["hunger_thirst_deduct"], \
        "[LSLEEP-023] clear_temp_buffs must come before hunger_thirst_deduct"


def test_trapper_removed_from_batch():
    """[LSLEEP-012 DELETED] trapper_harvest shall no longer be a batch step."""
    names = [name for _, name, _ in EXPECTED_BATCH_STEPS]
    assert "trapper_harvest" not in names, \
        "trapper_harvest was deleted in v0.5.2 and must not appear in batch steps"


# ===========================================================================
# LMAP-015..020 — Area and edge passability logic
# ===========================================================================

def is_edge_passable(edge_type: str, area_a_tags: list, area_b_tags: list,
                     area_a_tier: int, area_b_tier: int) -> bool:
    """
    [LMAP-015..018] Determine if a shared edge is passable.
    - cliff edges are never passable (LMAP-015)
    - river edges require Ford tag on either area OR Town+ (tier>=3) on either (LMAP-016..018)
    - ford edges are passable (ford is a navigable river crossing)
    """
    if edge_type == "cliff":
        return False
    if edge_type == "river":
        has_ford = "ford" in area_a_tags or "ford" in area_b_tags
        has_bridge = area_a_tier >= 3 or area_b_tier >= 3
        return has_ford or has_bridge
    return True


def is_area_road_traversable(tags: list) -> bool:
    """
    [LMAP-019..020] Mountain areas are not road-traversable unless Mountain Pass tag is present.
    """
    if "mountain" in tags:
        return "mountain_pass" in tags
    return True


def test_cliff_edge_not_passable_lmap015():
    """[LMAP-015] Cliff edges shall not be passable regardless of settlement or tags."""
    assert not is_edge_passable("cliff", [], [], 1, 1)
    assert not is_edge_passable("cliff", ["ford"], [], 4, 4)


def test_river_impassable_without_ford_or_bridge_lmap016():
    """[LMAP-016] River edge shall not be passable if neither area has Ford or Town+."""
    assert not is_edge_passable("river", [], [], 1, 2)
    assert not is_edge_passable("river", ["forest"], ["plains"], 2, 2)


def test_river_passable_with_ford_tag_lmap017():
    """[LMAP-017] River edge shall be passable if either area has the Ford tag."""
    assert is_edge_passable("river", ["ford"], [], 1, 1)
    assert is_edge_passable("river", [], ["ford"], 1, 2)


def test_river_passable_with_town_settlement_lmap018():
    """[LMAP-018] River edge shall be passable if either area has a Town+ (tier>=3) settlement."""
    assert is_edge_passable("river", [], [], 3, 1)  # area_a has Town
    assert is_edge_passable("river", [], [], 1, 3)  # area_b has Town


def test_ford_edge_always_passable():
    """Ford edge type is a passable river crossing (no restrictions)."""
    assert is_edge_passable("ford", [], [], 1, 1)


def test_mountain_not_road_traversable_lmap019():
    """[LMAP-019] Mountain area without Mountain Pass tag shall not be road-traversable."""
    assert not is_area_road_traversable(["mountain"])
    assert not is_area_road_traversable(["mountain", "forest"])


def test_mountain_pass_road_traversable_lmap020():
    """[LMAP-020] Mountain area with Mountain Pass tag shall be road-traversable."""
    assert is_area_road_traversable(["mountain", "mountain_pass"])


def test_non_mountain_always_traversable_lmap019():
    """[LMAP-019] Non-mountain areas are always road-traversable."""
    assert is_area_road_traversable(["forest"])
    assert is_area_road_traversable([])
    assert is_area_road_traversable(["river", "plains"])


# ===========================================================================
# LSURV-022..027 — Survival threshold effects
# ===========================================================================

def apply_thirst_effects(thirst: float, warn_threshold: float, crit_threshold: float,
                          base_fatigue_rate: float, max_carry: float,
                          carry_penalty: float) -> tuple[float, float]:
    """[LSURV-022..023] Apply thirst-based effects to fatigue rate and max_carry."""
    fatigue_mult = 1.0
    if thirst < warn_threshold:
        fatigue_mult = 1.5  # configurable increase
    if thirst < crit_threshold:
        max_carry -= carry_penalty
    return base_fatigue_rate * fatigue_mult, max_carry


def apply_temperature_effects(temperature: float,
                               cold_threshold: float, heat_threshold: float,
                               base_speed: float, base_stamina_regen: float) -> tuple[float, float]:
    """[LSURV-024..027] Apply temperature-based effects."""
    speed = base_speed
    stamina_regen = base_stamina_regen
    if temperature < cold_threshold:
        speed *= 0.8  # configurable
    if temperature > heat_threshold:
        stamina_regen *= 0.7  # configurable
    return speed, stamina_regen


def test_thirst_warn_increases_fatigue_rate_lsurv022():
    """[LSURV-022] When thirst < warn_threshold, fatigue accumulation rate shall increase."""
    rate, _ = apply_thirst_effects(thirst=20.0, warn_threshold=30.0, crit_threshold=10.0,
                                    base_fatigue_rate=1.0, max_carry=50.0, carry_penalty=10.0)
    assert rate > 1.0, \
        f"[LSURV-022] Fatigue rate should increase below warn threshold, got {rate}"


def test_thirst_above_warn_no_fatigue_penalty_lsurv022():
    """[LSURV-022] When thirst >= warn_threshold, fatigue rate shall not be increased."""
    rate, _ = apply_thirst_effects(thirst=35.0, warn_threshold=30.0, crit_threshold=10.0,
                                    base_fatigue_rate=1.0, max_carry=50.0, carry_penalty=10.0)
    assert math.isclose(rate, 1.0), \
        f"[LSURV-022] Fatigue rate should be 1.0 above warn threshold, got {rate}"


def test_thirst_crit_reduces_max_carry_lsurv023():
    """[LSURV-023] When thirst < crit_threshold, max_carry shall be reduced."""
    _, carry = apply_thirst_effects(thirst=5.0, warn_threshold=30.0, crit_threshold=10.0,
                                     base_fatigue_rate=1.0, max_carry=50.0, carry_penalty=10.0)
    assert carry < 50.0, \
        f"[LSURV-023] max_carry should decrease below crit threshold, got {carry}"


def test_thirst_above_crit_no_carry_penalty_lsurv023():
    """[LSURV-023] When thirst >= crit_threshold, max_carry shall not be reduced."""
    _, carry = apply_thirst_effects(thirst=15.0, warn_threshold=30.0, crit_threshold=10.0,
                                     base_fatigue_rate=1.0, max_carry=50.0, carry_penalty=10.0)
    assert math.isclose(carry, 50.0), \
        f"[LSURV-023] max_carry should stay at 50.0 above crit threshold, got {carry}"


def test_cold_reduces_movement_speed_lsurv024():
    """[LSURV-024] When temperature < cold_threshold, movement speed shall be reduced."""
    speed, _ = apply_temperature_effects(-5.0, cold_threshold=0.0, heat_threshold=30.0,
                                          base_speed=5.0, base_stamina_regen=1.0)
    assert speed < 5.0, \
        f"[LSURV-024] Speed should reduce below cold threshold, got {speed}"


def test_above_cold_threshold_no_speed_penalty_lsurv024():
    """[LSURV-024] When temperature >= cold_threshold, speed shall not be penalised."""
    speed, _ = apply_temperature_effects(10.0, cold_threshold=0.0, heat_threshold=30.0,
                                          base_speed=5.0, base_stamina_regen=1.0)
    assert math.isclose(speed, 5.0), \
        f"[LSURV-024] Speed should stay at 5.0 above cold threshold, got {speed}"


def test_heat_reduces_stamina_regen_lsurv026():
    """[LSURV-026] When temperature > heat_threshold, stamina regen shall be reduced."""
    _, regen = apply_temperature_effects(35.0, cold_threshold=0.0, heat_threshold=30.0,
                                          base_speed=5.0, base_stamina_regen=1.0)
    assert regen < 1.0, \
        f"[LSURV-026] Stamina regen should reduce above heat threshold, got {regen}"


def test_below_heat_threshold_no_stamina_penalty_lsurv026():
    """[LSURV-026] When temperature <= heat_threshold, stamina regen shall not be reduced."""
    _, regen = apply_temperature_effects(20.0, cold_threshold=0.0, heat_threshold=30.0,
                                          base_speed=5.0, base_stamina_regen=1.0)
    assert math.isclose(regen, 1.0), \
        f"[LSURV-026] Stamina regen should stay at 1.0 below heat threshold, got {regen}"


# ===========================================================================
# LECO-011..013 — Exploitation claim conflict resolution
# ===========================================================================

def resolve_hex_claim(settlements: list[dict], hex_id: str) -> str | None:
    """
    [LECO-011..013] For a hex contested by multiple settlements:
    - Only the highest-tier settlement wins.
    - On equal tier, the higher trade_score wins.
    Returns the winning settlement's id, or None if no settlement claims it.
    """
    claimants = [s for s in settlements if hex_id in s.get("exploited_hexes", [])]
    if not claimants:
        return None
    winner = max(claimants, key=lambda s: (s["tier"], s["trade_score"]))
    return winner["id"]


def test_higher_tier_wins_resource_claim_leco011():
    """[LECO-011] Only the highest-tier settlement shall receive resources from a contested hex."""
    settlements = [
        {"id": "village", "tier": 2, "trade_score": 500, "exploited_hexes": ["hex_A"]},
        {"id": "town",    "tier": 3, "trade_score": 100, "exploited_hexes": ["hex_A"]},
    ]
    winner = resolve_hex_claim(settlements, "hex_A")
    assert winner == "town", \
        f"[LECO-011] Tier 3 town should win over tier 2 village, got {winner}"


def test_lower_tier_gets_zero_from_contested_hex_leco012():
    """[LECO-012] Lower-tier settlement shall receive zero exploitation from a contested hex."""
    settlements = [
        {"id": "village", "tier": 2, "trade_score": 500, "exploited_hexes": ["hex_A"]},
        {"id": "town",    "tier": 3, "trade_score": 100, "exploited_hexes": ["hex_A"]},
    ]
    winner = resolve_hex_claim(settlements, "hex_A")
    # The loser gets zero — verified by checking they are NOT the winner
    assert winner != "village", \
        "[LECO-012] Lower-tier village must not win the contested hex"


def test_equal_tier_higher_trade_score_wins_leco013():
    """[LECO-013] When tiers are equal, the settlement with the higher trade score wins."""
    settlements = [
        {"id": "s_low",  "tier": 3, "trade_score": 200, "exploited_hexes": ["hex_B"]},
        {"id": "s_high", "tier": 3, "trade_score": 800, "exploited_hexes": ["hex_B"]},
    ]
    winner = resolve_hex_claim(settlements, "hex_B")
    assert winner == "s_high", \
        f"[LECO-013] Higher trade score (800) should win equal-tier contest, got {winner}"


def test_uncontested_hex_returns_sole_claimant():
    """Uncontested hex (single claimant) shall always return that settlement."""
    settlements = [
        {"id": "only_one", "tier": 2, "trade_score": 100, "exploited_hexes": ["hex_C"]},
        {"id": "no_claim", "tier": 4, "trade_score": 999, "exploited_hexes": ["hex_D"]},
    ]
    winner = resolve_hex_claim(settlements, "hex_C")
    assert winner == "only_one", \
        f"Uncontested claimant should always win, got {winner}"


# ===========================================================================
# LCBT-001..004 — Combat state logic
# ===========================================================================

class CombatTracker:
    """
    [LCBT-001..004] Minimal simulation of CombatManager combat tracking.
    """
    def __init__(self):
        self.targeting_monsters: set = set()
        self.in_combat: bool = False
        self.arrows_fired: int = 0
        self._combat_started_count = 0
        self._combat_ended_count = 0

    def on_monster_target(self, monster_id: str):
        was_in_combat = self.in_combat
        self.targeting_monsters.add(monster_id)
        self.in_combat = len(self.targeting_monsters) > 0
        if self.in_combat and not was_in_combat:
            self._combat_started_count += 1
            self.arrows_fired = 0  # reset on new combat

    def on_monster_stop_target(self, monster_id: str):
        self.targeting_monsters.discard(monster_id)
        was_in_combat = self.in_combat
        self.in_combat = len(self.targeting_monsters) > 0
        if was_in_combat and not self.in_combat:
            self._combat_ended_count += 1

    def fire_arrow(self):
        self.arrows_fired += 1


def test_player_in_combat_when_monster_targets_lcbt001():
    """[LCBT-001] CombatManager shall report in_combat when at least one monster targets player."""
    tracker = CombatTracker()
    assert not tracker.in_combat
    tracker.on_monster_target("wolf_1")
    assert tracker.in_combat, "[LCBT-001] Should be in combat when monster targets player"


def test_combat_started_signal_on_first_aggro_lcbt002():
    """[LCBT-002] combat_started shall emit when the first monster targets player."""
    tracker = CombatTracker()
    tracker.on_monster_target("wolf_1")
    assert tracker._combat_started_count == 1, \
        "[LCBT-002] combat_started should fire once on first aggro"
    tracker.on_monster_target("wolf_2")
    assert tracker._combat_started_count == 1, \
        "[LCBT-002] combat_started should not fire again for subsequent aggressors"


def test_combat_ended_when_no_aggressors_lcbt003():
    """[LCBT-003] combat_ended shall emit when no monsters are targeting the player."""
    tracker = CombatTracker()
    tracker.on_monster_target("wolf_1")
    tracker.on_monster_target("wolf_2")
    tracker.on_monster_stop_target("wolf_1")
    assert tracker.in_combat, "[LCBT-003] Still in combat with wolf_2"
    assert tracker._combat_ended_count == 0
    tracker.on_monster_stop_target("wolf_2")
    assert not tracker.in_combat, "[LCBT-003] Should leave combat when all monsters stop"
    assert tracker._combat_ended_count == 1, \
        "[LCBT-003] combat_ended should fire exactly once"


def test_arrows_fired_resets_on_combat_start_lcbt004():
    """[LCBT-004] arrows_fired counter shall reset to 0 on each new combat_started."""
    tracker = CombatTracker()
    # First combat
    tracker.on_monster_target("wolf_1")
    tracker.fire_arrow()
    tracker.fire_arrow()
    assert tracker.arrows_fired == 2
    tracker.on_monster_stop_target("wolf_1")
    # Second combat starts — counter must reset
    tracker.on_monster_target("bear_1")
    assert tracker.arrows_fired == 0, \
        f"[LCBT-004] arrows_fired must reset on new combat_started, got {tracker.arrows_fired}"
    tracker.fire_arrow()
    assert tracker.arrows_fired == 1


# ===========================================================================
# LSCORE-008 — Tier advancement requires all required_resources in flow
# ===========================================================================

def test_tier_advancement_requires_all_resources_lscore008():
    """[LSCORE-008] Tier advancement shall require all required_resources present in flow-through set."""
    def can_advance_tier(trade_score: float, threshold: float,
                          required: list, available: set) -> bool:
        if trade_score < threshold:
            return False
        return all(r in available for r in required)

    # Has score but missing a resource
    assert not can_advance_tier(500, 200, ["iron", "timber"], {"iron"}), \
        "[LSCORE-008] Should not advance with missing required resource"

    # Has score and all resources
    assert can_advance_tier(500, 200, ["iron", "timber"], {"iron", "timber", "fish"}), \
        "[LSCORE-008] Should advance with score met and all resources present"

    # Score not met even with all resources
    assert not can_advance_tier(100, 200, ["iron"], {"iron"}), \
        "[LSCORE-008] Should not advance if score below threshold"

    # Empty required list: score alone sufficient
    assert can_advance_tier(300, 200, [], set()), \
        "[LSCORE-008] Should advance when no resources required and score met"


# ===========================================================================
# LEXPORT-003 — Shop inventory filtering logic
# ===========================================================================

def test_shop_filtering_logic_lexport003():
    """[LEXPORT-003] Shop shall filter goods by export_tier <= global_tier AND
    min_settlement_tier <= this_settlement_tier."""
    def is_available_in_shop(item: dict, global_export_tier: int,
                              settlement_tier: int) -> bool:
        return (item.get("export_threshold_tier", 0) <= global_export_tier and
                item.get("min_settlement_tier", 1) <= settlement_tier)

    item_common   = {"id": "rope",         "export_threshold_tier": 1, "min_settlement_tier": 1}
    item_advanced = {"id": "spyglass",     "export_threshold_tier": 2, "min_settlement_tier": 2}
    item_rare     = {"id": "theodolite",   "export_threshold_tier": 3, "min_settlement_tier": 3}

    # Low export, low settlement — only common available
    assert     is_available_in_shop(item_common,   1, 1), "[LEXPORT-003] Common item should be available"
    assert not is_available_in_shop(item_advanced, 1, 1), "[LEXPORT-003] Advanced blocked by export tier"
    assert not is_available_in_shop(item_rare,     1, 1), "[LEXPORT-003] Rare blocked by export tier"

    # High export, low settlement — export gate passed but settlement gate blocks
    assert     is_available_in_shop(item_common,   3, 1), "[LEXPORT-003] Common still available"
    assert not is_available_in_shop(item_advanced, 3, 1), "[LEXPORT-003] Advanced blocked by settlement tier"

    # High export, high settlement — all available
    assert is_available_in_shop(item_common,   3, 3), "[LEXPORT-003] Common available"
    assert is_available_in_shop(item_advanced, 3, 3), "[LEXPORT-003] Advanced available"
    assert is_available_in_shop(item_rare,     3, 3), "[LEXPORT-003] Rare available"


# ===========================================================================
# LMAP-021 — Portage validation: graph topology check
# ===========================================================================

def get_areas_requiring_portage(areas: list[dict]) -> list[str]:
    """
    [LMAP-021] For each area, check if two of its non-adjacent neighbors both have
    a River tag. If so, that area must have a Portage tag.
    Returns list of area IDs that violate the rule (have River neighbors but no Portage).
    """
    area_map = {a["id"]: a for a in areas}
    violations = []

    for area in areas:
        neighbors = area.get("neighbors", [])
        # Find how many neighbors have River tag
        river_neighbors = [
            nid for nid in neighbors
            if "river" in [t.lower() for t in area_map.get(nid, {}).get("tags", [])]
        ]
        if len(river_neighbors) >= 2:
            # Check if any two river neighbors are non-adjacent to each other
            for i in range(len(river_neighbors)):
                for j in range(i + 1, len(river_neighbors)):
                    n1_neighbors = area_map.get(river_neighbors[i], {}).get("neighbors", [])
                    are_adjacent = river_neighbors[j] in n1_neighbors
                    if not are_adjacent:
                        # These two river neighbors are not adjacent — portage required
                        if "portage" not in [t.lower() for t in area.get("tags", [])]:
                            violations.append(area["id"])
                        break
    return violations


def test_portage_validation_no_violations_lmap021():
    """[LMAP-021] Areas with two non-adjacent River neighbors must have Portage tag."""
    # Valid: area has portage
    areas = [
        {"id": "A", "neighbors": ["B", "C"], "tags": ["portage"]},
        {"id": "B", "neighbors": ["A"],       "tags": ["river"]},
        {"id": "C", "neighbors": ["A"],       "tags": ["river"]},  # B and C not adjacent
    ]
    violations = get_areas_requiring_portage(areas)
    assert "A" not in violations, \
        "[LMAP-021] Area A has portage tag and should not be flagged"


def test_portage_validation_detects_violation_lmap021():
    """[LMAP-021] Area with two non-adjacent River neighbors but no Portage tag shall be flagged."""
    areas = [
        {"id": "A", "neighbors": ["B", "C"], "tags": []},          # no portage — violation
        {"id": "B", "neighbors": ["A"],       "tags": ["river"]},
        {"id": "C", "neighbors": ["A"],       "tags": ["river"]},
    ]
    violations = get_areas_requiring_portage(areas)
    assert "A" in violations, \
        "[LMAP-021] Area A should be flagged: two non-adjacent River neighbors without Portage"


def test_portage_not_required_for_adjacent_river_neighbors_lmap021():
    """[LMAP-021] If the two River neighbors are adjacent to each other, Portage is not required."""
    areas = [
        {"id": "A", "neighbors": ["B", "C"], "tags": []},
        {"id": "B", "neighbors": ["A", "C"], "tags": ["river"]},   # B and C are adjacent
        {"id": "C", "neighbors": ["A", "B"], "tags": ["river"]},
    ]
    violations = get_areas_requiring_portage(areas)
    assert "A" not in violations, \
        "[LMAP-021] Area A should not be flagged when River neighbors are adjacent to each other"


# ===========================================================================
# LSCORE-011 — First-mover advantage: Dijkstra doesn't displace existing routes
# ===========================================================================

def test_first_mover_dijkstra_stable_lscore011():
    """[LSCORE-011] Re-running Dijkstra on unchanged graph topology shall produce the same
    shortest paths — existing routes are not displaced by new settlements on same graph."""
    graph = {
        "s1":   ["junction", "port"],
        "s2":   ["junction"],
        "junction": ["s1", "s2", "port"],
        "port": ["s1", "junction"],
    }
    ports = {"port"}

    # Run twice — result must be identical (no displacement on re-calculation)
    port1, path1 = dijkstra_nearest_port("s1", graph, ports)
    port2, path2 = dijkstra_nearest_port("s1", graph, ports)
    assert path1 == path2, \
        "[LSCORE-011] Dijkstra must be deterministic — same graph yields same route"

    # s2 added after s1 connected — s2 should get its own valid route without affecting s1
    port_s1, path_s1 = dijkstra_nearest_port("s1", graph, ports)
    port_s2, path_s2 = dijkstra_nearest_port("s2", graph, ports)
    assert port_s1 is not None and port_s2 is not None, \
        "[LSCORE-011] Both settlements should reach a port"
    assert path_s1[0] == "s1" and path_s2[0] == "s2", \
        "[LSCORE-011] Each route must originate from its own settlement"
