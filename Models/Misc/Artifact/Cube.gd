class_name ArtifactCube
extends WorldItem

var artifact: Artifact = null
var eaten: bool = false

static func make() -> ArtifactCube:
	var result := (preload("res://Models/Misc/Artifact/Cube.tscn") as PackedScene).instantiate() as ArtifactCube
	result.height = 2.0
	result.kind = World.Item.ARTIFACT
	return result

func _ready() -> void:
	setup(0, World.Biome.WATER)
	
func setup(seedling: int, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and artifact != null:
		eaten = true
		(body as Player).artifacts.collection.append(artifact)
		UIAudioPlayer.ringing()
		SignalBus.pick_up_world_item_artifact.emit(artifact, "Artifact '%s' picked up" % artifact.name)
		var tween := create_tween_for_world_item_pick_up(body, 0.25)
		tween.finished.connect(custom_free.bind(self))
		tween.play()
