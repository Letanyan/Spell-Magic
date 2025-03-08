class_name NotesUI
extends Control

@onready var note_content: RichTextLabel = $Notes/Content
@onready var show_notes: OptionButton = $Notes/ShowNotes
@onready var sort_notes: OptionButton = $Notes/SortNotes

func _ready() -> void:
	show_notes.selected = GlobalData.game_settings.notes_unlock_settings
	sort_notes.selected = GlobalData.game_settings.notes_sort_settings

func update_notes() -> void:
	if note_content == null:
		return
	
	var content := ""
	
	if GlobalData.game_settings.notes_unlock_settings == GameSettings.NotesUnlockSettings.HIDE_ALL:
		note_content.text = "[center][font_size=16][b]\n\nAll Notes Are Hidden.\nChange 'Show' Setting Above to Show Notes[/b][/font_size][/center]"
		return
	
	var highlight := func(note: String) -> String:
		if note.begins_with("func"):
			return note.replace("func", "[color=#F70]func[/color]")
		elif note.begins_with("variable"):
			return note.replace("variable", "[color=#7F0]variable[/color]")
		elif note.begins_with("spell"):
			return note.replace("spell", "[color=#0F7]spell[/color]")
		elif note.begins_with("artifact"):
			return note.replace("artifact", "[color=#F07]artifact[/color]")
		elif note.begins_with("wand"):
			return note.replace("wand", "[color=#70F]wand[/color]")
		elif note.begins_with("upgrades"):
			return note.replace("upgrades", "[color=#07F]upgrades[/color]")
		return note
		
	var regex_tag_t := RegEx.new()
	regex_tag_t.compile(r"\{(.+?)\}")
	var tag_t := func(note: String) -> String:
		var m := regex_tag_t.search(note)
		while m != null and m.get_start() > -1:
			var internal := m.get_string(1)
			var prefix := note.left(m.get_start())
			var suffix := note.right(note.length() - m.get_end())
			match internal:
				"Burning": internal = "[color=#FF0000]Burning[/color]"
				"Fire": internal = "[color=#FF0000]Fire[/color]"
				"Wet": internal = "[color=#0080FF]Wet[/color]"
				"Water": internal = "[color=#0080FF]Water[/color]"
				"Feather": internal = "[color=#00FF80]Feather[/color]"
				"Wind": internal = "[color=#00FF80]Wind[/color]"
				"Stun": internal = "[color=#FF0080]Stun[/color]"
				"Electric": internal = "[color=#FF0080]Electric[/color]"
				"Freeze": internal = "[color=#00FFFF]Freeze[/color]"
				"Ice": internal = "[color=#00FFFF]Ice[/color]"
				"Rock": internal = "[color=#FF8000]Rock[/color]"
				
			note = prefix + "[b][i]" + internal + "[/i][/b]" + suffix
			m = regex_tag_t.search(note)
		return note
			
	var notes_keys := GlobalData.game_settings.notes.keys() if GlobalData.game_settings.notes_unlock_settings == GameSettings.NotesUnlockSettings.SHOW_ALL else GlobalData.game_settings.unlocked_notes.keys()
	
	match GlobalData.game_settings.notes_sort_settings:
		GameSettings.NotesSortSettings.ALPHABETICAL: notes_keys.sort_custom(func(a: String, b: String) -> bool: return a < b)
		GameSettings.NotesSortSettings.CHRONOLOGICAL: notes_keys.reverse()
	
	for note: String in notes_keys:
		if GlobalData.game_settings.notes.has(note):
			content += "[font_size=16][b][u]" + highlight.call(note) + "[/u][/b][/font_size]\n"
			content += tag_t.call(GlobalData.game_settings.notes[note]) + "\n\n"
			
	if not notes_keys.is_empty():
		note_content.text = content
	elif GlobalData.game_settings.notes_unlock_settings == GameSettings.NotesUnlockSettings.IN_GAME:
		note_content.text = "[center][font_size=16][b]\n\nExplore the World to Discover Notes[/b][/font_size][/center]"
	
func _on_show_notes_item_selected(index: int) -> void:
	GlobalData.game_settings.notes_unlock_settings = index as GameSettings.NotesUnlockSettings
	UIAudioPlayer.switch()
	update_notes()
	GlobalData.game_settings.save()
	
func _on_sort_notes_item_selected(index: int) -> void:
	GlobalData.game_settings.notes_sort_settings = index as GameSettings.NotesSortSettings
	UIAudioPlayer.switch()
	update_notes()
	GlobalData.game_settings.save()
