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
							var op := pop.spawn_enemy(World.Enemy.BIRD, state, pos + Vec2.xz(cursor), spacing) as Bird
							if op != null:
								op.idle_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(cursor.y)))
								op.attack_path.path.apply_transform(Transform3D.IDENTITY.translated(Vec3.y(cursor.y)))
								op.position.y += cursor.y
								result.append(op)
						cursor += (direction * distance) * 0.95 + Vec3.xz(offset_dir) * p.bounds
						direction = Population.random_entity_from_distribution(rng.randf(), {Vector3.UP: 5, Vector3.DOWN: 1, Vector3.LEFT: 1, Vector3.RIGHT: 1, Vector3.FORWARD: 1, Vector3.BACK: 1}) as Vector3
					
			JUNGLE_STRUCTURES_KIND.BIRD:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.BIRD, state, pos, spacing)
				if p != null:
					result.append(p)
				
				
		index += 1	
	return result
					
