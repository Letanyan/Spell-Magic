@tool
extends EditorPlugin


var editor_interface: EditorInterface
var code_editor: CodeEdit
var search_interface: Control
var is_regex_search: bool
var origin_cursor: Vector2i
var origin_selection: Vector4i
var findings: Array[Vector3i]
var current_finding: int


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	var script_editor := editor_interface.get_script_editor()
	script_editor.editor_script_changed.connect(on_script_changed)
	script_editor.script_close.connect(on_script_closed)
	on_script_changed(script_editor.get_current_script())

	var settings := editor_interface.get_editor_settings()
	settings.settings_changed.connect(on_settings_changed)
	on_settings_changed()
	
	search_interface = preload("res://addons/BetterSearch/better_search.tscn").instantiate()
	(search_interface.get_node("SearchBox") as LineEdit).text_changed.connect(search_box_text_changed)
	(search_interface.get_node("SearchBox") as LineEdit).text_submitted.connect(search_box_text_submitted)
	(search_interface.get_node("SearchBox") as LineEdit).focus_entered.connect(search_box_focus_entered)
	(search_interface.get_node("SearchBox") as LineEdit).focus_exited.connect(search_box_focus_exited)
	(search_interface.get_node("SearchBox") as LineEdit).visibility_changed.connect(visibility_changed)
	(search_interface.get_node("IsRegex") as CheckBox).toggled.connect(is_regex_toggled)
	(search_interface.get_node("IsRegex") as CheckBox).focus_entered.connect(search_button_focus_entered)
	(search_interface.get_node("IsRegex") as CheckBox).focus_exited.connect(search_button_focus_exited)
	(search_interface.get_node("Next") as Button).pressed.connect(next_pressed)
	(search_interface.get_node("Next") as Button).focus_entered.connect(search_button_focus_entered)
	(search_interface.get_node("Next") as Button).focus_exited.connect(search_button_focus_exited)
	(search_interface.get_node("Prev") as Button).pressed.connect(prev_pressed)
	(search_interface.get_node("Prev") as Button).focus_entered.connect(search_button_focus_entered)
	(search_interface.get_node("Prev") as Button).focus_exited.connect(search_button_focus_exited)
	(search_interface.get_node("SelectAll") as Button).pressed.connect(select_all_pressed)
	(search_interface.get_node("SelectAll") as Button).focus_entered.connect(search_button_focus_entered)
	(search_interface.get_node("SelectAll") as Button).focus_exited.connect(search_button_focus_exited)
	(search_interface.get_node("Clear") as Button).pressed.connect(clear_pressed)
	(search_interface.get_node("Clear") as Button).focus_entered.connect(search_button_focus_entered)
	(search_interface.get_node("Clear") as Button).focus_exited.connect(search_button_focus_exited)
	
	is_regex_search = false
	origin_cursor = Vector2i.ZERO
	findings = []
	current_finding = -1
	
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()
	event.alt_pressed = true
	event.key_label = KEY_L
	shortcut.events.append(event)
	add_control_to_bottom_panel(search_interface, "SeaSel", shortcut)


func _exit_tree() -> void:
	remove_control_from_bottom_panel(search_interface)
	search_interface.queue_free()
	
func visibility_changed() -> void:
	var box := search_interface.get_node("SearchBox") as LineEdit
	if box.visible:
		box.grab_focus()
		search_code_editor(box.text)

func on_script_changed(script: Script) -> void:
	var script_editor := editor_interface.get_script_editor()
	var scrpit_editor_base := script_editor.get_current_editor()
	if scrpit_editor_base:
		code_editor = scrpit_editor_base.get_base_editor() as CodeEdit
	
func on_script_closed(script: Script) -> void:
	pass
	
func on_settings_changed() -> void:
	pass

func search_box_focus_entered() -> void:
	if code_editor == null:
		return
	
	origin_cursor = Vector2i(code_editor.get_caret_line(), code_editor.get_caret_column())
	code_editor.highlight_all_occurrences = false
	if code_editor.get_selected_text() != "":
		origin_selection = Vector4i(code_editor.get_selection_from_line(), code_editor.get_selection_from_column(), code_editor.get_selection_to_line(), code_editor.get_selection_to_column())
	else:
		origin_selection = Vector4i(1, 1, code_editor.get_line_count(), code_editor.get_line(code_editor.get_line_count()).length())
	
func search_box_focus_exited() -> void:
	if code_editor == null:
		return
		
	origin_cursor = Vector2i.ZERO
	code_editor.highlight_all_occurrences = true
	origin_selection = Vector4i.ZERO
	
func search_button_focus_entered() -> void:
	if code_editor == null:
		return
	
	origin_cursor = Vector2i(code_editor.get_caret_line(), code_editor.get_caret_column())
	code_editor.highlight_all_occurrences = false
	
func search_button_focus_exited() -> void:
	if code_editor == null:
		return
		
	origin_cursor = Vector2i.ZERO
	code_editor.highlight_all_occurrences = true
		
func search_box_text_changed(new_text: String) -> void:
	search_code_editor(new_text)
	
func search_box_text_submitted(new_text: String) -> void:
	if code_editor == null:
		return
	select_all_pressed()
	
func is_regex_toggled(toggled_on: bool) -> void:
	is_regex_search = toggled_on
	
func next_pressed() -> void:
	if code_editor == null:
		return
	if not findings.is_empty():
		current_finding += 1
		if current_finding >= findings.size():
			current_finding = 0
		var finding := findings[current_finding]
		code_editor.select(finding.x, finding.y, finding.x, finding.y + finding.z)
		code_editor.center_viewport_to_caret()
		code_editor.queue_redraw()
	
func prev_pressed() -> void:
	if code_editor == null:
		return
	if not findings.is_empty():
		current_finding -= 1
		if current_finding < 0:
			current_finding = findings.size() - 1
		var finding := findings[current_finding]
		code_editor.select(finding.x, finding.y, finding.x, finding.y + finding.z)
		code_editor.center_viewport_to_caret()
		code_editor.queue_redraw()
	
func select_all_pressed() -> void:
	if code_editor == null:
		return
		
	var i := 0
	for finding in findings:
		if i != 0:
			code_editor.add_caret(finding.x, finding.y)
		code_editor.select(finding.x, finding.y, finding.x, finding.y + finding.z, i)
		i += 1
		
	code_editor.queue_redraw()
	code_editor.grab_focus()
	
func clear_pressed() -> void:
	if code_editor == null:
		return
		
	findings.clear()
	code_editor.deselect()
	(search_interface.get_node("SearchBox") as LineEdit).clear()
	(search_interface.get_node("SearchBox") as LineEdit).grab_focus()
	
func find_next_match(needle: String, haystack: String, line: int, col: int) -> Vector3i:
	return Vector3i(line, haystack.find(needle, col), needle.length())
	
func find_next_regex_match(needle: RegEx, haystack: String, line: int, col: int) -> Vector3i:
	var m := needle.search(haystack, col)
	if m == null:
		return Vector3(line, -1, 0)
	else:
		return Vector3i(line, m.get_start(), m.get_end() - m.get_start())
	
func search_code_editor(search_text: String) -> void:
	if code_editor == null:
		return
		
	var start_line := origin_selection.x
	var start_col := origin_selection.y
	var end_line := origin_selection.z
	var end_col := origin_selection.w
	
	var search_regex: RegEx
	if is_regex_search:
		search_regex = RegEx.new()
		search_regex.compile(search_text)
	
	findings.clear()
	current_finding = -1
	var best_match := Vector3i(-1, -1, -1)
	for line in range(start_line, end_line + 1):
		var finding: Vector3i
		if is_regex_search:
			finding = find_next_regex_match(search_regex, code_editor.get_line(line), line, 1 if line != start_line else start_col)
		else:
			finding = find_next_match(search_text, code_editor.get_line(line), line, 1 if line != start_line else start_col)
		var hard_limit := 50
		while finding.y != -1 and hard_limit > 0:
			if line == end_line and finding.y + finding.z > end_col:
				break
			hard_limit -= 1
			findings.append(finding)
			if current_finding == -1:
				best_match = finding
				current_finding = findings.size() - 1
			elif origin_cursor.distance_to(Vector2i(best_match.x, best_match.y)) >= origin_cursor.distance_to(Vector2i(finding.x, finding.y)):
				best_match = finding
				current_finding = findings.size() - 1
			finding = find_next_match(search_text, code_editor.get_line(line), finding.x, finding.y + finding.z)
	
	if current_finding != -1:
		var finding := findings[current_finding]
		code_editor.select(finding.x, finding.y, finding.x, finding.y + finding.z)
		code_editor.center_viewport_to_caret()
		code_editor.queue_redraw()
	
static func find_first_node_of_type(p: Node, type: String) -> Node:
	if p.get_class() == type:
		return p
	for c in p.get_children():
		var t := find_first_node_of_type(c, type)
		if t:
			return t
	return null
