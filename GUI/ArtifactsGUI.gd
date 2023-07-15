class_name ArtifactsGUI
extends Control

@onready var artifacts_list = $artifacts_list
@onready var artifact_grid: InfinityGrid = $artifact_grid
@onready var artifact_preview: GridTile = $artifact_preview

var artifacts: Artifacts:
	set(value):
		artifacts = value
		update_list_and_grid()

var list_clicked := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

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
		g.color = Color(0.1, 0.1, 0.1)
		artifact_grid.add_grid_tile(g, v)


func _on_artifacts_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	get_tree().create_timer(0.3).timeout.connect(func(): list_clicked = false)
	
	if list_clicked: # double click
		if artifact_grid.selected_cell_coord != null:
			var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(index))
			if artifact == null:
				return
			artifacts.connect_to_grid(artifact, artifact_grid.selected_cell_coord)
			update_list_and_grid()
		
	list_clicked = true


func _on_artifact_grid_on_cell_clicked(coord: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 2:
		for a in artifacts.connected:
			if artifacts.connected[a] == coord:
				artifacts.unconnect_from_grid(a)
				break
		update_list_and_grid()
	elif mouse_button_index == 1:
		var selected = artifacts_list.get_selected_items()
		if selected.size() == 0:
			return
		var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(selected[0]))
		if artifact == null:
			return
		artifacts.connect_to_grid(artifact, coord)
		update_list_and_grid()


func _on_artifacts_list_item_selected(index: int) -> void:
	var artifact := artifacts.get_artifact_by_name(artifacts_list.get_item_text(index))
	if artifact == null:
		return
	artifact_preview.artifact = artifact
	artifact_preview.queue_redraw()
