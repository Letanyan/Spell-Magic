class_name ForestGen

const ENEMY_SPAWN_PROB: Dictionary = {
	
}

const FOLIAGE_SPAWN_PROB: Dictionary = {
	World.Foliage.TREE_ROUND: 0.01,
	World.Foliage.TREE_PYRAMID: 0.24
}

static func populate(pop: Population, world: Node3D, area: Dictionary, spacing: float):
	var size = area.size()
	var skip = false
	var undead_hordes = 0
	while size > 10 and not skip:
		if size / (10.0 * undead_hordes + 1.0) > 100.0:
			var count = pop.rng.randi_range(4, 16)
			undead_hordes += count
			var origin = area.keys()[pop.rng.randi_range(0, area.size())]
			var x = origin.x
			var y = origin.y
			var v = Vector2(1, 0)
			for i in range(count):
				x += v.x * spacing / 4.0
				y += v.y * spacing / 4.0
				var p = pop.spawn_enemy(World.Enemy.UNDEAD, world, x, y, spacing)
				world.add_child(p)
				area.erase(p)
				v.rotated(float(i) / count * 2.0 * PI)
			continue
			
		if size > 10:
			skip = true # fill empty space by some percentage then call it down 
			for pos in area.keys():
				var p = pop.spawn_random_foliage(FOLIAGE_SPAWN_PROB, world, pos.x, pos.y, spacing)
				if p != null:
					world.add_child(p)
					area.erase(p)
					
		if size == area.size():
			skip = true # if no changes exit loop
		else:
			size = area.size()
