class_name TaigaGen
extends BiomeGenerator

enum TaigaStructuresKind {
	NONE,
	TREE_PYRAMID, BUSH_TALL, FLOWER_SUN3,
	HORZ_CIRCLE_PUZZLE, LINE_PUZZLE, ROTATING_PUZZLE,
	LONE_GOBLIN, GOBLIN_HORDE,
}

const taiga_structure := {
	TaigaStructuresKind.NONE: 120,
	TaigaStructuresKind.TREE_PYRAMID: 20,
	TaigaStructuresKind.BUSH_TALL: 5,
	TaigaStructuresKind.FLOWER_SUN3: 2,
	TaigaStructuresKind.HORZ_CIRCLE_PUZZLE: 1,
	TaigaStructuresKind.LINE_PUZZLE: 1,
	TaigaStructuresKind.ROTATING_PUZZLE: 1,
	TaigaStructuresKind.LONE_GOBLIN: 0.05,
	TaigaStructuresKind.GOBLIN_HORDE: 0.01,
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
				
			TaigaStructuresKind.TREE_PYRAMID:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_PYRAMID, pos, spacing)
				
			TaigaStructuresKind.BUSH_TALL:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.BUSH_TALL, pos, spacing)
				
			TaigaStructuresKind.FLOWER_SUN3:
				var pos := area[index]
				var ratio := rng.randf()
				if rng.randf() < 0.5:
					var radius := rng.randf_range(20, 50)
					for i in Rand.roll(10, 4, 2, rng, Rand.Accum.AVG):
						var kind := World.Foliage.FLOWERS_SUN3 if rng.randf() < ratio else World.Foliage.GRASS_SHRUB
						pop.spawn_foliage(kind, pos + Rand.point_in_circle_2d(radius, rng), spacing)
				else:
					var w := rng.randf_range(20, 50)
					var h := rng.randf_range(20, 50)
					var r := rng.randf_range(-PI, PI)
					for i in Rand.roll(10, 4, 2, rng, Rand.Accum.AVG):
						var kind := World.Foliage.FLOWERS_SUN3 if rng.randf() < ratio else World.Foliage.GRASS_SHRUB
						pop.spawn_foliage(kind, pos + Rand.point_in_rect_2d(w, h, r, rng), spacing)
				
			TaigaStructuresKind.GOBLIN_HORDE:
				var pos := area[index]
				var w := rng.randf_range(10, 30) * pop.fit(1, 2)
				var h := rng.randf_range(10, 30) * pop.fit(1, 2)
				var r := rng.randf_range(-PI, PI)
				var point_count := Rand.roll(8, 4, 2, rng, Rand.Accum.AVG)
				var path := Pathway.new().random_points_in_rect(1, w, 0, h, point_count)
				path.apply_transform(T.rotated(Vector3.UP, r).translated(Vec3.xz(pos)))
				var probs := {World.Enemy.GOBLIN: pop.fit(10, 5), World.Enemy.GOBLIN_KING: pop.fit(1, 5)}
				spawn_enemies_randomly(result, pop, point_count, path, probs, rng, spacing)
				
			TaigaStructuresKind.LONE_GOBLIN:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.GOBLIN if rng.randf() < pop.fit(0.8, 0.2) else World.Enemy.GOBLIN_KING, pos, spacing) as Enemy
				if king != null: result.append(king)
				
			TaigaStructuresKind.HORZ_CIRCLE_PUZZLE:
				var pos := area[index]
				var pos3d := Vec3.xz__y(pos, 1)
				var count := rng.randi_range(2, pop.fiti(2, 20))
				var size := rng.randf_range(pop.fit(4.0, 1.0), 5.0)
				var radius := rng.randf_range(size, size + pop.fit(1, 5)) * count
				var is_rotating := rng.randf() < pop.fit(0.0, 0.9)
				var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
				var is_horz := rng.randf() < pop.fit(0.0, 0.9)
				var transform: Transform3D
				var coin_cls := 1
				if is_horz:
					transform = T.I
				else:
					coin_cls += 1
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
					coin_cls += 1
					var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), pop.cns(coin_cls))
					for i in count:
						var a := float(i) / float(count) * 2.0 * PI
						var path_style := PathStyle.new(0, pos3d).follow_path(path.duplicate()).align_y_to_origin().look_at_player().transform_path([T.rotated(Vector3.UP, a), transform])
						var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
						config["size"] = size
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						if target != null:
							if kind == CENTER:
								target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
							else:
								target.focus_point = focus_point
							result.append(target)
							spawner.add_condition(target)
				else:
					var path := Pathway.new().circle(radius, 0, 1).apply_transform(transform)
					var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), pop.cns(coin_cls))
					for p in path.sample_points(count):
						var path_style := PathStyle.new(0, pos3d).follow_path(Pathway.new().wait(5, p)).align_y_to_origin().look_at_player()
						var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
						config["size"] = size
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						if target != null:
							if kind == CENTER:
								target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
							else:
								target.focus_point = focus_point
							result.append(target)
							spawner.add_condition(target)
						
			TaigaStructuresKind.LINE_PUZZLE:
				var pos := area[index]
				var pos3d := Vec3.xz__y(pos, 2)
				var count := rng.randi_range(2, pop.fiti(2, 20))
				var size := rng.randf_range(pop.fit(4.0, 1.0), 5.0)
				var distance := rng.randf_range(size, size + pop.fit(1, 5)) * count
				var is_shifting := rng.randf() < pop.fit(0.0, 0.9)
				var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
				var angle := rng.randf() * 2 * PI
				var path := Pathway.new().line_to(Vec3.polar(distance, angle), 1)
				var is_horz := rng.randf() < pop.fit(0.0, 0.9)
				var transform: Transform3D
				var coin_cls := 1
				if is_horz:
					transform = T.I
				else:
					coin_cls += 1
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
				var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), pop.cns(coin_cls))
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
					if target != null:
						if kind == CENTER:
							target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
						else:
							target.focus_point = focus_point
						result.append(target)
						spawner.add_condition(target)
					
			TaigaStructuresKind.ROTATING_PUZZLE:
				var pos := area[index]
				var pos3d := Vec3.xz__y(pos, 2)
				var count := rng.randi_range(2, pop.fiti(2, 20))
				var size := rng.randf_range(pop.fit(4.0, 1.0), 5.0)
				var dist := rng.randf_range(size, size + pop.fit(1, 5)) * count
				
				const NGON = 0
				const GRID = 1
				const LINE = 2
				var shape_kind := Rand.entity_from_distribution(rng.randf(), {NGON: pop.fit(0, 10), GRID: 5, LINE: pop.fit(10, 0)}) as int
				var path: Pathway
				var coin_cls := 1
				if shape_kind == NGON:
					path = Pathway.new().ngon(1, rng.randi_range(3, pop.fiti(4, 8)), dist * 0.5).apply_transform(T.translated(Vector3(dist, 0, dist) * -0.5))
					coin_cls += 2
				elif shape_kind == GRID:
					path = Pathway.new().grid(1, rng.randi_range(2, pop.fiti(2, 8)), rng.randi_range(2, pop.fiti(2, 8)), dist, dist)
					coin_cls += 1
				elif shape_kind == LINE:
					path = Pathway.new().line_to(Vec3.polar(dist, 2 * PI * rng.randf(), 0), 1).apply_transform(T.translated(Vector3(dist, 0, dist) * -0.5))
				var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
				var focus_point: Vector3
				const UP = 0
				const CENTER = 1
				const HORZ = 2
				var layout_kind := Rand.entity_from_distribution(rng.randf(), {UP: 1, CENTER: 1, HORZ: 1}) as int
				var facing_tangent := rng.randf() * 2 * PI
				var is_horz := rng.randf() < pop.fit(0.0, 0.9)
				var transform: Transform3D
				if is_horz:
					transform = T.I
				else:
					transform = T.rotated(Vector3.FORWARD.rotated(Vector3.UP, facing_tangent), PI * 0.5).translated(Vec3.y(dist * 0.5))
				if layout_kind == UP:
					focus_point = pos3d + Vec3.y(999_999)
				elif layout_kind == CENTER:
					focus_point = pos3d + transform * Vector3.ZERO
				elif layout_kind == HORZ:
					focus_point = pos3d + Vec3.polar(999_999, facing_tangent)
					
				var make_circle_path := func(pos: Vector3, speed: float) -> Pathway:
					return Pathway.new().move_to(pos).arc_to(pos.rotated(Vector3.UP, PI), true, speed).arc_to(pos, true, speed)
				var make_still_path := func(pos: Vector3, speed: float) -> Pathway:
					return Pathway.new().wait(5, pos)
				var make_line_path := func(pos: Vector3, speed: float) -> Pathway:
					return Pathway.new().from_to_and_back(speed, pos, Vec3.polar(dist * 0.5 * rng.randf(), 2 * PI * rng.randf(), dist * 0.1 * rng.randf()))
				
				var moving_path := Rand.entity_from_distribution(rng.randf(), {make_circle_path: pop.fit(0, 10), make_still_path: pop.fit(10, 0), make_line_path: 5}) as Callable
					
				if make_circle_path == moving_path:
					coin_cls += 1
				var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), pop.cns(coin_cls))
				for p in path.sample_points(count):
					var s := p.length() * 2 * PI * pop.fit(0.05, 1)
					var subpath := moving_path.call(p, s) as Pathway
					var path_style := PathStyle.new(0, pos3d).follow_path(subpath).align_y_to_origin().look_at_player().transform_path(transform)
					var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
					config["size"] = size
					var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
					if target != null:
						if layout_kind == CENTER:
							target.focus_point = pop.get_ground_level(Vec2.xz(focus_point), focus_point.y)
						else:
							target.focus_point = focus_point
						result.append(target)
						spawner.add_condition(target)
				
				
		index += 1
		
	from.data = index
	return result
					
