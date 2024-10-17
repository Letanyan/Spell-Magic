class_name ItemSpawner

var population: Population = null:
	set(value):
		population = value
		if population != null:
			population.other_objects.append(self)
var name: String = ""
var nodes_to_be_cleared := {}
var position: Vector3 = Vector3.ZERO
var artifact: Artifact = null
var spell: Spell = null
var key: int = 0
var coins: Array[int] = []
var health: float = 0.0

signal condition_met

func _init() -> void:
	pass

static func artifact_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, a: Artifact) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "ArtifactSpawner " + Globals.encode_v3(pos)
	result.population = pop
	result.artifact = a
	result.position = pos
	return result
	
static func spell_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, s: Spell) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "SpellSpawner " + Globals.encode_v3(pos)
	result.population = pop
	result.spell = s
	result.position = pos
	return result
	
static func key_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, k: int) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "KeySpawner " + Globals.encode_v3(pos)
	result.population = pop
	result.key = k
	result.position = pos
	return result
	
static func coins_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, cs: Array[int]) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "CoinsSpawner " + Globals.encode_v3(pos)
	result.population = pop
	result.coins = cs
	result.position = pos
	return result
	
static func health_spawner(rng: RandomNumberGenerator, pop: Population, pos: Vector3, h: float) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.name = "HealthSpawner " + Globals.encode_v3(pos)
	result.population = pop
	result.health = h
	result.position = pos
	return result
	
func remove_node(node: Node3D) -> void:
	var world := node.get_parent_node_3d()
	nodes_to_be_cleared.erase(node)
	if nodes_to_be_cleared.is_empty():
		if population:
			population.mark_entity_name(name)
		if key != 0:
			drop_key_item(world)
		if artifact != null:
			drop_artifact_item(world)
		if spell != null:
			drop_spell_item(world)
		if not coins.is_empty():
			drop_coin_items(world)
		if health != 0.0:
			drop_health_item(world)
		condition_met.emit() 
	
func drop_artifact_item(world: Node3D) -> bool:
	if artifact:
		var item := population.entity_manager.get_world_item(World.Item.ARTIFACT) as ArtifactCube
		item.position = position
		item.artifact = artifact
		world.add_child(item)
		return true
	return false
		
		
func drop_spell_item(world: Node3D) -> bool:
	if spell:
		var item := population.entity_manager.get_world_item(World.Item.SPELL) as SpellPaper
		item.position = position
		item.spell = spell
		world.add_child(item)
		return true
	return false
		
func drop_key_item(world: Node3D) -> bool:
	if key != 0:
		var item := population.entity_manager.get_world_item(World.Item.KEY) as KeyPrism
		item.position = position
		item.key = key
		world.add_child(item)
		return true
	return false

func drop_coin_items(world: Node3D) -> bool:
	if not coins.is_empty():
		for coin in coins:
			var item := population.entity_manager.get_world_item(World.Item.COIN) as CoinDisc
			item.position = position + Globals.rand_point_in_circle(1.0 + log(coins.size()), 0)
			item.amount = coin
			world.add_child(item)
		return true
	return false
	
func drop_health_item(world: Node3D) -> bool:
	if key != 0:
		var item := population.entity_manager.get_world_item(World.Item.HEALTH) as RedCross
		item.position = position
		item.health = health
		world.add_child(item)
		return true
	return false
