class_name JungleGen

enum JUNGLE_STRUCTURES_KIND {
	NONE,
	TREE_ROUND, TREE_BRANCHED
}

const JUNGLE_STRUCTURE = {
	JUNGLE_STRUCTURES_KIND.NONE: 60,
	JUNGLE_STRUCTURES_KIND.TREE_BRANCHED: 5,
}

static func scale_entity(scale: float) -> Callable:
	return func(entity: Node3D) -> void:
		if entity is Foliage:
			(entity as Foliage).scale_store = scale

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
				index += 1
			JUNGLE_STRUCTURES_KIND.TREE_BRANCHED:
				index += 1
				var pos := area[index] as Vector2
				var p := pop.spawn_foliage(World.Foliage.TREE_BRANCHED, state, pos, spacing, scale_entity(10.0)) as Foliage
				if p != null:
					result.append(p)
					
	return result
					
