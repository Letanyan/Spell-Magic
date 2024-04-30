class_name SpellBuilder

var x: String
var y: String
var z: String
var r: String

func _init() -> void:
	pass
	
func camera3(u: String, v: String, w: String) -> void:
	x += "(u * %)" % u
	y += "(v * %)" % v
	z += "(w * %)" % w
	
func camera(a: String) -> void:
	x += "(u * %)" % a
	y += "(v * %)" % a
	z += "(w * %)" % a
