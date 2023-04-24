class_name CharacterCollision

static func handle(player: Player, projectile: SpellBody):
	player.impulse += projectile.impulse()
	var dist = clamp(player.impulse.length(), -100, 100)
	player.impulse = player.impulse.normalized() * dist
