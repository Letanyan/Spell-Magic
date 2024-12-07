class_name TaigaGen
extends BiomeGenerator

enum TaigaStructuresKind {
	NONE,
	HORZ_CIRCLE_PUZZLE, LINE_PUZZLE
}

const taiga_structure := {
	TaigaStructuresKind.NONE: 120,
	TaigaStructuresKind.HORZ_CIRCLE_PUZZLE: 1,
	TaigaStructuresKind.LINE_PUZZLE: 1,
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
				if is_rotating:
					var path := Pathway.new().circle(radius, 0, 1)
					var spawner := ItemSpawner.coins_spawner(pop, pos3d, [10, 5, 10, 5, 10])
					for i in count:
						var a := float(i) / float(count) * 2.0 * PI
						var path_style := PathStyle.new(0, pos3d).follow_path(path).align_y_to_air().look_at_player().transform_path(T.rotated(Vector3.UP, a))
						var config := TargetShape.config_for_gauge(Spell.Element.FIRE, spawner, pop.fit(10, 0.3), Vitals.Stat.new(0, 0, 0.1), path_style)
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						target.focus_point = pos3d + Vec3.y(1000)
						spawner.add_condition(target)
				else:
					var path := Pathway.new().circle(radius, 0, 1)
					var spawner := ItemSpawner.coins_spawner(pop, pos3d, [10, 5, 10, 5, 10])
					for p in path.sample_points(count):
						var path_style := PathStyle.new(0, pos3d).follow_path(Pathway.new().wait(5, p)).align_y_to_air().look_at_player()
						var config := TargetShape.config_for_gauge(Spell.Element.FIRE, spawner, pop.fit(10, 0.3), Vitals.Stat.new(0, 0, 0.1), path_style)
						var target := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config) as TargetShape
						target.focus_point = pos3d + Vec3.y(1000)
						spawner.add_condition(target)
						
			TaigaStructuresKind.LINE_PUZZLE:
				var pos := area[index]
				
				
		index += 1
		
	from.data = index
	return result
					
