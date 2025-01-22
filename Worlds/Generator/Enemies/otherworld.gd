class_name OtherworldGen
extends BiomeGenerator

enum OtherworldStructuresKind {
	NONE,
	FLOWER_FIELD,
	LONE_PINK, LONE_RED, LONE_DRAGON,
	ARTIFACT, NOTE,
}

var otherworld_structure := {
	OtherworldStructuresKind.NONE: 120,
	OtherworldStructuresKind.FLOWER_FIELD: 10,
	OtherworldStructuresKind.LONE_PINK: 0.5,
	OtherworldStructuresKind.LONE_RED: 0.25,
	OtherworldStructuresKind.LONE_DRAGON: 0.125,
	OtherworldStructuresKind.ARTIFACT: 0.001,
	OtherworldStructuresKind.NOTE: 0.01,
}

func setup_state(pop: Population) -> void:
	Rand.normalise_distribution(otherworld_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), otherworld_structure) as OtherworldStructuresKind
		
		match struct:
			OtherworldStructuresKind.NONE:
				pass
				
			OtherworldStructuresKind.FLOWER_FIELD:
				var pos := area[index]
				var ratio := rng.randf()
				if rng.randf() < 0.5:
					var radius := rng.randf_range(5, 15)
					var point_count := Rand.roll(8, 4, 2, rng, Rand.Accum.AVG)
					var path := Pathway.new().random_points_in_disc(1, 0, radius, 0, point_count)
					path.apply_transform(T.translated(Vec3.xz(pos)))
					spawn_foliage_randomly(pop, point_count, path, {World.Foliage.FLOWERS_SUN2: 1 - ratio, World.Foliage.FLOWERS_SUN3: ratio}, rng, spacing)
				else:
					var w := rng.randf_range(5, 15)
					var h := rng.randf_range(5, 15)
					var r := rng.randf_range(-PI, PI)
					var point_count := Rand.roll(8, 4, 2, rng, Rand.Accum.AVG)
					var path := Pathway.new().random_points_in_rect(1, w, 0, h, point_count)
					path.apply_transform(T.rotated(Vector3.UP, r).translated(Vec3.xz(pos)))
					spawn_foliage_randomly(pop, point_count, path, {World.Foliage.FLOWERS_SUN2: 1 - ratio, World.Foliage.FLOWERS_SUN3: ratio}, rng, spacing)
						
			OtherworldStructuresKind.LONE_PINK:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.PINKMON, pos, spacing)
				if king != null: result.append(king)
				var radius_offset := rng.randf_range(10, 20)
				
				var foliage_rates := Rand.normalise_distribution({World.Foliage.FLOWERS_SUN2: rng.randf(), World.Foliage.FLOWERS_SUN3: rng.randf()})
				for i in rng.randi_range(5, 15):
					var kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_rates) as World.Foliage
					pop.spawn_foliage(kind, pos + Rand.point_in_circle_2d(radius_offset * 1.25 + 5, rng), spacing)
					
					
			OtherworldStructuresKind.LONE_RED:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.REDMON, pos, spacing)
				if king != null: result.append(king)
				var radius_offset := rng.randf_range(10, 20)
				
				var foliage_rates := Rand.normalise_distribution({World.Foliage.ROCK_EGG: rng.randf(), World.Foliage.ROCK_TALL: rng.randf()})
				for i in rng.randi_range(5, 15):
					var kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_rates) as World.Foliage
					pop.spawn_foliage(kind, pos + Rand.point_in_circle_2d(radius_offset * 1.25 + 5, rng), spacing)
				
			OtherworldStructuresKind.LONE_DRAGON:
				var pos := area[index]
				for i in rng.randi_range(5, 15):
					pop.spawn_foliage(World.Foliage.FLOWERS_SUN3, pos + Rand.point_in_circle_2d(spacing * 2.0, rng), spacing)
				
				var r := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.05, 0.5), 3: pop.fit(0.15, 0.5), 2: pop.fit(0.8, 0.5)}) as int
				var spike_count := rng.randi_range(1, r)
				var path := Pathway.new().random_points_in_disc(1, 0, spacing / 2.0, 0, spike_count, Easing.linear, rng)
				path.apply_transform(T.translated(Vec3.xz(pos)))
				for spike_pos in path.sample_points_xz(spike_count):
					var p := pop.spawn_enemy(World.Enemy.DRAGOON, spike_pos, spacing)
					if p != null:
						result.append(p)
						var subpath := Pathway.new().random_points_in_disc(1, 0, spacing, 0, rng.randi_range(2,3), Easing.linear, rng)
						subpath.apply_transform(T.translated(Vec3.xz(spike_pos)))
						for sp in subpath.sample_points_xz(rng.randi_range(2,3)):
							var q := pop.spawn_enemy(World.Enemy.DRAGON, sp, spacing)
							if q != null:
								result.append(q)
			
			OtherworldStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10)}) as int:
					1: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.5, Vector2i(5, 1), Vector4i(2, 0, 6, 0), 
								{ Artifact.Element.FIRE: 5, Artifact.Element.AIR: 5, },
								{ Artifact.Element.FIRE: 5, Artifact.Element.AIR: 5, Artifact.Element.MANA: 2 },
								Vector3i(0, 4, 1),
								pop.artier(4)
							),
						}, pop.player.name_generator, World.Biome.OTHERWORLD)
					2: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.5, Vector2i(5, 3), Vector4i(4, 0, 8, 0), 
								{ Artifact.Element.FIRE: 5, Artifact.Element.AIR: 5, },
								{ Artifact.Element.FIRE: 5, Artifact.Element.AIR: 5, Artifact.Element.MANA: 2 },
								Vector3i(0, 1, 8),
								pop.artier(12)
							),
						}, pop.player.name_generator, World.Biome.OTHERWORLD)
					3: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.5, Vector2i(5, 5), Vector4i(6, 0, 2, 0), 
								{ Artifact.Element.FIRE: 5, Artifact.Element.AIR: 5, },
								{ Artifact.Element.FIRE: 5, Artifact.Element.AIR: 5, Artifact.Element.MANA: 2 },
								Vector3i(0, 8, 4),
								pop.artier(20)
							),
						}, pop.player.name_generator, World.Biome.OTHERWORLD)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					reward.position = pop.get_ground_level(pos)
					result.append(reward)					
			
			OtherworldStructuresKind.NOTE:
				var pos := area[index] as Vector2
				var note_id := GlobalData.game_settings.get_unfound_note(GameSettings.NoteKind.SPELL)
				var reward := pop.spawn_world_item(World.Item.NOTE, pos, spacing, {}, note_id.is_empty()) as ScrollNote
				if reward != null:
					reward.note_id = note_id
					result.append(reward)
				
				
		index += 1
		
	from.data = index
	return result
					
