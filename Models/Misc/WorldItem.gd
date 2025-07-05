class_name WorldItem
extends Node3D

var is_active: bool = true
var kind: World.Item = World.Item.NONE
var custom_free: Callable = func(this: WorldItem) -> void:
	this.queue_free()
var height: float = 0.5
var original_scale := Vector3(1, 1, 1)
var original_position := Vector3.ZERO

func setup(seedling: int, biome: World.Biome) -> void:
	pass

func create_tween_for_world_item_pick_up(body: Node3D, duration: float) -> Tween:
	original_scale = scale
	original_position = position
	var tween := create_tween().set_parallel()
	var mid := Globals.midpoint_tangent1(position, body.position) if randf() < 0.5 else Globals.midpoint_tangent2(position, body.position)
	var path := Segment.quad(position, body.position, mid + Vector3(0, randf_range(-1, 5), 0))
	tween.tween_method(func(t: float) -> void: position = path.position_at_time(t), 0.0, 1.0, duration)
	tween.tween_property(self, "scale", Vector3(0.0001, 0.0001, 0.0001), duration)
	tween.stop()
	return tween

func create_tween_for_key_pick_up(body: Player, duration: float) -> Tween:
	var tween := create_tween().set_parallel(false)
	
	var reparent_to_camera := func(t: float) -> void:
		var camera := body.get_node("CamPivot/Arm/Lens") as Camera3D
		reparent(camera)
	
	original_scale = scale
	original_position = position
	tween.tween_method(reparent_to_camera, 0.0, 1.0, 0.02)
	tween.tween_property(self, "position", Vector3(0, 0, -1.5), duration * 0.3)
	tween.tween_property(self, "scale", Vector3(0.0001, 0.0001, 0.0001), duration * 0.2).set_delay(duration * 0.5)
	tween.stop()
	return tween
	
func create_tween_for_drop(start: Vector3, end: Vector3, duration: float) -> Tween:
	var tween := create_tween().set_parallel()
	var mid := Globals.midpoint_tangent1(start, end) if randf() < 0.5 else Globals.midpoint_tangent2(start, end)
	var path := Segment.quad(start, end, mid + Vector3(0, randf_range(-1, 5), 0))
	tween.tween_method(func(t: float) -> void: set_base_position(path.position_at_time(t)), 0.0, 1.0, duration)
	tween.stop()
	return tween
	
func reset_to_original() -> void:
	position = original_position
	scale = original_scale

func set_base_position(pos: Vector3) -> void:
	position = pos + Vec3.y(height)

func save_to_dict(dict: Dictionary) -> void:
	dict["kind"] = kind
	dict["height"] = height
	dict["is_active"] = is_active
	dict["position"] = position
	dict["name"] = name
	
func load_from_dict(dict: Dictionary) -> void:
	kind = dict.get("kind", 0)
	height = dict.get("height", 0.5)
	is_active = dict.get("is_active", true)
	position = dict.get("position", Vector3.ZERO)
	name = dict.get("name", "Item" + Rand.id(5, Time.get_ticks_usec()))
