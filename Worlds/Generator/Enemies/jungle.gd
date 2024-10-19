class_name JungleGen

enum JUNGLE_STRUCTURES_KIND {
	NONE,
	TREE_BRANCHED, BUSH_SPROUT, BUSH_ROUND,
	ELEVATOR, PLATFORM,
	BIRD,
}

const JUNGLE_STRUCTURE = {
	JUNGLE_STRUCTURES_KIND.NONE: 60,
	JUNGLE_STRUCTURES_KIND.TREE_BRANCHED: 5,
	#JUNGLE_STRUCTURES_KIND.BUSH_SPROUT: 10,
	#JUNGLE_STRUCTURES_KIND.BUSH_ROUND: 10,
	JUNGLE_STRUCTURES_KIND.ELEVATOR: 0.75,
	JUNGLE_STRUCTURES_KIND.PLATFORM: 0.9,
	JUNGLE_STRUCTURES_KIND.BIRD: 0.25,
}

static func populate(pop: Population, state: PhysicsDirectSpaceState3D, area: PackedVector2Array, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pop.coord)
	var exclusion := {}
	while index < area.size() - 1:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Population.random_entity_from_distribution(rng.randf(), JUNGLE_STRUCTURE) as JUNGLE_STRUCTURES_KIND
		
		match struct:
			JUNGLE_STRUCTURES_KIND.NONE:
				pass
			JUNGLE_STRUCTURES_KIND.TREE_BRANCHED:
				var pos := area[index]
				var p := pop.spawn_foliage(World.Foliage.TREE_BRANCHED, state, pos, spacing) as Foliage
				if p != null: result.append(p)
			JUNGLE_STRUCTURES_KIND.BUSH_SPROUT:
				var pos := area[index]
				var p := pop.spawn_foliage(World.Foliage.BUSH_SPROUT, state, pos, spacing) as Foliage
				if p != null: result.append(p)
			JUNGLE_STRUCTURES_KIND.BUSH_ROUND:
				var pos := area[index]
				var p := pop.spawn_foliage(World.Foliage.BUSH_ROUND, state, pos, spacing) as Foliage
				if p != null: result.append(p)
					
			JUNGLE_STRUCTURES_KIND.ELEVATOR:
				var pos := area[index]
				var cursor := Vector3.ZERO
				var direction := Vector3.UP
				var distance := 0.0
				var duration := rng.randf_range(10, 20)
				for i in rng.randi_range(1, 5):
					distance = rng.randf_range(10, 20)
					var dest := cursor + direction * distance
					var pathway: Pathway
					if i % 2 == 0:
						pathway = Pathway.new().from_to_and_back(duration * 2, cursor, dest, Easing.in_out_quad)
					else:
						pathway = Pathway.new().from_to_and_back(duration * 2, dest, cursor, Easing.in_out_quad)
					var path := PathStyle.new(0, Vec3.xz(pos)).follow_path(pathway).align_y_to_ground_and_air().look_at_nothing()
					var config := TargetShape.config_for_platform(Spell.Element.ROCK, 5, path)
					var p := pop.spawn_world_item(World.Item.TARGET, state, pos, spacing, config) as TargetShape
					if p != null:
						result.append(p)
						var offset_dir := Population.random_entity_from_distribution(rng.randf(), {Vector2.LEFT: 1, Vector2.RIGHT: 1, Vector2.UP: 1, Vector2.DOWN: 1}) as Vector2
						if cursor.y > 20 and rng.randf() < 0.5:
							var op := pop.spawn_enemy(World.Enemy.BIRD, state, pos + Vec2.xz(cursor) + Globals.rand_point_in_circle_2d(spacing, rng), spacing) as Bird
							if op != null:
								op.idle_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(cursor.y)))
								op.attack_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(cursor.y)))
								op.position.y += cursor.y
								result.append(op)
						cursor += (direction * distance) * 0.95 + Vec3.xz(offset_dir) * p.bounds
						direction = Population.random_entity_from_distribution(rng.randf(), {Vector3.UP: 5, Vector3.DOWN: 1, Vector3.LEFT: 1, Vector3.RIGHT: 1, Vector3.FORWARD: 1, Vector3.BACK: 1}) as Vector3
				var artifact := Artifact.random( \
					pop.player.name_generator.spanish_names.generate(9), \
					0.5,
					{Artifact.Event.RECEIVE: 10, Artifact.Event.DEAL: 5}, \
					{Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5}, \
					{Artifact.Element.AIR: 10, Artifact.Element.RUNNING_SPEED: 2}, \
					Vector2i(1,5), \
					{Artifact.Pattern.TRIANGLE: 8, Artifact.Pattern.CIRCLE: 4}
				)
				var reward := pop.spawn_world_item(World.Item.ARTIFACT, state, pos, spacing, {}) as ArtifactCube
				if reward != null:
					reward.artifact = artifact
					reward.position = Vec3.xz(pos) + cursor + Vec3.y(Navigator.get_world_height(state, pos.x, pos.y))
					result.append(reward)
					
			JUNGLE_STRUCTURES_KIND.PLATFORM:
				var pos := area[index]
				var spacing_radius := sqrt(2 * spacing ** 2)
				var platform_size := rng.randf_range(spacing_radius, spacing_radius * 5)
				var points := Population.points_around(pos, platform_size, index, area, exclusion, null)
				if points.size() > spacing:
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
					var pathway := Pathway.new().wait(1.0).apply_transform(Transform3D.IDENTITY.translated(h))
					var path := PathStyle.new(0, Vec3.xz(center)).follow_path(pathway).align_y_to_ground_air_and_dirt().look_at_nothing()
					var config := TargetShape.config_for_platform(Spell.Element.ROCK, platform_scale, path, true)
					var platform := pop.spawn_world_item(World.Item.TARGET, state, center, spacing, config) as TargetShape
					if platform != null:
						var wh := Navigator.get_world_height(state, center.x, center.y)
						platform.position.y = h.y + wh
						var caster_y := h.y + platform.bounds.y + pop.player.bounds.y * 0.5
						platform.caster_target_position = Vec3.xz(center) + Vec3.y(wh + caster_y)
						var arc := GlobalData.magic_book.copy_spell("arc")
						arc.configure({"R": "pi/2", "s": "10"}, Spell.Element.AIR, 5, 0, 0.5, 8, 0, 0, 0)
						var pattern := AttackPatterns.new([arc], AttackPatterns.choose_from_distribution(10, [1], 1))
						platform.attack_sequence = AttackSequence.new(true, [
							PathStyle.new(0, Vec3.xz(center) + Vec3.y(wh)).follow_path(Pathway.new().wait(0.1, Vector3(platform_scale, caster_y, 0))).align_y_to_origin(),
							pattern,
							PathStyle.new(0, Vec3.xz(center) + Vec3.y(wh)).follow_path(Pathway.new().wait(0.1, Vector3(0, caster_y, platform_scale))).align_y_to_origin(),
							pattern,
							PathStyle.new(0, Vec3.xz(center) + Vec3.y(wh)).follow_path(Pathway.new().wait(0.1, Vector3(-platform_scale, caster_y, 0))).align_y_to_origin(),
							pattern,
							PathStyle.new(0, Vec3.xz(center) + Vec3.y(wh)).follow_path(Pathway.new().wait(0.1, Vector3(0, caster_y, -platform_scale))).align_y_to_origin(),
							pattern,
						])
							
							
						result.append(platform)
						var p := pop.spawn_enemy(World.Enemy.BIRDMAN, state, center, spacing) as Birdman
						if p != null:
							p.idle_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(caster_y)))
							p.attack_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(caster_y)))
							p.position.y += caster_y
							result.append(p)
						for q in points: exclusion[q] = true
					
			JUNGLE_STRUCTURES_KIND.BIRD:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.BIRD, state, pos, spacing)
				if p != null:
					result.append(p)
				
				
		index += 1
	return result
					
