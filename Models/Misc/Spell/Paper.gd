class_name SpellPaper
extends WorldItem

var spell: Spell = null
var eaten: bool = false

static func make() -> SpellPaper:
	var result := (preload("res://Models/Misc/Spell/Paper.tscn") as PackedScene).instantiate() as SpellPaper
	result.kind = World.Item.SPELL
	result.height = 2.0
	return result

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup(0, World.Biome.WATER)

func setup(seedling: int, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and spell != null and not (body as Player).world_settings.is_level_editor:
		eaten = true
		if not (body as Player).magic_book.spell_exists(spell.name):
			UIAudioPlayer.grabbing()
			SignalBus.pick_up_world_item_spell.emit(spell, "Spell '%s' picked up" % spell.name)		
		else:
			SignalBus.pick_up_world_item_spell.emit(spell, "Spell '%s' already in Magic Book" % spell.name)
		var tween := create_tween_for_world_item_pick_up(body, 0.25)
		tween.finished.connect(custom_free.bind(self))
		tween.play()

func save_to_dict(dict: Dictionary) -> void:
	super.save_to_dict(dict)
	dict["spell"] = spell.save_dict()

func load_from_dict(dict: Dictionary) -> void:
	super.load_from_dict(dict)
	spell.load_dict(dict.get("spell", {}) as Dictionary)
