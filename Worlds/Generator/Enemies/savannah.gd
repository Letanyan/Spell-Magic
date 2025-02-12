class_name SavannahGen
extends BiomeGenerator

enum SavannahStructuresKind {
	NONE,
	TREE_SAFARI, TREE_BRANCHED, 
	PIGEONS, LONE_ORC, ORC_HORDE,
	ARTIFACT, NOTE
}

const savannah_structure_base := {
	SavannahStructuresKind.NONE: 100,
	SavannahStructuresKind.TREE_SAFARI: 10,
	SavannahStructuresKind.TREE_BRANCHED: 2,
	SavannahStructuresKind.PIGEONS: 0.5,
	SavannahStructuresKind.ORC_HORDE: 0.25,
	SavannahStructuresKind.LONE_ORC: 0.1,
	SavannahStructuresKind.ARTIFACT: 0.01,
	SavannahStructuresKind.NOTE: 0.1,
}
var savannah_structure := {}

func setup_state(pop: Population) -> void:
	savannah_structure.merge(savannah_structure_base, true)
	savannah_structure[SavannahStructuresKind.LONE_ORC] = pop.fit(0.01, 0.1)
	Rand.normalise_distribution(savannah_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), savannah_structure) as SavannahStructuresKind
		
		match struct:
			SavannahStructuresKind.NONE:
				pass
				
			SavannahStructuresKind.TREE_SAFARI:
				var pos := area[index]
				pop.spawn_foliage(World.Foliage.TREE_SAFARI if rng.randf() < 0.5 else World.Foliage.TREE_SAFARI2, pos, spacing)
				
			SavannahStructuresKind.TREE_BRANCHED:
				var pos := area[index]
				pop.spawn_foliage(World.Foliage.TREE_BRANCHED, pos, spacing)
				
			SavannahStructuresKind.PIGEONS:
				var pos := area[index]
				pop.spawn_foliage(World.Foliage.TREE_SAFARI, pos, spacing)
				
				var count := rng.randi_range(pop.fiti(1,3), pop.fiti(2,8))
				var min_radius := rng.randf_range(pop.fit(2, 4), pop.fit(3, 6))
				var max_radius := rng.randf_range(pop.fit(2, 4), pop.fit(3, 6)) + min_radius
				var path := Pathway.new().random_points_in_disc(1, min_radius, max_radius, 0, count)
				path.apply_transform(T.translated(Vec3.xz(pos)))
				var probs := {World.Enemy.FLYGEON: pop.fit(2, 10), World.Enemy.BOUGEON: pop.fit(10, 2)}
				spawn_enemies_randomly(result, pop, count, path, probs, rng, spacing)
				
			SavannahStructuresKind.ORC_HORDE:
				var pos := area[index]
				var w := rng.randf_range(10, 30) * pop.fit(1, 2)
				var h := rng.randf_range(10, 30) * pop.fit(1, 2)
				var r := rng.randf_range(-PI, PI)
				var point_count := Rand.roll(6, 4, 2, rng, Rand.Accum.AVG)
				var path := Pathway.new().random_points_in_rect(1, w, 0, h, point_count)
				path.apply_transform(T.rotated(Vector3.UP, r).translated(Vec3.xz(pos)))
				var probs := {World.Enemy.ORC: pop.fit(10, 5), World.Enemy.ORC_DEAD: pop.fit(1, 5)}
				spawn_enemies_randomly(result, pop, point_count, path, probs, rng, spacing)
				
			SavannahStructuresKind.LONE_ORC:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.ORC if rng.randf() < pop.fit(0.8, 0.2) else World.Enemy.ORC_DEAD, pos, spacing)
				if king != null: result.append(king)
				var minion_count := Rand.roll(8, 3, 0, rng, Rand.Accum.AVG)
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().ngon(1, 3, radius_offset, Easing.linear)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				var probs := {World.Enemy.BOUGEON: rng.randf_range(2, pop.fit(4, 10)), World.Enemy.FLYGEON: rng.randf_range(5, pop.fit(3, 10))}
				spawn_enemies_randomly(result, pop, minion_count, path, probs, rng, spacing)
				
			SavannahStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10)}) as int:
					1: artifact = Artifact.from_config({
							"NS": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.SPELL_RADIUS: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(6),
							},
							"WE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.SPELL_RADIUS: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(6),
							},
						}, pop.player.name_generator, World.Biome.SAVANNAH)
					2: artifact = Artifact.from_config({
							"NS": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.FIRE: 8, Artifact.Element.AIR: 8, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.SPELL_RADIUS: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(12),
							},
							"WE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.FIRE: 8, Artifact.Element.AIR: 8, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.SPELL_RADIUS: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(12),
							},
						}, pop.player.name_generator, World.Biome.SAVANNAH)
					3: artifact = Artifact.from_config({
							"NS": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.FIRE: 6, Artifact.Element.AIR: 6, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.SPELL_RADIUS: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(18),
							},
							"WE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.AIR: 10, },
								"ef_element": { Artifact.Element.FIRE: 6, Artifact.Element.AIR: 6, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.SPELL_RADIUS: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(18),
							},
						}, pop.player.name_generator, World.Biome.SAVANNAH)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					result.append(reward)
					
			SavannahStructuresKind.NOTE:
				var pos := area[index] as Vector2
				var note_id := GlobalData.game_settings.get_unfound_note(GameSettings.NoteKind.UPGRADES)
				var reward := pop.spawn_world_item(World.Item.NOTE, pos, spacing, {}, note_id.is_empty()) as ScrollNote
				if reward != null:
					reward.note_id = note_id
					result.append(reward)
				
				
		index += 1
		
	from.data = index
	return result
					
