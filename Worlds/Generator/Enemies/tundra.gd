class_name TundraGen
extends BiomeGenerator

enum TundraStructuresKind {
	NONE,
	FLAT_ROCK,
	LONE_HEAD, LONE_WALKER, HOARD,
	RABBIT,
}

const tundra_structure := {
	TundraStructuresKind.NONE: 120,
	TundraStructuresKind.FLAT_ROCK: 1,
	TundraStructuresKind.LONE_HEAD: 0.5,
	TundraStructuresKind.LONE_WALKER: 0.025,
	TundraStructuresKind.HOARD: 0.0125,
	TundraStructuresKind.RABBIT: 0.1,
}

func setup_state(pop: Population) -> void:
	Rand.normalise_distribution(tundra_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), tundra_structure) as TundraStructuresKind
		
		match struct:
			TundraStructuresKind.NONE:
				pass
				
			TundraStructuresKind.FLAT_ROCK:
				var pos := area[index]
				var count := Rand.entity_from_distribution(rng.randf(), { 1: 10, 2: 20, 3: 10 }) as int
				for i in count:
					pop.spawn_foliage(World.Foliage.ROCK_FLATTOP, pos + Rand.point_in_circle_2d(10, rng), spacing)
				
			TundraStructuresKind.LONE_HEAD:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.WALKER_HEAD, pos, spacing)
				if p != null: result.append(p)
				
			TundraStructuresKind.LONE_WALKER:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.WALKER, pos, spacing)
				if p != null: result.append(p)
				
			TundraStructuresKind.RABBIT:
				var pos := area[index]
				var count := Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: pop.fit(1, 10)}) as int
				for i in count:
					var p := pop.spawn_enemy(World.Enemy.WALKER_HEAD, pos + Rand.point_in_circle_2d(10, rng), spacing)
					if p != null: result.append(p)
					
			TundraStructuresKind.HOARD:
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
		
	from.data = index
	return result
					
