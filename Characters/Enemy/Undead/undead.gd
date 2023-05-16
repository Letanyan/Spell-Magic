class_name Undead
extends Enemy

func _ready():
	super._ready()
	
	animation_map["idle"] = "undead_idle"
	animation_map["walk"] = "undead_walk"
	
	velocity_movement = VelocityMovement.new()

	behaviour = Behaviour.new(
		PathStyle.new(blender, get_rid().get_id()).circle(position, 15).speed(2),
		PathStyle.new(blender, get_rid().get_id()).follow_player(0, 1).speed(2)
	)
	behaviour.update_state(self, player)
	
	vitals = Vitals.new(100, 50)
	
	patterns = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.ROCK, 1),
		],
		[
			5,
			3,
			2,
		]
	)
