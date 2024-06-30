class_name ArtifactCube
extends Node3D

var artifact: Artifact = null
var eaten: bool = false

func _ready() -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and artifact != null:
		eaten = true
		(body as Player).artifacts.collection.append(artifact)
		SignalBus.pick_up_world_item_artifact.emit(artifact, "Artifact '%s' picked up" % artifact.name)
		queue_free()
