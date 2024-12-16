class_name SettingsGUI
extends Control

@onready var hide_wand_mappings := $Tabs/Display/HideWandMappings as CheckButton
@onready var hide_wand_modifier_hints := $Tabs/Display/HideWandModifierHints as CheckButton
@onready var hide_notifications := $Tabs/Display/HideNotifications as CheckButton
@onready var hide_status_effects := $Tabs/Display/HideStatusEffects as CheckButton
@onready var hide_health_and_mana := $Tabs/Display/HideHealthAndMana as CheckButton
@onready var hide_cooldown_timings := $Tabs/Display/HideCooldownTimings as CheckButton
@onready var hide_stats_view := $Tabs/Display/HideStatsView as CheckButton
@onready var hide_reticule: CheckButton = $Tabs/Display/HideReticule as CheckButton
@onready var projectile_indicator_size: HSlider = $Tabs/Display/ProjectileIndicatorSize/ProjectileIndicatorSize as HSlider
@onready var projectile_indicator_size_display: Label = $Tabs/Display/ProjectileIndicatorSize/ProjectileIndicatorSizeDisplay as Label
@onready var key_display: OptionButton = $Tabs/Display/KeyDisplayLabel/KeyDisplay
@onready var theme_color: ColorPickerButton = $Tabs/Display/ThemeColor/ThemeColor
@onready var theme_variation: OptionButton = $Tabs/Display/ThemeVariation/ThemeVariation

@onready var fov_slider: HSlider = $"Tabs/Camera/FOV Label/Slider" as HSlider
@onready var fov_value: Label = $"Tabs/Camera/FOV Label/Value" as Label
@onready var distance_slider: HSlider = $Tabs/Camera/Distance/Slider as HSlider
@onready var distance_value: Label = $Tabs/Camera/Distance/Value as Label
@onready var render_slider: HSlider = $"Tabs/Camera/Render Distance/Slider" as HSlider
@onready var render_value: Label = $"Tabs/Camera/Render Distance/Value" as Label
@onready var panning_speed_slider: HSlider = $"Tabs/Camera/Panning Speed/Slider" as HSlider
@onready var panning_speed_value: Label = $"Tabs/Camera/Panning Speed/Value" as Label


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


@onready var master_slider: HSlider = $Tabs/Sound/Master/Slider
@onready var master_value: Label = $Tabs/Sound/Master/Value
@onready var music_slider: HSlider = $Tabs/Sound/Music/Slider
@onready var music_value: Label = $Tabs/Sound/Music/Value
@onready var sfx_slider: HSlider = $Tabs/Sound/SFX/Slider
@onready var sfx_value: Label = $Tabs/Sound/SFX/Value

@onready var info_label: RichTextLabel = $Tabs/Game/Info

@onready var user_functions: TextEdit = $Tabs/Tools/user_functions

@onready var note_content: RichTextLabel = $Tabs/Notes/Content
@onready var show_notes: OptionButton = $Tabs/Notes/ShowNotes
@onready var sort_notes: OptionButton = $Tabs/Notes/SortNotes

var world_settings: WorldSettings:
	set(value):
		world_settings = value
		update_controls()

signal settings_changed(settings: WorldSettings)

signal save_game
signal main_menu
signal exit_game


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	user_functions.text = GlobalData.game_settings.user_functions_text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_controls() -> void:
	hide_wand_mappings.button_pressed = world_settings.hud_settings.hide_wand_mappings
	hide_wand_modifier_hints.button_pressed = world_settings.hud_settings.hide_wand_modifier_hints
	hide_notifications.button_pressed = world_settings.hud_settings.hide_notifications
	hide_status_effects.button_pressed = world_settings.hud_settings.hide_status_effects
	hide_health_and_mana.button_pressed = world_settings.hud_settings.hide_health_mana
	hide_cooldown_timings.button_pressed = world_settings.hud_settings.hide_cooldown_timings
	hide_stats_view.button_pressed = world_settings.hud_settings.hide_stats_view
	hide_reticule.button_pressed = world_settings.hud_settings.hide_reticule
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
	panning_speed_slider.value = world_settings.camera_settings.panning_speed
	panning_speed_value.text = str(int(world_settings.camera_settings.panning_speed)) + "m/s"
	
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
	
	for i in range(fps_options.item_count):
		if fps_options.get_item_text(i) == "Max" and world_settings.graphics_settings.max_fps == 0:
			fps_options.selected = i
			break
		elif int(fps_options.get_item_text(i)) == world_settings.graphics_settings.max_fps:
			fps_options.selected = i
			break
	vsync_options.selected = 0 if world_settings.graphics_settings.vsync else 1
	
	master_slider.value = world_settings.audio_settings.master
	music_slider.value = world_settings.audio_settings.bg
	sfx_slider.value = world_settings.audio_settings.sfx
	
	user_functions.text = GlobalData.game_settings.user_functions_text
	
	show_notes.selected = GlobalData.game_settings.notes_unlock_settings
	sort_notes.selected = GlobalData.game_settings.notes_sort_settings

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
	
func _on_hide_reticule_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_reticule = button_pressed
	UIAudioPlayer.check(button_pressed)
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
	
func _on_panning_speed_slider_value_changed(value: float) -> void:
	world_settings.camera_settings.panning_speed = value
	UIAudioPlayer.switch()
	panning_speed_value.text = str(int(value)) + "m/s"
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

func _on_master_slider_value_changed(value: float) -> void:
	world_settings.audio_settings.update_master(value)
	UIAudioPlayer.switch()
	master_value.text = str(int(value * 100)) + "%"
	settings_changed.emit(world_settings)


func _on_music_slider_value_changed(value: float) -> void:
	world_settings.audio_settings.update_bg(value)
	UIAudioPlayer.switch()
	music_value.text = str(int(value * 100)) + "%"
	settings_changed.emit(world_settings)


func _on_sfx_slider_value_changed(value: float) -> void:
	world_settings.audio_settings.update_sfx(value)
	UIAudioPlayer.switch()
	sfx_value.text = str(int(value * 100)) + "%"
	settings_changed.emit(world_settings)
	

func update_info() -> void:
	if world_settings == null or world_settings.game_mode_settings == null:
		return
		
	var game_flags: String = ", ".join(world_settings.game_mode_settings.flags_description())
	if game_flags.is_empty():
		game_flags = "None"
		
	var hour := floori(world_settings.time_of_day)
	var time := "%02d:%02d" % [hour, clampi(int((world_settings.time_of_day - hour) * 60), 0, 59)]
	info_label.text = """
[center]
[b]World Name:[/b] %s
[b]Keys Obtained:[/b] %d / 8 (%s)
[b]Day of the Year:[/b] %d
[b]Time of Day:[/b] %s
[b]Game Mode:[/b] %s
[b]Flags:[/b] %s

[b]Enemies Killed:[/b]
%s

[b]Seed:[/b] %d
[b]Generator Version: [/b] %d
[/center]
""" % [
	world_settings.world_name,
	GDNavigator.popcnt(world_settings.player_keys), String.num_int64(world_settings.player_keys, 2),
	world_settings.day_of_the_year, time,
	world_settings.game_mode_settings.game_mode_description(), game_flags,
	world_settings.enemies_killed_table(),
	world_settings.sed, world_settings.world_generation_version,
]

func update_notes() -> void:
	if note_content == null:
		return
	
	var content := ""
	
	if GlobalData.game_settings.notes_unlock_settings == GameSettings.NotesUnlockSettings.HIDE_ALL:
		note_content.text = "[center]\n\n Notes are hidden. Change the unlock settings if you want to enable notes.[/center]"
		return
	
	var highlight := func(note: String) -> String:
		if note.begins_with("func"):
			return note.replace("func", "[color=#F70]func[/color]")
		elif note.begins_with("variable"):
			return note.replace("variable", "[color=#7F0]variable[/color]")
		elif note.begins_with("spell"):
			return note.replace("spell", "[color=#0F7]spell[/color]")
		elif note.begins_with("artifact"):
			return note.replace("artifact", "[color=#F07]artifact[/color]")
		elif note.begins_with("wand"):
			return note.replace("wand", "[color=#70F]wand[/color]")
		elif note.begins_with("upgrades"):
			return note.replace("upgrades", "[color=#07F]upgrades[/color]")
		return note
		
	var regex_tag_t := RegEx.new()
	regex_tag_t.compile(r"\{(.+?)\}")
	var tag_t := func(note: String) -> String:
		var m := regex_tag_t.search(note)
		while m != null and m.get_start() > -1:
			var internal := m.get_string(1)
			var prefix := note.left(m.get_start())
			var suffix := note.right(note.length() - m.get_end())
			note = prefix + "[b][i]" + internal + "[/i][/b]" + suffix
			m = regex_tag_t.search(note)
		return note
			
	var notes_keys := GlobalData.game_settings.notes.keys() if GlobalData.game_settings.notes_unlock_settings == GameSettings.NotesUnlockSettings.SHOW_ALL else GlobalData.game_settings.unlocked_notes.keys()
	
	if GlobalData.game_settings.notes_sort_settings == GameSettings.NotesSortSettings.ALPHABETICAL:
		notes_keys.sort_custom(func(a: String, b: String) -> bool: return a < b)
	
	for note: String in notes_keys:
		if GlobalData.game_settings.notes.has(note):
			content += "[font_size=16][b][u]" + highlight.call(note) + "[/u][/b][/font_size]\n"
			content += tag_t.call(GlobalData.game_settings.notes[note]) + "\n\n"
	
	note_content.text = content

func _on_show_notes_item_selected(index: int) -> void:
	GlobalData.game_settings.notes_unlock_settings = index as GameSettings.NotesUnlockSettings
	UIAudioPlayer.switch()
	update_notes()
	GlobalData.game_settings.save()
	
func _on_sort_notes_item_selected(index: int) -> void:
	GlobalData.game_settings.notes_sort_settings = index as GameSettings.NotesSortSettings
	UIAudioPlayer.switch()
	update_notes()
	GlobalData.game_settings.save()

func hide_game_tab(should_hide: bool) -> void:
	var tab_container := $Tabs as TabContainer
	tab_container.set_tab_hidden(tab_container.get_tab_count() - 1, should_hide)

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
	var tab_container := $Tabs as TabContainer
	if tab_container.get_current_tab_control().name == "Game":
		update_info()
	if tab_container.get_current_tab_control().name == "Notes":
		update_notes()

func _on_user_functions_focus_exited() -> void:
	GlobalData.game_settings.build_user_functions(user_functions.text)
	GlobalData.game_settings.save()

func _on_user_functions_focus_entered() -> void:
	UIAudioPlayer.focus()
