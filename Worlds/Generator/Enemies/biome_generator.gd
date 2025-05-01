class_name BiomeGenerator

var exclusion: Dictionary = {}

func setup_state(pop: Population) -> void:
	pass

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	from.data = area.size()
	return []

func spawn_enemies_randomly(result: Array[Node3D], pop: Population, count: int, path: Pathway, probs: Dictionary, rng: RandomNumberGenerator, spacing: float, spawner: ItemSpawner = null) -> void:
	Rand.normalise_distribution(probs)
	for p in path.sample_points_xz(count):
		var kind := Rand.entity_from_non_relative_distribution(rng.randf(), probs) as World.Enemy
		var enemy := pop.spawn_enemy(kind, p, spacing)
		if enemy != null:
			result.append(enemy)
			if spawner != null:
				spawner.add_condition(enemy)

func spawn_foliage_randomly(pop: Population, count: int, path: Pathway, probs: Dictionary, rng: RandomNumberGenerator, spacing: float) -> void:
	Rand.normalise_distribution(probs)
	for p in path.sample_points_xz(count):
		var kind := Rand.entity_from_non_relative_distribution(rng.randf(), probs) as World.Foliage
		pop.spawn_foliage(kind, p, {"spacing": spacing, "scale": rng.randf_range(2, 5)})
		
func spawn_buildings_randomly(result: Array[Node3D], pop: Population, count: int, path: Pathway, probs: Dictionary, rng: RandomNumberGenerator, spacing: float, config: Callable) -> void:
	Rand.normalise_distribution(probs)
	for p in path.sample_points_xz(count):
		var kind := Rand.entity_from_non_relative_distribution(rng.randf(), probs) as World.Building
		var node := pop.spawn_building(kind, p, spacing, config.call(kind) as Dictionary)
		if node != null:
			result.append(node)

func spawn_randomly(result: Array[Node3D], pop: Population, count: int, path: Pathway, enemy_odds: float, enemy_probs: Dictionary, foliage_probs: Dictionary, rng: RandomNumberGenerator, spacing: float, spawner: ItemSpawner = null) -> void:
	Rand.normalise_distribution(foliage_probs)
	Rand.normalise_distribution(enemy_probs)
	for p in path.sample_points_xz(count):
		var foliage_kind := Rand.entity_from_non_relative_distribution(rng.randf(), foliage_probs) as World.Foliage
		var enemy_kind := Rand.entity_from_non_relative_distribution(rng.randf(), enemy_probs) as World.Enemy
		var is_enemy := rng.randf() < enemy_odds
		if is_enemy:
			var enemy := pop.spawn_enemy(enemy_kind, p, spacing)
			if enemy != null:
				result.append(enemy)
				if spawner != null:
					spawner.add_condition(enemy)
		else:
			pop.spawn_foliage(foliage_kind, p, {"spacing": spacing, "scale": rng.randf_range(2, 5)})


static func print_generater_probs() -> void:
	var print_structs := func(structs: Dictionary, keys: Array, label: String) -> void:
		var base := structs.duplicate()
		Rand.normalise_distribution(base)
		print(label, " ------------------------")
		for key: int in base:
			print(keys[key], ": ", base[key])
		print()
	
	print_structs.call(DesertGen.desert_structure_base, DesertGen.DesertStructuresKind.keys(), "Desert")
	print_structs.call(ForestGen.forest_structures_base, ForestGen.ForestStructuresKind.keys(), "Forest")
	print_structs.call(GrasslandGen.grassland_structure_base, GrasslandGen.GrasslandStructuresKind.keys(), "Grassland")
	print_structs.call(HFILGen.HFIL_structure_base, HFILGen.HFILStructuresKind.keys(), "HFIL")
	print_structs.call(JungleGen.jungle_structure_base, JungleGen.JungleStructuresKind.keys(), "Jungle")
	print_structs.call(OtherworldGen.otherworld_structure_base, OtherworldGen.OtherworldStructuresKind.keys(), "Otherworld")
	print_structs.call(SavannahGen.savannah_structure_base, SavannahGen.SavannahStructuresKind.keys(), "Savannah")
	print_structs.call(TaigaGen.taiga_structure_base, TaigaGen.TaigaStructuresKind.keys(), "Taiga")
	print_structs.call(TundraGen.tundra_structure_base, TundraGen.TundraStructuresKind.keys(), "Tundra")
