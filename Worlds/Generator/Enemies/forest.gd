class_name ForestGen

enum FOREST_STRUCTURES_KIND {
	NONE, 
	TREE_CHRISTMAS, TREE_PYRAMID, 
	HORDE, BAT, MOLE,
	
	DENSE_BATTLEFIELD
}

const FOREST_STRUCTURES: Dictionary = {
	FOREST_STRUCTURES_KIND.TREE_CHRISTMAS: 0.01,
	FOREST_STRUCTURES_KIND.TREE_PYRAMID: 0.25,
#	FOREST_STRUCTURES_KIND.HORDE: 0.001,
#	FOREST_STRUCTURES_KIND.BAT: 0.01,
#	FOREST_STRUCTURES_KIND.MOLE: 0.005,
	FOREST_STRUCTURES_KIND.DENSE_BATTLEFIELD: 0.05,
}

static func populate(pop: Population, state: PhysicsDirectSpaceState3D, area: PackedVector2Array, spacing: float) -> Array:
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
		var struct = Population.random_entity_from_distribution(rng.randf(), FOREST_STRUCTURES) as FOREST_STRUCTURES_KIND
		match struct:
			FOREST_STRUCTURES_KIND.NONE:
				index += 1
			FOREST_STRUCTURES_KIND.TREE_CHRISTMAS:
				index += 1
				var pos = area[index]
				var p = pop.spawn_foliage(World.Foliage.TREE_CHRISTMAS, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.TREE_PYRAMID:
				index += 1
				var pos = area[index]
				var p = pop.spawn_foliage(World.Foliage.TREE_PYRAMID, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.BAT:
				index += 1
				var pos = area[index]
				var p = pop.spawn_enemy(World.Enemy.BAT, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)
			FOREST_STRUCTURES_KIND.MOLE:
				index += 1
				var pos = area[index]
				var p = pop.spawn_enemy(World.Enemy.MOLE, state, pos.x, pos.y, spacing)
				if p != null:
					result.append(p)		
			FOREST_STRUCTURES_KIND.HORDE:
				if area.size() - index < 100:
					index += 1
					continue
				var count = pop.rng.randi_range(4, 16)
				index += 1
				var origin := area[index]
				var x := origin.x
				var y := origin.y
				var v := Vector2(1, 0)
				for i in range(count):
					x += v.x * spacing / 4.0
					y += v.y * spacing / 4.0
					var p := pop.spawn_enemy(World.Enemy.UNDEAD, state, x, y, spacing)
					if p != null:
						result.append(p)
					v = v.rotated(float(i) / count * 2.0 * PI)
					
			FOREST_STRUCTURES_KIND.DENSE_BATTLEFIELD:
				if area.size() - index < 100:
					index += 1
					continue
				var count_tree = pop.rng.randi_range(2, 8)
				var origin := area[index]
				var x := origin.x
				var y := origin.y
				var v := Vector2(1, 0)
				for i in range(count_tree):
					index += 1
					var count = pop.rng.randi_range(4, 18)
					for j in range(count):
						x += v.x * spacing
						y += v.y * spacing
						var p: Node3D
						if pop.rng.randf_range(0, 1.0) < 0.9:
							p = pop.spawn_foliage(World.Foliage.TREE_PYRAMID, state, x, y, spacing)
						else:
							p = pop.spawn_enemy(World.Enemy.UNDEAD, state, x, y, spacing)
						if p != null:
							result.append(p)
						v = v.rotated(float(i) / count * 2.0 * PI)
				
			
	return result
			
