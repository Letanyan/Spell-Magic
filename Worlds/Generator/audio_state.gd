class_name AudioState

enum PlayerState { MUTE, PLAYING_1, PLAYING_2, IN_TRANSITION_TO_1, IN_TRANSITION_TO_2 }
const MIN_VOLUME_DB = -80
const MAX_VOLUME_DB = 0

var state: PlayerState:
	set(value):
		print("state: ", PlayerState.keys()[state], " -> ", PlayerState.keys()[value])
		state = value
var player1: AudioStreamPlayer3D
var player2: AudioStreamPlayer3D
var current_stream: AudioStream

var fade_player1: AudioManager.FadeParam
var fade_player2: AudioManager.FadeParam

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
	
func fade_player(player: AudioStreamPlayer3D, from: float, to: float, duration: float, delay: float) -> void:
	var is_for_player_1 := true
	if player == player2:
		is_for_player_1 = false
	
	var fade_param := AudioManager.FadeParam.new()
	fade_param.start_value = from
	fade_param.final_value = to
	if is_nan(duration) or is_nan(delay):
		if is_for_player_1 and fade_player1 != null:
			fade_param.duration = fade_player1.duration
			fade_param.time_stamp = fade_player1.time_stamp
			fade_param.time_delay = fade_player1.time_delay
		elif fade_player2 != null:
			fade_param.duration = fade_player2.duration
			fade_param.time_stamp = fade_player2.time_stamp
			fade_param.time_delay = fade_player2.time_delay
		else:
			fade_param.duration = 0.5
			fade_param.time_stamp = 0.0
			fade_param.time_delay = 0.0
	else:
		fade_param.duration = duration
		fade_param.time_delay = delay
		fade_param.time_stamp = 0
	
	if is_for_player_1: 
		fade_player1 = fade_param
		if not player1.playing:
			player1.play()
	else: 
		fade_player2 = fade_param
		if not player2.playing:
			player2.play()

func fade_in(player: AudioStreamPlayer3D, duration: float, delay: float) -> void:
	fade_player(player, player.volume_db, MAX_VOLUME_DB, duration, delay)
		
func fade_out(player: AudioStreamPlayer3D, duration: float, delay: float) -> void:
	fade_player(player, player.volume_db, MIN_VOLUME_DB, duration, delay)
		
func stop(fade_duration: float) -> void:
	current_stream = null
	match state:
		PlayerState.PLAYING_1:
			fade_out(player1, fade_duration, 0.0)
			state = PlayerState.IN_TRANSITION_TO_2
			
		PlayerState.PLAYING_2:
			fade_out(player2, fade_duration, 0.0)
			state = PlayerState.IN_TRANSITION_TO_1
			
		PlayerState.IN_TRANSITION_TO_1:
			fade_out(player1, NAN, NAN)
			state = PlayerState.IN_TRANSITION_TO_2
			
		PlayerState.IN_TRANSITION_TO_2:
			fade_out(player2, NAN, NAN)
			state = PlayerState.IN_TRANSITION_TO_1
	
func play(stream: AudioStream, fade_duration: float, fade_delay: float) -> void:
	if stream == current_stream:
		return
		
	if stream == null:
		stop(fade_duration)
		return
		
	current_stream = stream
	match state:
		PlayerState.MUTE:
			player1.stream = stream
			fade_in(player1, fade_duration, fade_delay)
			state = PlayerState.IN_TRANSITION_TO_1
			
		PlayerState.PLAYING_1:
			player2.stream = stream
			fade_in(player2, fade_duration, fade_delay)
			fade_out(player1, fade_duration, 0.0)
			state = PlayerState.IN_TRANSITION_TO_2
			
		PlayerState.PLAYING_2:
			player1.stream = stream
			fade_in(player1, fade_duration, fade_delay)
			fade_out(player2, fade_duration, 0.0)
			state = PlayerState.IN_TRANSITION_TO_1
		
		PlayerState.IN_TRANSITION_TO_1:
			player2.stream = stream
			fade_out(player1, NAN, NAN)
			fade_in(player2, NAN, NAN)
			state = PlayerState.IN_TRANSITION_TO_2
			
		PlayerState.IN_TRANSITION_TO_2:
			player1.stream = stream
			fade_in(player1, NAN, NAN)
			fade_out(player2, NAN, NAN)
			state = PlayerState.IN_TRANSITION_TO_1

func update(delta: float) -> void:
	var playing_state_changed := false
	
	if fade_player1 != null:
		fade_player1.time_stamp += delta
		if fade_player1.time_stamp > fade_player1.duration + fade_player1.time_delay:
			if player1.volume_db <= MIN_VOLUME_DB:
				player1.stop()
			fade_player1 = null
			playing_state_changed = true
		elif fade_player1.time_stamp >= fade_player1.time_delay:
			player1.volume_db = lerpf(fade_player1.start_value, fade_player1.final_value, (fade_player1.time_stamp - fade_player1.time_delay) / fade_player1.duration)
		else:
			player1.volume_db = fade_player1.start_value
		
	if fade_player2 != null:
		fade_player2.time_stamp += delta
		if fade_player2.time_stamp > fade_player2.duration + fade_player2.time_delay:
			if player2.volume_db <= MIN_VOLUME_DB:
				player2.stop()
			fade_player2 = null
			playing_state_changed = true
		elif fade_player2.time_stamp >= fade_player2.time_delay:
			player2.volume_db = lerpf(fade_player2.start_value, fade_player2.final_value, (fade_player2.time_stamp - fade_player2.time_delay) / fade_player2.duration)
		else:
			player2.volume_db = fade_player2.start_value
		
	if playing_state_changed:
		if (not player1.playing and fade_player1 == null) and (not player2.playing and fade_player2 == null):
			state = PlayerState.MUTE
		elif player1.playing or fade_player1 != null:
			state = PlayerState.PLAYING_1 if fade_player1 == null else PlayerState.IN_TRANSITION_TO_1
		elif player2.playing or fade_player2 != null:
			state = PlayerState.PLAYING_2 if fade_player2 == null else PlayerState.IN_TRANSITION_TO_2
