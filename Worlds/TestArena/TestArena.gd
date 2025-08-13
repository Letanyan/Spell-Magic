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
		if settings.game_mode_settings.has_flag(GameModeSettings.SPELL_DECK_BUILDING):
			menu.spell_deck.update_cards()
	)
	player.name_generator = NameGenerator.new()
	player.name_generator.read(settings.world_name)
	player.set_current_biome(World.Biome.GRASSLAND)
	#player.play_bg_audio(World.Biome.WATER)
	
	case = WandCase.new()
	case.read(settings.world_name, book)
	book.spell_was_updated.connect(case.spell_was_updated)
	
	artifacts = Artifacts.new()
	artifacts.read(settings.world_name)
	
	#for i in ["flower", "feather", "goblet", "sands", "crown"]:
		#var artifact := Artifact.new(i)
		#artifact.fill(
			#[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT],
			#randf() < 0.5,
			#{ Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 10, },
			#{ Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 10, },
			#{ Artifact.Element.FIRE: 10 },
			#{ Artifact.Element.FIRE: 10 },
			#{ Artifact.Pattern.CIRCLE: 10, Artifact.Pattern.TRIANGLE: 2 },
			#Vector2i(7, 3),
		#)
		#artifacts.collection.append(artifact)
	
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
	
	#make_targets()
	#make_line_targets()
	
	const pX = 100
	const pY = 100
	const LVL = 20
	var enemy := Population.generate_enemy(World.Enemy.BAT, player, pX / 2.5, 1000, pY / 2.5, LVL)
	add_enemy(enemy)
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
	
	#var rng := RandomNumberGenerator.new()
	spawner = ItemSpawner.key_spawner(null, Vector3(20, 1000, 20), 16)
	#spawner.add_condition(fishman)
	
	#var h := Vec3.y(10)
	#var center := Vector2(0, 0)
	#var pathway := Pathway.new().wait(1.0).apply_transform(Transform3D.IDENTITY.translated(h))
	#var path := PathStyle.new(0, Vec3.xz(center)).follow_path(pathway).align_y_to_ground_air_and_dirt().look_at_nothing()
	#var platform_scale := 15.0
	#var config := TargetShape.config_for_platform(Spell.Element.ROCK, platform_scale, path, true)
	#var platform := TargetShape.make()
	#platform.configure(config)
	#var wh := 1000.0
	#platform.position.y = h.y + wh
	#platform.caster_target_position = Vec3.xz(center) + Vec3.y(h.y + wh + platform.bounds.y + player.bounds.y * 0.5)
	#var arc := GlobalData.magic_book.copy_spell("arc")
	#arc.configure({"R": "pi/2", "s": "10"}, Spell.Element.AIR, 2, 0, 0.5, 8, 0, 0, 0)
	#var pattern := AttackPatterns.new([arc], AttackPatterns.choose_from_distribution(5, [1], 1))
	#platform.attack_sequence = AttackSequence.new(true, [
		#PathStyle.new(0, Vec3.xz(center)).follow_path(Pathway.new().wait(0.1, Vector3(platform_scale, h.y + platform.bounds.y, 0))).align_y_to_origin(),
		#pattern,
		#PathStyle.new(0, Vec3.xz(center)).follow_path(Pathway.new().wait(0.1, Vector3(0, h.y + platform.bounds.y, platform_scale))).align_y_to_origin(),
		#pattern,
		#PathStyle.new(0, Vec3.xz(center)).follow_path(Pathway.new().wait(0.1, Vector3(-platform_scale, h.y + platform.bounds.y, 0))).align_y_to_origin(),
		#pattern,
		#PathStyle.new(0, Vec3.xz(center)).follow_path(Pathway.new().wait(0.1, Vector3(0, h.y + platform.bounds.y, -platform_scale))).align_y_to_origin(),
		#pattern,
	#])
	#
	#add_child(platform)
	
	#var T := Transform3D.IDENTITY.rotated(Vector3.FORWARD, PI / 2).translated(Vector3.UP * 10)
	#var RT := Transform3D.IDENTITY.rotated(Vector3.UP, TAU / 3)
	#var circle_path := Pathway.new().move_to(Vector3.ZERO).circle_with_speed(4, 2, 1)
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
	#spawner.add_condition(target1)
	#spawner.add_condition(target2)
	#spawner.add_condition(target3)
	#
	#add_child(target1)
	#add_child(target2)
	#add_child(target3)
	#
	#
	#
	#var path4 := PathStyle.new(0, Vector3(20, 1000, 20)).follow_path(Pathway.new().move_to(Vector3(0, 0, 0)).line_to(Vector3(0, 10, 10), 5).line_to(Vector3.ZERO, 5)).align_y_to_ground_and_air().look_at_nothing()
	#var target4 := TargetShape.make()
	#target4.configure(TargetShape.config_for_platform(Spell.Element.ROCK, 5, path4))
	#add_child(target4)
	
func make_targets() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var pos := Vector2(20, 20)
	var cursor := Vector3.ZERO
	var direction := Vector3.UP
	var distance := 0.0
	for i in rng.randi_range(1, 2) * 2:
		distance = rng.randf_range(10, 20)
		var dest := cursor + direction * distance
		var pathway: Pathway
		if i % 2 == 0:
			pathway = Pathway.new().from_to_and_back(distance * 0.5, cursor, dest, Easing.in_out_quad)
		else:
			pathway = Pathway.new().from_to_and_back(distance * 0.5, dest, cursor, Easing.in_out_quad)
		var path := PathStyle.new(0, Vec3.xz__y(pos, 0)).follow_path(pathway).align_y_to_ground().look_at_nothing()
		var config := TargetShape.config_for_platform(Spell.Element.ROCK, 5, path)
		var p := TargetShape.make()
		p.configure(config)
		if p != null:
			add_child(p)
			var offset_dir: Vector2 = -Vec2.xz(direction)
			while offset_dir.is_equal_approx(-Vec2.xz(direction)):
				offset_dir = Rand.entity_from_distribution(rng.randf(), {Vector2.LEFT: 1, Vector2.RIGHT: 1, Vector2.UP: 1, Vector2.DOWN: 1}) as Vector2
			cursor += (direction * distance) + Vec3.xz(offset_dir) * p.bounds
			direction = Rand.entity_from_distribution(rng.randf(), {Vector3.UP: 5, Vector3.DOWN: 1, Vector3.LEFT: 1, Vector3.RIGHT: 1, Vector3.FORWARD: 1, Vector3.BACK: 1}) as Vector3
	
func make_line_targets() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var pos := Vector2(20, 20)
	var pos3d := Vec3.xz__y(pos, 2)
	var dist := 10.0 # pop.fit(1, pop.fit(5, 15))
	var path := Pathway.new().line_to(Vector3(dist, 0, 0), 1).line_to(Vector3(dist, 0, dist), 1).line_to(Vector3(0, 0, dist), 1).line_to(Vector3(0, 0, 0), 1).apply_transform(T.translated(Vector3(dist, 0, dist) * -0.5))
	var count := 10 # pop.fiti(2, 20)
	var el := Spell.Element.values()[rng.randi_range(1, Spell.Element.values().size() - 1)] as Spell.Element
	#var spawner := ItemSpawner.coins_spawner(pop, pop.get_ground_level(pos, 2), [10, 5, 10, 5, 10])
	var focus_point: Vector3
	const UP = 0
	const CENTER = 1
	const HORZ = 2
	var facing_tangent := rng.randf() * TAU
	var is_horz := true # rng.randf() < pop.fit(0.0, 0.9)
	var tform: Transform3D
	if is_horz:
		tform = T.I
	else:
		tform = T.rotated(Vector3.FORWARD.rotated(Vector3.UP, facing_tangent), PI * 0.5).translated(Vec3.y(dist * 0.5))
	var kind := CENTER # Rand.entity_from_distribution(rng.randf(), {UP: 1, CENTER: 1, HORZ: 1}) as int
	if kind == UP:
		focus_point = pos3d + Vec3.y(999_999)
	elif kind == CENTER:
		focus_point = pos3d + tform * Vector3.ZERO
	elif kind == HORZ:
		focus_point = pos3d + Vec3.polar(999_999, facing_tangent)
	var make_circle_path := func(pos: Vector3, speed: float) -> Pathway:
		return Pathway.new().move_to(pos).arc_to(pos.rotated(Vector3.UP, PI), true, speed).arc_to(pos, true, speed)
	var make_still_path := func(pos: Vector3, speed: float) -> Pathway:
		return Pathway.new().wait(5, pos)
	var moving_path := Rand.entity_from_distribution(rng.randf(), {make_circle_path: 0, make_still_path: 10}) as Callable
		
	for p in path.sample_points(count):
		var s := p.length() * TAU * 0.1
		var subpath := moving_path.call(p, s) as Pathway
		var path_style := PathStyle.new(0, pos3d).follow_path(subpath).align_y_to_ground_and_air().look_at_player().transform_path(tform).origin_is_offset()
		var config := TargetShape.config_for_gauge(el, null, 2.0, Vitals.default_ea(0.1, 0), path_style)
		var target := TargetShape.make()
		target.configure(config)
		if kind == CENTER:
			target.focus_point = focus_point + Vec3.y(1000.0) # Vec3.y(pos.get_ground_level(focus_point).y)
		else:
			target.focus_point = focus_point
		add_child(target)
		#spawner.add_condition(target)

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
	player.world_settings = settings
	menu.setup(book, case, artifacts, settings, player)
	
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
		for turret: SpellBody in spells_on_hold[turret_key]:
			turret.update_display(delta)
			
			
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
			
	test_tick -= delta
	const UPDATE = 2.0
	if test_tick < 0.0:
		test_tick = UPDATE
		var collision := $rigid_block/CollisionShape3D as CollisionShape3D
		var V := Terrain._height_at_position(collision, player.position.x, player.position.z)
		Debug3D.draw_sphere(Vec3.xz_y(player.position, V.w + collision.global_position.y), 0.3, Color.BLUE, UPDATE)
		#var normal := Vector3(V.x, V.y, V.z)
		#Debug3D.draw_arrow_ray(player.position, normal, 2, Color.RED, 0.5, false, UPDATE)
		var hmap := collision.shape as HeightMapShape3D
		var S := collision.scale.x
		var w := (hmap.map_width - 1) * collision.scale.x
		var d := (hmap.map_depth - 1) * collision.scale.x
		var x := -w / 2.0
		var z := -d / 2.0
		var s := S * 0.5
		for c in range(x, -x, S):
			for r in range(z, -z, S):
				var X := (c + s + collision.global_position.x) 
				var Y := (r + s + collision.global_position.z)
				var h := Terrain._height_at_position(collision, X, Y).w
				var p := Vector3(c + s, h, r + s) + collision.global_position
				Debug3D.draw_sphere(p, 0.1, Color.BLACK, UPDATE)

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
	settings.player_camera = player.camera_coords()
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
			if event.is_action_pressed(k):
				var hold_spell := Globals.Ref.new(null)
				s = wand.action_down(k, book, is_rapid_fire, hold_spell)
				is_down = true
				if hold_spell.data != null:
					spells_on_hold[k] = player.project_spell(insert_spell, hold_spell.data as Spell)
			if event.is_action_released(k):
				s = wand.action_up(k, book)
				if spells_on_hold.has(k):
					for t: SpellBody in spells_on_hold[k]:
						SpellBuffer.free_projectile(t)
					spells_on_hold.erase(k)
			if s != null:
				cast_spell_with_recusive_check_for_rapid_fire(s, is_down and is_rapid_fire.data as bool)
				

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
