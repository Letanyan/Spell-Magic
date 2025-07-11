extends Node

@onready var http: HTTPRequest = $HTTPRequest
var session_id: String = ""
const BASE_ADDR = "http://127.0.0.1:8181/"
const IS_WIP = true

enum SearchKind { NONE, NAME, USER }

signal got_level(level_id: int, data: Dictionary)
signal added_level(level_id: int)
signal placed_level(level_id: int)
signal got_levels(data: Array, page: int)

func _ready() -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	if session_id.is_empty():
		if GlobalData.game_settings.user_id == -1:
			sign_up()
		else:
			sign_in()

func sign_up() -> void:
	http.request(BASE_ADDR + "api/v1/user/sign_up/", [], HTTPClient.METHOD_POST, JSON.stringify({"password": GlobalData.game_settings.password.uri_encode()}))

func sign_in() -> void:
	http.request(BASE_ADDR + "api/v1/user/sign_in/", [], HTTPClient.METHOD_POST, JSON.stringify({"userid": GlobalData.game_settings.user_id, "password": GlobalData.game_settings.password.uri_encode()}))	

func update_username() -> void:
	http.request(BASE_ADDR + "api/v1/user/update_name/", PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_POST, JSON.stringify({"name": GlobalData.game_settings.username}))	
	GlobalData.game_settings.save()

func get_level(id: int) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	http.request(BASE_ADDR + "api/v1/level?id=%d" % id, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_GET)

func add_level(level_name: String, level_desciption: String, data: Dictionary) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	http.request_raw(BASE_ADDR + "api/v1/level/?name=%s&desc=%s" % [level_name.uri_encode(), level_desciption.uri_encode()], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_POST, var_to_bytes(data))

func put_level(level_id: int, level_desciption: String, data: Dictionary) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	http.request_raw(BASE_ADDR + "api/v1/level/?id=%d&desc=%s" % [level_id, level_desciption.uri_encode()], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, var_to_bytes(data))

func get_levels(page: int, search: String, search_kind: SearchKind) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	if search.is_empty():
		search_kind = SearchKind.NONE
	match search_kind:
		SearchKind.NONE: http.request(BASE_ADDR + "api/v1/levels?page=%d&limit=50" % page, [], HTTPClient.METHOD_GET, "")
		SearchKind.NAME: http.request(BASE_ADDR + "api/v1/levels?name=%s&page=%d&limit=50" % [search.uri_encode(), page], [], HTTPClient.METHOD_GET, "")
		SearchKind.USER: http.request(BASE_ADDR + "api/v1/levels?user=%s&page=%d&limit=50" % [search.uri_encode(), page], [], HTTPClient.METHOD_GET, "")

func add_level_user_data(level: int) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	http.request(BASE_ADDR + "api/v1/level/data/?levelId=%d" % level, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_POST, "")
	
func put_level_user_data(level: int, vote: int) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	var vote_text := ""
	if vote == 1:
		vote_text = "upvote"
	elif vote == -1:
		vote_text = "downvote"
	http.request(BASE_ADDR + "api/v1/level/data/?levelId=%d&vote=%s" % [level, vote_text.uri_encode()], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, "")
	
func begin_level_user_data_play(level: int) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	http.request(BASE_ADDR + "api/v1/level/data/start/?levelId=%d" % level, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, "")
	
func save_level_user_data_play(level: int) -> void:
	if GlobalData.is_demo or IS_WIP:
		return
	http.request(BASE_ADDR + "api/v1/level/data/save/?levelId=%d" % level, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, "")

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	#prints(result, response_code, headers, body)
	var kind := -1
	var page := -1
	for header in headers:
		if header == "Kind: AddLevel":
			kind = 0
		elif header == "Kind: GetLevel":
			kind = 1
		elif header == "Kind: PutLevel":
			kind = 2
		elif header == "Kind: SignIn":
			kind = 3
		elif header == "Kind: GetLevels":
			kind = 4
		elif header.begins_with("Page: "):
			page = header.split(" ")[1].to_int()
		elif header == "Kind: SignUp":
			kind = 5
			
	if kind == 0:
		var id := body.get_string_from_utf8().to_int()
		added_level.emit(id)
	elif kind == 1:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Dictionary
		var data := json.get("Data", "") as String
		var bytes := Marshalls.base64_to_raw(data)
		got_level.emit(json.get("Id", -1) as int, bytes_to_var(bytes) as Dictionary, json)
	elif kind == 2:
		var id := body.get_string_from_utf8().to_int()
		placed_level.emit(id)
		update_username()
	elif kind == 3:
		session_id = body.get_string_from_utf8()
	elif kind == 4:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Array
		got_levels.emit(json, page)
	elif kind == 5:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Dictionary
		GlobalData.game_settings.user_id = json.get("user_id", 0) as int
		session_id = json.get("session_id", "") as String
		GlobalData.game_settings.save()
		
