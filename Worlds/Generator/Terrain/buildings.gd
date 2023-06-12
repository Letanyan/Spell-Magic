class_name Buildings
extends Node3D

const house_single = preload("res://Models/FantasyValley/house_single.tscn")
const house_double = preload("res://Models/FantasyValley/house_double.tscn")
const fantasy_well = preload("res://Models/FantasyValley/fantasy_well.tscn")

var entity_kind: World.Building
var _entity_info: EntityInfo

static func make(kind: World.Building, rng: RandomNumberGenerator) -> Buildings:
	var result: Buildings
	match kind:
		World.Building.FANTASY_VALLEY_SINGLE: result = house_single.instantiate()
		World.Building.FANTASY_VALLEY_DOUBLE: result = house_double.instantiate()
		World.Building.FANTASY_WELL: result = fantasy_well.instantiate()
		
	var r := rng.randf_range(0, 2 * PI)
	result.get_node("RootNode").rotate(Vector3.UP, r)
	
	result.entity_kind = kind
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 9
	var box := CollisionShape3D.new()
	box.name = "shape"
	match kind:
		World.Building.FANTASY_VALLEY_SINGLE:
			box.shape = BoxShape3D.new()
			box.shape.size = Vector3(7, 6, 5)
			box.position.y = box.shape.size.y / 2.0
			box.rotate(Vector3.UP, r)
		World.Building.FANTASY_VALLEY_DOUBLE:
			box.shape = BoxShape3D.new()
			box.shape.size = Vector3(7, 10, 5)
			box.position.y = box.shape.size.y / 2.0
			box.rotate(Vector3.UP, r)
		World.Building.FANTASY_WELL:
			box.shape = CylinderShape3D.new()
			box.shape.height = 4
			box.shape.radius = 1.25
			box.position.y = box.shape.height / 2.0
	
	body.add_child(box)
	result.add_child(body)
	
	match result.entity_kind:
		World.Building.FANTASY_WELL:
			result._entity_info = EntityInfo.new(EntityInfo.Kind.BUILDING, result.position, EntityInfo.Liquid.WATER, 0.5)
			result._entity_info.bounds = box
		World.Building.FANTASY_VALLEY_SINGLE, World.Building.FANTASY_VALLEY_DOUBLE:
			result._entity_info = EntityInfo.new(EntityInfo.Kind.BUILDING, result.position)
			result._entity_info.bounds = box
		
	return result
	
func _ready() -> void:
	_entity_info.position = position
	
				
func entity_info():
	return _entity_info
	
func update_entity_info(info: EntityInfo):
	pass
