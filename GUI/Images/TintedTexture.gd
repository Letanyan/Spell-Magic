@tool
class_name TintedTexture
extends Texture2D

@export var texture: CompressedTexture2D
@export var tint: Color = Color.WHITE
@export var flip_vertical: bool = false
@export var flip_horizontal: bool = false
@export_range(0, TAU, PI / 4) var rotation: float = 0.0
@export var stretch_mode: TextureRect.StretchMode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
@export var scale: Vector2 = Vector2(1, 1)
@export var offset: Vector2 = Vector2(0, 0)

func mix_tint(modulate: Color) -> Color:
	return Color(tint, modulate.a)
	
func draw_with_parameters(rid: RID, rect: Rect2, src_rect: Rect2, modulate: Color) -> void:
	var vertices := PackedVector2Array([])
	var uvs := PackedVector2Array([])
	var color := mix_tint(modulate)
	var colors := PackedColorArray([color, color, color, color])
	
	var uv_size := src_rect.size / rect.size
	var uv_offset := src_rect.position / src_rect.size
	
	var ui_normaliser := Vector2(0.5, 0.5)
	var coord := Vector2.ZERO
	
	# top left
	coord = (Vector2(0, 0) - ui_normaliser).rotated(rotation) + ui_normaliser
	uvs.append(Vector2(uv_offset.x, uv_offset.y))
	vertices.append(coord)
	
	# top right
	coord = (Vector2(1, 0) - ui_normaliser).rotated(rotation) + ui_normaliser
	uvs.append(Vector2(uv_offset.x + uv_size.x, uv_offset.y))
	vertices.append(coord)
	
	# bottom right
	coord = (Vector2(1, 1) - ui_normaliser).rotated(rotation) + ui_normaliser
	uvs.append(Vector2(uv_offset.x + uv_size.x, uv_offset.y + uv_size.y))
	vertices.append(coord)
	
	# bottom left
	coord = (Vector2(0, 1) - ui_normaliser).rotated(rotation) + ui_normaliser
	uvs.append(Vector2(uv_offset.x, uv_offset.y + uv_size.y))
	vertices.append(coord)
	
	if flip_horizontal:
		var t := uvs[0]
		uvs[0] = uvs[1]
		uvs[1] = t
		t = uvs[2]
		uvs[2] = uvs[3]
		uvs[3] = t
	if flip_vertical:
		var t := uvs[0]
		uvs[0] = uvs[3]
		uvs[3] = t
		t = uvs[1]
		uvs[1] = uvs[2]
		uvs[2] = t
	
	var minv := Vector2(0, 0)
	var maxv := Vector2(0, 0)
	for v in vertices:
		if v.x < minv.x: minv.x = v.x
		if v.y < minv.y: minv.y = v.y
		if v.x > maxv.x: maxv.x = v.x
		if v.y > maxv.y: maxv.y = v.y
		
	var rangev := maxv - minv
	for i in vertices.size():
		var v := vertices[i]
		match stretch_mode:
			TextureRect.StretchMode.STRETCH_SCALE:
				var s := rect.size * scale
				var o := rect.size * offset
				vertices[i] = (v - minv) / rangev * s + rect.position + o
			TextureRect.StretchMode.STRETCH_KEEP:
				var s := texture.get_size() * scale
				var o := rect.size * offset
				vertices[i] = (v - minv) / rangev * s + rect.position + o
			TextureRect.StretchMode.STRETCH_KEEP_ASPECT:
				var r := rect.size / texture.get_size()
				var s := texture.get_size() * minf(r.x, r.y) * scale
				var o := rect.size * offset
				vertices[i] = (v - minv) / rangev * s + rect.position + o
			TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED:
				var r := rect.size / texture.get_size()
				var s := texture.get_size() * minf(r.x, r.y) * scale
				var o := rect.size * offset
				vertices[i] = (v - minv) / rangev * s + rect.size * 0.5 - s * 0.5 + rect.position + o
			TextureRect.StretchMode.STRETCH_KEEP_ASPECT_COVERED:
				var r := rect.size / texture.get_size()
				var s := texture.get_size() * maxf(r.x, r.y) * scale
				var o := rect.size * offset
				vertices[i] = (v - minv) / rangev * s + rect.size * 0.5 - s * 0.5 + rect.position + o
			TextureRect.StretchMode.STRETCH_KEEP_CENTERED:
				var s := texture.get_size() * scale
				var o := rect.size * offset
				vertices[i] = (v - minv) / rangev * s + rect.size * 0.5 - s * 0.5 + rect.position + o
			TextureRect.StretchMode.STRETCH_TILE:
				var r := rect.size / texture.get_size()
				var s := texture.get_size() * minf(r.x, r.y) * scale
				var o := rect.size * offset
				vertices[i] = (v - minv) / rangev * s - s * 0.5 + rect.position + o
	
	#RenderingServer.canvas_item_add_polygon(rid, vertices, PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]), uvs)
	RenderingServer.canvas_item_add_polygon(rid, vertices, colors, uvs, texture.get_rid())
	

func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	draw_with_parameters(to_canvas_item, Rect2(pos, texture.get_size()), Rect2(Vector2.ZERO, texture.get_size()), modulate)
	#RenderingServer.canvas_item_add_texture_rect(to_canvas_item, Rect2(pos, texture.get_size()), texture.get_rid(), false, mix_tint(modulate), transpose)
	
func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	draw_with_parameters(to_canvas_item, rect, Rect2(Vector2.ZERO, rect.size), modulate)
	#RenderingServer.canvas_item_add_texture_rect(to_canvas_item, rect, texture.get_rid(), false, mix_tint(modulate), transpose)
	
func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	draw_with_parameters(to_canvas_item, rect, src_rect, modulate)
	#RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, rect, texture.get_rid(), src_rect, mix_tint(modulate), transpose, clip_uv)

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
