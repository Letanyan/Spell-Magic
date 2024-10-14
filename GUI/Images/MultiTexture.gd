@tool
class_name MultiTexture
extends Texture2D

@export var texture: Array[Texture2D]

func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	for tex in texture:
		tex.draw(to_canvas_item, pos, modulate, transpose)
	
func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	for tex in texture:
		tex.draw_rect(to_canvas_item, rect, tile, modulate, transpose)
	
func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	for tex in texture:
		tex.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)

func _get_height() -> int:
	var result := 0
	for tex in texture:
		result = maxi(tex.get_height(), result)
	return result
	
func _get_width() -> int:
	var result := 0
	for tex in texture:
		result = maxi(tex.get_width(), result)
	return result

func _get(property: StringName) -> Variant:
	return 0
	
func _get_property_list() -> Array[Dictionary]:
	return []
	
func _get_rid() -> RID:
	return RID()
	
func _has_alpha() -> bool:
	return true
	
func _init() -> void:
	pass
	
func _is_pixel_opaque(x: int, y: int) -> bool:
	return false
	
func _notification(what: int) -> void:
	pass
	
func _property_can_revert(property: StringName) -> bool:
	return false
	
func _property_get_revert(property: StringName) -> Variant:
	return 0
	
func _set(property: StringName, value: Variant) -> bool:
	return false
	
func _setup_local_to_scene() -> void:
	pass
	
func _to_string() -> String:
	return ""
