class_name BuildMenuGUI
extends Control

var settings: WorldSettings:
	set(value):
		settings = value
		update_settings()
var player: Player = null
var projectiles_in_world: Array[SpellBody] = []
var items_in_world: Array[WorldItem] = []
var item_flag_state: Array[int] = []
var current_flags_in_world: Array[Flag] = []
var enemies_in_world: Array[Enemy] = []
var enemy_flag_state: Array[int] = []
var current_enemies_in_world: Array[Enemy] = []
var base_upgrades: UpgradeSettings = null
var base_artifacts: Artifacts = null
var base_position := Vector3.ZERO
var base_camera := Vector3.ZERO
var pick_up_stack: Array[WorldItem] = []

@onready var desc_edit: LineEdit = $DescEdit
@onready var share_online: CheckBox = $ShareOnline
@onready var username_edit: LineEdit = $Username

@onready var projectiles_in_world_list: ItemList = $ProjectilesInWorld
@onready var projectile_name: LineEdit = $ProjectileName
@onready var items_in_world_list: ItemList = $ItemsInWorld
@onready var item_name: LineEdit = $ItemName
@onready var enemies_in_world_list: ItemList = $EnemiesInWorld
@onready var enemies_name: LineEdit = $EnemiesName

@onready var deck_building: CheckBox = $"SettingsTabBar/Game Settings/DeckBuilding"
@onready var shop_upgrades: CheckBox = $"SettingsTabBar/Game Settings/ShopUpgrades"
@onready var respawn: CheckBox = $"SettingsTabBar/Game Settings/Respawn"
@onready var respawn_upgrades: CheckBox = $"SettingsTabBar/Game Settings/RespawnUpgrades"
@onready var respawn_artifacts: CheckBox = $"SettingsTabBar/Game Settings/RespawnArtifacts"
@onready var respawn_spells: CheckBox = $"SettingsTabBar/Game Settings/RespawnSpells"
@onready var respawn_coins: CheckBox = $"SettingsTabBar/Game Settings/RespawnCoins"
@onready var world_radius_edit: SpinBox = $"SettingsTabBar/Game Settings/WorldRadiusEdit"
@onready var track_time: CheckBox = $"SettingsTabBar/Game Settings/TrackTime"
@onready var track_score: CheckBox = $"SettingsTabBar/Game Settings/TrackScore"

@onready var test_mode_button: Button = $TestMode

@onready var settings_tab: TabContainer = $SettingsTabBar
@onready var entity_settings_tab: TabContainer = $"SettingsTabBar/Entity Settings"

var entity_to_edit: Variant = null
@onready var note_edit: TextEdit = $"SettingsTabBar/Entity Settings/Note/NoteEdit"
@onready var spell_spell_edit: TextEdit = $"SettingsTabBar/Entity Settings/Spell/SpellEdit"
@onready var enemy_level_edit: LineEdit = $"SettingsTabBar/Entity Settings/Enemy/LevelEdit"
@onready var enemy_score_edit: LineEdit = $"SettingsTabBar/Entity Settings/Enemy/ScoreEdit"
@onready var enemy_flag_edit: LineEdit = $"SettingsTabBar/Entity Settings/Enemy/FlagEdit"
@onready var coin_amount_edit: LineEdit = $"SettingsTabBar/Entity Settings/Coin/AmountEdit"
@onready var health_amount_edit: LineEdit = $"SettingsTabBar/Entity Settings/Health/AmountEdit"
@onready var flag_tag_edit: LineEdit = $"SettingsTabBar/Entity Settings/Flag/TagEdit"

@onready var artifact_creator_panel: Panel = $ArtifactCreator
@onready var artifact_creator: ArtifactCreator = $ArtifactCreator/ArtifactCreator


signal test_mode_changed(is_editing: bool)
signal world_radius_changed(radius: float)

func _ready() -> void:
	#HttpLevels.got_level.connect(func(id: int, data: Dictionary) -> void: print(id, data))
	#HttpLevels.added_level.connect(func(id: int) -> void: HttpLevels.get_level(id))
	#HttpLevels.save_level("New Level", {"projectiles": {}, "items": {}})
	HttpLevels.added_level.connect(level_added)
	SignalBus.spell_added_to_world.connect(spell_added_into_world)
	SignalBus.spell_removed_from_world.connect(spell_removed_from_world)
	SignalBus.item_added_to_world.connect(item_added_into_world)
	SignalBus.item_removed_from_world.connect(item_removed_from_world)
	SignalBus.enemy_added_to_world.connect(enemy_added_into_world)
	SignalBus.enemy_removed_from_world.connect(enemy_removed_from_world)
	
	artifact_creator.cancelled.connect(func() -> void: artifact_creator_panel.hide())
	artifact_creator.artifact_edited.connect(edit_old_artifact)
	
	base_upgrades = UpgradeSettings.new()
	base_upgrades.reset_all_stats_to_default_values()
	base_artifacts = Artifacts.new()
	
	username_edit.text = GlobalData.game_settings.username
	share_online.disabled = HttpLevels.IS_WIP
	
	
	
func update_settings() -> void:
	deck_building.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.SPELL_DECK_BUILDING))
	shop_upgrades.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES))
	respawn.set_pressed_no_signal(settings.game_mode_settings.mode == GameModeSettings.GameMode.RESPAWN)
	respawn_artifacts.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_ARTIFACTS))
	respawn_upgrades.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_UPGRADES))
	respawn_spells.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS))
	respawn_coins.set_pressed_no_signal(settings.game_mode_settings.has_flag(GameModeSettings.RESPAWN_WITH_COINS))
	world_radius_edit.value = settings.world_radius
	track_time.set_pressed_no_signal(settings.track_time)
	track_score.set_pressed_no_signal(settings.track_score)
	
	
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
	open_entity_settings(EntitySettingsIndex.PROJECTILE, proj)

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
				items_in_world_list.set_item_tooltip(i, "Spell: " + (p as SpellPaper).spell.name)
			World.Item.HEALTH:
				items_in_world_list.set_item_tooltip(i, "Health: %d%%" % ceili((p as RedCross).health * 100))
			World.Item.COIN:
				items_in_world_list.set_item_tooltip(i, "Coin: " + Globals.format_number_nearest_place((p as CoinDisc).amount))
			World.Item.FLAG:
				items_in_world_list.set_item_tooltip(i, "Flag: %d" % (p as Flag).tag)
			World.Item.NOTE:
				items_in_world_list.set_item_tooltip(i, "Note: '%s'" % (p as ScrollNote).note_id.substr(0, mini(18, (p as ScrollNote).note_id.length())))
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

func delete_item(item: WorldItem, should_free: bool) -> void:
	var idx := -1
	for i in items_in_world.size():
		var it := items_in_world[i]
		if it == item:
			idx = i
			break
			
	if idx != -1:
		var it := items_in_world[idx]
		if should_free:
			it.queue_free()
		elif it.get_parent_node_3d() != null:
			it.get_parent_node_3d().remove_child(it)
		items_in_world.remove_at(idx)
		item_name.text = ""
		update_item_list()

func _on_items_in_world_item_selected(index: int) -> void:
	var it := items_in_world[index]
	item_name.text = it.name
	if it is ScrollNote:
		open_entity_settings(EntitySettingsIndex.NOTE, it)
	elif it is SpellPaper:
		open_entity_settings(EntitySettingsIndex.SPELL, it)
	elif it is ArtifactCube:
		open_entity_settings(EntitySettingsIndex.ARTIFACT, it)
	elif it is CoinDisc:
		open_entity_settings(EntitySettingsIndex.COIN, it)
	elif it is RedCross:
		open_entity_settings(EntitySettingsIndex.HEALTH, it)
	elif it is Flag:
		open_entity_settings(EntitySettingsIndex.FLAG, it)
	
func enemy_added_into_world(enemy: Enemy) -> void:
	enemies_in_world.append(enemy)
	update_enemies_list()
	
func enemy_removed_from_world(enemy: Enemy) -> void:
	var pidx := -1
	for i in enemies_in_world.size():
		var en := enemies_in_world[pidx]
		if en == enemy:
			pidx = i
			break
			
	if pidx != -1:
		enemies_in_world.remove_at(pidx)
	update_enemies_list()
		
func update_enemies_list() -> void:
	enemies_in_world_list.clear()
	var i := 0
	for e in enemies_in_world:
		enemies_in_world_list.add_item(e.name)
		enemies_in_world_list.set_item_tooltip(i, "Tag: %d" % e.level_flag)
		i += 1

func _on_rename_enemy_pressed() -> void:
	var selected := enemies_in_world_list.get_selected_items()
	if selected.is_empty():
		return
		
	var idx := selected[0]
	enemies_in_world[idx].name = enemies_name.text
	update_enemies_list()


func _on_delete_enemy_pressed() -> void:
	var selected := enemies_in_world_list.get_selected_items()
	if selected.is_empty():
		return
	var idx := selected[0]
	
	var en := enemies_in_world[idx]
	en.queue_free()
	enemies_in_world.remove_at(idx)
	enemies_name.text = ""
	update_enemies_list()

func delete_enemy(enemy: Enemy) -> void:
	var idx := -1
	for i in enemies_in_world.size():
		var en := enemies_in_world[i]
		if en == enemy:
			idx = i
			break
			
	if idx != -1:
		var en := enemies_in_world[idx]
		SignalBus.enemy_death.emit(en)
		enemies_in_world.remove_at(idx)
		enemies_name.text = ""
		update_enemies_list()

func _on_enemies_in_world_item_selected(index: int) -> void:
	var en := enemies_in_world[index]
	enemies_name.text = en.name
	open_entity_settings(EntitySettingsIndex.ENEMY, en)

func retrieve_enemies_based_on_flag_state() -> Array[Enemy]:
	if not current_enemies_in_world.is_empty():
		return current_enemies_in_world
	else:
		var current_max := 999999999
		if not enemy_flag_state.is_empty():
			current_max = enemy_flag_state[enemy_flag_state.size() - 1]
		var max_below_current := -1
		for enemy in current_enemies_in_world if not current_enemies_in_world.is_empty() else enemies_in_world:
			if enemy.level_flag < current_max:
				max_below_current = maxi(max_below_current, enemy.level_flag)
		
		if max_below_current != current_max:
			enemy_flag_state.append(max_below_current)
		
		for enemy in enemies_in_world:
			if enemy.level_flag == max_below_current:
				current_enemies_in_world.append(enemy)
		
		return current_enemies_in_world

func retrieve_flags_based_on_flag_state() -> Array[Flag]:
	if not current_flags_in_world.is_empty():
		return current_flags_in_world
	else:
		var current_max := 999999999
		if not item_flag_state.is_empty():
			current_max = item_flag_state[item_flag_state.size() - 1]
		var max_below_current := -1
		if current_flags_in_world.is_empty():
			for item in items_in_world:
				if item is Flag and (item as Flag).tag < current_max:
					max_below_current = maxi(max_below_current, (item as Flag).tag)
		else:
			for flag in current_flags_in_world:
				if flag.tag < current_max:
					max_below_current = maxi(max_below_current, flag.tag)
		
		if max_below_current != current_max:
			item_flag_state.append(max_below_current)
			
		for item in items_in_world:
			if item is Flag and (item as Flag).tag == max_below_current:
				current_flags_in_world.append(item)
		
		return current_flags_in_world

func remove_current_enemy(enemy: Enemy) -> void:
	var i := -1
	for x in current_enemies_in_world:
		i += 1
		if x == enemy:
			break
	if i != -1:
		current_enemies_in_world.remove_at(i)
		
func remove_current_flag(flag: Flag) -> void:
	var i := -1
	for x in current_flags_in_world:
		i += 1
		if x == flag:
			break
	if i != -1:
		current_flags_in_world.remove_at(i)

func save(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/level_build.json" % (world_name), FileAccess.WRITE)	
	var dict := get_dict()
	file.store_var(dict)
	file.close()
	GlobalData.game_settings.username = username_edit.text
	
	if settings.is_shared_online != -1:
		HttpLevels.put_level(settings.is_shared_online, desc_edit.text, dict)
	
func get_dict() -> Dictionary:
	var projectiles := {}
	var spells := {}
	for proj in projectiles_in_world:
		if proj.spell.is_infinite:
			projectiles[proj.name] = {"spell": proj.spell.name, "vars": proj.fixed_vars.export_dict(), "exprs": proj.expression_vars.export_dict()}
			if not spells.has(proj.spell.name):
				spells[proj.spell.name] = proj.spell.save_dict()
			
	var items := {}
	for item in items_in_world:
		var dict := {}
		item.save_to_dict(dict)
		items[item.name] = dict
		
	var enemies := {}
	for enemy in enemies_in_world:
		enemies[enemy.name] = {"kind": World.Enemy.keys()[enemy.kind], "level": enemy.level, "position": enemy.position, "flag": enemy.level_flag, "score": enemy.level_score}
		
	var picked_up := {}
	for item in pick_up_stack:
		var dict := {}
		item.save_to_dict(dict)
		picked_up[item.name] = dict
		
	var result := {}
	result["projectiles"] = projectiles
	result["items"] = items
	result["spells"] = spells
	result["enemies"] = enemies
	result["name"] = settings.world_name
	result["username"] = GlobalData.game_settings.username
	result["desc"] = desc_edit.text
	result["settings"] = settings.game_mode_settings.save_dict()
	result["picked_up"] = picked_up
	
	var current_enemies: Array[String] = []
	var current_flags: Array[String] = []
	if settings.is_editing_level:
		base_upgrades.reset_all_stats_to_other(settings.upgrade_settings)
		base_artifacts.reset_from_other(player.artifacts)
		base_position = player.position
		base_camera = settings.player_camera
		item_flag_state.clear()
		enemy_flag_state.clear()
	else:
		for enemy in current_enemies_in_world:
			current_enemies.append(enemy.name)
		for flag in current_flags_in_world:
			current_flags.append(flag.name)
		
	result["base_upgrades"] = base_upgrades.save_dict()
	result["base_artifacts"] = base_artifacts.save_dict()
	result["item_flag_state"] = item_flag_state
	result["enemy_flag_state"] = enemy_flag_state
	result["base_position"] = base_position
	result["base_camera"] = base_camera
	result["current_enemies"] = current_enemies
	result["current_flags"] = current_flags
	
	return result

func read(world_name: String, caster: SpellCaster) -> void:
	var file := FileAccess.open("user://worlds/%s/level_build.json" % (world_name), FileAccess.READ)
	if file == null:
		projectiles_in_world = []
		items_in_world = []
		enemies_in_world = []
		return
	var data := file.get_var() as Dictionary
	if data == null:
		projectiles_in_world = []
		items_in_world = []
		enemies_in_world = []
		return
		
	load_data(data, caster)
		
func load_data(data: Dictionary, caster: SpellCaster) -> void:
	projectiles_in_world = []
	var projectiles := data.get("projectiles", {}) as Dictionary
	var spells := data.get("spells", {}) as Dictionary
	for key: String in projectiles:
		var info := projectiles[key] as Dictionary
		var spell := Spell.new()
		spell.load_dict(spells.get(info["spell"] as String, {}) as Dictionary)
		var proj := SpellBuffer.get_projectile(spell.element)
		proj.fixed_vars = Vars.new()
		proj.fixed_vars.import_dict(info["vars"] as Dictionary)
		proj.expression_vars = Vars.new()
		proj.expression_vars.import_dict(info.get("exprs", {}) as Dictionary)
		proj.spell = spell
		spell.setup_particle(proj, proj.fixed_vars)
		proj.origin_spell_caster = caster
		proj.caster_vitals = Vitals.custom_level
		proj.origin_node = player
		caster.particles.append(proj)
		projectiles_in_world.append(proj)
		
	var load_item := func(info: Dictionary) -> WorldItem:
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
			World.Item.FLAG:
				item = Flag.make()
				item.load_from_dict(info)
			World.Item.NOTE:
				item = ScrollNote.make()
				item.load_from_dict(info)
		return item
		
		
	items_in_world = []
	var items := data.get("items", {}) as Dictionary
	for key: String in items:
		var info := items[key] as Dictionary
		var item := load_item.call(info) as WorldItem
		if item != null:				
			items_in_world.append(item)
			
	pick_up_stack = []
	var picked_up := data.get("picked_up", {}) as Dictionary
	for key: String in picked_up:
		var info := picked_up[key] as Dictionary
		var item := load_item.call(info) as WorldItem
		if item != null:
			pick_up_stack.append(item)
 			
	var enemies := data.get("enemies", {}) as Dictionary
	for key: String in enemies:
		var enemy_data := enemies[key] as Dictionary
		var enemy_name := enemy_data.get("kind", "") as String
		var enemy_level := enemy_data.get("level", "1") as int
		var enemy_flag := enemy_data.get("flag", "1") as int
		var enemy_score := enemy_data.get("score", "0") as int
		var enemy_position := enemy_data.get("position", Vector3(0, 1000, 0)) as Vector3
		var enemy_kind := World.Enemy.NONE
		var idx := 0
		for kind: String in World.Enemy.keys():
			if enemy_name == kind:
				enemy_kind = idx as World.Enemy
				break
			idx += 1
		if enemy_kind != World.Enemy.NONE:
			var enemy := Population.generate_enemy(enemy_kind, player, enemy_position.x, enemy_position.y, enemy_position.z, enemy_level)
			enemy.level_flag = enemy_flag
			enemy.level_score = enemy_score
			enemy.name = key
			enemies_in_world.append(enemy)
	
			
	desc_edit.text = data.get("desc", "") as String
	share_online.set_pressed_no_signal(settings.is_shared_online != -1)
	
	settings.game_mode_settings.load_dict(data.get("settings", {}) as Dictionary)
	base_upgrades.load_dict(data.get("base_upgrades", {}) as Dictionary)
	settings.upgrade_settings.reset_all_stats_to_other(base_upgrades)
	base_artifacts.load_dict(data.get("base_artifacts", {}) as Dictionary)
	player.artifacts.reset_from_other(base_artifacts)
	if not settings.is_editing_level:
		player.artifacts.collection.clear()
	item_flag_state.assign(data.get("item_flag_state", []) as Array)
	enemy_flag_state.assign(data.get("enemy_flag_state", []) as Array)
	base_position = data.get("base_position", Vector3(0, 1000.95, 0)) as Vector3
	base_camera = data.get("base_camera", Vector3.ZERO) as Vector3
	player.position = base_position
	player.update_camera(base_camera)
	
	var current_enemies := data.get("current_enemies", []) as Array
	for enemy_name: String in current_enemies:
		for e in enemies_in_world:
			if e.name == enemy_name:
				current_enemies_in_world.append(e)
	var current_flags := data.get("current_flags", []) as Array
	for flag_name: String in current_flags:
		for item: WorldItem in items_in_world:
			if (item is Flag) and item.name == flag_name:
				current_flags_in_world.append(item)
		
	update_item_list()
	update_projectile_list()
	update_enemies_list()


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


func _on_share_online_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if settings.is_shared_online == -1:
			HttpLevels.add_level(settings.world_name, desc_edit.text, get_dict())
		else:
			HttpLevels.put_level(settings.is_shared_online, desc_edit.text, get_dict())

func level_added(id: int) -> void:
	settings.is_shared_online = id
	settings.save()


func switch_editing_mode(is_editing: bool) -> void:
	settings.is_editing_level = is_editing
	test_mode_changed.emit(settings.is_editing_level)
	if settings.is_editing_level:
		test_mode_button.text = "Test Level"
		settings.upgrade_settings.reset_all_stats_to_other(base_upgrades)
		player.artifacts.reset_from_other(base_artifacts)
		player.position = base_position
		player.update_camera(base_camera)
	else:
		test_mode_button.text = "Edit Level"
		base_upgrades.reset_all_stats_to_other(settings.upgrade_settings)
		base_artifacts.reset_from_other(player.artifacts)
		base_position = player.position
		base_camera = player.camera_coords()
		player.artifacts.collection.clear()
		
		
func reset_level_when_playing() -> void:
	test_mode_changed.emit(false)
	settings.upgrade_settings.reset_all_stats_to_other(base_upgrades)
	player.artifacts.reset_from_other(base_artifacts)
	player.position = base_position

func _on_test_mode_pressed() -> void:
	switch_editing_mode(not settings.is_editing_level)

func _on_world_radius_edit_value_changed(value: float) -> void:
	settings.world_radius = value
	world_radius_changed.emit(settings.world_radius)


func _on_track_time_toggled(toggled_on: bool) -> void:
	settings.track_time = toggled_on

func _on_track_score_toggled(toggled_on: bool) -> void:
	settings.track_score = toggled_on

func _on_edit_artifact_pressed() -> void:
	UIAudioPlayer.click()
	if entity_to_edit is ArtifactCube:
		var artifact := (entity_to_edit as ArtifactCube).artifact
		if artifact != null:
			artifact_creator.reset_to_other(artifact)
			artifact_creator_panel.show()
			
func edit_old_artifact() -> void:
	artifact_creator_panel.hide()

enum EntitySettingsIndex { PROJECTILE, NOTE, SPELL, ARTIFACT, ENEMY, COIN, HEALTH, FLAG }
func open_entity_settings(entity_settings_index: EntitySettingsIndex, entity: Variant) -> void:
	settings_tab.current_tab = 1
	entity_settings_tab.current_tab = entity_settings_index
	
	entity_to_edit = entity
	match entity_settings_index:
		EntitySettingsIndex.PROJECTILE:
			pass	
		EntitySettingsIndex.NOTE:
			var note := entity as ScrollNote
			note_edit.text = note.note_id
		EntitySettingsIndex.SPELL:
			var spell_paper := entity as SpellPaper
			spell_spell_edit.text = spell_paper.spell.call_with_parameter_collection_description()
		EntitySettingsIndex.ARTIFACT:
			pass
		EntitySettingsIndex.ENEMY:
			var enemy := entity as Enemy
			enemy_flag_edit.text = str(enemy.level_flag)
			enemy_level_edit.text = str(enemy.level)
			enemy_score_edit.text = str(enemy.level_score)
		EntitySettingsIndex.COIN:
			var coin := entity as CoinDisc
			coin_amount_edit.text = str(coin.amount)
		EntitySettingsIndex.HEALTH:
			var health := entity as RedCross
			health_amount_edit.text = str(health.health)
		EntitySettingsIndex.FLAG:
			var flag := entity as Flag
			flag_tag_edit.text = str(flag.tag)
		

func _on_note_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is ScrollNote:
		(entity_to_edit as ScrollNote).note_id = new_text
	
func _on_spell_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is SpellPaper:
		var wand := Wand.Option.new()
		wand.parse_spells(new_text, player.magic_book)
		if not wand.spells.is_empty() and wand.spells[0] != null:
			(entity_to_edit as SpellPaper).spell = wand.spells[0]

func _on_enemy_level_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is Enemy:
		if new_text.is_valid_int():
			(entity_to_edit as Enemy).level = new_text.to_int()

func _on_enemy_score_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is Enemy:
		if new_text.is_valid_int():
			(entity_to_edit as Enemy).level_score = new_text.to_int()


func _on_enemy_flag_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is Enemy:
		if new_text.is_valid_int():
			(entity_to_edit as Enemy).level_flag = new_text.to_int()


func _on_coin_amount_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is CoinDisc:
		if new_text.is_valid_int():
			(entity_to_edit as CoinDisc).amount = new_text.to_int()


func _on_health_amount_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is RedCross:
		if new_text.is_valid_int():
			(entity_to_edit as RedCross).health = new_text.to_int()

func _on_flag_tag_edit_text_changed(new_text: String) -> void:
	if entity_to_edit is Flag:
		if new_text.is_valid_int():
			(entity_to_edit as Flag).tag = new_text.to_int()
