class_name WorldSettings

var world_name: String
var player_position: Vector3
var sed: int

func save():
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	if not dir.dir_exists("worlds/%s" % (world_name)):
		dir.make_dir("worlds/%s" % (world_name))
	var file = FileAccess.open("user://worlds/%s/settings.json" % (world_name), FileAccess.WRITE)
	file.store_var({"name": world_name, "player": {"position": player_position}, "seed": sed})

func read(filename: String):
	var file = FileAccess.open("user://worlds/%s/settings.json" % (filename), FileAccess.READ)
	var data = file.get_var()
	world_name = data["name"]
	player_position = data["player"]["position"]
	sed = data["seed"]
