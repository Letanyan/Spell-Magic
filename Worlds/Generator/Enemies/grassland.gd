class_name GrasslandGen

const ENEMY_SPAWN_PROB: Dictionary = {
	World.Enemy.UNDEAD: 0.01
}

const FOLIAGE_SPAWN_PROB: Dictionary = {
	World.Foliage.TREE_ROUND: 0.01
}

static func populate(pop: Population, world: Node3D, area: Array, spacing: float):
	while area.size() > 0:
		var pos = area.back()
		var p = pop.spawn_random_enemy(ENEMY_SPAWN_PROB, world, pos.x, pos.y, spacing)
		if p == null:
			p = pop.spawn_random_foliage(FOLIAGE_SPAWN_PROB, world, pos.x, pos.y, spacing)
			
		if p != null:
			world.add_child(p)
			
		area.pop_back()
					
