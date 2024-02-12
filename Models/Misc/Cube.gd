extends Node3D

var artifact: Artifact = null
var eaten: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("idle")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and artifact != null:
		eaten = true
		body.artifacts.collection.append(artifact)
		SignalBus.pick_up_world_item_artifact.emit(artifact, "Artifact '%s' picked up" % artifact.name)
		queue_free()
