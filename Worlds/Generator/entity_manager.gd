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

var buffer_enemies: Array[EntityBuffer] = []

var buffer_target: EntityBuffer
var buffer_artifact: EntityBuffer
var buffer_coin: EntityBuffer
var buffer_spell: EntityBuffer
var buffer_key: EntityBuffer
var buffer_health: EntityBuffer
var buffer_note: EntityBuffer
var buffer_flag: EntityBuffer

var buffer_house_ruined_01: EntityBuffer
var buffer_house_ruined_02: EntityBuffer
var buffer_house_ruined_03: EntityBuffer
var buffer_tower_base: EntityBuffer
var buffer_tower_body: EntityBuffer
var buffer_tower_head: EntityBuffer

func _init() -> void:
	var deinit_enemy := func(node: Enemy) -> void:
		node.position.y = -1000
		node.hide()
		node.kind = World.Enemy.NONE
		node.process_mode = Node.PROCESS_MODE_DISABLED
		var col: CollisionShape3D = node.get_node("./Collision")
		var area: CollisionShape3D = node.get_node("./WetArea/WetCollision")
		col.disabled = true
		area.disabled = col.disabled
		if node.is_node_ready():
			node.animation_tree.active = false
	var deinit_world_item := func(node: WorldItem) -> void:
		node.position.y = -1000
		node.is_active = false
	var deinit_building := func(node: Building) -> void:
		node.position.y = -1000
		node.is_active = false
	
	buffer_foliage_lod0 = Foliage.new(0)
	buffer_foliage_lod1 = Foliage.new(1)
	
	for kind: World.Enemy in World.Enemy.values():
		if kind == World.Enemy.NONE: continue
		var buffer := EntityBuffer.new(10, func() -> Enemy: return Enemy.make(kind), deinit_enemy, str(World.Enemy.keys()[kind]))
		buffer_enemies.append(buffer)

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
	var make_flag := func() -> WorldItem:
		var result := Flag.make(); result.custom_free = free_world_item
		return result
		
	var make_house_ruined_01 := func() -> Building:
		var result := Building.make(World.Building.HOUSE_RUINED_01); result.custom_free = free_building
		return result
	var make_house_ruined_02 := func() -> Building:
		var result := Building.make(World.Building.HOUSE_RUINED_02); result.custom_free = free_building
		return result
	var make_house_ruined_03 := func() -> Building:
		var result := Building.make(World.Building.HOUSE_RUINED_03); result.custom_free = free_building
		return result
	var make_tower_base := func() -> Building:
		var result := Building.make(World.Building.TOWER_BASE); result.custom_free = free_building
		return result
	var make_tower_body := func() -> Building:
		var result := Building.make(World.Building.TOWER_BODY); result.custom_free = free_building
		return result
	var make_tower_head := func() -> Building:
		var result := Building.make(World.Building.TOWER_HEAD); result.custom_free = free_building
		return result
	
	buffer_target = EntityBuffer.new(20, make_target_shape, deinit_world_item, "TARGET")
	buffer_artifact = EntityBuffer.new(10, make_artifact, deinit_world_item, "ARTIFACT")
	buffer_coin = EntityBuffer.new(10, make_coin, deinit_world_item, "COIN")
	buffer_key = EntityBuffer.new(10, make_key, deinit_world_item, "KEY")
	buffer_spell = EntityBuffer.new(10, make_spell, deinit_world_item, "SPELL")
	buffer_health = EntityBuffer.new(10, make_health, deinit_world_item, "HEALTH")
	buffer_note = EntityBuffer.new(10, make_note, deinit_world_item, "NOTE")
	buffer_flag = EntityBuffer.new(10, make_flag, deinit_world_item, "FLAG")
	
	buffer_house_ruined_01 = EntityBuffer.new(10, make_house_ruined_01, deinit_building, "HOUSE_RUINED_01")
	buffer_house_ruined_02 = EntityBuffer.new(10, make_house_ruined_02, deinit_building, "HOUSE_RUINED_02")
	buffer_house_ruined_03 = EntityBuffer.new(10, make_house_ruined_03, deinit_building, "HOUSE_RUINED_03")
	
	buffer_tower_base = EntityBuffer.new(10, make_tower_base, deinit_building, "TOWER_BASE")
	buffer_tower_body = EntityBuffer.new(20, make_tower_body, deinit_building, "TOWER_BODY")
	buffer_tower_head = EntityBuffer.new(20, make_tower_head, deinit_building, "TOWER_HEAD")

		
func get_enemy(kind: World.Enemy) -> Enemy:
	return buffer_enemies[kind].get_entity()

func free_enemy(enemy: Enemy, kind: World.Enemy = World.Enemy.NONE) -> void:
	if kind == World.Enemy.NONE:
		if enemy.kind != World.Enemy.NONE:
			buffer_enemies[enemy.kind].free_entity(enemy)
	else:
		buffer_enemies[kind].free_entity(enemy)
		
func get_world_item(kind: World.Item) -> WorldItem:
	match kind:
		World.Item.TARGET: return buffer_target.get_entity()
		World.Item.ARTIFACT: return buffer_artifact.get_entity()
		World.Item.KEY: return buffer_key.get_entity()
		World.Item.COIN: return buffer_coin.get_entity()
		World.Item.SPELL: return buffer_spell.get_entity()
		World.Item.HEALTH: return buffer_health.get_entity()
		World.Item.NOTE: return buffer_note.get_entity()
		World.Item.FLAG: return buffer_flag.get_entity()
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
		World.Item.FLAG: buffer_flag.free_entity(node)
		
func get_building(kind: World.Building, config: Dictionary = {}) -> Building:
	match kind:
		World.Building.HOUSE_RUINED_01: return buffer_house_ruined_01.get_entity()
		World.Building.HOUSE_RUINED_02: return buffer_house_ruined_02.get_entity()
		World.Building.HOUSE_RUINED_03: return buffer_house_ruined_03.get_entity()
		World.Building.TOWER_BASE: 
			var base := buffer_tower_base.get_entity() as Building
			var body_count := config.get("height", 0) as int
			for i in body_count:
				var body := buffer_tower_body.get_entity() as Building
				body.position.y = (i + 1) * 3.0
				body.rotate(Vector3.UP, i * PI)
				base.add_child(body)
			var head := buffer_tower_head.get_entity() as Building
			head.position.y = (body_count + 1) * 3.0
			head.rotate(Vector3.UP, (body_count + 1) * PI)
			base.add_child(head)
			return base
	return buffer_house_ruined_01.get_entity()

func free_building(node: Building) -> void:
	match node.kind:
		World.Building.HOUSE_RUINED_01: buffer_house_ruined_01.free_entity(node)
		World.Building.HOUSE_RUINED_02: buffer_house_ruined_02.free_entity(node)
		World.Building.HOUSE_RUINED_03: buffer_house_ruined_03.free_entity(node)
		World.Building.TOWER_BASE:
			for child: Building in node.get_children():
				match child.kind:
					World.Building.TOWER_BODY: buffer_tower_body.free_entity(node)
					World.Building.TOWER_HEAD: buffer_tower_head.free_entity(node)
			buffer_tower_base.free_entity(node)
