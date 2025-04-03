class_name SettingsGUI
extends Control

@onready var tab_container: TabContainer = $Tabs

@onready var hide_wand_mappings := $Tabs/UI/HideWandMappings as CheckButton
@onready var hide_wand_modifier_hints := $Tabs/UI/HideWandModifierHints as CheckButton
@onready var hide_notifications := $Tabs/UI/HideNotifications as CheckButton
@onready var hide_status_effects := $Tabs/UI/HideStatusEffects as CheckButton
@onready var hide_health_and_mana := $Tabs/UI/HideHealthAndMana as CheckButton
@onready var hide_cooldown_timings := $Tabs/UI/HideCooldownTimings as CheckButton
@onready var hide_stats_view := $Tabs/UI/HideStatsView as CheckButton
@onready var hide_reticule: CheckButton = $Tabs/UI/HideReticule as CheckButton
@onready var hide_compass: CheckButton = $Tabs/UI/HideCompass
@onready var hide_key_count: CheckButton = $Tabs/UI/HideKeyCount
@onready var projectile_indicator_size: HSlider = $Tabs/UI/ProjectileIndicatorSize/ProjectileIndicatorSize as HSlider
@onready var projectile_indicator_size_display: Label = $Tabs/UI/ProjectileIndicatorSize/ProjectileIndicatorSizeDisplay as Label
@onready var key_display: OptionButton = $Tabs/UI/KeyDisplayLabel/KeyDisplay
@onready var theme_color: ColorPickerButton = $Tabs/UI/ThemeColor/ThemeColor
@onready var theme_variation: OptionButton = $Tabs/UI/ThemeVariation/ThemeVariation

@onready var fov_slider: HSlider = $"Tabs/Camera/FOV Label/Slider" as HSlider
@onready var fov_value: Label = $"Tabs/Camera/FOV Label/Value" as Label
@onready var distance_slider: HSlider = $Tabs/Camera/Distance/Slider as HSlider
@onready var distance_value: Label = $Tabs/Camera/Distance/Value as Label
@onready var render_slider: HSlider = $"Tabs/Camera/Render Distance/Slider" as HSlider
@onready var render_value: Label = $"Tabs/Camera/Render Distance/Value" as Label
@onready var panning_speed_x_slider: HSlider = $"Tabs/Camera/Panning Speed X/Slider" as HSlider
@onready var panning_speed_x_value: Label = $"Tabs/Camera/Panning Speed X/Value" as Label
@onready var panning_speed_y_slider: HSlider = $"Tabs/Camera/Panning Speed Y/Slider" as HSlider
@onready var panning_speed_y_value: Label = $"Tabs/Camera/Panning Speed Y/Value" as Label

@onready var scaling_options: OptionButton = $"Tabs/Graphics/Scaling Mode/Options"
@onready var scaling_slider: HSlider = $Tabs/Graphics/Scaling/Slider
@onready var scaling_value: Label = $Tabs/Graphics/Scaling/Value
@onready var sharpness_slider: HSlider = $Tabs/Graphics/Sharpness/Slider
@onready var sharpness_value: Label = $Tabs/Graphics/Sharpness/Value
@onready var display_style_options: OptionButton = $"Tabs/Graphics/Display Style/Options"
@onready var display_size_options: OptionButton = $"Tabs/Graphics/Display Size/Options"
@onready var msaa_options: OptionButton = $Tabs/Graphics/MSAA/Options
@onready var ssaa_options: OptionButton = $Tabs/Graphics/SSAA/Options
@onready var taa_check: CheckButton = $Tabs/Graphics/TAA/Check
@onready var fps_options: OptionButton = $Tabs/Graphics/FPS/Options
@onready var vsync_options: OptionButton = $Tabs/Graphics/VSYNC/Options
@onready var grass_size_slider: HSlider = $"Tabs/Graphics/Grass Size/Slider"
@onready var grass_size_value: Label = $"Tabs/Graphics/Grass Size/Value"
@onready var terrain_detail_value: OptionButton = $Tabs/Graphics/TerrainDetail/Value
@onready var graphics_notice: Label = $Tabs/Graphics/Notice

@onready var master_slider: HSlider = $Tabs/Sound/Master/Slider
@onready var master_value: Label = $Tabs/Sound/Master/Value
@onready var bg_slider: HSlider = $Tabs/Sound/Background/Slider
@onready var bg_value: Label = $Tabs/Sound/Background/Value
@onready var sfx_slider: HSlider = $Tabs/Sound/SFX/Slider
@onready var sfx_value: Label = $Tabs/Sound/SFX/Value
@onready var ui_slider: HSlider = $Tabs/Sound/UI/Slider
@onready var ui_value: Label = $Tabs/Sound/UI/Value

@onready var info_label: RichTextLabel = $Tabs/Game/Info

@onready var user_functions: TextEdit = $Tabs/Functions/user_functions

@onready var magic_book: MagicBookGUI = $"Tabs/Universal Magic Book/MagicBook"

@onready var skin_color_picker: ColorPickerButton = $Tabs/Skin/Container/Skin/ColorPicker
@onready var hair_color_picker: ColorPickerButton = $Tabs/Skin/Container/Hair/ColorPicker
@onready var eyes_color_picker: ColorPickerButton = $Tabs/Skin/Container/Eyes/ColorPicker
@onready var overshirt_color_picker: ColorPickerButton = $Tabs/Skin/Container/Overshirt/ColorPicker
@onready var undershirt_color_picker: ColorPickerButton = $Tabs/Skin/Container/Undershirt/ColorPicker
@onready var body_armor_trim_color_picker: ColorPickerButton = $Tabs/Skin/Container/BodyArmorTrim/ColorPicker
@onready var body_armor_plate_color_picker: ColorPickerButton = $Tabs/Skin/Container/BodyArmorPlate/ColorPicker
@onready var shoes_color_picker: ColorPickerButton = $Tabs/Skin/Container/Shoes/ColorPicker
@onready var pants_color_picker: ColorPickerButton = $Tabs/Skin/Container/Pants/ColorPicker
@onready var legs_armor_trim_color_picker: ColorPickerButton = $Tabs/Skin/Container/LegsArmorTrim/ColorPicker
@onready var legs_armor_plate_color_picker: ColorPickerButton = $Tabs/Skin/Container/LegsArmorPlate/ColorPicker

var player: Player
var world_settings: WorldSettings:
	set(value):
		world_settings = value
		update_controls()
		
var is_magic_book_selected: bool = false

signal settings_changed(settings: WorldSettings)

signal save_game
signal main_menu
signal exit_game

signal tab_changed(tab: String)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	user_functions.text = GlobalData.game_settings.user_functions_text
	magic_book.book = GlobalData.user_magic_book
	magic_book.is_universal = true
	magic_book.page.is_universal = true
	tab_container.set_tab_hidden(6, GlobalData.is_demo)
	# TODO hide universal magic book when using spell deck

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_controls() -> void:
	UIAudioPlayer.silence = true
	
	hide_wand_mappings.button_pressed = world_settings.hud_settings.hide_wand_mappings
	hide_wand_modifier_hints.button_pressed = world_settings.hud_settings.hide_wand_modifier_hints
	hide_notifications.button_pressed = world_settings.hud_settings.hide_notifications
	hide_status_effects.button_pressed = world_settings.hud_settings.hide_status_effects
	hide_health_and_mana.button_pressed = world_settings.hud_settings.hide_health_mana
	hide_cooldown_timings.button_pressed = world_settings.hud_settings.hide_cooldown_timings
	hide_stats_view.button_pressed = world_settings.hud_settings.hide_stats_view
	hide_reticule.button_pressed = world_settings.hud_settings.hide_reticule
	hide_compass.button_pressed = world_settings.hud_settings.hide_compass
	hide_key_count.button_pressed = world_settings.hud_settings.hide_collected_keys_label
	
	projectile_indicator_size.value = world_settings.hud_settings.projectile_indicator_size
	projectile_indicator_size_display.text = str(int(projectile_indicator_size.value))
	key_display.selected = world_settings.hud_settings.key_display
	theme_variation.selected = world_settings.hud_settings.theme_variation
	theme_color.color = world_settings.hud_settings.theme_color
	
	fov_slider.value = int(world_settings.camera_settings.fov)
	fov_value.text = str(int(world_settings.camera_settings.fov))
	distance_slider.value = int(world_settings.camera_settings.distance)
	distance_value.text = str(int(world_settings.camera_settings.distance))
	render_slider.value = world_settings.camera_settings.render_distance
	render_value.text = str(int(world_settings.camera_settings.render_distance)) + "m"
	panning_speed_x_slider.value = world_settings.camera_settings.panning_speed_x
	panning_speed_x_value.text = "x %.2f" % world_settings.camera_settings.panning_speed_x
	panning_speed_y_slider.value = world_settings.camera_settings.panning_speed_y
	panning_speed_y_value.text = "x %.2f" % world_settings.camera_settings.panning_speed_y
	
	scaling_options.selected = world_settings.graphics_settings.scaling_mode
	sharpness_slider.value = world_settings.graphics_settings.sharpness * 100
	sharpness_value.text = "%.0f%%" % [world_settings.graphics_settings.sharpness * 100]
	scaling_slider.value = world_settings.graphics_settings.scaling * 100
	scaling_value.text = "%.0f%%" % [world_settings.graphics_settings.scaling * 100]
	display_style_options.selected = world_settings.graphics_settings.display_style
	for i in range(display_size_options.item_count):
		if display_size_options.get_item_text(i).begins_with(world_settings.graphics_settings.display_size):
			display_size_options.selected = i
			break
	msaa_options.selected = world_settings.graphics_settings.msaa
	ssaa_options.selected = world_settings.graphics_settings.ssaa
	taa_check.button_pressed = world_settings.graphics_settings.taa
	grass_size_slider.value = world_settings.graphics_settings.grass_size * 100
	grass_size_value.text = "%.0f%%" % [world_settings.graphics_settings.grass_size * 100]
	terrain_detail_value.select(terrain_detail_value.get_item_index(world_settings.graphics_settings.terrain_detail))
	
	for i in range(fps_options.item_count):
		if fps_options.get_item_text(i) == "Max" and world_settings.graphics_settings.max_fps == 0:
			fps_options.selected = i
			break
		elif int(fps_options.get_item_text(i)) == world_settings.graphics_settings.max_fps:
			fps_options.selected = i
			break
	vsync_options.selected = 0 if world_settings.graphics_settings.vsync else 1
	
	master_slider.value = world_settings.audio_settings.master
	bg_slider.value = world_settings.audio_settings.bg
	sfx_slider.value = world_settings.audio_settings.sfx
	ui_slider.value = world_settings.audio_settings.ui
	
	user_functions.text = GlobalData.game_settings.user_functions_text
	
	if tab_container.get_current_tab_control().name == "Game":
		update_info()
	if tab_container.get_current_tab_control().name == "Universal Magic Book":
		update_magic_book()
		
	skin_color_picker.color = world_settings.customisation_settings.skin
	hair_color_picker.color = world_settings.customisation_settings.hair
	eyes_color_picker.color = world_settings.customisation_settings.eyes
	overshirt_color_picker.color = world_settings.customisation_settings.overshirt
	undershirt_color_picker.color = world_settings.customisation_settings.undershirt
	body_armor_trim_color_picker.color = world_settings.customisation_settings.body_armor_trim
	body_armor_plate_color_picker.color = world_settings.customisation_settings.body_armor_plate
	shoes_color_picker.color = world_settings.customisation_settings.shoes
	pants_color_picker.color = world_settings.customisation_settings.pants
	legs_armor_trim_color_picker.color = world_settings.customisation_settings.legs_armor_trim
	legs_armor_plate_color_picker.color = world_settings.customisation_settings.legs_armor_plate
	
	UIAudioPlayer.silence = false

func _on_hide_wand_mappings_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_wand_mappings = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)


func _on_hide_wand_modifier_hints_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_wand_modifier_hints = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)


func _on_hide_notifications_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_notifications = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)


func _on_hide_status_effects_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_status_effects = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)


func _on_hide_health_and_mana_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_health_mana = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)


func _on_hide_cooldown_timings_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_cooldown_timings = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)


func _on_hide_stats_view_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_stats_view = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)
	
func _on_hide_possible_upgrades_toggled(toggled_on: bool) -> void:
	world_settings.hud_settings.hide_possible_upgrades = toggled_on
	UIAudioPlayer.check(toggled_on)
	settings_changed.emit(world_settings)
	
func _on_hide_reticule_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_reticule = button_pressed
	UIAudioPlayer.check(button_pressed)
	settings_changed.emit(world_settings)
	
func _on_hide_compass_toggled(toggled_on: bool) -> void:
	world_settings.hud_settings.hide_compass = toggled_on
	UIAudioPlayer.check(toggled_on)
	settings_changed.emit(world_settings)
	
func _on_hide_key_count_toggled(toggled_on: bool) -> void:
	world_settings.hud_settings.hide_collected_keys_label = toggled_on
	UIAudioPlayer.check(toggled_on)
	settings_changed.emit(world_settings)
	
func _on_projectile_indicator_size_value_changed(value: float) -> void:
	world_settings.hud_settings.projectile_indicator_size = value
	UIAudioPlayer.switch()
	projectile_indicator_size_display.text = str(int(projectile_indicator_size.value))
	settings_changed.emit(world_settings)
	
func _on_key_display_item_selected(index: int) -> void:
	world_settings.hud_settings.key_display = index as HUDSettings.KeyDisplay
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)
	
func _on_theme_variation_item_selected(index: int) -> void:
	world_settings.hud_settings.theme_variation = index as HUDSettings.ThemeKind
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)
	
func _on_theme_color_color_changed(color: Color) -> void:
	world_settings.hud_settings.theme_color = color
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)

func _on_fov_slider_value_changed(value: float) -> void:
	world_settings.camera_settings.fov = int(value)
	UIAudioPlayer.switch()
	fov_value.text = str(int(value))
	settings_changed.emit(world_settings)

func _on_distance_slider_value_changed(value: float) -> void:
	world_settings.camera_settings.distance = int(value)
	UIAudioPlayer.switch()
	distance_value.text = str(int(value))
	settings_changed.emit(world_settings)
	
func _on_render_distance_slider_value_changed(value: float) -> void:
	world_settings.camera_settings.render_distance = value
	UIAudioPlayer.switch()
	render_value.text = str(int(value)) + "m"
	settings_changed.emit(world_settings)
	
func _on_panning_speed_x_slider_value_changed(value: float) -> void:
	world_settings.camera_settings.panning_speed_x = value
	UIAudioPlayer.switch()
	panning_speed_x_value.text = "x %.2f" % value
	settings_changed.emit(world_settings)
	
func _on_panning_speed_y_slider_value_changed(value: float) -> void:
	world_settings.camera_settings.panning_speed_y = value
	UIAudioPlayer.switch()
	panning_speed_y_value.text = "x %.2f" % value
	settings_changed.emit(world_settings)
	
func _on_auto_distance_toggled(toggled_on: bool) -> void:
	world_settings.camera_settings.auto_distance = toggled_on
	UIAudioPlayer.check(toggled_on)
	settings_changed.emit(world_settings)

func _on_scaling_mode_options_item_selected(index: int) -> void:
	world_settings.graphics_settings.update_scaling_mode(index)
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)
		

func _on_scaling_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var value: float = scaling_slider.value / 100.0
		world_settings.graphics_settings.update_scaling(value)
		settings_changed.emit(world_settings)


func _on_sharpness_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var value: float = sharpness_slider.value / 100.0
		world_settings.graphics_settings.update_sharpness(value)
		settings_changed.emit(world_settings)


func _on_scaling_slider_value_changed(value: float) -> void:
	scaling_value.text = "%.0f%%" % [value]
	UIAudioPlayer.switch()


func _on_sharpness_slider_value_changed(value: float) -> void:
	sharpness_value.text = "%.0f%%" % [value]
	UIAudioPlayer.switch()


func _on_display_style_options_item_selected(index: int) -> void:
	world_settings.graphics_settings.update_display_style(index)
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)


func _on_display_size_options_item_selected(index: int) -> void:
	world_settings.graphics_settings.update_display_size(display_size_options.get_item_text(index))
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)


func _on_msaa_options_item_selected(index: int) -> void:
	world_settings.graphics_settings.update_msaa(index)
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)


func _on_ssaa_options_item_selected(index: int) -> void:
	world_settings.graphics_settings.update_ssaa(index)
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)


func _on_taa_check_toggled(toggled_on: bool) -> void:
	world_settings.graphics_settings.update_taa(toggled_on)
	UIAudioPlayer.check(toggled_on)
	settings_changed.emit(world_settings)


func _on_max_fps_options_item_selected(index: int) -> void:
	var num_text: String = fps_options.get_item_text(index)
	UIAudioPlayer.switch()
	var num: int = 0
	if num_text == "Max":
		num = 0
	else:
		num = num_text.to_int()
	world_settings.graphics_settings.update_max_fps(num)
	settings_changed.emit(world_settings)
	

func _on_vsync_options_item_selected(index: int) -> void:
	world_settings.graphics_settings.update_vsync(index == 0)
	UIAudioPlayer.switch()
	settings_changed.emit(world_settings)
	
func _on_grass_size_slider_value_changed(value: float) -> void:
	grass_size_value.text = "%.0f%%" % [value]	
	UIAudioPlayer.switch()
	
func _on_grass_size_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		world_settings.graphics_settings.grass_size = grass_size_slider.value / 100.0
		settings_changed.emit(world_settings)
		graphics_notice.show()
		
func _on_terrain_detail_value_item_selected(index: int) -> void:
	world_settings.graphics_settings.terrain_detail = terrain_detail_value.get_item_id(index)
	UIAudioPlayer.switch()
	graphics_notice.show()

func _on_master_slider_value_changed(value: float) -> void:
	world_settings.audio_settings.update_master(value)
	UIAudioPlayer.switch(&"Master")
	master_value.text = str(int(value * 100)) + "%"
	settings_changed.emit(world_settings)


func _on_bg_slider_value_changed(value: float) -> void:
	world_settings.audio_settings.update_bg(value)
	UIAudioPlayer.switch(&"BG")
	bg_value.text = str(int(value * 100)) + "%"
	settings_changed.emit(world_settings)


func _on_sfx_slider_value_changed(value: float) -> void:
	world_settings.audio_settings.update_sfx(value)
	UIAudioPlayer.switch(&"SFX")
	sfx_value.text = str(int(value * 100)) + "%"
	settings_changed.emit(world_settings)
	
func _on_ui_slider_value_changed(value: float) -> void:
	world_settings.audio_settings.update_ui(value)
	UIAudioPlayer.switch(&"UI")
	ui_value.text = str(int(value * 100)) + "%"
	settings_changed.emit(world_settings)
	

func update_info() -> void:
	if world_settings == null or world_settings.game_mode_settings == null:
		return
		
	var game_flags: String = ", ".join(world_settings.game_mode_settings.flags_description())
	if game_flags.is_empty():
		game_flags = "None"
		
	var hour := floori(world_settings.time_of_day)
	var time := "%02d:%02d" % [hour, clampi(int((world_settings.time_of_day - hour) * 60), 0, 59)]
	info_label.text = """[center][b]World Name:[/b] %s
[b]Keys Obtained:[/b] %d / 8
[b]Day of the Year:[/b] %d
[b]Time of Day:[/b] %s
[b]Game Mode:[/b] %s
[b]Flags:[/b] %s
[b]Current Position:[/b] %.v

[b]Enemies Killed:[/b]
%s

[b]Seed:[/b] %d
[b]Generator Version: [/b] %d
[/center]
""" % [
	world_settings.world_name,
	GDNavigator.popcnt(world_settings.player_keys),
	world_settings.day_of_the_year, time,
	world_settings.game_mode_settings.game_mode_description(), game_flags,
	player.position if player != null else world_settings.player_position,
	world_settings.enemies_killed_table(),
	world_settings.sed, world_settings.world_generation_version,
]

func hide_game_tab(should_hide: bool) -> void:
	var tabs := $Tabs as TabContainer
	tabs.set_tab_hidden(0, should_hide)
	tabs.set_tab_hidden(tabs.get_tab_count() - 1, should_hide)

func _on_save_pressed() -> void:
	save_game.emit()
	UIAudioPlayer.click()


func _on_main_menu_pressed() -> void:
	main_menu.emit()
	UIAudioPlayer.click()


func _on_exit_game_pressed() -> void:
	exit_game.emit()
	UIAudioPlayer.click()

func _on_tabs_tab_selected(tab: int) -> void:
	UIAudioPlayer.switch()
	var tabs := $Tabs as TabContainer
	if tabs.get_current_tab_control().name == "Game":
		update_info()
		
	if is_magic_book_selected:
		is_magic_book_selected = false
		save_user_magic_book()
	if tabs.get_current_tab_control().name == "Universal Magic Book":
		is_magic_book_selected = true
		update_magic_book()
		
	if player != null:
		tab_changed.emit(tabs.get_current_tab_control().name)
		

func _on_user_functions_focus_exited() -> void:
	GlobalData.game_settings.build_user_functions(user_functions.text)
	GlobalData.game_settings.save()

func _on_user_functions_focus_entered() -> void:
	UIAudioPlayer.focus()

func save_user_magic_book() -> void:
	magic_book.book.save_absolute_path("user://universal_magic_book.json")

func update_magic_book() -> void:
	magic_book.duplicate_book()
	magic_book.reload_list()

func _on_skin_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_skin(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_hair_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_hair(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_eyes_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_eyes(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_overshirt_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_overshirt(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_undershirt_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_undershirt(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_body_armor_trim_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_body_armor_trim(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_body_armor_plate_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_body_armor_plate(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_shoes_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_shoes(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_pants_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_pants(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_legs_armor_trim_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_legs_armor_trim(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_legs_armor_plate_color_picker_color_changed(color: Color) -> void:
	world_settings.customisation_settings.update_legs_armor_plate(player.skeleton_3d, color)
	UIAudioPlayer.switch()

func _on_make_customisation_default_pressed() -> void:
	GlobalData.game_settings.default_world_settings.customisation_settings.update_skin(player.skeleton_3d, skin_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_hair(player.skeleton_3d, hair_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_eyes(player.skeleton_3d, eyes_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_overshirt(player.skeleton_3d, overshirt_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_undershirt(player.skeleton_3d, undershirt_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_body_armor_trim(player.skeleton_3d, body_armor_trim_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_body_armor_plate(player.skeleton_3d, body_armor_plate_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_shoes(player.skeleton_3d, shoes_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_pants(player.skeleton_3d, pants_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_legs_armor_trim(player.skeleton_3d, legs_armor_trim_color_picker.color)
	GlobalData.game_settings.default_world_settings.customisation_settings.update_legs_armor_plate(player.skeleton_3d, legs_armor_plate_color_picker.color)
	GlobalData.game_settings.save()
	UIAudioPlayer.click()
