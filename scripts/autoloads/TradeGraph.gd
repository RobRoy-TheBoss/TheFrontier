## TradeGraph
## Autoload singleton. Maintains the trade-routing graph for the road network (LTRADE-001..005).
## Adjacency is built by FoundingManager / SettlementManager calling add_road().
## Dijkstra (1-hop edge weight) finds paths to the nearest deep-water port.
extends Node

signal routes_recalculated

## Adjacency list: settlement_id -> Array[String] of connected settlement ids.
var _adjacency: Dictionary = {}

## Set to true when the graph has been modified but routes have not been recalculated.
var is_dirty: bool = false


# --- Graph mutation ---

## Add a bidirectional road between two settlements.
func add_road(from_id: String, to_id: String) -> void:
	_ensure_entry(from_id)
	_ensure_entry(to_id)
	if not (to_id in _adjacency[from_id]):
		_adjacency[from_id].append(to_id)
	if not (from_id in _adjacency[to_id]):
		_adjacency[to_id].append(from_id)
	mark_dirty()


## Remove a bidirectional connection. Kept for API completeness (LTRADE-002).
## Note: roads are generally permanent in The Frontier — prefer not calling this.
func remove_connection(from_id: String, to_id: String) -> void:
	if _adjacency.has(from_id):
		_adjacency[from_id].erase(to_id)
	if _adjacency.has(to_id):
		_adjacency[to_id].erase(from_id)
	mark_dirty()


## Return the direct neighbors of a settlement in the graph.
func get_neighbors(settlement_id: String) -> Array[String]:
	var result: Array[String] = []
	for n in _adjacency.get(settlement_id, []):
		result.append(n)
	return result


## Mark the graph as needing route recalculation.
func mark_dirty() -> void:
	is_dirty = true


# --- Routing ---

## Run Dijkstra from settlement_id to the nearest deep-water port.
## Returns an ordered Array[String] of settlement ids from start to port (inclusive).
## Returns an empty array if no path exists.
func get_route_to_port(settlement_id: String) -> Array[String]:
	var ports := _get_port_ids()
	if settlement_id in ports:
		return [settlement_id]
	return _dijkstra(settlement_id, ports)


## Recalculate routes for every settlement and return a snapshot Dictionary:
##   settlement_id -> Array[String] (path to nearest port)
func recalculate_all_routes() -> Dictionary:
	var ports := _get_port_ids()
	var result: Dictionary = {}
	for sid in _adjacency:
		if sid in ports:
			result[sid] = [sid]
		else:
			result[sid] = _dijkstra(sid, ports)
	is_dirty = false
	routes_recalculated.emit()
	return result


# --- Private helpers ---

func _ensure_entry(settlement_id: String) -> void:
	if not _adjacency.has(settlement_id):
		_adjacency[settlement_id] = []


func _get_port_ids() -> Array:
	var ports := []
	# Ask SettlementManager which settlements are deep-water ports.
	for sid in _adjacency:
		var s = SettlementManager.get_settlement(sid)
		if s != null and s.is_deep_water_port:
			ports.append(sid)
	return ports


## Dijkstra with unit edge weights. Returns path from start to the nearest target in targets[].
func _dijkstra(start: String, targets: Array) -> Array[String]:
	if targets.is_empty():
		return []

	# dist[id] = steps from start
	var dist: Dictionary = { start: 0 }
	var prev: Dictionary = {}
	# Priority queue as a sorted Array of [cost, id] pairs — small enough for settlement counts.
	var queue: Array = [[0, start]]
	var visited: Dictionary = {}

	while queue.size() > 0:
		# Pop lowest-cost entry
		queue.sort_custom(func(a, b): return a[0] < b[0])
		var entry: Array = queue.pop_front()
		var cost: int = entry[0]
		var current: String = entry[1]

		if visited.has(current):
			continue
		visited[current] = true

		if current in targets:
			# Reconstruct path
			return _reconstruct_path(prev, start, current)

		for neighbor in _adjacency.get(current, []):
			if visited.has(neighbor):
				continue
			var new_cost: int = cost + 1
			if new_cost < dist.get(neighbor, 999999):
				dist[neighbor] = new_cost
				prev[neighbor] = current
				queue.append([new_cost, neighbor])

	return []  # No path found


func _reconstruct_path(prev: Dictionary, start: String, end: String) -> Array[String]:
	var path: Array[String] = []
	var current := end
	while current != start:
		path.push_front(current)
		current = prev.get(current, "")
		if current == "":
			push_error("[TradeGraph] Path reconstruction failed — broken prev chain.")
			return []
	path.push_front(start)
	return path
