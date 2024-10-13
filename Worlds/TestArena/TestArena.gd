extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $SubViewportContainer/SubViewport/Menu
@onready var hud: HUD = $HUD
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

@onready var population: Dictionary = {}

@onready var skybox: SkyBox

var terrain_update_interval := 0
var has_init_terrain_population := false

var book: MagicBook
var case: WandCase
var wand: Wand
var artifacts: Artifacts

var knowledge_tick: float = 0.0
var daytime_tick: float = 0.0

var settings: WorldSettings
var pause_start: float
var inhabitants: Array[Enemy] = []
var spawner: ItemSpawner

func setup(_settings: WorldSettings) -> void:
	settings = _settings
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	book = GlobalData.magic_book
	book.settings = settings
	book.ignore_cooldown = true
	book.settings.upgrade_settings.level_spells_in_book = 25
	
	book.update_spell_limits(settings.upgrade_settings.max_v(), settings.upgrade_settings.max_r())
	settings.upgrade_settings.max_velocity_updated.connect(func(v: float) -> void:
		book.update_spell_limits(v, settings.upgrade_settings.max_r())
	)
	settings.upgrade_settings.max_radius_updated.connect(func(r: float) -> void:
		book.update_spell_limits(settings.upgrade_settings.max_v(), r)
	)
	settings.upgrade_settings.upgrade_was_purchased.connect(func(us: UpgradeSettings) -> void:
		player.vitals.health.max_value = us.max_health()
		player.vitals.mana.max_value = us.max_mana()
		player.vitals.mana.change_per_tick = us.max_mana_regen()
		player.vitals.attack.set_fixed_value(us.max_attack())
		player.vitals.defence.set_fixed_value(us.max_defence())
	)
	player.world_settings = settings
	player.name_generator = NameGenerator.new()
	player.name_generator.read(settings.world_name)
	
	case = WandCase.new()
	case.read(settings.world_name)
	
	artifacts = Artifacts.new()
	artifacts.read(settings.world_name)
	
	SignalBus.enemy_death.connect(func(e: Enemy) -> void: e.queue_free(); print(e, " died"))

	#var seq := " 1"
	#for i in ["flower", "feather", "goblet", "sands", "crown", "glove", "brace", "gown", "helmet"]:
		#var artifact := Artifact.new(i + seq)
		#artifact.top = Artifact.Option.make_random()
		#artifact.bottom = Artifact.Option.make_random()
		#artifact.left = Artifact.Option.make_random()
		#artifact.right = Artifact.Option.make_random()
		#artifacts.collection.append(artifact)
	
	const pX = 100
	const pY = 100
	const LVL = 1
	var undead := Population.generate_enemy(World.Enemy.SNOT_SPIKE, player, pX / 1.0, 1000, pY / 1.0)
	undead.level = LVL
	add_enemy(undead)
	#var bat := Population.generate_enemy(World.Enemy.BAT, player, pX, 1000, -pY)
	#add_enemy(bat)
	#var bat2 := Population.generate_enemy(World.Enemy.BAT, player, -pX, 1000, -pY)
	#add_enemy(bat2)
	#var walker := Population.generate_enemy(World.Enemy.WALKER, player, -pX, 1000, -pY)
	#add_enemy(walker)
	#var fish := Population.generate_enemy(World.Enemy.FISH, player, -pX, 1000, pY)
	#add_enemy(fish)
	#var mole := Population.generate_enemy(World.Enemy.MOLE, player, -pX, 1000, pY)
	#add_enemy(mole)
	#var birdman := Population.generate_enemy(World.Enemy.BIRDMAN, player, pX, 1000, pY)
	#add_enemy(birdman)
	
	#var fishman := Population.generate_enemy(World.Enemy.FISHMAN, player, pX, 1000, pY)
	#fishman.level = 50
	#add_enemy(fishman)
	#var undead := Population.generate_enemy(World.Enemy.UNDEAD, player, pX, 1000, pY)
	#undead.level = 50
	#add_enemy(undead)
	#var undead2 := Population.generate_enemy(World.Enemy.UNDEAD, player, pX, 1000, pY)
	#undead2.level = 50
	#add_enemy(undead2)
	#var undead3 := Population.generate_enemy(World.Enemy.UNDEAD, player, pX, 1000, pY)
	#undead3.level = 50
	#add_enemy(undead3)
	#var undead4 := Population.generate_enemy(World.Enemy.UNDEAD, player, pX, 1000, pY)
	#undead4.level = 50
	#add_enemy(undead4)
	#var fish := Population.generate_enemy(World.Enemy.FISH, player, -pX, 1000, pY)
	#fish.level = 1
	#add_enemy(fish)
	#var fishman2 := Population.generate_enemy(World.Enemy.FISHMAN, player, pX, 1000, pY)
	#fishman2.level = 50
	#add_enemy(fishman2)
	#var fishman3 := Population.generate_enemy(World.Enemy.FISHMAN, player, pX, 1000, pY)
	#fishman3.level = 50
	#add_enemy(fishman3)
	#var dragon := Population.generate_enemy(World.Enemy.DRAGON, player, -pX, 1000, -pY)
	#dragon.level = LVL
	#add_enemy(dragon)
	#var dragoon := Population.generate_enemy(World.Enemy.DRAGOON, player, pX, 1000, -pY)
	#add_enemy(dragoon)
	#var ghost := Population.generate_enemy(World.Enemy.GHOST, player, -pX, 1000, pY)
	#add_enemy(ghost)
	#var ghostly := Population.generate_enemy(World.Enemy.GHOSTLY, player, pX, 1000, pY)
	#add_enemy(ghostly)
	#var fungi := Population.generate_enemy(World.Enemy.FUNGI, player, -pX, 1000, -pY)
	#add_enemy(fungi)
	#var mushroom := Population.generate_enemy(World.Enemy.MUSHROOM, player, pX, 1000, -pY)
	#add_enemy(mushroom)
	#var bird := Population.generate_enemy(World.Enemy.BIRD, player, -pX, 1000, pY)
	#add_enemy(bird)
	#var hot_blob := Population.generate_enemy(World.Enemy.HOT_BLOB, player, pX, 1000, -pY)
	#hot_blob.level = LVL
	#add_enemy(hot_blob)
	#var bluemon := Population.generate_enemy(World.Enemy.BLUEMON, player, -pX, 1000, -pY)
	#add_enemy(bluemon)
	#var frog := Population.generate_enemy(World.Enemy.FROG, player, pX, 1000, -pY)
	#add_enemy(frog)
	#var mushking := Population.generate_enemy(World.Enemy.MUSHKING, player, -pX, 1000, pY)
	#mushking.level = LVL
	#add_enemy(mushking)
	#var rabbit := Population.generate_enemy(World.Enemy.RABBIT, player, pX, 1000, pY)
	#add_enemy(rabbit)
	#var batty := Population.generate_enemy(World.Enemy.BATTY, player, -pX, 1000, -pY)
	#add_enemy(batty) 
	#var bee := Population.generate_enemy(World.Enemy.BEE, player, pX, 1000, -pY)
	#add_enemy(bee) 
	#var bumble_bee := Population.generate_enemy(World.Enemy.BUMBLE_BEE, player, -pX, 1000, pY)
	#add_enemy(bumble_bee) 
	#var undead_head := Population.generate_enemy(World.Enemy.UNDEAD_HEAD, player, pX, 1000, pY)
	#add_enemy(undead_head)
	
	var rng := RandomNumberGenerator.new()
	spawner = ItemSpawner.key_spawner(rng, null, Vector3(20, 1000, 20), 16)
	#spawner.nodes_to_be_cleared[fishman] = true
	
	#var T := Transform3D.IDENTITY.rotated(Vector3.FORWARD, PI / 2).translated(Vector3.UP * 10)
	#var RT := Transform3D.IDENTITY.rotated(Vector3.UP, 2 * PI / 3)
	#var circle_path := PathStyle.Pathway.new().move_to(Vector3.ZERO).circle_with_speed(4, 2, 1)
	#var path1 := PathStyle.new(0, Vector3(20, 1000, -20)).follow_path(circle_path).align_y_to_ground_and_air().look_at_player_xz().transform_path(T)
	#var path2 := PathStyle.new(1, Vector3(20, 1000, -20)).follow_path(circle_path).align_y_to_ground_and_air().look_at_player_xz().transform_path([RT, T])
	#var path3 := PathStyle.new(2, Vector3(20, 1000, -20)).follow_path(circle_path).align_y_to_ground_and_air().look_at_player_xz().transform_path([RT, RT, T])
	#var target1 := TargetShape.make()
	#target1.configure(TargetShape.config_for_gauge(Spell.Element.WATER, spawner, 3, Vitals.Stat.new(0, 0, 1, -0.1), path1))
	#var target2 := TargetShape.make()
	#target2.configure(TargetShape.config_for_damage(Spell.Element.FIRE, spawner, 3, Vitals.Stat.new(100, 0, 100, 5), path2))
	#
	#var target3 := TargetShape.make()
	#var spell := Spell.new(false, "tu", "tv", "10*t", 0.5, 7, 2.0, Spell.Element.FIRE, 1, "2.5", false, 0.0)
	#var caster_pos := Vector3(20, 1000 + 10, -20) + Vector3.RIGHT * 10
	#target3.configure(TargetShape.config_for_avoid_damage(Spell.Element.VOID, spawner, 3, Vitals.Stat.new(0, 0, 100, 15), path3, spell, caster_pos))
	#
	#target1.focus_point = Vector3(20, 1000, -20) + Vector3.RIGHT * 3e10
	#target2.focus_point = Vector3(20, 1000, -20) + Vector3.RIGHT * 3e10
	#target3.focus_point = Vector3(20, 1000, -20) + Vector3.RIGHT * 3e10
	#spawner.nodes_to_be_cleared[target1] = true
	#spawner.nodes_to_be_cleared[target2] = true
	#spawner.nodes_to_be_cleared[target3] = true
	#
	#add_child(target1)
	#add_child(target2)
	#add_child(target3)
	#
	#SignalBus.enemy_death.connect(spawner.remove_node)
	#
	#
	#var path4 := PathStyle.new(0, Vector3(20, 1000, 20)).follow_path(PathStyle.Pathway.new().move_to(Vector3(0, 0, 0)).line_to(Vector3(0, 10, 10), 5).line_to(Vector3.ZERO, 5)).align_y_to_ground_and_air().look_at_player()
	#var target4 := TargetShape.make()
	#target4.configure(TargetShape.config_for_platform(Spell.Element.ROCK, 5, path4))
	#target4.focus_point = Vector3.UP * 3e10
	#add_child(target4)
	

func add_enemy(enemy: Enemy) -> void:
	inhabitants.append(enemy)
	add_child(enemy)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if book == null:
		var _settings := WorldSettings.new(get_viewport())
		_settings.read("test+arena")
		_settings.is_test_arena = true
		setup(_settings)
		
	for enemy in inhabitants:
		enemy.animation_tree.active = true
		
	settings.upgrade_settings.currency = 10000
	settings.game_mode_settings.flags |= GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS | GameModeSettings.RESPAWN_WITH_ARTIFACTS
	menu.setup(book, case, artifacts, settings)
	
	wand = case.current_wand()
	menu.wand_case.use_current_wand = func(id: int) -> void:
		wand = case.wands[id]
		
	menu.close_menu.connect(toggle_menu)
		
	player.spell_caster.ignore_mana_cost = true
	player.spell_velocity_was_buffed.connect(func(v: float) -> void:
		book.update_spell_buff_limits(v, settings.upgrade_settings.buff_r)
	)
	player.spell_radius_was_buffed.connect(func(r: float) -> void:
		book.update_spell_buff_limits(settings.upgrade_settings.buff_v, r)
	)
	player.attack_was_buffed.connect(func(atk: float) -> void:
		book.update_spell_attack_and_defence(atk, settings.upgrade_settings.buff_defence)
	)
	player.defence_was_buffed.connect(func(def: float) -> void:
		book.update_spell_attack_and_defence(settings.upgrade_settings.buff_attack, def)
	)
	player.vitals.health.max_value = settings.upgrade_settings.max_health()
	player.vitals.mana.max_value = settings.upgrade_settings.max_mana()
	player.vitals.mana.change_per_tick = settings.upgrade_settings.max_mana_regen()
	player.vitals.health.set_value(settings.player_health)
	player.vitals.mana.set_value(settings.player_mana)
	player.vitals.attack.set_fixed_value(settings.upgrade_settings.max_attack())
	player.vitals.defence.set_fixed_value(settings.upgrade_settings.max_defence())
	
	skybox = SkyBox.new($WorldEnvironment as WorldEnvironment, $Sun as DirectionalLight3D, $Moon as DirectionalLight3D)
	skybox.day_time = 14
	daytime_tick = 0.0
	
	player.magic_book = book
	player.artifacts = artifacts
	hud.player = player
	hud.book = book
	hud.wand = wand
	menu.wand_case.new_wand_selected.connect(hud.set_wand)
	
	menu.settings.settings_changed.connect(hud.update_settings)
	hud.update_settings(settings)
	
	await RenderingServer.frame_post_draw
	(player.interface.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture = sub_viewport.get_texture()
	sub_viewport_container.visible = false
	

func _process(delta: float) -> void:
	($FPS as Label).text = str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	
func _physics_process(delta: float) -> void:
	if player.magic_book.settings.is_paused:
		return
	
	knowledge_tick += delta
	daytime_tick += delta

	if knowledge_tick >= Globals.knowledge_tick() and has_init_terrain_population:
		knowledge_tick = 0.0
		for loc: Vector2 in population:
			var pop := population[loc] as Population
			pop.update_info()
			
	if daytime_tick >= 1.0:
		if skybox.day_time + 0.016667 >= SkyBox.HOURS_IN_DAY:
			skybox.day_time = 0
			if skybox.day_of_year + 1 > SkyBox.DAYS_IN_YEAR:
				skybox.day_of_year = 1
			else:
				skybox.day_of_year += 1
		else:
			skybox.day_time += 0.016667
		daytime_tick = 0.0
			
	if not menu.is_showing:
		const SPEED = 12.0
		var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * SPEED
		if movement != Vector2.ZERO:
			player.pan_camera(movement)

func close_menu_for_player() -> void:
	settings.is_paused = false
	var pause_duration := Time.get_unix_time_from_system() - pause_start
	player.spell_caster.update_pause_time(pause_duration)
	var indices: Array[int] = []
	var idx := 0
	for e in inhabitants:
		if e == null:
			indices.append(idx)
			continue
		e.spell_caster.update_pause_time(pause_duration)
		idx += 1
	indices.reverse()
	for i in indices:
		inhabitants.remove_at(i)
	menu.close()
	hud.show()
	
func open_menu_for_player() -> void:
	settings.is_paused = true
	sub_viewport_container.visible = true
	pause_start = Time.get_unix_time_from_system()
	menu.open(Menu.Kind.ANY)
	settings.player_position = player.position
	settings.player_health = player.vitals.health.value
	settings.player_mana = player.vitals.mana.value
	settings.last_save_time = Time.get_unix_time_from_system()
	hud.hide()
	

func toggle_menu() -> void:
	if not player.menu_callbacks_are_set:
		player.setup_menu_transition(open_menu_for_player, close_menu_for_player)
	
	settings.is_paused = true
	sub_viewport_container.visible = false
	#menu.visible = true
	player.transition_menu(not menu.is_showing)
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle_menu()
		
	if not menu.is_showing and event.is_action_pressed("RT"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if not menu.is_showing:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				player.pan_camera((event as InputEventMouseMotion).relative)
	else:
		if event is InputEventJoypadMotion:
			var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * 12
			get_viewport().warp_mouse(get_viewport().get_mouse_position() + movement)
		
	if not menu.is_showing:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			if settings.camera_settings.distance > 1:
				settings.camera_settings.distance -= 1
				menu.settings.settings_changed.emit(settings)
				menu.settings.update_controls()
				settings.save()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			if settings.camera_settings.distance < 10:
				settings.camera_settings.distance += 1
				menu.settings.settings_changed.emit(settings)
				menu.settings.update_controls()
				settings.save()
		
		for k: String in wand.basic_keys:
			var s: Spell = null
			var is_down := false
			var is_rapid_fire := Globals.Ref.new(false)
			if event.is_action_pressed(k):
				s = wand.action_down(k, book, is_rapid_fire)
				is_down = true
			if event.is_action_released(k):
				s = wand.action_up(k, book)
			if s != null:
				cast_spell_with_recusive_check_for_rapid_fire(s, is_down and is_rapid_fire.data as bool)
				

func cast_spell_with_recusive_check_for_rapid_fire(s: Spell, is_down: bool) -> void:
	player.cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_child", p), s)
	if is_down:
		get_tree().create_timer(maxf(s.cooldown + 0.02, 0.1)).timeout.connect(func() -> void: 
			var is_rapid_fire := Globals.Ref.new(false)
			var ns := wand.action_down("", book, is_rapid_fire)
			if ns != null and is_rapid_fire.data:
				cast_spell_with_recusive_check_for_rapid_fire(ns, true)
		)

func _on_player_moved(delta: float, state: PhysicsDirectSpaceState3D) -> void:	
	pass


func quit_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://GUI/Menu/MainMenu.tscn")


func _on_player_vital_update(vitals: Vitals) -> void:
	if settings == null or settings.game_mode_settings == null:
		return
		
	match settings.game_mode_settings.mode:
		GameModeSettings.GameMode.RESPAWN:
			if vitals.health.value > 0:
				return
				
			vitals.health.value = vitals.health.max_value
			#if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_ARTIFACTS == 0:
				#artifacts.reset_by_deleting_all_artifacts()
				#menu.artifacts.update_list_and_grid()
			#if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_UPGRADES == 0:
				#settings.upgrade_settings.reset_all_stats_to_default_values()
				#menu.upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
			#if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS == 0:
				#book.reset_by_deleting_all_spells()
				#case.reset_by_deleting_all_wands()
				#wand = case.wands[0]
				#menu.magic_book.update_book_without_selection()
				#menu.wand_case.reload_wand_shelf_items(0)
			
		GameModeSettings.GameMode.PERMADEATH:
			if vitals.health.value > 0:
				return
			
			SceneHandler.load_new_scene("res://GUI/Main Menu/MainMenu.tscn", "fade_to_black")
