extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $Menu
@onready var hud: HUD = $HUD

@onready var population: Dictionary = {}

@onready var skybox: SkyBox

var terrain_update_interval = 0
var has_init_terrain_population = false

var book: MagicBook
var case: WandCase
var wand: Wand
var artifacts: Artifacts

var knowledge_tick: int

var settings: WorldSettings

func setup(_settings: WorldSettings) -> void:
	settings = _settings
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	book = GlobalData.magic_book
	book.settings = settings
	book.ignore_cooldown = true
	
	book.update_spell_limits(settings.upgrade_settings.max_v, settings.upgrade_settings.max_r)
	settings.upgrade_settings.max_velocity_updated.connect(func(v):
		book.update_spell_limits(v, settings.upgrade_settings.max_r)
	)
	settings.upgrade_settings.max_radius_updated.connect(func(r):
		book.update_spell_limits(settings.upgrade_settings.max_v, r)
	)
	
	case = WandCase.new()
	case.read(settings.world_name)
	
	artifacts = Artifacts.new()
	artifacts.read(settings.world_name)

#	for i in ["flower", "feather", "goblet", "sands", "crown", "glove", "brace", "gown", "helmet"]:
#		var artifact := Artifact.new(i)
#		artifact.top = Artifact.Option.make_random()
#		artifact.bottom = Artifact.Option.make_random()
#		artifact.left = Artifact.Option.make_random()
#		artifact.right = Artifact.Option.make_random()
#		artifacts.collection.append(artifact)
	
#	var undead := Population.generate_enemy(World.Enemy.UNDEAD, player, -20, 1000, 20)
#	add_child(undead)
#	var bat := Population.generate_enemy(World.Enemy.BAT, player, 20, 1000, 20)
#	add_child(bat)
	var walker := Population.generate_enemy(World.Enemy.WALKER, player, -20, 1000, -20)
	add_child(walker)
	

# Called when the node enters the scene tree for the first time.
func _ready():
	if book == null:
		var _settings := WorldSettings.new()
		_settings.read("empty")
		setup(_settings)
		
	settings.upgrade_settings.currency = 10000
	settings.game_mode_settings.flags |= GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS | GameModeSettings.RESPAWN_WITH_ARTIFACTS
	menu.setup(book, case, artifacts, settings)
	
#	book.ignore_cooldown = true
	wand = case.wands[0]
	menu.wand_case.use_current_wand = func(id: int):
		wand = case.wands[id]
		
	player.spell_caster.ignore_mana_cost = true
	player.spell_velocity_was_buffed.connect(func(v):
		book.update_spell_buff_limits(v, settings.upgrade_settings.buff_r)
	)
	player.spell_radius_was_buffed.connect(func(r):
		book.update_spell_buff_limits(settings.upgrade_settings.buff_v, r)
	)
	
	skybox = SkyBox.new($WorldEnvironment, $Sun, $Moon)
	skybox.day_time = 14
	
	player.magic_book = book
	player.artifacts = artifacts
	hud.player = player
	hud.book = book
	hud.wand = wand
	menu.wand_case.new_wand_selected.connect(hud.set_wand)
	
	menu.settings.settings_changed.connect(hud.update_settings)
	hud.update_settings(settings)

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$FPS.text = str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	pass
	
func _physics_process(delta):
	knowledge_tick += 1

	if knowledge_tick == 60 and has_init_terrain_population:
		knowledge_tick = 0
		for loc in population:
			var pop = population[loc]
			pop.update_info()
			
	if not menu.is_showing:
		const SPEED = 12.0
		var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * SPEED
		if movement != Vector2.ZERO:
			player.pan_camera(movement)


func _input(event):
	if event.is_action_pressed("menu"):
		if menu.is_showing:
			settings.is_paused = false
			menu.close()
			hud.show()
		else:
			settings.is_paused = true
			menu.open(Menu.Kind.ANY)
			settings.player_position = player.position
			hud.hide()
			
	if not menu.is_showing and event.is_action_pressed("magic_book"):
		menu.open(Menu.Kind.SPELLS)
			
	if not menu.is_showing and event.is_action_pressed("wand_case"):
		menu.open(Menu.Kind.WANDS)
		
	if not menu.is_showing and event.is_action_pressed("RT"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if not menu.is_showing:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				player.pan_camera(event.relative)
		
	if not menu.is_showing:
		for k in wand.basic_keys:
			var s: Spell = null
			var is_down := false
			var is_rapid_fire := Globals.Ref.new(false)
			if event.is_action_pressed(k):
				s = wand.action_down(k, book, is_rapid_fire)
				is_down = true
			if event.is_action_released(k):
				s = wand.action_up(k, book)
			if s != null:
				cast_spell_with_recusive_check_for_rapid_fire(s, is_down and is_rapid_fire.data)
				

func cast_spell_with_recusive_check_for_rapid_fire(s: Spell, is_down: bool):
	player.cast_spell(func(p): if p != null: call_deferred("add_child", p), s)
	if is_down:
		get_tree().create_timer(maxf(s.cooldown + 0.02, 0.1)).timeout.connect(func(): 
			var is_rapid_fire := Globals.Ref.new(false)
			s = wand.action_down("", book, is_rapid_fire)
			if s != null and is_rapid_fire.data:
				cast_spell_with_recusive_check_for_rapid_fire(s, true)
		)

func _on_player_moved(delta: float, state: PhysicsDirectSpaceState3D):	
	pass

func enemy_drops_artifact(enemy: Enemy, artifact: Artifact):
	if artifact != null:
		artifacts.collection.append(artifact)
	var enemy_kind = enemy.world_enemy_enum()
	if settings.enemies_killed.has(enemy_kind):
		settings.enemies_killed[enemy_kind] += 1
	else:
		settings.enemies_killed[enemy_kind] = 1

func quit_to_main_menu():
	get_tree().change_scene_to_file("res://GUI/Menu/MainMenu.tscn")


func _on_player_vital_update(vitals: Vitals) -> void:
	if settings == null or settings.game_mode_settings == null:
		return
		
	match settings.game_mode_settings.mode:
		GameModeSettings.GameMode.RESPAWN:
			if vitals.health.value > 0:
				return
				
			vitals.health.value = vitals.health.max_value
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_ARTIFACTS == 0:
				artifacts.reset_by_deleting_all_artifacts()
				menu.artifacts.update_list_and_grid()
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_UPGRADES == 0:
				settings.upgrade_settings.reset_all_stats_to_default_values()
				menu.upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS == 0:
				book.reset_by_deleting_all_spells()
				case.reset_by_deleting_all_wands()
				wand = case.wands[0]
				menu.magic_book.update_book_without_selection()
				menu.wand_case.reload_wand_shelf_items(0)
			
		GameModeSettings.GameMode.PERMADEATH:
			if vitals.health.value > 0:
				return
			
			get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")
