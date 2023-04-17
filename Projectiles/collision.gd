class_name CharacterCollision

static func handle(player: Player, projectile: SpellBody):
	player.impulse = projectile.spell.force * 1000
	print(player.impulse)
#	player.move_and_collide(projectile.spell.velocity * 100)
	pass
