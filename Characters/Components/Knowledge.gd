class_name Knowledge

var entries: Dictionary
var kinds: Dictionary
var ignore: bool
var has_been_updated: bool
var actions: Dictionary

func _init(kind_list: Dictionary, should_ignore: bool):
	entries = {}
	kinds = kind_list
	ignore = should_ignore
	has_been_updated = true
	actions = {}
	
func update_entry_from(entity):
	var info = entries.get(entity.name, null)
	if info == null:
		info = entity.entity_info()
		if (ignore and not kinds.has(info.kind)) or (not ignore and kinds.has(info.kind)):
			entries[entity.name] = info
			has_been_updated = true
	else:
		has_been_updated = has_been_updated or entity.update_entity_info(info)
	

func direct_entry(name: String, info: EntityInfo):
	entries[name] = info
	has_been_updated = true

enum ActionKind {
	WALK, DRINK
}

class Action:
	var kind: ActionKind
	var entity: EntityInfo
	
	func _init(info: EntityInfo, k: ActionKind):
		entity = info
		kind = k
	

func actions_list() -> Dictionary:
	for k in entries:
		var info: EntityInfo = entries[k]
		if not actions.has(k):
			if info.liquid == EntityInfo.Liquid.WATER:
				actions[k] = Action.new(info, ActionKind.DRINK)
			if info.kind == EntityInfo.Kind.BASE:
				actions[k] = Action.new(info, ActionKind.WALK)
	
	return actions
