class_name RingBuffer

var buffer: Array
var front: int
var tag: String

func _init(k: String = "") -> void:
	buffer = []
	front = 0
	tag = k
		
func append(item: Variant) -> void:
	buffer.append(item)
	
func pop_back() -> Variant:
	var item: Variant = buffer.pop_back()
	if is_empty(): reset()
	return item
	
func pop_front() -> Variant:
	if is_empty(): return null
	var item: Variant = buffer[front]
	front += 1
	if is_empty(): reset()
	return item
	
func is_empty() -> bool:
	return front == buffer.size()
	
func size() -> int:
	return buffer.size() - front
	
func reset() -> void:
	front = 0
	buffer.clear()
