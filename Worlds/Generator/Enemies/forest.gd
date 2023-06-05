class_name ForestGen

const ENEMY_SPAWN_PROB: Dictionary = {
	
}

const FOLIAGE_SPAWN_PROB: Dictionary = {
	World.Foliage.TREE_ROUND: 0.01,
	World.Foliage.TREE_PYRAMID: 0.24
}

enum FOREST_STRUCTURES_KIND {
	NONE, 
	TREE_CHRISTMAS, TREE_PYRAMID, 
	HORDE, BAT, MOLE
}

const FOREST_STRUCTURES: Dictionary = {
	FOREST_STRUCTURES_KIND.TREE_CHRISTMAS: 0.01,
	FOREST_STRUCTURES_KIND.TREE_PYRAMID: 0.5,
	FOREST_STRUCTURES_KIND.HORDE: 0.01,
	FOREST_STRUCTURES_KIND.BAT: 0.1,
	FOREST_STRUCTURES_KIND.MOLE: 0.05
}

static func populate(pop: Population, state: PhysicsDirectSpaceState3D, area: Array, spacing: float) -> Array:
	var result = []
	while area.size() > 0:
		var struct = pop.random_entity_from_distribution(FOREST_STRUCTURES) as FOREST_STRUCTURES_KIND
		match struct:
			FOREST_STRUCTURES_KIND.NONE:
				area.pop_back()
			FOREST_STRUCTURES_KIND.TREE_CHRISTMAS:
				var pos = area.pop_back()
				var p = pop.spawn_foliage(World.Foliage.TREE_CHRISTMAS, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.TREE_PYRAMID:
				var pos = area.pop_back()
				var p = pop.spawn_foliage(World.Foliage.TREE_PYRAMID, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.BAT:
				var pos = area.pop_back()
				var p = pop.spawn_enemy(World.Enemy.BAT, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.MOLE:
				var pos = area.pop_back()
				var p = pop.spawn_enemy(World.Enemy.MOLE, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)		
			FOREST_STRUCTURES_KIND.HORDE:
				if area.size() < 100:
					area.pop_back()
					continue
				var count = pop.rng.randi_range(4, 16)
				var origin = area.pop_back()
				area.pop_back()
				var x = origin.x
				var y = origin.y
				var v = Vector2(1, 0)
				for i in range(count):
					x += v.x * spacing / 4.0
					y += v.y * spacing / 4.0
					var p = pop.spawn_enemy(World.Enemy.UNDEAD, state, x, y, spacing)
					if p != null:
						result.append(p)
					v.rotated(float(i) / count * 2.0 * PI)
			
	return result
			
