class_name JungleGen

enum JUNGLE_STRUCTURES_KIND {
	NONE,
	TREE_BRANCHED,
	PLATFORM,
	BIRD,
}

const JUNGLE_STRUCTURE = {
	JUNGLE_STRUCTURES_KIND.NONE: 60,
	JUNGLE_STRUCTURES_KIND.TREE_BRANCHED: 5,
	JUNGLE_STRUCTURES_KIND.PLATFORM: 0.75,
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
				if p != null:
					result.append(p)
					
			JUNGLE_STRUCTURES_KIND.PLATFORM:
				var pos := area[index]
				var h := 0.0
				var ah := 0.0
				var base := 0.0
				var d := rng.randf_range(5, 15)
				for i in rng.randi_range(1, 5):
					h = rng.randf_range(10, 20)
					if i % 2 == 0:
						ah = h
						h = 0.0
					else:
						ah = 0.0
					var pathway := Pathway.new().move_to(Vec3.y(base + ah)) \
						.line_to(Vec3.y(base + h), d, Easing.in_out_quad) \
						.line_to(Vec3.y(base + ah), d, Easing.in_out_quad)
					var path := PathStyle.new(0, Vec3.xz(pos)).follow_path(pathway).align_y_to_ground_and_air().look_at_nothing()
					var config := TargetShape.config_for_platform(Spell.Element.ROCK, 5, path)
					var p := pop.spawn_world_item(World.Item.TARGET, state, pos, spacing, config) as TargetShape
					if p != null:
						result.append(p)
						var direction := Population.random_entity_from_distribution(rng.randf(), {Vector2.LEFT: 0.25, Vector2.RIGHT: 0.25, Vector2.UP: 0.25, Vector2.DOWN: 0.25}) as Vector2
						pos += direction * Vec2.xz(p.bounds)
						base += (h + ah) * 0.95
					
			JUNGLE_STRUCTURES_KIND.BIRD:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.BIRD, state, pos, spacing)
				if p != null:
					result.append(p)
				
				
		index += 1	
	return result
					
