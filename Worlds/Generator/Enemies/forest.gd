class_name ForestGen
extends BiomeGenerator

enum ForestStructuresKind {
	NONE, 
	TREE_CHRISTMAS, TREE_PYRAMID,
	UNDEAD_HORDE, BAT_HORDE, BAT, MOLE, UNDEAD,
	DENSE_BATTLEFIELD,
	ARTIFACT, NOTE,
}

const forest_structures_base := {
	ForestStructuresKind.NONE: 30.0,
	ForestStructuresKind.TREE_CHRISTMAS: 5.0,
	ForestStructuresKind.TREE_PYRAMID: 10.0,
	ForestStructuresKind.UNDEAD_HORDE: 0.05,
	ForestStructuresKind.BAT_HORDE: 0.05,
	ForestStructuresKind.BAT: 0.5,
	ForestStructuresKind.MOLE: 0.05,
	ForestStructuresKind.UNDEAD: 0.1,
	ForestStructuresKind.DENSE_BATTLEFIELD: 0.01,
	ForestStructuresKind.ARTIFACT: 0.01,
	ForestStructuresKind.NOTE: 0.05,
}
var forest_structures := {}

func setup_state(pop: Population) -> void:
	forest_structures.merge(forest_structures_base, true)
	forest_structures[ForestStructuresKind.TREE_PYRAMID] = pop.fit(2.5, 5.0)
	forest_structures[ForestStructuresKind.TREE_CHRISTMAS] = pop.fit(1.25, 2.5)
	Rand.normalise_distribution(forest_structures)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	
	while index < area.size() and pop.current_spawn_duration_us < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), forest_structures) as ForestStructuresKind
		match struct:
			ForestStructuresKind.NONE:
				pass
			ForestStructuresKind.TREE_CHRISTMAS:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_CHRISTMAS, pos, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
			ForestStructuresKind.TREE_PYRAMID:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_PYRAMID, pos, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
			ForestStructuresKind.BAT:
				var pos := area[index] as Vector2
				var elite_prob := pop.fit(0.2, 0.8)
				var p := pop.spawn_enemy(World.Enemy.BATTY if rng.randf() < elite_prob else World.Enemy.BAT, pos, spacing)
				if p != null:
					result.append(p)
			ForestStructuresKind.MOLE:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.MOLE, pos, spacing)
				if p != null:
					result.append(p)
			ForestStructuresKind.UNDEAD:
				var pos := area[index] as Vector2
				var elite_prob := pop.fit(0.2, 0.8)
				var p := pop.spawn_enemy(World.Enemy.UNDEAD if rng.randf() < elite_prob else World.Enemy.UNDEAD_HEAD, pos, spacing)
				if p != null:
					result.append(p)	
			ForestStructuresKind.UNDEAD_HORDE:
				var pos := area[index]
				var count := rng.randi_range(1, pop.fiti(3, 5))
				var path := Pathway.new().random_points_in_disc(1, spacing * 0.5, spacing * 2, 0, count, Easing.linear, rng)
				path.apply_transform(Transform3D.IDENTITY.translated(Vec3.xz(pos)))
				var elite_prob := pop.fit(0.1, 0.5)
				for ppos in path.sample_points_xz(count):
					var p := pop.spawn_enemy(World.Enemy.UNDEAD if rng.randf() < elite_prob else World.Enemy.UNDEAD_HEAD, ppos, spacing)
					if p != null:
						result.append(p)
			ForestStructuresKind.BAT_HORDE:
				var pos := area[index]
				var count := rng.randi_range(2, pop.fiti(4, 8))
				var path := Pathway.new().random_points_in_sphere(1, 0, spacing / 2.0, count, Easing.linear, rng)
				path.apply_transform(T.translated(Vec3.xz(pos)))
				var elite_prob := pop.fit(0.1, 0.9)
				for ppos in path.sample_points_xz(count):
					var p := pop.spawn_enemy(World.Enemy.BATTY if rng.randf() < elite_prob else World.Enemy.BAT, ppos, spacing)
					if p != null:
						result.append(p)
					
			ForestStructuresKind.DENSE_BATTLEFIELD:
				if area.size() - index < 100:
					index += 1
					continue
				var count_tree := pop.rng.randi_range(5, pop.fiti(10, 15))
				var pos := area[index]
				for i in range(count_tree):
					index += 1
					pos = area[index]
					exclusion[index] = true
					var count := pop.rng.randi_range(2, pop.fiti(3, 10))
					var path := Pathway.new().circle(rng.randf_range(spacing, spacing * 2), 0, 1)
					path.apply_transform(T.translated(Vec3.xz(pos)))
					for ppos in path.sample_points_xz(count):
						var p: Node3D
						var tree_prob := pop.fit(0.95, 0.7)
						var enemy_prob := {
							World.Enemy.UNDEAD: rng.randf_range(1, pop.fit(2, 10)), 
							World.Enemy.UNDEAD_HEAD: rng.randf_range(5, pop.fit(7.5, 1)),
							World.Enemy.BATTY: rng.randf_range(2, pop.fit(2.5, 8)),
							World.Enemy.BAT: rng.randf_range(7, pop.fit(6, 2)),
						}
						if rng.randf() < tree_prob:
							pop.spawn_foliage(World.Foliage.TREE_PYRAMID if rng.randf() < 0.5 else World.Foliage.TREE_CHRISTMAS, ppos, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
						else:
							p = pop.spawn_enemy(Rand.entity_from_distribution(rng.randf(), enemy_prob) as World.Enemy, ppos, spacing)
						if p != null:
							result.append(p)
							
			ForestStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10)}) as int:
					1: artifact = Artifact.from_config({
							"NE": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 5, Artifact.Effect.RESISTANCE_FLAT: 10, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.COUNT: 5, Artifact.Element.DURATION: 3, },
								"pattern": {Artifact.Pattern.CIRCLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(5),
							},
							"WS": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 5, Artifact.Effect.RESISTANCE_FLAT: 10, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, Artifact.Element.COUNT: 5, Artifact.Element.DURATION: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(10),
							},
						}, pop.player.name_generator, World.Biome.FOREST)
					2: artifact = Artifact.from_config({
							"NW": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 5, Artifact.Effect.RESISTANCE_PERCENTAGE: 5, Artifact.Effect.RESISTANCE_FLAT: 5, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.WATER: 8, Artifact.Element.AIR: 8, Artifact.Element.COUNT: 5, Artifact.Element.DURATION: 3, },
								"pattern": {Artifact.Pattern.CIRCLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(10),
							},
							"SE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 5, Artifact.Effect.RESISTANCE_PERCENTAGE: 5, Artifact.Effect.RESISTANCE_FLAT: 5, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.WATER: 8, Artifact.Element.AIR: 8, Artifact.Element.COUNT: 5, Artifact.Element.DURATION: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(15),
							},
						}, pop.player.name_generator, World.Biome.FOREST)
					3: artifact = Artifact.from_config({
							"NS": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, Artifact.Effect.RESISTANCE_PERCENTAGE: 10, Artifact.Effect.RESISTANCE_FLAT: 5, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.WATER: 6, Artifact.Element.AIR: 6, Artifact.Element.COUNT: 5, Artifact.Element.DURATION: 3, },
								"pattern": {Artifact.Pattern.CIRCLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(15),
							},
							"WE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, Artifact.Effect.RESISTANCE_PERCENTAGE: 10, Artifact.Effect.RESISTANCE_FLAT: 5, },
								"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.WATER: 6, Artifact.Element.AIR: 6, Artifact.Element.COUNT: 5, Artifact.Element.DURATION: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(20),
							},
						}, pop.player.name_generator, World.Biome.FOREST)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					result.append(reward)
					
			ForestStructuresKind.NOTE:
				var pos := area[index] as Vector2
				var note_id := GlobalData.game_settings.get_unfound_note(GameSettings.NoteKind.FUNC)
				var reward := pop.spawn_world_item(World.Item.NOTE, pos, spacing, {}, note_id.is_empty()) as ScrollNote
				if reward != null:
					reward.note_id = note_id
					result.append(reward)
			
		index += 1
		
	from.data = index
	return result
			
