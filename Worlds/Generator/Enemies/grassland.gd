class_name GrasslandGen


enum GRASSLAND_STRUCTURES_KIND {
	NONE,
	TREE_ROUND, TREE_BRANCHED,
	VILLAGE,
	UNDEAD
}

const GRASSLAND_STRUCTURE = {
	GRASSLAND_STRUCTURES_KIND.TREE_ROUND: 0.025,
	GRASSLAND_STRUCTURES_KIND.TREE_BRANCHED: 0.025,
	GRASSLAND_STRUCTURES_KIND.VILLAGE: 0.0005,
	GRASSLAND_STRUCTURES_KIND.UNDEAD: 0.01,
}


static func populate(pop: Population, state: PhysicsDirectSpaceState3D, area: PackedVector2Array, spacing: float) -> Array:
	var result: Array[Node3D] = []
	var index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pop.coord)
	var exclusion := {}
	while index < area.size() - 1:
		if exclusion.has(index):
			index += 1
			continue
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
			GRASSLAND_STRUCTURES_KIND.VILLAGE:
				print("village: ", area.size() - index, " < ", 100)
				if area.size() - index < 100:
					index += 1
					continue
				index += 1
				var candidates = Population.points_around(area[index], 100.0, index, area, exclusion)
				var max_limit = rng.randi_range(1, 10)
				for i in range(0, candidates.size()):
					var j = candidates[i]
					var pos = area[j]
					exclusion[j] = true
					var p: Node3D
					if rng.randf() < 0.7:
						p = pop.spawn_building(World.Building.FANTASY_VALLEY_SINGLE, state, pos.x, pos.y, spacing)
					else:
						p = pop.spawn_building(World.Building.FANTASY_VALLEY_DOUBLE, state, pos.x, pos.y, spacing)
					if p != null:
						max_limit -= 1
						result.append(p)
					if max_limit <= 0:
						break
					
	return result
					
