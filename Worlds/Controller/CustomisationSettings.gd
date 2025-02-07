class_name CustomisationSettings

var skin: Color
var hair: Color
var eyes: Color
var body_armor_trim: Color
var body_armor_plate: Color
var overshirt: Color
var undershirt: Color
var shoes: Color
var legs_armor_trim: Color
var pants: Color
var legs_armor_plate: Color

func save_dict() -> Dictionary:
	return {
		"skin": skin, "hair": hair, "eyes": eyes,
		"body_armor_trim": body_armor_trim, "body_armor_plate": body_armor_plate, "overshirt": overshirt, "undershirt": undershirt,
		"shoes": shoes,
		"legs_armor_trim": legs_armor_trim, "legs_armor_plate": legs_armor_plate, "pants": pants,
	}
	
func load_dict(dict: Dictionary) -> void:
	skin = dict.get("skin", Color(0.808, 0.678, 0.525)) as Color
	hair = dict.get("hair", Color(0, 0, 0)) as Color
	eyes = dict.get("eyes", Color(0.193, 0.144, 0.108)) as Color
	body_armor_trim = dict.get("body_armor_trim", Color(0.388, 0.393, 0.389)) as Color
	body_armor_plate = dict.get("body_armor_plate", Color(0.31, 0.313, 0.31)) as Color
	overshirt = dict.get("overshirt", Color(0.35, 0.35, 0.35)) as Color
	undershirt = dict.get("undershirt", Color(0.5, 0.5, 0.5)) as Color
	shoes = dict.get("shoes", Color(0.35, 0.35, 0.35)) as Color
	legs_armor_trim = dict.get("legs_armor_trim", Color(0.388, 0.393, 0.389)) as Color
	pants = dict.get("pants", Color(0.5, 0.5, 0.5)) as Color
	legs_armor_plate = dict.get("legs_armor_plate", Color(0.31, 0.313, 0.31)) as Color
	
func update_all(node: Node3D) -> void:
	var head := (node.find_child("King_Head") as MeshInstance3D).mesh
	var body := (node.find_child("King_Body") as MeshInstance3D).mesh
	var feet := (node.find_child("King_Feet") as MeshInstance3D).mesh
	var legs := (node.find_child("King_Legs") as MeshInstance3D).mesh
	(head.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", skin)
	(head.surface_get_material(1) as ShaderMaterial).set_shader_parameter("albedo", hair)
	(head.surface_get_material(2) as ShaderMaterial).set_shader_parameter("albedo", eyes)
	(body.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", body_armor_trim)
	(body.surface_get_material(1) as ShaderMaterial).set_shader_parameter("albedo", body_armor_plate)
	(body.surface_get_material(2) as ShaderMaterial).set_shader_parameter("albedo", skin)
	(body.surface_get_material(3) as ShaderMaterial).set_shader_parameter("albedo", overshirt)
	(body.surface_get_material(4) as ShaderMaterial).set_shader_parameter("albedo", undershirt)
	(feet.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", shoes)
	(legs.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", legs_armor_trim)
	(legs.surface_get_material(1) as ShaderMaterial).set_shader_parameter("albedo", pants)
	(legs.surface_get_material(2) as ShaderMaterial).set_shader_parameter("albedo", legs_armor_plate)
	
func update_skin(node: Node3D, color: Color) -> void:
	skin = color
	var head := (node.find_child("King_Head") as MeshInstance3D).mesh
	var body := (node.find_child("King_Body") as MeshInstance3D).mesh
	(head.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", color)
	(body.surface_get_material(2) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_hair(node: Node3D, color: Color) -> void:
	hair = color
	var head := (node.find_child("King_Head") as MeshInstance3D).mesh
	(head.surface_get_material(1) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_eyes(node: Node3D, color: Color) -> void:
	eyes = color
	var head := (node.find_child("King_Head") as MeshInstance3D).mesh
	(head.surface_get_material(2) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_body_armor_trim(node: Node3D, color: Color) -> void:
	body_armor_trim = color
	var body := (node.find_child("King_Body") as MeshInstance3D).mesh
	(body.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_body_armor_plate(node: Node3D, color: Color) -> void:
	body_armor_plate = color
	var body := (node.find_child("King_Body") as MeshInstance3D).mesh
	(body.surface_get_material(1) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_overshirt(node: Node3D, color: Color) -> void:
	overshirt = color
	var body := (node.find_child("King_Body") as MeshInstance3D).mesh
	(body.surface_get_material(3) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_undershirt(node: Node3D, color: Color) -> void:
	undershirt = color
	var body := (node.find_child("King_Body") as MeshInstance3D).mesh
	(body.surface_get_material(4) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_shoes(node: Node3D, color: Color) -> void:
	shoes = color
	var feet := (node.find_child("King_Feet") as MeshInstance3D).mesh
	(feet.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_legs_armor_trim(node: Node3D, color: Color) -> void:
	legs_armor_trim = color
	var legs := (node.find_child("King_Legs") as MeshInstance3D).mesh
	(legs.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_pants(node: Node3D, color: Color) -> void:
	pants = color
	var legs := (node.find_child("King_Legs") as MeshInstance3D).mesh
	(legs.surface_get_material(1) as ShaderMaterial).set_shader_parameter("albedo", color)
	
func update_legs_armor_plate(node: Node3D, color: Color) -> void:
	legs_armor_plate = color
	var legs := (node.find_child("King_Legs") as MeshInstance3D).mesh
	(legs.surface_get_material(2) as ShaderMaterial).set_shader_parameter("albedo", color)
