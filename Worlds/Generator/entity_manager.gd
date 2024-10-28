class_name EntityManager

class EntityBuffer:
	var buffer: Array[Node3D] = []
	var high_watermark: int = 0
	var allocater: Callable
	var deinit: Callable
	var tag: String
	var last_index_check: int = -1
	
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
		var index := -1
		var i := maxi(last_index_check - 1, 0)
		var found := false
		while i < high_watermark:
			if buffer[i] == node:
				index = i
				found = true
				break
			i += 1
		if not found and last_index_check > 2:
			i = last_index_check - 2
			while i >= 0:
				if buffer[i] == node:
					index = i
					break
				i -= 1
		
		if index == -1:
			push_error(tag + ": free node that does not exist: ", str(node.get_instance_id()))
			return
		
		last_index_check = index
		high_watermark -= 1
		var temp := buffer[index]
		buffer[index] = buffer[high_watermark]
		buffer[high_watermark] = temp
		deinit.call(temp)
		

var buffer_tree_round: EntityBuffer
var buffer_tree_branched: EntityBuffer
var buffer_tree_pyramid: EntityBuffer
var buffer_tree_christmas: EntityBuffer
var buffer_tree_safari: EntityBuffer
var buffer_rock_egg: EntityBuffer
var buffer_rock_flattop: EntityBuffer
var buffer_rock_overhang: EntityBuffer
var buffer_rock_squashed: EntityBuffer
var buffer_rock_tall: EntityBuffer
var buffer_bush_round: EntityBuffer
var buffer_bush_sprout: EntityBuffer
var buffer_bush_tall: EntityBuffer
var buffer_flowers_sun2: EntityBuffer
var buffer_flowers_sun3: EntityBuffer
var buffer_grass_reed: EntityBuffer
var buffer_grass_shrub: EntityBuffer
var buffer_mushroom_bulb: EntityBuffer
var buffer_mushroom_pointed: EntityBuffer

var buffer_fish: EntityBuffer
var buffer_bird: EntityBuffer
var buffer_fungi: EntityBuffer
var buffer_hot_blob: EntityBuffer
var buffer_mushroom: EntityBuffer
var buffer_snot_blob: EntityBuffer
var buffer_snot_spike: EntityBuffer
var buffer_walker_head: EntityBuffer
var buffer_wizard: EntityBuffer

var buffer_undead: EntityBuffer
var buffer_mole: EntityBuffer
var buffer_walker: EntityBuffer
var buffer_birdman: EntityBuffer
var buffer_fishman: EntityBuffer
var buffer_bluemon: EntityBuffer
var buffer_frog: EntityBuffer
var buffer_mushking: EntityBuffer
var buffer_rabbit: EntityBuffer


var buffer_bat: EntityBuffer
var buffer_dragon: EntityBuffer
var buffer_dragoon: EntityBuffer
var buffer_ghost: EntityBuffer
var buffer_ghostly: EntityBuffer
var buffer_batty: EntityBuffer
var buffer_bee: EntityBuffer
var buffer_bumble_bee: EntityBuffer
var buffer_undead_head: EntityBuffer

var buffer_house_single: EntityBuffer
var buffer_house_double: EntityBuffer
var buffer_well: EntityBuffer

var buffer_target: EntityBuffer
var buffer_artifact: EntityBuffer
var buffer_coin: EntityBuffer
var buffer_spell: EntityBuffer
var buffer_key: EntityBuffer
var buffer_health: EntityBuffer

func _init() -> void:
	var deinit_foliage := func(node: Foliage) -> void:
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
	
	buffer_tree_round = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.TREE_ROUND), deinit_foliage, "TREE_ROUND")
	buffer_tree_branched = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.TREE_BRANCHED), deinit_foliage, "TREE_BRANCHED")
	buffer_tree_pyramid = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.TREE_PYRAMID), deinit_foliage, "TREE_PYRAMID")
	buffer_tree_christmas = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.TREE_CHRISTMAS), deinit_foliage, "TREE_CHRISTMAS")
	buffer_tree_safari = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.TREE_SAFARI), deinit_foliage, "TREE_SAFARI")
	buffer_rock_egg = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.ROCK_EGG), deinit_foliage, "ROCK_EGG")
	buffer_rock_flattop = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.ROCK_FLATTOP), deinit_foliage, "ROCK_FLATTOP")
	buffer_rock_overhang = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.ROCK_OVERHANG), deinit_foliage, "ROCK_OVERHANG")
	buffer_rock_squashed = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.ROCK_SQUASHED), deinit_foliage, "ROCK_SQUASHED")
	buffer_rock_tall = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.ROCK_TALL), deinit_foliage, "ROCK_TALL")
	buffer_bush_round = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.BUSH_ROUND), deinit_foliage, "BUSH_ROUND")
	buffer_bush_sprout = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.BUSH_SPROUT), deinit_foliage, "BUSH_SPROUT")
	buffer_bush_tall = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.BUSH_TALL), deinit_foliage, "BUSH_TALL")
	buffer_flowers_sun2 = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.FLOWERS_SUN2), deinit_foliage, "FLOWERS_SUN2")
	buffer_flowers_sun3 = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.FLOWERS_SUN3), deinit_foliage, "FLOWERS_SUN3")
	buffer_grass_reed = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.GRASS_REED), deinit_foliage, "GRASS_REED")
	buffer_grass_shrub = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.GRASS_SHRUB), deinit_foliage, "GRASS_SHRUB")
	buffer_mushroom_bulb = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.MUSHROOM_BULB), deinit_foliage, "MUSHROOM_BULB")
	buffer_mushroom_pointed = EntityBuffer.new(10, func() -> Foliage: return Foliage.make(World.Foliage.MUSHROOM_POINTED), deinit_foliage, "MUSHROOM_POINTED")
	
	buffer_fish = EntityBuffer.new(10, func() -> Fish: return Enemy.make(World.Enemy.FISH), deinit_enemy, "FISH")
	buffer_bird = EntityBuffer.new(10, func() -> Bird: return Enemy.make(World.Enemy.BIRD), deinit_enemy, "BIRD")
	buffer_fungi = EntityBuffer.new(10, func() -> Fungi: return Enemy.make(World.Enemy.FUNGI), deinit_enemy, "FUNGI")
	buffer_hot_blob = EntityBuffer.new(10, func() -> HotBlob: return Enemy.make(World.Enemy.HOT_BLOB), deinit_enemy, "HOT_BLOB")
	buffer_mushroom = EntityBuffer.new(10, func() -> Mushroom: return Enemy.make(World.Enemy.MUSHROOM), deinit_enemy, "MUSHROOM")
	buffer_undead = EntityBuffer.new(10, func() -> Undead: return Enemy.make(World.Enemy.UNDEAD), deinit_enemy, "UNDEAD")
	buffer_mole = EntityBuffer.new(10, func() -> Mole: return Enemy.make(World.Enemy.MOLE), deinit_enemy, "MOLE")
	buffer_walker = EntityBuffer.new(10, func() -> Walker: return Enemy.make(World.Enemy.WALKER), deinit_enemy, "WALKER")
	buffer_birdman = EntityBuffer.new(10, func() -> Birdman: return Enemy.make(World.Enemy.BIRDMAN), deinit_enemy, "BIRDMAN")
	buffer_fishman = EntityBuffer.new(10, func() -> Fishman: return Enemy.make(World.Enemy.FISHMAN), deinit_enemy, "FISHMAN")
	buffer_bluemon = EntityBuffer.new(10, func() -> Bluemon: return Enemy.make(World.Enemy.BLUEMON), deinit_enemy, "BLUEMON")
	buffer_frog = EntityBuffer.new(10, func() -> Frog: return Enemy.make(World.Enemy.FROG), deinit_enemy, "FROG")
	buffer_mushking = EntityBuffer.new(10, func() -> Mushking: return Enemy.make(World.Enemy.MUSHKING), deinit_enemy, "MUSHKING")
	buffer_rabbit = EntityBuffer.new(10, func() -> Rabbit: return Enemy.make(World.Enemy.RABBIT), deinit_enemy, "RABBIT")
	buffer_bat = EntityBuffer.new(10, func() -> Bat: return Enemy.make(World.Enemy.BAT), deinit_enemy, "BAT")
	buffer_dragon = EntityBuffer.new(10, func() -> Dragon: return Enemy.make(World.Enemy.DRAGON), deinit_enemy, "DRAGON")
	buffer_dragoon = EntityBuffer.new(10, func() -> Dragoon: return Enemy.make(World.Enemy.DRAGOON), deinit_enemy, "DRAGOON")
	buffer_ghost = EntityBuffer.new(10, func() -> Ghost: return Enemy.make(World.Enemy.GHOST), deinit_enemy, "GHOST")
	buffer_ghostly = EntityBuffer.new(10, func() -> Ghostly: return Enemy.make(World.Enemy.GHOSTLY), deinit_enemy, "GHOSTLY")
	buffer_batty = EntityBuffer.new(10, func() -> Batty: return Enemy.make(World.Enemy.BATTY), deinit_enemy, "BATTY")
	buffer_bee = EntityBuffer.new(10, func() -> Bee: return Enemy.make(World.Enemy.BEE), deinit_enemy, "BEE")
	buffer_bumble_bee = EntityBuffer.new(10, func() -> BumbleBee: return Enemy.make(World.Enemy.BUMBLE_BEE), deinit_enemy, "BUMBLE_BEE")
	buffer_undead_head = EntityBuffer.new(10, func() -> UndeadHead: return Enemy.make(World.Enemy.UNDEAD_HEAD), deinit_enemy, "UNDEAD_HEAD")
	buffer_snot_blob = EntityBuffer.new(10, func() -> SnotBlob: return Enemy.make(World.Enemy.SNOT_BLOB), deinit_enemy, "SNOT_BLOB")
	buffer_snot_spike = EntityBuffer.new(10, func() -> SnotSpike: return Enemy.make(World.Enemy.SNOT_SPIKE), deinit_enemy, "SNOT_SPIKE")
	buffer_walker_head = EntityBuffer.new(10, func() -> WalkerHead: return Enemy.make(World.Enemy.WALKER_HEAD), deinit_enemy, "WALKER_HEAD")
	buffer_wizard = EntityBuffer.new(10, func() -> Wizard: return Enemy.make(World.Enemy.WIZARD), deinit_enemy, "WIZARD")
	
	buffer_house_single = EntityBuffer.new(10, func() -> Buildings: return Buildings.make(World.Building.FANTASY_VALLEY_SINGLE), deinit_building, "single")
	buffer_house_double = EntityBuffer.new(10, func() -> Buildings: return Buildings.make(World.Building.FANTASY_VALLEY_DOUBLE), deinit_building, "double")
	buffer_well = EntityBuffer.new(10, func() -> Buildings: return Buildings.make(World.Building.FANTASY_WELL), deinit_building, "well")
	

	var make_target_shape := func() -> WorldItem:
		var result := TargetShape.make(); result.custom_free = free_world_item
		return result
	var make_artifact := func() -> WorldItem:
		var result := ArtifactCube.make(); result.custom_free = free_world_item
		return result
	var make_coin := func() -> WorldItem:
		var result := CoinDisc.make(); result.custom_free = free_world_item
		return result
	var make_key := func() -> WorldItem:
		var result := KeyPrism.make(); result.custom_free = free_world_item
		return result
	var make_spell := func() -> WorldItem:
		var result := SpellPaper.make(); result.custom_free = free_world_item
		return result
	var make_health := func() -> WorldItem:
		var result := RedCross.make(); result.custom_free = free_world_item
		return result
	
	buffer_target = EntityBuffer.new(10, make_target_shape, deinit_world_item, "TARGET")
	buffer_artifact = EntityBuffer.new(10, make_artifact, deinit_world_item, "ARTIFACT")
	buffer_coin = EntityBuffer.new(10, make_coin, deinit_world_item, "COIN")
	buffer_key = EntityBuffer.new(10, make_key, deinit_world_item, "KEY")
	buffer_spell = EntityBuffer.new(10, make_spell, deinit_world_item, "SPELL")
	buffer_health = EntityBuffer.new(10, make_health, deinit_world_item, "HEALTH")


func get_foliage(kind: World.Foliage) -> Foliage:
	match kind:
		World.Foliage.TREE_ROUND: return buffer_tree_round.get_entity()
		World.Foliage.TREE_BRANCHED: return buffer_tree_branched.get_entity()
		World.Foliage.TREE_PYRAMID: return buffer_tree_pyramid.get_entity()
		World.Foliage.TREE_CHRISTMAS: return buffer_tree_christmas.get_entity()
		World.Foliage.TREE_SAFARI: return buffer_tree_safari.get_entity()
		World.Foliage.ROCK_EGG: return buffer_rock_egg.get_entity()
		World.Foliage.ROCK_FLATTOP: return buffer_rock_flattop.get_entity()
		World.Foliage.ROCK_OVERHANG: return buffer_rock_overhang.get_entity()
		World.Foliage.ROCK_SQUASHED: return buffer_rock_squashed.get_entity()
		World.Foliage.ROCK_TALL: return buffer_rock_tall.get_entity()
		World.Foliage.BUSH_ROUND: return buffer_bush_round.get_entity()
		World.Foliage.BUSH_SPROUT: return buffer_bush_sprout.get_entity()
		World.Foliage.BUSH_TALL: return buffer_bush_tall.get_entity()
		World.Foliage.FLOWERS_SUN2: return buffer_flowers_sun2.get_entity()
		World.Foliage.FLOWERS_SUN3: return buffer_flowers_sun3.get_entity()
		World.Foliage.GRASS_REED: return buffer_grass_reed.get_entity()
		World.Foliage.GRASS_SHRUB: return buffer_grass_shrub.get_entity()
		World.Foliage.MUSHROOM_BULB: return buffer_mushroom_bulb.get_entity()
		World.Foliage.MUSHROOM_POINTED: return buffer_mushroom_pointed.get_entity()
	return buffer_tree_round.get_entity()

func free_foliage(foliage: Foliage) -> void:
	match foliage.kind:
		World.Foliage.TREE_ROUND: buffer_tree_round.free_entity(foliage)
		World.Foliage.TREE_BRANCHED: buffer_tree_branched.free_entity(foliage)
		World.Foliage.TREE_PYRAMID: buffer_tree_pyramid.free_entity(foliage)
		World.Foliage.TREE_CHRISTMAS: buffer_tree_christmas.free_entity(foliage)
		World.Foliage.TREE_SAFARI: buffer_tree_safari.free_entity(foliage)
		World.Foliage.ROCK_EGG: buffer_rock_egg.free_entity(foliage)
		World.Foliage.ROCK_FLATTOP: buffer_rock_flattop.free_entity(foliage)
		World.Foliage.ROCK_OVERHANG: buffer_rock_overhang.free_entity(foliage)
		World.Foliage.ROCK_SQUASHED: buffer_rock_squashed.free_entity(foliage)
		World.Foliage.ROCK_TALL: buffer_rock_tall.free_entity(foliage)
		World.Foliage.BUSH_ROUND: buffer_bush_round.free_entity(foliage)
		World.Foliage.BUSH_SPROUT: buffer_bush_sprout.free_entity(foliage)
		World.Foliage.BUSH_TALL: buffer_bush_tall.free_entity(foliage)
		World.Foliage.FLOWERS_SUN2: buffer_flowers_sun2.free_entity(foliage)
		World.Foliage.FLOWERS_SUN3: buffer_flowers_sun3.free_entity(foliage)
		World.Foliage.GRASS_REED: buffer_grass_reed.free_entity(foliage)
		World.Foliage.GRASS_SHRUB: buffer_grass_shrub.free_entity(foliage)
		World.Foliage.MUSHROOM_BULB: buffer_mushroom_bulb.free_entity(foliage)
		World.Foliage.MUSHROOM_POINTED: buffer_mushroom_pointed.free_entity(foliage)
		
func get_enemy(kind: World.Enemy) -> Enemy:
	match kind:
		World.Enemy.FISH: return buffer_fish.get_entity()
		World.Enemy.UNDEAD: return buffer_undead.get_entity()
		World.Enemy.MOLE: return buffer_mole.get_entity()
		World.Enemy.WALKER: return buffer_walker.get_entity()
		World.Enemy.BIRDMAN: return buffer_birdman.get_entity()
		World.Enemy.FISHMAN: return buffer_fishman.get_entity()
		World.Enemy.BLUEMON: return buffer_bluemon.get_entity()
		World.Enemy.FROG: return buffer_frog.get_entity()
		World.Enemy.MUSHKING: return buffer_mushking.get_entity()
		World.Enemy.RABBIT: return buffer_rabbit.get_entity()
		World.Enemy.BAT: return buffer_bat.get_entity()
		World.Enemy.DRAGON: return buffer_dragon.get_entity()
		World.Enemy.DRAGOON: return buffer_dragoon.get_entity()
		World.Enemy.GHOST: return buffer_ghost.get_entity()
		World.Enemy.GHOSTLY: return buffer_ghostly.get_entity()
		World.Enemy.BIRD: return buffer_bird.get_entity()
		World.Enemy.FUNGI: return buffer_fungi.get_entity()
		World.Enemy.HOT_BLOB: return buffer_hot_blob.get_entity()
		World.Enemy.MUSHROOM: return buffer_mushroom.get_entity()
		World.Enemy.BATTY: return buffer_batty.get_entity()
		World.Enemy.BEE: return buffer_bee.get_entity()
		World.Enemy.BUMBLE_BEE: return buffer_bumble_bee.get_entity()
		World.Enemy.UNDEAD_HEAD: return buffer_undead_head.get_entity()
		World.Enemy.SNOT_BLOB: return buffer_snot_blob.get_entity()
		World.Enemy.SNOT_SPIKE: return buffer_snot_spike.get_entity()
		World.Enemy.WALKER_HEAD: return buffer_walker_head.get_entity()
		World.Enemy.WIZARD: return buffer_wizard.get_entity()
	return buffer_undead.get_entity()

func free_enemy(enemy: Enemy) -> void:
	match enemy.kind:
		World.Enemy.FISH: buffer_fish.free_entity(enemy)
		World.Enemy.UNDEAD: buffer_undead.free_entity(enemy)
		World.Enemy.MOLE: buffer_mole.free_entity(enemy)
		World.Enemy.WALKER: buffer_walker.free_entity(enemy)
		World.Enemy.BIRDMAN: buffer_birdman.free_entity(enemy)
		World.Enemy.FISHMAN: buffer_fishman.free_entity(enemy)
		World.Enemy.BLUEMON: buffer_bluemon.free_entity(enemy)
		World.Enemy.FROG: buffer_frog.free_entity(enemy)
		World.Enemy.MUSHKING: buffer_mushking.free_entity(enemy)
		World.Enemy.RABBIT: buffer_rabbit.free_entity(enemy)
		World.Enemy.BAT: buffer_bat.free_entity(enemy)
		World.Enemy.DRAGON: buffer_dragon.free_entity(enemy)
		World.Enemy.DRAGOON: buffer_dragoon.free_entity(enemy)
		World.Enemy.GHOST: buffer_ghost.free_entity(enemy)
		World.Enemy.GHOSTLY: buffer_ghostly.free_entity(enemy)
		World.Enemy.BIRD: buffer_bird.free_entity(enemy)
		World.Enemy.FUNGI: buffer_fungi.free_entity(enemy)
		World.Enemy.HOT_BLOB: buffer_hot_blob.free_entity(enemy)
		World.Enemy.MUSHROOM: buffer_mushroom.free_entity(enemy)
		World.Enemy.BATTY: buffer_batty.free_entity(enemy)
		World.Enemy.BEE: buffer_bee.free_entity(enemy)
		World.Enemy.BUMBLE_BEE: buffer_bumble_bee.free_entity(enemy)
		World.Enemy.UNDEAD_HEAD: buffer_undead_head.free_entity(enemy)
		World.Enemy.SNOT_BLOB: buffer_snot_blob.free_entity(enemy)
		World.Enemy.SNOT_SPIKE: buffer_snot_spike.free_entity(enemy)
		World.Enemy.WALKER_HEAD: buffer_walker_head.free_entity(enemy)
		World.Enemy.WIZARD: buffer_wizard.free_entity(enemy)
		
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
		World.Item.TARGET: return buffer_target.get_entity()
		World.Item.ARTIFACT: return buffer_artifact.get_entity()
		World.Item.KEY: return buffer_key.get_entity()
		World.Item.COIN: return buffer_coin.get_entity()
		World.Item.SPELL: return buffer_spell.get_entity()
		World.Item.HEALTH: return buffer_health.get_entity()
	return buffer_target.get_entity()

func free_world_item(node: WorldItem) -> void:
	match node.kind:
		World.Item.TARGET: buffer_target.free_entity(node)
		World.Item.ARTIFACT: buffer_artifact.free_entity(node)
		World.Item.KEY: buffer_key.free_entity(node)
		World.Item.COIN: buffer_coin.free_entity(node)
		World.Item.SPELL: buffer_spell.free_entity(node)
		World.Item.HEALTH: buffer_health.free_entity(node)
