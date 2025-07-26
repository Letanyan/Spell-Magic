class_name LevelEditor
extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $SubViewportContainer/SubViewport/Menu
@onready var hud: HUD = $HUD
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

@onready var skybox: SkyBox
@onready var ground: MeshInstance3D = $Ground
@onready var ground_collision: CollisionShape3D = $Ground/StaticBody3D/CollisionShape3D

@onready var world_boundary_y_minus: CollisionShape3D = $WorldBoundary/YMinus
@onready var world_boundary_x_minus: CollisionShape3D = $WorldBoundary/XMinus
@onready var world_boundary_x_plus: CollisionShape3D = $WorldBoundary/XPlus
@onready var world_boundary_z_minus: CollisionShape3D = $WorldBoundary/ZMinus
@onready var world_boundary_z_plus: CollisionShape3D = $WorldBoundary/ZPlus
@onready var world_boundary_x_minus_mesh: MeshInstance3D = $WorldBoundary/XMinus/Mesh
@onready var world_boundary_x_plus_mesh: MeshInstance3D = $WorldBoundary/XPlus/Mesh
@onready var world_boundary_z_minus_mesh: MeshInstance3D = $WorldBoundary/ZMinus/Mesh
@onready var world_boundary_z_plus_mesh: MeshInstance3D = $WorldBoundary/ZPlus/Mesh

var book: MagicBook
var case: WandCase
var wand: Wand
var artifacts: Artifacts

var knowledge_tick: float = 0.0
var daytime_tick: float = 0.0
var test_tick: float = 0.0
var playtime_tick: float = 0.0

var settings: WorldSettings
var inhabitants: Array[Enemy] = []
var spawner: ItemSpawner

var is_mouse_down: bool = false
var spells_on_hold: Dictionary = {}

var ready_state: GameSettings.ReadyState = GameSettings.ReadyState.NOT

var level_build_data: Dictionary = {}
var is_in_testing_mode: bool = false

func setup(_settings: WorldSettings, level_data: Dictionary) -> void:
	settings = _settings
	level_build_data = level_data
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	book = MagicBook.new()
	book.settings = settings
	if settings.is_editing_level:
		book.read_absolute_path("user://universal_magic_book.json", false)
		book.rebuild_spell_chains()
		book.ignore_cooldown = true
		book.settings.upgrade_settings.level_spells_in_book = 25
	else:
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
	var wand_case_file_exists := case.read(settings.world_name, book)
	if not wand_case_file_exists:
		case.reset_by_setting_is_for_user(book)
	book.spell_was_updated.connect(case.spell_was_updated)
	case.is_build_mode = settings.is_editing_level
	
	artifacts = Artifacts.new()
	artifacts.read(settings.world_name)
	
	SignalBus.pick_up_world_item_artifact.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_spell.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_coin.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_key.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_red_cross.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_scroll_note.connect(mark_world_item_entity)
	
	SignalBus.observe_world_item_scroll_note.connect(func(entity: ScrollNote, note_id: String, message: String) -> void: 
		const DURATION = 10.0
		hud.show_message(GameSettings.Tutorials.PLAYER_MESSAGE, note_id.replace("\"", ""), DURATION)
	)
	
	SignalBus.enemy_death.connect(func(e: Enemy) -> void:
		var i := -1
		for x in inhabitants:
			i += 1
			if x == e:
				break
		if i != -1:
			inhabitants.remove_at(i)
		menu.build_menu.remove_current_enemy(e)
		mark_entity(e)
		remove_child(e)
		settings.current_score += e.level_score
		for enemy in menu.build_menu.retrieve_enemies_based_on_flag_state():
			if enemy.get_parent() == null:
				add_enemy(enemy)
		if e.level_flag == 0:
			win_condition_met()
	)
	SignalBus.pick_up_world_item_flag.connect(func(f: Flag, tag: int, m: String) -> void:
		menu.build_menu.remove_current_flag(f)
		mark_entity(f)
		for flag in menu.build_menu.retrieve_flags_based_on_flag_state():
			if flag.get_parent() == null:
				flag.custom_free = remove_world_item
				add_child(flag)
		if f.tag == 0:
			win_condition_met()
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
		
	GlobalData.game_settings.unlocked_notes["wand Remove"] = true
	GlobalData.game_settings.unlocked_notes["wand Place"] = true
	GlobalData.game_settings.unlocked_notes["wand Place Chosen"] = true
		
	for enemy in inhabitants:
		enemy.animation_tree.active = true
		
	menu.setup(book, case, artifacts, settings, player)
	
	wand = case.current_wand()
	menu.wand_case.use_current_wand = func(id: int) -> void:
		wand = case.wands[id]
		
	menu.close_menu.connect(toggle_menu)
		
	player.magic_book = book
	player.artifacts = artifacts
	if level_build_data.is_empty():
		menu.build_menu.read(settings.world_name, player.spell_caster)
	else:
		menu.build_menu.load_data(level_build_data, player.spell_caster)
	for proj in menu.build_menu.projectiles_in_world:
		proj.time_stamp = 0.0
		insert_spell(proj)
	if settings.is_editing_level:
		is_in_testing_mode = true
		for item in menu.build_menu.items_in_world:
			item.custom_free = remove_world_item
			add_child(item)
		for enemy in menu.build_menu.enemies_in_world:
			add_enemy(enemy)
	else:
		is_in_testing_mode = false
		for item in menu.build_menu.items_in_world:
			if not (item is Flag) and not entity_name_is_marked(item.name):
				item.custom_free = remove_world_item
				add_child(item)
		for enemy in menu.build_menu.retrieve_enemies_based_on_flag_state():
			if enemy.get_parent() == null and not entity_name_is_marked(enemy.name):
				add_enemy(enemy)
		for flag in menu.build_menu.retrieve_flags_based_on_flag_state():
			if flag.get_parent() == null and not entity_name_is_marked(flag.name):
				flag.custom_free = remove_world_item
				add_child(flag)
	
	player.position = settings.player_position
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
	
	menu.build_menu.test_mode_changed.connect(test_mode_changed)
	menu.build_menu.world_radius_changed.connect(update_world_radius)
	
	book.spell_was_updated.connect(func(spell: Spell) -> void:
		for item in menu.build_menu.items_in_world:
			if item is SpellPaper:
				var paper := item as SpellPaper
				if paper.spell != null and paper.spell.name == spell.name:
					paper.spell = spell
	)
	
	world_boundary_y_minus.position.y = 900.0
	world_boundary_x_minus.position.x = -settings.world_radius
	world_boundary_x_plus.position.x = settings.world_radius
	world_boundary_z_minus.position.z = -settings.world_radius
	world_boundary_z_plus.position.z = settings.world_radius
	update_world_boundary()
	
	await RenderingServer.frame_post_draw
	(player.interface.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("texture_albedo", sub_viewport.get_texture())
	sub_viewport_container.visible = true
	
	if settings.is_shared_online != -1:
		HttpLevels.begin_level_user_data_play(settings.is_shared_online)

func _exit_tree() -> void:
	if settings.is_shared_online != -1:
		HttpLevels.save_level_user_data_play(settings.is_shared_online)
	AudioManager.world = null
	AudioManager.camera = null

func _process(delta: float) -> void:
	if not settings.is_editing_level:
		if not settings.is_paused:
			settings.current_time += delta
		($FPS as Label).text = ""
		var score_text := ""
		if settings.track_score:
			score_text = "Score: " + str(settings.current_score)
		if settings.track_time:
			if not score_text.is_empty():
				score_text += " "
			score_text += "Time: " + Globals.format_seconds_into_minute_and_seconds(settings.current_time)
		hud.objective_label.text = "[right][font_size=24]%s[/font_size][/right]" % score_text
	else:
		($FPS as Label).text = "[EDIT MODE] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
		
	
	
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
	playtime_tick += delta

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
		
	if playtime_tick >= 300.0:
		if settings.is_shared_online != -1:
			HttpLevels.save_level_user_data_play(settings.is_shared_online)
		playtime_tick = 0.0

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
	
func remove_world_item(this: WorldItem) -> void:
	remove_child(this)
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("tab_menu"):
		menu.is_quick_menu = false
		toggle_menu()
	elif event.is_action_pressed("esc_menu"):
		menu.is_quick_menu = GlobalData.controller.get_has_tab_menu_key()
		toggle_menu()
		
	Input.stop_joy_vibration(event.device)
			
	if not menu.is_showing and hud.visible:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				player.pan_camera((event as InputEventMouseMotion).relative * settings.camera_settings.panning_speed())
				hud.update_compass_position(player.cam_pivot.rotation.y, player.position)
		
	if not menu.is_showing and hud.visible:
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
						elif node_to_track is Enemy:
							menu.build_menu.delete_enemy(node_to_track as Enemy)
				elif option.kind == Wand.Kind.PLACE_ITEM or option.kind == Wand.Kind.PLACE_PICKED:
					if option.kind == Wand.Kind.PLACE_PICKED:
						wand.get_spell(option, book, action_option)
						option = action_option.data
					var cdir := Vector3.ZERO
					var port := get_viewport()
					var pos := port.get_visible_rect().size / 2.0
					var coord := port.get_camera_3d().project_ray_origin(pos)
					cdir = port.get_camera_3d().project_ray_normal(pos)
					var place_pos := Navigator.get_ray_intersection_point_of_node(player, coord, coord + cdir * 500, Globals.Layer.WORLD | Globals.Layer.OBJECT | Globals.Layer.BOUNDARY)
					var spell := option.get_spell()
					if not place_pos.is_finite():
						hud.show_notification("Can not place there", 3.0)
					elif spell != null:
						var paper := SpellPaper.make()
						paper.spell = spell
						paper.set_base_position(place_pos)
						paper.custom_free = remove_world_item
						add_child(paper)
						SignalBus.item_added_to_world.emit(paper)
					else:
						option.next_spell()
						var spell_name := option.get_spell_name()
						if spell_name == "health":
							var cross := RedCross.make()
							cross.health = ((option.parameters[option.spell_index] as Dictionary).get("0", "0") as String).to_float() / 100.0
							cross.set_base_position(place_pos)
							cross.custom_free = remove_world_item
							add_child(cross)
							SignalBus.item_added_to_world.emit(cross)
						elif spell_name == "coin":
							var coin := CoinDisc.make()
							coin.amount = ((option.parameters[option.spell_index] as Dictionary).get("0", "0") as String).to_int()
							coin.set_base_position(place_pos)
							coin.custom_free = remove_world_item
							add_child(coin)
							SignalBus.item_added_to_world.emit(coin)
						elif spell_name == "artifact":
							var cube := ArtifactCube.make()
							var art_name := (option.parameters[option.spell_index] as Dictionary).get("0", "") as String
							for art in artifacts.collection:
								if art.name == art_name:
									cube.artifact = art
									break
							cube.set_base_position(place_pos)
							cube.custom_free = remove_world_item
							add_child(cube)
							SignalBus.item_added_to_world.emit(cube)
						elif spell_name == "enemy":
							var opts := option.parameters[option.spell_index] as Dictionary
							var enemy_name := opts.get("0", "") as String
							var enemy_level := (opts.get("1", "1") as String).to_int()
							var enemy_flag := (opts.get("2", "1") as String).to_int()
							var enemy_score := (opts.get("3", "0") as String).to_int()
							var enemy_kind := World.Enemy.NONE
							var idx := 0
							for kind: String in World.Enemy:
								if enemy_name.to_lower() == kind.to_lower():
									enemy_kind = idx as World.Enemy
									break
								idx += 1
							if enemy_kind != World.Enemy.NONE:
								var enemy := Population.generate_enemy(enemy_kind, player, place_pos.x, place_pos.y, place_pos.z, enemy_level)
								enemy.level_flag = enemy_flag
								enemy.level_score = enemy_score
								add_enemy(enemy)
								SignalBus.enemy_added_to_world.emit(enemy)
						elif spell_name == "flag":
							var flag := Flag.make()
							flag.tag = ((option.parameters[option.spell_index] as Dictionary).get("0", "0") as String).to_int()
							flag.set_base_position(place_pos)
							flag.custom_free = remove_world_item
							add_child(flag)
							SignalBus.item_added_to_world.emit(flag)
						elif spell_name == "note":
							var note := ScrollNote.make()
							note.note_id = (option.parameters[option.spell_index] as Dictionary).get("0", "0") as String
							note.set_base_position(place_pos)
							note.custom_free = remove_world_item
							add_child(note)
							SignalBus.item_added_to_world.emit(note)
				

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

func add_enemy(enemy: Enemy) -> void:
	inhabitants.append(enemy)
	enemy.is_dead = settings.is_editing_level
	enemy.is_idle = settings.is_editing_level
	enemy.invunerable = INF if settings.is_editing_level else 0.0
	add_child(enemy)
	enemy.animation_tree.active = true
		
func update_world_radius(radius: float) -> void:
	world_boundary_x_minus.position.x = -radius
	world_boundary_x_plus.position.x = radius
	world_boundary_z_minus.position.z = -radius
	world_boundary_z_plus.position.z = radius
	(ground.mesh as PlaneMesh).size = Vector2(radius * 2, radius * 2)
	(ground_collision.shape as BoxShape3D).size = Vector3(radius * 2, 1, radius * 2)
		
func update_world_boundary() -> void:
	world_boundary_x_minus.position.z = player.position.z
	world_boundary_x_minus.position.y = player.position.y
	world_boundary_x_plus.position.z = player.position.z
	world_boundary_x_plus.position.y = player.position.y
	world_boundary_z_minus.position.x = player.position.x
	world_boundary_z_minus.position.y = player.position.y
	world_boundary_z_plus.position.x = player.position.x
	world_boundary_z_plus.position.y = player.position.y
	world_boundary_y_minus.position.x = player.position.x
	world_boundary_y_minus.position.z = player.position.z
	(world_boundary_x_minus_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("fade_amount", clampf((1.0 - player.position.distance_to(world_boundary_x_minus.position) / 256.0) ** 3.0 * 2.0, 0.0, 1.0))
	(world_boundary_x_plus_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("fade_amount", clampf((1.0 - player.position.distance_to(world_boundary_x_plus.position) / 256.0) ** 3.0 * 2.0, 0.0, 1.0))
	(world_boundary_z_minus_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("fade_amount", clampf((1.0 - player.position.distance_to(world_boundary_z_minus.position) / 256.0) ** 3.0 * 2.0, 0.0, 1.0))
	(world_boundary_z_plus_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("fade_amount", clampf((1.0 - player.position.distance_to(world_boundary_z_plus.position) / 256.0) ** 3.0 * 2.0, 0.0, 1.0))


func _on_player_moved(delta: float) -> void:
	update_world_boundary()
	hud.update_compass_position(player.cam_pivot.rotation.y, player.position)


func quit_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://GUI/Menu/MainMenu.tscn")

func mark_entity(entity: Node3D) -> void:
	mark_entity_name(entity.name)
	
func mark_world_item_entity(entity: WorldItem, x: Variant, y: Variant) -> void:
	mark_entity_name(entity.name)

func mark_entity_name(ename: String) -> void:
	if not player.world_settings.marked_entities.has(Vector2i.ZERO):
		settings.marked_entities[Vector2i.ZERO] = []
	(settings.marked_entities[Vector2i.ZERO] as Array[String]).append(ename)
	
func entity_name_is_marked(ename: String) -> bool:
	return (settings.marked_entities.get(Vector2i.ZERO, []) as Array[String]).find(ename) != -1

func reset_wand_and_magic_book(is_editing: bool, delete_wands: bool) -> void:
	book.reset_by_deleting_all_spells()
	if delete_wands:
		case.reset_by_deleting_all_wands()
	else:
		case.reset_by_setting_is_for_user(book)
	case.is_build_mode = is_editing
	wand = case.current_wand()
	hud.wand = wand
	menu.magic_book.update_book_without_selection()
	menu.wand_case.reload_wand_shelf_items(case.selected_wand, true)
	menu.wand_case.case.save(settings.world_name)
	menu.magic_book.book.save(settings.world_name)

func _on_player_vital_update(vitals: Vitals) -> void:
	if settings == null or settings.game_mode_settings == null:
		return
	
	match settings.game_mode_settings.mode:
		GameModeSettings.GameMode.RESPAWN:
			if vitals.health.value > 0:
				return
				
			settings.is_paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			UIAudioPlayer.hurt()
			player.play_animation("death")
			var subtitle_components := []
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_ARTIFACTS == 0:
				subtitle_components.append("Artifacts")
				artifacts.reset_by_deleting_all_artifacts()
				menu.artifacts.update_list_and_grid()
				menu.artifacts.artifacts.save(settings.world_name)
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_UPGRADES == 0:
				subtitle_components.append("Upgrades")
				settings.upgrade_settings.reset_all_stats_to_default_values()
				menu.upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
				menu.upgrades.settings.save()
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS == 0:
				subtitle_components.append("Spells")
				reset_wand_and_magic_book(false, true)
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_COINS == 0:
				subtitle_components.append("Coins")
				settings.upgrade_settings.currency = 0
				menu.upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
				menu.upgrades.settings.save()
				
			settings.player_position = player.position
			settings.player_health = player.vitals.health.max_value
			settings.player_mana = player.vitals.mana.max_value
			settings.last_save_time = Time.get_unix_time_from_system()
			settings.save()
			hud.hide()
			
			for enemy: Enemy in player.enemies_in_range:
				enemy.vitals.reset()
				
			var subtitle := ""
			if subtitle_components.size() == 1:
				subtitle = subtitle_components[0] + " have been removed"
			elif subtitle_components.size() == 2:
				subtitle = subtitle_components[0] + " and " + subtitle_components[1] + " have been removed"
			elif subtitle_components.size() == 3:
				subtitle = subtitle_components[0] + ", " + subtitle_components[1] + " and " + subtitle_components[2] + " have been removed"
			elif subtitle_components.size() == 4:
				subtitle = subtitle_components[0] + ", " + subtitle_components[1] + ", " + subtitle_components[2] + " and " + subtitle_components[3] + " have been removed"
			var overlay := OverlayScreen.display("DEATH", subtitle, "Revive")
			overlay.confirmed.connect(func() -> void:
				player.play_animation("revive")
				hud.show()
				settings.is_paused = false
				vitals.reset()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			)
			overlay.show_in_root(self)
			
			
		GameModeSettings.GameMode.PERMADEATH:
			if vitals.health.value > 0:
				return
			
			UIAudioPlayer.hurt()
			player.play_animation("death")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			settings.is_paused = true
			hud.hide()
			GlobalData.game_settings.last_world = ""
			GlobalData.game_settings.save()
			GlobalData.remove_folder_that_only_has_files("user://worlds/%s" % (settings.world_name))
			var overlay := OverlayScreen.display("DEATH", "Game Over", "Main Menu")
			overlay.confirmed.connect(func() -> void:
				SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "fade_to_black")
			)
			overlay.show_in_root(self)
			
func win_condition_met() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	settings.is_paused = true
	hud.hide()
	var overlay := OverlayScreen.display("VICTORY", "You've Beaten the Level", "Edit Mode" if is_in_testing_mode else "Main Menu")
	overlay.confirmed.connect(func() -> void:
		if is_in_testing_mode:
			if not settings.is_editing_level:
				reset_wand_and_magic_book(true, false) # NOTE: set to true because we are switching into editing mode
				settings.save()
			menu.build_menu.switch_editing_mode(not settings.is_editing_level)
			hud.show()
			settings.is_paused = false
			player.vitals.reset()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			if settings.current_score > settings.best_score:
				settings.best_score = settings.current_score
			if settings.current_time < settings.best_time:
				settings.best_time = settings.current_time
			settings.is_editing_level = true
			reset_wand_and_magic_book(false, false)
			settings.save()
			menu.build_menu.reset_level_when_playing()
			menu.save_changes()
			menu.build_menu.save(settings.world_name)
			SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "fade_to_black")
	)
	overlay.show_in_root(self)

func test_mode_changed(is_editing: bool) -> void:
	settings.marked_entities.clear()
	
	case.is_build_mode = is_editing
	reset_wand_and_magic_book(is_editing, false)
	if is_editing:
		book.reset_by_deleting_all_spells()
		book.read_absolute_path("user://universal_magic_book.json", false)
		book.rebuild_spell_chains()
	else:
		book.reset_by_deleting_all_spells()
		book.read(settings.world_name, false)
		book.rebuild_spell_chains()
	menu.magic_book.current_index = -1
	menu.wand_case.reload_wand_shelf_items(case.selected_wand, true)
	hud.wand = menu.wand_case.case.current_wand()
	
	for proj in menu.build_menu.projectiles_in_world:
		proj.time_stamp = 0.0
	for item in menu.build_menu.items_in_world:
		if item.get_parent() == null:
			if item is CoinDisc:
				(item as CoinDisc).eaten = false
			elif item is SpellPaper:
				(item as SpellPaper).eaten = false
			elif item is RedCross:
				(item as RedCross).eaten = false
			elif item is Flag:
				(item as Flag).eaten = false
			item.reset_to_original()
			add_child(item)
	for enemy in menu.build_menu.enemies_in_world:
		if enemy.get_parent() == null:
			add_enemy(enemy)
			
	player.vitals.reset()
	menu.artifacts.update_list_and_grid()
	settings.current_time = 0.0
	settings.current_score = 0
	
	for enemy in inhabitants:
		enemy.vitals.reset()
		enemy.is_dead = is_editing
		enemy.invunerable = INF if is_editing else 0.0
		enemy.animation_tree.active = true
		
	if not is_editing:
		for item in menu.build_menu.items_in_world:
			if item is Flag:
				remove_child(item)
		for enemy in menu.build_menu.enemies_in_world:
			remove_child(enemy)
		menu.build_menu.current_flags_in_world.clear()
		menu.build_menu.current_enemies_in_world.clear()
		menu.build_menu.item_flag_state.clear()
		menu.build_menu.enemy_flag_state.clear()
		
		for enemy in menu.build_menu.retrieve_enemies_based_on_flag_state():
			add_enemy(enemy)
		for flag in menu.build_menu.retrieve_flags_based_on_flag_state():
			add_child(flag)
