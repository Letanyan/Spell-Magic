class_name TundraGen

enum TUNDRA_STRUCTURES_KIND {
	NONE,
	FLAT_ROCK,
	LONE_HEAD, LONE_WALKER, HOARD,
	RABBIT,
}

const TUNDRA_STRUCTURE = {
	TUNDRA_STRUCTURES_KIND.NONE: 120,
	TUNDRA_STRUCTURES_KIND.FLAT_ROCK: 1,
	TUNDRA_STRUCTURES_KIND.LONE_HEAD: 0.5,
	TUNDRA_STRUCTURES_KIND.LONE_WALKER: 0.025,
	TUNDRA_STRUCTURES_KIND.HOARD: 0.0125,
	TUNDRA_STRUCTURES_KIND.RABBIT: 0.1,
}

static func populate(pop: Population, area: PackedVector2Array, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pop.coord)
	var exclusion := {}
	while index < area.size() - 1:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_distribution(rng.randf(), TUNDRA_STRUCTURE) as TUNDRA_STRUCTURES_KIND
		
		match struct:
			TUNDRA_STRUCTURES_KIND.NONE:
				pass
				
			TUNDRA_STRUCTURES_KIND.FLAT_ROCK:
				var pos := area[index]
				var count := Rand.entity_from_distribution(rng.randf(), { 1: 10, 2: 20, 3: 10 }) as int
				for i in count:
					var p := pop.spawn_foliage(World.Foliage.ROCK_FLATTOP, pos + Rand.point_in_circle_2d(10, rng), spacing)
					if p != null: result.append(p)
				
			TUNDRA_STRUCTURES_KIND.LONE_HEAD:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.WALKER_HEAD, pos, spacing)
				if p != null: result.append(p)
				
			TUNDRA_STRUCTURES_KIND.LONE_WALKER:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.WALKER, pos, spacing)
				if p != null: result.append(p)
				
			TUNDRA_STRUCTURES_KIND.RABBIT:
				var pos := area[index]
				var count := Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: pop.fit(1, 10)}) as int
				for i in count:
					var p := pop.spawn_enemy(World.Enemy.WALKER_HEAD, pos + Rand.point_in_circle_2d(10, rng), spacing)
					if p != null: result.append(p)
					
			TUNDRA_STRUCTURES_KIND.HOARD:
				var pos := area[index]
				var king_count := Rand.entity_from_distribution(rng.randf(), {1: pop.fit(15, 5), 2: pop.fit(10, 5), 3: pop.fit(5, 3)}) as int
				for i in king_count:
					var king := pop.spawn_enemy(World.Enemy.WALKER, pos, spacing) as Mushking
					if king != null: result.append(king)
				var minion_count := Rand.roll(floori(6 * pop.fit(1, 1.5)), 2, king_count, rng, Rand.Accum.AVG)
				for c in minion_count:
					var minion := pop.spawn_enemy(World.Enemy.WALKER_HEAD, pos + Rand.point_in_disc_2d(10, 20, rng), spacing) as Mushroom
					if minion != null:
						result.append(minion)
				
			
				
				
		index += 1
	return result
					
