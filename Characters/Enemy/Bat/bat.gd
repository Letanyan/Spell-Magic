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
	
	idle_path = PathStyle.new(randf()).circle_path(5, 10).set_origin(position).speed(clamp(level * 1.1, 1, 14)).use_absolute().align_y_to_origin()
#	attack_path = PathStyle.new(randf()).circle_path(5 * randf() + 5, 5 * randf() + 2).set_use_player_as_origin().speed(clamp(level * 1.25, 1, 14)).use_absolute().align_y_to_origin().look_at_player()
#	attack_path = PathStyle.new(randf()).use_expr("cos(t/pi*s)*15", "sin(t/pi)*5+10", "sin(t/pi*s)*15").set_use_player_as_origin().speed(clamp(level * 1.25, 1, 14)).use_absolute().align_y_to_origin().look_at_player()
	
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
	var e: Vector3 = rand_point.call()
	var f: Vector3 = rand_point.call()
	var g: Vector3 = rand_point.call()
	var h: Vector3 = rand_point.call()
	
	rotate_path.append([form_arc.call(a, b), form_arc.call(b, c), form_arc.call(c, d), form_arc.call(d, e), form_arc.call(e, f), form_arc.call(f, g), form_arc.call(g, h), form_arc.call(h, a)])
	
	attack_path = PathStyle.new(randf()).follow_path(rotate_path).align_y_to_origin().set_use_player_as_origin().use_absolute().look_at_player()
	
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	random_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 10 + u * 2", "v * t * 10 + v * 2", "w * t * 10 + w * 2", "1", 0.1, 1000, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2", "w * t * 5 + w * 2", "1", 0.1, 2000, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 15 + u * 2", "v * t * 15 + v * 2", "w * t * 15 + w * 2", "1", 0.1, 3000, Spell.Element.ELECTRIC, 1),
		],
		[ 3, 10, 2 ],
		false,
		0.15
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 1", "w * t * 5", "1", 0.1, 5, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 1", "w * t * 5", "1", 0.1, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 1", "w * t * 5", "1", 0.1, 5, Spell.Element.ELECTRIC, 1),
		],
		[ 1, 2, 1 ],
		true
	)
	
	animation_map["attack"] = "Headbutt"

func attack_state() -> AttackPatterns:
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
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
