class_name Bat
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

func _ready():
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100 * level, 0, 100 * level), Vitals.Stat.new(500, 0, 500, 10))
	vitals.perception.value = 25
	
	idle_path = PathStyle.new(randf()).speed(clamp(level * 1.1, 1, 14)).circle(position, 5, 10).use_absolute().align_y_to_origin()
	
	const idle_r := 20.0
	const idle_h := 10.0
		
	var rotate_path := PathStyle.Pathway.new()
	var a: Vector3 = Globals.rand_point_in_circle(idle_r, idle_h)
	var b: Vector3 = Globals.rand_point_in_circle(idle_r, idle_h)
	var c: Vector3 = Globals.rand_point_in_circle(idle_r, idle_h)
	var d: Vector3 = Globals.rand_point_in_circle(idle_r, idle_h)
	
	rotate_path.append_with_speed(
		[Globals.form_arc_in_circle(a, b, idle_h), Globals.form_arc_in_circle(b, c, idle_h), Globals.form_arc_in_circle(c, d, idle_h), Globals.form_arc_in_circle(d, a, idle_h)],
		[2, 2, 2, 2],
		[PathStyle.Easing.linear, PathStyle.Easing.linear, PathStyle.Easing.linear, PathStyle.Easing.linear]
	)
	
	#attack_path = PathStyle.new(randf()).follow_path(rotate_path).align_y_to_origin().set_use_player_as_origin().use_absolute().look_at_player()
	
	attack_path = PathStyle.new(0.0).follow_path(PathStyle.Pathway.new().move_to(Vector3(0, 0, 0)).line_to(Vector3(0, 10, 0), 5, PathStyle.Easing.linear).line_to(Vector3(0, 0, 0), 5, PathStyle.Easing.linear)) \
	.align_y_to_origin().set_player_body_vision_as_origin(0, 10).use_absolute().look_at_player()
	
	#attack_path = PathStyle.new(0.0).towards_player(15.0, 20.0).align_y_to_ground().set_use_player_as_origin().use_absolute().look_at_player().speed(5.0)
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var elec1 = GlobalData.magic_book.copy_spell("linear", {"s": "2", "d": "2"})
	elec1.element = Spell.Element.ELECTRIC
	elec1.duration = 10.0
	elec1.power = 1
	var elec2 = GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"})
	elec2.element = Spell.Element.ELECTRIC
	elec2.duration = 8.0
	elec2.power = 1
	var elec3 = GlobalData.magic_book.copy_spell("linear", {"s": "10", "d": "2"})
	elec3.element = Spell.Element.ELECTRIC
	elec3.duration = 6.0
	elec3.power = 1
	
	var elec_arc1 = GlobalData.magic_book.copy_spell("arc", {"R": "pi", "s": "2"})
	elec_arc1.element = Spell.Element.ELECTRIC
	elec_arc1.duration = 10.0
	var elec_arc2 = GlobalData.magic_book.copy_spell("arc", {"R": "pi/2", "s": "5"})
	elec_arc2.element = Spell.Element.ELECTRIC
	elec_arc2.duration = 8.0
	var elec_arc3 = GlobalData.magic_book.copy_spell("arc", {"R": "pi/4", "s": "10"})
	elec_arc3.element = Spell.Element.ELECTRIC
	elec_arc3.duration = 6.0
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
		],
		[ 10, 3, 2 ],
		0.55
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			elec1,
			elec_arc1,
			elec2,
			elec_arc2,
			elec3,
			elec_arc3,
		],
		[ 1, 1, 3, 1, 5, 1 ]
	)
	
	animation_map["attack"] = "Headbutt"

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 20:
		return random_pattern
	else:
		return sequence_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.BAT, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour():
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_path
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		current_path = idle_path
