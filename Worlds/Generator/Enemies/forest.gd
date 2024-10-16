class_name ForestGen

enum FOREST_STRUCTURES_KIND {
	NONE, 
	TREE_CHRISTMAS, TREE_PYRAMID, 
	HORDE, BAT, MOLE,
	
	DENSE_BATTLEFIELD
}

const FOREST_STRUCTURES: Dictionary = {
	FOREST_STRUCTURES_KIND.NONE: 10.0,
	FOREST_STRUCTURES_KIND.TREE_CHRISTMAS: 0.125,
	FOREST_STRUCTURES_KIND.TREE_PYRAMID: 0.25,
	FOREST_STRUCTURES_KIND.HORDE: 0.0001,
	FOREST_STRUCTURES_KIND.BAT: 0.1,
	FOREST_STRUCTURES_KIND.MOLE: 0.005,
	FOREST_STRUCTURES_KIND.DENSE_BATTLEFIELD: 0.0005,
}

static func populate(pop: Population, state: PhysicsDirectSpaceState3D, area: PackedVector2Array, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pop.coord)
	
	# Shuffle area so DENSE_BATTLEFIELD can have more varied shapes
	for i in range(area.size()):
		var j := rng.randi_range(0, area.size() - 1)
		var t := area[i]
		area[i] = area[j]
		area[j] = t
	
	while index < area.size() - 1:
		var struct := Population.random_entity_from_distribution(rng.randf(), FOREST_STRUCTURES) as FOREST_STRUCTURES_KIND
		match struct:
			FOREST_STRUCTURES_KIND.NONE:
				pass
			FOREST_STRUCTURES_KIND.TREE_CHRISTMAS:
				var pos := area[index] as Vector2
				var p := pop.spawn_foliage(World.Foliage.TREE_CHRISTMAS, state, pos, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.TREE_PYRAMID:
				var pos := area[index] as Vector2
				var p := pop.spawn_foliage(World.Foliage.TREE_PYRAMID, state, pos, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.BAT:
				var pos := area[index] as Vector2
				var p := pop.spawn_enemy(World.Enemy.BAT, state, pos, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.MOLE:
				var pos := area[index] as Vector2
				var p := pop.spawn_enemy(World.Enemy.MOLE, state, pos, spacing)
				if p != null:
					result.append(p)		
			FOREST_STRUCTURES_KIND.HORDE:
				if area.size() - index < 100:
					index += 1
					continue
				var count := pop.rng.randi_range(4, 16)
				var pos := area[index]
				var path := Pathway.new().random_points_in_disc(1, 0, spacing / 4.0, 0, count, Easing.linear, rng)
				path.apply_transform(Transform3D.IDENTITY.translated(Vec3.xz(pos)))
				for ppos in path.sample_points_xz(count):
					var p := pop.spawn_enemy(World.Enemy.UNDEAD, state, ppos, spacing)
					if p != null:
						result.append(p)
					
			FOREST_STRUCTURES_KIND.DENSE_BATTLEFIELD:
				if area.size() - index < 100:
					index += 1
					continue
				var count_tree := pop.rng.randi_range(20, 30)
				var pos := area[index]
				var offset := Vector2(1, 0)
				for i in range(count_tree):
					index += 1
					var count := pop.rng.randi_range(5, 10)
					for j in range(count):
						var p: Node3D
						if pop.rng.randf_range(0, 1.0) < 0.95:
							p = pop.spawn_foliage(World.Foliage.TREE_PYRAMID, state, pos + offset, spacing)
						else:
							p = pop.spawn_enemy(World.Enemy.UNDEAD, state, pos + offset, spacing)
						if p != null:
							result.append(p)
						offset = offset.rotated(float(i) / float(count) * 2.0 * PI)
		index += 1
		
	return result
			
