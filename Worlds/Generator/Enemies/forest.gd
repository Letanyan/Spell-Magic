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
	while size > 10 and not skip:
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
