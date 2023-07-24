class_name Artifacts

var collection: Array[Artifact] = []
var connected: Dictionary = {} # Artifact -> Vector2
var active_options: Dictionary = {} # Vector2 -> (int -> bool])

var effects: Dictionary = {} # Artifact.Event -> Artifact.Effect -> (flat: int, ratio: float)

func unconnected() -> Array[Artifact]:
	var result: Array[Artifact] = []
	for c in collection:
		if not connected.has(c):
			result.append(c)
	return result
	
func connect_to_grid(artifact: Artifact, coord: Vector2):
	connected[artifact] = coord
	build_active_options()
	
func unconnect_from_grid(artifact: Artifact):
	connected.erase(artifact)
	build_active_options()

func get_artifact_by_name(name: String) -> Artifact:
	for c in collection:
		if c.name == name:
			return c
	return null	

func get_artifact_at_coord(coord: Vector2) -> Artifact:
	for c in connected:
		if connected[c] == coord:
			return c
	return null
	
func build_active_options():
	active_options.clear()
	effects.clear()
	for c in connected:
		var v = connected[c]
		update_active_options(c, v)
	
func update_active_options(artifact: Artifact, coord: Vector2):
	const TOP := 0
	const RIGHT := 1
	const BOTTOM := 2
	const LEFT := 3
	
	if true:
		var other_coord := coord + Vector2(0, -1) 
		var other = get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.top.event != Artifact.Event.NONE and other.bottom.effect != Artifact.Effect.NONE) or (artifact.top.effect != Artifact.Effect.NONE and other.bottom.event != Artifact.Event.NONE):
				if artifact.top.event != Artifact.Event.NONE:
					if not effects.has(artifact.top.element_event()):
						effects[artifact.top.element_event()] = {other.bottom.element_effect(): other.bottom.amount_as_tuple()}
					elif not effects[artifact.top.element_event()].has(other.bottom.element_effect()):
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
		var other = get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.right.event != Artifact.Event.NONE and other.left.effect != Artifact.Effect.NONE) or (artifact.right.effect != Artifact.Effect.NONE and other.left.event != Artifact.Event.NONE):
				if artifact.right.event != Artifact.Event.NONE:
					if not effects.has(artifact.right.element_event()):
						effects[artifact.right.element_event()] = {other.left.element_effect(): other.left.amount_as_tuple()}
					elif not effects[artifact.right.element_event()].has(other.left.element_effect()):
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
		var other = get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.bottom.event != Artifact.Event.NONE and other.top.effect != Artifact.Effect.NONE) or (artifact.bottom.effect != Artifact.Effect.NONE and other.top.event != Artifact.Event.NONE):
				if artifact.bottom.event != Artifact.Event.NONE:
					if not effects.has(artifact.bottom.element_event()):
						effects[artifact.bottom.element_event()] = {other.top.element_effect(): other.top.amount_as_tuple()}
					elif not effects[artifact.bottom.element_event()].has(other.top.element_effect()):
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
		var other = get_artifact_at_coord(other_coord)
		if other != null:
			if (artifact.left.event != Artifact.Event.NONE and other.right.effect != Artifact.Effect.NONE) or (artifact.left.effect != Artifact.Effect.NONE and other.right.event != Artifact.Event.NONE):
				if artifact.left.event != Artifact.Event.NONE:
					if not effects.has(artifact.left.element_event()):
						effects[artifact.left.element_event()] = {other.right.element_effect(): other.right.amount_as_tuple()}
					elif not effects[artifact.left.element_event()].has(other.right.element_effect()):
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

func save():
	var file = FileAccess.open("user://artifacts.json", FileAccess.WRITE)
	var data = []
	for a in collection:
		data.append(a.save_dict())
	var connections = {}
	for c in connected:
		connections[c.save_dict()] = connected[c]
	file.store_var({"artifacts": data, "connected": connections, "active_options": active_options, "effects": effects})
	
func load():
	var file = FileAccess.open("user://artifacts.json", FileAccess.READ)
	if not file:
		collection = []
		connected = {}
		active_options = {}
		return 
	var data = file.get_var()
	if data == null:
		collection = []
		connected = {}
		active_options = {}
		return
	active_options = data.get("active_options", {})
	effects = data.get("effects", {})
	for d in data["artifacts"]:
		var w = Artifact.new("")
		w.load_dict(d)
		collection.append(w)
	for c in data["connected"]:
		var w = Artifact.new("")
		w.load_dict(c)
		for a in collection:
			if a.name == w.name:
				connected[a] = data["connected"][c]
