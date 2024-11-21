class_name BiomeGenerator

var exclusion: Dictionary = {}

func setup_state(pop: Population) -> void:
	pass

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	from.data = area.size()
	return []

func spawn_enemies_randomly(result: Array[Node3D], pop: Population, count: int, path: Pathway, probs: Dictionary, rng: RandomNumberGenerator, spacing: float, spawner: ItemSpawner = null) -> void:
	Rand.normalise_distribution(probs)
	if spawner == null:
		return
	for p in path.sample_points_xz(count):
		var kind := Rand.entity_from_non_relative_distribution(rng.randf(), probs) as World.Enemy
		var enemy := pop.spawn_enemy(kind, p, spacing) as Enemy
		if enemy != null:
			result.append(enemy)
			spawner.add_condition(enemy)

func spawn_foliage_randomly(pop: Population, count: int, path: Pathway, probs: Dictionary, rng: RandomNumberGenerator, spacing: float) -> void:
	Rand.normalise_distribution(probs)
	for p in path.sample_points_xz(count):
		var kind := Rand.entity_from_non_relative_distribution(rng.randf(), probs) as World.Foliage
		pop.spawn_foliage(kind, p, spacing)
