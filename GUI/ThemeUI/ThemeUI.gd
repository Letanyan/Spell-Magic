class_name ThemeUI
extends Theme

func change_tint_color(tint: Color, variation: HUDSettings.ThemeKind) -> Color:
	# enum ThemeVariation { FLAT, MONO, COMP, ANA, TRI, TETRA, ELEMENTS }
	match variation:
		HUDSettings.ThemeKind.FLAT:
			change_tint_color_array(PackedColorArray([tint, tint]))
			return tint
		
		HUDSettings.ThemeKind.MONO: 
			return change_tint_color_mono(tint)
		
		HUDSettings.ThemeKind.COMP:
			var start := tint
			var end := tint
			var h := end.h + 0.5
			if h > 1.0: h -= 1.0
			end.h = h
			change_tint_color_array(PackedColorArray([start, end]))
			return start
			
		HUDSettings.ThemeKind.ANA:
			var start := tint
			var sh := start.h - 0.08333
			if sh < 0.0: sh += 1.0
			start.h = sh
			
			var end := tint
			var eh := end.h + 0.08333
			if eh > 1.0: eh -= 1.0
			end.h = eh
			
			change_tint_color_array(PackedColorArray([start, tint, end]))
			return start
			
		HUDSettings.ThemeKind.TRI:
			var start := tint
			var sh := start.h - 0.3333
			if sh < 0.0: sh += 1.0
			start.h = sh
			
			var end := tint
			var eh := end.h + 0.3333
			if eh > 1.0: eh -= 1.0
			end.h = eh
			
			change_tint_color_array(PackedColorArray([start, tint, end]))
			return start
			
		HUDSettings.ThemeKind.TETRA:
			var next1 := tint
			var n1 := next1.h + 0.25
			if n1 > 1.0: n1 -= 1.0
			next1.h = n1
			
			var next2 := tint
			var n2 := next2.h + 0.5
			if n2 > 1.0: n2 -= 1.0
			next2.h = n2
			
			var next3 := tint
			var n3 := next3.h + 0.75
			if n3 > 1.0: n3 -= 1.0
			next3.h = n3
			
			change_tint_color_array(PackedColorArray([tint, next1, next2, next3]))
			return tint
			
		HUDSettings.ThemeKind.ELEMENTS:
			var colors := [
				Color("FF0000"),
				Color("FF8000"),
				Color("FF0080"),
				Color("0080FF"),
				Color("00FF80"),
				Color("00FFFF"),
			]
			change_tint_color_array(PackedColorArray(colors))
			return colors[0]
			
	return Color.BLACK
			

func change_tint_color_mono(tint: Color) -> Color:
	var root_base_style: StyleBoxGradientFill = get_stylebox("normal", "Button") as StyleBoxGradientFill
	var root_disabled_style: StyleBoxGradientFill = get_stylebox("disabled", "Button") as StyleBoxGradientFill
	var root_focus_style: StyleBoxGradientFill = get_stylebox("focus", "Button") as StyleBoxGradientFill
	var root_hover_style: StyleBoxGradientFill = get_stylebox("hover", "Button") as StyleBoxGradientFill
	var root_pressed_style: StyleBoxGradientFill = get_stylebox("pressed", "Button") as StyleBoxGradientFill
	
	var result_tint := tint
	if tint.s < 0.25:
		tint.s = 0.25
		tint.h = 0.66667 + (tint.s * 4) * 0.0392157
		result_tint = tint
	
	var base_tint := tint
	var base_degen_tint := tint
	base_degen_tint.h = clampf(maxf(base_degen_tint.h - 0.111111, 0.0), 0.0, 1.0)
	
	var degen_tint := base_degen_tint
	
	root_base_style.set_border_gradient(tint, degen_tint)
	root_hover_style.set_border_gradient(tint, degen_tint)
	root_hover_style.set_fill_gradient(tint, degen_tint)
	root_pressed_style.set_border_gradient(tint, degen_tint)
	root_pressed_style.set_fill_gradient(tint, degen_tint)
	
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
	#var check_pressed_style: StyleBoxFlat = get_stylebox("hover_pressed", "CheckBox") as StyleBoxFlat
	
	tint = base_tint
	degen_tint = base_degen_tint
	degen_tint.a = 0.0
	
	check_hover_style.set_fill_gradient(tint, degen_tint)
	check_focus_style.set_fill_gradient(tint, degen_tint)
	
	var tab_base_style: StyleBoxGradientFill = get_stylebox("tab_unselected", "TabBar") as StyleBoxGradientFill
	var tab_disabled_style: StyleBoxGradientFill = get_stylebox("tab_disabled", "TabBar") as StyleBoxGradientFill
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
	
	tint = base_tint
	tint.s = 0.7
	tint.v = 0.7
	degen_tint = base_degen_tint
	degen_tint.s = 0.7
	degen_tint.v = 0.7
	tab_disabled_style.set_fill_gradient(tint, degen_tint)
	
	var slider_pressed_style: StyleBoxGradientFill = get_stylebox("grabber_area", "HSlider") as StyleBoxGradientFill
	var scroll_hover_style: StyleBoxGradientFill = get_stylebox("grabber", "HScrollBar") as StyleBoxGradientFill
	var v_slider_pressed_style: StyleBoxGradientFill = get_stylebox("grabber_area", "VSlider") as StyleBoxGradientFill
	var v_scroll_hover_style: StyleBoxGradientFill = get_stylebox("grabber", "VScrollBar") as StyleBoxGradientFill
	
	tint = base_tint
	degen_tint = base_degen_tint
	
	slider_pressed_style.set_border_gradient(tint, degen_tint)
	scroll_hover_style.set_border_gradient(tint, degen_tint)
	v_slider_pressed_style.set_border_gradient(tint, degen_tint)
	v_scroll_hover_style.set_border_gradient(tint, degen_tint)
	
	tint.s = 1.0
	degen_tint.s = 1.0
	slider_pressed_style.set_fill_gradient(tint, degen_tint)
	scroll_hover_style.set_fill_gradient(tint, degen_tint)
	v_slider_pressed_style.set_fill_gradient(tint, degen_tint)
	v_scroll_hover_style.set_fill_gradient(tint, degen_tint)
	
	return result_tint

func change_tint_color_array(tint: PackedColorArray) -> void:
	var root_base_style: StyleBoxGradientFill = get_stylebox("normal", "Button") as StyleBoxGradientFill
	var root_disabled_style: StyleBoxGradientFill = get_stylebox("disabled", "Button") as StyleBoxGradientFill
	var root_focus_style: StyleBoxGradientFill = get_stylebox("focus", "Button") as StyleBoxGradientFill
	var root_hover_style: StyleBoxGradientFill = get_stylebox("hover", "Button") as StyleBoxGradientFill
	var root_pressed_style: StyleBoxGradientFill = get_stylebox("pressed", "Button") as StyleBoxGradientFill
	
	var offsets := PackedFloat32Array([])
	var alpha_tints: Array[Color] = []
	for i in tint.size(): 
		var x := float(i) / float(tint.size() - 1)
		offsets.append(x)
		alpha_tints.append(Color(tint[i], 1.0 - x))
	
	root_base_style.set_complete_border_gradient(tint, offsets)
	root_hover_style.set_complete_border_gradient(tint, offsets)
	root_hover_style.set_complete_fill_gradient(tint, offsets)
	root_pressed_style.set_complete_border_gradient(tint, offsets)
	root_pressed_style.set_complete_fill_gradient(tint, offsets)
	
	root_focus_style.set_complete_fill_gradient(alpha_tints, offsets)
	
	root_pressed_style.set_complete_fill_gradient(tint, offsets)
	
	root_disabled_style.set_complete_fill_gradient(tint, offsets)
	
	#var check_base_style: StyleBoxFlat = get_stylebox("normal", "CheckBox") as StyleBoxFlat
	#var check_disabled_style: StyleBoxFlat = get_stylebox("disabled", "CheckBox") as StyleBoxFlat
	var check_focus_style: StyleBoxGradientFill = get_stylebox("focus", "CheckBox") as StyleBoxGradientFill
	var check_hover_style: StyleBoxGradientFill = get_stylebox("hover", "CheckBox") as StyleBoxGradientFill
	#var check_pressed_style: StyleBoxFlat = get_stylebox("hover_pressed", "CheckBox") as StyleBoxFlat
	
	check_hover_style.set_complete_fill_gradient(alpha_tints, offsets)
	check_focus_style.set_complete_fill_gradient(alpha_tints, offsets)
	
	var tab_base_style: StyleBoxGradientFill = get_stylebox("tab_unselected", "TabBar") as StyleBoxGradientFill
	var tab_disabled_style: StyleBoxGradientFill = get_stylebox("tab_disabled", "TabBar") as StyleBoxGradientFill
	var tab_focus_style: StyleBoxGradientFill = get_stylebox("tab_focus", "TabBar") as StyleBoxGradientFill
	var tab_hover_style: StyleBoxGradientFill = get_stylebox("tab_hovered", "TabBar") as StyleBoxGradientFill
	var tab_pressed_style: StyleBoxGradientFill = get_stylebox("tab_selected", "TabBar") as StyleBoxGradientFill
	
	tab_base_style.set_complete_border_gradient(tint, offsets)
	tab_hover_style.set_complete_border_gradient(tint, offsets)
	tab_hover_style.set_complete_fill_gradient(tint, offsets)
	tab_pressed_style.set_complete_border_gradient(tint, offsets)
	tab_pressed_style.set_complete_fill_gradient(tint, offsets)
	
	tab_focus_style.set_complete_fill_gradient(alpha_tints, offsets)
	
	tab_disabled_style.set_complete_fill_gradient(tint, offsets)
	
	var slider_pressed_style: StyleBoxGradientFill = get_stylebox("grabber_area", "HSlider") as StyleBoxGradientFill
	var scroll_hover_style: StyleBoxGradientFill = get_stylebox("grabber", "HScrollBar") as StyleBoxGradientFill
	var v_slider_pressed_style: StyleBoxGradientFill = get_stylebox("grabber_area", "VSlider") as StyleBoxGradientFill
	var v_scroll_hover_style: StyleBoxGradientFill = get_stylebox("grabber", "VScrollBar") as StyleBoxGradientFill
	
	slider_pressed_style.set_complete_border_gradient(tint, offsets)
	scroll_hover_style.set_complete_border_gradient(tint, offsets)
	v_slider_pressed_style.set_complete_border_gradient(tint, offsets)
	v_scroll_hover_style.set_complete_border_gradient(tint, offsets)
	
	slider_pressed_style.set_complete_fill_gradient(tint, offsets)
	scroll_hover_style.set_complete_fill_gradient(tint, offsets)
	v_slider_pressed_style.set_complete_fill_gradient(tint, offsets)
	v_scroll_hover_style.set_complete_fill_gradient(tint, offsets)
