class_name TargetShape
extends WorldItem

enum PuzzleKind { SINGLE_HIT, DAMAGE, ELEMENTAL_APPLICATION }

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_3d: Area3D = $Area3D
@onready var health_bar: Node3D = $HealthBar
@onready var health_bar_level: Label3D = $HealthBar/Level
@onready var health_bar_mesh: MeshInstance3D = $HealthBar/Bar

var puzzle_kind: PuzzleKind = PuzzleKind.DAMAGE

var is_down: bool = false
var time_when_down: float = 0.0
var respawn_time: float = INF

var health := Vitals.Stat.new(100, 0, 100)
var gauge  := Vitals.Stat.new(0.0, 0, 1.0)

var element: Spell.Element = Spell.Element.VOID

var spawner: ItemSpawner = null:
	set(value):
		if spawner != null:
			spawner.condition_met.disconnect(remove_when_done)
		spawner = value
		spawner.condition_met.connect(remove_when_done)

var path := PathStyle.still_path()
var start_position := Vector3.ZERO
var target_position := Vector3.ZERO
var bounds := Vector3(2, 2, 2)
var movement_tick: float = 0.0
var vital_tick: float = 1.0
var invunerable: int = 0

var focus_point := Vector3.ZERO

static func make() -> TargetShape:
	var result := (preload("res://Models/Misc/Target/Target.tscn") as PackedScene).instantiate() as TargetShape
	result.kind = World.Item.TARGET
	return result
	
func setup() -> void:
	update_mesh_color()
	
func _ready() -> void:
	setup()

func feet_position() -> float:
	return position.y - bounds.y / 2.0
	
func set_feet_position(y: float) -> void:
	position.y = y + bounds.y / 2.0
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	invunerable -= 1
	
	if is_down and Time.get_unix_time_from_system() - time_when_down > respawn_time:
		is_down = false
		time_when_down = 0.0
		health.value = health.max_value
		gauge.value = gauge.min_value
		if spawner != null:
			spawner.nodes_to_be_cleared[self] = true
		update_health_bar()
		animation_player.play("unset_down")
			
	movement_tick -= delta
	if movement_tick <= 0.0:
		var next := path.next_position_basic(0.5, self, focus_point)
		target_position = Vector3(next.x, next.y, next.z)
		movement_tick = 0.5
		var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
		if feet_position() <= g:
			if path.coord_y == PathStyle.CoordY.GROUND or path.coord_y == PathStyle.CoordY.GROUND_AND_AIR:
				set_feet_position(g)
				if target_position.y < position.y:
					target_position.y = position.y
		elif feet_position() >= g:
			if path.coord_y == PathStyle.CoordY.GROUND or path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT:
				set_feet_position(g)
				if target_position.y > position.y:
					target_position.y = position.y
		start_position = position
				
	position = lerp(start_position, target_position, (0.5 - movement_tick) / 0.5)
	var velocity := (target_position - start_position)
	if path.lookat == PathStyle.LookAt.PLAYER:
		var goal_position := position + velocity.normalized() * 10
		look_at(focus_point.lerp(goal_position, clampf(velocity.length() / 100.0, 0.0, 1.0)))
	elif path.lookat == PathStyle.LookAt.PLAYER_XZ:
		var goal_position := position + velocity * 10
		var player_position := focus_point
		player_position.y = position.y
		var target := player_position.lerp(goal_position, clampf(velocity.length() / 100.0, 0.0, 1.0)) 
		if target != position:
			look_at(target)
	elif path.lookat == PathStyle.LookAt.VELOCITY:
		velocity = velocity.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), 0.05)
			
			
	vital_tick -= delta
	if vital_tick <= 0.0:
		vital_tick = 1.0
		health.update_per_tick()
		gauge.update_per_tick()
		update_health_bar()

func _on_area_3d_area_entered(spell: Spell, caster_vitals: Vitals) -> void:
	if invunerable > 0:
		return
		
	var is_fire    : int = spell.element == Spell.Element.FIRE
	var is_rock    : int = spell.element == Spell.Element.ROCK
	var is_water   : int = spell.element == Spell.Element.WATER
	var is_air     : int = spell.element == Spell.Element.AIR
	var is_ice     : int = spell.element == Spell.Element.ICE
	var is_electric: int = spell.element == Spell.Element.ELECTRIC

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
		match puzzle_kind:
			PuzzleKind.SINGLE_HIT:
				is_down = true
				time_when_down = Time.get_unix_time_from_system()
				spawner.remove_node(self)
				animation_player.play("set_down")
			PuzzleKind.DAMAGE:
				var dmg := spell.damage(caster_vitals)
				health.apply(-dmg)
				invunerable = 20
				if health.value <= health.min_value:
					is_down = true
					time_when_down = Time.get_unix_time_from_system()
					spawner.remove_node(self)
					animation_player.play("set_down")
			PuzzleKind.ELEMENTAL_APPLICATION:
				var app := spell.elemental_application
				gauge.apply(app)
				invunerable = 20
				if gauge.value >= gauge.max_value:
					is_down = true
					time_when_down = Time.get_unix_time_from_system()
					spawner.remove_node(self)
					animation_player.play("set_down")
		update_health_bar()

func set_down() -> void:
	hide()
	
func unset_down() -> void:
	show()

func update_mesh_with_color(color: Color) -> void:
	var mat := ($coin as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = color
	update_health_bar()
	
func update_health_bar() -> void:
	if get_parent() == null:
		return
	health_bar_level.hide()
	match puzzle_kind:
		PuzzleKind.SINGLE_HIT:
			health_bar.hide()
		PuzzleKind.DAMAGE:
			health_bar.show()
			(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/health_gradient.tres"))
			(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("percentage", health.percentage())
		PuzzleKind.ELEMENTAL_APPLICATION:
			health_bar.show()
			match element:
				Spell.Element.FIRE:
					(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/fire_gradient.tres"))
				Spell.Element.ROCK:
					(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/rock_gradient.tres"))
				Spell.Element.WATER:
					(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/water_gradient.tres"))
				Spell.Element.ICE:
					(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/ice_gradient.tres"))
				Spell.Element.ELECTRIC:
					(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/electric_gradient.tres"))
				Spell.Element.AIR:
					(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/air_gradient.tres"))
				Spell.Element.VOID:
					(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/void_gradient.tres"))
			(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("percentage", gauge.percentage())
	
func update_mesh_color() -> void:
	update_mesh_with_color(Spell.color_from_element(element))
	update_health_bar()

func remove_when_done() -> void:
	var parent := get_parent()
	if parent:
		parent.remove_child(self)

static func config_for_single_hit(el: Spell.Element, spwnr: ItemSpawner, retime: float, pth: PathStyle) -> Dictionary:
	return {
		"puzzle": PuzzleKind.SINGLE_HIT,
		"element": el, "spawner": spwnr, "respawn_time": retime, "path": pth
	}
	
static func config_for_damage(el: Spell.Element, spwnr: ItemSpawner, retime: float, hlth: Vitals.Stat, pth: PathStyle) -> Dictionary:
	return {
		"puzzle": PuzzleKind.DAMAGE,
		"element": el, "spawner": spwnr, "respawn_time": retime, "path": pth, "health": hlth
	}
	
static func config_for_gauge(el: Spell.Element, spwnr: ItemSpawner, retime: float, gg: Vitals.Stat, pth: PathStyle) -> Dictionary:
	return {
		"puzzle": PuzzleKind.ELEMENTAL_APPLICATION,
		"element": el, "spawner": spwnr, "respawn_time": retime, "path": pth, "gauge": gg,
	}
	
func configure(config: Dictionary) -> void:
	element = config.get("element", Spell.Element.VOID)
	spawner = config.get("spawner", null)
	respawn_time = config.get("respawn_time", INF)
	path = config.get("path", PathStyle.still_path())
	health = config.get("health", Vitals.Stat.new(100, 0, 100))
	gauge = config.get("gauge", Vitals.Stat.new(0, 0, 1))
	puzzle_kind = config.get("puzzle", PuzzleKind.SINGLE_HIT)
