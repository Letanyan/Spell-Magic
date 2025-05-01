class_name DesertGen
extends BiomeGenerator

enum DesertStructuresKind {
	NONE,
	OASIS,
	GHOST, GHOSTLY, HOT_BLOB,
	ARTIFACT, NOTE,
}

const desert_structure_base := {
	DesertStructuresKind.NONE: 120,
	DesertStructuresKind.OASIS: 1,
	DesertStructuresKind.GHOST: 0.75,
	DesertStructuresKind.GHOSTLY: 0.5,
	DesertStructuresKind.HOT_BLOB: 0.25,
	DesertStructuresKind.ARTIFACT: 0.01,
	DesertStructuresKind.NOTE: 0.1,
}

var desert_structure := {}

func setup_state(pop: Population) -> void:
	desert_structure.merge(desert_structure_base, true)
	desert_structure[DesertStructuresKind.GHOST] = pop.fit(0.75, 1.0)
	desert_structure[DesertStructuresKind.GHOSTLY] = pop.fit(0.5, 0.75)
	Rand.normalise_distribution(desert_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_us < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), desert_structure) as DesertStructuresKind
		
		match struct:
			DesertStructuresKind.NONE:
				pass
				
			DesertStructuresKind.OASIS:
				var pos := area[index]
				var count := Rand.roll(9, 2, 0, rng, Rand.Accum.AVG)
				for i in count:
					if rng.randf() < 0.75:
						pop.spawn_foliage(World.Foliage.TREE_PALM, pos + Rand.point_in_circle_2d(10, rng), {"spacing": spacing, "scale": rng.randf_range(2, 5)})
					else:
						pop.spawn_foliage(World.Foliage.ROCK_SQUASHED, pos + Rand.point_in_circle_2d(10, rng), {"spacing": spacing, "scale": rng.randf_range(2, 5)})
						
				
			DesertStructuresKind.GHOST:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.GHOST, pos, spacing)
				if p != null: 
					result.append(p)
				var count := rng.randi_range(5, 5 + pop.fiti(2, 5))
				var radius := rng.randf_range(spacing, spacing * pop.fit(1, 3))
				var path := Pathway.new().ngon(1, 5, radius).apply_transform(T.rotated(Vector3.UP, rng.randf() * 2 * PI).translated(Vec3.xz(pos)))
				var foliage_ratio := Rand.normalise_distribution({World.Foliage.ROCK_SQUASHED: rng.randf(), World.Foliage.TREE_PALM: rng.randf()})
				for position in path.sample_points_xz(count):
					var kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_ratio) as World.Foliage
					pop.spawn_foliage(kind, position, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
				
			DesertStructuresKind.GHOSTLY:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.GHOSTLY, pos, spacing)
				if p != null: 
					result.append(p)
				var row_count := rng.randi_range(1, pop.fiti(2, 7))
				var col_count := rng.randi_range(1, pop.fiti(2, 7))
				var width := rng.randf_range(spacing, spacing * pop.fit(1, 3))
				var height := rng.randf_range(spacing, spacing * pop.fit(1, 3))
				var path := Pathway.new().grid(1, row_count, col_count, width, height).apply_transform(T.rotated(Vector3.UP, rng.randf() * 2 * PI).translated(Vec3.xz(pos)))
				var foliage_ratio := Rand.normalise_distribution({World.Foliage.ROCK_SQUASHED: rng.randf(), World.Foliage.TREE_PALM: rng.randf()})
				for position in path.sample_points_xz(row_count * col_count):
					var kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_ratio) as World.Foliage
					pop.spawn_foliage(kind, position, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
				
			DesertStructuresKind.HOT_BLOB:
				var pos := area[index]
				var count := Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: pop.fit(1, 10)}) as int
				for i in count:
					var p := pop.spawn_enemy(World.Enemy.HOT_BLOB, pos + Rand.point_in_circle_2d(10, rng), spacing)
					if p != null: result.append(p)
					
			DesertStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10)}) as int:
					1: artifact = Artifact.from_config({
							"all": {
								"is_effect": 0.5,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10 },
								"ev_element": { Artifact.Element.FIRE: 10, },
								"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.ATTACK: 2, Artifact.Element.CRIT_DMG: 1 },
								"pattern": {Artifact.Pattern.TRIANGLE: 8, Artifact.Pattern.CIRCLE: 4 },
								"tier": pop.artier(5),
							},
						}, pop.player.name_generator, World.Biome.DESERT)
					2: artifact = Artifact.from_config({
							"all": {
								"is_effect": 0.5,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 10 },
								"ev_element": { Artifact.Element.FIRE: 10, },
								"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.ATTACK: 2, Artifact.Element.CRIT_DMG: 1 },
								"pattern": {Artifact.Pattern.TRIANGLE: 8, Artifact.Pattern.CIRCLE: 4 },
								"tier": pop.artier(10),
							},
						}, pop.player.name_generator, World.Biome.DESERT)
					3: artifact = Artifact.from_config({
							"all": {
								"is_effect": 0.5,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5 },
								"ev_element": { Artifact.Element.FIRE: 10, },
								"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.ATTACK: 2, Artifact.Element.CRIT_DMG: 1 },
								"pattern": {Artifact.Pattern.TRIANGLE: 8, Artifact.Pattern.CIRCLE: 4 },
								"tier": pop.artier(15),
							},
						}, pop.player.name_generator, World.Biome.DESERT)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					result.append(reward)
					
			DesertStructuresKind.NOTE:
				var pos := area[index] as Vector2
				var note_id := GlobalData.game_settings.get_unfound_note(GameSettings.NoteKind.ARTIFACT)
				var reward := pop.spawn_world_item(World.Item.NOTE, pos, spacing, {}, note_id.is_empty()) as ScrollNote
				if reward != null:
					reward.note_id = note_id
					result.append(reward)
				
		index += 1
		
	from.data = index
	return result
					
