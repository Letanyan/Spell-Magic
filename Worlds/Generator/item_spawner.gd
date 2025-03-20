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
var note_id: String = ""

signal condition_met

func free() -> void:
	if SignalBus.enemy_death.is_connected(remove_node):
		SignalBus.enemy_death.disconnect(remove_node)

func _init() -> void:
	pass

static func artifact_spawner(pop: Population, pos: Vector3, a: Artifact) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.population = pop
	result.artifact = a
	result.position = pos
	return result
	
static func spell_spawner(pop: Population, pos: Vector3, s: Spell) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.population = pop
	result.spell = s
	result.position = pos
	return result
	
static func key_spawner(pop: Population, pos: Vector3, k: int) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.population = pop
	result.key = k
	result.position = pos
	return result
	
static func coins_spawner(pop: Population, pos: Vector3, cs: Array[int]) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.population = pop
	result.coins = cs
	result.position = pos
	return result
	
static func health_spawner(pop: Population, pos: Vector3, h: float) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.population = pop
	result.health = h
	result.position = pos
	return result
	
static func note_spawner(pop: Population, pos: Vector3, id: String) -> ItemSpawner:
	var result := ItemSpawner.new()
	result.population = pop
	result.note_id = id
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
		
func add_condition(node: Node3D) -> void:
	nodes_to_be_cleared[node] = true
	if node is Enemy and not SignalBus.enemy_death.is_connected(remove_node):
		SignalBus.enemy_death.connect(remove_node)
	
func drop_artifact_item(world: Node3D) -> bool:
	if artifact:
		var item := population.entity_manager.get_world_item(World.Item.ARTIFACT) as ArtifactCube
		item.position = position
		item.artifact = artifact
		if item.get_parent() == null:
			world.add_child(item)
		drop_animation(world, item)
		return true
	return false
		
		
func drop_spell_item(world: Node3D) -> bool:
	if spell:
		var item := population.entity_manager.get_world_item(World.Item.SPELL) as SpellPaper
		item.position = position
		item.spell = spell
		if item.get_parent() == null:
			world.add_child(item)
		drop_animation(world, item)
		return true
	return false
		
func drop_key_item(world: Node3D) -> bool:
	if key != 0:
		var item := population.entity_manager.get_world_item(World.Item.KEY) as KeyPrism
		item.position = position
		item.key = key
		if item.get_parent() == null:
			world.add_child(item)
		drop_animation(world, item)
		return true
	return false

func drop_coin_items(world: Node3D) -> bool:
	if not coins.is_empty():
		for coin in coins:
			var item := population.entity_manager.get_world_item(World.Item.COIN) as CoinDisc
			item.position = position + Rand.point_in_circle(1.0 + log(coins.size()), 0)
			item.amount = coin
			if item.get_parent() == null:
				world.add_child(item)
			drop_animation(world, item)
		return true
	return false
	
func drop_health_item(world: Node3D) -> bool:
	if key != 0:
		var item := population.entity_manager.get_world_item(World.Item.HEALTH) as RedCross
		item.position = position
		item.health = health
		if item.get_parent() == null:
			world.add_child(item)
		drop_animation(world, item)
		return true
	return false

func drop_note_item(world: Node3D) -> bool:
	if note_id != "":
		var item := population.entity_manager.get_world_item(World.Item.NOTE) as ScrollNote
		item.position = position
		item.note_id = note_id
		if item.get_parent() == null:
			world.add_child(item)
		drop_animation(world, item)
		return true
	return false

func drop_animation(world: Node3D, item: Node3D) -> void:
	var explosion: Node3D = preload("res://Characters/Enemy/enemy_die.tscn").instantiate()
	var source := explosion.get_node("source") as GPUParticles3D
	source.one_shot = false
	(source.process_material as ParticleProcessMaterial).emission_box_extents = Vector3(3, 3, 3)
	(source.process_material as ParticleProcessMaterial).color = Color(0.25, 0.25, 1)
		
	explosion.position = item.position
	explosion.global_transform = item.global_transform
	world.add_child(explosion)
	source.emitting = true
	
	UIAudioPlayer.drop_world_item(position)
	world.get_tree().create_timer(Globals.particle_system_lifetime(source)).timeout.connect(func() -> void: explosion.queue_free())
