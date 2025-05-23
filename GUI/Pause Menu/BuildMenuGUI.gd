class_name BuildMenuGUI
extends Control

var settings: WorldSettings:
	set(value):
		settings = value
		update_settings()
var projectiles_in_world: Array[SpellBody] = []
var items_in_world: Array[WorldItem] = []
@onready var projectiles_in_world_list: ItemList = $ProjectilesInWorld
@onready var projectile_name: LineEdit = $ProjectileName
@onready var items_in_world_list: ItemList = $ItemsInWorld
@onready var item_name: LineEdit = $ItemName

@onready var deck_building: CheckBox = $DeckBuilding
@onready var shop_upgrades: CheckBox = $ShopUpgrades
@onready var respawn: CheckBox = $Respawn
@onready var respawn_upgrades: CheckBox = $RespawnUpgrades
@onready var respawn_artifacts: CheckBox = $RespawnArtifacts
@onready var respawn_spells: CheckBox = $RespawnSpells
@onready var respawn_coins: CheckBox = $RespawnCoins


func _ready() -> void:
	SignalBus.spell_added_to_world.connect(spell_added_into_world)
	SignalBus.spell_removed_from_world.connect(spell_removed_from_world)
	SignalBus.item_added_to_world.connect(item_added_into_world)
	SignalBus.item_removed_from_world.connect(item_removed_from_world)
	
func update_settings() -> void:
	deck_building.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.SPELL_DECK_BUILDING))
	shop_upgrades.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES))
	respawn.set_pressed_no_signal(settings.game_mode_settings.mode == GameModeSettings.GameMode.RESPAWN)
	respawn_artifacts.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_ARTIFACTS))
	respawn_upgrades.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_UPGRADES))
	respawn_spells.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS))
	respawn_coins.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_COINS))
	
func spell_added_into_world(projectile: SpellBody) -> void:
	if projectile.spell.is_infinite:
		projectiles_in_world.append(projectile)
		update_projectile_list()
	
func spell_removed_from_world(projectile: SpellBody) -> void:
	var pidx := -1
	for i in projectiles_in_world.size():
		var proj := projectiles_in_world[pidx]
		if proj == projectile:
			pidx = i
			break
			
	if pidx != -1:
		projectiles_in_world.remove_at(pidx)
	update_projectile_list()
		
func update_projectile_list() -> void:
	projectiles_in_world_list.clear()
	for p in projectiles_in_world:
		projectiles_in_world_list.add_item(p.name)

func _on_rename_projectile_pressed() -> void:
	var selected := projectiles_in_world_list.get_selected_items()
	if selected.is_empty():
		return
		
	var idx := selected[0]
	projectiles_in_world[idx].name = projectile_name.text
	update_projectile_list()


func _on_delete_projectile_pressed() -> void:
	var selected := projectiles_in_world_list.get_selected_items()
	if selected.is_empty():
		return
	var idx := selected[0]
	
	var proj := projectiles_in_world[idx]
	proj.expired = true
	proj.spell.is_infinite = false
	projectiles_in_world.remove_at(idx)
	projectile_name.text = ""
	update_projectile_list()

func delete_projectile(projectile: SpellBody) -> void:
	var idx := -1
	for i in projectiles_in_world.size():
		var proj := projectiles_in_world[i]
		if proj == projectile:
			idx = i
			break
			
	if idx != -1:
		var proj := projectiles_in_world[idx]
		proj.expired = true
		proj.spell.is_infinite = false
		projectiles_in_world.remove_at(idx)
		projectile_name.text = ""
		update_projectile_list()

func _on_spells_in_world_item_selected(index: int) -> void:
	var proj := projectiles_in_world[index]
	projectile_name.text = proj.name

func item_added_into_world(item: WorldItem) -> void:
	items_in_world.append(item)
	update_item_list()
	
func item_removed_from_world(item: WorldItem) -> void:
	var pidx := -1
	for i in items_in_world.size():
		var it := items_in_world[pidx]
		if item == it:
			pidx = i
			break
			
	if pidx != -1:
		items_in_world.remove_at(pidx)
	update_item_list()
		
func update_item_list() -> void:
	items_in_world_list.clear()
	var i := 0
	for p in items_in_world:
		items_in_world_list.add_item(p.name)
		match p.kind:
			World.Item.SPELL:
				items_in_world_list.set_item_tooltip(i, (p as SpellPaper).spell.name)
			World.Item.HEALTH:
				items_in_world_list.set_item_tooltip(i, "Amount: %d%%" % ceili((p as RedCross).health * 100))
			World.Item.COIN:
				items_in_world_list.set_item_tooltip(i, "Amount: " + Globals.format_number_nearest_place((p as CoinDisc).amount))
		i += 1

func _on_rename_item_pressed() -> void:
	var selected := items_in_world_list.get_selected_items()
	if selected.is_empty():
		return
		
	var idx := selected[0]
	items_in_world[idx].name = item_name.text
	update_item_list()


func _on_delete_item_pressed() -> void:
	var selected := items_in_world_list.get_selected_items()
	if selected.is_empty():
		return
	var idx := selected[0]
	
	var item := items_in_world[idx]
	item.queue_free()
	items_in_world.remove_at(idx)
	projectile_name.text = ""
	update_item_list()

func delete_item(item: WorldItem) -> void:
	var idx := -1
	for i in items_in_world.size():
		var it := items_in_world[i]
		if it == item:
			idx = i
			break
			
	if idx != -1:
		var it := items_in_world[idx]
		it.queue_free()
		items_in_world.remove_at(idx)
		item_name.text = ""
		update_item_list()

func _on_items_in_world_item_selected(index: int) -> void:
	var it := items_in_world[index]
	item_name.text = it.name


func save(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/level_build.json" % (world_name), FileAccess.WRITE)
	
	var projectiles := {}
	for proj in projectiles_in_world:
		if proj.spell.is_infinite:
			projectiles[proj.name] = {"spell": proj.spell.name, "vars": proj.fixed_vars.export_dict(), "exprs": proj.expression_vars.export_dict()}
			
	var items := {}
	for item in items_in_world:
		var dict := {}
		item.save_to_dict(dict)
		items[item.name] = dict
		
	var result := {}
	result["projectiles"] = projectiles
	result["items"] = items 
		
	file.store_var(result)

func read(world_name: String, book: MagicBook, caster: SpellCaster) -> void:
	var file := FileAccess.open("user://worlds/%s/level_build.json" % (world_name), FileAccess.READ)
	if file == null:
		projectiles_in_world = []
		items_in_world = []
		return
	var data := file.get_var() as Dictionary
	if data == null:
		projectiles_in_world = []
		items_in_world = []
		return
		
	projectiles_in_world = []
	var projectiles := data.get("projectiles", {}) as Dictionary
	for key: String in projectiles:
		var info := projectiles[key] as Dictionary
		var spell := book.find_spell(info["spell"] as String).duplicate()
		var proj := SpellBuffer.get_projectile(spell.element)
		proj.fixed_vars = Vars.new()
		proj.fixed_vars.import_dict(info["vars"] as Dictionary)
		proj.expression_vars = Vars.new()
		proj.expression_vars.import_dict(info.get("exprs", {}) as Dictionary)
		proj.spell = spell
		proj.origin_spell_caster = caster
		caster.particles.append(proj)
		projectiles_in_world.append(proj)
		
	items_in_world = []
	var items := data.get("items", {}) as Dictionary
	for key: String in items:
		var info := items[key] as Dictionary
		var item: WorldItem = null
		match info.get("kind", 0):
			World.Item.SPELL:
				item = SpellPaper.make()
				item.load_from_dict(info)
			World.Item.HEALTH:
				item = RedCross.make()
				item.load_from_dict(info)
			World.Item.COIN:
				item = CoinDisc.make()
				item.load_from_dict(info)
				
		if item != null:				
			items_in_world.append(item)
			
	update_item_list()
	update_projectile_list()


func _on_deck_building_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		settings.game_mode_settings.flags |= GameModeSettings.SPELL_DECK_BUILDING
	else:
		settings.game_mode_settings.flags &= ~GameModeSettings.SPELL_DECK_BUILDING

func _on_shop_upgrades_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		settings.game_mode_settings.flags |= GameModeSettings.SHOP_FOR_UPGRADES
	else:
		settings.game_mode_settings.flags &= ~GameModeSettings.SHOP_FOR_UPGRADES


func _on_respawn_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		settings.game_mode_settings.mode = GameModeSettings.GameMode.RESPAWN
	else:
		settings.game_mode_settings.mode = GameModeSettings.GameMode.PERMADEATH
	
	
func _on_respawn_upgrades_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		settings.game_mode_settings.flags |= GameModeSettings.RESPAWN_WITH_UPGRADES
	else:
		settings.game_mode_settings.flags &= ~GameModeSettings.RESPAWN_WITH_UPGRADES


func _on_respawn_artifacts_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		settings.game_mode_settings.flags |= GameModeSettings.RESPAWN_WITH_ARTIFACTS
	else:
		settings.game_mode_settings.flags &= ~GameModeSettings.RESPAWN_WITH_ARTIFACTS


func _on_respawn_spells_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		settings.game_mode_settings.flags |= GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS
	else:
		settings.game_mode_settings.flags &= ~GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS


func _on_respawn_coins_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		settings.game_mode_settings.flags |= GameModeSettings.RESPAWN_WITH_COINS
	else:
		settings.game_mode_settings.flags &= ~GameModeSettings.RESPAWN_WITH_COINS
