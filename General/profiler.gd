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
	
func lap(log: String = "") -> int:
	var lap_time := (Time.get_ticks_usec() - start_time)
	elapsed += lap_time
	start_time = Time.get_ticks_usec()
	if not log.is_empty(): print(log, ": lap: ", lap_time, ", total: ", elapsed)
	return lap_time
	
func stop(log: String = "") -> int:
	elapsed += (Time.get_ticks_usec() - start_time)
	if not log.is_empty(): print(log, ": ", elapsed)
	return elapsed
