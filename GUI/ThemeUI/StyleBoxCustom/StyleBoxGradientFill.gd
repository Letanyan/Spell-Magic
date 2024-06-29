@tool
class_name StyleBoxGradientFill
extends StyleBox

@export var top_right_corner_radius: float = 0.0
@export var top_left_corner_radius: float = 0.0
@export var bottom_left_corner_radius: float = 0.0
@export var bottom_right_corner_radius: float = 0.0
@export var fill_texture: Texture2D
@export var border_texture: Texture2D
@export var border_width: float = 0.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if border_width > 0.0:
		render_rect(to_canvas_item, rect, border_texture)
	rect.position += Vector2(border_width, border_width)
	rect.size -= Vector2(border_width * 2, border_width * 2)
	render_rect(to_canvas_item, rect, fill_texture)

func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect
	
func _get_minimum_size() -> Vector2:
	return Vector2.ZERO
	
func _test_mask(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)

func render_rect(canvas_id: RID, rect: Rect2, texture: Texture2D) -> void:
	var vertices := PackedVector2Array([])
	var uvs := PackedVector2Array([])
	var colors := PackedColorArray([])
	
	if top_right_corner_radius != 0:
		var center := rect.position + Vector2(rect.size.x - top_right_corner_radius, 0 + top_right_corner_radius)
		var angle := 0.0
		for i in top_right_corner_radius + 1:
			var point := center + Vector2(cos(angle) * top_right_corner_radius, -sin(angle) * top_right_corner_radius)
			vertices.append(point)
			var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
			uvs.append(u)
			colors.append(get_color(texture, u))
			angle += (PI / 2.0) / top_right_corner_radius
	else:
		vertices.append(rect.position + Vector2(rect.size.x, 0))
		uvs.append(Vector2(1, 0))
		colors.append(get_color(texture, Vector2(1, 0)))
		
	if top_left_corner_radius != 0:
		var center := rect.position + Vector2(0 + top_left_corner_radius, 0 + top_left_corner_radius)
		var angle := PI / 2.0
		for i in top_left_corner_radius + 1:
			var point := center + Vector2(cos(angle) * top_left_corner_radius, -sin(angle) * top_left_corner_radius)
			vertices.append(point)
			var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
			uvs.append(u)
			colors.append(get_color(texture, u))
			angle += (PI / 2.0) / top_left_corner_radius
	else:
		vertices.append(rect.position + Vector2(0, 0))
		uvs.append(Vector2(0, 0))
		colors.append(get_color(texture, Vector2(0, 0)))
		
	if bottom_left_corner_radius != 0:
		var center := rect.position + Vector2(0 + bottom_left_corner_radius, rect.size.y - bottom_left_corner_radius)
		var angle := PI
		for i in bottom_left_corner_radius + 1:
			var point := center + Vector2(cos(angle) * bottom_left_corner_radius, -sin(angle) * bottom_left_corner_radius)
			vertices.append(point)
			var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
			uvs.append(u)
			colors.append(get_color(texture, u))
			angle += (PI / 2.0) / bottom_left_corner_radius
	else:
		vertices.append(rect.position + Vector2(0, rect.size.y))
		uvs.append(Vector2(0, 1))
		colors.append(get_color(texture, Vector2(0, 1)))
		
	if bottom_right_corner_radius != 0:
		var center := rect.position + Vector2(rect.size.x - bottom_right_corner_radius, rect.size.y - bottom_right_corner_radius)
		var angle := PI / 2.0 * 3.0
		for i in bottom_right_corner_radius + 1:
			var point := center + Vector2(cos(angle) * bottom_right_corner_radius, -sin(angle) * bottom_right_corner_radius)
			vertices.append(point)
			var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
			uvs.append(u)
			colors.append(get_color(texture, u))
			angle += (PI / 2.0) / bottom_right_corner_radius
	else:
		vertices.append(rect.position + Vector2(rect.size.x, rect.size.y))
		uvs.append(Vector2(1, 1))
		colors.append(get_color(texture, Vector2(1, 1)))
		
	RenderingServer.canvas_item_add_polygon(canvas_id, vertices, colors, uvs)
	
func get_color(tex: Texture2D, coord: Vector2) -> Color:
	if tex != null:
		var img := tex.get_image()
		return img.get_pixel(roundi(coord.x * (img.get_width() - 1)), roundi(coord.y * (img.get_height() - 1)))
		
	return Color(1, 0, 0, 1)
