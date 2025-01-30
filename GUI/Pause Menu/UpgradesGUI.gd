class_name UpgradesGUI
extends Control

var settings: WorldSettings:
	set(value):
		settings = value
		update_state(UpgradeSettings.PurchaseError.NONE)

@onready var max_P_current: Label = $container/max_P/current
@onready var max_P_upgrade: Button = $container/max_P/upgrade
@onready var max_P_cost: RichTextLabel = $container/max_P/upgrade/cost

@onready var max_v_current: Label = $container/max_v/current
@onready var max_v_upgrade: Button = $container/max_v/upgrade
@onready var max_v_cost: RichTextLabel = $container/max_v/upgrade/cost

@onready var max_cd_current: Label = $container/crit_dmg/current
@onready var max_cd_upgrade: Button = $container/crit_dmg/upgrade
@onready var max_cd_cost: RichTextLabel = $container/crit_dmg/upgrade/cost

@onready var max_cr_current: Label = $container/crit_rate/current
@onready var max_cr_upgrade: Button = $container/crit_rate/upgrade
@onready var max_cr_cost: RichTextLabel = $container/crit_rate/upgrade/cost

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

@onready var max_running_speed_current: Label = $container/running_speed/current
@onready var max_running_speed_upgrade: Button = $container/running_speed/upgrade
@onready var max_running_speed_cost: RichTextLabel = $container/running_speed/upgrade/cost

@onready var attack_current: Label = $container/attack/current
@onready var attack_upgrade: Button = $container/attack/upgrade
@onready var attack_cost: RichTextLabel = $container/attack/upgrade/cost

@onready var defence_current: Label = $container/defence/current
@onready var defence_upgrade: Button = $container/defence/upgrade
@onready var defence_cost: RichTextLabel = $container/defence/upgrade/cost

@onready var mana_regen_current: Label = $container/mana_regen/current
@onready var mana_regen_upgrade: Button = $container/mana_regen/upgrade
@onready var mana_regen_cost: RichTextLabel = $container/mana_regen/upgrade/cost

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

func update_state(purchase_error: UpgradeSettings.PurchaseError) -> void:
	if purchase_error != UpgradeSettings.PurchaseError.NONE:
		var message := ""
		if purchase_error == UpgradeSettings.PurchaseError.NOT_ENOUGH_CURRENCY:
			message = "Not enough coins to make purchase. Defeat enemies to gain coins."
		elif purchase_error == UpgradeSettings.PurchaseError.UPGRADE_IS_OVER_LIMIT:
			message = "Max level reached. Can not upgrade furthur."
		var popup := PopupDialog.display(message, "Okay", "")
		popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
		popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
		popup.show_in_root(self)
		return
	
	max_spell_count_current.text = str(settings.upgrade_settings.max_spells_in_book())
	max_running_speed_current.text = str(settings.upgrade_settings.max_running_speed())
	max_P_current.text = str(settings.upgrade_settings.max_P())
	max_v_current.text = str(settings.upgrade_settings.max_v())
	max_N_current.text = str(settings.upgrade_settings.max_N())
	max_T_current.text = str(settings.upgrade_settings.max_T())
	max_M_current.text = str(settings.upgrade_settings.max_mana())
	max_r_current.text = str(settings.upgrade_settings.max_r())
	max_H_current.text = str(settings.upgrade_settings.max_health())
	attack_current.text = str(settings.upgrade_settings.max_attack())
	defence_current.text = str(settings.upgrade_settings.max_defence())
	mana_regen_current.text = str(settings.upgrade_settings.max_mana_regen())
	max_cr_current.text = str(settings.upgrade_settings.max_crit_rate())
	max_cd_current.text = str(settings.upgrade_settings.max_crit_dmg())
	
	element_void_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.VOID)
	element_fire_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.FIRE)
	element_water_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.WATER)
	element_air_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.AIR)
	element_rock_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ROCK)
	element_ice_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ICE)
	element_electric_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ELECTRIC)
	
	chain_at_start_upgrade.disabled = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.START)
	chain_at_end_upgrade.disabled = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.END)
	chain_on_hit_upgrade.disabled = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.HIT)
	
	var coin_suffix := " [img color=#ffc000]res://GUI/Images/coins.svg[/img][/center]"
	max_spell_count_cost.text = "[center]" + str(settings.upgrade_settings.cost_spells_in_book()) + coin_suffix
	max_running_speed_cost.text = "[center]" + str(settings.upgrade_settings.cost_running_speed()) + coin_suffix
	max_P_cost.text = "[center]" + str(settings.upgrade_settings.cost_P()) + coin_suffix
	max_v_cost.text = "[center]" + str(settings.upgrade_settings.cost_v()) + coin_suffix
	max_N_cost.text = "[center]" + str(settings.upgrade_settings.cost_N()) + coin_suffix
	max_T_cost.text = "[center]" + str(settings.upgrade_settings.cost_T()) + coin_suffix
	max_M_cost.text = "[center]" + str(settings.upgrade_settings.cost_mana()) + coin_suffix
	max_r_cost.text = "[center]" + str(settings.upgrade_settings.cost_r()) + coin_suffix
	max_H_cost.text = "[center]" + str(settings.upgrade_settings.cost_health()) + coin_suffix
	attack_cost.text = "[center]" + str(settings.upgrade_settings.cost_attack()) + coin_suffix
	defence_cost.text = "[center]" + str(settings.upgrade_settings.cost_defence()) + coin_suffix
	mana_regen_cost.text = "[center]" + str(settings.upgrade_settings.cost_mana_regen()) + coin_suffix
	max_cr_cost.text = "[center]" + str(settings.upgrade_settings.cost_crit_rate()) + coin_suffix
	max_cd_cost.text = "[center]" + str(settings.upgrade_settings.cost_crit_dmg()) + coin_suffix
	
	element_void_cost.text = "[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix
	element_fire_cost.text = "[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix
	element_water_cost.text = "[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix
	element_air_cost.text = "[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix
	element_rock_cost.text = "[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix
	element_ice_cost.text = "[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix
	element_electric_cost.text = "[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix
	
	chain_at_start_cost.text = "[center]" + str(settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.START) ) + coin_suffix
	chain_at_end_cost.text = "[center]" + str(settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.END)) + coin_suffix
	chain_on_hit_cost.text = "[center]" + str(settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.HIT)) + coin_suffix
	
	currency.text = "[right]" + str(settings.upgrade_settings.currency) + " [img color=#ffc000]res://GUI/Images/coins.svg[/img][/right]"
	
	max_spell_count_upgrade.disabled = settings.upgrade_settings.level_spells_in_book >= UpgradeSettings.level_max_spells_in_book
	max_running_speed_upgrade.disabled = settings.upgrade_settings.level_running_speed >= UpgradeSettings.level_max_running_speed
	max_P_upgrade.disabled = settings.upgrade_settings.level_P >= UpgradeSettings.level_max_P
	max_v_upgrade.disabled = settings.upgrade_settings.level_v >= UpgradeSettings.level_max_v
	max_T_upgrade.disabled = settings.upgrade_settings.level_T >= UpgradeSettings.level_max_T
	max_N_upgrade.disabled = settings.upgrade_settings.level_N >= UpgradeSettings.level_max_N
	max_H_upgrade.disabled = settings.upgrade_settings.level_health >= UpgradeSettings.level_max_health
	max_M_upgrade.disabled = settings.upgrade_settings.level_mana >= UpgradeSettings.level_max_mana
	max_r_upgrade.disabled = settings.upgrade_settings.level_r >= UpgradeSettings.level_max_r
	attack_upgrade.disabled = settings.upgrade_settings.level_attack >= UpgradeSettings.level_max_attack
	defence_upgrade.disabled = settings.upgrade_settings.level_defence >= UpgradeSettings.level_max_defence
	mana_regen_upgrade.disabled = settings.upgrade_settings.level_mana_regen >= UpgradeSettings.level_max_mana_regen
	max_cr_upgrade.disabled = settings.upgrade_settings.level_crit_rate >= UpgradeSettings.level_max_crit_rate
	max_cd_upgrade.disabled = settings.upgrade_settings.level_crit_dmg >= UpgradeSettings.level_max_crit_dmg
	
	max_spell_count_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_spells_in_book())
	max_running_speed_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_running_speed()) + "m/s"
	max_P_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_P())
	max_v_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_v()) + "m/s"
	max_T_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_T()) + "s"
	max_N_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_N())
	max_H_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_health())
	max_M_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_mana())
	max_r_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_r()) + "m"
	attack_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_attack())
	defence_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_defence())
	mana_regen_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_mana_regen())
	max_cr_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_crit_rate()) + "%"
	max_cd_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_crit_dmg())

func _on_max_spell_count_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spells_in_book()
	UIAudioPlayer.click()
	update_state(err)
	
func _on_max_running_speed_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_running_speed()
	update_state(err)
	
func _on_void_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.VOID)
	UIAudioPlayer.click()
	update_state(err)

func _on_fire_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.FIRE)
	UIAudioPlayer.click()
	update_state(err)

func _on_water_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.WATER)
	UIAudioPlayer.click()
	update_state(err)
	
func _on_air_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.AIR)
	UIAudioPlayer.click()
	update_state(err)

func _on_rock_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.ROCK)
	UIAudioPlayer.click()
	update_state(err)

func _on_ice_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.ICE)
	UIAudioPlayer.click()
	update_state(err)

func _on_electric_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.ELECTRIC)
	UIAudioPlayer.click()
	update_state(err)

func _on_max_P_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_P()
	UIAudioPlayer.click()
	update_state(err)
	
func _on_max_v_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_v()
	UIAudioPlayer.click()
	update_state(err)

func _on_max_T_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_T()
	UIAudioPlayer.click()
	update_state(err)

func _on_max_N_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_N()
	UIAudioPlayer.click()
	update_state(err)

func _on_max_M_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_mana()
	UIAudioPlayer.click()
	update_state(err)
	
func _on_max_R_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_r()
	UIAudioPlayer.click()
	update_state(err)

func _on_at_start_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_chain_method(Spell.ChainCastKind.START)
	UIAudioPlayer.click()
	update_state(err)

func _on_at_end_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_chain_method(Spell.ChainCastKind.END)
	UIAudioPlayer.click()
	update_state(err)

func _on_on_hit_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_chain_method(Spell.ChainCastKind.HIT)
	UIAudioPlayer.click()
	update_state(err)

func _on_max_H_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_health()
	UIAudioPlayer.click()
	update_state(err)
	
func _on_attack_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_attack()
	UIAudioPlayer.click()
	update_state(err)

func _on_defence_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_defence()
	UIAudioPlayer.click()
	update_state(err)
	
func _on_mana_regen_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_mana_regen()
	UIAudioPlayer.click()
	update_state(err)


func _on_crit_rate_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_crit_rate()
	UIAudioPlayer.click()
	update_state(err)

func _on_crit_dmg_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_crit_dmg()
	UIAudioPlayer.click()
	update_state(err)
