class_name TargetShape
extends WorldItem

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_3d: Area3D = $Area3D

var is_down: bool = false
var time_when_down: float = 0.0 
var element: Spell.Element = Spell.Element.VOID
var respawn_time: float = INF
var spawner: ItemSpawner = null
var path := PathStyle.still_path()
var start_position := Vector3.ZERO
var target := Vector3.ZERO
var movement_tick: float = 0.0

static func make() -> TargetShape:
	var result := (preload("res://Models/Misc/Target/Target.tscn") as PackedScene).instantiate() as TargetShape
	result.kind = World.Item.TARGET
	return result
	
func setup() -> void:
	update_mesh_color()
	spawner.condition_met.connect(remove_when_done)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	if is_down and Time.get_unix_time_from_system() - time_when_down > respawn_time:
		is_down = false
		time_when_down = 0.0
		if spawner != null:
			spawner.nodes_to_be_cleared[self] = true
		animation_player.play("unset_down")
			
	movement_tick -= delta
	if movement_tick <= 0.0:
		var next := path.next_position_basic(0.5, self, Vector3.ZERO)
		target = Vector3(next.x, next.y, next.z)
		start_position = position
		movement_tick = 0.5
	position = lerp(start_position, target, (0.5 - movement_tick) / 0.5)

func _on_area_3d_area_entered(layer: int) -> void:
	var is_fire    : int = layer & 0b0_0000_1000 != 0
	var is_rock    : int = layer & 0b0_0001_0000 != 0
	var is_water   : int = layer & 0b0_0010_0000 != 0
	var is_air     : int = layer & 0b0_0100_0000 != 0
	var is_ice     : int = layer & 0b0_1000_0000 != 0
	var is_electric: int = layer & 0b1_0000_0000 != 0

	var is_hit := false
	match element:
		Spell.Element.VOID: is_hit = true
		Spell.Element.FIRE: is_hit = is_fire
		Spell.Element.ROCK: is_hit = is_rock
		Spell.Element.WATER: is_hit = is_water
		Spell.Element.AIR: is_hit = is_air
		Spell.Element.ICE: is_hit = is_ice
		Spell.Element.ELECTRIC: is_hit = is_electric
		
	if is_hit:
		is_down = true
		time_when_down = Time.get_unix_time_from_system()
		spawner.remove_node(self)
		animation_player.play("set_down")

func set_down() -> void:
	hide()
	
func unset_down() -> void:
	show()

func update_mesh_with_color(color: Color) -> void:
	var mat := ($coin as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = color
	
func update_mesh_color() -> void:
	update_mesh_with_color(Spell.color_from_element(element))

func remove_when_done() -> void:
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
