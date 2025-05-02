class_name Building
extends Node3D

var is_active: bool = true
var kind: World.Building
var custom_free: Callable = func(this: WorldItem) -> void:
	this.queue_free()

static func make(_kind: World.Building) -> Building:
	var result: Building
	match _kind:
		World.Building.HOUSE_RUINED_01: result = (preload("res://Models/Structures/House/House_Ruined_01.tscn") as PackedScene).instantiate() as Building
		World.Building.HOUSE_RUINED_02: result = (preload("res://Models/Structures/House/House_Ruined_02.tscn") as PackedScene).instantiate() as Building
		World.Building.HOUSE_RUINED_03: result = (preload("res://Models/Structures/House/House_Ruined_03.tscn") as PackedScene).instantiate() as Building
		World.Building.TOWER_BASE: result = (preload("res://Models/Structures/Tower/Tower_Base.tscn") as PackedScene).instantiate() as Building
	result.kind = _kind
	return result
