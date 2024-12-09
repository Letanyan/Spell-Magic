class_name TargetShape
extends WorldItem

enum PuzzleKind { SINGLE_HIT, DAMAGE, ELEMENTAL_APPLICATION, AVOID_DAMAGE, AVOID_EA, PLATFORM }

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_3d: Area3D = $area
@onready var health_bar: Node3D = $HealthBar
@onready var health_bar_level: Label3D = $HealthBar/Level
@onready var health_bar_mesh: MeshInstance3D = $HealthBar/Bar
@onready var static_body: StaticBody3D = $static
@onready var coin: MeshInstance3D = $coin
@onready var platform: MeshInstance3D = $platform

var puzzle_kind: PuzzleKind = PuzzleKind.DAMAGE

var is_down: bool = false
var respawn_ticks: float = 0.0
var respawn_time: float = INF

var health := Vitals.Stat.new(100, 0, 100)
var gauge  := Vitals.Stat.new(0.0, 0, 1.0)

var element: Spell.Element = Spell.Element.VOID

var spell_caster: SpellCaster = null
var caster_position := Vector3.ZERO
var caster_target_position := Vector3(NAN, NAN, NAN)
var caster_target_offset := Vector3.ZERO
var vitals: Vitals = null
var current_attack: AttackPatterns = null
var attack_sequence: AttackSequence = null
var player: Player = null

var spawner: ItemSpawner = null:
	set(value):
		if spawner != null:
			spawner.condition_met.disconnect(remove_when_done)
		spawner = value
		if spawner != null:
			spawner.condition_met.connect(remove_when_done)

var path := PathStyle.still_path_default
var start_position := Vector3(NAN, NAN, NAN)
var target_position := Vector3.ZERO
var bounds := Vector3(2, 2, 2)
var movement_tick: float = 0.0
var vital_tick: float = 1.0
var invunerable: int = 0

var focus_point := Vector3.ZERO

var should_be_removed := false

static func make() -> TargetShape:
	# FIXME: optimise this
	var result := (preload("res://Models/Misc/Target/Target.tscn") as PackedScene).instantiate() as TargetShape
	result.kind = World.Item.TARGET
	return result
	
func setup(rng: RandomNumberGenerator, biome: World.Biome) -> void:
	update_mesh_color()
	
func _ready() -> void:
	setup(null, World.Biome.WATER)

func feet_position() -> float:
	return position.y - bounds.y / 2.0
	
func set_feet_position(y: float) -> void:
	position.y = y + bounds.y / 2.0
	
func get_caster_target_position() -> Vector3:
	if is_nan(caster_target_position.x):
		return (global_position if player == null else player.global_position) + caster_target_offset
	else:
		return caster_target_position + caster_target_offset
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not is_active or GlobalData.magic_book.settings.is_paused:
		return
		
	if should_be_removed:
		if spell_caster.particles.is_empty():
			if spell_caster != null:
				spell_caster.free_particles()
			custom_free.call(self)
		return
	
	invunerable -= 1
	
	if is_down:
		respawn_ticks += delta
		if respawn_ticks >= respawn_time:
			is_down = false
			respawn_ticks = 0.0
			if is_blocking_puzzle():
				health.value = health.min_value
				gauge.value = gauge.max_value
			else:
				if not is_zero_approx(health.change_per_tick):
					health.value = health.max_value
				if not is_zero_approx(gauge.change_per_tick):
					gauge.value = gauge.min_value
			if spawner != null:
				spawner.add_condition(self)
			update_health_bar()
			animation_player.play("unset_down")
			
	movement_tick -= delta
	const MOVE_TICK_TIME = 0.5
	if not is_nan(start_position.x):
		position = start_position.lerp(target_position, (MOVE_TICK_TIME - movement_tick) / MOVE_TICK_TIME)
	if movement_tick <= 0.0:
		movement_tick = MOVE_TICK_TIME
		var me := Vec4.vec3(caster_position, bounds.y)
		var next := path.next_position(MOVE_TICK_TIME, me, focus_point, null, get_world_3d().direct_space_state)
		target_position = Vector3(next.x, next.y, next.z)
		var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
		if feet_position() < g:
			if path.coord_y == PathStyle.CoordY.GROUND or path.coord_y == PathStyle.CoordY.GROUND_AND_AIR:
				set_feet_position(g)
				if target_position.y < position.y:
					target_position.y = position.y
		elif feet_position() > g:
			if path.coord_y == PathStyle.CoordY.GROUND or path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT:
				set_feet_position(g)
				if target_position.y > position.y:
					target_position.y = position.y
		start_position = position
		static_body.constant_linear_velocity = (target_position - start_position) / movement_tick
		
				
	var velocity := (target_position - start_position)
	if path.lookat == PathStyle.LookAt.PLAYER:
		var actual_goal := focus_point
		if platform.visible:
			Globals.look_at_point(platform, actual_goal)
			Globals.look_at_point(static_body, actual_goal)
		elif coin.visible:
			Globals.look_at_point(coin, actual_goal)
			Globals.look_at_point(area_3d, actual_goal)
	elif path.lookat == PathStyle.LookAt.PLAYER_XZ:
		var player_position := focus_point
		player_position.y = position.y
		var target := player_position
		if platform.visible:
			Globals.look_at_point(platform, target)
			Globals.look_at_point(static_body, target)
		elif coin.visible:
			Globals.look_at_point(coin, target)
			Globals.look_at_point(area_3d, target)
	elif path.lookat == PathStyle.LookAt.VELOCITY:
		velocity = velocity.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), 0.05)
			
			
	if spell_caster != null:
		spell_caster.update(self, delta)
		var is_done := Globals.Ref.new(false)
		if attack_sequence != null:
			var player_body := (self as Node3D) if player == null else (player as Node3D)
			var me := Vec4.vec3(caster_position, 2.0)
			attack_sequence.update(0.5, me, player_body, is_done, get_world_3d().direct_space_state)
			caster_position = attack_sequence.next_position
			current_attack = attack_sequence.last_attack
		if current_attack != null:
			var spell := current_attack.choose_spell(vitals)
			if spell != null:
				cast_spell(insert_spell, spell)
			
	vital_tick -= delta
	if vital_tick <= 0.0:
		vital_tick = 1.0
		health.update_per_tick()
		gauge.update_per_tick()
		update_health_bar()
		if not is_down:
			if puzzle_kind == PuzzleKind.AVOID_DAMAGE and health.value >= health.max_value:
				set_is_down()
			elif puzzle_kind == PuzzleKind.AVOID_EA and gauge.value <= gauge.min_value:
				set_is_down()
			
			
func _on_area_3d_area_entered(projectile: SpellBody, caster_vitals: Vitals, area: Area3D, contact_points: Array[Vector3]) -> void:
	if invunerable > 0 or is_down:
		return
		
	var is_fire    : int = projectile.spell.element == Spell.Element.FIRE
	var is_rock    : int = projectile.spell.element == Spell.Element.ROCK
	var is_water   : int = projectile.spell.element == Spell.Element.WATER
	var is_air     : int = projectile.spell.element == Spell.Element.AIR
	var is_ice     : int = projectile.spell.element == Spell.Element.ICE
	var is_electric: int = projectile.spell.element == Spell.Element.ELECTRIC

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
				set_is_down()
			PuzzleKind.DAMAGE:
				var dmg := projectile.spell.damage(caster_vitals)
				health.apply(-dmg)
				invunerable = 20
				if health.value <= health.min_value:
					set_is_down()
			PuzzleKind.ELEMENTAL_APPLICATION:
				var app := projectile.spell.elemental_application
				gauge.apply(app)
				invunerable = 20
				if gauge.value >= gauge.max_value:
					set_is_down()
			PuzzleKind.AVOID_DAMAGE:
				var dmg := projectile.spell.damage(caster_vitals)
				health.apply(-dmg)
				invunerable = 20
			PuzzleKind.AVOID_EA:
				var app := projectile.spell.elemental_application
				gauge.apply(app)
				invunerable = 20
		update_health_bar()
		
	if projectile.spell.chain_cast_kind == Spell.ChainCastKind.HIT and projectile.spell.chain != null and not projectile.on_hit_casts.has(area):
		projectile.on_hit_casts[area] = true
		projectile.cast_spell(insert_spell, projectile.spell.chain)
	var dmg := projectile.spell.damage(caster_vitals)
	if is_rock:
		projectile.lose_control(projectile, area, {"dmg": dmg, "el": projectile.spell.element})
	else:
		projectile.expire_now(projectile, area, {"dmg": dmg, "el": projectile.spell.element})
	Vitals.apply_damage(projectile.get_parent() as Node3D, area, dmg, projectile.spell.element, false, true, contact_points, projectile.most_recent_radius.length(), projectile.velocity, vitals)
		

func set_is_down() -> void:
	is_down = true
	respawn_ticks = 0.0
	if spawner != null:
		spawner.remove_node(self)
	animation_player.play("set_down")
	($static/shape as CollisionShape3D).disabled = true
	($area/shape as CollisionShape3D).disabled = true

func set_down() -> void:
	hide()
	
func unset_down() -> void:
	health.value = health.max_value
	gauge.value = gauge.min_value
	update_health_bar()
	show()
	($static/shape as CollisionShape3D).disabled = puzzle_kind != PuzzleKind.PLATFORM
	($area/shape as CollisionShape3D).disabled = false

func update_mesh_with_color(color: Color) -> void:
	if puzzle_kind == PuzzleKind.PLATFORM:
		($platform as MeshInstance3D).show()
		($coin as MeshInstance3D).hide()		
		var mat := ($platform as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
		mat.set_shader_parameter("albedo", color.darkened(0.2))
	else:
		($platform as MeshInstance3D).hide()
		($coin as MeshInstance3D).show()
		var mat := ($coin as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
		mat.set_shader_parameter("albedo", color.darkened(0.2))
	update_health_bar()
	
func update_health_bar() -> void:
	if get_parent() == null:
		return
	health_bar_level.hide()
	match puzzle_kind:
		PuzzleKind.SINGLE_HIT, PuzzleKind.PLATFORM:
			health_bar.hide()
		PuzzleKind.DAMAGE, PuzzleKind.AVOID_DAMAGE:
			health_bar.show()
			(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("color_transitions", preload("res://Characters/Enemy/Health Bar/health_gradient.tres"))
			(health_bar_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("percentage", health.percentage())
		PuzzleKind.ELEMENTAL_APPLICATION, PuzzleKind.AVOID_EA:
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
	
func resize_target(size: float) -> void:
	var y_size := minf(size, 1.5)
	($coin as MeshInstance3D).scale = Vector3(5, 5, 5) * size
	($platform as MeshInstance3D).scale = Vector3(0.5 * size, 0.15 * y_size, 0.5 * size)
	(($static/shape as CollisionShape3D).shape as BoxShape3D).size = Vector3(size, 0.25 * y_size, size)
	(($area/shape as CollisionShape3D).shape as SphereShape3D).radius = size / 2.0
	#(($HealthBar/Bar as MeshInstance3D).mesh as PlaneMesh).size.x = size * 1.5
	bounds = Vector3(size, 0.25 * y_size, size)
	
func rescale_target(size: Vector3) -> void:
	($coin as MeshInstance3D).scale = size * 5
	($platform as MeshInstance3D).scale = Vector3(size.x * 0.5, size.y * 0.15, size.z * 0.5)
	(($static/shape as CollisionShape3D).shape as BoxShape3D).size = size
	(($area/shape as CollisionShape3D).shape as SphereShape3D).radius = size.y / 2.0
	#(($HealthBar/Bar as MeshInstance3D).mesh as PlaneMesh).size.x = size * 1.5
	bounds = size
	
func is_blocking_puzzle() -> bool:
	return puzzle_kind == PuzzleKind.AVOID_DAMAGE or puzzle_kind == PuzzleKind.AVOID_EA

func remove_when_done() -> void:
	should_be_removed = true

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
	
static func config_for_avoid_damage(el: Spell.Element, spwnr: ItemSpawner, retime: float, hlth: Vitals.Stat, pth: PathStyle, spll: AttackPatterns, caster_pos: Vector3) -> Dictionary:
	return {
		"puzzle": PuzzleKind.AVOID_DAMAGE, "spell": spll, "caster_position": caster_pos,
		"element": el, "spawner": spwnr, "respawn_time": retime, "path": pth, "health": hlth
	}
	
static func config_for_avoid_gauge(el: Spell.Element, spwnr: ItemSpawner, retime: float, gg: Vitals.Stat, pth: PathStyle, spll: AttackPatterns, caster_pos: Vector3) -> Dictionary:
	return {
		"puzzle": PuzzleKind.AVOID_EA, "spell": spll, "caster_position": caster_pos,
		"element": el, "spawner": spwnr, "respawn_time": retime, "path": pth, "gauge": gg,
	}
	
static func config_for_platform(el: Spell.Element, size: float, pth: PathStyle, has_spell: bool = false) -> Dictionary:
	return {
		"puzzle": PuzzleKind.PLATFORM, "has_spell": has_spell,
		"element": el, "path": pth, "size": size
	}
	
func configure(config: Dictionary) -> void:
	element = config.get("element", Spell.Element.VOID)
	spawner = config.get("spawner", null)
	respawn_time = config.get("respawn_time", INF)
	path = config.get("path", PathStyle.still_path())
	health = config.get("health", Vitals.Stat.new(100, 0, 100))
	gauge = config.get("gauge", Vitals.Stat.new(0, 0, 1))
	puzzle_kind = config.get("puzzle", PuzzleKind.SINGLE_HIT)
	current_attack = config.get("spell", null)
	caster_position = config.get("caster_position", Vector3.ZERO)
	($static/shape as CollisionShape3D).disabled = puzzle_kind != PuzzleKind.PLATFORM
	($area/shape as CollisionShape3D).disabled = puzzle_kind == PuzzleKind.PLATFORM
	if config.has("size"):
		resize_target(config["size"] as float)
	else:
		resize_target(1.0)
	if config.has("has_spell") or is_blocking_puzzle():
		spell_caster = SpellCaster.new(self, SpellCaster.Entity.TARGET)
		vitals = Vitals.new(Vitals.Stat.new(1000), Vitals.Stat.new(1000))
		vitals.attack.value = 100
		vitals.defence.value = 100

func cast_spell(insert: Callable, next_spell: Spell) -> void:
	if spell_caster == null:
		return
	spell_caster.cast_spell(self, vitals, insert, next_spell)

func insert_spell(p: Node3D) -> void:
	if p == null:
		return
	if p.get_parent() == null:
		add_sibling(p)
	if p is SpellBody:
		(p as SpellBody).setup()
