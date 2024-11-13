class_name BiomeGenerator

var exclusion: Dictionary = {}

func setup_state(pop: Population) -> void:
	pass

func populate(pop: Population, area: Array[Vector2], from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	from.data = area.size()
	return []
