class_name Player
extends CharacterBody

@onready var cam_pivot: Marker3D = $CamPivot
@onready var cam_arm: SpringArm3D = $CamPivot/Arm
@onready var cam: Camera3D = $CamPivot/Arm/Lens

@onready var body_pivot: Node3D = $Pivot
var projectile_indicator_scale: float = 1.0

@onready var animator: AnimationPlayer = $Pivot/King/AnimationPlayer 
@onready var cam_animator: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $Pivot/King/AnimationTree

@onready var bg_audio: AudioStreamPlayer3D = $BGAudio
@onready var walking_audio: AudioStreamPlayer3D = $MovementAudio

@onready var interface: MeshInstance3D = $CamPivot/Interface

@onready var leaves: GPUParticles3D = $leaves

var platform: PhysicsBody3D = null

var spell_caster: SpellCaster
var magic_book: MagicBook
var artifacts: Artifacts
var world_settings: WorldSettings:
	set(value):
		world_settings = value
		keys = world_settings.player_keys
var name_generator: NameGenerator
var keys: int

var enemies_in_range: Dictionary = {} ## [Enemy]Time.get_unix_time_from_system
var targets_in_range: Dictionary = {} ## [TargetShape]Time.get_unix_time_from_system
var projectile_indicators: Dictionary = {} ## [Node3D]ProjectileIndicator
var projectile_indicator_store: Array[ProjectileIndicator] = []
var max_watched_enemies_distance := 0.0
var indicator_update_tick := 0.0
const projectile_indicator = preload("res://Characters/Player/ProjectileIndicator.tscn")

var camera_target_velocity: float = 0
var shake_intensity: float = 0.0
const camera_shake_noise = preload("res://Characters/Player/camera_shake_noise.tres")
var camera_bounce_direction := 0

signal player_moved(delta: float, state: PhysicsDirectSpaceState3D)
signal vital_update(vitals: Vitals)
signal spell_was_cast(spell: Spell)
signal spell_was_disallowed(spell: Spell, reason: MagicBook.DisallowSpellReason)
signal spell_was_limited(spell: Spell, reason: MagicBook.DisallowSpellReason)
signal spell_velocity_was_buffed(amount: float)
signal spell_radius_was_buffed(amount: float)
signal attack_was_buffed(amount: float)
signal defence_was_buffed(amount: float)
signal speed_was_buffed(amount: float)

var active_effects: Dictionary = {} ## [Vector2i][int]bool
var spell_modifier: Dictionary = {} ## [Artifact.Element]Vector2(flat: int, percentage: float)
var damage_resistance: Dictionary = {} ## [Artifact.Element]Vector2(flat: int, percentage: float)
var buff_crit_rate := Vector2.ZERO
var buff_crit_dmg := Vector2.ZERO

var menu_callbacks_are_set: bool = false
var on_menu_open: Callable = func() -> void: pass
var on_menu_close: Callable = func() -> void: pass

func _ready() -> void:
	velocity_movement = VelocityMovement.new()
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 50, 0.5))
	spell_caster = SpellCaster.new(get_node(".") as Node3D, SpellCaster.Entity.PLAYER)
	emit_vitals_update()
	velocity = Vector3.ZERO
	SignalBus.projectile_hit.connect(give_back_mana_after_hit)
	SignalBus.pick_up_world_item_artifact.connect(on_pick_up_artifact)
	SignalBus.pick_up_world_item_spell.connect(on_pick_up_spell)
	SignalBus.pick_up_world_item_key.connect(on_pick_up_key)
	SignalBus.pick_up_world_item_coin.connect(on_pick_up_coin)
	SignalBus.pick_up_world_item_red_cross.connect(on_pick_up_red_cross)
	SignalBus.pick_up_world_item_scroll_note.connect(on_pick_up_scroll_note)
	animation_tree.active = true
	if not bounds:
		bounds = Navigator.shape_bounds((get_node("Collision") as CollisionShape3D).shape)
	
func emit_vitals_update() -> void:
	vital_update.emit(vitals)
	
func emit_spell_was_cast(s: Spell) -> void:
	spell_was_cast.emit(s)
	
func pan_camera(movement: Vector2) -> void:
	var damping := 0.75
	const rate := 5.0
	const S := 1.5
	var exp_movement := Vector2(absf(movement.x / rate) ** S * signf(movement.x), absf(movement.y / rate) ** S * signf(movement.y))
	cam_pivot.rotate_y(-exp_movement.x * damping / 180 * PI)
	cam_arm.rotate_x(-exp_movement.y * damping / 180 * PI / 3)
	cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)
	
	var size := -movement.length()
	if vitals.wetness.value > vitals.wetness.min_value and position.y > world_settings.sea_level:
		vitals.wetness.apply(size / 50_000.0)
	if vitals.freeze.value > vitals.freeze.min_value:
		vitals.wetness.apply(size / 75_000.0)

func current_animation_is(animation: String) -> bool:
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	var current := playback.get_current_node()
	return current == animation

func play_animation(animation: String, parameters: Dictionary = {}) -> void:
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	for path: StringName in parameters:
		animation_tree.set(path, parameters[path])
	var current := playback.get_current_node()
	if current != "death" and current != animation:
		playback.travel(animation)

func can_move() -> bool:
#	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
#	var current := playback.get_current_node()
#	print(current)
	return is_zero_approx(invunerable)
	
func add_shake(amount: float) -> void:
	shake_intensity += amount

func _physics_process(delta: float) -> void:
	if magic_book.settings.is_paused:
		return
	
	invunerable = max(0.0, invunerable - delta)
		
	update_watched_enemies_positions(delta)
	velocity_movement.update_movement_speed(magic_book.settings.upgrade_settings.max_running_speed() + magic_book.settings.upgrade_settings.buff_running_speed, bounds.y, 21.0)
	var movement := velocity_movement.update(delta, vitals, velocity_movement.speed, self, false, world_settings.sea_level)
	emit_vitals_update()
	
	velocity = movement["velocity"]
	var direction := movement["direction"] as Vector3
	var is_underwater := not is_on_floor and position.y <= world_settings.sea_level and direction != Vector3.ZERO and velocity != Vector3.ZERO
	velocity_movement.rotate_character(get_node(".") as Player, direction, is_underwater)
	move_and_slide()
	if direction != Vector3.ZERO and velocity != Vector3.ZERO:
		if is_on_floor:
			if velocity.length() < 0.166667:
				play_walking_audio(NoiseBlender.walking_audio_for_biome(velocity_movement.current_biome))
				play_animation("walk")
			else:
				play_walking_audio(NoiseBlender.walking_audio_for_biome(velocity_movement.current_biome))
				var pivot_vector := Vector3.FORWARD.rotated(Vector3.UP, cam_pivot.rotation.y)
				var direction_angle := Vector3(direction.x, 0, direction.z).signed_angle_to(pivot_vector, Vector3.UP)
				var is_forward := absf(direction_angle) < PI / 2
				var left_right := 0.0
				if direction_angle < 0.0:
					left_right = -(1.0 - absf((direction_angle + PI / 2) / (PI / 2)))
				if direction_angle > 0.0:
					left_right = 1.0 - absf((direction_angle - PI / 2) / (PI / 2))
					
				if enemies_in_range.is_empty():
					play_animation("run", {
						"parameters/run/Backward/blend_amount": 0, 
						"parameters/run/Forward/blend_amount": 0, 
						"parameters/run/Movement/blend_amount": 1,
						"parameters/run/Speed/scale": velocity_movement.movement_speed_animation_scale()
					})
				else:
					play_animation("run", {
						"parameters/run/Backward/blend_amount": left_right, 
						"parameters/run/Forward/blend_amount": left_right, 
						"parameters/run/Movement/blend_amount": 1.0 if is_forward else 0.0,
						"parameters/run/Speed/scale": velocity_movement.movement_speed_animation_scale()
					})
		elif position.y <= world_settings.sea_level:
			play_animation("swim")
	else:
		if is_on_floor:
			play_walking_audio("empty")
			#if enemies_in_range.is_empty():
				#play_animation("idle")
			#else:
			play_animation("battle_idle")
		
	if not is_on_floor:
		if position.y <= world_settings.sea_level:
			if velocity.length() <= 0:
				play_animation("float")
		elif feet_position() > Navigator.get_platform_height(get_world_3d().direct_space_state, position.x, position.z) + 0.25:
			play_animation("fall")
	elif current_animation_is("fall"):
		play_animation("land")
		
		
	if velocity:
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		player_moved.emit(delta, state)
		set_underwater()
	
	if enemies_in_range.is_empty() and velocity:
		if camera_bounce_direction == 0:
			camera_bounce_direction = 1
		var y_mult := clampf(velocity.y, -10.0, 10.0) / 10.0
		if is_zero_approx(y_mult):
			if absf(cam.v_offset) > 0.05:
				camera_bounce_direction *= -1
		else:
			camera_bounce_direction = floori(signf(y_mult))
		cam.v_offset = lerpf(cam.v_offset, 0.5 * camera_bounce_direction, 0.025)
	else:
		camera_bounce_direction = 0
		if not is_zero_approx(cam.v_offset):
			cam.v_offset = lerpf(cam.v_offset, 0.0, 0.05)
		
	var rate := 0.05 if velocity.length() == 0 else 0.01
	camera_target_velocity = lerp(camera_target_velocity, clamp(velocity.length(), 0.0, 3.0), rate)
	var cam_distance_ratio := (1 + (world_settings.camera_settings.distance - 5) / 5.0)
	var spring_extension := 0.0
	if world_settings.camera_settings.auto_distance:
		cam_arm.spring_length = 1.0 * cam_distance_ratio # set it to min here so `compute_max_watched_enemies_distance` is consistent
		max_watched_enemies_distance = lerp(max_watched_enemies_distance, compute_max_watched_enemies_distance(), rate)
		spring_extension = minf(max_watched_enemies_distance / 5.0, 10.0)
	cam_arm.spring_length = (1.0 + spring_extension) * cam_distance_ratio
	
	if shake_intensity > 0.0:
		var intensity := clampf(shake_intensity, 0.0, 1.0) ** 2
		if is_zero_approx(intensity):
			shake_intensity = 0.0
		else:
			shake_intensity = clampf(lerpf(shake_intensity, 0.0, 0.05), 0.0, 1.0)
		var t := fmod(Time.get_unix_time_from_system(), 1000000)
		var dx := camera_shake_noise.get_noise_3d(t, 0, 0)
		var dy := camera_shake_noise.get_noise_3d(0, t, 0)
		var dz := camera_shake_noise.get_noise_3d(0, 0, t)
		cam.rotation.x = (dx * intensity) * (2 * PI / 8)
		cam.rotation.y = (dy * intensity) * (2 * PI / 8)
		cam.rotation.z = (dz * intensity) * (2 * PI / 8)
				
	var reasons := spell_caster.update(self, delta)
	for spell: Spell in reasons:
		spell_was_limited.emit(spell, reasons[spell])
	
	projectile_indicator_scale = 1.0 + (spring_extension / 10.0) * 2.0
	update_projectile_indicators()
	
	#(interface.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture = sub_viewport.get_texture()

func cast_spell(insert: Callable, next_spell: Spell) -> void:
	if vitals.stun.value > 0 or vitals.freeze.value >= 1.0:
		return
	
	var new_spell := next_spell.duplicate({}, true)
	for e: Artifact.Element in spell_modifier:
		if e == new_spell.element or e == Artifact.Element.ANY:
			new_spell.power = new_spell.power * (1.0 + spell_modifier[e].y / 100.0) + spell_modifier[e].x
	new_spell.crit_rate = new_spell.crit_rate * (1.0 + buff_crit_rate.y / 100.0) + buff_crit_rate.x 
	new_spell.crit_dmg = new_spell.crit_dmg * (1.0 + buff_crit_dmg.y / 100.0) + buff_crit_dmg.x 
	play_animation("attack")
#	await get_parent_node_3d().get_tree().create_timer(animator.get_animation("Attack").length / 2.5 / 2.0).timeout
	await get_tree().physics_frame
	var err := spell_caster.cast_spell(self, vitals, insert, new_spell) as MagicBook.DisallowSpellReason
	if err == MagicBook.DisallowSpellReason.NONE:
		emit_spell_was_cast(next_spell)
	else:
		spell_was_disallowed.emit(new_spell, err)
	emit_vitals_update()
			
		
func _on_wet_area_body_entered(body: Node3D) -> void:
	print(body)
	

func give_back_mana_after_hit(origin: Node3D, target: CollisionObject3D, spell: Spell, time: float, p: SpellBody, damage: Dictionary) -> void:
	if not origin is Player:
		return
	var c := spell.cooldown
	var u := magic_book.cooldown.get(spell.name, 0.0) as float
	var v := minf(u / (c + spell.mana_cost), 1.0)
	var t := (1.0 - (-1.5 * (v ** 3.0 / 3.0 - v))) * spell.mana_cost / float(spell.count)
	#t = t / (clampf(absf(p.lifetime_velocity) * 0.05, 0.0, 1.0) ** 10.0 + 1) 
	var rv := 1.0 - clampf(absf(p.lifetime_velocity) / (UpgradeSettings.LIMIT_v + spell.buff_v), 0.0, 1.0)
	t = t * (1.0 - pow(1.0 - rv, 2.0)) # scale payback down when spell has high velocity.
	vitals.mana.apply_ignoring_resistance(t * p.calculate_overall_complexity())
	if target.collision_layer & Globals.Layer.ENEMY != 0:
		update_artifact_effects(Artifact.Event.DEAL, spell)
		if enemies_in_range.has(target) and (damage["dmg"] as int) > 0:
			var stats := enemies_in_range[target] as CombatStats
			stats.hit_count += 1
			var interval := Time.get_unix_time_from_system() - stats.last_hit_time
			var factor := clampf(1.0 - interval / 5.0, 0.0, 1.0)
			stats.sum_of_hit_intervals += factor
			stats.last_hit_time = Time.get_unix_time_from_system()
		
	
func watch_enemy(enemy: Enemy) -> void:
	enemies_in_range[enemy] = CombatStats.new(Time.get_unix_time_from_system())
	
func ignore_enemy(enemy: Enemy) -> void:
	enemies_in_range.erase(enemy)
	enemy.vitals.health.value = enemy.vitals.health.max_value
	
func watch_target(target: TargetShape) -> void:
	targets_in_range[target] = Time.get_unix_time_from_system()
	target.player = self
	
func ignore_target(target: TargetShape) -> void:
	targets_in_range.erase(target)
	target.player = null
	
func kill_multiplier(enemy: Enemy) -> float:
	if enemies_in_range.has(enemy):
		var stats := enemies_in_range[enemy] as CombatStats
		var count := stats.hit_count
		var sum := stats.sum_of_hit_intervals
		if count == 0:
			return 0.0
		else:
			return sum / float(count)
	else:
		return 0.0
	
	
func set_current_biome(biome: World.Biome) -> void:
	velocity_movement.current_biome = biome
	
func set_current_biome_grass_color(color: Color) -> void:
	(leaves.process_material as ParticleProcessMaterial).color = color

func set_underwater(underwater: float = 0.5) -> float:
	var screen_filter: MeshInstance3D = $CamPivot/Arm/Lens/ScreenFilter
	var screen_mesh: Mesh = screen_filter.mesh
	var screen_material: ShaderMaterial = screen_mesh.surface_get_material(0)
	if position.y + 2.0 < world_settings.sea_level:
		screen_filter.visible = true
		screen_material.set_shader_parameter("underwater", underwater)
		var meters_below_sea := world_settings.sea_level - (position.y + 2.0)
		screen_material.set_shader_parameter("depth_distance", maxf(10.0, 500.0 - meters_below_sea))
		return underwater
	else:
		screen_filter.visible = false
		screen_material.set_shader_parameter("underwater", 0.0)
		screen_material.set_shader_parameter("depth_distance", 0.0)
		return 0.0
	
func compute_max_watched_enemies_distance() -> float:
	var result := 0.0
	for e: Enemy in enemies_in_range:
		if not cam.is_position_in_frustum(e.global_position):
			result = maxf(result, position.distance_to(e.position))
	return result
	
func update_watched_enemies_positions(delta: float) -> void:
	for enemy: Enemy in enemies_in_range:
		var movement := Vector3.ZERO
		
		var enemy_seperation := maxf(enemy.bounds.x, maxf(enemy.bounds.y, enemy.bounds.z)) * enemy.separation_multiplier()
		for other: Enemy in enemies_in_range:
			if enemy == other:
				continue
			var distance := enemy.position.distance_to(other.position)
			if distance < enemy_seperation:
				movement += (enemy.position - other.position).normalized() * (1.0 - distance / enemy_seperation)
				
		var stats := enemies_in_range[enemy] as CombatStats
		if movement.is_zero_approx():			
			stats.seperation = Vector3.ZERO
		else:
			stats.seperation += movement / enemies_in_range.size()
	
	
func pick_up_key(key: int) -> bool:
	if keys & (1 << (key - 1)) == 0:
		keys |= (1 << (key - 1))
		world_settings.player_keys = keys
		return true
	else:
		return false
	
func update_artifact_effects(event_to_match: Artifact.Event, spell: Spell) -> void:
	for event: Vector2i in artifacts.effects:
		if not active_effects.has(event):
			active_effects[event] = {}
		var duration := float(event.x) as float
		@warning_ignore("integer_division")
		var event_kind: Artifact.Event = (event.y / Artifact.Element.size()) as Artifact.Event
		var event_el: Artifact.Element = (event.y % Artifact.Element.size()) as Artifact.Element
		if event_kind == event_to_match and (event_el == spell.element or event_el == Artifact.Element.ANY):
			for effect: int in artifacts.effects[event]:
				if (active_effects[event] as Dictionary).get(effect, false):
					continue
				else:
					active_effects[event][effect] = true
				var amount := artifacts.effects[event][effect] as Vector2
				@warning_ignore("integer_division")
				var effect_kind: Artifact.Effect = (effect / Artifact.Element.size()) as Artifact.Effect
				var effect_el: Artifact.Element = (effect % Artifact.Element.size()) as Artifact.Element
				if effect_el == Artifact.Element.HEALTH:
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						vitals.health.apply(amount.x)
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						vitals.health.apply(vitals.health.max_value * amount.y / 100.0)
				elif effect_el == Artifact.Element.MANA:
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						vitals.mana.apply(amount.x)
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						vitals.mana.apply(vitals.mana.max_value * amount.y / 100.0)
				elif effect_el == Artifact.Element.POWER:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_P() * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_P += value
					get_tree().create_timer(duration).timeout.connect(func() -> void: magic_book.settings.upgrade_settings.buff_P -= value; active_effects[event][effect] = false)
				elif effect_el == Artifact.Element.COUNT:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_N() * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_N += value
					get_tree().create_timer(duration).timeout.connect(func() -> void: magic_book.settings.upgrade_settings.buff_N -= value; active_effects[event][effect] = false)
				elif effect_el == Artifact.Element.DURATION:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_T() * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_T += value
					get_tree().create_timer(duration).timeout.connect(func() -> void: magic_book.settings.upgrade_settings.buff_T -= value; active_effects[event][effect] = false)
				elif effect_el == Artifact.Element.MANA_BUMP:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_mana() * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_mana += value
					get_tree().create_timer(duration).timeout.connect(func() -> void: magic_book.settings.upgrade_settings.buff_mana -= value; active_effects[event][effect] = false)
				elif effect_el == Artifact.Element.HEALTH_BUMP:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_health() * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_health += value
					get_tree().create_timer(duration).timeout.connect(func() -> void: magic_book.settings.upgrade_settings.buff_health -= value; active_effects[event][effect] = false)
				elif effect_el == Artifact.Element.SPELL_VELOCITY:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_v() * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_v += value
					spell_velocity_was_buffed.emit(magic_book.settings.upgrade_settings.buff_v)
					get_tree().create_timer(duration).timeout.connect(func() -> void: 
						magic_book.settings.upgrade_settings.buff_v -= value
						spell_velocity_was_buffed.emit(magic_book.settings.upgrade_settings.buff_v)
						active_effects[event][effect] = false
					)
				elif effect_el == Artifact.Element.SPELL_RADIUS:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_r() * amount.x / 100.0
					magic_book.settings.upgrade_settings.buff_r += value
					spell_radius_was_buffed.emit(magic_book.settings.upgrade_settings.buff_r)
					get_tree().create_timer(duration).timeout.connect(func() -> void: 
						magic_book.settings.upgrade_settings.buff_r -= value
						spell_radius_was_buffed.emit(magic_book.settings.upgrade_settings.buff_r)
						active_effects[event][effect] = false
					)
				elif effect_el == Artifact.Element.ATTACK:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_attack() * amount.x / 100.0
					magic_book.settings.upgrade_settings.buff_attack += value
					attack_was_buffed.emit(magic_book.settings.upgrade_settings.buff_attack)
					get_tree().create_timer(duration).timeout.connect(func() -> void: 
						magic_book.settings.upgrade_settings.buff_attack -= value
						attack_was_buffed.emit(magic_book.settings.upgrade_settings.buff_attack)
						active_effects[event][effect] = false
					)
				elif effect_el == Artifact.Element.DEFENCE:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_defence() * amount.x / 100.0
					magic_book.settings.upgrade_settings.buff_defence += value
					defence_was_buffed.emit(magic_book.settings.upgrade_settings.buff_defence)
					get_tree().create_timer(duration).timeout.connect(func() -> void: 
						magic_book.settings.upgrade_settings.buff_defence -= value
						defence_was_buffed.emit(magic_book.settings.upgrade_settings.buff_defence)
						active_effects[event][effect] = false
					)
				elif effect_el == Artifact.Element.RUNNING_SPEED:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_running_speed() * amount.x / 100.0
					magic_book.settings.upgrade_settings.buff_running_speed += value
					speed_was_buffed.emit(magic_book.settings.upgrade_settings.buff_running_speed)
					get_tree().create_timer(duration).timeout.connect(func() -> void: 
						magic_book.settings.upgrade_settings.buff_running_speed -= value
						speed_was_buffed.emit(magic_book.settings.upgrade_settings.buff_running_speed)
						active_effects[event][effect] = false
					)
				elif effect_el == Artifact.Element.CRIT_RATE:
					buff_crit_rate += amount
					get_tree().create_timer(duration).timeout.connect(func() -> void: 
						buff_crit_rate -= amount
						active_effects[event][effect] = false
					)
				elif effect_el == Artifact.Element.CRIT_DMG:
					buff_crit_dmg += amount
					get_tree().create_timer(duration).timeout.connect(func() -> void: 
						buff_crit_dmg -= amount
						active_effects[event][effect] = false
					)
				else:
					if effect_el == Artifact.Element.ANY:
						for eff_el: Artifact.Element in [Artifact.Element.FIRE, Artifact.Element.WATER, Artifact.Element.AIR, Artifact.Element.ROCK, Artifact.Element.ICE, Artifact.Element.ELECTRIC]:
							if not spell_modifier.has(eff_el):
								spell_modifier[eff_el] = Vector2.ZERO
							if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
								spell_modifier[eff_el] += amount
								get_tree().create_timer(duration).timeout.connect(func() -> void: spell_modifier[eff_el] -= amount; active_effects[event][effect] = false)
								
							if not damage_resistance.has(eff_el):
								damage_resistance[eff_el] = Vector2.ZERO
							if effect_kind == Artifact.Effect.RESISTANCE_FLAT or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
								damage_resistance[eff_el] += amount
								get_tree().create_timer(duration).timeout.connect(func() -> void: damage_resistance[eff_el] -= amount; active_effects[event][effect] = false)
					else:
						if not spell_modifier.has(effect_el):
							spell_modifier[effect_el] = Vector2.ZERO
						if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
							spell_modifier[effect_el] += amount
							get_tree().create_timer(duration).timeout.connect(func() -> void: spell_modifier[effect_el] -= amount; active_effects[event][effect] = false)
							
						if not damage_resistance.has(effect_el):
							damage_resistance[effect_el] = Vector2.ZERO
						if effect_kind == Artifact.Effect.RESISTANCE_FLAT or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
							damage_resistance[effect_el] += amount
							get_tree().create_timer(duration).timeout.connect(func() -> void: damage_resistance[effect_el] -= amount; active_effects[event][effect] = false)
					
	vitals.damage_resistance = damage_resistance
	
func transition_bg_audio(clip: String) -> void:
	if bg_audio["parameters/switch_to_clip"] != clip:
		bg_audio["parameters/switch_to_clip"] = clip
		
func setup_menu_transition(open: Callable, close: Callable) -> void:
	on_menu_open = open
	on_menu_close = close
	menu_callbacks_are_set = true
	cam_animator.animation_finished.connect(func(animation_name: String) -> void:
		if animation_name == "OpenMenu":
			on_menu_open.call()
		elif animation_name == "CloseMenu":
			on_menu_close.call()
	)
		
func transition_menu(is_open: bool) -> void:
	if is_open:
		cam_animator.play("OpenMenu")
	else:		
		cam_animator.play("CloseMenu")
		
func change_reticule_visible(should_hide: bool) -> void:
	(get_node("CanvasLayer/Reticule") as TextureRect).visible = not should_hide

func play_walking_audio(clip: String) -> void:
	if walking_audio["parameters/switch_to_clip"] != clip:
		walking_audio["parameters/switch_to_clip"] = clip
		
func on_pick_up_artifact(artifact: Artifact, message: String) -> void:
	artifacts.save(world_settings.world_name)
	save_name_generator()
	
func on_pick_up_spell(spell: Spell, message: String) -> void:
	magic_book.save(world_settings.world_name)
	save_name_generator()
	
func on_pick_up_key(key: int, message: String) -> void:
	world_settings.save()
	
func on_pick_up_coin(coin: int, message: String) -> void:
	world_settings.save()
	
func on_pick_up_red_cross(health: float, message: String) -> void:
	vitals.health.apply_by_percentage_on_max(health)
	world_settings.save()
	
func on_pick_up_scroll_note(note_id: String, message: String) -> void:
	if not GlobalData.game_settings.unlocked_notes.has(note_id):
		GlobalData.game_settings.unlocked_notes[note_id] = true
		GlobalData.game_settings.save()
	
func save_name_generator() -> void:
	name_generator.save(world_settings.world_name)

func update_projectile(pivot: Node3D, pi_size: float, body: Node3D, color: Color) -> bool:
	if not body.is_inside_tree():
		return false
	if cam.is_position_in_frustum(body.global_position):
		return false
		
	if projectile_indicators.has(body):
		var mi := projectile_indicators[body] as Node3D
		mi.scale = Vector3(pi_size, pi_size, pi_size)
		if body.position != mi.position:
			if not Vector3.UP.cross(body.position - mi.global_position).is_zero_approx():
				mi.look_at(body.position)
	else:
		var mi: ProjectileIndicator
		if projectile_indicator_store.is_empty():
			mi = projectile_indicator.instantiate() as ProjectileIndicator
			pivot.add_child(mi)
		else:
			mi = projectile_indicator_store.pop_back()
		mi.position = Vector3(0, 2, 0)
		mi.scale = Vector3(pi_size, pi_size, pi_size)
		projectile_indicators[body] = mi
		var mat := mi.mesh_instance.mesh.surface_get_material(0) as ShaderMaterial
		mat.set_shader_parameter("albedo", color)
		
	return true
	

## updated_spell_bodies: [SpellBody]bool
func update_projectile_indicator(body: SpellBody, updated_spell_bodies: Dictionary) -> void:
	var pis := world_settings.hud_settings.projectile_indicator_size * projectile_indicator_scale
	var dist := clampf(1.0 - body.position.distance_to(position) / 20.0, 0.0, 1.0)
	updated_spell_bodies[body] = update_projectile(body_pivot, pis * (1.0 + dist * dist), body, Spell.color_from_element(body.spell.element))

func update_projectile_indicators() -> void:
	var updated_spell_bodies := {} ## [SpellBody]bool
	var pis := world_settings.hud_settings.projectile_indicator_size * projectile_indicator_scale
	if pis > 0:
		for enemy: Enemy in enemies_in_range:
			var enemy_dist := clampf(1.0 - enemy.position.distance_to(position) / 20.0, 0.0, 1.0)
			updated_spell_bodies[enemy] = update_projectile(body_pivot, pis * (1.0 + enemy_dist * enemy_dist), enemy, Color.BLACK)
			enemy.spell_caster.apply_to_all_particles(update_projectile_indicator, updated_spell_bodies)
		for target: TargetShape in targets_in_range:
			if target.spell_caster == null:
				continue
			target.spell_caster.apply_to_all_particles(update_projectile_indicator, updated_spell_bodies)
		spell_caster.apply_to_all_particles(update_projectile_indicator, updated_spell_bodies)
		
	for body: Node3D in projectile_indicators:
		if not updated_spell_bodies.get(body, false) as bool:
			var mi := projectile_indicators[body] as Node3D
			projectile_indicator_store.append(mi)
			mi.position = Vector3(0, -1000, 0)
			projectile_indicators.erase(body)

class CombatStats:
	var start_time: float
	var seperation: Vector3
	var hit_count: int
	var last_hit_time: float
	var sum_of_hit_intervals: float
	
	func _init(t: float) -> void:
		start_time = t
		seperation = Vector3.ZERO
		hit_count = 0
		last_hit_time = t
		sum_of_hit_intervals = 0.0
