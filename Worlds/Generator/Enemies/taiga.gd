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
				var pos3d := Vec3.xz__y(pos, 2)
				var count := pop.fiti(2, 20)
				var radius := pop.fit(5, 25)
				var is_rotating := rng.randf() < pop.fit(0.0, 0.9)
				var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
				if is_rotating:
					var path := Pathway.new().circle(radius, 0, 1)
					var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), [10, 5, 10, 5, 10])
					for i in count:
						var a := float(i) / float(count) * 2.0 * PI
						var path_style := PathStyle.new(0, pos3d).follow_path(path.duplicate()).align_y_to_origin().look_at_player().transform_path(T.rotated(Vector3.UP, a))
						var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						target.focus_point = pos3d + Vec3.y(999999)
						spawner.add_condition(target)
				else:
					var path := Pathway.new().circle(radius, 0, 1)
					var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), [10, 5, 10, 5, 10])
					for p in path.sample_points(count):
						var path_style := PathStyle.new(0, pos3d).follow_path(Pathway.new().wait(5, p)).align_y_to_origin().look_at_player()
						var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						target.focus_point = pos3d + Vec3.y(999999)
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
					var path_style := PathStyle.new(0, pos3d).follow_path(pathway).align_y_to_origin().look_at_player()
					var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
					var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
					target.focus_point = pos3d + Vec3.y(999999)
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
				for p in path.sample_points(count):
					var s := p.length() * 2 * PI * pop.fit(0.05, 1)
					var subpath := Pathway.new().move_to(p).arc_to(p.rotated(Vector3.UP, PI), true, s).arc_to(p, true, s)
					var path_style := PathStyle.new(0, pos3d).follow_path(subpath).align_y_to_origin().look_at_player()
					var config := TargetShape.config_for_gauge(el, spawner, pop.fit(10, 0.3), Vitals.default_ea(0.1, 0), path_style)
					var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
					target.focus_point = pos3d + Vec3.y(999999)
					spawner.add_condition(target)
				
				
		index += 1
		
	from.data = index
	return result
					
