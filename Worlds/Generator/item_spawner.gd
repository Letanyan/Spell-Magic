class_name ItemSpawner

var population: Population = null
var name: String = ""
var nodes_to_be_cleared := {}
var position: Vector3 = Vector3.ZERO
var artifact: Artifact = null
var spell: Spell = null
var key: int = 0

func _init() -> void:
	pass

static func artifact_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, a: Artifact) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "ArtifactSpawner " + str(rng.randi())
	result.population = pop
	result.artifact = a
	result.position = pos
	return result
	
static func spell_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, s: Spell) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "SpellSpawner " + str(rng.randi())
	result.population = pop
	result.spell = s
	result.position = pos
	return result
	
static func key_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, k: int) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "KeySpawner " + str(rng.randi())
	result.population = pop
	result.key = k
	result.position = pos
	return result
	
func remove_node(node: Node3D) -> void:
	nodes_to_be_cleared.erase(node)
	if population:
		population.other_objects.append(self)
		population.mark_entity_name(name)
	else:
		print("no population set")
	if nodes_to_be_cleared.is_empty():
		var world := node.get_parent_node_3d()
		if key != 0:
			drop_key_item(world)
		elif artifact != null:
			drop_artifact_item(world)
		elif spell != null:
			drop_spell_item(world)
	
func drop_artifact_item(world: Node3D) -> bool:
	if artifact:
		var item := (preload("res://Models/Misc/Artifact/Cube.tscn") as PackedScene).instantiate() as ArtifactCube
		item.position = position
		item.artifact = artifact
		world.add_child(item)
		return true
	return false
		
		
func drop_spell_item(world: Node3D) -> bool:
	if spell:
		var item := (preload("res://Models/Misc/Spell/Paper.tscn") as PackedScene).instantiate() as SpellPaper
		item.position = position
		item.spell = spell
		world.add_child(item)
		return true
	return false
		
func drop_key_item(world: Node3D) -> bool:
	if key != 0:
		var item := (preload("res://Models/Misc/Key/Key.tscn") as PackedScene).instantiate() as KeyPrism
		item.position = position
		item.key = key
		world.add_child(item)
		return true
	return false
