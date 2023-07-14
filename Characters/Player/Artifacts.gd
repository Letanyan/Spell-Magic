class_name Artifacts

var collection: Array[Artifact] = []
var connected: Dictionary = {} # Artifact -> Vector2

func unconnected() -> Array[Artifact]:
	var result: Array[Artifact] = []
	for c in collection:
		if not connected.has(c):
			result.append(c)
	return result
	
func connect_to_grid(artifact: Artifact, coord: Vector2):
	connected[artifact] = coord
	
func unconnect_from_grid(artifact: Artifact):
	connected.erase(artifact)

func get_artifact_by_name(name: String) -> Artifact:
	for c in collection:
		if c.name == name:
			return c
	return null

func save():
	var file = FileAccess.open("user://artifacts.json", FileAccess.WRITE)
	var data = []
	for a in collection:
		data.append(a.save_dict())
	var connections = {}
	for c in connected:
		connections[c.save_dict()] = connected[c]
	file.store_var({"artifacts": data, "connected": connections})
	
func load():
	var file = FileAccess.open("user://artifacts.json", FileAccess.READ)
	if not file:
		collection = []
		connected = {}
		return 
	var data = file.get_var()
	if data == null:
		collection = []
		connected = {}
		return
	for d in data["artifacts"]:
		var w = Artifact.new()
		w.load_dict(d)
		collection.append(w)
	for c in data["connected"]:
		var w = Artifact.new()
		w.load_dict(c)
		for a in collection:
			if a.name == w.name:
				connected[a] = data["connected"][c]
