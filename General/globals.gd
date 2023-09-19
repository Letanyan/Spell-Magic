class_name Globals
extends Node

static func sea_level() -> float:
	return 400.0

static func invf(v: float) -> float:
	if is_zero_approx(v):
		return 1.0 / 0.0000000001
	else:
		return 1.0 / v

class Ref extends RefCounted:
	var data
	
	func _init(value) -> void:
		data = value

static func particle_system_lifetime(p: GPUParticles3D) -> float:
	return p.lifetime * (1.0 + 1.0 - p.explosiveness) + 0.1
