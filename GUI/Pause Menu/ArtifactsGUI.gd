class_name ArtifactsGUI
extends Control

@onready var artifacts_list = $artifacts_list
@onready var artifact_grid: InfinityGrid = $artifact_grid
@onready var artifact_preview: GridTile = $artifact_preview

var temporary_grid_tile: GridTile
var last_moused_coord := Vector2.ZERO

var artifacts: Artifacts:
	set(value):
		artifacts = value
		update_list_and_grid()

var list_clicked := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	temporary_grid_tile = GridTile.new()
	temporary_grid_tile.is_temporary = true
	artifact_grid.add_grid_tile(temporary_grid_tile, Vector2.ZERO)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_list_and_grid():
	artifacts_list.clear()
	for a in artifacts.unconnected():
		artifacts_list.add_item(a.name)
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
		
	list_clicked = true


func _on_artifact_grid_on_cell_clicked(coord: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 2:
		var was_removed := attempt_remove_artifact(coord)
		if not was_removed:
			temporary_grid_tile.artifact = null
			temporary_grid_tile.queue_redraw()
		elif temporary_grid_tile.artifact != null:
			artifact_grid.remove_tile_at_coord(coord)
			artifact_grid.remove_grid_tile(temporary_grid_tile)
			artifact_grid.add_grid_tile(temporary_grid_tile, coord)
			attempt_place_artifact(temporary_grid_tile.artifact, coord, true)
		else:
			update_list_and_grid()
			
	elif mouse_button_index == 1:
		if temporary_grid_tile.artifact == null:
			return
		attempt_place_artifact(temporary_grid_tile.artifact, coord, false)

func attempt_place_artifact(artifact: Artifact, coord: Vector2, temporarily: bool):
	if artifact == null:
		return
	if artifacts.get_artifact_at_coord(coord) != null:
		return
		
	const WARN_COLOR = Color.RED
	const WARN_INTERVAL = 0.1
	const WARN_COUNT = 5
	var check_count := 0
	var should_fail := false
		
	# Check artifact fits with top artifact
	var other = artifacts.get_artifact_at_coord(coord + Vector2(0, -1))
	if other != null:
		check_count += 1
		var ok1 : bool = other.bottom.event != Artifact.Event.NONE and artifact.top.effect != Artifact.Effect.NONE
		var ok2 : bool = other.bottom.effect != Artifact.Effect.NONE and artifact.top.event != Artifact.Event.NONE
		var ok3 : bool = other.bottom.pattern == artifact.top.pattern
		if not ok3:
			artifact_grid.child_grid[coord + Vector2(0, -1)].warn(2, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
		if not (ok1 or ok2):
			artifact_grid.child_grid[coord + Vector2(0, -1)].warn(2, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
			
	# Check artifact fits with bottom artifact	
	other = artifacts.get_artifact_at_coord(coord + Vector2(0, 1))
	if other != null:
		check_count += 1
		var ok1 : bool = other.top.event != Artifact.Event.NONE and artifact.bottom.effect != Artifact.Effect.NONE
		var ok2 : bool = other.top.effect != Artifact.Effect.NONE and artifact.bottom.event != Artifact.Event.NONE
		var ok3 : bool = other.top.pattern == artifact.bottom.pattern
		if not ok3:
			artifact_grid.child_grid[coord + Vector2(0, 1)].warn(0, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
		if not (ok1 or ok2):
			artifact_grid.child_grid[coord + Vector2(0, 1)].warn(0, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
			
	# Check artifact fits with left artifact
	other = artifacts.get_artifact_at_coord(coord + Vector2(-1, 0))
	if other != null:
		check_count += 1
		var ok1 : bool = other.right.event != Artifact.Event.NONE and artifact.left.effect != Artifact.Effect.NONE
		var ok2 : bool = other.right.effect != Artifact.Effect.NONE and artifact.left.event != Artifact.Event.NONE
		var ok3 : bool = other.right.pattern == artifact.left.pattern
		if not ok3:
			artifact_grid.child_grid[coord + Vector2(-1, 0)].warn(1, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
		if not (ok1 or ok2):
			artifact_grid.child_grid[coord + Vector2(-1, 0)].warn(1, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
			
	# Check artifact fits with right artifact
	other = artifacts.get_artifact_at_coord(coord + Vector2(1, 0))
	if other != null:
		check_count += 1
		var ok1 : bool = other.left.event != Artifact.Event.NONE and artifact.right.effect != Artifact.Effect.NONE
		var ok2 : bool = other.left.effect != Artifact.Effect.NONE and artifact.right.event != Artifact.Event.NONE
		var ok3 : bool = other.left.pattern == artifact.right.pattern
		if not ok3:
			artifact_grid.child_grid[coord + Vector2(1, 0)].warn(3, 2, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
		if not (ok1 or ok2):
			artifact_grid.child_grid[coord + Vector2(1, 0)].warn(3, 0, WARN_COLOR, WARN_INTERVAL, WARN_COUNT)
			should_fail = true
			
	if should_fail or (check_count <= 0 and not artifacts.is_empty()):
		return
		
	if not temporarily:
		artifacts.connect_to_grid(artifact, coord)
		temporary_grid_tile.artifact = null
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
	temporary_grid_tile.queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not has_focus():
		return
		
	var direction := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back")
	
	if artifacts_list.has_focus():
		if direction.x > 0:
			artifact_grid.grab_focus()
	elif artifact_grid.has_focus():
		if direction.x < 0:
			artifacts_list.grab_focus()


func _on_artifact_grid_on_cell_moused_over(coord: Vector2) -> void:
	if coord == last_moused_coord:
		return
	last_moused_coord = coord
	if temporary_grid_tile.artifact != null:
		artifact_grid.remove_grid_tile(temporary_grid_tile)
		attempt_place_artifact(temporary_grid_tile.artifact, coord, true)
		artifact_grid.add_grid_tile(temporary_grid_tile, coord)
