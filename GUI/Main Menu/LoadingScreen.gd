class_name LoadingScreen
extends Node

@onready var progress_bar: TextureProgressBar = $ProgressBar
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var loading_label: Label = $Loading
@onready var message_label: RichTextLabel = $VBoxMessage/Message

@onready var progress_animation: AnimationPlayer = $ProgressAnimation

var message: Array
var starting_animation_name:String


func _ready() -> void:
	loading_label.visible = false
	message_label.visible = false
	progress_bar.visible = false
	#progress_animation.play("spin")
	
func start_transition(animation_name: String, on_complete: Callable) -> void:
	if !anim_player.has_animation(animation_name):
		push_warning("'%s' animation does not exist" % animation_name)
		animation_name = "fade_to_black"
	starting_animation_name = animation_name
	anim_player.play(animation_name)
	anim_player.animation_finished.connect(func(anim_name: String) -> void: if anim_name == animation_name: on_complete.call())
	
	# if timer reaches the end before we finish loading, this will show the progress bar
	timer.start()
	
# called by SceneManger to play the outro to the transition once the content is loaded
func finish_transition() -> void:
	if timer:
		timer.stop()
	# construct second half of the transitation's animation name
	var ending_animation_name:String = starting_animation_name.replace("to","from")
	
	if !anim_player.has_animation(ending_animation_name):
		push_warning("'%s' animation does not exist" % ending_animation_name)
		ending_animation_name = "fade_from_black"
	anim_player.play(ending_animation_name)
	
	# once this final animation plays, we can free this scene
	await anim_player.animation_finished
	queue_free()

func _on_timer_timeout() -> void:
	loading_label.visible = true
	message_label.visible = true
	if message.is_empty():
		message_label.text = ""
	else:
		message_label.text = """
[font_size=72][b]"[/b][/font_size]
[font_size=36]%s[/font_size]

[font_size=36][right][i]%s[/i][/right][/font_size]
""" % message

func update_bar(val: float) -> void:
	progress_bar.value = val
