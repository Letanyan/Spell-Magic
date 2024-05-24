class_name HUD
extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var burning_bar: TextureProgressBar = $BurningBar
@onready var freeze_bar: TextureProgressBar = $FreezeBar
@onready var wet_bar: TextureProgressBar = $WetBar

@onready var cooldown_list: ItemList = $CooldownList

@onready var wand_mapping: RichTextLabel = $WandMappingPanel/WandMapping

@onready var notification_label: RichTextLabel = $NotificationLabel
var notifications: Dictionary = {} # [String(Message)]int(seconds until expiration)

@onready var stats_view: StatsView = $StatsView

var cooldown_map: Dictionary
var cooldown_alert: Dictionary
var not_enough_mana_alert: float = 0.0

var world_settings: WorldSettings = null
var hud_settings: HUDSettings = null

var player: Player:
	set(value):
		player = value
		player.vital_update.connect(update_hud_with_vitals)
		update_hud_with_vitals(player.vitals)
		player.spell_was_cast.connect(spell_was_cast)
		player.spell_was_disallowed.connect(spell_was_disallowed)

var wand: Wand: set = set_wand
		
var book: MagicBook:
	set(value):
		book = value
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	($SpellCooldownTimer as Timer).start()
	SignalBus.pick_up_world_item_artifact.connect(func(a: Artifact, m: String) -> void: show_notification(bbcode_new_item(m), 5))
	SignalBus.pick_up_world_item_spell.connect(func(s: Spell, m: String) -> void: show_notification(bbcode_new_item(m), 5))
	
func set_wand(value: Wand) -> void:
	if wand != null:
		wand.spell_disallowed.disconnect(spell_was_disallowed)
		wand.action_updated.disconnect(update_wand_mappings)
		wand.spell_updated.disconnect(update_wand_mappings)
		wand.picked_spell_changed.disconnect(update_wand_mappings)
		wand.key_up.disconnect(update_wand_mappings)
		wand.key_down.disconnect(update_wand_mappings)
	wand = value
	wand.spell_disallowed.connect(spell_was_disallowed)
	wand.action_updated.connect(update_wand_mappings)
	wand.spell_updated.connect(update_wand_mappings)
	wand.picked_spell_changed.connect(update_wand_mappings)
	wand.key_up.connect(update_wand_mappings)
	wand.key_down.connect(update_wand_mappings)
	update_wand_mappings()
	update_spell_cooldowns()

func update_hud_with_vitals(vitals: Vitals) -> void:
	health_bar.value = vitals.health.value
	health_bar.max_value = vitals.health.max_value
	mana_bar.value = vitals.mana.value
	mana_bar.max_value = vitals.mana.max_value
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
	for s: String in cooldown_map:
		if i >= cooldown_list.item_count:
			break
		if s == spell.name:
			cooldown_list.select(i, false)
			cooldown_alert[s] = Time.get_unix_time_from_system()
		i += 1
	update_spell_cooldowns()
	
func not_enough_mana_for_spell(spell: Spell) -> void:
	not_enough_mana_alert = Time.get_unix_time_from_system()
	var style: StyleBoxFlat = load("res://GUI/HUD_progress_bar_bg.tres")
	style.bg_color = Color(1, 0, 0.3, 1)
	style.border_color = Color(1, 0, 0.3, 1)
	mana_bar.add_theme_stylebox_override("background", style)
	
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
		MagicBook.DisallowSpellReason.COUNT:
			show_notification(bbcode_error("'%s' requires N %d upgrade" % [spell.name, spell.count]), 5)
		MagicBook.DisallowSpellReason.DURATION:
			show_notification(bbcode_error("'%s' requires T %.1f upgrade" % [spell.name, spell.duration]), 5)
		MagicBook.DisallowSpellReason.RADIUS:
			show_notification(bbcode_error("'%s' requires r %.1f upgrade" % [spell.name, spell.radius]), 5)
		MagicBook.DisallowSpellReason.ACTIVE:
			show_notification(bbcode_error("'%s' is not active in magic book" % [spell.name]), 5)
	
func spell_was_cast(s: Spell) -> void:
	var t := Time.get_unix_time_from_system()
	cooldown_map[s.name] = t
	var ns := s.chain
	while ns != null:
		cooldown_map[ns.name] = t
		ns = ns.chain
	update_spell_cooldowns()
	
func get_spell(spell_name: String) -> Spell:
	for s in book.spells:
		if s.name == spell_name:
			return s
	return null
	
func update_spell_cooldowns() -> void:
	if book == null:
		return
	
	var i := 0
	var to_remove := []
	for s: String in cooldown_map:
		var spell := get_spell(s)
		var used := book.last_use.get(s, 0.0) as float
		if spell == null:
			continue
		var wait := spell.cooldown - (Time.get_unix_time_from_system() - used)
		if wait < 0.0:
			to_remove.append(i)
		var description := " " + s + " - " +("%d" % wait) + "s"
		if i < cooldown_list.item_count:
			cooldown_list.set_item_text(i, description)
		else:
			cooldown_list.add_item(description)
		if Time.get_unix_time_from_system() - cooldown_alert.get(s, 0) > 3:
			cooldown_list.deselect(i)
		i += 1
		
	i = to_remove.size() - 1
	while i >= 0:
		var idx := to_remove[i] as int
		cooldown_list.remove_item(idx)
		i -= 1
		
	cooldown_list.visible = not((hud_settings != null and hud_settings.hide_cooldown_timings) or cooldown_list.item_count == 0) 
		
	var mana_alert_time := Time.get_unix_time_from_system() - not_enough_mana_alert
	if not_enough_mana_alert != 0.0 and mana_alert_time > 5:
		var style: StyleBoxFlat = load("res://GUI/HUD_progress_bar_bg.tres")
		style.bg_color = Color(1, 1, 1, 1)
		mana_bar.add_theme_stylebox_override("background", style)
		not_enough_mana_alert = 0.0
		
	draw_notifications()
	
		
func show_notification(message: String, duration: float) -> void:
	notifications[message] = Time.get_unix_time_from_system() + duration
	draw_notifications()
	
func draw_notifications() -> void:
	var to_erase := []
	var count := 0
	var result: String = "[right]\n"
	for n: String in notifications:
		var d := notifications[n] as float
		if Time.get_unix_time_from_system() >= d:
			to_erase.append(n)
		else:
			notifications[n] -= 1
			count += 1
			result += n + "\n"
		if count >= 4:
			break
			
	result += "[/right]"
	notification_label.text = result
	for n: String in to_erase:
		notifications.erase(n)
		
func update_wand_mappings() -> void:
	const SIZE := 16
	var rich_text := ""
	rich_text = "[font_size=%d]" % SIZE
	
	if (hud_settings != null and not hud_settings.hide_wand_modifier_hints) and wand.mods.size() > 0:
		var modifier_keys := ""
		for m: String in wand.mods:
			modifier_keys += GlobalData.controller.key_images([m]) + " "
		rich_text += " Modifiers: " + modifier_keys + "\n"
		
	var build_desc := func(kd: String, title: String, spell: String) -> String:
		var reason := book.can_use_spell_with_name(spell)
		if reason == MagicBook.DisallowSpellReason.NONE:
			var s := book.find_spell(spell)
			if player.vitals.mana.value < s.actual_mana_cost():
				reason = MagicBook.DisallowSpellReason.MANA
		match reason:
			MagicBook.DisallowSpellReason.NONE:
				return kd + " [b]" + title +  "[/b]: " + spell + "\n"
			MagicBook.DisallowSpellReason.COOLDOWN:
				return kd + " [b]" + title + "[/b]: [color=#F05]" + spell + "[/color]\n"
			MagicBook.DisallowSpellReason.MANA:
				return kd + " [b]" + title + "[/b]: [color=#A0A]" + spell + "[/color]\n"
			MagicBook.DisallowSpellReason.ACTIVE:
				return kd + " [b]" + title + "[/b]: [color=#222]" + spell + "[/color]\n"
			MagicBook.DisallowSpellReason.COUNT:
				return kd + " [b]" + title + "[/b]: [color=#F700FF]" + spell + "[/color]\n"
			MagicBook.DisallowSpellReason.POWER:
				return kd + " [b]" + title + "[/b]: [color=#0008FF]" + spell + "[/color]\n"
			MagicBook.DisallowSpellReason.DURATION:
				return kd + " [b]" + title + "[/b]: [color=#00FF08]" + spell + "[/color]\n"
			MagicBook.DisallowSpellReason.RADIUS:
				return kd + " [b]" + title + "[/b]: [color=#7700FF]" + spell + "[/color]\n"
			_:
				return kd + " [b]" + title + "[/b]: [color=#F50]" + spell + "[/color]\n"
		
	for k: PackedStringArray in wand.get_bound_keys():
		var s: Wand.Option = wand.keys[k]
		var kd := " " + GlobalData.controller.key_images(k, int(SIZE * 1.5) )
		match s.kind:
			Wand.Kind.FIRE:
				if not s.spell.is_empty():
					rich_text += build_desc.call(kd, "Cast", s.spell[0])
			Wand.Kind.FIRE_HOLD:
				if not s.spell.is_empty(): 
					rich_text += build_desc.call(kd, "Charge", s.spell[0])					
			Wand.Kind.RAPID_FIRE:
				if not s.spell.is_empty():
					rich_text += build_desc.call(kd, "Rapid", s.spell[0])
				
			Wand.Kind.PICK:
				if not s.spell.is_empty(): 
					rich_text += kd + " [b]Choose[/b]: " + s.display_rotated_spells_list(book) + "\n"
			Wand.Kind.FIRE_PICKED:
				if not wand.picked.is_empty():
					rich_text += build_desc.call(kd, "Cast", "[i]" + wand.picked + "[/i]")
			Wand.Kind.FIRE_PICKED_HOLD:
				if not wand.picked.is_empty():
					rich_text += build_desc.call(kd, "Charge", "[i]" + wand.picked + "[/i]")
			Wand.Kind.RAPID_SELECT:
				if not wand.picked.is_empty():
					rich_text += build_desc.call(kd, "Rapid", "[i]" + wand.picked + "[/i]")
	
	rich_text += "[/font_size]"
	wand_mapping.text = ""
	wand_mapping.size = Vector2(($WandMappingPanel as Control).size.x, 0)
	($WandMappingPanel as Control).size.y = 0
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
	world_settings = settings
	hud_settings = settings.hud_settings
	
	wand_mapping.visible = not hud_settings.hide_wand_mappings
	notification_label.visible = not hud_settings.hide_notifications
	
	burning_bar.visible = not hud_settings.hide_status_effects
	freeze_bar.visible = not hud_settings.hide_status_effects
	wet_bar.visible = not hud_settings.hide_status_effects
	
	health_bar.visible = not hud_settings.hide_health_mana
	mana_bar.visible = not hud_settings.hide_health_mana
	
	cooldown_list.visible = cooldown_list.visible and not hud_settings.hide_cooldown_timings
	
	stats_view.visible = not hud_settings.hide_stats_view
	
	player.cam.fov = settings.camera_settings.fov
	
	player.change_reticule_visible(hud_settings.hide_reticule)
		
	update_stats_view()
	update_wand_mappings()

func update_stats_view() -> void:
	if not stats_view.visible or world_settings == null:
		return
	
	var ws := world_settings.upgrade_settings
	var sv := stats_view
	sv.health.text = "%d+%d" % [ws.max_health, ws.buff_health]
	sv.velocity.text = "%.1f+%.1f" % [ws.max_v, ws.buff_v]
	sv.mana.text = "%d+%d" % [ws.max_mana, ws.buff_mana]
	sv.attack.text = "%d+%d" % [ws.max_attack, ws.buff_attack]
	sv.defence.text = "%d+%d" % [ws.max_defence, ws.buff_defence]
	sv.r.text = "%.1f+%.1f" % [ws.max_r, ws.buff_r]
	sv.T.text = "%d+%d" % [ws.max_T, ws.buff_T]
	sv.N.text = "%d+%d" % [ws.max_N, ws.buff_N]
	sv.P.text = "%d+%d" % [ws.max_P, ws.buff_P]
	sv.S.text = "%.1f+%.1f" % [ws.max_running_speed, ws.buff_running_speed]
	
	var v: Vector2 = Vector2.ZERO
	sv.fireDMG.text = "%d%%+%d" % [player.spell_modifier.get(Spell.Element.FIRE, v).y, player.spell_modifier.get(Spell.Element.FIRE, v).x]
	sv.fireRES.text = "%d%%+%d" % [player.damage_resistance.get(Spell.Element.FIRE, v).y, player.damage_resistance.get(Spell.Element.FIRE, v).x]
	sv.waterDMG.text = "%d%%+%d" % [player.spell_modifier.get(Spell.Element.WATER, v).y, player.spell_modifier.get(Spell.Element.WATER, v).x]
	sv.waterRES.text = "%d%%+%d" % [player.damage_resistance.get(Spell.Element.WATER, v).y, player.damage_resistance.get(Spell.Element.WATER, v).x]
	sv.rockDMG.text = "%d%%+%d" % [player.spell_modifier.get(Spell.Element.ROCK, v).y, player.spell_modifier.get(Spell.Element.ROCK, v).x]
	sv.rockRES.text = "%d%%+%d" % [player.damage_resistance.get(Spell.Element.ROCK, v).y, player.damage_resistance.get(Spell.Element.ROCK, v).x]
	sv.airDMG.text = "%d%%+%d" % [player.spell_modifier.get(Spell.Element.AIR, v).y, player.spell_modifier.get(Spell.Element.AIR, v).x]
	sv.airRES.text = "%d%%+%d" % [player.damage_resistance.get(Spell.Element.AIR, v).y, player.damage_resistance.get(Spell.Element.AIR, v).x]
	sv.iceDMG.text = "%d%%+%d" % [player.spell_modifier.get(Spell.Element.ICE, v).y, player.spell_modifier.get(Spell.Element.ICE, v).x]
	sv.iceRES.text = "%d%%+%d" % [player.damage_resistance.get(Spell.Element.ICE, v).y, player.damage_resistance.get(Spell.Element.ICE, v).x]
	sv.electricDMG.text = "%d%%+%d" % [player.spell_modifier.get(Spell.Element.ELECTRIC, v).y, player.spell_modifier.get(Spell.Element.ELECTRIC, v).x]
	sv.electricRES.text = "%d%%+%d" % [player.damage_resistance.get(Spell.Element.ELECTRIC, v).y, player.damage_resistance.get(Spell.Element.ELECTRIC, v).x]
	
