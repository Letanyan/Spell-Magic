class_name ArtifactsGUI
extends Control

@onready var artifacts_list = $artifacts_list
@onready var artifact_grid: InfinityGrid = $artifact_grid
@onready var artifact_preview: GridTile = $artifact_preview

@onready var filter_top: MenuButton = $Top
@onready var filter_left: MenuButton = $Left
@onready var filter_right: MenuButton = $Right
@onready var filter_bottom: MenuButton = $Bottom

var filter_top_options := FilterOptions.new()
var filter_left_options := FilterOptions.new()
var filter_right_options := FilterOptions.new()
var filter_bottom_options := FilterOptions.new()


var temporary_grid_tile: GridTile
var last_moused_coord := Vector2.ZERO

var artifacts: Artifacts:
	set(value):
		artifacts = value
		update_list_and_grid()

var list_clicked := false
var list_mouse_down := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	temporary_grid_tile = GridTile.new()
	temporary_grid_tile.is_temporary = true
	artifact_grid.add_grid_tile(temporary_grid_tile, Vector2.ZERO)
	
	filter_top.get_popup().id_pressed.connect(func(id: int): filter_id_pressed(filter_top, id, filter_top_options))
	filter_left.get_popup().id_pressed.connect(func(id: int): filter_id_pressed(filter_left, id, filter_left_options))
	filter_right.get_popup().id_pressed.connect(func(id: int): filter_id_pressed(filter_right, id, filter_right_options))
	filter_bottom.get_popup().id_pressed.connect(func(id: int): filter_id_pressed(filter_bottom, id, filter_bottom_options))
	
func update_temporary_grid_tile():
	temporary_grid_tile.is_hidden = false
	if artifact_grid.selected_cell_coord:
		artifact_grid.remove_grid_tile(temporary_grid_tile)
		attempt_place_artifact(temporary_grid_tile.artifact, artifact_grid.selected_cell_coord, true)
		artifact_grid.add_grid_tile(temporary_grid_tile, artifact_grid.selected_cell_coord)
	elif temporary_grid_tile.artifact != null and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		temporary_grid_tile.is_hidden = true
		
	temporary_grid_tile.queue_redraw()
		
func update_artifact_list_height():
	if artifact_preview.artifact == null:
		artifacts_list.set_deferred("size", Vector2(artifacts_list.size.x, size.y - artifacts_list.position.y - 8))
	else:
		artifacts_list.set_deferred("size", Vector2(artifacts_list.size.x, artifact_preview.position.y - artifacts_list.position.y - 8))
	$Destroy.visible = artifact_preview.artifact != null
	
func update_list():
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
			if filter_artifact_matches(a) and can_place_artifact(a, artifact_grid.selected_cell_coord).is_empty():
				artifacts_list.add_item(a.name)
				if a == artifact_preview.artifact:
					found_preview = true
	if not found_preview:
		artifact_preview.artifact = null
		artifact_preview.queue_redraw()
		update_artifact_list_height()
	else:
		for idx in artifacts_list.item_count:
			if artifacts.get_artifact_by_name(artifacts_list.get_item_text(idx)) == artifact_preview.artifact:
				artifacts_list.select(idx)
				break

func update_list_and_grid():
	update_list()
	for c in artifact_grid.get_children():
		artifact_grid.remove_child(c)
	artifact_grid.child_grid.clear()
	for a in artifacts.connected:
		var v = artifacts.connected[a]
		var g := GridTile.new()
		g.artifact = a
		g.highlighted = artifacts.active_options.get(v, {})
		artifact_grid.add_grid_tile(g, v)


func _on_artifacts_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	get_tree().create_timer(0.3).timeout.connect(func(): list_clicked = false)
	
	if list_clicked: # double click
		if artifact_grid.selected_cell_coord != null:
			var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(index))
			attempt_place_artifact(artifact, artifact_grid.selected_cell_coord, false)
	else:
		var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(index))
		if artifact == null:
			return
		artifact_preview.artifact = artifact
		temporary_grid_tile.artifact = artifact
		artifact_preview.queue_redraw()
		update_artifact_list_height()
		if artifact_grid.selected_cell_coord:
			update_temporary_grid_tile()
		
		
	list_clicked = true


func _on_artifact_grid_on_cell_clicked(coord: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var was_removed := attempt_remove_artifact(coord)
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

func can_place_artifact(artifact: Artifact, coord: Vector2) -> Array:
	if artifact == null:
		return [Vector4(coord.x, coord.y, 0, 0)]
	if artifacts.get_artifact_at_coord(coord) != null:
		return [Vector4(coord.x, coord.y, 0, 0)]
		
	var check_count := 0
	var result: Array[Vector4] = []
		
	# Check artifact fits with top artifact
	var other = artifacts.get_artifact_at_coord(coord + Vector2(0, -1))
	if other != null:
		check_count += 1
		var ok1 : bool = other.bottom.event != Artifact.Event.NONE and artifact.top.effect != Artifact.Effect.NONE
		var ok2 : bool = other.bottom.effect != Artifact.Effect.NONE and artifact.top.event != Artifact.Event.NONE
		var ok3 : bool = other.bottom.pattern == artifact.top.pattern
		if not ok3:
			var nc := coord + Vector2(0, -1)
			result.append(Vector4(nc.x, nc.y, 2, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(0, -1)
			result.append(Vector4(nc.x, nc.y, 2, 0))
			
	# Check artifact fits with bottom artifact	
	other = artifacts.get_artifact_at_coord(coord + Vector2(0, 1))
	if other != null:
		check_count += 1
		var ok1 : bool = other.top.event != Artifact.Event.NONE and artifact.bottom.effect != Artifact.Effect.NONE
		var ok2 : bool = other.top.effect != Artifact.Effect.NONE and artifact.bottom.event != Artifact.Event.NONE
		var ok3 : bool = other.top.pattern == artifact.bottom.pattern
		if not ok3:
			var nc := coord + Vector2(0, 1)
			result.append(Vector4(nc.x, nc.y, 0, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(0, 1)
			result.append(Vector4(nc.x, nc.y, 0, 0))
			
	# Check artifact fits with left artifact
	other = artifacts.get_artifact_at_coord(coord + Vector2(-1, 0))
	if other != null:
		check_count += 1
		var ok1 : bool = other.right.event != Artifact.Event.NONE and artifact.left.effect != Artifact.Effect.NONE
		var ok2 : bool = other.right.effect != Artifact.Effect.NONE and artifact.left.event != Artifact.Event.NONE
		var ok3 : bool = other.right.pattern == artifact.left.pattern
		if not ok3:
			var nc := coord + Vector2(-1, 0)
			result.append(Vector4(nc.x, nc.y, 1, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(-1, 0)
			result.append(Vector4(nc.x, nc.y, 1, 0))
			
	# Check artifact fits with right artifact
	other = artifacts.get_artifact_at_coord(coord + Vector2(1, 0))
	if other != null:
		check_count += 1
		var ok1 : bool = other.left.event != Artifact.Event.NONE and artifact.right.effect != Artifact.Effect.NONE
		var ok2 : bool = other.left.effect != Artifact.Effect.NONE and artifact.right.event != Artifact.Event.NONE
		var ok3 : bool = other.left.pattern == artifact.right.pattern
		if not ok3:
			var nc := coord + Vector2(1, 0)
			result.append(Vector4(nc.x, nc.y, 3, 2))
		if not (ok1 or ok2):
			var nc := coord + Vector2(1, 0)
			result.append(Vector4(nc.x, nc.y, 3, 0))
			
	if (check_count <= 0 and not artifacts.is_empty()):
		return [Vector4(coord.x, coord.y, 0, 0)]
			
	return result

func attempt_place_artifact(artifact: Artifact, coord: Vector2, temporarily: bool):	
	const WARN_COLOR = Color.RED
	const WARN_INTERVAL = 0.1
	const WARN_COUNT = 5
	
	var errors := can_place_artifact(artifact, coord)
	for error in errors:
		if error.x == coord.x and error.y == coord.y:
			continue
		else:
			artifact_grid.child_grid[Vector2(error.x, error.y)].warn(error.z, error.w, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
		
	if not temporarily:
		temporary_grid_tile.artifact = null
		
	if not errors.is_empty():
		return
		
	if not temporarily:
		artifacts.connect_to_grid(artifact, coord)
		update_list_and_grid()
	else:
		temporary_grid_tile.queue_redraw()
	
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
			artifact_grid.child_grid[coord + Vector2(0, -1)].warn(GridTile.Direction.BOTTOM, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			artifact_grid.child_grid[coord + Vector2(0, -1)].warn(GridTile.Direction.BOTTOM, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			
		if artifacts.get_artifact_at_coord(coord + Vector2(0, 1)):
			artifact_grid.child_grid[coord + Vector2(0, 1)].warn(GridTile.Direction.TOP, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			artifact_grid.child_grid[coord + Vector2(0, 1)].warn(GridTile.Direction.TOP, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			
		if artifacts.get_artifact_at_coord(coord + Vector2(-1, 0)):
			artifact_grid.child_grid[coord + Vector2(-1, 0)].warn(GridTile.Direction.RIGHT, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			artifact_grid.child_grid[coord + Vector2(-1, 0)].warn(GridTile.Direction.RIGHT, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			
		if artifacts.get_artifact_at_coord(coord + Vector2(1, 0)):
			artifact_grid.child_grid[coord + Vector2(1, 0)].warn(GridTile.Direction.LEFT, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			artifact_grid.child_grid[coord + Vector2(1, 0)].warn(GridTile.Direction.LEFT, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
		
		return false
		
		
	var was_removed = false
	for a in artifacts.connected:
		if artifacts.connected[a] == coord:
			artifacts.unconnect_from_grid(a)
			was_removed = true
			break
			
	return was_removed

func _on_artifacts_list_item_selected(index: int) -> void:
	var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(index))
	if artifact == null:
		return
	artifact_preview.artifact = artifact
	temporary_grid_tile.artifact = artifact
	artifact_preview.queue_redraw()
	update_artifact_list_height()
	if artifact_grid.selected_cell_coord:
		update_temporary_grid_tile()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
			
	if event is InputEventKey:
		if Input.is_action_pressed("S", true):
			if artifacts_list.has_focus():
				if artifact_grid.selected_cell_coord != null:
					var selected: Array = artifacts_list.get_selected_items()
					if selected.size() == 1:
						var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(selected[0]))
						attempt_place_artifact(artifact, artifact_grid.selected_cell_coord, false)
			elif artifact_grid.has_focus():
				artifacts_list.grab_focus()
				if artifacts_list.item_count > 0:
					artifacts_list.select(0)


func _on_artifact_grid_on_cell_moused_over(coord: Vector2) -> void:
	if coord == last_moused_coord:
		return
	last_moused_coord = coord
	update_temporary_grid_tile()
	#if temporary_grid_tile.artifact != null:
		#artifact_grid.remove_grid_tile(temporary_grid_tile)
		#attempt_place_artifact(temporary_grid_tile.artifact, coord, true)
		#artifact_grid.add_grid_tile(temporary_grid_tile, coord)



func _on_artifact_grid_on_cell_selected(coord: Vector2) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		temporary_grid_tile.artifact = null
	update_list()
	update_temporary_grid_tile()


func _on_artifact_grid_on_cell_unselected(coord: Vector2) -> void:
	update_list()
	update_temporary_grid_tile()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		temporary_grid_tile.artifact = null

func handle_artifact_drag(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	var coord := Vector2.ZERO	
	var in_grid := false
	
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		coord = event.global_position - artifact_grid.global_position
		if not (coord.x < 0 or coord.y < 0 or coord.x > artifact_grid.size.x or coord.y > artifact_grid.size.y):
			coord -= artifact_grid.offset
			coord /= artifact_grid.cell_size
			coord = floor(coord)
			in_grid = true
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			list_mouse_down = event.pressed
			if not list_mouse_down:
				if in_grid:
					if temporary_grid_tile.artifact != null:
						attempt_place_artifact(temporary_grid_tile.artifact, coord, false)
					temporary_grid_tile.artifact = null
					update_temporary_grid_tile()
	elif event is InputEventMouseMotion:
		if not list_mouse_down:
			return
		if not in_grid:
			return
		if coord == last_moused_coord:
			return
		last_moused_coord = coord
		if temporary_grid_tile.artifact != null:
			artifact_grid.remove_grid_tile(temporary_grid_tile)
			attempt_place_artifact(temporary_grid_tile.artifact, coord, true)
			artifact_grid.add_grid_tile(temporary_grid_tile, coord)

func _on_artifacts_list_gui_input(event: InputEvent) -> void:
	handle_artifact_drag(event)

func _on_artifact_preview_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		temporary_grid_tile.artifact = artifact_preview.artifact
		
	handle_artifact_drag(event)


func _on_destroy_pressed() -> void:
	if artifact_preview.artifact == null or artifact_preview.is_hidden:
		return
		
	artifacts.delete_artifact(artifact_preview.artifact)
	artifact_preview.artifact = null
	temporary_grid_tile.artifact = null
	update_list()
	update_temporary_grid_tile()


func filter_id_pressed(button: MenuButton, id: int, data: FilterOptions):
	var menu := button.get_popup() as PopupMenu
	
	if id >= 0 and id <= 2:
		if id != data.main_option:
			filter_update_popup_menu_items(menu, id)
			data.set_main_option(id)
	elif data.main_option == 1: # Event
		if id < 6:
			var key := id - 3 
			if data.events.has(key):
				data.events.erase(key)
			else:
				data.events[key] = true
		elif id < 9:
			var key := id - 6
			if data.patterns.has(key):
				data.patterns.erase(key)
			else:
				data.patterns[key] = true
		else:
			var key := id - 9
			if data.elements.has(key):
				data.elements.erase(key)
			else:
				data.elements[key] = true
	elif data.main_option == 2:
		if id < 8:
			var key := id - 3
			if data.effects.has(key):
				data.effects.erase(key)
			else:
				data.effects[key] = true
		elif id < 11:
			var key := id - 8
			if data.patterns.has(key):
				data.patterns.erase(key)
			else:
				data.patterns[key] = true
		else:
			var key := id - 11
			if data.elements.has(key):
				data.elements.erase(key)
			else:
				data.elements[key] = true
				
	filter_update_popup_menu_checked(menu, data)
	update_list()
		
		
func filter_update_popup_menu_items(menu: PopupMenu, option: int):
	while menu.item_count > 3:
		menu.remove_item(3)
		
	menu.set_item_checked(0, option == 0)
	menu.set_item_checked(1, option == 1)
	menu.set_item_checked(2, option == 2)
	
	if option == 1: # Event
		menu.add_separator()
		menu.add_check_item("Receive", Artifact.Event.RECEIVE + 3)
		menu.add_check_item("Deal", Artifact.Event.DEAL + 3)
		menu.add_separator()
		menu.add_check_item("Triangle", Artifact.Pattern.TRIANGLE + 6)
		menu.add_check_item("Square", Artifact.Pattern.SQUARE + 6)
		menu.add_check_item("Circle", Artifact.Pattern.CIRCLE + 6)
		menu.add_separator()
		menu.add_check_item("Any", Artifact.Element.ANY + 9)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_fire.tres"), "Fire", Artifact.Element.FIRE + 9)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_rock.tres"), "Rock", Artifact.Element.ROCK + 9)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_electric.tres"), "Electric", Artifact.Element.ELECTRIC + 9)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_water.tres"), "Water", Artifact.Element.WATER + 9)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_wind.tres"), "Wind", Artifact.Element.AIR + 9)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_ice.tres"), "Ice", Artifact.Element.ICE + 9)
	elif option == 2: # Effect
		menu.add_separator()
		menu.add_check_item("DMG %", Artifact.Effect.BOOST_PERCENTAGE + 3)
		menu.add_check_item("DMG", Artifact.Effect.BOOST_FLAT + 3)
		menu.add_check_item("RES %", Artifact.Effect.RESISTANCE_PERCENTAGE + 3)
		menu.add_check_item("RES", Artifact.Effect.RESISTANCE_FLAT + 3)
		menu.add_separator()
		menu.add_check_item("Triangle", Artifact.Pattern.TRIANGLE + 8)
		menu.add_check_item("Square", Artifact.Pattern.SQUARE + 8)
		menu.add_check_item("Circle", Artifact.Pattern.CIRCLE + 8)
		menu.add_separator()
		menu.add_check_item("Any", Artifact.Element.ANY + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_fire.tres"), "Fire", Artifact.Element.FIRE + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_rock.tres"), "Rock", Artifact.Element.ROCK + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_electric.tres"), "Electric", Artifact.Element.ELECTRIC + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_water.tres"), "Water", Artifact.Element.WATER + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_wind.tres"), "Wind", Artifact.Element.AIR + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_ice.tres"), "Ice", Artifact.Element.ICE + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_health.tres"), "Health", Artifact.Element.HEALTH + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_mana.tres"), "Mana", Artifact.Element.MANA + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_sword.tres"), "Attack", Artifact.Element.ATTACK + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_shield.tres"), "Defence", Artifact.Element.DEFENCE + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_velocity.tres"), "v", Artifact.Element.SPELL_VELOCITY + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_time.tres"), "T", Artifact.Element.DURATION + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_running.tres"), "Movement Speed", Artifact.Element.RUNNING_SPEED + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_radius.tres"), "r", Artifact.Element.SPELL_RADIUS + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_count.tres"), "N", Artifact.Element.COUNT + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_power.tres"), "P", Artifact.Element.POWER + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_health_outline.tres"), "Max Health", Artifact.Element.HEALTH_BUMP + 11)
		menu.add_icon_check_item(load("res://GUI/Images/tinted_mana_outline.tres"), "Max Mana", Artifact.Element.MANA_BUMP + 11)
		
func filter_update_popup_menu_checked(menu: PopupMenu, data: FilterOptions):
	var index := 3
	while index < menu.item_count:
		if menu.is_item_checkable(index):
			menu.set_item_checked(index, false)
		index += 1
	
	if data.main_option == 1:
		for e in data.events:
			menu.set_item_checked(menu.get_item_index(e + 3), true)
		for e in data.patterns:
			menu.set_item_checked(menu.get_item_index(e + 6), true)
		for e in data.elements:
			menu.set_item_checked(menu.get_item_index(e + 9), true)
	elif data.main_option == 2:
		for e in data.effects:
			menu.set_item_checked(menu.get_item_index(e + 3), true)
		for e in data.patterns:
			menu.set_item_checked(menu.get_item_index(e + 8), true)
		for e in data.elements:
			menu.set_item_checked(menu.get_item_index(e + 11), true)
	
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
			print(filter.events, option.event)
			return false
	elif filter.main_option == 2:
		if not filter.effects.is_empty() and not filter.effects.has(option.effect):
			return false
			
	if not filter.elements.is_empty() and not filter.elements.has(option.element):
		return false
		
	return true
	
func filter_artifact_matches(artifact: Artifact) -> bool:
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
	var patterns: Dictionary = {} # Artifact.Pattern -> bool
	var events: Dictionary = {} # Artifact.Event -> bool
	var effects: Dictionary = {} # Artifact.Effect -> bool
	var elements: Dictionary = {} # Artifact.Element -> bool
	
	func set_main_option(option: int):
		main_option = option
		patterns.clear()
		events.clear()
		effects.clear()
		elements.clear()
		
