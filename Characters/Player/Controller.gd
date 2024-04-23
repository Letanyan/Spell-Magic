class_name Controller
extends Node

enum Devices {
	LUNA,
	OUYA,
	PS3,
	PS4,
	PS5,
	STADIA,
	STEAM,
	SWITCH,
	JOYCON,
	XBOX360,
	XBOXONE,
	XBOXSERIES,
	STEAM_DECK
}

enum InputType {
	KEYBOARD,
	CONTROLLER
}

const pc_images = {
	"LT": "[img=%d]res://addons/controller_icons/assets/key/shift.png[/img]",
	"LB": "[img=%d]res://addons/controller_icons/assets/key/ctrl.png[/img]",
	"RT": "[img=%d]res://addons/controller_icons/assets/mouse/left.png[/img]",
	"RB": "[img=%d]res://addons/controller_icons/assets/mouse/right.png[/img]",
	"S": "[img=%d]res://addons/controller_icons/assets/key/space.png[/img]",
	"W": "[img=%d]res://addons/controller_icons/assets/key/r.png[/img]",
	"E": "[img=%d]res://addons/controller_icons/assets/key/e.png[/img]",
	"N": "[img=%d]res://addons/controller_icons/assets/key/q.png[/img]",
	"UP": "[img=%d]res://addons/controller_icons/assets/key/arrow_up.png[/img]",
	"DOWN": "[img=%d]res://addons/controller_icons/assets/key/arrow_down.png[/img]",
	"LEFT": "[img=%d]res://addons/controller_icons/assets/key/arrow_left.png[/img]",
	"RIGHT": "[img=%d]res://addons/controller_icons/assets/key/arrow_right.png[/img]",
	"L3": "[img=%d]res://addons/controller_icons/assets/key/z.png[/img]",
	"R3": "[img=%d]res://addons/controller_icons/assets/key/alt.png[/img]",
	"move_forward": "[img=%d]res://addons/controller_icons/assets/key/w.png[/img]",
	"move_left": "[img=%d]res://addons/controller_icons/assets/key/a.png[/img]",
	"move_back": "[img=%d]res://addons/controller_icons/assets/key/s.png[/img]",
	"move_right": "[img=%d]res://addons/controller_icons/assets/key/d.png[/img]",
}

signal last_input_type_changed(newType: InputType)
var last_input_type: InputType:
	set(value):
		last_input_type = value
		last_image_set = get_image_set()
		last_input_type_changed.emit(value)
		
var last_image_set: Dictionary = pc_images
		
func _ready() -> void:
	Input.joy_connection_changed.connect(on_joy_connection_changed)

func on_joy_connection_changed(device: int, connected: bool) -> void:
	if device == 0:
		if connected:
			# An await is required, otherwise a deadlock happens
			await get_tree().process_frame
			last_input_type = InputType.CONTROLLER
		else:
			# An await is required, otherwise a deadlock happens
			await get_tree().process_frame
			last_input_type = InputType.KEYBOARD

func get_joypad_type(fallback: Devices = Devices.JOYCON) -> Devices:
	# If on editor, default to fallback always, to avoid editing scene
	# files on controller reload
	if Engine.is_editor_hint():
		return fallback

	var controller_name := Input.get_joy_name(0)
	if "Luna Controller" in controller_name:
		return Devices.LUNA
	elif "PS3 Controller" in controller_name:
		return Devices.PS3
	elif "PS4 Controller" in controller_name:
		return Devices.PS4
	elif "PS5 Controller" in controller_name:
		return Devices.PS5
	elif "Stadia Controller" in controller_name:
		return Devices.STADIA
	elif "Steam Controller" in controller_name:
		return Devices.STEAM
	elif "Switch Controller" in controller_name or \
		"Switch Pro Controller" in controller_name:
		return Devices.SWITCH
	elif "Joy-Con" in controller_name:
		return Devices.JOYCON
	elif "Xbox 360 Controller" in controller_name:
		return Devices.XBOX360
	elif "Xbox One" in controller_name or \
		"X-Box One" in controller_name or \
		"Xbox Wireless Controller" in controller_name:
		return Devices.XBOXONE
	elif "Xbox Series" in controller_name:
		return Devices.XBOXSERIES
	elif "Steam Deck" in controller_name or \
		"Steam Virtual Gamepad" in controller_name:
		return Devices.STEAM_DECK
	elif "OUYA Controller" in controller_name:
		return Devices.OUYA
	else:
		return fallback
		
func get_image_set() -> Dictionary:
	if last_input_type == InputType.KEYBOARD:
		return pc_images
	else:
		match get_joypad_type():
			Devices.JOYCON:
				return pc_images
				
	return pc_images
		
func key_images(key: PackedStringArray, size: int = 32) -> String:
	var text := (last_image_set.get(key[0], "img:%d") as String) % size
	for i: int in range(1, key.size()):
		text += " + " + (last_image_set.get(key[i], "img:%d") % size)
	return text
