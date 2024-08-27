class_name ThemeUI
extends Theme


func change_tint_color(tint: Color) -> void:
	var root_base_style: StyleBoxGradientFill = get_stylebox("normal", "Button") as StyleBoxGradientFill
	var root_disabled_style: StyleBoxGradientFill = get_stylebox("disabled", "Button") as StyleBoxGradientFill
	var root_focus_style: StyleBoxGradientFill = get_stylebox("focus", "Button") as StyleBoxGradientFill
	var root_hover_style: StyleBoxGradientFill = get_stylebox("hover", "Button") as StyleBoxGradientFill
	var root_pressed_style: StyleBoxGradientFill = get_stylebox("pressed", "Button") as StyleBoxGradientFill
	
	var base_tint := tint
	var base_degen_tint := tint
	base_degen_tint.h = clampf(base_degen_tint.h - 0.111111, 0.0, 1.0)
	
	var degen_tint := base_degen_tint
	
	root_base_style.set_border_gradient(tint, Color(1, 0, 0))
	root_hover_style.set_border_gradient(tint, degen_tint)
	root_hover_style.set_fill_gradient(tint, degen_tint)
	root_pressed_style.set_border_gradient(tint, degen_tint)
	
	degen_tint.a = 0.0
	root_focus_style.set_fill_gradient(tint, degen_tint)
	
	degen_tint.s = 1.0
	degen_tint.a = 1.0
	tint.s = 1.0
	root_pressed_style.set_fill_gradient(tint, degen_tint)
	
	tint = base_tint
	tint.s = 0.7
	tint.v = 0.7
	degen_tint = base_degen_tint
	degen_tint.s = 0.7
	degen_tint.v = 0.7
	root_disabled_style.set_fill_gradient(tint, degen_tint)
	
	#var check_base_style: StyleBoxFlat = get_stylebox("normal", "CheckBox") as StyleBoxFlat
	#var check_disabled_style: StyleBoxFlat = get_stylebox("disabled", "CheckBox") as StyleBoxFlat
	var check_focus_style: StyleBoxGradientFill = get_stylebox("focus", "CheckBox") as StyleBoxGradientFill
	var check_hover_style: StyleBoxGradientFill = get_stylebox("hover", "CheckBox") as StyleBoxGradientFill
	#var check_pressed_style: StyleBoxFlat = get_stylebox("pressed", "CheckBox") as StyleBoxFlat
	
	tint = base_tint
	degen_tint = base_degen_tint
	degen_tint.a = 0.0
	
	check_hover_style.set_fill_gradient(tint, degen_tint)
	check_focus_style.set_fill_gradient(tint, degen_tint)
	
	var tab_base_style: StyleBoxGradientFill = get_stylebox("tab_unselected", "TabBar") as StyleBoxGradientFill
	#var tab_disabled_style: StyleBoxGradientFill = get_stylebox("tab_disabled", "TabBar") as StyleBoxGradientFill
	var tab_focus_style: StyleBoxGradientFill = get_stylebox("tab_focus", "TabBar") as StyleBoxGradientFill
	var tab_hover_style: StyleBoxGradientFill = get_stylebox("tab_hovered", "TabBar") as StyleBoxGradientFill
	var tab_pressed_style: StyleBoxGradientFill = get_stylebox("tab_selected", "TabBar") as StyleBoxGradientFill
	
	tint = base_tint
	degen_tint = base_degen_tint
	
	tab_base_style.set_border_gradient(tint, degen_tint)
	tab_hover_style.set_border_gradient(tint, degen_tint)
	tab_hover_style.set_fill_gradient(tint, degen_tint)
	tab_pressed_style.set_border_gradient(tint, degen_tint)
	
	degen_tint.a = 0.0
	tab_focus_style.set_fill_gradient(tint, degen_tint)
	
	degen_tint.s = 1.0
	degen_tint.a = 1.0
	tint.s = 1.0
	tab_pressed_style.set_fill_gradient(tint, degen_tint)
	
	#tint = base_tint
	#tint.s = 0.7
	#tint.v = 0.7
	#degen_tint = base_degen_tint
	#degen_tint.s = 0.7
	#degen_tint.v = 0.7
	#tab_disabled_style.set_fill_gradient(tint, degen_tint)
	
	var slider_pressed_style: StyleBoxGradientFill = get_stylebox("grabber_area", "HSlider") as StyleBoxGradientFill
	
	tint = base_tint
	degen_tint = base_degen_tint
	
	slider_pressed_style.set_border_gradient(tint, degen_tint)
	
	tint.s = 1.0
	degen_tint.s = 1.0
	slider_pressed_style.set_fill_gradient(tint, degen_tint)
