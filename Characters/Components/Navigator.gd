class_name Navigator

class VectorEdge:
	var p: Vector3
	var q: Vector3
	
	func _init(a: Vector3, b: Vector3):
		p = a
		q = b
		
static func vertices(parent: Node3D, shape: Shape3D) -> Array:
	if shape is CylinderShape3D:
		var bottom = parent.global_position
		var radius = shape.radius * 2
		var result = []
		var pivot = Vector3(radius, 0, 0)
		var p = bottom + pivot
		result.append(p)
		for t in range(8):
			p = bottom + pivot.rotated(Vector3.UP, t / 8.0 * 2.0 * PI)
			result.append(p)
		return result
	elif shape is BoxShape3D:
		var bottom = parent.global_position
		var radius = max(shape.size.x, max(shape.size.y, shape.size.z))
		var result = []
		var pivot = Vector3(radius, 0, 0)
		var p = bottom + pivot
		result.append(p)
		for t in range(8):
			p = bottom + pivot.rotated(Vector3.UP, t / 8.0 * 2.0 * PI)
			result.append(p)
		return result
		
	return []

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
	elif shape is BoxShape3D:
		var bottom = parent.global_position
		var radius = max(shape.size.x, max(shape.size.y, shape.size.z))
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
		if not visited.get(p, false) and get_ray_intersection(body, node, p) == null:
			visited[p] = true
			graph[VectorEdge.new(node, p)] = true
			graph[VectorEdge.new(p, node)] = true
		p = k.q
		if not visited.get(p, false) and get_ray_intersection(body, node, p) == null:
			visited[p] = true
			graph[VectorEdge.new(node, p)] = true
			graph[VectorEdge.new(p, node)] = true

static func get_point_intersection(p: Node3D, target: Vector3) -> CollisionShape3D:
	var space_state = p.get_world_3d().direct_space_state
	var query = PhysicsPointQueryParameters3D.new()
	query.position = target
	query.collision_mask = ~1
	query.exclude = [p]
	var result = space_state.intersect_point(query)
	if result.is_empty():
		return null
	if result[0].is_empty():
		return null
	var obj: CollisionObject3D = result[0].get("collider")	
	if obj == null:
		return null
	var c: CollisionShape3D = null
	for o in obj.get_children():
		if o.name == "shape":
			c = o
			break
	return c

static func get_ray_collision(p: Node3D, from: Vector3, direction: Vector3, mask: int) -> Vector3:
	var space_state = p.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + direction, mask, [p])
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return Vector3.ZERO
	return result.get("position")
	
static func get_ray_intersection(p: Node3D, from: Vector3, target: Vector3) -> CollisionShape3D:
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
		if o.name == "shape":
			c = o
			break
	return c
	
static func get_world_height(space_state: PhysicsDirectSpaceState3D, x: float, z: float) -> float:
	var query = PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), 1)
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return 0
	else:
		return result.get("position", Vector3.ZERO).y
	
static func build_graph(p: Node3D, current_position: Vector3, target: Vector3) -> Dictionary:
	var obj = get_ray_intersection(p, current_position, target)
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
			obj = get_ray_intersection(p, candidate, target)
			if obj == null:
				candidates[VectorEdge.new(candidate, target)] = true
			elif not obstacles.get(obj, false):
				var new_candidates = edges(obj, obj.shape)
				stack.append_array(new_candidates.keys())
				fully_connect(p, candidate, new_candidates)
				candidates.merge(new_candidates)
		
		candidate = candidate_edge.q
		if not visited.get(candidate, false):
			obj = get_ray_intersection(p, candidate, target)
			if obj == null:
				candidates[VectorEdge.new(candidate, target)] = true
			elif not obstacles.get(obj, false):
				var new_candidates = edges(obj, obj.shape)
				stack.append_array(new_candidates.keys())
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
	
static func minimum_score(nodes: Dictionary, scores: Dictionary) -> Vector3:
	var result = Vector3.ZERO
	var best = INF
	for v in nodes:
		if scores.get(v, INF) < best:
			best = scores[v]
			result = v
	return result
	
static func reconstruct_path(came_from: Dictionary, target: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = [target]
	var current = target
	while came_from.has(current):
		current = came_from[current]
		result.insert(0, current)
	return result
	
static func neighbours(p: Node3D, from: Vector3, directions: int, distance: float) -> Array[Vector3]:
	var result: Array[Vector3] = [from + Vector3(0, distance, 0), from + Vector3(0, -distance, 0)]
	var direction = Vector3(1, 0, 0)
	var angle = 2 * PI / float(directions)
	for y in range(-1, 2):
		for a in range(directions):
			var to = from + direction * distance + Vector3(0, y, 0) * distance
			if get_ray_intersection(p, from, to) == null:
				result.append(to)
			direction = direction.rotated(Vector3.UP, angle)
	return result
	
static func astar(p: Node3D, target: Vector3, margin: float = 2.0, distance: float = 2.0) -> Array[Vector3]:	
	var start = p.global_position
	var open = {start: true}
	var came_from = {}
	var g_score = {}
	g_score[start] = 0.0
	var f_score = {}
	f_score[start] = start.distance_to(target)
	var max_look_up = 200.0 / distance
	
	while open.size() > 0:
		var current = minimum_score(open, f_score)
		
		if current.distance_to(target) <= margin:
			return reconstruct_path(came_from, current)
			
		open.erase(current)
		for n in neighbours(p, current, 8, distance):
			var tentative = g_score[current] + distance
			if tentative < g_score.get(n, INF):
				came_from[n] = current
				g_score[n] = tentative
				f_score[n] = tentative + n.distance_to(target)
				if not open.has(n):
					open[n] = true
					
		max_look_up -= 1
		if max_look_up <= 0:
			return [target]
				
	return [target]
	
static func will_collide(p: Node3D, target: Vector3) -> bool:
	return get_ray_intersection(p, p.global_position, target) != null
	
static func find_target(p: Node3D, target: Vector3, margin: float = 4.0, distance: float = 2.0) -> Vector3:
	if p.global_position.distance_to(target) > 200.0 / distance:
		return target
	if not will_collide(p, target):
		return target
	var target_in_shape = get_point_intersection(p, target)
	if target_in_shape != null:
		var candidates = vertices(target_in_shape, target_in_shape.shape)
		if candidates.size() <= 0:
			return target
		var result = candidates[0]
		var max_res = INF
		for c in candidates:
			if c.distance_to(target) < max_res:
				max_res = c.distance_to(target)
				result = c
		target = result
				
	var path = astar(p, target, margin, distance)
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
	var obj = get_ray_intersection(p, current_position, target)
	if obj == null:
		return target
	
	var shape: Shape3D = obj.shape
	var candidates = edges(obj, shape)
	
	
	for candidate in candidates:
		if get_ray_intersection(p, current_position, candidate) != null:
			continue
		
		var obj_n = get_ray_intersection(p, candidate, target)
		if obj_n == null:
			return candidate
	
	return target
	
	
