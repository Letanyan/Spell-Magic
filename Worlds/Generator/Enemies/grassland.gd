class_name GrasslandGen

const ENEMY_SPAWN_PROB: Dictionary = {
	World.Enemy.UNDEAD: 0.01
}

const FOLIAGE_SPAWN_PROB: Dictionary = {
	World.Foliage.TREE_ROUND: 0.01
}

enum GRASSLAND_STRUCTURES_KIND {
	NONE,
	TREE_ROUND, TREE_BRANCHED,
	HOUSE_SINGLE, HOUSE_DOUBLE,
	UNDEAD
}

const GRASSLAND_STRUCTURE = {
	GRASSLAND_STRUCTURES_KIND.TREE_ROUND: 0.025,
	GRASSLAND_STRUCTURES_KIND.TREE_BRANCHED: 0.025,
	GRASSLAND_STRUCTURES_KIND.HOUSE_SINGLE: 0.005,
	GRASSLAND_STRUCTURES_KIND.HOUSE_DOUBLE: 0.0025,
	GRASSLAND_STRUCTURES_KIND.UNDEAD: 0.01,
}


static func populate(pop: Population, state: PhysicsDirectSpaceState3D, area: PackedVector2Array, spacing: float) -> Array:
	var result: Array[Node3D] = []
	var index := 0
	while index < area.size() - 1:
		var struct := pop.random_entity_from_distribution(GRASSLAND_STRUCTURE) as GRASSLAND_STRUCTURES_KIND
		match struct:
			GRASSLAND_STRUCTURES_KIND.NONE:
				index += 1
			GRASSLAND_STRUCTURES_KIND.TREE_ROUND:
				index += 1
				var pos := area[index]
				var p := pop.spawn_foliage(World.Foliage.TREE_ROUND, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			GRASSLAND_STRUCTURES_KIND.TREE_BRANCHED:
				index += 1
				var pos = area[index]
				var p := pop.spawn_foliage(World.Foliage.TREE_BRANCHED, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			GRASSLAND_STRUCTURES_KIND.UNDEAD:
				index += 1
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.UNDEAD, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			GRASSLAND_STRUCTURES_KIND.HOUSE_SINGLE:
				index += 1
				var pos = area[index]
				var p = pop.spawn_building(World.Building.FANTASY_VALLEY_SINGLE, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			GRASSLAND_STRUCTURES_KIND.HOUSE_DOUBLE:
				index += 1
				var pos = area[index]
				var p = pop.spawn_building(World.Building.FANTASY_VALLEY_DOUBLE, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
					
	return result
					
