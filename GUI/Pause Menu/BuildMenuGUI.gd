class_name BuildMenuGUI
extends Control

var projectiles_in_world: Array[SpellBody] = []
@onready var spells_in_world: ItemList = $SpellsInWorld
@onready var projectile_name: LineEdit = $ProjectileName

func _ready() -> void:
	SignalBus.spell_added_to_world.connect(spell_added_into_world)
	SignalBus.spell_removed_from_world.connect(spell_removed_from_world)
	
func spell_added_into_world(projectile: SpellBody) -> void:
	projectiles_in_world.append(projectile)
	update_projectile_list()
	
func spell_removed_from_world(projectile: SpellBody) -> void:
	var pidx := -1
	for i in projectiles_in_world.size():
		var proj := projectiles_in_world[pidx]
		if proj == projectile:
			pidx = i
			break
			
	if pidx != -1:
		projectiles_in_world.remove_at(pidx)
	update_projectile_list()
		
func update_projectile_list() -> void:
	spells_in_world.clear()
	for p in projectiles_in_world:
		spells_in_world.add_item(p.name)

func _on_rename_pressed() -> void:
	var selected := spells_in_world.get_selected_items()
	if selected.is_empty():
		return
		
	var idx := selected[0]
	projectiles_in_world[idx].name = projectile_name.text
	update_projectile_list()


func _on_delete_pressed() -> void:
	var selected := spells_in_world.get_selected_items()
	if selected.is_empty():
		return
	var idx := selected[0]
	
	var proj := projectiles_in_world[idx]
	proj.expired = true
	proj.spell.is_infinite = false
	projectiles_in_world.remove_at(idx)
	projectile_name.text = ""
	update_projectile_list()


func _on_spells_in_world_item_selected(index: int) -> void:
	var proj := projectiles_in_world[index]
	projectile_name.text = proj.name
