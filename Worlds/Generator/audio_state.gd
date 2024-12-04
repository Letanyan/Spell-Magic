class_name AudioState

enum PlayerState { MUTE, PLAYING_1, PLAYING_2, IN_TRANSITION_TO_1, IN_TRANSITION_TO_2 }

var state: PlayerState
var player1: AudioStreamPlayer3D
var player2: AudioStreamPlayer3D
var current_stream: AudioStream
var in_queue: AudioStream
var in_queue_fade: float
var in_queue_should_stop: bool

var pitch_scale: float:
	set(value):
		match state:
			PlayerState.MUTE:
				player1.pitch_scale = value
				player2.pitch_scale = value
			PlayerState.PLAYING_1:
				player1.pitch_scale = value
			PlayerState.PLAYING_2:
				player2.pitch_scale = value
			PlayerState.IN_TRANSITION_TO_1:
				player1.pitch_scale = value
			PlayerState.IN_TRANSITION_TO_2:
				player2.pitch_scale = value

func _init(p1: AudioStreamPlayer3D, p2: AudioStreamPlayer3D) -> void:
	state = PlayerState.MUTE
	player1 = p1
	player2 = p2
	player1.stop()
	player2.stop()
	
func fade_in(player: AudioStreamPlayer3D, tween: Tween, duration: float) -> void:
	player.volume_db = -40
	player.play()
	tween.tween_property(player, "volume_db", 0, duration)
	
func fade_out(player: AudioStreamPlayer3D, tween: Tween, duration: float) -> void:
	tween.tween_property(player, "volume_db", -40, duration)
	tween.tween_method(func(should_stop: float) -> void: 
		if is_zero_approx(should_stop):
			player.stop()
	, 1.0, 0.0, duration)
	
func transition_done(done_state: PlayerState) -> Callable:
	var result := func() -> void:
		if in_queue_should_stop:
			in_queue_should_stop = false
			stop(in_queue_fade)
		else:
			state = done_state
			if in_queue != null:
				play(in_queue, in_queue_fade)
				in_queue = null
	return result
		
func stop(fade_time: float = 0.5) -> void:
	match state:
		PlayerState.PLAYING_1:
			var tween := player1.get_tree().create_tween().set_parallel()
			fade_out(player1, tween, fade_time)
			tween.finished.connect(transition_done(PlayerState.MUTE))
			state = PlayerState.IN_TRANSITION_TO_2
			current_stream = null
			
		PlayerState.PLAYING_2:
			var tween := player2.get_tree().create_tween().set_parallel()
			fade_out(player2, tween, fade_time)
			tween.finished.connect(transition_done(PlayerState.MUTE))
			state = PlayerState.IN_TRANSITION_TO_1
			current_stream = null
			
		PlayerState.IN_TRANSITION_TO_1, PlayerState.IN_TRANSITION_TO_2:
			in_queue_should_stop = true
			in_queue_fade = fade_time
	
func play(stream: AudioStream, fade_time: float = 0.5) -> void:
	if stream == current_stream:
		return
		
	if stream == null:
		stop(fade_time)
		return
		
	match state:
		PlayerState.MUTE:
			player1.stream = stream
			current_stream = stream
			var tween := player1.get_tree().create_tween().set_parallel()
			fade_in(player1, tween, fade_time)
			state = PlayerState.IN_TRANSITION_TO_1
			tween.finished.connect(transition_done(PlayerState.PLAYING_1))
			
		PlayerState.PLAYING_1:
			player2.stream = stream
			current_stream = stream
			var tween := player2.get_tree().create_tween().set_parallel()
			fade_in(player2, tween, fade_time)
			fade_out(player1, tween, fade_time)
			state = PlayerState.IN_TRANSITION_TO_2
			tween.finished.connect(transition_done(PlayerState.PLAYING_2))
			
		PlayerState.PLAYING_2:
			player1.stream = stream
			current_stream = stream
			var tween := player1.get_tree().create_tween().set_parallel()
			fade_in(player1, tween, fade_time)
			fade_out(player2, tween, fade_time)
			state = PlayerState.IN_TRANSITION_TO_1
			tween.finished.connect(transition_done(PlayerState.PLAYING_1))
		
		PlayerState.IN_TRANSITION_TO_1, PlayerState.IN_TRANSITION_TO_2:
			if current_stream == stream:
				in_queue = null
			else:
				in_queue = stream
				in_queue_fade = fade_time
