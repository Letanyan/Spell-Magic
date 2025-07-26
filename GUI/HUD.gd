class_name HUD
extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_bar_label: Label = $HealthBar/Label
@onready var mana_bar: ProgressBar = $ManaBar
@onready var mana_bar_label: Label = $ManaBar/Label
@onready var burning_bar: TextureProgressBar = $BurningBar
@onready var freeze_bar: TextureProgressBar = $FreezeBar
@onready var wet_bar: TextureProgressBar = $WetBar

@onready var cooldown_list: ItemList = $CooldownList

@onready var wand_mapping_panel: Panel = $WandMappingPanel
@onready var wand_mapping: RichTextLabel = $WandMappingPanel/WandMapping

@onready var notification_label: RichTextLabel = $NotificationLabel
var notifications: Dictionary = {} ## [String(Message)]int(seconds until expiration)

@onready var stats_view: StatsView = $VBox/StatsView

@onready var hud_upgrades: HUDUpgrades = $VBox/HudUpgrades


@onready var objective_label: RichTextLabel = $ObjectiveLabel

@onready var selection_wheel: SelectionWheel = $SelectionWheel
var image_preview_raws := {} ## [String]Texture2D

@onready var message_panel: Panel = $MessagePanel
@onready var message_label: RichTextLabel = $MessagePanel/VBoxContainer/MessageLabel
var messages: Dictionary = {} ## [GameSettings.Tutorial]String(Message)
var message_times: Dictionary = {} ## [GameSettings.Tutorial]int(seconds until expiration)

@onready var compass: Control = $Compass
@onready var compass_n: Label = $Compass/N
@onready var compass_e: Label = $Compass/E
@onready var compass_s: Label = $Compass/S
@onready var compass_w: Label = $Compass/W
@onready var compass_overflow: Label = $Compass/Overflow
var compass_markers: Array[Control] = []
var compass_marker_locations: Array[Vector2] = []


var cooldown_alert: Dictionary
var not_enough_mana_alert: float = 0.0

var world_settings: WorldSettings:
	set(value):
		world_settings = value
		hud_settings = world_settings.hud_settings
		
var hud_settings: HUDSettings = null
var cached_theme_color := Color()
var cached_theme_variation := HUDSettings.ThemeKind.MONO

var player: Player:
	set(value):
		player = value
		player.vital_update.connect(update_hud_with_vitals)
		update_hud_with_vitals(player.vitals)
		player.spell_was_cast.connect(spell_was_cast)
		player.spell_was_disallowed.connect(spell_was_disallowed)
		player.spell_was_limited.connect(spell_was_limited)
		objective_label.text = "[right][font_size=24][color=#ffb500]%d [img=l,24x24, color=#ffb500]res://GUI/Images/key.svg[/img][/color][/font_size][/right]" % GDNavigator.popcnt(player.world_settings.player_keys)

var wand: Wand: set = set_wand
		
var book: MagicBook:
	set(value):
		book = value
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.pick_up_world_item_artifact.connect(update_pick_up_world_item_artifact)
	SignalBus.pick_up_world_item_spell.connect(update_pick_up_world_item_spell)
	SignalBus.pick_up_world_item_key.connect(update_pick_up_world_item_key)
	SignalBus.pick_up_world_item_coin.connect(update_pick_up_world_item_coin)
	SignalBus.pick_up_world_item_red_cross.connect(func(entity: RedCross, c: float, m: String) -> void: show_notification(bbcode_new_item(m), 10))
	SignalBus.pick_up_world_item_scroll_note.connect(update_pick_up_world_item_scroll_note)
	hud_upgrades.upgrade_was_complete.connect(func(message: String) -> void:
		show_message(GameSettings.Tutorials.GOT_UPGRADE, message, 8.0)
	)
	
func set_wand(value: Wand) -> void:
	if wand != null:
		wand.selection_wheel = null
		wand.spell_disallowed.disconnect(spell_was_disallowed)
		wand.action_updated.disconnect(update_wand_mappings)
		wand.spell_updated.disconnect(update_wand_mappings)
		wand.picked_spell_changed.disconnect(update_wand_mappings)
		wand.key_up.disconnect(update_wand_mappings)
		wand.key_down.disconnect(update_wand_mappings)
		wand.will_show_selection_wheel.disconnect(update_selection_wheel_spells)
	wand = value
	wand.selection_wheel = selection_wheel
	wand.spell_disallowed.connect(spell_was_disallowed)
	wand.action_updated.connect(update_wand_mappings)
	wand.spell_updated.connect(update_wand_mappings)
	wand.picked_spell_changed.connect(update_wand_mappings)
	wand.key_up.connect(update_wand_mappings)
	wand.key_down.connect(update_wand_mappings)
	wand.will_show_selection_wheel.connect(update_selection_wheel_spells)
	update_wand_mappings()
	update_spell_cooldowns(0.0)

func update_hud_with_vitals(vitals: Vitals) -> void:
	health_bar.max_value = vitals.health.max_value
	if health_bar.value != vitals.health.value:
		var tween := create_tween()
		tween.tween_property(health_bar, "value", vitals.health.value, 0.3)
	health_bar_label.text = "%d/%d" % [ceili(vitals.health.value), vitals.health.max_value]
	mana_bar.max_value = vitals.mana.max_value
	if mana_bar.value != vitals.mana.value:
		var tween := create_tween()
		tween.tween_property(mana_bar, "value", vitals.mana.value, 0.3)
	mana_bar_label.text = "%d/%d" % [vitals.mana.value, vitals.mana.max_value]
	burning_bar.value = vitals.burning.value
	burning_bar.max_value = vitals.burning.max_value
	freeze_bar.value = vitals.freeze.value
	freeze_bar.max_value = vitals.freeze.max_value
	wet_bar.value = vitals.wetness.value
	wet_bar.max_value = vitals.wetness.max_value
	update_stats_view()
	if wand != null and book != null and player != null:
		update_wand_mappings()

func spell_on_cooldown(spell: Spell) -> void:
	var i := 0
	for s: String in book.cooldown:
		if i >= cooldown_list.item_count:
			break
		if s == spell.name:
			cooldown_list.select(i, false)
			cooldown_alert[s] = Time.get_unix_time_from_system()
		i += 1
	update_spell_cooldowns(0.0)
	
func not_enough_mana_for_spell(spell: Spell) -> void:
	not_enough_mana_alert = Time.get_unix_time_from_system()
	var style: StyleBoxFlat = mana_bar.get_theme_stylebox("background")
	style.bg_color = Color(1, 0, 0.3, 0.5)
	style.border_color = Color(1, 0, 0.3, 1)
	
	
func bbcode(message: String, font_size: int = 18, color: String = "#F05", outline_color: String = "#000", outline_size: int = 4) -> String:
	return "[outline_color=%s][outline_size=%d][color=%s][font_size=%d]%s[/font_size][/color][/outline_size][/outline_color]" % [outline_color, outline_size, color, font_size, message]
	
func bbcode_error(message: String) -> String:
	return bbcode(message)
	
func bbcode_new_item(message: String) -> String:
	return bbcode(message, 18, "#0F5")
	
func spell_was_disallowed(spell: Spell, reason: MagicBook.DisallowSpellReason) -> void:
	match reason:
		MagicBook.DisallowSpellReason.COOLDOWN:
			spell_on_cooldown(spell)
			show_notification(bbcode_error("'%s' is on cooldown" % spell.name), 5)	
		MagicBook.DisallowSpellReason.MANA:
			not_enough_mana_for_spell(spell)
			show_notification(bbcode_error("'%s' requires M %.1f" % [spell.name, spell.actual_mana_cost()]), 5)		
		MagicBook.DisallowSpellReason.POWER:
			show_notification(bbcode_error("'%s' requires P %d upgrade" % [spell.name, spell.power]), 5)
		MagicBook.DisallowSpellReason.CRIT_RATE:
			show_notification(bbcode_error("'%s' requires CR %d upgrade" % [spell.name, spell.crit_rate]), 5)
		MagicBook.DisallowSpellReason.CRIT_DMG:
			show_notification(bbcode_error("'%s' requires CD %d upgrade" % [spell.name, spell.crit_dmg]), 5)
		MagicBook.DisallowSpellReason.COUNT:
			show_notification(bbcode_error("'%s' requires N %d upgrade" % [spell.name, spell.count]), 5)
		MagicBook.DisallowSpellReason.DURATION:
			show_notification(bbcode_error("'%s' requires T %.1f upgrade" % [spell.name, spell.duration]), 5)
		MagicBook.DisallowSpellReason.RADIUS:
			var r := spell.radius_cache
			show_notification(bbcode_error("'%s' requires r %.1f upgrade" % [spell.name, r]), 5)
		MagicBook.DisallowSpellReason.ACTIVE:
			show_notification(bbcode_error("'%s' is not active in magic book" % [spell.name]), 5)
		MagicBook.DisallowSpellReason.CHAINED_SPELL:
			show_notification(bbcode_error("'%s''s chained spell has a problem" % [spell.name]), 5)
		MagicBook.DisallowSpellReason.ELEMENT:
			show_notification(bbcode_error("'%s''s requires element '%s' upgrade" % [spell.name, (Spell.Element.keys()[spell.element] as String).to_lower()]), 5)
		# We don't disallow spells from being cast because of velocity. We just limit the velocity and notify the player.
		#MagicBook.DisallowSpellReason.VELOCITY:
			#show_notification(bbcode_error(""), 5)
			
func spell_was_limited(spell: Spell, reason: MagicBook.DisallowSpellReason) -> void:
	match reason:
		MagicBook.DisallowSpellReason.VELOCITY:
			show_notification(bbcode_error("'%s' velocity limited to %.0fm/s" % [spell.name, world_settings.upgrade_settings.max_v() + world_settings.upgrade_settings.buff_v]), 5)
	
func spell_was_cast(s: Spell) -> void:
	#book.use_spell(s)
	update_spell_cooldowns(0.0)
	
func update_spell_cooldowns(delta: float) -> void:
	if book == null or not visible:
		return
	
	var i := 0
	for s: String in book.cooldown:
		var cooldown := book.cooldown[s] as float
		var description := " " + s + " - " + ("%.0f" % cooldown) + "s"
		if i < cooldown_list.item_count:
			cooldown_list.set_item_text(i, description)
		else:
			cooldown_list.add_item(description)
		if Time.get_unix_time_from_system() - cooldown_alert.get(s, 0) > 3:
			cooldown_list.deselect(i)
		i += 1
		
	if i < cooldown_list.item_count:
		update_wand_mappings()
		
	while i < cooldown_list.item_count:
		cooldown_list.remove_item(i)
		
	cooldown_list.visible = not((hud_settings != null and hud_settings.hide_cooldown_timings) or cooldown_list.item_count == 0) 
		
	var mana_alert_time := Time.get_unix_time_from_system() - not_enough_mana_alert
	if not_enough_mana_alert != 0.0 and mana_alert_time > 0.5:
		var style: StyleBoxFlat = mana_bar.get_theme_stylebox("background")
		style.bg_color = Color(1, 0.702, 1)
		style.border_color = Color(0.667, 0, 0.667)
		not_enough_mana_alert = 0.0
		
	draw_notifications(delta)
	draw_messages(delta)
		
func show_notification(message: String, duration: float) -> void:
	notifications[message] = Time.get_unix_time_from_system() + duration
	draw_notifications(0.0)
	
func draw_notifications(delta: float) -> void:
	var to_erase := []
	var count := 0
	var result: String = "[right]\n"
	for n: String in notifications:
		var d := notifications[n] as float
		if Time.get_unix_time_from_system() >= d:
			to_erase.append(n)
		else:
			count += 1
			notifications[n] -= delta
			result += n + "\n"
		if count >= 4:
			break
			
	result += "[/right]"
	notification_label.text = result
	for n: String in to_erase:
		notifications.erase(n)
		
func show_message(key: GameSettings.Tutorials, text: String, duration: float) -> void:
	messages[key] = text
	message_times[key] = Time.get_unix_time_from_system() + duration
	draw_messages(0.0)
	
func hide_message(key: GameSettings.Tutorials) -> void:
	messages.erase(key)
	message_times.erase(key)
	draw_messages(0.0)
		
func draw_messages(delta: float) -> void:
	var to_erase := []
	var result := ""
	for key: GameSettings.Tutorials in messages:
		var d := message_times[key] as float
		if Time.get_unix_time_from_system() >= d:
			to_erase.append(key)
		else:
			message_times[key] -= delta
			result = messages[key] as String
			break
			
	message_label.text = result
	message_panel.visible = not result.is_empty()
	for key: GameSettings.Tutorials in to_erase:
		messages.erase(key)
		message_times.erase(key)
		
func update_wand_mappings() -> void:
	const SIZE := 16
	var rich_text := ""
	rich_text = "[font_size=%d]" % SIZE
	
	if (hud_settings != null and not hud_settings.hide_wand_modifier_hints) and wand.mods.size() > 0:
		var modifier_keys := ""
		for m: String in wand.mods:
			modifier_keys += GlobalData.controller.key_images([m]) + " "
		rich_text += " Modifiers: " + modifier_keys + "\n"
		
		
	var color_spell := func(s: Spell) -> String:
		var reason := book.can_use_spell(s)
		if reason == MagicBook.DisallowSpellReason.NONE:
			if player.vitals.mana.value < s.actual_mana_cost():
				reason = MagicBook.DisallowSpellReason.MANA
		match reason:
			MagicBook.DisallowSpellReason.NONE:
				if Wand.is_item_place_spell(s.name):
					return s.name
				else:
					return s.name
			MagicBook.DisallowSpellReason.COOLDOWN:
				return "[color=#F05]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.MANA:
				return "[color=#A0A]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.ACTIVE:
				return "[color=#777]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.COUNT:
				return "[color=#F700FF]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.POWER:
				return "[color=#0008FF]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.CRIT_RATE:
				return "[color=#0000AA]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.CRIT_DMG:
				return "[color=#AAAA00]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.DURATION:
				return "[color=#00FF08]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.RADIUS:
				return "[color=#7700FF]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.CHAINED_SPELL:
				return "[color=#F70]" + s.name + "[/color]"
			MagicBook.DisallowSpellReason.ELEMENT:
				return "[color=#FFF7]" + s.name + "[/color]"
			_:
				return "[color=#F50]" + s.name + "[/color]"
				
	var color_spell_option := func(opt: Wand.Option) -> String:
		var s := wand.get_spell(opt, book)
		if s == null:
			var name_str := opt.get_spell_name()
			var is_item_spell := Wand.is_item_place_spell(name_str)
			var color_str := ("#FFF" if opt.kind == Wand.Kind.REMOVE_ITEM or opt.kind == Wand.Kind.PLACE_ITEM or opt.kind == Wand.Kind.PLACE_PICKED or is_item_spell else "#333")
			if is_item_spell:
				name_str += opt.get_spell_params_desc(false)
			return "[color=%s]" % color_str + name_str + "[/color]"
		else:
			return color_spell.call(s)
		
		
	var build_desc := func(kd: String, title: String, option: Wand.Option) -> String:
		return kd + " [b]" + title + "[/b]: " + color_spell_option.call(option) + "\n"
		
	for k: PackedStringArray in wand.get_bound_keys():
		var s: Wand.Option = wand.keys[k]
		var kd := " " + GlobalData.controller.key_images(k, int(SIZE * 1.5) )
		match s.kind:
			Wand.Kind.FIRE:
				var colored_list := s.display_rotated_spells_list(color_spell_option)
				if not colored_list.is_empty(): 
					rich_text += kd + " [b]Cast[/b]: " + colored_list + "\n"
			Wand.Kind.FIRE_HOLD:
				var colored_list := s.display_rotated_spells_list(color_spell_option)
				if not colored_list.is_empty(): 
					rich_text += kd + " [b]Charge[/b]: " + colored_list + "\n"				
			Wand.Kind.RAPID_FIRE:
				var colored_list := s.display_rotated_spells_list(color_spell_option)
				if not colored_list.is_empty(): 
					rich_text += kd + " [b]Rapid[/b]: " + colored_list + "\n"
				
			Wand.Kind.PICK:
				var colored_list := s.display_rotated_spells_list(color_spell_option)
				if not colored_list.is_empty(): 
					rich_text += kd + " [b]Choose[/b]: " + colored_list + "\n"
			Wand.Kind.FIRE_PICKED:
				var spell := wand.get_spell(s, book)
				if spell != null:
					rich_text += build_desc.call(kd, "[i]Cast[/i]", s)
			Wand.Kind.FIRE_PICKED_HOLD:
				var spell := wand.get_spell(s, book)
				if spell != null:
					rich_text += build_desc.call(kd, "[i]Charge[/i]", s)
			Wand.Kind.FIRE_PICKED_RAPID:
				var spell := wand.get_spell(s, book)
				if spell != null:
					rich_text += build_desc.call(kd, "[i]Rapid[/i]", s)
					
			Wand.Kind.REMOVE_ITEM:
				rich_text += kd + " [b]Remove[/b]\n"
			Wand.Kind.PLACE_ITEM:
				var colored_list := s.display_rotated_spells_list(color_spell_option)
				if not colored_list.is_empty(): 
					rich_text += kd + " [b]Place[/b]: " + colored_list + "\n"
			Wand.Kind.PLACE_PICKED:
				var option := Globals.Ref.new(null)
				wand.get_spell(s, book, option)
				if option.data != null:
					rich_text += build_desc.call(kd, "[i]Place[/i]", option.data)
	
	rich_text += "[/font_size]"
	var old_text := wand_mapping.text
	wand_mapping.size = Vector2(($WandMappingPanel as Control).size.x, 0)
	($WandMappingPanel as Control).size.y = 0
	if old_text != rich_text:
		wand_mapping.text = rich_text
	if hud_settings != null and hud_settings.hide_wand_mappings:
		wand_mapping.visible = false
	else:
		wand_mapping.visible = rich_text != ("[font_size=%d][/font_size]" % SIZE)
	
	
#	await wand_mapping.finished
	wand_mapping.size.x = ($WandMappingPanel as Control).size.x
	($WandMappingPanel as Control).visible = wand_mapping.visible
	($WandMappingPanel as Control).size = wand_mapping.size
	($WandMappingPanel as Control).position.y = get_viewport_rect().size.y - 8 - wand_mapping.size.y
	# NOTE (HACK): Set again to make sure the panel size is correct after resizing the label
	($WandMappingPanel as Control).size.y = wand_mapping.size.y
		
func update_settings(settings: WorldSettings) -> void:
	hud_upgrades.upgrade_slots_refreshed(settings.upgrade_settings, settings)
	
	GlobalData.controller.switching_mode = hud_settings.key_display
	match hud_settings.key_display:
		HUDSettings.KeyDisplay.KEYBOARD:
			GlobalData.controller.last_input_type = Controller.InputType.KEYBOARD
		HUDSettings.KeyDisplay.CONTROLLER:
			GlobalData.controller.last_input_type = Controller.InputType.CONTROLLER
	
	wand_mapping.visible = not hud_settings.hide_wand_mappings
	notification_label.visible = not hud_settings.hide_notifications
	
	burning_bar.visible = not hud_settings.hide_status_effects
	freeze_bar.visible = not hud_settings.hide_status_effects
	wet_bar.visible = not hud_settings.hide_status_effects
	
	health_bar.visible = not hud_settings.hide_health_mana
	mana_bar.visible = not hud_settings.hide_health_mana
	
	cooldown_list.visible = cooldown_list.visible and not hud_settings.hide_cooldown_timings
	
	stats_view.visible = not hud_settings.hide_stats_view
	
	hud_upgrades.visible = hud_upgrades.visible and not hud_settings.hide_possible_upgrades
	
	player.cam.fov = settings.camera_settings.fov
	player.cam.far = settings.camera_settings.render_distance
	
	player.change_reticule_visible(hud_settings.hide_reticule)
	
	compass.visible = not settings.hud_settings.hide_compass
	
	objective_label.visible = not hud_settings.hide_collected_keys_label
	
	if cached_theme_color != hud_settings.theme_color or cached_theme_variation != hud_settings.theme_variation:
		var global_theme := load(ProjectSettings.get("gui/theme/custom") as String) as ThemeUI
		global_theme.change_tint_color(hud_settings.theme_color, hud_settings.theme_variation)
		update_theme_colors(hud_settings.theme_color, hud_settings.theme_variation)
		
	update_stats_view()
	update_wand_mappings()

func update_stats_view() -> void:
	if not stats_view.visible or world_settings == null:
		return
	
	var ws := world_settings.upgrade_settings
	var sv := stats_view
	sv.health.text = "%d%+d" % [ws.max_health(), ws.buff_health]
	sv.velocity.text = "%s%s" % [Globals.format_number_nearest_place(ws.max_v(), 1), Globals.format_number_nearest_place(ws.buff_v, 1, true)]
	sv.mana.text = "%d%+d" % [ws.max_mana(), ws.buff_mana]
	sv.attack.text = "%d%+d" % [ws.max_attack(), ws.buff_attack]
	sv.defence.text = "%d%+d" % [ws.max_defence(), ws.buff_defence]
	sv.crit_rate.text = "%s%%%s%%" % [Globals.format_number_nearest_place(player.buff_crit_rate.x, 1), Globals.format_number_nearest_place(player.buff_crit_rate.y, 1, true)]
	sv.crit_dmg.text = "%s%s" % [Globals.format_number_nearest_place(player.buff_crit_dmg.x, 1), Globals.format_number_nearest_place(player.buff_crit_dmg.y, 1, true)]
	sv.radius.text = "%s%s" % [Globals.format_number_nearest_place(ws.max_r(), 1), Globals.format_number_nearest_place(ws.buff_r, 1, true)]
	sv.duration.text = "%d%+d" % [ws.max_T(), ws.buff_T]
	sv.count.text = "%d%+d" % [ws.max_N(), ws.buff_N]
	sv.power.text = "%d%+d" % [ws.max_P(), ws.buff_P]
	sv.running_speed.text = "%d%+d" % [ws.max_running_speed(), ws.buff_running_speed]
	
	var v: Vector2 = Vector2.ZERO
	sv.fireDMG.text = "%d%%%+d" % [player.spell_modifier.get(Spell.Element.FIRE, v).y, player.spell_modifier.get(Spell.Element.FIRE, v).x]
	sv.fireRES.text = "%d%%%+d" % [player.damage_resistance.get(Spell.Element.FIRE, v).y, player.damage_resistance.get(Spell.Element.FIRE, v).x]
	sv.waterDMG.text = "%d%%%+d" % [player.spell_modifier.get(Spell.Element.WATER, v).y, player.spell_modifier.get(Spell.Element.WATER, v).x]
	sv.waterRES.text = "%d%%%+d" % [player.damage_resistance.get(Spell.Element.WATER, v).y, player.damage_resistance.get(Spell.Element.WATER, v).x]
	sv.rockDMG.text = "%d%%%+d" % [player.spell_modifier.get(Spell.Element.ROCK, v).y, player.spell_modifier.get(Spell.Element.ROCK, v).x]
	sv.rockRES.text = "%d%%%+d" % [player.damage_resistance.get(Spell.Element.ROCK, v).y, player.damage_resistance.get(Spell.Element.ROCK, v).x]
	sv.airDMG.text = "%d%%%+d" % [player.spell_modifier.get(Spell.Element.AIR, v).y, player.spell_modifier.get(Spell.Element.AIR, v).x]
	sv.airRES.text = "%d%%%+d" % [player.damage_resistance.get(Spell.Element.AIR, v).y, player.damage_resistance.get(Spell.Element.AIR, v).x]
	sv.iceDMG.text = "%d%%%+d" % [player.spell_modifier.get(Spell.Element.ICE, v).y, player.spell_modifier.get(Spell.Element.ICE, v).x]
	sv.iceRES.text = "%d%%%+d" % [player.damage_resistance.get(Spell.Element.ICE, v).y, player.damage_resistance.get(Spell.Element.ICE, v).x]
	sv.electricDMG.text = "%d%%%+d" % [player.spell_modifier.get(Spell.Element.ELECTRIC, v).y, player.spell_modifier.get(Spell.Element.ELECTRIC, v).x]
	sv.electricRES.text = "%d%%%+d" % [player.damage_resistance.get(Spell.Element.ELECTRIC, v).y, player.damage_resistance.get(Spell.Element.ELECTRIC, v).x]	
	

func update_selection_wheel_spells() -> void:
	selection_wheel.image_segments.clear()
	for spell_text in selection_wheel.segments:
		var spell := book.find_spell(spell_text)
		if spell != null:
			selection_wheel.image_segments[spell_text] = spell.create_thumbnail(Spell.ThumbnailSize.LARGE, image_preview_raws)

func update_pick_up_world_item_artifact(entity: ArtifactCube, a: Artifact, m: String) -> void:
	show_notification(bbcode_new_item(m), 10)
	if not GlobalData.game_settings.tutorials_shown.has(GameSettings.Tutorials.ARTIFACTS):
		show_message(GameSettings.Tutorials.ARTIFACTS, "[center][font_size=21]View 'Artifacts' in the menu to build your character[/font_size][/center]", INF)
		
func update_pick_up_world_item_spell(entity: SpellPaper, s: Spell, m: String) -> void:
	show_notification(bbcode_new_item(m), 10)
	if not GlobalData.game_settings.tutorials_shown.has(GameSettings.Tutorials.SPELLS):
		show_message(GameSettings.Tutorials.SPELLS, "[center][font_size=21]View 'Spells' in the menu to view and edit your spells[/font_size][/center]", INF)
	if not GlobalData.game_settings.tutorials_shown.has(GameSettings.Tutorials.WANDS):
		show_message(GameSettings.Tutorials.WANDS, "[center][font_size=21]View 'Wands' to assign spells to keys[/font_size][/center]", INF)
		
func update_pick_up_world_item_key(entity: KeyPrism, k: int, m: String) -> void: 
	show_notification(bbcode_new_item(m), 10)
	objective_label.text = "[right][font_size=24][color=#ffb500]%d [img=l,24x24, color=#ffb500]res://GUI/Images/key.svg[/img][/color][/font_size][/right]" % GDNavigator.popcnt(world_settings.player_keys)
	if not GlobalData.game_settings.tutorials_shown.has(GameSettings.Tutorials.KEYS):
		GlobalData.game_settings.mark_tutorial(GameSettings.Tutorials.KEYS)
		show_message(GameSettings.Tutorials.KEYS, "[center][font_size=21]Defeat more high level enemies in other biomes for more Keys", INF)

func update_pick_up_world_item_coin(entity: CoinDisc, s: int, m: String) -> void:
	show_notification(bbcode_new_item(m), 5)
	if not GlobalData.game_settings.tutorials_shown.has(GameSettings.Tutorials.COINS) and world_settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES):
		show_message(GameSettings.Tutorials.COINS, "[center][font_size=21]View 'Upgrades' in the menu to upgrade your character[/font_size][/center]", INF)

func update_pick_up_world_item_scroll_note(entity: ScrollNote, c: String, m: String) -> void:
	show_notification(bbcode_new_item(m), 10)
	if not GlobalData.game_settings.tutorials_shown.has(GameSettings.Tutorials.NOTES):
		show_message(GameSettings.Tutorials.NOTES, "[center][font_size=21]View 'Notes' in the menu to learn about the game[/font_size][/center]", INF)

func update_theme_colors(color: Color, variation: HUDSettings.ThemeKind) -> void:
	cached_theme_color = color
	cached_theme_variation = variation
	
	var list_theme := cooldown_list.get_theme_stylebox("panel") as StyleBoxFlat
	list_theme.border_color = Color(color, 0.5)
	
	var mapping_theme := wand_mapping_panel.get_theme_stylebox("panel") as StyleBoxFlat
	mapping_theme.border_color = list_theme.border_color

	var stats_theme := (stats_view.get_node("container") as Control).get_theme_stylebox("panel") as StyleBoxFlat
	stats_theme.border_color = list_theme.border_color

enum Indicator { NOTE, PAPER, CUBE }
func add_marker(id: String, indicator: Indicator, location: Vector2) -> void:
	var img := TextureRect.new()
	img.size = Vector2(16, 16)
	img.position = Vector2(0, 8)
	img.name = id
	match indicator:
		Indicator.NOTE: img.texture = preload("res://GUI/Images/scroll-note.svg")
		Indicator.PAPER: img.texture = preload("res://GUI/Images/scroll-paper.svg")
		Indicator.CUBE: img.texture = preload("res://GUI/Images/artifact-cube.svg")
	compass_markers.append(img)
	compass_marker_locations.append(location)
	compass.add_child(img)
	
func remove_marker(id: String) -> void:
	var index := -1
	for control in compass_markers:
		index += 1
		if control.name == id:
			break
			
	if index > -1:
		var marker := compass_markers[index]
		compass_markers.remove_at(index)
		compass_marker_locations.remove_at(index)
		marker.queue_free()

func update_compass_position(looking_angle: float, location: Vector3) -> void:
	var bounds := compass.size.x
	var offset := (looking_angle / PI * bounds * 0.5)
	var width := compass_n.size.x
	compass_n.position.x = fposmod(bounds * 1.0 + offset - width * 0.5, bounds)
	compass_e.position.x = fposmod(bounds * 0.25 + offset - width * 0.5, bounds)
	compass_s.position.x = fposmod(bounds * 0.5 + offset - width * 0.5, bounds)
	compass_w.position.x = fposmod(bounds * 0.75 + offset - width * 0.5, bounds)
	
	var loc2 := Vec2.xz(location)
	for i in compass_markers.size():
		var loc := compass_marker_locations[i]
		var control := compass_markers[i]
		var x := loc2.angle_to_point(loc) / PI * 0.5 - 0.25
		control.position.x = fposmod(bounds * x + offset - width * 0.5, bounds)
		control.modulate = Color(1, 1, 1, clampf(1.0 - loc2.distance_to(loc) / 1024.0, 0.0, 1.0))
	
	var max_x := 0.0
	var max_ratio := 0.0	
	if compass_n.position.x > max_x: max_x = compass_n.position.x; max_ratio = 1.0
	if compass_e.position.x > max_x: max_x = compass_e.position.x; max_ratio = 0.25
	if compass_s.position.x > max_x: max_x = compass_s.position.x; max_ratio = 0.5
	if compass_w.position.x > max_x: max_x = compass_w.position.x; max_ratio = 0.75
	
	if is_equal_approx(max_ratio, 1.0): compass_overflow.text = "N"
	if is_equal_approx(max_ratio, 0.25): compass_overflow.text = "E"
	if is_equal_approx(max_ratio, 0.5): compass_overflow.text = "S"
	if is_equal_approx(max_ratio, 0.75): compass_overflow.text = "W"
	
	compass_overflow.position.x = fposmod(bounds * max_ratio + offset - compass_overflow.size.x * 0.5 + compass_overflow.size.x, bounds) - compass_overflow.size.x
	
