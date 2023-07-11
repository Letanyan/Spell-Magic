class_name ArtifactsGUI
extends Control

@onready var artifacts_list = $artifacts_list
@onready var artifact_grid: InfinityGrid = $artifact_grid

var artifacts := Artifacts.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in ["flower", "feather", "goblet", "sands", "crown"]:
		var artifact := Artifact.new()
		artifact.name = i
		artifacts.collection.append(artifact)
		
	for a in artifacts.collection:
		artifacts_list.add_item(a.name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_artifacts_list_item_selected(index: int) -> void:
	if artifact_grid.selected_cell_coord != null:
		pass
