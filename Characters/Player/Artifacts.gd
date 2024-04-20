class_name Artifacts

var collection: Array[Artifact] = []
var connected: Dictionary = {} # Artifact -> Vector2
var active_options: Dictionary = {} # Vector2 -> (int -> bool])

var effects: Dictionary = {} # Vector2i (duration, Artifact.Event | Artifact.Element) -> (Artifact.Effect | Artifact.Element) -> (flat: int, ratio: float)

func reset_by_deleting_all_artifacts() -> void:
	collection = []
	connected = {}
	active_options = {}
	effects = {}

func unconnected() -> Array[Artifact]:
	var result: Array[Artifact] = []
	for c in collection:
		if not connected.has(c):
			result.append(c)
	return result
	
func connect_to_grid(artifact: Artifact, coord: Vector2) -> void:
	connected[artifact] = coord
	build_active_options()
	
func unconnect_from_grid(artifact: Artifact) -> void:
	connected.erase(artifact)
	build_active_options()
	
func is_empty() -> bool:
	return connected.is_empty()

func get_artifact_by_name(name: String) -> Artifact:
	for c: Artifact in collection:
		if c.name == name:
			return c
	return null	

func get_artifact_at_coord(coord: Vector2) -> Artifact:
	for c: Artifact in connected:
		if connected[c] == coord:
			return c
	return null
	
func build_active_options() -> void:
	active_options.clear()
	effects.clear()
	for c: Artifact in connected:
		var v := connected[c] as Vector2
		update_active_options(c, v)
		
func delete_artifact(artifact: Artifact) -> void:
	if connected.has(artifact):
		return
		
	var i := 0
	var found := -1
	for a in collection:
		if a == artifact:
			found = i
			break
		i += 1
	
	if found > -1:
		collection.remove_at(i)
	
	
func update_active_options(artifact: Artifact, coord: Vector2) -> void:
	const TOP := 0
	const RIGHT := 1
	const BOTTOM := 2
	const LEFT := 3
	
	if true:
		var other_coord := coord + Vector2(0, -1) 
		var other := get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.top.event != Artifact.Event.NONE and other.bottom.effect != Artifact.Effect.NONE) or (artifact.top.effect != Artifact.Effect.NONE and other.bottom.event != Artifact.Event.NONE):
				if artifact.top.event != Artifact.Event.NONE:
					if not effects.has(artifact.top.element_event()):
						effects[artifact.top.element_event()] = {other.bottom.element_effect(): other.bottom.amount_as_tuple()}
					elif not (effects[artifact.top.element_event()] as Dictionary).has(other.bottom.element_effect()):
						effects[artifact.top.element_event()][other.bottom.element_effect()] = other.bottom.amount_as_tuple()
					else:
						effects[artifact.top.element_event()][other.bottom.element_effect()] += other.bottom.amount_as_tuple()
				
				if not active_options.has(coord):
					active_options[coord] = {TOP: true}
				else:
					active_options[coord][TOP] = true
				if not active_options.has(other_coord):
					active_options[other_coord] = {BOTTOM: true}
				else:
					active_options[other_coord][BOTTOM] = true
					
	if true:
		var other_coord := coord + Vector2(1, 0) 
		var other := get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.right.event != Artifact.Event.NONE and other.left.effect != Artifact.Effect.NONE) or (artifact.right.effect != Artifact.Effect.NONE and other.left.event != Artifact.Event.NONE):
				if artifact.right.event != Artifact.Event.NONE:
					if not effects.has(artifact.right.element_event()):
						effects[artifact.right.element_event()] = {other.left.element_effect(): other.left.amount_as_tuple()}
					elif not (effects[artifact.right.element_event()] as Dictionary).has(other.left.element_effect()):
						effects[artifact.right.element_event()][other.left.element_effect()] = other.left.amount_as_tuple()
					else:
						effects[artifact.right.element_event()][other.left.element_effect()] += other.left.amount_as_tuple()
				
				if not active_options.has(coord):
					active_options[coord] = {RIGHT: true}
				else:
					active_options[coord][RIGHT] = true
				if not active_options.has(other_coord):
					active_options[other_coord] = {LEFT: true}
				else:
					active_options[other_coord][LEFT] = true
					
	if true:
		var other_coord := coord + Vector2(0, 1) 
		var other := get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.bottom.event != Artifact.Event.NONE and other.top.effect != Artifact.Effect.NONE) or (artifact.bottom.effect != Artifact.Effect.NONE and other.top.event != Artifact.Event.NONE):
				if artifact.bottom.event != Artifact.Event.NONE:
					if not effects.has(artifact.bottom.element_event()):
						effects[artifact.bottom.element_event()] = {other.top.element_effect(): other.top.amount_as_tuple()}
					elif not (effects[artifact.bottom.element_event()] as Dictionary).has(other.top.element_effect()):
						effects[artifact.bottom.element_event()][other.top.element_effect()] = other.top.amount_as_tuple()
					else:
						effects[artifact.bottom.element_event()][other.top.element_effect()] += other.top.amount_as_tuple()
				
				if not active_options.has(coord):
					active_options[coord] = {BOTTOM: true}
				else:
					active_options[coord][BOTTOM] = true
				if not active_options.has(other_coord):
					active_options[other_coord] = {TOP: true}
				else:
					active_options[other_coord][TOP] = true
					
	if true:
		var other_coord := coord + Vector2(-1, 0) 
		var other := get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.left.event != Artifact.Event.NONE and other.right.effect != Artifact.Effect.NONE) or (artifact.left.effect != Artifact.Effect.NONE and other.right.event != Artifact.Event.NONE):
				if artifact.left.event != Artifact.Event.NONE:
					if not effects.has(artifact.left.element_event()):
						effects[artifact.left.element_event()] = {other.right.element_effect(): other.right.amount_as_tuple()}
					elif not (effects[artifact.left.element_event()] as Dictionary).has(other.right.element_effect()):
						effects[artifact.left.element_event()][other.right.element_effect()] = other.right.amount_as_tuple()
					else:
						effects[artifact.left.element_event()][other.right.element_effect()] += other.right.amount_as_tuple()
				
				if not active_options.has(coord):
					active_options[coord] = {LEFT: true}
				else:
					active_options[coord][LEFT] = true
				if not active_options.has(other_coord):
					active_options[other_coord] = {RIGHT: true}
				else:
					active_options[other_coord][RIGHT] = true

func is_still_continuous_after_removing(coord: Vector2) -> bool:
	# flood fill from coord. If the total number of 'painted' tiles with artifacts
	# is one less than the total then we have a fully connected path.
	
	if connected.size() <= 2:
		return true
	
	var to_visit := PackedVector2Array()
	var visited := {coord: true}
	# loop to find exactly one tile that has an artifact which is not the removed 'coord'
	for a: Vector2 in connected:
		var c: Vector2 = connected[a]
		if c == coord:
			continue
		to_visit.append(c)
		break # we must only find exactly one tile
		
	var island_count := 0
	while not to_visit.is_empty():
		var c := to_visit[to_visit.size() - 1]
		to_visit.remove_at(to_visit.size() - 1)
		
		if visited.has(c):
			continue
		visited[c] = true
		
		if get_artifact_at_coord(c) == null:
			continue
		
		to_visit.append(c + Vector2(0, -1))
		to_visit.append(c + Vector2(0, 1))
		to_visit.append(c + Vector2(-1, 0))
		to_visit.append(c + Vector2(1, 0))
		
		island_count += 1
			
	return island_count == connected.size() - 1
	
	
func save(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/artifacts.json" % (world_name), FileAccess.WRITE)
	var data := []
	for a: Artifact in collection:
		data.append(a.save_dict())
	var connections := {}
	for c: Artifact in connected:
		connections[c.save_dict()] = connected[c]
	file.store_var({"artifacts": data, "connected": connections, "active_options": active_options, "effects": effects})
	
func read(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/artifacts.json" % (world_name), FileAccess.READ)
	if not file:
		collection = []
		connected = {}
		active_options = {}
		effects = {}
		return 
	var data := file.get_var() as Dictionary
	if data == null:
		collection = []
		connected = {}
		active_options = {}
		effects = {}
		return
	active_options = data.get("active_options", {}) as Dictionary
	effects = data.get("effects", {}) as Dictionary
	for d: Dictionary in data["artifacts"]:
		var w := Artifact.new("")
		w.load_dict(d)
		collection.append(w)
	for c: Dictionary in data["connected"]:
		var w := Artifact.new("")
		w.load_dict(c)
		for a: Artifact in collection:
			if a.name == w.name:
				connected[a] = data["connected"][c]
