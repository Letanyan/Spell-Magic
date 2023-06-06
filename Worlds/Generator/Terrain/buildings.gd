class_name Buildings
extends Node3D

const house_single = preload("res://Models/FantasyValley/house_single.tscn")
const house_double = preload("res://Models/FantasyValley/house_double.tscn")

static func make(kind: World.Building, rng: RandomNumberGenerator) -> Buildings:
	var result: Buildings
	match kind:
		World.Building.FANTASY_VALLEY_SINGLE: result = house_single.instantiate()
		World.Building.FANTASY_VALLEY_DOUBLE: result = house_double.instantiate()
		
	var r := rng.randf_range(0, 2 * PI)
	result.get_node("RootNode").rotate(Vector3.UP, r)
#	var s = rng.randf_range(2, 3)
#	result.get_node("RootNode").scale = Vector3(s, s, s)
	
	
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 9
	var box := CollisionShape3D.new()
	box.name = "shape"
	box.shape = BoxShape3D.new()
	match kind:
		World.Building.FANTASY_VALLEY_SINGLE: box.shape.size = Vector3(7, 6, 5)
		World.Building.FANTASY_VALLEY_DOUBLE: box.shape.size = Vector3(7, 10, 5)
	box.position.y = box.shape.size.y / 2.0
	box.rotate(Vector3.UP, r)
	body.add_child(box)
	result.add_child(body)
	
	
		
	return result
				
func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.BUILDING, position)
