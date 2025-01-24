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

func artier(cls: int) -> Vector2i:
	var p := cls / 20.0
	var s := 7 * (1 if randf() < p else -1)
	var c := roundi(p * 4) + 1
	return Vector2i(s, c)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#var artifact_drop_probs := {
		#"NS": {
			#"effect": { Artifact.Effect.BOOST_PERCENTAGE: 2, Artifact.Effect.RESISTANCE_PERCENTAGE: 10 },
			#"element": { Artifact.Element.AIR: 10 },
			#"pattern": { Artifact.Pattern.TRIANGLE: 10, Artifact.Pattern.CIRCLE: 2 },
			#"tier": -artier(10),
		#},
		#"WE": {
			#"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 2 },
			#"element": { Artifact.Element.AIR: 10 },
			#"pattern": { Artifact.Pattern.TRIANGLE: 2, Artifact.Pattern.CIRCLE: 10 },
			#"tier": artier(10),
		#}
	#}
	#for i in range(10):
		#var artifact := Artifact.from_config(artifact_drop_probs, null, World.Biome.GRASSLAND)
		#print("------------")
		#print(artifact.left.description(), " For ", artifact.left.duration_description(), ": ", Artifact.Pattern.keys()[artifact.left.pattern])
		#print(artifact.top.description(), " For ", artifact.top.duration_description(), ": ", Artifact.Pattern.keys()[artifact.top.pattern])
		#print(artifact.right.description(), " For ", artifact.right.duration_description(), ": ", Artifact.Pattern.keys()[artifact.right.pattern])
		#print(artifact.bottom.description(), " For ", artifact.bottom.duration_description(), ": ", Artifact.Pattern.keys()[artifact.bottom.pattern])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
