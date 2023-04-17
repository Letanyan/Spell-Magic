class_name CharacterCollision

static func handle(player: Player, projectile: SpellBody):
	player.impulse = projectile.spell.force * 100
	print(projectile.spell.force)
#	player.move_and_collide(projectile.spell.velocity * 100)
	pass
