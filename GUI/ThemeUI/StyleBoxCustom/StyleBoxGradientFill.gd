@tool
class_name StyleBoxGradientFill
extends StyleBox

@export var expanded: float = 0.0

@export_group("Corner Radius", "corner_radius")
@export var corner_radius_top_right: float = 0.0
@export var corner_radius_top_left: float = 0.0
@export var corner_radius_bottom_left: float = 0.0
@export var corner_radius_bottom_right: float = 0.0
@export var corner_radius_detail: float = 4.0

@export_group("Fill", "fill")
@export var fill_texture: Texture2D

@export_group("Border", "border")
@export var border_texture: Texture2D
@export var border_width: float = 0.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var ex_rect := rect
	ex_rect.position -= Vector2(expanded / 2, expanded / 2)
	ex_rect.size += Vector2(expanded, expanded)
	if border_width > 0.0:
		render_rect(to_canvas_item, ex_rect, border_texture)
	ex_rect.position += Vector2(border_width, border_width)
	ex_rect.size -= Vector2(border_width * 2, border_width * 2)
	render_rect(to_canvas_item, ex_rect, fill_texture)

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
	
	var top_right_corner_vertex := Vector2.ZERO
	var top_right_corner_uv := Vector2.ZERO
	
	if corner_radius_top_right != 0:
		var center := rect.position + Vector2(rect.size.x - corner_radius_top_right, 0 + corner_radius_top_right)
		var angle := 0.0
		top_right_corner_vertex = center + Vector2(cos(angle) * corner_radius_top_right, -sin(angle) * corner_radius_top_right)
		top_right_corner_uv = Vector2((top_right_corner_vertex.x - rect.position.x) / rect.size.x, (top_right_corner_vertex.y - rect.position.y) / rect.size.y)
		for i in corner_radius_top_right * corner_radius_detail + 1:
			var point := center + Vector2(cos(angle) * corner_radius_top_right, -sin(angle) * corner_radius_top_right)
			if vertices.is_empty() or vertices[vertices.size() - 1] != point:
				vertices.append(point)
				var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_top_right * corner_radius_detail)
	else:
		top_right_corner_vertex = rect.position + Vector2(rect.size.x, 0)
		top_right_corner_uv = Vector2(1, 0)
		vertices.append(top_right_corner_vertex)
		uvs.append(top_right_corner_uv)
		
	if corner_radius_top_left != 0:
		var center := rect.position + Vector2(0 + corner_radius_top_left, 0 + corner_radius_top_left)
		var angle := PI / 2.0
		for i in corner_radius_top_left * corner_radius_detail + 1:
			var point := center + Vector2(cos(angle) * corner_radius_top_left, -sin(angle) * corner_radius_top_left)
			if vertices[vertices.size() - 1] != point:
				vertices.append(point)
				var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_top_left * corner_radius_detail)
	else:
		vertices.append(rect.position + Vector2(0, 0))
		uvs.append(Vector2(0, 0))
		
	if corner_radius_bottom_left != 0:
		var center := rect.position + Vector2(0 + corner_radius_bottom_left, rect.size.y - corner_radius_bottom_left)
		var angle := PI
		for i in corner_radius_bottom_left * corner_radius_detail + 1:
			var point := center + Vector2(cos(angle) * corner_radius_bottom_left, -sin(angle) * corner_radius_bottom_left)
			if vertices[vertices.size() - 1] != point:
				vertices.append(point)
				var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_bottom_left * corner_radius_detail)
	else:
		vertices.append(rect.position + Vector2(0, rect.size.y))
		uvs.append(Vector2(0, 1))
		
	if corner_radius_bottom_right != 0:
		var center := rect.position + Vector2(rect.size.x - corner_radius_bottom_right, rect.size.y - corner_radius_bottom_right)
		var angle := PI / 2.0 * 3.0
		for i in corner_radius_bottom_right * corner_radius_detail + 1:
			var point := center + Vector2(cos(angle) * corner_radius_bottom_right, -sin(angle) * corner_radius_bottom_right)
			if vertices[vertices.size() - 1] != point:
				vertices.append(point)
				var u := Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / rect.size.y)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_bottom_right * corner_radius_detail)
	else:
		vertices.append(rect.position + Vector2(rect.size.x, rect.size.y))
		uvs.append(Vector2(1, 1))
		
	if vertices[vertices.size() - 1] != top_right_corner_vertex:
		vertices.append(top_right_corner_vertex)
		uvs.append(top_right_corner_uv)
		
	if not Geometry2D.triangulate_polygon(vertices).is_empty():
		RenderingServer.canvas_item_add_polygon(canvas_id, vertices, colors, uvs, texture.get_rid())
	else:
		RenderingServer.canvas_item_add_rect(canvas_id, rect, Color(1, 0, 0, 1))
	
func get_color(tex: Texture2D, coord: Vector2) -> Color:
	if tex != null:
		var img := tex.get_image()
		return img.get_pixel(roundi(coord.x * (img.get_width() - 1)), roundi(coord.y * (img.get_height() - 1)))
	return Color(1, 0, 0, 1)
	
func get_color_from_image(img: Image, coord: Vector2) -> Color:
	if img != null:
		return img.get_pixel(roundi(coord.x * (img.get_width() - 1)), roundi(coord.y * (img.get_height() - 1)))
	return Color(0, 0, 0, 0)

func set_border_gradient(start: Color, end: Color) -> void:
	if border_texture is GradientTexture1D:
		var tex := border_texture as GradientTexture1D
		var grad := tex.gradient
		grad.set_color(0, start)
		grad.set_color(1, end)
		tex.gradient = grad
		
func set_fill_gradient(start: Color, end: Color) -> void:
	if fill_texture is GradientTexture1D:
		var tex := fill_texture as GradientTexture1D
		var grad := tex.gradient
		grad.set_color(0, start)
		grad.set_color(1, end)
		tex.gradient = grad

var border_gradient_start_color: Color:
	set(value):
		if border_texture is GradientTexture1D:
			var tex := border_texture as GradientTexture1D
			tex.gradient.set_color(0, value)
	get:
		if border_texture is GradientTexture1D:
			var tex := border_texture as GradientTexture1D
			return tex.gradient.get_color(0)
		else:
			return Color(0, 0, 0, 0)
			
var border_gradient_end_color: Color:
	set(value):
		if border_texture is GradientTexture1D:
			var tex := border_texture as GradientTexture1D
			tex.gradient.set_color(1, value)
	get:
		if border_texture is GradientTexture1D:
			var tex := border_texture as GradientTexture1D
			return tex.gradient.get_color(1)
		else:
			return Color(0, 0, 0, 0)
			
var fill_gradient_start_color: Color:
	set(value):
		if fill_texture is GradientTexture1D:
			var tex := fill_texture as GradientTexture1D
			tex.gradient.set_color(0, value)
	get:
		if fill_texture is GradientTexture1D:
			var tex := fill_texture as GradientTexture1D
			return tex.gradient.get_color(0)
		else:
			return Color(0, 0, 0, 0)
			
var fill_gradient_end_color: Color:
	set(value):
		if fill_texture is GradientTexture1D:
			var tex := fill_texture as GradientTexture1D
			tex.gradient.set_color(1, value)
	get:
		if fill_texture is GradientTexture1D:
			var tex := fill_texture as GradientTexture1D
			return tex.gradient.get_color(1)
		else:
			return Color(0, 0, 0, 0)
