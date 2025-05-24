extends Node

@onready var http: HTTPRequest = $HTTPRequest

signal got_level(level_id: int, data: Dictionary)
signal added_level(level_id: int)

func get_level(id: int) -> void:
	http.request("http://127.0.0.1:8181/api/v1/level?id=%d" % id, PackedStringArray(["Cookie: user_token=I3ygQBvLIrJIPfx3Y97U1y8n42pxXXoi57YSyufi2NI4yjMYiXcxDfZcIqSh3aJnqvDMPNBGyJkY0LseRhz6QIwBkElWQWxqw7tCepvjAVoJLT8iu6URcj9lM3gPwGg85"]), HTTPClient.METHOD_GET)

func save_level(level_name: String, data: Dictionary) -> void:
	http.request_raw("http://127.0.0.1:8181/api/v1/level/?name=%s" % level_name.replace(" ", "%20"), PackedStringArray(["Cookie: user_token=I3ygQBvLIrJIPfx3Y97U1y8n42pxXXoi57YSyufi2NI4yjMYiXcxDfZcIqSh3aJnqvDMPNBGyJkY0LseRhz6QIwBkElWQWxqw7tCepvjAVoJLT8iu6URcj9lM3gPwGg85"]), HTTPClient.METHOD_POST, var_to_bytes(data))

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var kind := -1
	print(result)
	print(response_code)
	print(headers)
	for header in headers:
		if header == "Kind: AddLevel":
			kind = 0
			break
		elif header == "Kind: GetLevel":
			kind = 1
			break
			
	if kind == 0:
		var id := body.get_string_from_utf8().to_int()
		added_level.emit(id)
	elif kind == 1:
		var json := JSON.parse_string(body.get_string_from_utf8()) as Dictionary
		var data := json.get("Data", "") as String
		var bytes := Marshalls.base64_to_raw(data)
		got_level.emit(json.get("Id", -1) as int, bytes_to_var(bytes) as Dictionary)
	
