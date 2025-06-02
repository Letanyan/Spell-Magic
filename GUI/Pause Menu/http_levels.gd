extends Node

@onready var http: HTTPRequest = $HTTPRequest
var session_id: String = ""
const BASE_ADDR = "http://127.0.0.1:8181/"

signal got_level(level_id: int, data: Dictionary)
signal added_level(level_id: int)
signal placed_level(level_id: int)
signal got_levels(data: Array, page: int)

func _ready() -> void:
	if GlobalData.is_demo:
		return
	if session_id.is_empty():
		http.request(BASE_ADDR + "api/v1/user/sign_in/", [], HTTPClient.METHOD_POST, "name=%s&password=%s" % [GlobalData.game_settings.username, GlobalData.game_settings.password])

func get_level(id: int) -> void:
	if GlobalData.is_demo:
		return
	http.request(BASE_ADDR + "api/v1/level?id=%d" % id, PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_GET)

func add_level(level_name: String, level_desciption: String, data: Dictionary) -> void:
	if GlobalData.is_demo:
		return
	http.request_raw(BASE_ADDR + "api/v1/level/?name=%s&desc=%s" % [level_name.replace(" ", "%20"), level_desciption.replace(" ", "%20")], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_POST, var_to_bytes(data))

func put_level(level_id: int, level_desciption: String, data: Dictionary) -> void:
	if GlobalData.is_demo:
		return
	http.request_raw(BASE_ADDR + "api/v1/level/?id=%d&desc=%s" % [level_id, level_desciption.replace(" ", "%20")], PackedStringArray(["Cookie: user_token=%s" % session_id]), HTTPClient.METHOD_PUT, var_to_bytes(data))

func get_levels(page: int) -> void:
	if GlobalData.is_demo:
		return
	http.request(BASE_ADDR + "api/v1/levels?page=%d&limit=50" % page, [], HTTPClient.METHOD_GET, "")

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
			
	if kind == 0:
		var id := body.get_string_from_utf8().to_int()
		added_level.emit(id)
	elif kind == 1:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Dictionary
		var data := json.get("Data", "") as String
		var bytes := Marshalls.base64_to_raw(data)
		got_level.emit(json.get("Id", -1) as int, bytes_to_var(bytes) as Dictionary)
	elif kind == 2:
		var id := body.get_string_from_utf8().to_int()
		placed_level.emit(id)
	elif kind == 3:
		session_id = body.get_string_from_utf8()
	elif kind == 4:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Array
		got_levels.emit(json, page)
