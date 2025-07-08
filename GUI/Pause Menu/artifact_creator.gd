class_name ArtifactCreator
extends Panel

@onready var name_edit: LineEdit = $MarginContainer/VBoxContainer/Name


@onready var top_effect: Button = $MarginContainer/VBoxContainer/Top/Type/Effect
@onready var top_event: Button = $MarginContainer/VBoxContainer/Top/Type/Event
@onready var top_lvl: SpinBox = $MarginContainer/VBoxContainer/Top/Kind/Level
@onready var top_pattern: OptionButton = $MarginContainer/VBoxContainer/Top/Kind/Pattern
@onready var top_kind: OptionButton = $MarginContainer/VBoxContainer/Top/Value/Kind
@onready var top_option: MenuButton = $MarginContainer/VBoxContainer/Top/Value/Option

@onready var left_effect: Button = $MarginContainer/VBoxContainer/LeftRight/Left/Type/Effect
@onready var left_event: Button = $MarginContainer/VBoxContainer/LeftRight/Left/Type/Event
@onready var left_lvl: SpinBox = $MarginContainer/VBoxContainer/LeftRight/Left/Kind/Level
@onready var left_pattern: OptionButton = $MarginContainer/VBoxContainer/LeftRight/Left/Kind/Pattern
@onready var left_kind: OptionButton = $MarginContainer/VBoxContainer/LeftRight/Left/Value/Kind
@onready var left_option: MenuButton = $MarginContainer/VBoxContainer/LeftRight/Left/Value/Option

@onready var right_effect: Button = $MarginContainer/VBoxContainer/LeftRight/Right/Type/Effect
@onready var right_event: Button = $MarginContainer/VBoxContainer/LeftRight/Right/Type/Event
@onready var right_lvl: SpinBox = $MarginContainer/VBoxContainer/LeftRight/Right/Kind/Level
@onready var right_pattern: OptionButton = $MarginContainer/VBoxContainer/LeftRight/Right/Kind/Pattern
@onready var right_kind: OptionButton = $MarginContainer/VBoxContainer/LeftRight/Right/Value/Kind
@onready var right_option: MenuButton = $MarginContainer/VBoxContainer/LeftRight/Right/Value/Option

@onready var bottom_effect: Button = $MarginContainer/VBoxContainer/Bottom/Type/Effect
@onready var bottom_event: Button = $MarginContainer/VBoxContainer/Bottom/Type/Event
@onready var bottom_lvl: SpinBox = $MarginContainer/VBoxContainer/Bottom/Kind/Level
@onready var bottom_pattern: OptionButton = $MarginContainer/VBoxContainer/Bottom/Kind/Pattern
@onready var bottom_kind: OptionButton = $MarginContainer/VBoxContainer/Bottom/Value/Kind
@onready var bottom_option: MenuButton = $MarginContainer/VBoxContainer/Bottom/Value/Option

signal artifact_created(artifact: Artifact)
signal cancelled

func _ready() -> void:
	top_effect.pressed.connect(press_effect(top_effect, top_event, top_lvl, top_kind, top_option))
	top_event.pressed.connect(press_event(top_event, top_effect, top_lvl, top_kind, top_option))
	top_option.get_popup().index_pressed.connect(option_index_pressed(top_option))
	
	left_effect.pressed.connect(press_effect(left_effect, left_event, left_lvl, left_kind, left_option))
	left_event.pressed.connect(press_event(left_event, left_effect, left_lvl, left_kind, left_option))
	left_option.get_popup().index_pressed.connect(option_index_pressed(left_option))
	
	right_effect.pressed.connect(press_effect(right_effect, right_event, right_lvl, right_kind, right_option))
	right_event.pressed.connect(press_event(right_event, right_effect, right_lvl, right_kind, right_option))
	right_option.get_popup().index_pressed.connect(option_index_pressed(right_option))
	
	bottom_effect.pressed.connect(press_effect(bottom_effect, bottom_event, bottom_lvl, bottom_kind, bottom_option))
	bottom_event.pressed.connect(press_event(bottom_event, bottom_effect, bottom_lvl, bottom_kind, bottom_option))
	bottom_option.get_popup().index_pressed.connect(option_index_pressed(bottom_option))
	
func press_event(this: Button, other: Button, level: SpinBox, kind: OptionButton, option: MenuButton) -> Callable:
	return func() -> void:
		this.set_pressed_no_signal(true)
		other.set_pressed_no_signal(false)
		
		level.min_value = 1
		level.max_value = 10
		level.value = 1
		
		option.icon = null
		option.modulate = Color.WHITE
		option.text = "Any"
		
		kind.clear()
		kind.add_icon_item(preload("res://GUI/Images/take.svg") as Texture2D, "Receive")
		kind.add_icon_item(preload("res://GUI/Images/deal.svg") as Texture2D, "Deal")
		
		var menu := option.get_popup()
		menu.clear()
		menu.add_radio_check_item("Any")
		menu.add_icon_radio_check_item(preload("res://GUI/Images/fire.svg") as Texture2D, "Fire")
		menu.set_item_icon_modulate(menu.item_count - 1, Spell.color_from_element(Spell.Element.FIRE))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/rock.svg") as Texture2D, "Rock")
		menu.set_item_icon_modulate(menu.item_count - 1, Spell.color_from_element(Spell.Element.ROCK))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/electric.svg") as Texture2D, "Electric")
		menu.set_item_icon_modulate(menu.item_count - 1, Spell.color_from_element(Spell.Element.ELECTRIC))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/water.svg") as Texture2D, "Water")
		menu.set_item_icon_modulate(menu.item_count - 1, Spell.color_from_element(Spell.Element.WATER))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/wind.svg") as Texture2D, "Wind")
		menu.set_item_icon_modulate(menu.item_count - 1, Spell.color_from_element(Spell.Element.AIR))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/ice.svg") as Texture2D, "Ice")
		menu.set_item_icon_modulate(menu.item_count - 1, Spell.color_from_element(Spell.Element.ICE))
		
func press_effect(this: Button, other: Button, level: SpinBox, kind: OptionButton, option: MenuButton) -> Callable:
	return func() -> void:
		this.set_pressed_no_signal(true)
		other.set_pressed_no_signal(false)
		
		level.min_value = -10
		level.max_value = 10
		level.value = 1
		
		option.icon = null
		option.modulate = Color.WHITE
		option.text = "Any"
		
		kind.clear()
		kind.add_icon_item(preload("res://GUI/Images/sword.svg") as Texture2D, "DMG %")
		kind.add_icon_item(preload("res://GUI/Images/sword.svg") as Texture2D, "DMG")
		kind.add_icon_item(preload("res://GUI/Images/shield.svg") as Texture2D, "RES %")
		kind.add_icon_item(preload("res://GUI/Images/shield.svg") as Texture2D, "RES")
		
		var menu := option.get_popup()
		menu.clear()
		menu.add_radio_check_item("Any")
		menu.add_icon_radio_check_item(preload("res://GUI/Images/fire.svg") as Texture2D, "Fire")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.FIRE))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/rock.svg") as Texture2D, "Rock")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.ROCK))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/electric.svg") as Texture2D, "Electric")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.ELECTRIC))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/water.svg") as Texture2D, "Water")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.WATER))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/wind.svg") as Texture2D, "Wind")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.AIR))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/ice.svg") as Texture2D, "Ice")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.ICE))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/health.svg") as Texture2D, "Health")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.HEALTH))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/mana.svg") as Texture2D, "Mana")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.MANA))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/sword.svg") as Texture2D, "Attack")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.ATTACK))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/shield.svg") as Texture2D, "Defence")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.DEFENCE))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/cubes.svg") as Texture2D, "Crit_Rate")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.CRIT_RATE))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/hypersonic.svg") as Texture2D, "Crit_Dmg")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.CRIT_DMG))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/velocity.svg") as Texture2D, "v")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.SPELL_VELOCITY))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/time.svg") as Texture2D, "T")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.DURATION))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/running.svg") as Texture2D, "Movement_Speed")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.RUNNING_SPEED))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/radius.svg") as Texture2D, "r")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.SPELL_RADIUS))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/count.svg") as Texture2D, "N")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.COUNT))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/power.svg") as Texture2D, "P")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.POWER))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/health-outline.svg") as Texture2D, "Max_Health")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.HEALTH_BUMP))
		menu.add_icon_radio_check_item(preload("res://GUI/Images/mana-outline.svg") as Texture2D, "Max_Mana")
		menu.set_item_icon_modulate(menu.item_count - 1, Artifact.color_for_element(Artifact.Element.MANA_BUMP))

func option_index_pressed(button: MenuButton) -> Callable:
	return func (index: int) -> void:
		var menu := button.get_popup()
		for i in menu.item_count:
			if i == index:
				menu.set_item_checked(i, true)
				button.text = menu.get_item_text(i)
				button.modulate = menu.get_item_icon_modulate(i)
				button.icon = menu.get_item_icon(i) 
			else:
				menu.set_item_checked(i, false) 
				

func _on_cancel_pressed() -> void:
	cancelled.emit()
	
func get_index_of_selected_radio(button: MenuButton) -> int:
	var menu := button.get_popup()
	for index in menu.item_count:
		if menu.is_item_checked(index):
			return index
	return -1
	
func _on_create_pressed() -> void:
	var top: Artifact.Option
	if top_effect.button_pressed:
		top = Artifact.Option.make_effect(top_kind.selected + 1 as Artifact.Effect, get_index_of_selected_radio(top_option), int(top_lvl.value), top_pattern.selected as Artifact.Pattern)
	else:
		top = Artifact.Option.make_event(top_kind.selected + 1 as Artifact.Event, get_index_of_selected_radio(top_option), int(top_lvl.value), top_pattern.selected as Artifact.Pattern)
		
	var left: Artifact.Option
	if left_effect.button_pressed:
		left = Artifact.Option.make_effect(left_kind.selected + 1 as Artifact.Effect, get_index_of_selected_radio(left_option), int(left_lvl.value), left_pattern.selected as Artifact.Pattern)
	else:
		left = Artifact.Option.make_event(left_kind.selected + 1 as Artifact.Event, get_index_of_selected_radio(left_option), int(left_lvl.value), left_pattern.selected as Artifact.Pattern)	
		
	var right: Artifact.Option
	if right_effect.button_pressed:
		right = Artifact.Option.make_effect(right_kind.selected + 1 as Artifact.Effect, get_index_of_selected_radio(right_option), int(right_lvl.value), right_pattern.selected as Artifact.Pattern)
	else:
		right = Artifact.Option.make_event(right_kind.selected + 1 as Artifact.Event, get_index_of_selected_radio(right_option), int(right_lvl.value), right_pattern.selected as Artifact.Pattern)
		
	var bottom: Artifact.Option
	if bottom_effect.button_pressed:
		bottom = Artifact.Option.make_effect(bottom_kind.selected + 1 as Artifact.Effect, get_index_of_selected_radio(bottom_option), int(bottom_lvl.value), bottom_pattern.selected as Artifact.Pattern)
	else:
		bottom = Artifact.Option.make_event(bottom_kind.selected + 1 as Artifact.Event, get_index_of_selected_radio(bottom_option), int(bottom_lvl.value), bottom_pattern.selected as Artifact.Pattern)
	
	var name_text := name_edit.text
	if name_text.is_empty():
		name_text = "ART_" + Rand.id(5)
	var artifact := Artifact.new(name_text, top, right, bottom, left)
	
	artifact_created.emit(artifact)

func reset() -> void:
	top_effect.pressed.emit()
	top_lvl.value = 1
	top_pattern.select(0)
	top_kind.select(0)
	top_option.get_popup().set_item_checked(0, true)
	top_option.icon = null
	top_option.text = "Any"
	
	left_effect.pressed.emit()
	left_lvl.value = 1
	left_pattern.select(0)
	left_kind.select(0)
	left_option.get_popup().set_item_checked(0, true)
	left_option.icon = null
	left_option.text = "Any"
	
	right_effect.pressed.emit()
	right_lvl.value = 1
	right_pattern.select(0)
	right_kind.select(0)
	right_option.get_popup().set_item_checked(0, true)
	right_option.icon = null
	right_option.text = "Any"
	
	bottom_effect.pressed.emit()
	bottom_lvl.value = 1
	bottom_pattern.select(0)
	bottom_kind.select(0)
	bottom_option.get_popup().set_item_checked(0, true)
	bottom_option.icon = null
	bottom_option.text = "Any"
	
