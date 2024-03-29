class_name StatsView
extends Control

@onready var health: Label = $"container/Value Health"
@onready var mana: Label = $"container/Value M"
@onready var attack: Label = $"container/Value ATK"
@onready var defence: Label = $"container/Value DEF"
@onready var velocity: Label = $"container/Value Velocity"
@onready var r: Label = $"container/Value r"
@onready var T: Label = $"container/Value T"
@onready var N: Label = $"container/Value N"
@onready var P: Label = $"container/Value P"
@onready var S: Label = $"container/Value S"
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
