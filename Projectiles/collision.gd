class_name CharacterCollision

static func handle(player, projectile: SpellBody):
	player.apply_impulse(projectile.impulse())
#	var dist = clamp(player.impulse.length(), -100, 100)
#	player.impulse = player.impulse.normalized() * dist
