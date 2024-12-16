class_name ArtifactsGUI
extends Control

@onready var artifacts_list: ItemList = $artifacts_list
@onready var artifact_grid: InfinityGrid = $artifact_grid
@onready var artifact_preview: GridTile = $artifact_preview
@onready var destroy_artifact: Button = $Destroy
@onready var effects_list: Label = $effects_list

@onready var filter_top: MenuButton = $Top
@onready var filter_left: MenuButton = $Left
@onready var filter_right: MenuButton = $Right
@onready var filter_bottom: MenuButton = $Bottom
@onready var filter_all: MenuButton = $FilterAll

var filter_top_options := FilterOptions.new()
var filter_left_options := FilterOptions.new()
var filter_right_options := FilterOptions.new()
var filter_bottom_options := FilterOptions.new()
var filter_all_options := FilterOptions.new()

var temporary_grid_tile: GridTile

var double_click_timer: Dictionary = {} ## [int(MOUSE_BUTTON_INDEX)]bool(is_clicked)

var artifacts: Artifacts:
	set(value):
		artifacts = value
		update_list_and_grid()

var list_mouse_down := false

var is_first_view: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	temporary_grid_tile = GridTile.new()
	temporary_grid_tile.is_temporary = true
	artifact_grid.add_grid_tile(temporary_grid_tile, Vector2.ZERO)
	
	filter_top.get_popup().id_pressed.connect(func(id: int) -> void: filter_id_pressed(filter_top, id, filter_top_options))
	filter_left.get_popup().id_pressed.connect(func(id: int) -> void: filter_id_pressed(filter_left, id, filter_left_options))
	filter_right.get_popup().id_pressed.connect(func(id: int) -> void: filter_id_pressed(filter_right, id, filter_right_options))
	filter_bottom.get_popup().id_pressed.connect(func(id: int) -> void: filter_id_pressed(filter_bottom, id, filter_bottom_options))
	filter_all.get_popup().id_pressed.connect(func(id: int) -> void: filter_id_pressed(filter_all, id, filter_all_options))
	
func update_temporary_grid_tile() -> void:
	temporary_grid_tile.is_hidden = false
	if artifact_grid.selected_cell_coord:
		artifact_grid.remove_grid_tile(temporary_grid_tile)
		attempt_place_artifact(temporary_grid_tile.artifact, artifact_grid.selected_cell_coord as Vector2, true)
		artifact_grid.add_grid_tile(temporary_grid_tile, artifact_grid.selected_cell_coord as Vector2)
		
	#elif temporary_grid_tile.artifact != null and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#temporary_grid_tile.is_hidden = true
		
	temporary_grid_tile.queue_redraw()
		
func update_artifact_list_height() -> void:
	var should_disconnect_artifact := false
	if artifact_grid.selected_cell_coord != null:
		var grid_artifact := artifacts.get_artifact_at_coord(artifact_grid.selected_cell_coord as Vector2)
		should_disconnect_artifact = grid_artifact != null
	if artifact_preview.artifact == null and not should_disconnect_artifact:
		artifacts_list.set_deferred("size", Vector2(artifacts_list.size.x, size.y - artifacts_list.position.y - 8))
	elif should_disconnect_artifact:
		artifacts_list.set_deferred("size", Vector2(artifacts_list.size.x, destroy_artifact.position.y - artifacts_list.position.y - 8))
	else:
		artifacts_list.set_deferred("size", Vector2(artifacts_list.size.x, artifact_preview.position.y - artifacts_list.position.y - 8))
	destroy_artifact.text = "Destroy" if artifact_preview.artifact != null else "Disconnect"
	destroy_artifact.visible = artifact_preview.artifact != null or should_disconnect_artifact
	
	
func update_list() -> void:
	artifacts_list.clear()
	var found_preview := false
	if artifact_grid.selected_cell_coord == null:
		for a in artifacts.unconnected():
			if filter_artifact_matches(a):
				artifacts_list.add_item(a.name)
				if a == artifact_preview.artifact:
					found_preview = true
	else:
		for a in artifacts.unconnected():
			if filter_artifact_matches(a) and artifacts.can_place_artifact(a, artifact_grid.selected_cell_coord as Vector2).is_empty():
				artifacts_list.add_item(a.name)
				if a == artifact_preview.artifact:
					found_preview = true
	if not found_preview:
		artifact_preview.artifact = null
		artifact_preview.queue_redraw()
		update_artifact_list_height()
	else:
		for idx: int in artifacts_list.item_count:
			if artifacts.get_artifact_by_name(artifacts_list.get_item_text(idx)) == artifact_preview.artifact:
				artifacts_list.select(idx)
				break
	highlight_all_available_cells_for_placement()

func update_list_and_grid() -> void:
	update_list()
	for c in artifact_grid.get_children():
		if c != temporary_grid_tile:
			c.queue_free()
		else:
			artifact_grid.remove_grid_tile(temporary_grid_tile)
	artifact_grid.child_grid.clear()
	for a: Artifact in artifacts.connected:
		var v := artifacts.connected[a] as Vector2
		var g := GridTile.new()
		g.artifact = a
		g.highlighted = artifacts.active_options.get(v, {})
		artifact_grid.add_grid_tile(g, v)
	
	var possible_moves := artifacts.highlight_all_available_cells_for_placement(temporary_grid_tile.artifact)
	for move in possible_moves:
		if move == artifact_grid.selected_cell_coord:
			update_selected_artifact()
			
	update_effects_list_tooltip()
	
	if is_first_view:
		is_first_view = false
		artifact_grid.center_grid_on_first_cell()

func update_selected_artifact() -> void:
	if artifacts_list.get_selected_items().is_empty():
		return
	var index := artifacts_list.get_selected_items()[0]
	var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(index))
	if artifact == null:
		return
	artifact_preview.artifact = artifact
	temporary_grid_tile.artifact = artifact
	artifact_preview.queue_redraw()
	update_artifact_list_height()
	if artifact_grid.selected_cell_coord:
		update_temporary_grid_tile()
	highlight_all_available_cells_for_placement()

func _on_artifacts_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		update_selected_artifact()
		if double_click_timer.get(mouse_button_index, false):
			confirm_place_artifact_from_list()
		else:
			get_tree().create_timer(0.3).timeout.connect(func() -> void: double_click_timer[mouse_button_index] = false)
			double_click_timer[mouse_button_index] = true

func _on_artifact_grid_on_cell_clicked(coord: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		disconnect_artifact(coord)
	elif mouse_button_index == MOUSE_BUTTON_LEFT:
		if not artifacts_list.get_selected_items().is_empty():
			var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(artifacts_list.get_selected_items()[0]))
			temporary_grid_tile.artifact = artifact
			attempt_place_artifact(artifact, coord, false)
			
func _on_artifact_grid_on_cell_selected(coord: Vector2, old_coord: Vector2) -> void:
	update_list_and_grid()

func attempt_place_artifact(artifact: Artifact, coord: Vector2, temporarily: bool) -> void:	
	const WARN_COLOR = Color.RED
	const WARN_INTERVAL = 0.1
	const WARN_COUNT = 5
	
	var errors := artifacts.can_place_artifact(artifact, coord)
	for error: Vector4 in errors:
		if error.x == coord.x and error.y == coord.y:
			continue
		else:
			(artifact_grid.child_grid[Vector2(error.x, error.y)] as GridTile).warn(int(error.z) as GridTile.Direction, int(error.w) as GridTile.Level, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
		
	if not temporarily:
		temporary_grid_tile.artifact = null
		
	if not errors.is_empty():
		return
		
	if not temporarily:
		artifacts.connect_to_grid(artifact, coord)
		update_list_and_grid()
	else:
		temporary_grid_tile.queue_redraw()
		
	artifact_grid.center_grid_on_cell(coord)
	
func attempt_remove_artifact(coord: Vector2) -> bool:
	var artifact: Artifact = artifacts.get_artifact_at_coord(coord)
	if artifact == null:
		return false
		
	const WARN_COLOR = Color.RED
	const WARN_INTERVAL = 0.1
	const WARN_COUNT = 5
	
	var is_valid: bool = artifacts.is_still_continuous_after_removing(coord)
	if not is_valid:
		if artifacts.get_artifact_at_coord(coord + Vector2(0, -1)):
			(artifact_grid.child_grid[coord + Vector2(0, -1)] as GridTile).warn(GridTile.Direction.BOTTOM, GridTile.Level.TOP, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			(artifact_grid.child_grid[coord + Vector2(0, -1)] as GridTile).warn(GridTile.Direction.BOTTOM, GridTile.Level.PATTERN, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			
		if artifacts.get_artifact_at_coord(coord + Vector2(0, 1)):
			(artifact_grid.child_grid[coord + Vector2(0, 1)] as GridTile).warn(GridTile.Direction.TOP, GridTile.Level.TOP, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			(artifact_grid.child_grid[coord + Vector2(0, 1)] as GridTile).warn(GridTile.Direction.TOP, GridTile.Level.PATTERN, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			
		if artifacts.get_artifact_at_coord(coord + Vector2(-1, 0)):
			(artifact_grid.child_grid[coord + Vector2(-1, 0)] as GridTile).warn(GridTile.Direction.RIGHT, GridTile.Level.TOP, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			(artifact_grid.child_grid[coord + Vector2(-1, 0)] as GridTile).warn(GridTile.Direction.RIGHT, GridTile.Level.PATTERN, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			
		if artifacts.get_artifact_at_coord(coord + Vector2(1, 0)):
			(artifact_grid.child_grid[coord + Vector2(1, 0)] as GridTile).warn(GridTile.Direction.LEFT, GridTile.Level.TOP, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			(artifact_grid.child_grid[coord + Vector2(1, 0)] as GridTile).warn(GridTile.Direction.LEFT, GridTile.Level.PATTERN, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
		
		return false
		
		
	var was_removed := false
	for a: Artifact in artifacts.connected:
		if artifacts.connected[a] == coord:
			artifacts.unconnect_from_grid(a)
			was_removed = true
			break
			
	if not was_removed:
		temporary_grid_tile.artifact = null
		update_temporary_grid_tile()
	elif temporary_grid_tile.artifact != null:
		artifact_grid.remove_tile_at_coord(coord)
		artifact_grid.remove_grid_tile(temporary_grid_tile)
		artifact_grid.add_grid_tile(temporary_grid_tile, coord)
		attempt_place_artifact(temporary_grid_tile.artifact, coord, true)
		update_list()
	else:
		update_list_and_grid()
		
	return was_removed

func _on_artifacts_list_item_selected(index: int) -> void:
	update_selected_artifact()
	
func _on_artifact_grid_on_cell_unselected(coord: Vector2) -> void:
	artifact_grid.selected_cell_coord = null
	temporary_grid_tile.artifact = null
	update_list_and_grid()

func _on_artifacts_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_action_pressed("ui_accept"):
			confirm_place_artifact_from_list()
		elif event.is_action_pressed("E"):
			print("hello")
			deselect_all()
			
func confirm_place_artifact_from_list() -> void:
	if not artifacts_list.get_selected_items().is_empty():
		var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(artifacts_list.get_selected_items()[0]))
		temporary_grid_tile.artifact = artifact
		if artifact_grid.selected_cell_coord != null:
			attempt_place_artifact(artifact, artifact_grid.selected_cell_coord as Vector2, false)
			artifact_grid.selected_cell_coord = null
			update_list_and_grid()
		elif not artifact_grid.highlighted_cells.is_empty():
			artifact_grid.selected_cell_coord = artifact_grid.highlighted_cells[0]
			update_temporary_grid_tile()
		artifact_grid.grab_focus()

func _on_artifact_grid_gui_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_action_pressed("E") or event.is_action_pressed("ui_accept"):
			if event.is_action_pressed("E"):
				deselect_all()
				artifact_grid.selected_cell_coord = null
			elif event.is_action_pressed("ui_accept"):
				if artifact_preview.artifact == null and artifacts_list.item_count > 0:
					artifacts_list.select(0)
					_on_artifacts_list_item_selected(0)
				else:
					temporary_grid_tile.artifact = artifact_preview.artifact
					if temporary_grid_tile.artifact != null and artifact_grid.selected_cell_coord != null:
						attempt_place_artifact(temporary_grid_tile.artifact, artifact_grid.selected_cell_coord as Vector2, false)
			
			artifacts_list.grab_focus()
		elif event.is_action_pressed("W"):
			if artifact_grid.selected_cell_coord != null:
				attempt_remove_artifact(artifact_grid.selected_cell_coord as Vector2)
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
			if not artifact_grid.highlighted_cells.is_empty() and artifact_grid.selected_cell_coord != null:
				var possible_moves := artifacts.highlight_all_available_cells_for_placement(temporary_grid_tile.artifact)
				var old_coord := artifact_grid.selected_cell_coord as Vector2
				if possible_moves.is_empty():
					return
				var current_index := 0
				for move in possible_moves:
					if move == old_coord:
						break
					current_index += 1
					
				var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_up")
				var best_index := 0
				var best_distance := INF
				var i := 0
				for move in possible_moves:
					if i == current_index:
						i += 1 
						continue
					if direction.y < 0 and move.y > old_coord.y:
						i += 1 
						continue
					elif direction.y > 0 and move.y < old_coord.y:
						i += 1 
						continue
					elif direction.x < 0 and move.x > old_coord.x:
						i += 1 
						continue
					elif direction.x > 0 and move.x < old_coord.x:
						i += 1 
						continue
					var dist := move.distance_squared_to(old_coord)
					if dist < best_distance:
						best_distance = dist
						best_index = i
					i += 1 
					
				artifact_grid.selected_cell_coord = possible_moves[best_index]
				update_temporary_grid_tile()
				artifact_grid.center_grid_on_cell(possible_moves[best_index])
				artifact_grid.accept_event()
			

func attempt_delete_artifact() -> void:
	if artifact_preview.artifact == null or artifact_preview.is_hidden:
		UIAudioPlayer.failed_click()
		return
		
	UIAudioPlayer.click()
	var popup := PopupDialog.display("Are you sure you wish to delete the artifact '%s'" % artifact_preview.artifact.name)
	popup.confirmed.connect(func() -> void:
		UIAudioPlayer.delete()
		artifacts.delete_artifact(artifact_preview.artifact)
		artifact_preview.artifact = null
		temporary_grid_tile.artifact = null
		update_list()
		update_temporary_grid_tile()
	)
	popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
	popup.show_in_root(self)
	
func _on_destroy_pressed() -> void:
	if destroy_artifact.text == "Destroy":
		attempt_delete_artifact()
	elif artifact_grid.selected_cell_coord != null:
		UIAudioPlayer.check(false)
		disconnect_artifact(artifact_grid.selected_cell_coord as Vector2)
			
func disconnect_artifact(coord: Vector2) -> void:
	if not attempt_remove_artifact(coord):
		if temporary_grid_tile.artifact != null:
			temporary_grid_tile.artifact = null
			artifact_preview.artifact = null
			if not artifacts_list.get_selected_items().is_empty():
				artifacts_list.deselect(artifacts_list.get_selected_items()[0])
		else:
			artifact_grid.selected_cell_coord = null
			artifact_preview.artifact = null
			if not artifacts_list.get_selected_items().is_empty():
				artifacts_list.deselect(artifacts_list.get_selected_items()[0])
		update_temporary_grid_tile()
		update_list_and_grid()
	else:
		artifact_grid.selected_cell_coord = null
		artifact_preview.artifact = null
		if not artifacts_list.get_selected_items().is_empty():
			artifacts_list.deselect(artifacts_list.get_selected_items()[0])
		update_temporary_grid_tile()
		update_list_and_grid()
		
		
func deselect_all() -> void:
	artifact_grid.selected_cell_coord = null
	temporary_grid_tile.artifact = null
	if artifacts_list.item_count > 0:
		artifacts_list.select(0)
		_on_artifacts_list_item_selected(0)
	update_list_and_grid()
	
func highlight_all_available_cells_for_placement() -> void:
	artifact_grid.highlighted_cells = artifacts.highlight_all_available_cells_for_placement(artifact_preview.artifact)
	if not artifact_grid.highlighted_cells.is_empty():
		artifact_grid.center_grid_on_cell(artifact_grid.highlighted_cells[0])
	else:
		artifact_grid.queue_redraw()
	
func update_effects_list_tooltip() -> void:
	effects_list.tooltip_text = artifacts.all_effects_description()

func filter_id_pressed(button: MenuButton, id: int, data: FilterOptions) -> void:
	var menu := button.get_popup() as PopupMenu
	
	if id >= 0 and id <= 2:
		if id != data.main_option:
			UIAudioPlayer.switch()
			filter_update_popup_menu_items(menu, id)
			data.set_main_option(id)
	elif data.main_option == 1: # Event
		if id < 6:
			var key := id - 3 
			if data.events.has(key):
				data.events.erase(key)
				UIAudioPlayer.check(false)
			else:
				data.events[key] = true
				UIAudioPlayer.check(true)
		elif id < 9:
			var key := id - 6
			if data.patterns.has(key):
				data.patterns.erase(key)
				UIAudioPlayer.check(false)
			else:
				data.patterns[key] = true
				UIAudioPlayer.check(true)
		else:
			var key := id - 9
			if data.elements.has(key):
				data.elements.erase(key)
				UIAudioPlayer.check(false)
			else:
				data.elements[key] = true
				UIAudioPlayer.check(true)
	elif data.main_option == 2:
		if id < 8:
			var key := id - 3
			if data.effects.has(key):
				data.effects.erase(key)
				UIAudioPlayer.check(false)
			else:
				data.effects[key] = true
				UIAudioPlayer.check(true)
		elif id < 13:
			var key := id - 8
			if data.patterns.has(key):
				data.patterns.erase(key)
				UIAudioPlayer.check(false)
			else:
				data.patterns[key] = true
				UIAudioPlayer.check(true)
		else:
			var key := id - 13
			if data.elements.has(key):
				data.elements.erase(key)
				UIAudioPlayer.check(false)
			else:
				data.elements[key] = true
				UIAudioPlayer.check(true)
				
	filter_update_popup_menu_checked(menu, data)
	update_list()
		
		
func filter_update_popup_menu_items(menu: PopupMenu, option: int) -> void:
	while menu.item_count > 3:
		menu.remove_item(3)
		
	menu.set_item_checked(0, option == 0)
	menu.set_item_checked(1, option == 1)
	menu.set_item_checked(2, option == 2)
	
	if option == 1: # Event
		menu.add_separator()
		menu.add_icon_check_item(preload("res://GUI/Images/take.svg") as Texture2D, "Receive", Artifact.Event.RECEIVE + 3)
		menu.add_icon_check_item(preload("res://GUI/Images/deal.svg") as Texture2D, "Deal", Artifact.Event.DEAL + 3)
		menu.add_separator()
		menu.add_icon_check_item(preload("res://GUI/Images/triangle.png") as Texture2D, "Triangle", Artifact.Pattern.TRIANGLE + 6)
		menu.add_icon_check_item(preload("res://GUI/Images/square.png") as Texture2D, "Square", Artifact.Pattern.SQUARE + 6)
		menu.add_icon_check_item(preload("res://GUI/Images/circle.png") as Texture2D, "Circle", Artifact.Pattern.CIRCLE + 6)
		menu.add_separator()
		menu.add_check_item("Any", Artifact.Element.ANY + 9)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_fire.tres") as Texture2D, "Fire", Artifact.Element.FIRE + 9)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_rock.tres") as Texture2D, "Rock", Artifact.Element.ROCK + 9)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_electric.tres") as Texture2D, "Electric", Artifact.Element.ELECTRIC + 9)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_water.tres") as Texture2D, "Water", Artifact.Element.WATER + 9)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_wind.tres") as Texture2D, "Wind", Artifact.Element.AIR + 9)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_ice.tres") as Texture2D, "Ice", Artifact.Element.ICE + 9)
	elif option == 2: # Effect
		menu.add_separator()
		menu.add_icon_check_item(preload("res://GUI/Images/sword.svg") as Texture2D, "DMG %", Artifact.Effect.BOOST_PERCENTAGE + 3)
		menu.add_icon_check_item(preload("res://GUI/Images/sword.svg") as Texture2D, "DMG", Artifact.Effect.BOOST_FLAT + 3)
		menu.add_icon_check_item(preload("res://GUI/Images/shield.svg") as Texture2D, "RES %", Artifact.Effect.RESISTANCE_PERCENTAGE + 3)
		menu.add_icon_check_item(preload("res://GUI/Images/shield.svg") as Texture2D, "RES", Artifact.Effect.RESISTANCE_FLAT + 3)
		menu.add_separator()
		menu.add_icon_check_item(preload("res://GUI/Images/triangle.png") as Texture2D, "Triangle", Artifact.Pattern.TRIANGLE + 8)
		menu.add_icon_check_item(preload("res://GUI/Images/square.png") as Texture2D, "Square", Artifact.Pattern.SQUARE + 8)
		menu.add_icon_check_item(preload("res://GUI/Images/circle.png") as Texture2D, "Circle", Artifact.Pattern.CIRCLE + 8)
		menu.add_separator()
		menu.add_check_item("Any", Artifact.Element.ANY + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_fire.tres") as Texture2D, "Fire", Artifact.Element.FIRE + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_rock.tres") as Texture2D, "Rock", Artifact.Element.ROCK + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_electric.tres") as Texture2D, "Electric", Artifact.Element.ELECTRIC + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_water.tres") as Texture2D, "Water", Artifact.Element.WATER + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_wind.tres") as Texture2D, "Wind", Artifact.Element.AIR + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_ice.tres") as Texture2D, "Ice", Artifact.Element.ICE + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_health.tres") as Texture2D, "Health", Artifact.Element.HEALTH + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_mana.tres") as Texture2D, "Mana", Artifact.Element.MANA + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_sword.tres") as Texture2D, "Attack", Artifact.Element.ATTACK + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_shield.tres") as Texture2D, "Defence", Artifact.Element.DEFENCE + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_cubes.tres") as Texture2D, "Crit Rate", Artifact.Element.CRIT_RATE + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_hypersonic.tres") as Texture2D, "Crit Dmg", Artifact.Element.CRIT_DMG + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_velocity.tres") as Texture2D, "v", Artifact.Element.SPELL_VELOCITY + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_time.tres") as Texture2D, "T", Artifact.Element.DURATION + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_running.tres") as Texture2D, "Movement Speed", Artifact.Element.RUNNING_SPEED + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_radius.tres") as Texture2D, "r", Artifact.Element.SPELL_RADIUS + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_count.tres") as Texture2D, "N", Artifact.Element.COUNT + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_power.tres") as Texture2D, "P", Artifact.Element.POWER + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_health_outline.tres") as Texture2D, "Max Health", Artifact.Element.HEALTH_BUMP + 13)
		menu.add_icon_check_item(preload("res://GUI/Images/tinted_mana_outline.tres") as Texture2D, "Max Mana", Artifact.Element.MANA_BUMP + 13)
		
func filter_update_popup_menu_checked(menu: PopupMenu, data: FilterOptions) -> void:
	var index := 3
	while index < menu.item_count:
		if menu.is_item_checkable(index):
			menu.set_item_checked(index, false)
		index += 1
	
	if data.main_option == 1:
		for e: Artifact.Event in data.events:
			menu.set_item_checked(menu.get_item_index(e + 3), true)
		for e: Artifact.Pattern in data.patterns:
			menu.set_item_checked(menu.get_item_index(e + 6), true)
		for e: Artifact.Element in data.elements:
			menu.set_item_checked(menu.get_item_index(e + 9), true)
	elif data.main_option == 2:
		for e: Artifact.Effect in data.effects:
			menu.set_item_checked(menu.get_item_index(e + 3), true)
		for e: Artifact.Pattern in data.patterns:
			menu.set_item_checked(menu.get_item_index(e + 8), true)
		for e: Artifact.Element in data.elements:
			menu.set_item_checked(menu.get_item_index(e + 13), true)
	
func filter_artifact_option_matches(option: Artifact.Option, filter: FilterOptions) -> bool:
	if filter.main_option == 0:
		return true
		
	if filter.main_option == 1 and option.event == Artifact.Event.NONE:
		return false
		
	if filter.main_option == 2 and option.effect == Artifact.Effect.NONE:
		return false
		
	if not filter.patterns.is_empty() and not filter.patterns.has(option.pattern):
		return false
		
	if filter.main_option == 1:
		if not filter.events.is_empty() and not filter.events.has(option.event):
			return false
	elif filter.main_option == 2:
		if not filter.effects.is_empty() and not (filter.effects.has(option.effect) and Artifact.SpellElements.has(option.element)):
			return false
			
	if not filter.elements.is_empty() and not filter.elements.has(option.element):
		return false
		
	return true
	
func filter_artifact_matches(artifact: Artifact) -> bool:
	if not (filter_artifact_option_matches(artifact.top, filter_all_options) or filter_artifact_option_matches(artifact.left, filter_all_options) or \
	filter_artifact_option_matches(artifact.right, filter_all_options) or  filter_artifact_option_matches(artifact.bottom, filter_all_options)):
		return false
	
	if not filter_artifact_option_matches(artifact.top, filter_top_options):
		return false
	if not filter_artifact_option_matches(artifact.left, filter_left_options):
		return false
	if not filter_artifact_option_matches(artifact.right, filter_right_options):
		return false
	if not filter_artifact_option_matches(artifact.bottom, filter_bottom_options):
		return false
	return true
	
class FilterOptions:
	var main_option: int = 0 # 0=none, 1=event, 2=effect
	var patterns: Dictionary = {} # [Artifact.Pattern]bool
	var events: Dictionary = {} # [Artifact.Event]bool
	var effects: Dictionary = {} # [Artifact.Effect]bool
	var elements: Dictionary = {} # [Artifact.Element]bool
	
	func set_main_option(option: int) -> void:
		main_option = option
		patterns.clear()
		events.clear()
		effects.clear()
		elements.clear()


func _on_top_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)

func _on_left_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)

func _on_right_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)

func _on_bottom_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)

func _on_filter_all_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
