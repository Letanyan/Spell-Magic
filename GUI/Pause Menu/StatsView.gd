class_name StatsView
extends Control

@onready var health: Label = $"container/Value Health"
@onready var mana: Label = $"container/Value M"
@onready var attack: Label = $"container/Value ATK"
@onready var defence: Label = $"container/Value DEF"
@onready var velocity: Label = $"container/Value Velocity"
@onready var crit_rate: Label = $"container/Value Crit Rate"
@onready var crit_dmg: Label = $"container/Value Crit Dmg"
@onready var radius: Label = $"container/Value r"
@onready var duration: Label = $"container/Value T"
@onready var count: Label = $"container/Value N"
@onready var power: Label = $"container/Value P"
@onready var running_speed: Label = $"container/Value S"
@onready var fireDMG: Label = $"container/Value Fire DMG"
@onready var fireRES: Label = $"container/Value Fire RES"
@onready var waterDMG: Label = $"container/Value Water DMG"
@onready var waterRES: Label = $"container/Value Water RES"
@onready var rockDMG: Label = $"container/Value Rock DMG"
@onready var rockRES: Label = $"container/Value Rock RES"
@onready var airDMG: Label = $"container/Value Air DMG"
@onready var airRES: Label = $"container/Value Air RES"
@onready var iceDMG: Label = $"container/Value Ice DMG"
@onready var iceRES: Label = $"container/Value Ice RES"
@onready var electricDMG: Label = $"container/Value Electric DMG"
@onready var electricRES: Label = $"container/Value Electric RES"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	var text := "-unit(posi)"
	var expr := Expr.new(text)
	var vars := Vars.new()
	vars.set_raw("posi", Vector3(1, 2, 3))
	print(text, " = ", expr.compute(vars, true))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
