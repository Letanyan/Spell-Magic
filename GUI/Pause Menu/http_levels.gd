extends Node

@onready var http: HTTPRequest = $HTTPRequest
var session_id: String = ""
const BASE_ADDR = "http://144.172.97.48:8181/"
#const BASE_ADDR = "http://127.0.0.1:8181/"
var is_available := true

enum SearchKind { NONE, NAME, USER }

signal got_level(level_id: int, data: Dictionary)
signal added_level(level_id: int)
signal placed_level(level_id: int)
signal got_levels(data: Array, page: int)

func _ready() -> void:
	if GlobalData.is_demo or not is_available:
		return
	if session_id.is_empty():
		if GlobalData.game_settings.user_id == -1:
			sign_up()
		else:
			sign_in()

func sign_up() -> void:
	is_available = OK == http.request(BASE_ADDR + "api/v1/user/sign_up/", [], HTTPClient.METHOD_POST, JSON.stringify({"password": GlobalData.game_settings.password.uri_encode()}))

func sign_in() -> void:
	is_available = OK == http.request(BASE_ADDR + "api/v1/user/sign_in/", [], HTTPClient.METHOD_POST, JSON.stringify({"userid": GlobalData.game_settings.user_id, "password": GlobalData.game_settings.password.uri_encode()}))	

func update_username() -> void:
	if GlobalData.is_demo or not is_available:
		return
	is_available = OK == http.request(BASE_ADDR + "api/v1/user/update_name/", PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_POST, JSON.stringify({"name": GlobalData.game_settings.username}))	
	GlobalData.game_settings.save()

func get_level(id: int) -> void:
	if GlobalData.is_demo or not is_available:
		return
	is_available = OK == http.request(BASE_ADDR + "api/v1/level?id=%d" % id, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_GET)

func compress(data: Dictionary, buffer_size: Globals.Ref) -> PackedByteArray:
	var bytes := var_to_bytes(data)
	buffer_size.data = bytes.size()
	var result := bytes.compress(FileAccess.CompressionMode.COMPRESSION_ZSTD)
	return result

func decompress(buffer_size: int, data: PackedByteArray) -> PackedByteArray:
	return data.decompress(buffer_size, FileAccess.CompressionMode.COMPRESSION_ZSTD)

func add_level(level_name: String, level_desciption: String, data: Dictionary) -> void:
	if GlobalData.is_demo or not is_available:
		return
	var buffer_size := Globals.Ref.new(0)
	var comp := compress(data, buffer_size)
	is_available = OK == http.request_raw(BASE_ADDR + "api/v1/level/?name=%s&desc=%s&datasize=%d" % [level_name.uri_encode(), level_desciption.uri_encode(), buffer_size.data], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_POST, comp)

func put_level(level_id: int, level_name: String, level_desciption: String, data: Dictionary) -> void:
	if GlobalData.is_demo or not is_available:
		return
	var buffer_size := Globals.Ref.new(0)
	var comp := compress(data, buffer_size)
	is_available = OK == http.request_raw(BASE_ADDR + "api/v1/level/?id=%d&name=%s&desc=%s&datasize=%d" % [level_id, level_name.uri_encode(), level_desciption.uri_encode(), buffer_size.data], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, comp)

func get_levels(page: int, search: String, search_kind: SearchKind) -> void:
	if GlobalData.is_demo or not is_available:
		return
	if search.is_empty():
		search_kind = SearchKind.NONE
	match search_kind:
		SearchKind.NONE: http.request(BASE_ADDR + "api/v1/levels?page=%d&limit=50" % page, [], HTTPClient.METHOD_GET, "")
		SearchKind.NAME: http.request(BASE_ADDR + "api/v1/levels?name=%s&page=%d&limit=50" % [search.uri_encode(), page], [], HTTPClient.METHOD_GET, "")
		SearchKind.USER: http.request(BASE_ADDR + "api/v1/levels?user=%s&page=%d&limit=50" % [search.uri_encode(), page], [], HTTPClient.METHOD_GET, "")

func add_level_user_data(level: int) -> void:
	if GlobalData.is_demo or not is_available:
		return
	is_available = OK == http.request(BASE_ADDR + "api/v1/level/data/?levelId=%d" % level, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_POST, "")
	
func put_level_user_data(level: int, vote: int) -> void:
	if GlobalData.is_demo or not is_available:
		return
	var vote_text := ""
	if vote == 1:
		vote_text = "upvote"
	elif vote == -1:
		vote_text = "downvote"
	is_available = OK == http.request(BASE_ADDR + "api/v1/level/data/?levelId=%d&vote=%s" % [level, vote_text.uri_encode()], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, "")
	
func begin_level_user_data_play(level: int) -> void:
	if GlobalData.is_demo or not is_available:
		return
	is_available = OK == http.request(BASE_ADDR + "api/v1/level/data/start/?levelId=%d" % level, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, "")
	
func save_level_user_data_play(level: int) -> void:
	if GlobalData.is_demo or not is_available:
		return
	is_available = OK == http.request(BASE_ADDR + "api/v1/level/data/save/?levelId=%d" % level, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, "")

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	#prints(result, response_code, headers, body)
	var kind := -1
	var page := -1
	const ADD_LEVEL = 0
	const GET_LEVEL = 1
	const PUT_LEVEL = 2
	const SIGN_IN = 3
	const GET_LEVELS = 4
	const SIGN_UP = 5
	for header in headers:
		if header == "Kind: AddLevel":
			kind = ADD_LEVEL
		elif header == "Kind: GetLevel":
			kind = GET_LEVEL
		elif header == "Kind: PutLevel":
			kind = PUT_LEVEL
		elif header == "Kind: SignIn":
			kind = SIGN_IN
		elif header == "Kind: GetLevels":
			kind = GET_LEVELS
		elif header.begins_with("Page: "):
			page = header.split(" ")[1].to_int()
		elif header == "Kind: SignUp":
			kind = SIGN_UP
			
	if kind == ADD_LEVEL:
		var id := body.get_string_from_utf8().to_int()
		added_level.emit(id)
	elif kind == GET_LEVEL:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Dictionary
		var buffer_size := json.get("MaxBufferSize", -1) as int
		var data := json.get("Data", "") as String
		var bytes := Marshalls.base64_to_raw(data)
		var decomp: PackedByteArray
		if buffer_size != -1:
			decomp = decompress(buffer_size, bytes)
		else:
			decomp = bytes
		got_level.emit(json.get("Id", -1) as int, bytes_to_var(decomp) as Dictionary, json)
	elif kind == PUT_LEVEL:
		var id := body.get_string_from_utf8().to_int()
		placed_level.emit(id)
		update_username()
	elif kind == SIGN_IN:
		var data := body.get_string_from_utf8().split("\n", 2)
		session_id = data[0]
		GlobalData.game_settings.user_id = data[1].to_int()
		GlobalData.game_settings.save()
	elif kind == GET_LEVELS:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Array
		got_levels.emit(json, page)
	elif kind == SIGN_UP:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Dictionary
		GlobalData.game_settings.user_id = json.get("user_id", 0) as int
		session_id = json.get("session_id", "") as String
		GlobalData.game_settings.save()
		
