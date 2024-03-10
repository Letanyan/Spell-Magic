class_name GraphicsSettings

var scaling_mode := 0
var scaling := 1.0
var sharpness := 0.2

enum DisplayStyle { WINDOWED, BORDERLESS, FULLSCREEN }
var display_style: DisplayStyle = DisplayStyle.WINDOWED

var display_size: String = "1920x1080 (16:9)"
var msaa: Viewport.MSAA = Viewport.MSAA_DISABLED
var taa: bool = false
var ssaa: Viewport.ScreenSpaceAA = Viewport.SCREEN_SPACE_AA_DISABLED

var max_fps: int = 60
var vsync: bool = true

var viewport: Viewport

func _init(vp: Viewport, should_update: bool = false) -> void:
	viewport = vp
	if should_update:
		update_sharpness(sharpness)
		update_scaling(scaling)
		update_scaling_mode(scaling_mode)
		update_display_style(display_style)
		update_display_size(display_size)
		update_msaa(msaa)
		update_taa(taa)
		update_ssaa(ssaa)
		update_max_fps(max_fps)
		update_vsync(vsync)
		

func save_dict():
	return {
		"scaling_mode": scaling_mode, "scaling": scaling, "sharpness": sharpness,
		"display_style": display_style, "display_size": display_size,
		"msaa": msaa, "taa": taa, "ssaa": ssaa, "max_fps": max_fps, "vsync": vsync,
	}

func load_dict(dict: Dictionary):
	update_sharpness(dict.get("sharpness", 0.2))
	update_scaling(dict.get("scaling", 1.0))
	update_scaling_mode(dict.get("scaling_mode", 0))
	update_display_style(dict.get("display_style", DisplayStyle.WINDOWED))
	update_display_size(dict.get("display_size", "1920x1080 (16:9)"))
	update_msaa(dict.get("msaa", Viewport.MSAA_DISABLED))
	update_taa(dict.get("taa", false))
	update_ssaa(dict.get("ssaa", Viewport.SCREEN_SPACE_AA_DISABLED))
	update_max_fps(dict.get("max_fps", 60))
	update_vsync(dict.get("vsync", true))

func update_sharpness(s: float):
	sharpness = s
	ProjectSettings.set_setting("rendering/scaling_3d/sharpness", sharpness)
	
func update_scaling(s: float):
	scaling = s
	ProjectSettings.set_setting("rendering/scaling_3d/scaling", scaling)
	
func update_scaling_mode(s: int):
	scaling_mode = s
	ProjectSettings.set_setting("rendering/scaling_3d/scaling_mode", scaling_mode)

func update_display_style(style: DisplayStyle):
	display_style = style
	match display_style:
		DisplayStyle.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayStyle.WINDOWED:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayStyle.BORDERLESS:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
func update_display_size(s: String):
	display_size = s
	var size = display_size.split(" ")
	var sizes = size[0].split("x")
	var res = Vector2i(int(sizes[0]), int(sizes[1]))
	DisplayServer.window_set_size(res)
	
func update_msaa(aa: Viewport.MSAA):
	msaa = aa
	viewport.msaa_3d = msaa
	
func update_ssaa(aa: Viewport.ScreenSpaceAA):
	ssaa = aa
	viewport.screen_space_aa = ssaa
	
func update_taa(aa: bool):
	taa = aa
	viewport.use_taa = taa 

func update_max_fps(fps: int):
	max_fps = fps
	Engine.max_fps = fps
	
func update_vsync(v: bool):
	vsync = v
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v else DisplayServer.VSYNC_DISABLED)
