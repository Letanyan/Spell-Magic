class_name GrasslandEnemies

const ENEMY_SPAWN_PROB: Dictionary = {
	World.Enemy.UNDEAD: 0.01
}

static func populate(pop: Population, world: Node3D, area: Dictionary):
	var size = area.size()
	var skip = false
	while size > 10 and not skip:
		if size > 10:
			skip = true # fill empty space by some percentage then call it down 
			for pos in area.keys():
				var p = pop.spawn_random(ENEMY_SPAWN_PROB, world, pos.x, pos.y)
				if p != null:
					world.add_child(p)
					area.erase(p)
					
		if size == area.size():
			skip = true # if no changes exit loop
		else:
			size = area.size()
					
