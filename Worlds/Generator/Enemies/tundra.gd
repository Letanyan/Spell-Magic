class_name TundraGen
extends BiomeGenerator

enum TundraStructuresKind {
	NONE,
	FLAT_ROCK,
	LONE_HEAD, LONE_WALKER, HOARD,
	BLUEMON,
	ARTIFACT,
}

const tundra_structure := {
	TundraStructuresKind.NONE: 120,
	TundraStructuresKind.FLAT_ROCK: 1,
	TundraStructuresKind.LONE_HEAD: 0.5,
	TundraStructuresKind.LONE_WALKER: 0.025,
	TundraStructuresKind.HOARD: 0.0125,
	TundraStructuresKind.BLUEMON: 0.1,
	TundraStructuresKind.ARTIFACT: 0.001,
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
				
			TundraStructuresKind.BLUEMON:
				var pos := area[index]
				var count := Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: pop.fit(1, 10)}) as int
				for i in count:
					var p := pop.spawn_enemy(World.Enemy.BLUEMON, pos + Rand.point_in_circle_2d(10, rng), spacing)
					if p != null: result.append(p)
					
			TundraStructuresKind.HOARD:
				var pos := area[index]
				var king_count := Rand.entity_from_distribution(rng.randf(), {1: pop.fit(15, 5), 2: pop.fit(10, 5), 3: pop.fit(5, 3)}) as int
				for i in king_count:
					var king := pop.spawn_enemy(World.Enemy.WALKER if rng.randf() < pop.fit(0.9, 0.1) else World.Enemy.BLUEMON, pos, spacing)
					if king != null: result.append(king)
				var minion_count := Rand.roll(floori(6 * pop.fit(1, 1.5)), 2, king_count, rng, Rand.Accum.AVG)
				for c in minion_count:
					var minion := pop.spawn_enemy(World.Enemy.WALKER_HEAD, pos + Rand.point_in_disc_2d(10, 20, rng), spacing)
					if minion != null: result.append(minion)
					
			TundraStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10), 4: pop.fit(1, 5)}) as int:
					1: artifact = Artifact.from_config({
							"all": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10, Artifact.Effect.RESISTANCE_FLAT: 10, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, },
								"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.MANA: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 8, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(5),
							},
						}, pop.player.name_generator, World.Biome.TUNDRA)
					2: artifact = Artifact.from_config({
							"all": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 5, Artifact.Effect.RESISTANCE_FLAT: 5, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, },
								"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.MANA: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 6, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(10),
							},
						}, pop.player.name_generator, World.Biome.TUNDRA)
					3: artifact = Artifact.from_config({
							"all": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, Artifact.Effect.RESISTANCE_FLAT: 5, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, },
								"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.MANA: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(15),
							},
						}, pop.player.name_generator, World.Biome.TUNDRA)
					4: artifact = Artifact.from_config({
							"all": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, Artifact.Effect.RESISTANCE_FLAT: 5, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, },
								"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.MANA: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 2, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(20),
							},
						}, pop.player.name_generator, World.Biome.TUNDRA)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					reward.position = pop.get_ground_level(pos)
					result.append(reward)
				
			
				
				
		index += 1
		
	from.data = index
	return result
					
