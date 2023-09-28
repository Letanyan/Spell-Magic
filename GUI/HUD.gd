class_name HUD
extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var burning_bar: TextureProgressBar = $BurningBar
@onready var freeze_bar: TextureProgressBar = $FreezeBar
@onready var wet_bar: TextureProgressBar = $WetBar

@onready var cooldown_list: ItemList = $CooldownList

@onready var wand_mapping: ItemList = $WandMapping

@onready var notification_label: RichTextLabel = $NotificationLabel
var notifications: Dictionary = {} # Message -> Expire after n seconds

var cooldown_map: Dictionary
var cooldown_alert: Dictionary
var not_enough_mana_alert: float = 0.0

var hud_settings: HUDSettings = null

var player: Player:
	set(value):
		player = value
		player.vital_update.connect(update_hud_with_vitals)
		update_hud_with_vitals(player.vitals)
		player.spell_was_cast.connect(spell_was_cast)

var wand: Wand: set = set_wand
		
var book: MagicBook:
	set(value):
		book = value
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SpellCooldownTimer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func set_wand(value: Wand):
	wand = value
	wand.spell_disallowed.connect(spell_was_disallowed)
	wand.action_updated.connect(update_wand_mappings)
	wand.spell_updated.connect(update_wand_mappings)
	wand.picked_spell_changed.connect(update_wand_mappings)
	wand.key_up.connect(update_wand_mappings)
	wand.key_down.connect(update_wand_mappings)
	update_wand_mappings()
	update_spell_cooldowns()

func update_hud_with_vitals(vitals: Vitals):
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

func spell_on_cooldown(spell: Spell):
	var i := 0
	for s in cooldown_map:
		if i >= cooldown_list.item_count:
			break
		if s == spell.name:
			cooldown_list.select(i, false)
			cooldown_alert[s] = Time.get_unix_time_from_system()
		i += 1
	update_spell_cooldowns()
	
func not_enough_mana_for_spell(spell: Spell):
	not_enough_mana_alert = Time.get_unix_time_from_system()
	var style: StyleBoxFlat = load("res://GUI/HUD_progress_bar_bg.tres")
	style.bg_color = Color(1, 0, 0.3, 1)
	style.border_color = Color(1, 0, 0.3, 1)
	mana_bar.add_theme_stylebox_override("background", style)
	
func bbcode(message: String, font_size: int = 18, color: String = "#F05", outline_color: String = "#000", outline_size: int = 4) -> String:
	return "[outline_color=%s][outline_size=%d][color=%s][font_size=%d]%s[/font_size][/color][/outline_size][/outline_color]" % [outline_color, outline_size, color, font_size, message]
	
	
func spell_was_disallowed(spell: Spell, reason: MagicBook.DisallowSpellReason):
	match reason:
		MagicBook.DisallowSpellReason.COOLDOWN:
			spell_on_cooldown(spell)
			show_notification(bbcode("'%s' is on cooldown" % spell.name), 5)	
		MagicBook.DisallowSpellReason.MANA:
			not_enough_mana_for_spell(spell)
			show_notification(bbcode("'%s' requires M %.1f" % [spell.name, spell.actual_mana_cost()]), 5)		
		MagicBook.DisallowSpellReason.POWER:
			show_notification(bbcode("'%s' requires P %d upgrade" % [spell.name, spell.power]), 5)
		MagicBook.DisallowSpellReason.COUNT:
			show_notification(bbcode("'%s' requires N %d upgrade" % [spell.name, spell.count]), 5)
		MagicBook.DisallowSpellReason.DURATION:
			show_notification(bbcode("'%s' requires T %.1f upgrade" % [spell.name, spell.duration]), 5)
	
func spell_was_cast(s: Spell):
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
	
func update_spell_cooldowns():
	if book == null:
		return
	
	var i := 0
	var to_remove := []
	for s in cooldown_map:
		var spell := get_spell(s)
		var used = book.last_use.get(s, 0.0)
		if spell == null:
			continue
		var wait = spell.cooldown - (Time.get_unix_time_from_system() - used)
		if wait < 0.0:
			to_remove.append(i)
		var description = " " + s + " - " +("%d" % wait) + "s"
		if i < cooldown_list.item_count:
			cooldown_list.set_item_text(i, description)
		else:
			cooldown_list.add_item(description)
		if Time.get_unix_time_from_system() - cooldown_alert.get(s, 0) > 3:
			cooldown_list.deselect(i)
		i += 1
		
	i = to_remove.size() - 1
	while i >= 0:
		var idx = to_remove[i]
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
	
		
func show_notification(message: String, duration: int):
	notifications[message] = duration
	draw_notifications()
	
func draw_notifications():
	var to_erase := []
	var count := 0
	var result: String = "[right]\n"
	for n in notifications:
		var d = notifications[n]
		if d <= 0:
			to_erase.append(n)
		else:
			notifications[n] -= 1
			count += 1
			result += n + "\n"
		if count >= 4:
			break
			
	result += "[/right]"
	notification_label.text = result
	for n in to_erase:
		notifications.erase(n)
		
func update_wand_mappings():
	wand_mapping.clear()
	
	if (hud_settings != null and not hud_settings.hide_wand_modifier_hints) and wand.mods.size() > 0:
		var modifier_keys := ""
		for m in wand.mods:
			modifier_keys += Wand.key_description([m]) + " "
		wand_mapping.add_item(modifier_keys)
	
	for k in wand.get_bound_keys():
		var s: Wand.Option = wand.keys[k]
		var kd = Wand.key_description(k)
		match s.kind:
			Wand.Kind.FIRE:
				wand_mapping.add_item(kd + " > " + ("" if s.spell.is_empty() else s.spell[0]))
			Wand.Kind.FIRE_HOLD:
				wand_mapping.add_item(kd + " -> " + ("" if s.spell.is_empty() else s.spell[0]))
			Wand.Kind.RAPID_FIRE:
				wand_mapping.add_item(kd + " >> " + ("" if s.spell.is_empty() else s.spell[0]))
				
			Wand.Kind.PICK:
				wand_mapping.add_item(kd + " : (" + ",".join(s.spell) + ")")
			Wand.Kind.FIRE_PICKED:
				wand_mapping.add_item(kd + " :> " + wand.picked)
			Wand.Kind.FIRE_PICKED_HOLD:
				wand_mapping.add_item(kd + " :-> " + wand.picked)
			Wand.Kind.RAPID_SELECT:
				wand_mapping.add_item(kd + " :>> " + wand.picked)
	
	if hud_settings != null and hud_settings.hide_wand_mappings:
		wand_mapping.visible = false
	else:
		wand_mapping.visible = wand_mapping.item_count != 0
		
func update_settings(settings: WorldSettings):
	hud_settings = settings.hud_settings
	
	wand_mapping.visible = not hud_settings.hide_wand_mappings
	notification_label.visible = not hud_settings.hide_notifications
	
	burning_bar.visible = not hud_settings.hide_status_effects
	freeze_bar.visible = not hud_settings.hide_status_effects
	wet_bar.visible = not hud_settings.hide_status_effects
	
	health_bar.visible = not hud_settings.hide_health_mana
	mana_bar.visible = not hud_settings.hide_health_mana
	
	cooldown_list.visible = cooldown_list.visible and not hud_settings.hide_cooldown_timings
		
	update_wand_mappings()
