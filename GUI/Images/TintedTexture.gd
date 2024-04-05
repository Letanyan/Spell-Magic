@tool
class_name TintedTexture
extends Texture2D

@export var texture: CompressedTexture2D
@export var tint: Color = Color.WHITE

func mix_tint(modulate: Color) -> Color:
	return Color(tint, modulate.a)

func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(to_canvas_item, Rect2(pos, texture.get_size()), texture.get_rid(), false, mix_tint(modulate), transpose)
	
func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(to_canvas_item, rect, texture.get_rid(), false, mix_tint(modulate), transpose)
	
func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, rect, texture.get_rid(), src_rect, mix_tint(modulate), transpose, clip_uv)

func _get_height() -> int:
	if not texture:
		return 0
	return texture.get_height()
	
func _get_width() -> int:
	if not texture:
		return 0
	return texture.get_width()

func _get(property: StringName) -> Variant:
	if not texture:
		return 0
	return texture.get(property)
	
func _get_property_list() -> Array[Dictionary]:
	if not texture:
		return []
	return texture.get_property_list()
	
func _get_rid() -> RID:
	if not texture:
		return RID()
	return texture.get_rid()
	
func _has_alpha() -> bool:
	if not texture:
		return false
	return texture.has_alpha()
	
func _init() -> void:
	pass
	
func _is_pixel_opaque(x: int, y: int) -> bool:
	if not texture:
		return false
	return false
	
func _notification(what: int) -> void:
	if not texture:
		return
	texture.notification(what)
	
func _property_can_revert(property: StringName) -> bool:
	if not texture:
		return false
	return texture.property_can_revert(property)
	
func _property_get_revert(property: StringName) -> Variant:
	if not texture:
		return 0
	return texture.property_get_revert(property)
	
func _set(property: StringName, value: Variant) -> bool:
	if not texture:
		return false
	texture.set(property, value)
	return true
	
	
func _setup_local_to_scene() -> void:
	if not texture:
		return
	texture.setup_local_to_scene()
	
func _to_string() -> String:
	if not texture:
		return ""
	return texture.to_string()
