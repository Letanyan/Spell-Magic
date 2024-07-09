class_name WordGenerator

enum SourcePath {
	none,
	russian_names, satellites, scottish_names,
	spanish_names, swedish_names, swiss_names, capital_cities,
	chinese_names, constellations, cumbria_names, dutch_names,
	english_names, french_names, german_names, greek_islands,
	iclandic_names, indian_names, irish_names, italian_names,
	japanese_names, roman_names, latin_names,
}

var initial: Dictionary = {} # [String]float
var transitions: Dictionary = {} # [String][String]float
var originals: Dictionary = {} # [String]bool
var output: Dictionary = {} # [String]bool

var source := PackedStringArray([])

var source_paths: Array[SourcePath] = []
var chunk_sizes: Array[int] = []

func _init(source_path: SourcePath) -> void:
	if source_path == SourcePath.none:
		return
	add_source(source_path)
	
func add_source(source_path: SourcePath, chunk_size: int = 2, clear_current_source: bool = true) -> void:
	if clear_current_source:
		source.clear()
		originals.clear()
		transitions.clear()
		source_paths.clear()
		chunk_sizes.clear()
		
	if source_path == SourcePath.none:
		return
		
	if source_paths.find(source_path) != -1:
		return
		
	source_paths.append(source_path)
	chunk_sizes.append(chunk_size)
		
	var file := FileAccess.open(("res://Characters/Player/Words/%s.txt" % (SourcePath.keys()[source_path])) as String, FileAccess.READ)
	while true:
		var line := file.get_line()
		if line.is_empty():
			break
		source.append(line)
		
	var initial_count := 0.0
	var transition_count := {} # [String]float
	for _word in source:
		originals[_word] = true
		var word := _word + "."
		var i := 0
		var e := word.length() - chunk_size
		while i < e:
			var s := word.substr(i, chunk_size)
			var r := word.substr(i + 1, chunk_size)
			if i == 0:
				if not initial.has(s):
					initial[s] = 0.0
				initial_count += 1.0
				initial[s] += 1.0
			if not transitions.has(s):
				transitions[s] = {}
			if not transition_count.has(s):
				transition_count[s] = 0.0
			if not (transitions[s] as Dictionary).has(r):
				transitions[s][r] = 0.0
			transition_count[s] += 1.0
			transitions[s][r] += 1.0
			i += 1
			
	
	for s: String in initial:
		initial[s] = initial[s] / initial_count
	for s: String in transitions:
		for r: String in transitions[s]:
			transitions[s][r] = transitions[s][r] / transition_count[s]
	
func generate(max_word_length: int, word_count: int = 1, max_length: int = (max_word_length + 1) * word_count, is_unique: bool = true, max_attempts: int = 10) -> String:
	if max_attempts <= 0:
		if output.is_empty():
			return Time.get_datetime_string_from_system(true, true)
		output.clear()
		return generate(max_word_length, word_count, max_length, true)
		
	var s := Population.random_entity_from_non_relative_distribution(randf(), initial, "") as String
	var result := s
	var current_word_length := s.length()
	while word_count > 0:
		if result.length() >= max_length:
			word_count -= 1
			result += " "
			break
		if current_word_length >= max_word_length:
			word_count -= 1
			result += " "
			s = Population.random_entity_from_non_relative_distribution(randf(), initial, "") as String
			current_word_length = 0
			continue
		if not transitions.has(s):
			word_count -= 1
			result += " "
			s = Population.random_entity_from_non_relative_distribution(randf(), initial, "") as String
			current_word_length = 0
			continue
		var next := Population.random_entity_from_non_relative_distribution(randf(), transitions[s] as Dictionary, "") as String
		if next.length() <= 0:
			word_count -= 1
			result += " "
			s = Population.random_entity_from_non_relative_distribution(randf(), initial, "") as String
			current_word_length = 0
			continue
		s = next
		var last_char := next[next.length() - 1]
		if last_char == ".":
			word_count -= 1
			result += " "
			s = Population.random_entity_from_distribution(randf(), initial, "") as String
			current_word_length = 0
			continue
			
		current_word_length += 1
		result += last_char
		
	result = result.trim_suffix(" ")
	if not is_unique or not originals.has(result):
		output[result.capitalize()] = true
	else:
		return generate(max_word_length, word_count, max_length, true, max_attempts - 1)
		
	return result

func select_random(word_count: int = 1, is_unique: bool = true, max_attempts: int = 10) -> String:
	if max_attempts <= 0:
		if output.is_empty():
			return Time.get_datetime_string_from_system(true, true)
		output.clear()
		return select_random(word_count, true)
		
	var result := ""
	while word_count > 0:
		result += source[randi_range(0, source.size() - 1)]
		word_count -= 1
		
	if not is_unique or not originals.has(result):
		output[result.capitalize()] = true
	else:
		return select_random(word_count, true, max_attempts - 1)
		
	return result

func save_dict() -> Dictionary:
	var result := {}
	result["source_paths"] = source_paths
	result["chunk_sizes"] = chunk_sizes
	result["output"] = output
	
	return result
	
func load_dict(data: Dictionary) -> void:
	output = data["output"]
	var temp_source_paths: Array[SourcePath] = []
	temp_source_paths.assign(data["source_paths"] as Array)
	chunk_sizes.assign(data["chunk_sizes"] as Array)
	
	var remove_all: Array[SourcePath] = []
	var found := {}
	var path_index := 0
	for path in source_paths:
		if found.has(path):
			remove_all.append(path_index)
		else:
			found[path] = true
		path_index += 1
			
	remove_all.reverse()
	for idx in remove_all:
		source_paths.remove_at(idx)
		chunk_sizes.remove_at(idx)
	
	for index in temp_source_paths.size():
		var path := temp_source_paths[index]
		var chunk := chunk_sizes[index]
		add_source(path, chunk, false)
		
	
	
