class_name Ptr
extends RefCounted

var data

func _init(value):
	data = value

static func default(a, b):
	if a == null:
		return b
	else:
		return a
