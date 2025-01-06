class_name Artifacts

var collection: Array[Artifact] = []
var connected: Dictionary = {} # [Artifact]Vector2
var active_options: Dictionary = {} # [Vector2][int]Artifacts.Option

var effects: Dictionary = {} # [Vector2i(duration, Artifact.Event | Artifact.Element)][int(Artifact.Effect | Artifact.Element)]Vector2(flat: int, ratio: float)

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
					active_options[coord] = {TOP: other.bottom}
				else:
					active_options[coord][TOP] = other.bottom
				if not active_options.has(other_coord):
					active_options[other_coord] = {BOTTOM: artifact.top}
				else:
					active_options[other_coord][BOTTOM] = artifact.top
					
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
					active_options[coord] = {RIGHT: other.left}
				else:
					active_options[coord][RIGHT] = other.left
				if not active_options.has(other_coord):
					active_options[other_coord] = {LEFT: artifact.right}
				else:
					active_options[other_coord][LEFT] = artifact.right
					
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
					active_options[coord] = {BOTTOM: other.top}
				else:
					active_options[coord][BOTTOM] = other.top
				if not active_options.has(other_coord):
					active_options[other_coord] = {TOP: artifact.bottom}
				else:
					active_options[other_coord][TOP] = artifact.bottom
					
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
					active_options[coord] = {LEFT: other.right}
				else:
					active_options[coord][LEFT] = other.right
				if not active_options.has(other_coord):
					active_options[other_coord] = {RIGHT: artifact.left}
				else:
					active_options[other_coord][RIGHT] = artifact.left

func can_place_artifact(artifact: Artifact, coord: Vector2) -> Array[Vector4]:
	if artifact == null:
		return [Vector4(coord.x, coord.y, 0, 0)]
	if get_artifact_at_coord(coord) != null:
		return [Vector4(coord.x, coord.y, 0, 0)]
		
	var check_count := 0
	var result: Array[Vector4] = []
		
	# Check artifact fits with top artifact
	var other := get_artifact_at_coord(coord + Vector2(0, -1))
	if other != null:
		check_count += 1
		var ok1 : bool = other.bottom.event != Artifact.Event.NONE and artifact.top.effect != Artifact.Effect.NONE
		var ok2 : bool = other.bottom.effect != Artifact.Effect.NONE and artifact.top.event != Artifact.Event.NONE
		var ok3 : bool = other.bottom.pattern == artifact.top.pattern
		if not ok3:
			var nc := coord + Vector2(0, -1)
			result.append(Vector4(nc.x, nc.y, 2, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(0, -1)
			result.append(Vector4(nc.x, nc.y, 2, 0))
			
	# Check artifact fits with bottom artifact	
	other = get_artifact_at_coord(coord + Vector2(0, 1))
	if other != null:
		check_count += 1
		var ok1 : bool = other.top.event != Artifact.Event.NONE and artifact.bottom.effect != Artifact.Effect.NONE
		var ok2 : bool = other.top.effect != Artifact.Effect.NONE and artifact.bottom.event != Artifact.Event.NONE
		var ok3 : bool = other.top.pattern == artifact.bottom.pattern
		if not ok3:
			var nc := coord + Vector2(0, 1)
			result.append(Vector4(nc.x, nc.y, 0, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(0, 1)
			result.append(Vector4(nc.x, nc.y, 0, 0))
			
	# Check artifact fits with left artifact
	other = get_artifact_at_coord(coord + Vector2(-1, 0))
	if other != null:
		check_count += 1
		var ok1 : bool = other.right.event != Artifact.Event.NONE and artifact.left.effect != Artifact.Effect.NONE
		var ok2 : bool = other.right.effect != Artifact.Effect.NONE and artifact.left.event != Artifact.Event.NONE
		var ok3 : bool = other.right.pattern == artifact.left.pattern
		if not ok3:
			var nc := coord + Vector2(-1, 0)
			result.append(Vector4(nc.x, nc.y, 1, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(-1, 0)
			result.append(Vector4(nc.x, nc.y, 1, 0))
			
	# Check artifact fits with right artifact
	other = get_artifact_at_coord(coord + Vector2(1, 0))
	if other != null:
		check_count += 1
		var ok1 : bool = other.left.event != Artifact.Event.NONE and artifact.right.effect != Artifact.Effect.NONE
		var ok2 : bool = other.left.effect != Artifact.Effect.NONE and artifact.right.event != Artifact.Event.NONE
		var ok3 : bool = other.left.pattern == artifact.right.pattern
		if not ok3:
			var nc := coord + Vector2(1, 0)
			result.append(Vector4(nc.x, nc.y, 3, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(1, 0)
			result.append(Vector4(nc.x, nc.y, 3, 0))
			
	if (check_count <= 0 and not is_empty()):
		return [Vector4(coord.x, coord.y, 0, 0)]
			
	return result

func is_still_continuous_after_removing(coord: Vector2) -> bool:
	# flood fill from coord. If the total number of 'painted' tiles with artifacts
	# is one less than the total then we have a fully connected path.
	
	if connected.size() <= 2:
		return true
	
	var to_visit := PackedVector2Array()
	var visited := {coord: true}
	# loop to find exactly one tile that has an artifact which is not the removed 'coord'
	for a: Artifact in connected:
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
	
func highlight_all_available_cells_for_placement(artifact: Artifact) -> PackedVector2Array:
	if artifact == null:
		return PackedVector2Array([])
		
	if connected.is_empty():
		return PackedVector2Array([Vector2.ZERO])
		
	var result := PackedVector2Array([])
	var directions := PackedVector2Array([Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)])
	var visited_cells := {}
	for a: Artifact in connected:
		var coord := connected[a] as Vector2
		for dir in directions:
			var new_coord := coord + dir
			if visited_cells.has(new_coord):
				continue
			visited_cells[new_coord] = true
			if can_place_artifact(artifact, new_coord).is_empty():
				result.append(new_coord)
				
	return result
	
func all_effects_description() -> String:
	var result := ""
	
	var groups := {} ## [String][]String
	for c: Vector2 in active_options:
		var a := get_artifact_at_coord(c)
		for i: int in active_options[c]:
			var o := active_options[c][i] as Artifact.Option
			var e: Artifact.Option = null
			match i:
				0: e = a.top
				1: e = a.right
				2: e = a.bottom
				3: e = a.left
			if e != null and e.event != Artifact.Event.NONE:
				if not groups.has(e.description()):
					groups[e.description()] = []
				if o.element == Artifact.Element.MANA or o.element == Artifact.Element.HEALTH:
					(groups[e.description()] as Array).append(o.description())
				else:
					(groups[e.description()] as Array).append(o.description() + " For " + e.duration_description())
					
	for event: String in groups:
		result += event + ": \n"
		for effect: String in groups[event]:
			result += "  - " + effect + "\n"
				
	if result == "":
		result = "Connect Artifacts on the Grid to Gain Buffs and Debuffs"
				
	return result
	
func save(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/artifacts.json" % (world_name), FileAccess.WRITE)
	var data := []
	for a: Artifact in collection:
		data.append(a.save_dict())
	var connections := {}
	for c: Artifact in connected:
		connections[c.save_dict()] = connected[c]
	var act_options := {}
	for c: Vector2 in active_options:
		act_options[c] = {}
		for i: int in active_options[c]:
			act_options[c][i] = (active_options[c][i] as Artifact.Option).save_int()
	file.store_var({"artifacts": data, "connected": connections, "active_options": act_options, "effects": effects})
	
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
	active_options = {}
	for c: Vector2 in data["active_options"]:
		active_options[c] = {}
		for i: int in data["active_options"][c]:
			var opt := Artifact.Option.empty()
			opt.load_int(data["active_options"][c][i] as int)
			active_options[c][i] = opt
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
