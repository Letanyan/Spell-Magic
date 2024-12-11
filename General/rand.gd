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

static func point_in_disc(inner: float, outer: float, h: float, rng: RandomNumberGenerator = null) -> Vector3:
	var p: Vector3
	if rng == null:
		p = Vector3(randf() * 2.0 - 1.0, h, randf() * 2.0 - 1.0).normalized()
		p = (p * inner).lerp(p * outer, randf())
	else:
		p = Vector3(rng.randf() * 2.0 - 1.0, h, rng.randf() * 2.0 - 1.0).normalized()
		p = (p * inner).lerp(p * outer, rng.randf())
	return p
	
static func point_in_disc_2d(inner: float, outer: float, rng: RandomNumberGenerator = null) -> Vector2:
	var p: Vector2
	if rng == null:
		p = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()
		p = (p * inner).lerp(p * outer, randf())
	else:
		p = Vector2(rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0).normalized()
		p = (p * inner).lerp(p * outer, rng.randf())
	return p

static func point_in_rect(w: float, h: float, d: float, r: float, rng: RandomNumberGenerator = null) -> Vector3:
	var p: Vector3
	if rng == null:
		p = Vector3(randf() * w, randf() * h, randf() * d).rotated(Vector3.UP, r)
	else:
		p = Vector3(rng.randf() * w, rng.randf() * h, rng.randf() * d).rotated(Vector3.UP, r)
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
	
static func point_in_sphere_shell(min_r: float, max_r: float, rng: RandomNumberGenerator = null) -> Vector3:
	var p: Vector3
	var r := max_r - min_r
	if rng == null:
		p = Vector3(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized() * r + Vector3(min_r, min_r, min_r)
	else:
		p = Vector3(rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0).normalized() * r + Vector3(min_r, min_r, min_r)
	return p 
	
static func point_in_hemisphere(r: float, rng: RandomNumberGenerator = null) -> Vector3:
	var p: Vector3
	if rng == null:
		p = Vector3(randf() * 2.0 - 1.0, randf(), randf() * 2.0 - 1.0).normalized() * r
	else:
		p = Vector3(rng.randf() * 2.0 - 1.0, rng.randf(), rng.randf() * 2.0 - 1.0).normalized() * r
	return p 
	
static func point_in_hemisphere_shell(min_r: float, max_r: float, rng: RandomNumberGenerator = null) -> Vector3:
	var p: Vector3
	var r := max_r - min_r
	if rng == null:
		p = Vector3(randf() * 2.0 - 1.0, randf(), randf() * 2.0 - 1.0).normalized() * r + Vector3(min_r, min_r, min_r)
	else:
		p = Vector3(rng.randf() * 2.0 - 1.0, rng.randf(), rng.randf() * 2.0 - 1.0).normalized() * r + Vector3(min_r, min_r, min_r)
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
	return GDNavigator.rand_entity_from_distribution(r, probs, default)
	
# probs: [Variant]float
# probs is a dictionary where each key has its 'value' as a value of being choosen. Sum of all values must equal 1.0
static func entity_from_non_relative_distribution(r: float, probs: Dictionary, default: Variant = 0) -> Variant:
	return GDNavigator.rand_entity_from_non_relative_distribution(r, probs, default)
	
static func normalise_distribution(probs: Dictionary) -> Dictionary:
	GDNavigator.normalise_distribution(probs)
	return probs

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
	
const UINT32_MAX = 4294967295
static func xorshift(seedling: Globals.Ref) -> int:
	var x := seedling.data as int
	x ^= x << 13
	x ^= x >> 17
	x ^= x << 5
	seedling.data = x
	return x
	
static func randf(seedling: Globals.Ref) -> float:
	var value := Rand.xorshift(seedling)
	return value / float(UINT32_MAX)
	
static func randf_range(seedling: Globals.Ref, minimum: float, maximum: float) -> float:
	var value := Rand.randf(seedling)
	return lerpf(minimum, maximum, value)
	
static func randi(seedling: Globals.Ref) -> int:
	return Rand.xorshift(seedling)
	
static func randi_range(seedling: Globals.Ref, minimum: int, maximum: int) -> int:
	var value := Rand.randf(seedling)
	return minimum + roundi((maximum - minimum) * value)
