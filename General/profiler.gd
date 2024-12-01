class_name Profiler

var start_time: int
var elapsed: int

func _init() -> void:
	start_time = Time.get_ticks_usec()
	elapsed = 0
	
func start() -> void:
	start_time = Time.get_ticks_usec()
	
func reset() -> void:
	start_time = Time.get_ticks_usec()
	elapsed = 0
	
func lap(desc: String = "") -> int:
	var lap_time := (Time.get_ticks_usec() - start_time)
	elapsed += lap_time
	start_time = Time.get_ticks_usec()
	if not desc.is_empty(): print(desc, ": lap: ", lap_time, ", total: ", elapsed)
	return lap_time
	
func stop(desc: String = "") -> int:
	elapsed += (Time.get_ticks_usec() - start_time)
	if not desc.is_empty(): print(desc, ": ", elapsed)
	return elapsed

func seconds() -> float:
	return elapsed / 1e6
