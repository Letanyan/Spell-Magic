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
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 25
	
	idle_path = PathStyle.new(randf()).speed(clamp(level * 1.1, 1, 14)).circle(position, 5, 10).use_absolute().align_y_to_origin()
	
	const idle_r := 20.0
	const idle_h := 10.0
	var rand_point := func() -> Vector3:
		var p : Vector3 = Vector3(randf() * 2.0 - 1.0, 0, randf() * 2.0 - 1.0).normalized() * idle_r + Vector3(0, idle_h, 0)
		return p 
	
	var form_arc := func(s: Vector3, e: Vector3) -> PathStyle.Segment:
		var a := s.x
		var b := s.z
		var c := e.x
		var d := e.z
		
		var p := Vector3(0.5*(c+a) + sqrt(3.0)/2.0 * (d-b), idle_h, 0.5*(d+b) - sqrt(3.0)/2.0 * (c-a))
		var q := Vector3(0.5*(c+a) - sqrt(3.0)/2.0 * (d-b), idle_h, 0.5*(d+b) + sqrt(3.0)/2.0 * (c-a))
		var m: Vector3
		if randf() < 0.5:
			m = p
		else:
			m = q
			
		return PathStyle.Segment.quad(s, e, m)
		
	var rotate_path := PathStyle.Pathway.new()
	var a: Vector3 = rand_point.call()
	var b: Vector3 = rand_point.call()
	var c: Vector3 = rand_point.call()
	var d: Vector3 = rand_point.call()
	
	rotate_path.append_with_speed(
		[form_arc.call(a, b), form_arc.call(b, c), form_arc.call(c, d), form_arc.call(d, a)],
		[2, 2, 2, 2],
		[PathStyle.Easing.linear, PathStyle.Easing.linear, PathStyle.Easing.linear, PathStyle.Easing.linear]
	)
	
	attack_path = PathStyle.new(randf()).follow_path(rotate_path).align_y_to_origin().set_use_player_as_origin().use_absolute().look_at_player()
	
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var elec1 = GlobalData.magic_book.copy_spell("linear", {"s": "2", "d": "2"})
	elec1.element = Spell.Element.ELECTRIC
	elec1.duration = 10.0
	var elec2 = GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"})
	elec2.element = Spell.Element.ELECTRIC
	elec2.duration = 8.0
	var elec3 = GlobalData.magic_book.copy_spell("linear", {"s": "10", "d": "2"})
	elec3.element = Spell.Element.ELECTRIC
	elec3.duration = 6.0
	
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
		0.15
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
