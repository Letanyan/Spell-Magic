class_name EntityManager

class EntityBuffer:
	var buffer: Array = []
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
			
	func append(entity: Variant) -> void:
		if high_watermark == buffer.size():
			for i in mini(buffer.size(), 20):
				buffer.append(allocater.call())
		high_watermark += 1
		buffer[high_watermark - 1] = entity
		
	func pop_back() -> Variant:
		high_watermark -= 1
		var temp: Variant = buffer[high_watermark]
		deinit.call(temp)
		return temp
		
	func is_empty() -> bool:
		return high_watermark == 0
		
	func size() -> int:
		return high_watermark
		
	func get_entity() -> Variant:
		if high_watermark == buffer.size():
			for i in mini(buffer.size(), 20):
				buffer.append(allocater.call())
		high_watermark += 1
		return buffer[high_watermark - 1]
			
	func free_entity(node: Variant) -> void:
		var index := -1
		var i := maxi(last_index_check, 0)
		var j := i
		var found := false
		
		var min_bound := maxi(mini(last_index_check, high_watermark - last_index_check - 1), 0)
		var k := 0
		#var visited: Array[int] = []
		while k <= min_bound:
			#visited.append(i)
			if buffer[i] == node:
				index = i
				found = true
				break
			#visited.append(j)
			if buffer[j] == node:
				index = j
				found = true
				break
			i -= 1
			j += 1
			k += 1
			
		if not found:
			if i == -1:
				k = j
				while k <= high_watermark:
					#visited.append(k)
					if buffer[k] == node:
						index = k
						break
					k += 1
			else:
				k = i
				while k >= 0:
					#visited.append(k)
					if buffer[k] == node:
						index = k
						break
					k -= 1
		
		if index == -1:
			#print(visited)
			push_error(tag + ": free node that does not exist: ", str(node))
			return
		
		last_index_check = index
		high_watermark -= 1
		var temp: Variant = buffer[index]
		buffer[index] = buffer[high_watermark]
		buffer[high_watermark] = temp
		deinit.call(temp)
		
var buffer_foliage_lod0: Foliage
var buffer_foliage_lod1: Foliage

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

var buffer_target: EntityBuffer
var buffer_artifact: EntityBuffer
var buffer_coin: EntityBuffer
var buffer_spell: EntityBuffer
var buffer_key: EntityBuffer
var buffer_health: EntityBuffer
var buffer_note: EntityBuffer

func _init() -> void:
	var deinit_enemy := func(node: Enemy) -> void:
		node.position.y = -1000
		node.kind = World.Enemy.NONE
		var col: CollisionShape3D = node.get_node("./Collision")
		var area: CollisionShape3D = node.get_node("./WetArea/WetCollision")
		col.disabled = true
		area.disabled = col.disabled
		if node.is_node_ready():
			node.animation_tree.active = false
	var deinit_world_item := func(node: WorldItem) -> void:
		node.position.y = -1000
		node.is_active = false
	
	buffer_foliage_lod0 = Foliage.new(0)
	buffer_foliage_lod1 = Foliage.new(1)
	
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
	var make_note := func() -> WorldItem:
		var result := ScrollNote.make(); result.custom_free = free_world_item
		return result
	
	buffer_target = EntityBuffer.new(20, make_target_shape, deinit_world_item, "TARGET")
	buffer_artifact = EntityBuffer.new(10, make_artifact, deinit_world_item, "ARTIFACT")
	buffer_coin = EntityBuffer.new(10, make_coin, deinit_world_item, "COIN")
	buffer_key = EntityBuffer.new(10, make_key, deinit_world_item, "KEY")
	buffer_spell = EntityBuffer.new(10, make_spell, deinit_world_item, "SPELL")
	buffer_health = EntityBuffer.new(10, make_health, deinit_world_item, "HEALTH")
	buffer_note = EntityBuffer.new(10, make_note, deinit_world_item, "NOTE")

		
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
		
func get_world_item(kind: World.Item) -> WorldItem:
	match kind:
		World.Item.TARGET: return buffer_target.get_entity()
		World.Item.ARTIFACT: return buffer_artifact.get_entity()
		World.Item.KEY: return buffer_key.get_entity()
		World.Item.COIN: return buffer_coin.get_entity()
		World.Item.SPELL: return buffer_spell.get_entity()
		World.Item.HEALTH: return buffer_health.get_entity()
		World.Item.NOTE: return buffer_note.get_entity()
	return buffer_target.get_entity()

func free_world_item(node: WorldItem) -> void:
	match node.kind:
		World.Item.TARGET: buffer_target.free_entity(node)
		World.Item.ARTIFACT: buffer_artifact.free_entity(node)
		World.Item.KEY: buffer_key.free_entity(node)
		World.Item.COIN: buffer_coin.free_entity(node)
		World.Item.SPELL: buffer_spell.free_entity(node)
		World.Item.HEALTH: buffer_health.free_entity(node)
		World.Item.NOTE: buffer_note.free_entity(node)
