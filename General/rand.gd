class_name Rand

enum Accum { SUM, MAX, MIN, AVG }

static func v3_abs(x: float, y: float, z: float, rng: RandomNumberGenerator = null) -> Vector3:
	if rng == null:
		return Vector3(x * randf(), y * randf(), z * randf())
	else:
		return Vector3(x * rng.randf(), y * rng.randf(), z * rng.randf())
	
static func point_in_circle(r: float, h: float, rng: RandomNumberGenerator = null) -> Vector3:
	var p: Vector3
	if rng == null:
		p = Vector3(randf() * 2.0 - 1.0, 0, randf() * 2.0 - 1.0).normalized() * r + Vector3(0, h, 0)
	else:
		p = Vector3(rng.randf() * 2.0 - 1.0, 0, rng.randf() * 2.0 - 1.0).normalized() * r + Vector3(0, h, 0)
	return p 
	
static func point_in_circle_2d(r: float, rng: RandomNumberGenerator = null) -> Vector2:
	var p: Vector2
	if rng == null:
		p = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized() * r
	else:
		p = Vector2(rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0).normalized() * r
	return p
	
static func point_in_rect_2d(w: float, h: float, r: float, rng: RandomNumberGenerator = null) -> Vector2:
	var p: Vector2
	if rng == null:
		p = Vector2(randf() * w, randf() * h).rotated(r)
	else:
		p = Vector2(rng.randf() * w, rng.randf() * h).rotated(r)
	return p
	
static func point_in_sphere(r: float, rng: RandomNumberGenerator = null) -> Vector3:
	var p: Vector3
	if rng == null:
		p = Vector3(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized() * r
	else:
		p = Vector3(rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0).normalized() * r
	return p 
	
static func id(length: int, rng: RandomNumberGenerator = null) -> String:
	var result := ""
	var source := "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
	if rng == null:
		for i in length:
			result += source[rng.randi_range(0, source.length() - 1)]
	else:
		for i in length:
			result += source[randi_range(0, source.length() - 1)]
	return result

# probs: [Variant]float|int
# probs is a dictionary where each key has its 'value' as a value of being choosen relative to other siblings
static func entity_from_distribution(r: float, probs: Dictionary, default: Variant = 0) -> Variant:
	var keys := probs.keys()
	if keys.size() == 0:
		return default
	
	if keys.size() == 1:
		return keys[0]
		
	var sum := 0.0
	for n: float in probs.values():
		sum += n
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i: Variant = keys[n]
		var next_base : float = base + probs[i] / sum
		if base <= r and r < next_base:
			return i
		base = next_base
	
	return default
	
# probs: [Variant]float
# probs is a dictionary where each key has its 'value' as a value of being choosen. Sum of all values must equal 1.0
static func entity_from_non_relative_distribution(r: float, probs: Dictionary, default: Variant = 0) -> Variant:
	var keys := probs.keys()
	if keys.size() == 0:
		return default
	
	if keys.size() == 1:
		return keys[0]
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i: Variant = keys[n]
		var next_base : float = base + probs[i]
		if base <= r and r < next_base:
			return i
		base = next_base
	if base != 1.0:
		push_error("sum of probs must equal 1.0")
	
	return default

static func roll(sides: int, count: int, constant: int, rng: RandomNumberGenerator = null, accum: Accum = Accum.SUM, clamping: Vector2i = Vector2i(1, sides * count)) -> int:
	var result := 0
	if rng == null:
		match accum:
			Accum.SUM, Accum.AVG: for n in count: result += randi_range(1, sides)
			Accum.MAX: for n in count: result = maxi(result, randi_range(1, sides))
			Accum.MIN: for n in count: result = mini(result, randi_range(1, sides))
	else:
		match accum:
			Accum.SUM, Accum.AVG: for n in count: result += rng.randi_range(1, sides)
			Accum.MAX: for n in count: result = maxi(result, rng.randi_range(1, sides))
			Accum.MIN: for n in count: result = mini(result, rng.randi_range(1, sides))
	if accum == Accum.AVG:
		result = roundi(result / float(count))
	return clampi(result + constant, clamping.x, clamping.y)
	
