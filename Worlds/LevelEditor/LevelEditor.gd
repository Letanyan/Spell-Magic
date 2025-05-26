class_name LevelEditor
extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $SubViewportContainer/SubViewport/Menu
@onready var hud: HUD = $HUD
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

@onready var skybox: SkyBox

var book: MagicBook
var case: WandCase
var wand: Wand
var artifacts: Artifacts

var knowledge_tick: float = 0.0
var daytime_tick: float = 0.0
var test_tick: float = 0.0

var settings: WorldSettings
var inhabitants: Array[Enemy] = []
var spawner: ItemSpawner

var is_mouse_down: bool = false
var spells_on_hold: Dictionary = {}

var ready_state: GameSettings.ReadyState = GameSettings.ReadyState.NOT

var level_build_data: Dictionary = {}

func setup(_settings: WorldSettings, level_data: Dictionary) -> void:
	settings = _settings
	level_build_data = level_data
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if settings.is_editing_level:
		book = GlobalData.magic_book
		book.settings = settings
		book.ignore_cooldown = true
		book.settings.upgrade_settings.level_spells_in_book = 25
	else:
		book = MagicBook.new()
		book.settings = settings
		book.read(settings.world_name, false)
		book.rebuild_spell_chains()
		book.ignore_cooldown = GlobalData.is_debug
	
	book.update_spell_limits(settings.upgrade_settings.max_v(), settings.upgrade_settings.max_r())
	settings.upgrade_settings.max_velocity_updated.connect(func(v: float) -> void:
		book.update_spell_limits(v, settings.upgrade_settings.max_r())
	)
	settings.upgrade_settings.max_radius_updated.connect(func(r: float) -> void:
		book.update_spell_limits(settings.upgrade_settings.max_v(), r)
	)
	settings.upgrade_settings.upgrade_was_purchased.connect(func(us: UpgradeSettings, payload: Dictionary) -> void:
		player.vitals.health.max_value = us.max_health()
		player.vitals.mana.max_value = us.max_mana()
		player.vitals.mana.change_per_tick = us.max_mana_regen()
		player.vitals.attack.set_fixed_value(us.max_attack())
		player.vitals.defence.set_fixed_value(us.max_defence())
		player.vitals.health.value += payload.get("health", 0.0) as float
		player.vitals.mana.value += payload.get("mana", 0.0) as float
		hud.hud_upgrades.upgrade_slots_refreshed(us)
		if payload.has("element") or payload.has("chain"):
			menu.magic_book.page.update_combo_box_disabled()
		menu.spell_deck.update_cards()
	)
	
	case = WandCase.new()
	case.read(settings.world_name, book)
	book.spell_was_updated.connect(case.spell_was_updated)
	
	artifacts = Artifacts.new()
	artifacts.read(settings.world_name)
	
	SignalBus.enemy_death.connect(func(e: Enemy) -> void:
		var i := -1
		for x in inhabitants:
			i += 1
			if x == e:
				break
		if i != -1:
			inhabitants.remove_at(i)
		e.queue_free()
		print(e, " died")
	)

func _ready() -> void:
	if ready_state == GameSettings.ReadyState.NOT:
		run_on_ready()

# Called when the node enters the scene tree for the first time.
func run_on_ready() -> void:
	ready_state = GameSettings.ReadyState.IN
	if book == null:
		var _settings := WorldSettings.new(get_viewport())
		_settings.read("test+arena")
		_settings.is_level_editor = true
		setup(_settings, {})
		
		
	for enemy in inhabitants:
		enemy.animation_tree.active = true
		
	menu.setup(book, case, artifacts, settings, player)
	
	wand = case.current_wand()
	menu.wand_case.use_current_wand = func(id: int) -> void:
		wand = case.wands[id]
		
	menu.close_menu.connect(toggle_menu)
		
	if level_build_data.is_empty():
		menu.build_menu.read(settings.world_name, book, player.spell_caster)
	else:
		menu.build_menu.load_data(level_build_data, book, player.spell_caster)
	for proj in menu.build_menu.projectiles_in_world:
		proj.time_stamp = 0.0
		insert_spell(proj)
	for item in menu.build_menu.items_in_world:
		add_child(item)
	
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
	player.world_settings = settings
	player.name_generator = NameGenerator.new()
	player.name_generator.read(settings.world_name)
	player.set_current_biome(World.Biome.GRASSLAND)
	#player.play_bg_audio(World.Biome.WATER)
	
	skybox = SkyBox.new($WorldEnvironment as WorldEnvironment, $Sun as DirectionalLight3D, $Moon as DirectionalLight3D)
	skybox.day_time = 14
	daytime_tick = 0.0
	
	player.magic_book = book
	player.artifacts = artifacts
	hud.player = player
	hud.book = book
	hud.wand = wand
	menu.wand_case.new_wand_selected.connect(hud.set_wand)
	
	hud.world_settings = settings
	menu.settings.settings_changed.connect(hud.update_settings)
	hud.update_settings(settings)
	settings.upgrade_settings.upgrade_slot_progress.connect(hud.hud_upgrades.upgrade_slot_progress_update)
	settings.customisation_settings.update_all(player.skeleton_3d)
	
	AudioManager.world = self
	AudioManager.camera = player.cam
	
	var theme := load(ProjectSettings.get("gui/theme/custom") as String) as ThemeUI
	theme.change_tint_color(settings.hud_settings.theme_color, settings.hud_settings.theme_variation)
	hud.update_theme_colors(settings.hud_settings.theme_color, settings.hud_settings.theme_variation)
	ready_state = GameSettings.ReadyState.IS
	
	hud.update_compass_position(player.cam_pivot.rotation.y, player.position)
	
	await RenderingServer.frame_post_draw
	(player.interface.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("texture_albedo", sub_viewport.get_texture())
	sub_viewport_container.visible = true

func _exit_tree() -> void:
	AudioManager.world = null
	AudioManager.camera = null

func _process(delta: float) -> void:
	($FPS as Label).text = str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	
	
func _physics_process(delta: float) -> void:
	AudioManager.update(delta)
	player.update_audio_state(delta)
	
	if player.magic_book.settings.is_paused:
		if get_window().has_focus():
			if Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0:
				if not is_mouse_down:
					var event := InputEventMouseButton.new()
					is_mouse_down = true
					event.position = get_viewport().get_mouse_position()
					event.pressed = true
					event.button_index = MOUSE_BUTTON_LEFT
					Input.parse_input_event(event)
			elif is_mouse_down:
				is_mouse_down = false
				var event := InputEventMouseButton.new()
				event.position = get_viewport().get_mouse_position()
				event.pressed = false
				event.button_index = MOUSE_BUTTON_LEFT
				Input.parse_input_event(event)
			if GlobalData.controller.last_input_type == Controller.InputType.CONTROLLER:
				var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * 12
				get_viewport().warp_mouse(get_viewport().get_mouse_position() + movement)
		return
	
	knowledge_tick += delta
	daytime_tick += delta

	#player.play_bg_audio(World.Biome.GRASSLAND)
	book.update_spell_cooldowns(delta)
	hud.update_spell_cooldowns(delta)
	
	for inhabitant in inhabitants:
		inhabitant.manual_physics_process(delta)
		
	for turret_key: String in spells_on_hold:
		for turret: SpellTurret in spells_on_hold[turret_key]:
			turret.update_position(delta)
			
			
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

func close_menu_for_player() -> void:
	settings.is_paused = false
	var indices: Array[int] = []
	var idx := 0
	for e in inhabitants:
		if e == null:
			indices.append(idx)
			continue
		idx += 1
	indices.reverse()
	for i in indices:
		inhabitants.remove_at(i)
	menu.close()
	hud.show()
	
func open_menu_for_player() -> void:
	settings.is_paused = true
	sub_viewport_container.visible = true
	menu.player_in_combat = not player.enemies_in_range.is_empty()
	menu.open(Menu.Kind.ANY)
	if not menu.is_quick_menu and menu.current_index == Menu.Kind.SETTINGS and menu.settings.tab_container.get_current_tab_control().name == "Skin":
		player.animate_spring_arm(true, 0.2)
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
	player.transition_menu(not menu.is_showing, not menu.is_quick_menu and menu.current_index == Menu.Kind.SETTINGS and menu.settings.tab_container.get_current_tab_control().name == "Skin", menu.showing_customisation)
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("tab_menu"):
		menu.is_quick_menu = false
		toggle_menu()
	elif event.is_action_pressed("esc_menu"):
		menu.is_quick_menu = GlobalData.controller.get_has_tab_menu_key()
		toggle_menu()
		
	Input.stop_joy_vibration(event.device)
			
	if not menu.is_showing:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				player.pan_camera((event as InputEventMouseMotion).relative * settings.camera_settings.panning_speed())
				hud.update_compass_position(player.cam_pivot.rotation.y, player.position)
		
	if not menu.is_showing:
		GlobalData.controller.handle_input(event)
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			if GlobalData.is_debug:
				settings.upgrade_settings.level_running_speed -= 1
				print(settings.upgrade_settings.level_running_speed, " = ", settings.upgrade_settings.max_running_speed())
			else:
				if settings.camera_settings.distance > 1:
					settings.camera_settings.distance -= 1
					menu.settings.settings_changed.emit(settings)
					menu.settings.update_controls()
					settings.save()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			if GlobalData.is_debug:
				settings.upgrade_settings.level_running_speed += 1
				print(settings.upgrade_settings.level_running_speed, " = ", settings.upgrade_settings.max_running_speed())
			else:
				if settings.camera_settings.distance < 10:
					settings.camera_settings.distance += 1
					menu.settings.settings_changed.emit(settings)
					menu.settings.update_controls()
					settings.save()
		
		for k: String in wand.basic_keys:
			var s: Spell = null
			var is_down := false
			var is_rapid_fire := Globals.Ref.new(false)
			var action_option := Globals.Ref.new(null)
			if event.is_action_pressed(k):
				var hold_spell := Globals.Ref.new(null)
				s = wand.action_down(k, book, is_rapid_fire, hold_spell)
				is_down = true
				if hold_spell.data != null:
					spells_on_hold[k] = player.project_spell(insert_spell, hold_spell.data as Spell)
			if event.is_action_released(k):
				s = wand.action_up(k, book, action_option)
				if spells_on_hold.has(k):
					for t: SpellTurret in spells_on_hold[k]:
						SpellBuffer.free_turrent(t)
					spells_on_hold.erase(k)
			if s != null:
				cast_spell_with_recusive_check_for_rapid_fire(s, is_down and is_rapid_fire.data as bool)
			elif action_option.data != null:
				var option := action_option.data as Wand.Option
				if option.kind == Wand.Kind.REMOVE_ITEM:
					var cdir := Vector3.ZERO
					var port := get_viewport()
					var pos := port.get_visible_rect().size / 2.0
					var coord := port.get_camera_3d().project_ray_origin(pos)
					cdir = port.get_camera_3d().project_ray_normal(pos)
					var node_to_track := Navigator.get_ray_intersection_of_node(player, coord, coord + cdir * 500)
					if node_to_track != null:
						if node_to_track is SpellBody:
							menu.build_menu.delete_projectile(node_to_track as SpellBody)
						elif node_to_track is WorldItem:
							menu.build_menu.delete_item(node_to_track as WorldItem)
				elif option.kind == Wand.Kind.PLACE_ITEM:
					var spell := option.get_spell()
					if spell != null:
						var paper := SpellPaper.make()
						paper.spell = spell
						paper.position = player.position
						add_child(paper)
						SignalBus.item_added_to_world.emit(paper)
					else:
						option.next_spell()
						var spell_name := option.get_spell_name()
						if spell_name == "health":
							var cross := RedCross.make()
							cross.health = ((option.parameters[option.spell_index] as Dictionary).get("0", "0") as String).to_float() / 100.0
							cross.position = player.position
							add_child(cross)
							SignalBus.item_added_to_world.emit(cross)
						elif spell_name == "coin":
							var coin := CoinDisc.make()
							coin.amount = ((option.parameters[option.spell_index] as Dictionary).get("0", "0") as String).to_int()
							coin.position = player.position
							add_child(coin)
							SignalBus.item_added_to_world.emit(coin)
				

func cast_spell_with_recusive_check_for_rapid_fire(s: Spell, is_down: bool) -> void:
	player.cast_spell(insert_spell, s)
	if is_down:
		get_tree().create_timer(maxf(s.cooldown + 0.02, 0.1)).timeout.connect(func() -> void: 
			var is_rapid_fire := Globals.Ref.new(false)
			var hold_spell := Globals.Ref.new(null)
			var ns := wand.action_down("", book, is_rapid_fire, hold_spell)
			if ns != null and is_rapid_fire.data:
				cast_spell_with_recusive_check_for_rapid_fire(ns, true)
		)
		
func insert_spell(p: Node3D) -> void:
	if p == null:
		return
	if p.get_parent() == null:
		add_child(p)
	if p is SpellBody:
		(p as SpellBody).setup()

func _on_player_moved(delta: float) -> void:
	hud.update_compass_position(player.cam_pivot.rotation.y, player.position)


func quit_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://GUI/Menu/MainMenu.tscn")


func _on_player_vital_update(vitals: Vitals) -> void:
	if settings == null or settings.game_mode_settings == null:
		return
		
	match settings.game_mode_settings.mode:
		GameModeSettings.GameMode.RESPAWN:
			if vitals.health.value > 0:
				return
				
			UIAudioPlayer.hurt()
			vitals.health.value = vitals.health.max_value
			
		GameModeSettings.GameMode.PERMADEATH:
			if vitals.health.value > 0:
				return
			
			SceneHandler.load_new_scene("res://GUI/Main Menu/MainMenu.tscn", "fade_to_black")
