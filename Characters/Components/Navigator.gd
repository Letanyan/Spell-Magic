class_name Navigator

class VectorEdge:
	var p: Vector3
	var q: Vector3
	
	func _init(a: Vector3, b: Vector3):
		p = a
		q = b
		

static func edges(parent: Node3D, shape: Shape3D) -> Dictionary:
	if shape is CylinderShape3D:
		var bottom = parent.global_position
		var radius = shape.radius * 2
		var result = {}
		var pivot = Vector3(radius, 0, 0)
		var p = bottom + pivot
		for t in range(8):
			var q = bottom + pivot.rotated(Vector3.UP, t / 8.0 * 2.0 * PI)
			result[VectorEdge.new(p, q)] = true
			result[VectorEdge.new(q, p)] = true
			p = q
		return result
		
	return {}
	
static func fully_connect(body: Node3D, node: Vector3, graph: Dictionary):
	var visited = {}
	for k in graph:
		var p = k.p
		if not visited.get(p, false) and get_intersection(body, node, p) == null:
			visited[p] = true
			graph[VectorEdge.new(node, p)] = true
			graph[VectorEdge.new(p, node)] = true
		p = k.q
		if not visited.get(p, false) and get_intersection(body, node, p) == null:
			visited[p] = true
			graph[VectorEdge.new(node, p)] = true
			graph[VectorEdge.new(p, node)] = true
	
static func get_intersection(p: Node3D, from: Vector3, target: Vector3) -> CollisionShape3D:
	var space_state = p.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from + Vector3(0, 1, 0), target + Vector3(0, 1, 0), ~1, [p])
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return null
	
	var obj: CollisionObject3D = result.get("collider")	
	if obj == null:
		return null
		
	var c: CollisionShape3D = null
	for o in obj.get_children():
		if o.name == "collision":
			c = o
			break
			
	if c == null:
		return null
		
	return c
	
static func build_graph(p: Node3D, current_position: Vector3, target: Vector3) -> Dictionary:
	var obj = get_intersection(p, current_position, target)
	if obj == null:
		return {}
		
	var obstacles = {obj: true}
	var shape: Shape3D = obj.shape
	var candidates = edges(obj, shape)
	fully_connect(p, current_position, candidates)
	var stack = candidates.keys()
	var visited = {}
	
	while not stack.is_empty():
		var candidate_edge = stack.pop_back()
		
		var candidate = candidate_edge.p
		if not visited.get(candidate, false):
			obj = get_intersection(p, candidate, target)
			if obj == null:
				candidates[VectorEdge.new(candidate, target)] = true
			elif not obstacles.get(obj, false):
				var new_candidates = edges(obj, obj.shape)
				stack.append_array(new_candidates)
				fully_connect(p, candidate, new_candidates)
				candidates.merge(new_candidates)
		
		candidate = candidate_edge.q
		if not visited.get(candidate, false):
			obj = get_intersection(p, candidate, target)
			if obj == null:
				candidates[VectorEdge.new(candidate, target)] = true
			elif not obstacles.get(obj, false):
				var new_candidates = edges(obj, obj.shape)
				stack.append_array(new_candidates)
				fully_connect(p, candidate, new_candidates)
				candidates.merge(new_candidates)
		
	return candidates
		
static func dfs(graph: Dictionary, start: Vector3, target: Vector3) -> Array[Vector3]:
	var visited = {}
	var stack: Array[Vector3] = [start]
	while not stack.is_empty():
		var v = stack.pop_back()
		if not visited.get(v, false):
			visited[v] = true
			var temp_stack = []
			for e in graph:
				if e.p == v:
					temp_stack.append(e.q)
					if e.q == target:
						return stack
				if e.q == v:
					temp_stack.append(e.p)
					if e.p == target:
						return stack
			temp_stack.sort_custom(func(a, b): return a.distance_squared_to(target) < b.distance_squared_to(target))
			stack.append_array(temp_stack)
					
	return []
	
static func find_path(p: Node3D, target: Vector3) -> Vector3:
	var start_position = p.global_position
	var graph = build_graph(p, start_position, target)
	var path = dfs(graph, start_position, target)
	if path.is_empty():
		return target
	var next = path[0]
	while not path.is_empty():
		var x = Vector2(p.global_position.x, p.global_position.z)
		var y = Vector2(next.x, next.z)
		if x.distance_squared_to(y) > 2:
			break
		next = path.pop_front()
		
	return next
	
static func next_target(p: Node3D, target: Vector3) -> Vector3:
	var current_position = p.global_position
	var obj = get_intersection(p, current_position, target)
	if obj == null:
		return target
	
	var shape: Shape3D = obj.shape
	var candidates = edges(obj, shape)
	
	
	for candidate in candidates:
		if get_intersection(p, current_position, candidate) != null:
			continue
		
		var obj_n = get_intersection(p, candidate, target)
		if obj_n == null:
			return candidate
	
	return target
	
	
