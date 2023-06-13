class_name EntityInfo

enum Liquid {
	NONE, WATER
}

enum Food {
	NONE, CHICKEN, BEEF
}

enum Kind {
	PLAYER, ENEMY, BASE,
	UNDEAD, BAT, MOLE, HUMAN,
	TREE, BUILDING
}

var kind: Kind
var position: Vector3
var liquid: Liquid
var liquid_amount: float
var food: Food
var food_amount: float
var bounds: CollisionShape3D

func _init(type: Kind, pos: Vector3, _liquid := Liquid.NONE, l_amount: float = 0, _food := Food.NONE, f_amount: float = 0):
	kind = type
	position = pos
	liquid = _liquid
	liquid_amount = l_amount
	food = _food
	food_amount = f_amount
	bounds = null
