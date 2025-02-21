class_name JungleGen
extends BiomeGenerator

enum JungleStructuresKind {
	NONE,
	TREE_BRANCHED, BUSH,
	ELEVATOR, PLATFORM,
	BIRD,
	ARTIFACT, NOTE,
}

const jungle_structure_base := {
	JungleStructuresKind.NONE: 60,
	JungleStructuresKind.TREE_BRANCHED: 5,
	JungleStructuresKind.BUSH: 5,
	JungleStructuresKind.ELEVATOR: 0.75,
	JungleStructuresKind.PLATFORM: 0.25,
	JungleStructuresKind.BIRD: 0.5,
	JungleStructuresKind.ARTIFACT: 0.01,
	JungleStructuresKind.NOTE: 0.1,
}
var jungle_structure := {}

func setup_state(pop: Population) -> void:
	jungle_structure.merge(jungle_structure_base, true)
	jungle_structure[JungleStructuresKind.BIRD] = pop.fit(0.1, 1.0)
	Rand.normalise_distribution(jungle_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_us < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), jungle_structure) as JungleStructuresKind
		
		match struct:
			JungleStructuresKind.NONE:
				pass
			JungleStructuresKind.TREE_BRANCHED:
				var pos := area[index]
				pop.spawn_foliage(World.Foliage.TREE_BRANCHED, pos, spacing)
			JungleStructuresKind.BUSH:
				var pos := area[index]
				var ratio := rng.randf()
				if rng.randf() < 0.5:
					var radius := rng.randf_range(20, 50)
					for i in Rand.roll(10, 4, 2, rng, Rand.Accum.AVG):
						var kind := World.Foliage.BUSH_SPROUT if rng.randf() < ratio else World.Foliage.BUSH_ROUND
						pop.spawn_foliage(kind, pos + Rand.point_in_circle_2d(radius, rng), spacing)
				else:
					var w := rng.randf_range(20, 50)
					var h := rng.randf_range(20, 50)
					var r := rng.randf_range(-PI, PI)
					for i in Rand.roll(10, 4, 2, rng, Rand.Accum.AVG):
						var kind := World.Foliage.BUSH_SPROUT if rng.randf() < ratio else World.Foliage.BUSH_ROUND
						pop.spawn_foliage(kind, pos + Rand.point_in_rect_2d(w, h, r, rng), spacing)
					
			JungleStructuresKind.ELEVATOR:
				var pos := area[index]
				var cursor := Vector3.ZERO
				var direction := Vector3.UP
				var distance := 0.0
				const MAX_DIST := 20.0
				const MIN_DIST := 10.0
				for i in rng.randi_range(1, pop.fiti(1, 5)) * 2:
					distance = rng.randf_range(MIN_DIST, MAX_DIST)
					var dest := cursor + direction * distance
					var pathway: Pathway
					if i % 2 == 0:
						pathway = Pathway.new().from_to_and_back(pop.runs(10) * distance / MIN_DIST, cursor, dest, Easing.linear)
					else:
						pathway = Pathway.new().from_to_and_back(pop.runs(10) * distance / MIN_DIST, dest, cursor, Easing.linear)
					var path := PathStyle.new(0, Vec3.xz__y(pos, 0)).follow_path(pathway).align_y_to_origin().look_at_nothing().origin_is_offset()
					var config := TargetShape.config_for_platform(Spell.Element.ROCK, 5, path)
					var p := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
					if p != null:
						result.append(p)
						var offset_dir: Vector2 = -Vec2.xz(direction)
						while offset_dir.is_equal_approx(-Vec2.xz(direction)):
							offset_dir = Rand.entity_from_distribution(rng.randf(), {Vector2.LEFT: 1, Vector2.RIGHT: 1, Vector2.UP: 1, Vector2.DOWN: 1}) as Vector2
						if cursor.y > 20 and rng.randf() < 0.5:
							var op := pop.spawn_enemy(World.Enemy.BIRD, pos + Vec2.xz(cursor) + Rand.point_in_circle_2d(spacing, rng), spacing) as Bird
							if op != null:
								op.idle_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(cursor.y)))
								op.attack_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(cursor.y)))
								op.position.y += cursor.y
								result.append(op)
						cursor += (direction * distance) + Vec3.xz(offset_dir) * p.bounds
						direction = Rand.entity_from_distribution(rng.randf(), {Vector3.UP: 5, Vector3.DOWN: 1, Vector3.LEFT: 1, Vector3.RIGHT: 1, Vector3.FORWARD: 1, Vector3.BACK: 1}) as Vector3
				var artifact := Artifact.from_config({
					"all": {
						"is_effect": 0.5,
						"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 10 },
						"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5 },
						"ev_element": { Artifact.Element.AIR: 10, },
						"ef_element": { Artifact.Element.AIR: 10, Artifact.Element.RUNNING_SPEED: 2, },
						"pattern": {Artifact.Pattern.TRIANGLE: 8, Artifact.Pattern.CIRCLE: 4},
						"tier": pop.artier(5),
					},
				}, pop.player.name_generator, World.Biome.JUNGLE)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					reward.position = Vec3.xz(pos) + cursor + Vec3.y(pop.get_ground_level(pos).y)
					result.append(reward)
					
			JungleStructuresKind.PLATFORM:
				var pos := area[index]
				var spacing_radius := sqrt(2 * spacing ** 2)
				var platform_size := rng.randf_range(spacing_radius, spacing_radius * 5)
				var points := Population.points_around(pos, platform_size, index, area, exclusion, null)
				if points.size() > sqrt(spacing):
					var minv := Vector2(INF, INF)
					var maxv := Vector2(-INF, -INF)
					for p in points:
						if area[p].x < minv.x: minv.x = area[p].x
						if area[p].y < minv.y: minv.y = area[p].y
						if area[p].x > maxv.x: maxv.x = area[p].x
						if area[p].y > maxv.y: maxv.y = area[p].y
					var center := minv.lerp(maxv, 0.5)
					var platform_scale := sqrt(platform_size ** 2 / 2)
					var h := Vec3.y(rng.randf_range(50, 100) + platform_scale) 
					var pathway := Pathway.new().wait(1.0, h)
					var path := PathStyle.new(0, Vec3.xz(center)).follow_path(pathway).align_y_to_origin().look_at_nothing().origin_is_offset()
					var config := TargetShape.config_for_platform(Spell.Element.ROCK, platform_scale, path, true)
					var platform := pop.spawn_world_item(World.Item.TARGET, center, spacing, config) as TargetShape
					if platform != null:
						platform.caster_target_offset = Vec3.y(1.0)
						platform.should_set_player_on_watch = false
						
						var arc := GlobalData.magic_book.copy_spell("arc")
						arc.configure({"R": "pi/2", "s": "10"}, Spell.Element.AIR, 5, 0, 0.5, 8, 0, 0, 30)
						var arc_pattern := AttackPatterns.new([arc], AttackPatterns.choose_from_distribution(10, [1], 1))
						
						var linear := GlobalData.magic_book.copy_spell("linear-arc")
						linear.configure({"R": "pi", "s": "10", "d": str(platform_scale * 0.5)}, Spell.Element.AIR, 5, 0, 0.5, 8, 0, 0, 30)
						var linear_pattern := AttackPatterns.new([linear], AttackPatterns.choose_from_distribution(10, [1], 1))
						
						platform.attack_sequence = AttackSequence.new(true, [
							AttackSequence.ASLabel.new("choose"),
							AttackSequence.ASCondition.probability_jump({"arc": 5, "line": 2}),
							
							AttackSequence.ASLabel.new("arc"),
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, PI / 4))).align_y_to_origin().origin_is_player(),
							arc_pattern,
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, PI / 4 + PI / 2))).align_y_to_origin().origin_is_player(),
							arc_pattern,
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, PI / 4 + PI))).align_y_to_origin().origin_is_player(),
							arc_pattern,
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, PI / 4 + PI / 2 * 3))).align_y_to_origin().origin_is_player(),
							arc_pattern,
							AttackSequence.ASCondition.jump("choose"),
							
							AttackSequence.ASLabel.new("line"),
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, 0))).align_y_to_origin().origin_is_player(),
							linear_pattern,
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, PI / 2))).align_y_to_origin().origin_is_player(),
							linear_pattern,
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, PI / 2 * 3))).align_y_to_origin().origin_is_player(),
							linear_pattern,
							PathStyle.new(0).follow_path(Pathway.new().wait(0.1, Vec3.polar(platform_scale * 0.5, PI  * 2))).align_y_to_origin().origin_is_player(),
							linear_pattern,
							AttackSequence.ASCondition.jump("choose"),
						])
						result.append(platform)
						var p := pop.spawn_enemy(World.Enemy.BIRDMAN, center, spacing) as Birdman
						if p != null:
							var y_offset := h.y + platform.bounds.y + p.bounds.y
							p.idle_path.path.apply_transform(T.translated(Vec3.y(y_offset)))
							p.attack_path.path.apply_transform(T.translated(Vec3.y(y_offset)))
							p.position.y += y_offset
							result.append(p)
						for q in points: exclusion[q] = true
					
			JungleStructuresKind.BIRD:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.BIRD, pos, spacing)
				if p != null:
					result.append(p)
					
			JungleStructuresKind.ARTIFACT:
				var pos := area[index]
				var artifact: Artifact
				match Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: 5, 3: pop.fit(1, 10)}) as int:
					1: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.25, Vector2i(4, 4), Vector4i(2, 4, 6, 8), 
								{ Artifact.Element.AIR: 5, },
								{ Artifact.Element.AIR: 5, Artifact.Element.HEALTH: 5, Artifact.Element.HEALTH_BUMP: 5 },
								Vector3i(8, 0, 1),
								pop.artier(7)
							),
						}, pop.player.name_generator, World.Biome.JUNGLE)
					2: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.5, Vector2i(5, 3), Vector4i(4, 6, 8, 2), 
								{ Artifact.Element.AIR: 5, },
								{ Artifact.Element.AIR: 5, Artifact.Element.HEALTH: 5, Artifact.Element.HEALTH_BUMP: 5 },
								Vector3i(4, 0, 8),
								pop.artier(13)
							),
						}, pop.player.name_generator, World.Biome.JUNGLE)
					3: artifact = Artifact.from_config({
							"all": Artifact.make_config(
								0.75, Vector2i(6, 2), Vector4i(6, 8, 2, 4), 
								{ Artifact.Element.AIR: 5, },
								{ Artifact.Element.AIR: 5, Artifact.Element.HEALTH: 5, Artifact.Element.HEALTH_BUMP: 5 },
								Vector3i(1, 0, 4),
								pop.artier(19)
							),
						}, pop.player.name_generator, World.Biome.JUNGLE)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					result.append(reward)
					
			JungleStructuresKind.NOTE:
				var pos := area[index] as Vector2
				var note_id := GlobalData.game_settings.get_unfound_note(GameSettings.NoteKind.UPGRADES)
				var reward := pop.spawn_world_item(World.Item.NOTE, pos, spacing, {}, note_id.is_empty()) as ScrollNote
				if reward != null:
					reward.note_id = note_id
					result.append(reward)
				
				
		index += 1
		
	from.data = index
	return result
					
