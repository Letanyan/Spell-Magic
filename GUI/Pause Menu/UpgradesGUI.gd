class_name UpgradesGUI
extends Control

var world_settings: WorldSettings:
	set(value):
		world_settings = value
		update_state(WorldSettings.PurchaseError.NONE)

@onready var max_P_current: Label = $container/max_P/current
@onready var max_P_upgrade: Button = $container/max_P/upgrade
@onready var max_P_cost: RichTextLabel = $container/max_P/upgrade/cost

@onready var max_v_current: Label = $container/max_v/current
@onready var max_v_upgrade: Button = $container/max_v/upgrade
@onready var max_v_cost: RichTextLabel = $container/max_v/upgrade/cost

@onready var max_N_current: Label = $container/max_N/current
@onready var max_N_upgrade: Button = $container/max_N/upgrade
@onready var max_N_cost: RichTextLabel = $container/max_N/upgrade/cost

@onready var max_M_current: Label = $container/max_M/current
@onready var max_M_upgrade: Button = $container/max_M/upgrade
@onready var max_M_cost: RichTextLabel = $container/max_M/upgrade/cost

@onready var max_r_current: Label = $container/max_r/current
@onready var max_r_upgrade: Button = $container/max_r/upgrade
@onready var max_r_cost: RichTextLabel = $container/max_r/upgrade/cost

@onready var max_T_current: Label = $container/max_T/current
@onready var max_T_upgrade: Button = $container/max_T/upgrade
@onready var max_T_cost: RichTextLabel = $container/max_T/upgrade/cost

@onready var max_H_current: Label = $container/max_H/current
@onready var max_H_upgrade: Button = $container/max_H/upgrade
@onready var max_H_cost: RichTextLabel = $container/max_H/upgrade/cost

@onready var max_spell_count_current: Label = $container/max_spell_count/current
@onready var max_spell_count_upgrade: Button = $container/max_spell_count/upgrade
@onready var max_spell_count_cost: RichTextLabel = $container/max_spell_count/upgrade/cost

@onready var element_void_upgrade: Button = $container/elements/Void
@onready var element_void_cost: RichTextLabel = $container/elements/Void/cost
@onready var element_fire_upgrade: Button = $container/elements/Fire
@onready var element_fire_cost: RichTextLabel = $container/elements/Fire/cost
@onready var element_water_upgrade: Button = $container/elements/Water
@onready var element_water_cost: RichTextLabel = $container/elements/Water/cost
@onready var element_air_upgrade: Button = $container/elements/Air
@onready var element_air_cost: RichTextLabel = $container/elements/Air/cost
@onready var element_rock_upgrade: Button = $container/elements/Rock
@onready var element_rock_cost: RichTextLabel = $container/elements/Rock/cost
@onready var element_ice_upgrade: Button = $container/elements/Ice
@onready var element_ice_cost: RichTextLabel = $container/elements/Ice/cost
@onready var element_electric_upgrade: Button = $container/elements/Electric
@onready var element_electric_cost: RichTextLabel = $container/elements/Electric/cost

@onready var chain_at_start_upgrade: Button = $container/chain_methods/at_start
@onready var chain_at_start_cost: RichTextLabel = $container/chain_methods/at_start/cost
@onready var chain_at_end_upgrade: Button = $container/chain_methods/at_end
@onready var chain_at_end_cost: RichTextLabel = $container/chain_methods/at_end/cost
@onready var chain_on_hit_upgrade: Button = $container/chain_methods/on_hit
@onready var chain_on_hit_cost: RichTextLabel = $container/chain_methods/on_hit/cost

@onready var currency: RichTextLabel = $container/Currency

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_state(purchase_error: WorldSettings.PurchaseError):
	max_spell_count_current.text = str(world_settings.max_spells_in_book)
	max_P_current.text = str(world_settings.max_P)
	max_v_current.text = str(world_settings.max_v)
	max_N_current.text = str(world_settings.max_N)
	max_T_current.text = str(world_settings.max_T)
	max_M_current.text = str(world_settings.max_mana)
	max_r_current.text = str(world_settings.max_r)
	max_H_current.text = str(world_settings.max_health)
	
	element_void_upgrade.disabled = world_settings.check_if_has_spell_element(Spell.Element.VOID)
	element_fire_upgrade.disabled = world_settings.check_if_has_spell_element(Spell.Element.FIRE)
	element_water_upgrade.disabled = world_settings.check_if_has_spell_element(Spell.Element.WATER)
	element_air_upgrade.disabled = world_settings.check_if_has_spell_element(Spell.Element.AIR)
	element_rock_upgrade.disabled = world_settings.check_if_has_spell_element(Spell.Element.ROCK)
	element_ice_upgrade.disabled = world_settings.check_if_has_spell_element(Spell.Element.ICE)
	element_electric_upgrade.disabled = world_settings.check_if_has_spell_element(Spell.Element.ELECTRIC)
	
	chain_at_start_upgrade.disabled = world_settings.check_if_has_chain_method(Spell.ChainCastKind.START)
	chain_at_end_upgrade.disabled = world_settings.check_if_has_chain_method(Spell.ChainCastKind.END)
	chain_on_hit_upgrade.disabled = world_settings.check_if_has_chain_method(Spell.ChainCastKind.HIT)
	
	var coin_suffix := " [img]res://GUI/Images/coins.svg[/img][/center]"
	max_spell_count_cost.text = "[center]" + str(world_settings.cost_spells_in_book) + coin_suffix
	max_P_cost.text = "[center]" + str(world_settings.cost_P) + coin_suffix
	max_v_cost.text = "[center]" + str(world_settings.cost_v) + coin_suffix
	max_N_cost.text = "[center]" + str(world_settings.cost_N) + coin_suffix
	max_T_cost.text = "[center]" + str(world_settings.cost_T) + coin_suffix
	max_M_cost.text = "[center]" + str(world_settings.cost_mana) + coin_suffix
	max_r_cost.text = "[center]" + str(world_settings.cost_r) + coin_suffix
	max_H_cost.text = "[center]" + str(world_settings.cost_health) + coin_suffix
	
	element_void_cost.text = "[center]" + str(world_settings.cost_spell_element) + coin_suffix
	element_fire_cost.text = "[center]" + str(world_settings.cost_spell_element) + coin_suffix
	element_water_cost.text = "[center]" + str(world_settings.cost_spell_element) + coin_suffix
	element_air_cost.text = "[center]" + str(world_settings.cost_spell_element) + coin_suffix
	element_rock_cost.text = "[center]" + str(world_settings.cost_spell_element) + coin_suffix
	element_ice_cost.text = "[center]" + str(world_settings.cost_spell_element) + coin_suffix
	element_electric_cost.text = "[center]" + str(world_settings.cost_spell_element) + coin_suffix
	
	chain_at_start_cost.text = "[center]" + str(world_settings.cost_chain_method) + coin_suffix
	chain_at_end_cost.text = "[center]" + str(world_settings.cost_chain_method) + coin_suffix
	chain_on_hit_cost.text = "[center]" + str(world_settings.cost_chain_method) + coin_suffix
	
	currency.text = "[right]" + str(world_settings.currency) + " [img]res://GUI/Images/coins.svg[/img][/right]"
	
	max_spell_count_upgrade.disabled = world_settings.max_spells_in_book >= WorldSettings.LIMIT_SPELLS_IN_BOOK
	max_P_upgrade.disabled = world_settings.max_P >= WorldSettings.LIMIT_P
	max_v_upgrade.disabled = world_settings.max_v >= WorldSettings.LIMIT_v
	max_T_upgrade.disabled = world_settings.max_T >= WorldSettings.LIMIT_T
	max_N_upgrade.disabled = world_settings.max_N >= WorldSettings.LIMIT_N
	max_H_upgrade.disabled = world_settings.max_health >= WorldSettings.LIMIT_HEALTH
	max_M_upgrade.disabled = world_settings.max_mana >= WorldSettings.LIMIT_MANA
	max_r_upgrade.disabled = world_settings.max_r >= WorldSettings.LIMIT_r
	
	max_spell_count_upgrade.text = "+ " + str(world_settings.upgrade_spells_in_book)
	max_P_upgrade.text = "+ " + str(world_settings.upgrade_P)
	max_v_upgrade.text = "+ " + str(world_settings.upgrade_v)
	max_T_upgrade.text = "+ " + str(world_settings.upgrade_T)
	max_N_upgrade.text = "+ " + str(world_settings.upgrade_N)
	max_H_upgrade.text = "+ " + str(world_settings.upgrade_health)
	max_M_upgrade.text = "+ " + str(world_settings.upgrade_mana)
	max_r_upgrade.text = "+ " + str(world_settings.upgrade_r)

func _on_max_spell_count_upgrade_pressed() -> void:
	var err := world_settings.purchase_spells_in_book()
	update_state(err)
	
func _on_void_upgrade_pressed() -> void:
	var err := world_settings.purchase_spell_element(Spell.Element.VOID)
	update_state(err)

func _on_fire_upgrade_pressed() -> void:
	var err := world_settings.purchase_spell_element(Spell.Element.FIRE)
	update_state(err)

func _on_water_upgrade_pressed() -> void:
	var err := world_settings.purchase_spell_element(Spell.Element.WATER)
	update_state(err)
	
func _on_air_upgrade_pressed() -> void:
	var err := world_settings.purchase_spell_element(Spell.Element.AIR)
	update_state(err)

func _on_rock_upgrade_pressed() -> void:
	var err := world_settings.purchase_spell_element(Spell.Element.ROCK)
	update_state(err)

func _on_ice_upgrade_pressed() -> void:
	var err := world_settings.purchase_spell_element(Spell.Element.ICE)
	update_state(err)

func _on_electric_upgrade_pressed() -> void:
	var err := world_settings.purchase_spell_element(Spell.Element.ELECTRIC)
	update_state(err)

func _on_max_P_upgrade_pressed() -> void:
	var err := world_settings.purchase_P()
	update_state(err)
	
func _on_max_v_upgrade_pressed() -> void:
	var err := world_settings.purchase_v()
	update_state(err)

func _on_max_T_upgrade_pressed() -> void:
	var err := world_settings.purchase_T()
	update_state(err)

func _on_max_N_upgrade_pressed() -> void:
	var err := world_settings.purchase_N()
	update_state(err)

func _on_max_M_upgrade_pressed() -> void:
	var err := world_settings.purchase_mana()
	update_state(err)
	
func _on_max_R_upgrade_pressed() -> void:
	var err := world_settings.purchase_r()
	update_state(err)

func _on_at_start_upgrade_pressed() -> void:
	var err := world_settings.purchase_chain_method(Spell.ChainCastKind.START)
	update_state(err)

func _on_at_end_upgrade_pressed() -> void:
	var err := world_settings.purchase_chain_method(Spell.ChainCastKind.END)
	update_state(err)

func _on_on_hit_upgrade_pressed() -> void:
	var err := world_settings.purchase_chain_method(Spell.ChainCastKind.HIT)
	update_state(err)

func _on_max_H_upgrade_pressed() -> void:
	var err := world_settings.purchase_health()
	update_state(err)
	
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not has_focus():
		return
		
	var direction := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back")
	
	if max_spell_count_upgrade.has_focus():
		if direction.y > 0:
			element_void_upgrade.grab_focus()
	elif element_void_upgrade.has_focus():
		if direction.x > 0:
			element_fire_upgrade.grab_focus()
		if direction.y < 0:
			max_spell_count_upgrade.grab_focus()
		if direction.y > 0:
			max_P_upgrade.grab_focus()
	elif element_fire_upgrade.has_focus():
		if direction.x < 0:
			element_void_upgrade.grab_focus()
		if direction.x > 0:
			element_water_upgrade.grab_focus()
		if direction.y < 0:
			max_spell_count_upgrade.grab_focus()
		if direction.y > 0:
			max_P_upgrade.grab_focus()
	elif element_water_upgrade.has_focus():
		if direction.x < 0:
			element_fire_upgrade.grab_focus()
		if direction.x > 0:
			element_air_upgrade.grab_focus()
		if direction.y < 0:
			max_spell_count_upgrade.grab_focus()
		if direction.y > 0:
			max_P_upgrade.grab_focus()
	elif element_air_upgrade.has_focus():
		if direction.x < 0:
			element_water_upgrade.grab_focus()
		if direction.x > 0:
			element_rock_upgrade.grab_focus()
		if direction.y < 0:
			max_spell_count_upgrade.grab_focus()
		if direction.y > 0:
			max_P_upgrade.grab_focus()
	elif element_rock_upgrade.has_focus():
		if direction.x < 0:
			element_air_upgrade.grab_focus()
		if direction.x > 0:
			element_ice_upgrade.grab_focus()
		if direction.y < 0:
			max_spell_count_upgrade.grab_focus()
		if direction.y > 0:
			max_T_upgrade.grab_focus()
	elif element_ice_upgrade.has_focus():
		if direction.x < 0:
			element_rock_upgrade.grab_focus()
		if direction.x > 0:
			element_electric_upgrade.grab_focus()
		if direction.y < 0:
			max_spell_count_upgrade.grab_focus()
		if direction.y > 0:
			max_T_upgrade.grab_focus()
	elif element_electric_upgrade.has_focus():
		if direction.x < 0:
			element_ice_upgrade.grab_focus()
		if direction.y < 0:
			max_spell_count_upgrade.grab_focus()
		if direction.y > 0:
			max_T_upgrade.grab_focus()
	elif max_P_upgrade.has_focus():
		if direction.x > 0:
			max_T_upgrade.grab_focus()
		if direction.y < 0:
			element_void_upgrade.grab_focus()
		if direction.y > 0:
			max_N_upgrade.grab_focus()
	elif max_T_upgrade.has_focus():
		if direction.x < 0:
			max_P_upgrade.grab_focus()
		if direction.y < 0:
			element_electric_upgrade.grab_focus()
		if direction.y > 0:
			max_M_upgrade.grab_focus()
	elif max_N_upgrade.has_focus():
		if direction.x > 0:
			max_M_upgrade.grab_focus()
		if direction.y < 0:
			max_P_upgrade.grab_focus()
		if direction.y > 0:
			max_r_upgrade.grab_focus()
	elif max_M_upgrade.has_focus():
		if direction.x < 0:
			max_N_upgrade.grab_focus()
		if direction.y < 0:
			max_T_upgrade.grab_focus()
		if direction.y > 0:
			max_H_upgrade.grab_focus()
	elif max_r_upgrade.has_focus():
		if direction.x > 0:
			max_H_upgrade.grab_focus()
		if direction.y < 0:
			max_N_upgrade.grab_focus()
		if direction.y > 0:
			chain_at_start_upgrade.grab_focus()
	elif max_H_upgrade.has_focus():
		if direction.x < 0:
			max_r_upgrade.grab_focus()
		if direction.y < 0:
			max_M_upgrade.grab_focus()
		if direction.y > 0:
			max_v_upgrade.grab_focus()
	elif chain_at_start_upgrade.has_focus():
		if direction.x > 0:
			chain_at_end_upgrade.grab_focus()
		if direction.y < 0:
			max_r_upgrade.grab_focus()
	elif chain_at_end_upgrade.has_focus():
		if direction.x < 0:
			chain_at_start_upgrade.grab_focus()
		if direction.x > 0:
			chain_on_hit_upgrade.grab_focus()
		if direction.y < 0:
			max_r_upgrade.grab_focus()
	elif chain_on_hit_upgrade.has_focus():
		if direction.x < 0:
			chain_at_end_upgrade.grab_focus()
		if direction.x > 0:
			max_v_upgrade.grab_focus()
		if direction.y < 0:
			max_r_upgrade.grab_focus()
	elif max_v_upgrade.has_focus():
		if direction.x < 0:
			chain_on_hit_upgrade.grab_focus()
		if direction.y < 0:
			max_H_upgrade.grab_focus()
			
			
			
			
