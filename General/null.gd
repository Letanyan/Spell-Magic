class_name Ptr
extends RefCounted

var data: Variant

func _init(value: Variant) -> void:
	data = value

static func default(a: Variant, b: Variant) -> Variant:
	if a == null:
		return b
	else:
		return a
