class_name HUDUpgrades
extends Panel

@onready var progress_1: ProgressBar = $Grid/Progress1
@onready var label_1: RichTextLabel = $Grid/Progress1/Label
@onready var condition_1: RichTextLabel = $Grid/Progress1/Condition

@onready var progress_2: ProgressBar = $Grid/Progress2
@onready var label_2: RichTextLabel = $Grid/Progress2/Label
@onready var condition_2: RichTextLabel = $Grid/Progress2/Condition

@onready var progress_3: ProgressBar = $Grid/Progress3
@onready var label_3: RichTextLabel = $Grid/Progress3/Label
@onready var condition_3: RichTextLabel = $Grid/Progress3/Condition

@onready var progress_4: ProgressBar = $Grid/Progress4
@onready var label_4: RichTextLabel = $Grid/Progress4/Label
@onready var condition_4: RichTextLabel = $Grid/Progress4/Condition

signal upgrade_was_complete(message: String)

func _ready() -> void:
	pass
	
func upgrade_slots_refreshed(settings: UpgradeSettings) -> void:
	progress_1.visible = settings.upgrade_kind[0] != UpgradeSettings.UpgradeKind.NONE
	progress_2.visible = settings.upgrade_kind[1] != UpgradeSettings.UpgradeKind.NONE
	progress_3.visible = settings.upgrade_kind[2] != UpgradeSettings.UpgradeKind.NONE
	progress_4.visible = settings.upgrade_kind[3] != UpgradeSettings.UpgradeKind.NONE
	label_1.text = "[font_size=12][center]" + settings.description_for_upgrade_kind(settings.upgrade_kind[0]) + "[/center][/font_size]"
	label_2.text = "[font_size=12][center]" + settings.description_for_upgrade_kind(settings.upgrade_kind[1]) + "[/center][/font_size]"
	label_3.text = "[font_size=12][center]" + settings.description_for_upgrade_kind(settings.upgrade_kind[2]) + "[/center][/font_size]"
	label_4.text = "[font_size=12][center]" + settings.description_for_upgrade_kind(settings.upgrade_kind[3]) + "[/center][/font_size]"
	condition_1.text = "[font_size=12][center]" + settings.description_upgrade_condition(settings.upgrade_cond[0], settings.upgrade_cond_info[0]) + "[/center][/font_size]"
	condition_2.text = "[font_size=12][center]" + settings.description_upgrade_condition(settings.upgrade_cond[1], settings.upgrade_cond_info[1]) + "[/center][/font_size]"
	condition_3.text = "[font_size=12][center]" + settings.description_upgrade_condition(settings.upgrade_cond[2], settings.upgrade_cond_info[2]) + "[/center][/font_size]"
	condition_4.text = "[font_size=12][center]" + settings.description_upgrade_condition(settings.upgrade_cond[3], settings.upgrade_cond_info[3]) + "[/center][/font_size]"
	progress_1.max_value = settings.upgrade_prog_max[0]
	progress_2.max_value = settings.upgrade_prog_max[1]
	progress_3.max_value = settings.upgrade_prog_max[2]
	progress_4.max_value = settings.upgrade_prog_max[3]
	progress_1.value = settings.upgrade_prog_cur[0]
	progress_2.value = settings.upgrade_prog_cur[1]
	progress_3.value = settings.upgrade_prog_cur[2]
	progress_4.value = settings.upgrade_prog_cur[3]
	
	var upgrades_available := 1 if progress_1.visible else 0
	upgrades_available += 1 if progress_2.visible else 0
	upgrades_available += 1 if progress_3.visible else 0
	upgrades_available += 1 if progress_4.visible else 0
	
	if upgrades_available >= 3:
		visible = true
		size.y = 88
	elif upgrades_available >= 1:
		visible = true
		size.y = 48
	else:
		visible = false
	
func upgrade_slot_progress_update(settings: UpgradeSettings, message: String) -> void:
	progress_1.value = settings.upgrade_prog_cur[0]
	progress_2.value = settings.upgrade_prog_cur[1]
	progress_3.value = settings.upgrade_prog_cur[2]
	progress_4.value = settings.upgrade_prog_cur[3]
	if not message.is_empty():
		upgrade_was_complete.emit(message)
	
