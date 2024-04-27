class_name CombineNoise

@export var noise_a: Noise
@export var noise_b: Noise

enum CombineType { ADD, MULTIPLY  }

@export var combine_type: CombineType


func _init(a: Noise, b: Noise, combine: CombineType) -> void:
	noise_a = a
	noise_b = b
	self.combine_type = combine
	
func get_noise_1d(x: float) -> float:
	if combine_type == CombineType.ADD:
		return noise_a.get_noise_1d(x) + noise_b.get_noise_1d(x)
	elif combine_type == CombineType.MULTIPLY:
		return noise_a.get_noise_1d(x) + noise_b.get_noise_1d(x)
	return NAN
		
func get_noise_2d(x: float, y: float) -> float:
	if combine_type == CombineType.ADD:
		return noise_a.get_noise_2d(x, y) + noise_b.get_noise_2d(x, y)
	elif combine_type == CombineType.MULTIPLY:
		return noise_a.get_noise_2d(x, y) + noise_b.get_noise_2d(x, y)
	return NAN
		
func get_noise_2dv(x: Vector2) -> float:
	if combine_type == CombineType.ADD:
		return noise_a.get_noise_2dv(x) + noise_b.get_noise_2dv(x)
	elif combine_type == CombineType.MULTIPLY:
		return noise_a.get_noise_2dv(x) + noise_b.get_noise_2dv(x)
	return NAN
		
func get_noise_3d(x: float, y: float, z: float) -> float:
	if combine_type == CombineType.ADD:
		return noise_a.get_noise_3d(x, y, z) + noise_b.get_noise_3d(x, y, z)
	elif combine_type == CombineType.MULTIPLY:
		return noise_a.get_noise_3d(x, y, z) + noise_b.get_noise_3d(x, y, z)
	return NAN
		
func get_noise_3dv(x: Vector3) -> float:
	if combine_type == CombineType.ADD:
		return noise_a.get_noise_3dv(x) + noise_b.get_noise_3dv(x)
	elif combine_type == CombineType.MULTIPLY:
		return noise_a.get_noise_3dv(x) + noise_b.get_noise_3dv(x)
	return NAN

func get_image(width: int, height: int, invert: bool = false, in_3d_space: bool = false, normalize: bool = true) -> Image:
	var img := Image.new()
	img.resize(width, height)
	for x in range(width):
		for y in range(height):
			var z := int(get_noise_2d(x, y) * 255)
			img.set_pixel(x, y, Color8(z, z, z))
	return img
