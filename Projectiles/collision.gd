class_name CharacterCollision

static func handle(player: Player, projectile: SpellBody):	
	player.impulse = projectile.spell.impulse()
