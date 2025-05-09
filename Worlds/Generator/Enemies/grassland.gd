class_name GrasslandGen
extends BiomeGenerator

enum GrasslandStructuresKind {
	NONE,
	TREE_ROUND, TREE_BRANCHED,
	VILLAGE,
	ABANDONED_VILLAGE,
	TARGET_PUZZLE,
	HIVE, SLIMY, FLOCK, PETS, FISH,
	ARTIFACT, NOTE,
	TOWER,
}

const grassland_structure_base := {
	GrasslandStructuresKind.NONE: 120,
	GrasslandStructuresKind.TREE_ROUND: 5,
	GrasslandStructuresKind.TREE_BRANCHED: 0.5,
	GrasslandStructuresKind.HIVE: 0.5,
	GrasslandStructuresKind.FLOCK: 0.5,
	GrasslandStructuresKind.PETS: 0.1,
	GrasslandStructuresKind.FISH: 0.5,
	#GrasslandStructuresKind.TARGET_PUZZLE: 0.01
	GrasslandStructuresKind.ARTIFACT: 0.01,
	GrasslandStructuresKind.NOTE: 0.1,
	GrasslandStructuresKind.TOWER: 2,
}
var grassland_structure := {}

func setup_state(pop: Population) -> void:
	grassland_structure.merge(grassland_structure_base, true)
	grassland_structure[GrasslandStructuresKind.HIVE] = pop.fit(0.1, 0.5)
	grassland_structure[GrasslandStructuresKind.FLOCK] = pop.fit(0.1, 0.5)
	grassland_structure[GrasslandStructuresKind.PETS] = pop.fit(0.05, 0.1)
	grassland_structure[GrasslandStructuresKind.FISH] = pop.fit(0.1, 0.5)
	Rand.normalise_distribution(grassland_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_us < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), grassland_structure) as GrasslandStructuresKind
		match struct:
			GrasslandStructuresKind.NONE:
				pass
			GrasslandStructuresKind.TREE_ROUND:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_ROUND, pos, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
			GrasslandStructuresKind.TREE_BRANCHED:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_BRANCHED, pos, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
				
				
			GrasslandStructuresKind.TOWER:
				var pos := area[index]
				var h := pop.fiti(1, 6)
				var obj := pop.spawn_building(World.Building.TOWER_BASE, pos, spacing, {"scale": 3.0, "height": h, "rot_y": rng.randf_range(0, TAU)})
				if obj != null:
					var pos3 := pop.get_ground_level(pos, 10.0)
					var pathway := Pathway.empty().wait(2)
					var path := PathStyle.new(0, pos3).follow_path(pathway).align_y_to_origin()
					
					var linear := GlobalData.magic_book.copy_spell("linear-arc")
					linear.configure({"R": "pi*"+pop.fits(0.1, 1.0), "s": pop.fits(2,10), "d": "0"}, Spell.Element.FIRE, 10, pop.fit(0, 50), pop.fit(0.1, 0.5), pop.fiti(1,5), 0, 0, pop.fit(10, 30))
					var linear_pattern := AttackPatterns.new([linear], AttackPatterns.choose_from_distribution(4, [1], 1))
					var atk_seq := []
					for i in h:
						atk_seq.append(linear_pattern)
						atk_seq.append(PathStyle.new(0).follow_path(Pathway.new().wait(2, pos3 + Vec3.y(10 * i))).align_y_to_origin())
					var atk := AttackSequence.new(true, atk_seq)
					var config := TargetShape.config_for_empty(Spell.Element.FIRE, 2.0, path, atk)
					var target := pop.spawn_world_item(World.Item.TARGET, pos, 0.0, config) as TargetShape
					if target != null:
						target.position = pos3
						target.player = pop.player
						result.append(target)
						
					var art := pop.spawn_world_item(World.Item.COIN, pos, 0.0, {}, false) as CoinDisc
					if art != null:
						art.amount = 10
						art.position = pop.get_ground_level(pos) + Vec3.y(3.0 * (h + 1.5) * obj.scale.x)
						result.append(art)
						
					result.append(obj)
					
			GrasslandStructuresKind.FISH:
				var pos := area[index]
				
				if rng.randf() < pop.fit(0.8, 0.2):
					var p := pop.spawn_enemy(World.Enemy.FISH, pos, spacing)
					if p != null: result.append(p)
				else:
					var p := pop.spawn_enemy(World.Enemy.FISHMAN, pos, spacing)
					if p != null: result.append(p)
				
					
			GrasslandStructuresKind.HIVE:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {3: pop.fit(0.05, 0.5), 2: pop.fit(0.15, 0.5), 1: pop.fit(0.8, 0.5)}) as int
				var bee_count := Rand.roll(r, pop.fiti(1, 3), 0, rng, Rand.Accum.SUM)
				var bumble_count := Rand.roll(r, pop.fiti(1, 2), 0, rng, Rand.Accum.MAX)
				var art := Artifact.new("", Artifact.Option.make_effect(Artifact.Effect.BOOST_PERCENTAGE, Artifact.Element.FIRE, 2, Artifact.Pattern.TRIANGLE))
				if bee_count <= 0 and bumble_count <= 0:
					continue
					
				var radius := rng.randf_range(15.0, 30.0)
				var tree_path := Pathway.new().circle(radius, 0, 1)
				tree_path.apply_transform(T.rotated(Vector3.UP, TAU * rng.randf()).translated(Vec3.xz(pos)))
				spawn_foliage_randomly(pop, 6, tree_path, {World.Foliage.TREE_BRANCHED: 1}, rng, spacing)
					
				var spawner := pop.spawn_spawner(World.Item.ARTIFACT, pos, art)
				var bee_path := Pathway.new().random_points_in_disc(1, 0, spacing * 2.0, 0, bee_count)
				bee_path.apply_transform(T.rotated(Vector3.UP, rng.randf() * PI).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, bee_count, bee_path, {World.Enemy.BEE: 1}, rng, spacing, spawner)
				var bumble_path := Pathway.new().random_points_in_disc(1, 0, spacing * 2.0, 0, bumble_count)
				bumble_path.apply_transform(T.rotated(Vector3.UP, rng.randf() * PI).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, bumble_count, bumble_path, {World.Enemy.BUMBLE_BEE: 1}, rng, spacing, spawner)
								
			GrasslandStructuresKind.FLOCK:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {10: pop.fit(0.05, 0.5), 5: pop.fit(0.15, 0.5), 3: pop.fit(0.8, 0.5)}) as int
				const circle_points = 3
				var angle_offset := rng.randf_range(0, TAU)
				var radius_offset := rng.randf_range(0, float(r))
				var path := Pathway.new().circle(radius_offset + r * 8, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_foliage_randomly(pop, r * circle_points, path, {World.Foliage.ROCK_TALL: pop.fit(1, 10), World.Foliage.ROCK_EGG: pop.fit(1, 2), World.Foliage.TREE_ROUND: pop.fit(1, 10)}, rng, spacing)
					
				var mini_count := rng.randi_range(1, r)
				var boss := pop.spawn_enemy(World.Enemy.BIRDMAN, pos, spacing)
				if boss != null:
					result.append(boss)
				var mini_path := Pathway.new().circle(r * 4, 0, 1)
				mini_path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, mini_count, mini_path, {World.Enemy.BIRD: 1}, rng, spacing)
						
			GrasslandStructuresKind.PETS:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.05, 0.5), 3: pop.fit(0.15, 0.5), 1: pop.fit(0.8, 0.5)}) as int
				const circle_points = 3
				var angle_offset := rng.randf_range(0, TAU)
				var radius_offset := rng.randf_range(0, float(r))
				var path := Pathway.new().circle(radius_offset + r * 8, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_foliage_randomly(pop, r * circle_points, path, {World.Foliage.ROCK_TALL: pop.fit(1, 10), World.Foliage.ROCK_EGG: pop.fit(1, 2), World.Foliage.TREE_ROUND: pop.fit(1, 10)}, rng, spacing)
					
				var mini_count := rng.randi_range(1, r)
				for i in mini_count:
					var boss := pop.spawn_enemy(World.Enemy.RABBIT, pos + Rand.point_in_circle_2d(r * 4, rng), spacing)
					if boss != null:
						result.append(boss)
					var p := pop.spawn_enemy(World.Enemy.BIRD, pos + Rand.point_in_circle_2d(r * 4, rng), spacing)
					if p != null:
						result.append(p)
						 
			GrasslandStructuresKind.TARGET_PUZZLE:
				var pos := area[index] as Vector2
				
				var pos3 := Vector3.ZERO
				var spawner := pop.spawn_spawner(World.Item.KEY, pos, 2)
				
				for i in pop.fit(3, 8):
					var circle_path := Pathway.new().random_points_in_disc(2, 0, 2, 2, 8)
					var path := PathStyle.new(rng.randi(), pos3).follow_path(circle_path).align_y_to_ground_and_air()
					var config := TargetShape.config_for_damage(Spell.Element.FIRE, spawner, 5, Vitals.Stat.new(100), path)
					var p := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config)
					pos3 = p.position
					path.origin = pos3
					if p != null and spawner != null:
						spawner.add_condition(p)
						result.append(p)				
					
				spawner.position = pos3
				
			GrasslandStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10)}) as int:
					1: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.5, Vector2i(2, 6), Vector4i(2, 4, 6, 8), 
								{ Artifact.Element.AIR: 5, Artifact.Element.WATER: 5, },
								{ Artifact.Element.AIR: 5, Artifact.Element.WATER: 5, Artifact.Element.HEALTH_BUMP: 5 },
								Vector3i(8, 4, 1),
								pop.artier(8)
							),
						}, pop.player.name_generator, World.Biome.GRASSLAND)
					2: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.5, Vector2i(3, 5), Vector4i(4, 6, 8, 2), 
								{ Artifact.Element.AIR: 5, Artifact.Element.WATER: 5, },
								{ Artifact.Element.AIR: 5, Artifact.Element.WATER: 5, Artifact.Element.HEALTH_BUMP: 5 },
								Vector3i(4, 1, 8),
								pop.artier(12)
							),
						}, pop.player.name_generator, World.Biome.GRASSLAND)
					3: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.5, Vector2i(4, 4), Vector4i(6, 8, 2, 4), 
								{ Artifact.Element.AIR: 5, Artifact.Element.WATER: 5, },
								{ Artifact.Element.AIR: 5, Artifact.Element.WATER: 5, Artifact.Element.HEALTH_BUMP: 5 },
								Vector3i(1, 8, 4),
								pop.artier(16)
							),
						}, pop.player.name_generator, World.Biome.GRASSLAND)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					result.append(reward)
				
			GrasslandStructuresKind.NOTE:
				var pos := area[index] as Vector2
				var note_id := GlobalData.game_settings.get_unfound_note()
				var reward := pop.spawn_world_item(World.Item.NOTE, pos, spacing, {}, note_id.is_empty()) as ScrollNote
				if reward != null:
					reward.note_id = note_id
					result.append(reward)
		
		index += 1
					
	from.data = index
	return result
					
