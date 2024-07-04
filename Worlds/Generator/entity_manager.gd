class_name EntityManager

class EntityBuffer:
	var buffer: Array[Node3D] = []
	var high_watermark: int = 0
	var allocater: Callable
	var deinit: Callable
	var tag: String
	
	func _init(capacity: int, alloc: Callable, deiniter: Callable, k: String = "") -> void:
		buffer = []
		high_watermark = 0
		allocater = alloc
		deinit = deiniter
		tag = k
		for i in capacity:
			buffer.append(allocater.call())
		
	func get_entity() -> Node3D:
		if high_watermark == buffer.size():
			for i in mini(buffer.size(), 20):
				buffer.append(allocater.call())
		high_watermark += 1
		return buffer[high_watermark - 1]
			
	func free_entity(node: Node3D) -> void:
		var i := 0
		var index := -1
		for n in buffer:
			if n == node:
				index = i
				break
			i += 1
		
		if index == -1:
			push_error("free node that does not exist")
			return
		
		high_watermark -= 1
		var temp := buffer[index]
		buffer[index] = buffer[high_watermark]
		buffer[high_watermark] = temp
		deinit.call(temp)
		

var buffer_round_trees: EntityBuffer
var buffer_branched_trees: EntityBuffer
var buffer_pyramid_trees: EntityBuffer
var buffer_christmas_trees: EntityBuffer
var buffer_safari_trees: EntityBuffer

var buffer_undead: EntityBuffer
var buffer_mole: EntityBuffer
var buffer_walker: EntityBuffer
var buffer_fish: EntityBuffer
var buffer_bat: EntityBuffer
var buffer_birdman: EntityBuffer
var buffer_human: EntityBuffer

var buffer_house_single: EntityBuffer
var buffer_house_double: EntityBuffer
var buffer_well: EntityBuffer

var buffer_target: EntityBuffer
var buffer_artifact: EntityBuffer
var buffer_coin: EntityBuffer
var buffer_spell: EntityBuffer
var buffer_key: EntityBuffer

func _init() -> void:
	var deinit_tree := func(node: Trees) -> void:
		node.position.y = -1000
		var s: CollisionShape3D = node.get_node("./static/shape")
		if s != null:
			s.disabled = true
	var deinit_enemy := func(node: Enemy) -> void:
		node.position.y = -1000
		node.kind = World.Enemy.NONE
		var col: CollisionShape3D = node.get_node("./Collision")
		var area: CollisionShape3D = node.get_node("./WetArea/WetCollision")
		col.disabled = true
		area.disabled = col.disabled
		node.animation_tree.active = false
	var deinit_building := func(node: Buildings) -> void:
		node.position.y = -1000
		var s: CollisionShape3D = node.get_node("./static/shape")
		if s != null:
			s.disabled = true
	var deinit_world_item := func(node: WorldItem) -> void:
		node.position.y = -1000
		node.is_active = false
	
	buffer_round_trees = EntityBuffer.new(10, func() -> Trees: return Trees.make(World.Foliage.TREE_ROUND), deinit_tree, "round")
	buffer_branched_trees = EntityBuffer.new(10, func() -> Trees: return Trees.make(World.Foliage.TREE_BRANCHED), deinit_tree, "branched")
	buffer_pyramid_trees = EntityBuffer.new(10, func() -> Trees: return Trees.make(World.Foliage.TREE_PYRAMID), deinit_tree, "pyramid")
	buffer_christmas_trees = EntityBuffer.new(10, func() -> Trees: return Trees.make(World.Foliage.TREE_CHRISTMAS), deinit_tree, "christmas")
	buffer_safari_trees = EntityBuffer.new(10, func() -> Trees: return Trees.make(World.Foliage.TREE_SAFARI), deinit_tree, "safari")
	
	buffer_undead = EntityBuffer.new(10, func() -> Undead: return Enemy.make(World.Enemy.UNDEAD), deinit_enemy, "undead")
	buffer_mole = EntityBuffer.new(10, func() -> Mole: return Enemy.make(World.Enemy.MOLE), deinit_enemy, "mole")
	buffer_walker = EntityBuffer.new(10, func() -> Walker: return Enemy.make(World.Enemy.WALKER), deinit_enemy, "walker")
	buffer_fish = EntityBuffer.new(10, func() -> Fish: return Enemy.make(World.Enemy.FISH), deinit_enemy, "fish")
	buffer_bat = EntityBuffer.new(10, func() -> Bat: return Enemy.make(World.Enemy.BAT), deinit_enemy, "bat")
	buffer_birdman = EntityBuffer.new(10, func() -> Birdman: return Enemy.make(World.Enemy.BIRDMAN), deinit_enemy, "birdman")
	buffer_human = EntityBuffer.new(10, func() -> Human: return Enemy.make(World.Enemy.HUMAN), deinit_enemy, "human")
	
	buffer_house_single = EntityBuffer.new(10, func() -> Buildings: return Buildings.make(World.Building.FANTASY_VALLEY_SINGLE), deinit_building, "single")
	buffer_house_double = EntityBuffer.new(10, func() -> Buildings: return Buildings.make(World.Building.FANTASY_VALLEY_DOUBLE), deinit_building, "double")
	buffer_well= EntityBuffer.new(10, func() -> Buildings: return Buildings.make(World.Building.FANTASY_WELL), deinit_building, "well")
	
	buffer_target = EntityBuffer.new(10, func() -> WorldItem: return TargetShape.make(), deinit_world_item, "target")
	buffer_artifact = EntityBuffer.new(0, func() -> WorldItem: return ArtifactCube.make(), deinit_world_item, "artifact")
	buffer_coin = EntityBuffer.new(0, func() -> WorldItem: return CoinDisc.make(), deinit_world_item, "coin")
	buffer_key = EntityBuffer.new(0, func() -> WorldItem: return KeyPrism.make(), deinit_world_item, "key")
	buffer_spell = EntityBuffer.new(0, func() -> WorldItem: return SpellPaper.make(), deinit_world_item, "spell")

func get_tree(kind: World.Foliage) -> Trees:
	match kind:
		World.Foliage.TREE_ROUND: return buffer_round_trees.get_entity()
		World.Foliage.TREE_BRANCHED: return buffer_branched_trees.get_entity()
		World.Foliage.TREE_PYRAMID: return buffer_pyramid_trees.get_entity()
		World.Foliage.TREE_CHRISTMAS: return buffer_christmas_trees.get_entity()
		World.Foliage.TREE_SAFARI: return buffer_safari_trees.get_entity()
	return buffer_round_trees.get_entity()

func free_tree(tree: Trees) -> void:
	match tree.kind:
		World.Foliage.TREE_ROUND: buffer_round_trees.free_entity(tree)
		World.Foliage.TREE_BRANCHED: buffer_branched_trees.free_entity(tree)
		World.Foliage.TREE_PYRAMID: buffer_pyramid_trees.free_entity(tree)
		World.Foliage.TREE_CHRISTMAS: buffer_christmas_trees.free_entity(tree)
		World.Foliage.TREE_SAFARI: buffer_safari_trees.free_entity(tree)
		
func get_enemy(kind: World.Enemy) -> Enemy:
	match kind:
		World.Enemy.UNDEAD: return buffer_undead.get_entity()
		World.Enemy.MOLE: return buffer_mole.get_entity()
		World.Enemy.WALKER: return buffer_walker.get_entity()
		World.Enemy.FISH: return buffer_fish.get_entity()
		World.Enemy.BAT: return buffer_bat.get_entity()
		World.Enemy.BIRDMAN: return buffer_birdman.get_entity()
		World.Enemy.HUMAN: return buffer_human.get_entity()
	return buffer_undead.get_entity()

func free_enemy(enemy: Enemy) -> void:
	match enemy.kind:
		World.Enemy.UNDEAD: buffer_undead.free_entity(enemy)
		World.Enemy.MOLE: buffer_mole.free_entity(enemy)
		World.Enemy.WALKER: buffer_walker.free_entity(enemy)
		World.Enemy.FISH: buffer_fish.free_entity(enemy)
		World.Enemy.BAT: buffer_bat.free_entity(enemy)
		World.Enemy.BIRDMAN: buffer_birdman.free_entity(enemy)
		World.Enemy.HUMAN: buffer_human.free_entity(enemy)
		
func get_building(kind: World.Building) -> Buildings:
	match kind:
		World.Building.FANTASY_VALLEY_SINGLE: return buffer_house_single.get_entity()
		World.Building.FANTASY_VALLEY_DOUBLE: return buffer_house_double.get_entity()
		World.Building.FANTASY_WELL: return buffer_well.get_entity()
	return buffer_undead.get_entity()

func free_building(building: Buildings) -> void:
	match building.entity_kind:
		World.Building.FANTASY_VALLEY_SINGLE: buffer_house_single.free_entity(building)
		World.Building.FANTASY_VALLEY_DOUBLE: buffer_house_double.free_entity(building)
		World.Building.FANTASY_WELL: buffer_well.free_entity(building)
		
func get_world_item(kind: World.Item) -> WorldItem:
	match kind:
		World.Item.TARGET: buffer_target.get_entity()
		World.Item.ARTIFACT: buffer_artifact.get_entity()
		World.Item.KEY: buffer_key.get_entity()
		World.Item.COIN: buffer_coin.get_entity()
		World.Item.SPELL: buffer_spell.get_entity()
	return buffer_target.get_entity()

func free_world_item(node: WorldItem) -> void:
	match node.kind:
		World.Item.TARGET: buffer_target.free_entity(node)
		World.Item.ARTIFACT: buffer_artifact.free_entity(node)
		World.Item.KEY: buffer_key.free_entity(node)
		World.Item.COIN: buffer_coin.free_entity(node)
		World.Item.SPELL: buffer_spell.free_entity(node)
