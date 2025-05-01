class_name HFILGen
extends BiomeGenerator

enum HFILStructuresKind {
	NONE,
	MUSHROOM_FIELD,
	ENEMY_MIX, SLIMY,
	MUSH_ENEMIES, SNOT_ENEMIES, HOT_DRAGONS,
	ARTIFACT, NOTE,
}

const HFIL_structure_base := {
	HFILStructuresKind.NONE: 120,
	HFILStructuresKind.MUSHROOM_FIELD: 10,
	HFILStructuresKind.MUSH_ENEMIES: 0.75,
	HFILStructuresKind.SNOT_ENEMIES: 0.5,
	HFILStructuresKind.SLIMY: 0.25,
	HFILStructuresKind.HOT_DRAGONS: 0.175,
	HFILStructuresKind.ENEMY_MIX: 0.125,
	HFILStructuresKind.ARTIFACT: 0.01,
	HFILStructuresKind.NOTE: 0.1,
}
var HFIL_structure := {}

func setup_state(pop: Population) -> void:
	HFIL_structure.merge(HFIL_structure_base, true)
	Rand.normalise_distribution(HFIL_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_us < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), HFIL_structure) as HFILStructuresKind
		
		match struct:
			HFILStructuresKind.NONE:
				pass
			HFILStructuresKind.MUSHROOM_FIELD:
				var pos := area[index]
				var ratio := rng.randf()
				if rng.randf() < 0.5:
					var radius := rng.randf_range(5, 15)
					var point_count := Rand.roll(8, 4, 2, rng, Rand.Accum.AVG)
					var path := Pathway.new().random_points_in_disc(1, 0, radius, 0, point_count)
					path.apply_transform(T.translated(Vec3.xz(pos)))
					spawn_foliage_randomly(pop, point_count, path, {World.Foliage.MUSHROOM_POINTED: 1 - ratio, World.Foliage.MUSHROOM_BULB: ratio}, rng, spacing)
				else:
					var w := rng.randf_range(5, 15)
					var h := rng.randf_range(5, 15)
					var r := rng.randf_range(-PI, PI)
					var point_count := Rand.roll(8, 4, 2, rng, Rand.Accum.AVG)
					var path := Pathway.new().random_points_in_rect(1, w, 0, h, point_count)
					path.apply_transform(T.rotated(Vector3.UP, r).translated(Vec3.xz(pos)))
					spawn_foliage_randomly(pop, point_count, path, {World.Foliage.MUSHROOM_POINTED: 1 - ratio, World.Foliage.MUSHROOM_BULB: ratio}, rng, spacing)
						
			HFILStructuresKind.MUSH_ENEMIES:
				var pos := area[index]
				
				
				var king := pop.spawn_enemy(World.Enemy.MUSHKING, pos, spacing)
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.25, 0.5), 4: pop.fit(0.125, 0.5), 3: pop.fit(0.5, 0.25), 2: pop.fit(0.25, 0.25), 1: pop.fit(0.125, 0)}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				
				var foliage_rates := Rand.normalise_distribution({World.Foliage.MUSHROOM_BULB: rng.randf(), World.Foliage.MUSHROOM_POINTED: rng.randf()})
				for i in rng.randi_range(5, 15):
					var kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_rates) as World.Foliage
					pop.spawn_foliage(kind, pos + Rand.point_in_circle_2d(radius_offset * 1.25 + 5, rng), {"spacing": spacing, "scale": rng.randf_range(2, 5)})
					
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, minion_count, path, {World.Enemy.MUSHROOM: 1, World.Enemy.FUNGI: 1}, rng, spacing)
					
			HFILStructuresKind.SNOT_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.SNOT_BLOB, pos, spacing)
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.25, 0.5), 4: pop.fit(0.125, 0.5), 3: pop.fit(0.5, 0.25), 2: pop.fit(0.25, 0.25), 1: pop.fit(0.125, 0)}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				
				var foliage_rates := Rand.normalise_distribution({World.Foliage.ROCK_EGG: rng.randf(), World.Foliage.ROCK_TALL: rng.randf()})
				for i in rng.randi_range(5, 15):
					var kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_rates) as World.Foliage
					pop.spawn_foliage(kind, pos + Rand.point_in_circle_2d(radius_offset * 1.25 + 5, rng), {"spacing": spacing, "scale": rng.randf_range(2, 5)})
				
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, minion_count, path, {World.Enemy.SNOT_SPIKE: 1}, rng, spacing)
				
			HFILStructuresKind.SLIMY:
				var pos := area[index]
				for i in rng.randi_range(5, 15):
					pop.spawn_foliage(World.Foliage.ROCK_EGG, pos + Rand.point_in_circle_2d(spacing * 2.0, rng), {"spacing": spacing, "scale": rng.randf_range(2, 5)})
				
				var r := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.05, 0.5), 3: pop.fit(0.15, 0.5), 2: pop.fit(0.8, 0.5)}) as int
				var spike_count := rng.randi_range(1, r)
				var path := Pathway.new().random_points_in_disc(1, 0, spacing / 2.0, 0, spike_count, Easing.linear, rng)
				path.apply_transform(T.translated(Vec3.xz(pos)))
				for spike_pos in path.sample_points_xz(spike_count):
					var p := pop.spawn_enemy(World.Enemy.SNOT_SPIKE, spike_pos, spacing)
					if p != null:
						result.append(p)
					var subpath := Pathway.new().random_points_in_disc(1, 0, spacing, 0, rng.randi_range(2,3), Easing.linear, rng)
					subpath.apply_transform(T.translated(Vec3.xz(spike_pos)))
					for sp in subpath.sample_points_xz(rng.randi_range(2,3)):
						var q := pop.spawn_enemy(World.Enemy.SNOT_BLOB, sp, spacing)
						if q != null:
							result.append(q)
					
			HFILStructuresKind.HOT_DRAGONS:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.DRAGON if rng.randf() < pop.fit(0.8, 0.2) else World.Enemy.DRAGOON, pos, spacing)
				if king != null: result.append(king)
				var minion_count := Rand.roll(8, 3, 0, rng, Rand.Accum.AVG)
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().ngon(1, 3, radius_offset, Easing.linear)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, minion_count, path, {World.Enemy.HOT_BLOB: 1}, rng, spacing)
				
				var foliage_count := rng.randi_range(5, 5 + pop.fiti(2, 5))
				var foliage_path := Pathway.new().ngon(1, 3, radius_offset + 5).apply_transform(T.rotated(Vector3.UP, rng.randf() * PI * 2).translated(Vec3.xz(pos)))
				var foliage_ratio := Rand.normalise_distribution({World.Foliage.ROCK_EGG: rng.randf(), World.Foliage.MUSHROOM_BULB: rng.randf(), World.Foliage.MUSHROOM_POINTED: rng.randf()})
				for position in foliage_path.sample_points_xz(foliage_count):
					var kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_ratio) as World.Foliage
					pop.spawn_foliage(kind, position, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
						
			HFILStructuresKind.ENEMY_MIX:
				var pos := area[index]
				var king_count := Rand.entity_from_distribution(rng.randf(), { 4: pop.fit(1, 8), 3: pop.fit(2, 4), 2: pop.fit(4, 2), 1: pop.fit(8, 1)  }) as int
				var radius := rng.randf_range(10.0, 15.0)
				var king_path := Pathway.new().ngon(1, king_count, radius, Easing.linear)
				king_path.apply_transform(T.rotated(Vector3.UP, rng.randf() * 2 * PI).translated(Vec3.xz(pos)))
				var king_ratio := { World.Enemy.SNOT_SPIKE: rng.randf(), World.Enemy.MUSHKING: rng.randf(), World.Enemy.DRAGOON: rng.randf() }
				spawn_enemies_randomly(result, pop, king_count, king_path, king_ratio, rng, spacing)
					
				var minion_layers := Rand.entity_from_distribution(rng.randf(), { 1: pop.fit(20, 5), 2: 10, 3: pop.fit(5, 20)}) as int
				
				for layer in minion_layers:
					var minion_count := king_count + Rand.entity_from_distribution(rng.randf(), { 4: 4, 3: 8, 2: 16, 1: 32  }) as int
					radius += rng.randf_range(10.0, 15.0)
					var minion_path := Pathway.new().random_points_in_disc(1, radius, radius + rng.randf_range(10, 15), 0, 8, Easing.linear, rng)
					minion_path.apply_transform(T.translated(Vec3.xz(pos)))
					var minion_ratio := { World.Enemy.SNOT_BLOB: rng.randf(), World.Enemy.MUSHROOM: rng.randf(), World.Enemy.DRAGON: rng.randf(), World.Enemy.FUNGI: rng.randf() }
					var foliage_ratio := { World.Foliage.MUSHROOM_BULB: rng.randf(), World.Foliage.MUSHROOM_POINTED: rng.randf() }
					spawn_randomly(result, pop, minion_count, minion_path, rng.randf_range(0, 0.5), minion_ratio, foliage_ratio, rng, spacing)
			
			HFILStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10)}) as int:
					1: artifact = Artifact.from_config({
							"NS": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, },
								"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.HEALTH_BUMP: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 1, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(6),
							},
							"WE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, },
								"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.HEALTH_BUMP: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 1, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(6),
							},
						}, pop.player.name_generator, World.Biome.SAVANNAH)
					2: artifact = Artifact.from_config({
							"NS": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, },
								"ef_element": { Artifact.Element.FIRE: 8, Artifact.Element.ROCK: 8, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.HEALTH_BUMP: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 1, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(12),
							},
							"WE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, },
								"ef_element": { Artifact.Element.FIRE: 8, Artifact.Element.ROCK: 8, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.HEALTH_BUMP: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 1, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(12),
							},
						}, pop.player.name_generator, World.Biome.SAVANNAH)
					3: artifact = Artifact.from_config({
							"NS": {
								"is_effect": 0.75,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, },
								"ef_element": { Artifact.Element.FIRE: 6, Artifact.Element.ROCK: 6, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.HEALTH_BUMP: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 1, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(18),
							},
							"WE": {
								"is_effect": 0.25,
								"event": { Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 5 },
								"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5, },
								"ev_element": { Artifact.Element.FIRE: 10, Artifact.Element.ROCK: 10, },
								"ef_element": { Artifact.Element.FIRE: 6, Artifact.Element.ROCK: 6, Artifact.Element.SPELL_VELOCITY: 5, Artifact.Element.HEALTH_BUMP: 3, },
								"pattern": {Artifact.Pattern.TRIANGLE: 1, Artifact.Pattern.SQUARE: 4, },
								"tier": pop.artier(18),
							},
						}, pop.player.name_generator, World.Biome.SAVANNAH)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					result.append(reward)
					
			HFILStructuresKind.NOTE:
				var pos := area[index] as Vector2
				var note_id := GlobalData.game_settings.get_unfound_note(GameSettings.NoteKind.VARIABLE)
				var reward := pop.spawn_world_item(World.Item.NOTE, pos, spacing, {}, note_id.is_empty()) as ScrollNote
				if reward != null:
					reward.note_id = note_id
					result.append(reward)
				
				
		index += 1
		
	from.data = index
	return result
					
