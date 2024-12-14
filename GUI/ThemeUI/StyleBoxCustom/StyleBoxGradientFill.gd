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
@export var fill_texture_flip_xy: bool = false
@export var fill_texture_flip_vertical: bool = false
@export var fill_texture_flip_horizonal: bool = false

@export_group("Border", "border")
@export var border_texture: Texture2D
@export var border_width: float = 0.0
@export var border_texture_flip_xy: bool = false
@export var border_texture_flip_vertical: bool = false
@export var border_texture_flip_horizonal: bool = false


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var ex_rect := rect
	ex_rect.position -= Vector2(expanded / 2, expanded / 2)
	ex_rect.size += Vector2(expanded, expanded)
	if border_width > 0.0:
		render_rect(to_canvas_item, ex_rect, border_texture, border_texture_flip_vertical, border_texture_flip_horizonal, border_texture_flip_xy)
	ex_rect.position += Vector2(border_width, border_width)
	ex_rect.size -= Vector2(border_width * 2, border_width * 2)
	render_rect(to_canvas_item, ex_rect, fill_texture, fill_texture_flip_vertical, fill_texture_flip_horizonal, fill_texture_flip_xy)
	

func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect
	
func _get_minimum_size() -> Vector2:
	return Vector2.ZERO
	
func _test_mask(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)

func render_rect(canvas_id: RID, rect: Rect2, texture: Texture2D, flip_vertical: bool, flip_horizontal: bool, flip_xy: bool) -> void:
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
				var ux := (point.x - rect.position.x) / rect.size.x
				var uy := (point.y - rect.position.y) / rect.size.y
				if flip_horizontal: ux = 1.0 - ux
				if flip_vertical: uy = 1.0 - uy
				if flip_xy: var temp := ux; ux = uy; uy = temp
				var u := Vector2(ux, uy)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_top_right * corner_radius_detail)
	else:
		top_right_corner_vertex = rect.position + Vector2(rect.size.x, 0)
		var ux := 1.0
		var uy := 0.0
		if flip_horizontal: ux = 1.0 - ux
		if flip_vertical: uy = 1.0 - uy
		if flip_xy: var temp := ux; ux = uy; uy = temp
		top_right_corner_uv = Vector2(ux, uy)
		vertices.append(top_right_corner_vertex)
		uvs.append(top_right_corner_uv)
		
	if corner_radius_top_left != 0:
		var center := rect.position + Vector2(0 + corner_radius_top_left, 0 + corner_radius_top_left)
		var angle := PI / 2.0
		for i in corner_radius_top_left * corner_radius_detail + 1:
			var point := center + Vector2(cos(angle) * corner_radius_top_left, -sin(angle) * corner_radius_top_left)
			if vertices[vertices.size() - 1] != point:
				vertices.append(point)
				var ux := (point.x - rect.position.x) / rect.size.x
				var uy := (point.y - rect.position.y) / rect.size.y
				if flip_horizontal: ux = 1.0 - ux
				if flip_vertical: uy = 1.0 - uy
				if flip_xy: var temp := ux; ux = uy; uy = temp
				var u := Vector2(ux, uy)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_top_left * corner_radius_detail)
	else:
		vertices.append(rect.position + Vector2(0, 0))
		var ux := 0.0
		var uy := 0.0
		if flip_horizontal: ux = 1.0 - ux
		if flip_vertical: uy = 1.0 - uy
		if flip_xy: var temp := ux; ux = uy; uy = temp
		uvs.append(Vector2(ux, uy))
		
	if corner_radius_bottom_left != 0:
		var center := rect.position + Vector2(0 + corner_radius_bottom_left, rect.size.y - corner_radius_bottom_left)
		var angle := PI
		for i in corner_radius_bottom_left * corner_radius_detail + 1:
			var point := center + Vector2(cos(angle) * corner_radius_bottom_left, -sin(angle) * corner_radius_bottom_left)
			if vertices[vertices.size() - 1] != point:
				vertices.append(point)
				var ux := (point.x - rect.position.x) / rect.size.x
				var uy := (point.y - rect.position.y) / rect.size.y
				if flip_horizontal: ux = 1.0 - ux
				if flip_vertical: uy = 1.0 - uy
				if flip_xy: var temp := ux; ux = uy; uy = temp
				var u := Vector2(ux, uy)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_bottom_left * corner_radius_detail)
	else:
		vertices.append(rect.position + Vector2(0, rect.size.y))
		var ux := 0.0
		var uy := 1.0
		if flip_horizontal: ux = 1.0 - ux
		if flip_vertical: uy = 1.0 - uy
		if flip_xy: var temp := ux; ux = uy; uy = temp
		uvs.append(Vector2(ux, uy))
		
	if corner_radius_bottom_right != 0:
		var center := rect.position + Vector2(rect.size.x - corner_radius_bottom_right, rect.size.y - corner_radius_bottom_right)
		var angle := PI / 2.0 * 3.0
		for i in corner_radius_bottom_right * corner_radius_detail + 1:
			var point := center + Vector2(cos(angle) * corner_radius_bottom_right, -sin(angle) * corner_radius_bottom_right)
			if vertices[vertices.size() - 1] != point:
				vertices.append(point)
				var ux := (point.x - rect.position.x) / rect.size.x
				var uy := (point.y - rect.position.y) / rect.size.y
				if flip_horizontal: ux = 1.0 - ux
				if flip_vertical: uy = 1.0 - uy
				if flip_xy: var temp := ux; ux = uy; uy = temp
				var u := Vector2(ux, uy)
				uvs.append(u)
			angle += (PI / 2.0) / (corner_radius_bottom_right * corner_radius_detail)
	else:
		vertices.append(rect.position + Vector2(rect.size.x, rect.size.y))
		var ux := 1.0
		var uy := 1.0
		if flip_horizontal: ux = 1.0 - ux
		if flip_vertical: uy = 1.0 - uy
		if flip_xy: var temp := ux; ux = uy; uy = temp
		uvs.append(Vector2(ux, uy))
		
	if vertices[vertices.size() - 1] != top_right_corner_vertex:
		vertices.append(top_right_corner_vertex)
		uvs.append(top_right_corner_uv)
		
	if not Geometry2D.triangulate_polygon(vertices).is_empty():
		RenderingServer.canvas_item_add_polygon(canvas_id, vertices, colors, uvs, texture.get_rid())
		#RenderingServer.canvas_item_add_circle(canvas_id, rect.position, randf_range(5, 10), Color(1, 0, 0))
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
	
func set_complete_border_gradient(colors: PackedColorArray, offsets: PackedFloat32Array) -> void:
	if border_texture is GradientTexture1D:
		var tex := border_texture as GradientTexture1D
		var grad := tex.gradient
		grad.colors = colors
		grad.offsets = offsets
		
func set_complete_fill_gradient(colors: PackedColorArray, offsets: PackedFloat32Array) -> void:
	if fill_texture is GradientTexture1D:
		var tex := fill_texture as GradientTexture1D
		var grad := tex.gradient
		grad.colors = colors
		grad.offsets = offsets
		
func set_border_gradient(start: Color, end: Color) -> void:
	set_complete_border_gradient(PackedColorArray([start, end]), PackedFloat32Array([0, 1]))
		
func set_fill_gradient(start: Color, end: Color) -> void:
	set_complete_fill_gradient(PackedColorArray([start, end]), PackedFloat32Array([0, 1]))

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
