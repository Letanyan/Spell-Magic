class_name Knowledge

var entries: Dictionary
var kinds: Dictionary
var ignore: bool

func _init(kind_list: Dictionary, should_ignore: bool):
	entries = {}
	kinds = kind_list
	ignore = should_ignore
	
func update_entry_from(entity):
	var info = entries.get(entity.name, null)
	if info == null:
		info = entity.entity_info()
		if (ignore and not kinds.has(info.kind)) or (not ignore and kinds.has(info.kind)):
			entries[entity.name] = info
	else:
		entity.update_entity_info(info)
