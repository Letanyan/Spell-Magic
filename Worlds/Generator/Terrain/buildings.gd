class_name Buildings
extends Node3D

const house_single = preload("res://Models/FantasyValley/house_single.tscn")
const house_double = preload("res://Models/FantasyValley/house_double.tscn")
const fantasy_well = preload("res://Models/FantasyValley/fantasy_well.tscn")

var entity_kind: World.Building
var _entity_info: EntityInfo

static func make(kind: World.Building) -> Buildings:
	var result: Buildings
	match kind:
		World.Building.FANTASY_VALLEY_SINGLE: result = house_single.instantiate()
		World.Building.FANTASY_VALLEY_DOUBLE: result = house_double.instantiate()
		World.Building.FANTASY_WELL: result = fantasy_well.instantiate()
	result.entity_kind = kind
	return result
	
func setup(rng: RandomNumberGenerator) -> void:
	var r := rng.randf_range(0, 2 * PI)
	(get_node("RootNode") as Node3D).rotate(Vector3.UP, r)
	
	var box := get_node("./static/shape") as CollisionShape3D
	match entity_kind:
		World.Building.FANTASY_VALLEY_SINGLE:
			box.rotate(Vector3.UP, r)
		World.Building.FANTASY_VALLEY_DOUBLE:
			box.rotate(Vector3.UP, r)
	
	match entity_kind:
		World.Building.FANTASY_WELL:
			_entity_info = EntityInfo.new(EntityInfo.Kind.BUILDING, position, EntityInfo.Liquid.WATER, 0.5)
			_entity_info.bounds = box
		World.Building.FANTASY_VALLEY_SINGLE, World.Building.FANTASY_VALLEY_DOUBLE:
			_entity_info = EntityInfo.new(EntityInfo.Kind.BUILDING, position)
			_entity_info.bounds = box
	
func _ready() -> void:
	_entity_info.position = position
	
				
func entity_info() -> EntityInfo:
	return _entity_info
	
func update_entity_info(info: EntityInfo) -> bool:
	return false
