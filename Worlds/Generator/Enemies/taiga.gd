class_name TaigaGen
extends BiomeGenerator

enum TaigaStructuresKind {
	NONE,
	HORZ_CIRCLE_PUZZLE, LINE_PUZZLE, ROTATING_PUZZLE
}

const taiga_structure := {
	TaigaStructuresKind.NONE: 120,
	TaigaStructuresKind.HORZ_CIRCLE_PUZZLE: 1,
	TaigaStructuresKind.LINE_PUZZLE: 1,
	TaigaStructuresKind.ROTATING_PUZZLE: 1,
}

func setup_state(pop: Population) -> void:
	Rand.normalise_distribution(taiga_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), taiga_structure) as TaigaStructuresKind
		
		match struct:
			TaigaStructuresKind.NONE:
				pass
				
			TaigaStructuresKind.HORZ_CIRCLE_PUZZLE:
				var pos := area[index]
				var pos3d := Vec3.xz__y(pos, 1)
				var count := pop.fiti(2, 20)
				var radius := pop.fit(5, 25)
				var is_rotating := rng.randf() < pop.fit(0.0, 0.9)
				var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
				var is_horz := rng.randf() < pop.fit(0.0, 0.9)
				var transform: Transform3D
				if is_horz:
					transform = T.I
				else:
					transform = T.rotated(Vector3.FORWARD.rotated(Vector3.UP, rng.randf() * 2 * PI), PI * 0.5).translated(Vec3.y(radius))
				var focus_point: Vector3
				const UP = 0
				const CENTER = 1
				const HORZ = 2
				var kind := Rand.entity_from_distribution(rng.randf(), {UP: 1, CENTER: 1, HORZ: 1}) as int
				if kind == UP:
					focus_point = pos3d + Vec3.y(999_999)
				elif kind == CENTER:
					focus_point = pos3d + transform * Vector3.ZERO
				elif kind == HORZ:
					focus_point = pos3d + Vec3.polar(999_999, 2 * PI * rng.randf())
				if is_rotating:
					var path := Pathway.new().circle(radius, 0, 1)
					var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), [10, 5, 10, 5, 10])
					for i in count:
						var a := float(i) / float(count) * 2.0 * PI
						var path_style := PathStyle.new(0, pos3d).follow_path(path.duplicate()).align_y_to_origin().look_at_player().transform_path([T.rotated(Vector3.UP, a), transform])
						var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						if kind == CENTER:
							target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
						else:
							target.focus_point = focus_point
						spawner.add_condition(target)
				else:
					var path := Pathway.new().circle(radius, 0, 1).apply_transform(transform)
					var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), [10, 5, 10, 5, 10])
					for p in path.sample_points(count):
						var path_style := PathStyle.new(0, pos3d).follow_path(Pathway.new().wait(5, p)).align_y_to_origin().look_at_player()
						var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						if kind == CENTER:
							target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
						else:
							target.focus_point = focus_point
						spawner.add_condition(target)
						
			TaigaStructuresKind.LINE_PUZZLE:
				var pos := area[index]
				var pos3d := Vec3.xz__y(pos, 2)
				var count := pop.fiti(2, 20)
				var distance := pop.fit(1, pop.fit(10, 25))
				var is_shifting := rng.randf() < pop.fit(0.0, 0.9)
				var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
				var angle := rng.randf() * 2 * PI
				var path := Pathway.new().line_to(Vec3.polar(distance, angle), 1)
				var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), [10, 5, 10, 5, 10])
				var is_horz := rng.randf() < pop.fit(0.0, 0.9)
				var transform: Transform3D
				if is_horz:
					transform = T.I
				else:
					transform = T.rotated(Vector3.FORWARD.rotated(Vector3.UP, rng.randf() * 2 * PI), PI * 0.5).translated(Vec3.y(distance * 0.5))
				var focus_point: Vector3
				const UP = 0
				const CENTER = 1
				const HORZ = 2
				var kind := Rand.entity_from_distribution(rng.randf(), {UP: 1, CENTER: 1, HORZ: 1}) as int
				if kind == UP:
					focus_point = pos3d + Vec3.y(999_999)
				elif kind == CENTER:
					focus_point = pos3d + transform * Vector3.ZERO
				elif kind == HORZ:
					focus_point = pos3d + Vec3.polar(999_999, 2 * PI * rng.randf())
				for p in path.sample_points(count):
					var dist := rng.randf_range(pop.fit(5, 10), pop.fit(5, 20))
					var pathway: Pathway
					if is_shifting:
						var start := p - Vec3.polar(dist, angle - PI / 2)
						var end := p + Vec3.polar(dist, angle - PI / 2)
						var speed := rng.randf_range(pop.fit(pop.runs(1), pop.runs(5)), pop.fit(pop.runs(1), pop.runs(10)))
						pathway = Pathway.new().move_to(start).line_to(end, speed).line_to(start, speed)
					else:
						pathway = Pathway.new().wait(5, p)
					var path_style := PathStyle.new(0, pos3d).follow_path(pathway).align_y_to_origin().look_at_player().transform_path(transform)
					var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
					var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
					if kind == CENTER:
						target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
					else:
						target.focus_point = focus_point
					spawner.add_condition(target)
					
			TaigaStructuresKind.ROTATING_PUZZLE:
				var pos := area[index]
				var pos3d := Vec3.xz__y(pos, 2)
				var dist := pop.fit(1, pop.fit(5, 15))
				# TODO: randomize paths generated. Paths like lines, grids, etc.
				var path := Pathway.new() \
					.line_to(Vector3(dist, 0, 0), 1) \
					.line_to(Vector3(dist, 0, dist), 1) \
					.line_to(Vector3(0, 0, dist), 1) \
					.line_to(Vector3(0, 0, 0), 1) \
					.apply_transform(T.translated(Vector3(dist, 0, dist) * -0.5))
				var count := pop.fiti(2, 20)
				var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
				var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), [10, 5, 10, 5, 10])
				var focus_point: Vector3
				const UP = 0
				const CENTER = 1
				const HORZ = 2
				var kind := Rand.entity_from_distribution(rng.randf(), {UP: 1, CENTER: 1, HORZ: 1}) as int
				var facing_tangent := rng.randf() * 2 * PI
				var is_horz := rng.randf() < pop.fit(0.0, 0.9)
				var transform: Transform3D
				if is_horz:
					transform = T.I
				else:
					transform = T.rotated(Vector3.FORWARD.rotated(Vector3.UP, facing_tangent), PI * 0.5).translated(Vec3.y(dist * 0.5))
				if kind == UP:
					focus_point = pos3d + Vec3.y(999_999)
				elif kind == CENTER:
					focus_point = pos3d + transform * Vector3.ZERO
				elif kind == HORZ:
					focus_point = pos3d + Vec3.polar(999_999, facing_tangent)
					
				var make_circle_path := func(pos: Vector3, speed: float) -> Pathway:
					return Pathway.new().move_to(pos).arc_to(pos.rotated(Vector3.UP, PI), true, speed).arc_to(pos, true, speed)
				var make_still_path := func(pos: Vector3, speed: float) -> Pathway:
					return Pathway.new().wait(5, pos)
				# TODO: add more paths
				var moving_path := Rand.entity_from_distribution(rng.randf(), {make_circle_path: pop.fit(0, 10), make_still_path: pop.fit(10, 0)}) as Callable
					
				for p in path.sample_points(count):
					var s := p.length() * 2 * PI * pop.fit(0.05, 1)
					var subpath := moving_path.call(p, s) as Pathway
					var path_style := PathStyle.new(0, pos3d).follow_path(subpath).align_y_to_origin().look_at_player().transform_path(transform)
					var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
					var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
					if kind == CENTER:
						target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
					else:
						target.focus_point = focus_point
					spawner.add_condition(target)
				
				
		index += 1
		
	from.data = index
	return result
					
