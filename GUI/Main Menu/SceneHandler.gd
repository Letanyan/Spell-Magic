extends Node

# Bacon and Games on YouTube: https://www.youtube.com/watch?v=2uYaoQj_6o0


signal content_finished_loading(content: Variant)
signal content_invalid(content_path:String)
signal content_failed_to_load(content_path:String)


var loading_screen: LoadingScreen
var _loading_screen_scene:PackedScene = preload("res://GUI/Main Menu/LoadingScreen.tscn")
var _transition:String
var _content_path:String
var _load_progress_timer:Timer

func _ready() -> void:
	content_invalid.connect(on_content_invalid)
	content_failed_to_load.connect(on_content_failed_to_load)
	content_finished_loading.connect(on_content_finished_loading)

func load_new_scene(content_path:String, transition_type:String="fade_to_black", on_complete: Callable = func(content: Variant) -> void: pass) -> void:
	_transition = transition_type
	# add loading screen
	loading_screen = _loading_screen_scene.instantiate() as LoadingScreen
	get_tree().root.add_child(loading_screen)
	loading_screen.start_transition(transition_type, _load_content.bind(content_path, on_complete))
	
func _load_content(content_path:String, on_complete: Callable) -> void:
	_content_path = content_path
	var loader := ResourceLoader.load_threaded_request(content_path)
	if not ResourceLoader.exists(content_path) or loader == null:
		content_invalid.emit(content_path)
		return 		
		
	_load_progress_timer = Timer.new()
	_load_progress_timer.wait_time = 0.1
	_load_progress_timer.timeout.connect(monitor_load_status.bind(on_complete))
	get_tree().root.add_child(_load_progress_timer)
	_load_progress_timer.start()

# checks in on loading status - this can also be done with a while loop, but I found that ran too fast
# and ended up skipping over the loading display. 
func monitor_load_status(on_complete: Callable) -> void:
	var load_progress := []
	var load_status := ResourceLoader.load_threaded_get_status(_content_path, load_progress)
	
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			content_invalid.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if loading_screen != null:
				loading_screen.update_bar(load_progress[0] as float * 100) # 0.1
		ResourceLoader.THREAD_LOAD_FAILED:
			content_failed_to_load.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			_load_progress_timer.stop()
			_load_progress_timer.queue_free()
			var content: Variant = (ResourceLoader.load_threaded_get(_content_path) as PackedScene).instantiate()
			content_finished_loading.emit(content)
			#on_complete.call(content)
			return # this last return isn't necessary but I like how the 3 dead ends stand out as similar

func on_content_failed_to_load(path:String) -> void:
	printerr("error: Failed to load resource: '%s'" % [path])	

func on_content_invalid(path:String) -> void:
	printerr("error: Cannot load resource: '%s'" % [path])
	
func on_content_finished_loading(content: Variant) -> void:
	var outgoing_scene := get_tree().current_scene

	# Remove the old scene
	outgoing_scene.queue_free()
	
	# Add and set the new scene to current
	get_tree().root.call_deferred("add_child",content)
	get_tree().set_deferred("current_scene",content)
	
	# probably not necssary since we split our content_finished_loading but it won't hurt to have an extra check
	if loading_screen != null:
		loading_screen.finish_transition()
		# wait for LoadingScreen's transition to finish playing
		await loading_screen.anim_player.animation_finished
		loading_screen = null

