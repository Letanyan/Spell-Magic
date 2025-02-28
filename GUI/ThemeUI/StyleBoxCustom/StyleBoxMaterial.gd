@tool
class_name StyleBoxMaterial
extends StyleBox

@export var material: Material
@export var texture: Texture2D
@export var shape_kind: int = 0

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	RenderingServer.canvas_item_set_material(to_canvas_item, material.get_rid())
	if is_instance_valid(texture):
		RenderingServer.canvas_item_add_texture_rect(to_canvas_item, rect, texture.get_rid())
	else:
		RenderingServer.canvas_item_add_rect(to_canvas_item, rect, Color.RED)


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO
