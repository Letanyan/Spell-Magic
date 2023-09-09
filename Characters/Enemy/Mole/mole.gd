class_name Mole
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
	
	hormones = Hormones.new(-0.5, 0.5, -0.5, 0.25)
	
	idle_path = PathStyle.new(randf()).circle_path(5, 0).set_origin(position).speed(7).use_absolute().align_y_to_origin()
	
	var R := 5.0
	var U := -5.0
	var s1 := PathStyle.Segment.arc(R, 0, PI / 2, U)
	var v1 := Vector3(R, U, 0).rotated(Vector3.UP, PI / 2)
	var r1 := PathStyle.Segment.linear(v1, Vector3(v1.x, -U, v1.z))
	var r1d := PathStyle.Segment.linear(Vector3(v1.x, -U, v1.z), v1)
	
	var s2 := PathStyle.Segment.arc(R, PI / 2, PI, U)
	var v2 := Vector3(R, U, 0).rotated(Vector3.UP, PI)
	var r2 := PathStyle.Segment.linear(v2, Vector3(v2.x, -U, v2.z))
	var r2d := PathStyle.Segment.linear(Vector3(v2.x, -U, v2.z), v2)
	
	var s3 := PathStyle.Segment.arc(R, PI, PI * 3 / 2, U)
	var v3 := Vector3(R, U, 0).rotated(Vector3.UP, PI * 3 / 2)
	var r3 := PathStyle.Segment.linear(v3, Vector3(v3.x, -U, v3.z))
	var r3d := PathStyle.Segment.linear(Vector3(v3.x, -U, v3.z), v3)
	
	var s4 := PathStyle.Segment.arc(R, PI * 3 / 2, PI * 2, U)
	var v4 := Vector3(R, U, 0).rotated(Vector3.UP, PI * 2)
	var r4 := PathStyle.Segment.linear(v4, Vector3(v4.x, -U, v4.z))
	var r4d := PathStyle.Segment.linear(Vector3(v4.x, -U, v4.z), v4)
	
	var p := PathStyle.Pathway.new()
	p.append([s1, r1, r1d, s2, r2, r2d, s3, r3, r3d, s4, r4, r4d])
	
	attack_path = PathStyle.new(randf()).follow_path(p).set_use_player_as_origin().speed(5).use_absolute().align_y_to_origin()
	current_path = idle_path
	
	knowledge = Knowledge.new({EntityInfo.Kind.PLAYER: true, EntityInfo.Kind.BAT: true}, false)
	
	none_pattern = AttackPatterns.none()
	
	random_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 15 + u * 5", "v * t * 15 + v * 5", "w * t * 15 + w * 5", "1", 0.1, 1, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5 + u * 5", "v * t * 5 + v * 5", "w * t * 5 + w * 5", "1", 0.1, 2, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 15 + u * 5", "v * t * 15 + v * 5", "w * t * 15 + w * 5", "1", 0.1, 3, Spell.Element.ELECTRIC, 1),
		],
		[ 5, 3, 2 ],
		false,
		0.5
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.ELECTRIC, 1),
		],
		[ 1, 2, 1 ],
		true
	)
	
	animation_map["run"] = "Run"
	animation_map["idle"] = "Idle"
	animation_map["walk"] = "Walk"
	animation_map["attack"] = "Weapon"
	animation_map["death"] = "Death"

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
