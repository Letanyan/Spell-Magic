class_name CharacterCollision

static func handle(player: Player, projectile: SpellBody):	
	player.impulse += projectile.spell.impulse()
	player.impulse = clamp(player.impulse, Vector3(-10, -10, -10), Vector3(10, 10, 10))
