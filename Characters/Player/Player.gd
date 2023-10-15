class_name Player
extends CharacterBody3D

@onready var cam_pivot: Marker3D = $CamPivot
@onready var cam_arm: SpringArm3D = $CamPivot/Arm
@onready var cam: Camera3D = $CamPivot/Arm/Lens

@onready var animator: AnimationPlayer = $Pivot/King/AnimationPlayer 
@onready var cam_animator: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $Pivot/King/AnimationTree

var velocity_movement := VelocityMovement.player()
var spell_caster := SpellCaster.new(SpellCaster.Entity.PLAYER)
var invunerable := 0
var magic_book: MagicBook
var artifacts: Artifacts

var camera_target_velocity: float = 0
var shake_intensity: float = 0.0
const camera_shake_noise = preload("res://Characters/Player/camera_shake_noise.tres")

signal player_moved
signal vital_update(vitals: Vitals)
signal spell_was_cast
signal spell_velocity_was_buffed
signal spell_radius_was_buffed

var vitals: Vitals

var spell_modifier: Dictionary # Artifact.Element -> Vector2 (flat: int, percentage: float)
var damage_resistance: Dictionary # Artifact.Element -> Vector2 (flat: int, percentage: float)

func _ready():
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 50, 0.5))
	emit_vitals_signal()
	velocity = Vector3.ZERO
	spell_caster.projectile_hit.connect(give_back_mana_after_hit)
	

func _input(event):
	pass
	
func emit_vitals_signal():
	vital_update.emit(vitals)
	
func emit_spell_was_cast(s: Spell):
	spell_was_cast.emit(s)
	
func pan_camera(movement: Vector2):
	var damping := 0.75
	const T := 5.0
	const S := 1.5
	var exp_movement := Vector2(abs(movement.x / T) ** S * sign(movement.x), abs(movement.y / T) ** S * sign(movement.y))
	cam_pivot.rotate_y(-exp_movement.x * damping / 180 * PI)
	cam_arm.rotate_x(-exp_movement.y * damping / 180 * PI / 3)
	cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)
	
	var size := -movement.length()
	if vitals.wetness.value > vitals.wetness.min_value and position.y > Globals.sea_level():
		vitals.wetness.apply(size / 50_000.0)
	if vitals.freeze.value > vitals.freeze.min_value:
		vitals.wetness.apply(size / 75_000.0)

func current_animation_is(animation: String) -> bool:
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	var current := playback.get_current_node()
	return current == animation

func play_animation(animation: String):
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	var current := playback.get_current_node()
	if current != "death" and current != animation:
		playback.travel(animation)

func can_move() -> bool:
#	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
#	var current := playback.get_current_node()
#	print(current)
	return invunerable == 0

func add_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse
	
func add_shake(amount: float):
	shake_intensity += amount

func _physics_process(delta):
	if magic_book.settings.is_paused:
		return
	
	if invunerable > 0:
		invunerable -= 1
		
	var movement := velocity_movement.update(delta, vitals, 14, self)
	emit_vitals_signal()
	
	velocity = movement["velocity"]
	var direction = movement["direction"]
	velocity_movement.rotate_character(get_node("."), direction)
	move_and_slide()
	if direction != Vector3.ZERO and velocity != Vector3.ZERO:
		if is_on_floor():
			if velocity.length() < 1:
				play_animation("walk")
			else:
				play_animation("run")
	else:
		if is_on_floor():
			play_animation("battle_idle")
		
	if not is_on_floor_only():
		play_animation("fall")
	elif current_animation_is("fall"):
		play_animation("land")
		
		
	if velocity:
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		player_moved.emit(delta, state)
		var rect: ColorRect = get_node("CanvasLayer/ColorRect")
		if position.y + 2.0 < Globals.sea_level():
			rect.material.set_shader_parameter("underwater", 0.5)
		else:
			rect.material.set_shader_parameter("underwater", 0.0)
		
	var rate := 0.05 if velocity.length() == 0 else 0.01
	camera_target_velocity = lerp(camera_target_velocity, clamp(velocity.length(), 0.0, 3.0), rate)
	cam_arm.spring_length = 1 + camera_target_velocity
	
	if shake_intensity > 0.0:
		var intensity := clampf(shake_intensity, 0, 1) ** 2
		if is_zero_approx(intensity):
			shake_intensity = 0.0
		else:
			shake_intensity = clamp(lerp(shake_intensity, 0.0, 0.05), 0.0, 1.0)
		var t := fmod(Time.get_unix_time_from_system(), 1000000)
		var dx := camera_shake_noise.get_noise_3d(t, 0, 0)
		var dy := camera_shake_noise.get_noise_3d(0, t, 0)
		var dz := camera_shake_noise.get_noise_3d(0, 0, t)
		cam.rotation.x = (dx * intensity) * (2 * PI / 8)
		cam.rotation.y = (dy * intensity) * (2 * PI / 8)
		cam.rotation.z = (dz * intensity) * (2 * PI / 8)
				
	spell_caster.deferred_update(self, delta)

func cast_spell(insert: Callable, next_spell: Spell):
	if vitals.stun.value > 0 or vitals.freeze.value >= 1.0:
		return
	
	var new_spell := next_spell.duplicate()
	for e in spell_modifier:
		if e == new_spell.element or e == Artifact.Element.ANY:
			new_spell.power = new_spell.power * (1.0 + spell_modifier[e].y / 100.0) + spell_modifier[e].x
	play_animation("attack")
#	await get_parent_node_3d().get_tree().create_timer(animator.get_animation("Attack").length / 2.5 / 2.0).timeout
	await get_tree().physics_frame
	spell_caster.cast_spell(self, vitals, insert, new_spell)
	emit_spell_was_cast(next_spell)
	update_artifact_effects(Artifact.Event.DEAL, next_spell)
	emit_vitals_signal()
			
		
func _on_wet_area_body_entered(body):
	print(body)
	
func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.PLAYER, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true

func give_back_mana_after_hit(spell: Spell, time: float):
	var c := spell.cooldown
	var u = magic_book.last_use.get(spell.name, 0.0)
	var v = minf((time - u) / (c + spell.mana_cost), 1.0)
	var t = (1.0 - (-1.5 * (v ** 3.0 / 3.0 - v))) * spell.mana_cost / float(spell.count)
	vitals.mana.apply_ignoring_resistance(t)
	
func update_artifact_effects(event_to_match: Artifact.Event, spell: Spell):
	for event in artifacts.effects:
		var duration = event.x
		var event_kind = event.y / Artifact.Element.size()
		var event_el = event.y % Artifact.Element.size()
		if event_kind == event_to_match and event_el == spell.element or event_el == Artifact.Element.ANY:
			for effect in artifacts.effects[event]:
				var amount = artifacts.effects[event][effect]
				var effect_kind = effect / Artifact.Element.size()
				var effect_el = effect % Artifact.Element.size()
				if effect_el == Artifact.Element.HEALTH:
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						vitals.health.apply(amount.x)
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						vitals.health.apply(vitals.health.value * amount.y / 100.0)
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						vitals.health.apply(-amount.x)
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						vitals.health.apply(vitals.health.value * -amount.y / 100.0)
				elif effect_el == Artifact.Element.MANA:
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						vitals.mana.apply(amount.x)
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						vitals.mana.apply(vitals.mana.value * amount.y / 100.0)
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						vitals.mana.apply(-amount.x)
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						vitals.mana.apply(vitals.mana.value * -amount.y / 100.0)
				elif effect_el == Artifact.Element.POWER:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_P * amount.y / 100.0
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = -amount.x
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = -magic_book.settings.upgrade_settings.max_P * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_P += value
					get_tree().create_timer(duration).timeout.connect(func(): magic_book.settings.upgrade_settings.buff_P -= value)
				elif effect_el == Artifact.Element.COUNT:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_N * amount.y / 100.0
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = -amount.x
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = -magic_book.settings.upgrade_settings.max_N * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_N += value
					get_tree().create_timer(duration).timeout.connect(func(): magic_book.settings.upgrade_settings.buff_N -= value)
				elif effect_el == Artifact.Element.DURATION:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_T * amount.y / 100.0
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = -amount.x
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = -magic_book.settings.upgrade_settings.max_T * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_T += value
					get_tree().create_timer(duration).timeout.connect(func(): magic_book.settings.upgrade_settings.buff_T -= value)
				elif effect_el == Artifact.Element.MANA_BUMP:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_mana * amount.y / 100.0
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = -amount.x
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = -magic_book.settings.upgrade_settings.max_mana * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_mana += value
					get_tree().create_timer(duration).timeout.connect(func(): magic_book.settings.upgrade_settings.buff_mana -= value)
				elif effect_el == Artifact.Element.SPELL_VELOCITY:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_v * amount.y / 100.0
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = -amount.x
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = -magic_book.settings.upgrade_settings.max_v * amount.y / 100.0
					magic_book.settings.upgrade_settings.buff_v += value
					spell_velocity_was_buffed.emit(magic_book.settings.upgrade_settings.buff_v)
					get_tree().create_timer(duration).timeout.connect(func(): 
						magic_book.settings.upgrade_settings.buff_v -= value
						spell_velocity_was_buffed.emit(magic_book.settings.upgrade_settings.buff_v)
					)
				elif effect_el == Artifact.Element.SPELL_RADIUS:
					var value := 0.0
					if effect_kind == Artifact.Effect.BOOST_FLAT:
						value = amount.x
					elif effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						value = magic_book.settings.upgrade_settings.max_r * amount.x / 100.0
					elif effect_kind == Artifact.Effect.RESISTANCE_FLAT:
						value = -amount.x
					elif effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						value = -magic_book.settings.upgrade_settings.max_r * amount.x / 100.0
					magic_book.settings.upgrade_settings.buff_r += value
					spell_radius_was_buffed.emit(magic_book.settings.upgrade_settings.buff_r)
					get_tree().create_timer(duration).timeout.connect(func(): 
						magic_book.settings.upgrade_settings.buff_r -= value
						spell_radius_was_buffed.emit(magic_book.settings.upgrade_settings.buff_r)
					)
				else:
					if not spell_modifier.has(effect_el):
						spell_modifier[effect_el] = Vector2.ZERO
					if effect_kind == Artifact.Effect.BOOST_FLAT or effect_kind == Artifact.Effect.BOOST_PERCENTAGE:
						spell_modifier[effect_el] += amount
						get_tree().create_timer(duration).timeout.connect(func(): spell_modifier[effect_el] -= amount)
						
					if not damage_resistance.has(effect_el):
						damage_resistance[effect_el] = Vector2.ZERO
					if effect_kind == Artifact.Effect.RESISTANCE_FLAT or effect_kind == Artifact.Effect.RESISTANCE_PERCENTAGE:
						damage_resistance[effect_el] += amount
						get_tree().create_timer(duration).timeout.connect(func(): damage_resistance[effect_el] -= amount)
					
	vitals.damage_resistance = damage_resistance
	
