class_name ThemeUI
extends Theme


func change_tint_color(tint: Color):
	var root_base_style: StyleBoxFlat = get_stylebox("normal", "Button") as StyleBoxFlat
	var root_disabled_style: StyleBoxFlat = get_stylebox("disabled", "Button") as StyleBoxFlat
	var root_focus_style: StyleBoxFlat = get_stylebox("focus", "Button") as StyleBoxFlat
	var root_hover_style: StyleBoxFlat = get_stylebox("hover", "Button") as StyleBoxFlat
	var root_pressed_style: StyleBoxFlat = get_stylebox("pressed", "Button") as StyleBoxFlat
	
	root_base_style.border_color = tint
	root_disabled_style.border_color = tint
	root_focus_style.border_color = tint
	root_hover_style.border_color = tint
	root_pressed_style.border_color = tint
	
	root_disabled_style.bg_color = tint.darkened(0.75)
	root_hover_style.bg_color = tint.darkened(0.25)
	root_pressed_style.bg_color = tint.darkened(0.5)
	
	#var check_base_style: StyleBoxFlat = get_stylebox("normal", "CheckBox") as StyleBoxFlat
	#var check_disabled_style: StyleBoxFlat = get_stylebox("disabled", "CheckBox") as StyleBoxFlat
	var check_focus_style: StyleBoxFlat = get_stylebox("focus", "CheckBox") as StyleBoxFlat
	var check_hover_style: StyleBoxFlat = get_stylebox("hover", "CheckBox") as StyleBoxFlat
	#var check_pressed_style: StyleBoxFlat = get_stylebox("pressed", "CheckBox") as StyleBoxFlat
	
	check_hover_style.bg_color = tint
	check_hover_style.bg_color.a = 0.25
	check_focus_style.bg_color = tint
	check_focus_style.bg_color.a = 0.25
	
	var tab_base_style: StyleBoxFlat = get_stylebox("tab_unselected", "TabBar") as StyleBoxFlat
	var tab_disabled_style: StyleBoxFlat = get_stylebox("tab_disabled", "TabBar") as StyleBoxFlat
	var tab_focus_style: StyleBoxFlat = get_stylebox("tab_focus", "TabBar") as StyleBoxFlat
	var tab_hover_style: StyleBoxFlat = get_stylebox("tab_hovered", "TabBar") as StyleBoxFlat
	var tab_pressed_style: StyleBoxFlat = get_stylebox("tab_selected", "TabBar") as StyleBoxFlat
	
	tab_base_style.border_color = tint
	tab_disabled_style.border_color = tint
	tab_focus_style.border_color = tint
	tab_hover_style.border_color = tint
	tab_pressed_style.border_color = tint
	
	tab_disabled_style.bg_color = tint.darkened(0.75)
	tab_hover_style.bg_color = tint.darkened(0.25)
	tab_pressed_style.bg_color = tint.darkened(0.5)
	
	var slider_base_style: StyleBoxFlat = get_stylebox("slider", "HSlider") as StyleBoxFlat
	var slider_pressed_style: StyleBoxFlat = get_stylebox("grabber_area", "HSlider") as StyleBoxFlat
	
	slider_base_style.border_color = tint
	slider_pressed_style.bg_color = tint
	slider_pressed_style.border_color = tint
