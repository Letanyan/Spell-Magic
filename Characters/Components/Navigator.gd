class_name Navigator

class VectorEdge:
	var p: Vector3
	var q: Vector3
	
	func _init(a: Vector3, b: Vector3) -> void:
		p = a
		q = b
		
static func vertices(parent: Node3D, shape: Shape3D) -> PackedVector3Array:
	if shape is CylinderShape3D:
		var bottom := parent.global_position
		var radius: float = (shape as CylinderShape3D).radius * 2
		var result: PackedVector3Array = []
		var pivot := Vector3(radius, 0, 0)
		var p := bottom + pivot
		result.append(p)
		for t in range(8):
			p = bottom + pivot.rotated(Vector3.UP, t / 8.0 * 2.0 * PI)
			result.append(p)
		return result
	elif shape is BoxShape3D:
		var box := shape as BoxShape3D
		var bottom := parent.global_position
		var radius: float = max(box.size.x, max(box.size.y, box.size.z))
		var result: PackedVector3Array = []
		var pivot := Vector3(radius, 0, 0)
		var p := bottom + pivot
		result.append(p)
		for t in range(8):
			p = bottom + pivot.rotated(Vector3.UP, t / 8.0 * 2.0 * PI)
			result.append(p)
		return result
		
	return []

static func edges(parent: Node3D, shape: Shape3D) -> Dictionary:
	if shape is CylinderShape3D:
		var bottom := parent.global_position
		var radius: float = (shape as CylinderShape3D).radius * 2
		var result := {}
		var pivot := Vector3(radius, 0, 0)
		var p := bottom + pivot
		for t in range(8):
			var q := bottom + pivot.rotated(Vector3.UP, t / 8.0 * 2.0 * PI)
			result[VectorEdge.new(p, q)] = true
			result[VectorEdge.new(q, p)] = true
			p = q
		return result
	elif shape is BoxShape3D:
		var box := shape as BoxShape3D
		var bottom := parent.global_position
		var radius: float = max(box.size.x, max(box.size.y, box.size.z))
		var result := {}
		var pivot := Vector3(radius, 0, 0)
		var p := bottom + pivot
		for t in range(8):
			var q := bottom + pivot.rotated(Vector3.UP, t / 8.0 * 2.0 * PI)
			result[VectorEdge.new(p, q)] = true
			result[VectorEdge.new(q, p)] = true
			p = q
		return result
		
	return {}
	
static func fully_connect(body: Node3D, node: Vector3, graph: Dictionary) -> void:
	var visited := {}
	for k: VectorEdge in graph:
		var p: Vector3 = k.p
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
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsPointQueryParameters3D.new()
	query.position = target
	query.collision_mask = ~1
	query.exclude = [p]
	var result := space_state.intersect_point(query)
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

static func get_collisions_from_shape(p: Node3D, shape: Shape3D, transform: Transform3D, mask: int, exclude: Array = []) -> PackedVector3Array:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = mask
	query.shape = shape
	query.transform = transform
	query.exclude = [p] + exclude
	return space_state.collide_shape(query)
	
static func get_intersections_from_shape(p: Node3D, shape: Shape3D, transform: Transform3D, mask: int = ~1, exclude: Array = []) -> Array[Dictionary]:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = mask
	query.shape = shape
	query.transform = transform
	query.exclude = [p] + exclude
	return space_state.intersect_shape(query, 32)
	
static func rotation_vector(from: Vector3, to: Vector3) -> Quaternion:
	"""
	find Quaternion `q` such `v1` rotated by `q` will give `v2`.
	assuming `v1` and `v2` are not parallel.
	
	Quaternion q;
	vector a = crossproduct(v1, v2);
	q.xyz = a;
	q.w = sqrt((v1.Length ^ 2) * (v2.Length ^ 2)) + dotproduct(v1, v2);
	q = normalize(q)
	
	if `v1` is parallel to `v2` `dot(v1,v2) = 1` return Identity quaternion. 
	If `v1` is opposite to `v2` dot(v1,v2) = -1` return `q = <1, 0, 0, PI>` 
	"""
	var q := Quaternion.IDENTITY
	var a := from.cross(to)
	q.x = a.x
	q.y = a.y
	q.z = a.z
	q.w = sqrt(from.length_squared() * to.length_squared()) + from.dot(to)
	q = q.normalized()
	return q

static func get_ray_collision(p: Node3D, from: Vector3, direction: Vector3, mask: int) -> Vector3:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + direction, mask, [p])
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return Vector3.ZERO
	return result.get("position")
	
static func get_ray_intersection(p: Node3D, from: Vector3, target: Vector3) -> CollisionShape3D:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from + Vector3(0, 1, 0), target + Vector3(0, 1, 0), ~1, [p])
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var obj: CollisionObject3D = result.get("collider")	
	if obj == null:
		return null
	var c: CollisionShape3D = null
	for o in obj.get_children():
		if o.name == "shape" or o.name == "Collision":
			c = o
			break
	return c
	
static func get_shape_intersection(p: Node3D, from: Vector3, target: Vector3, shape: Shape3D, transform: Transform3D) -> bool:
	var space_state := p.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.collision_mask = ~1
	query.exclude = [p]
	query.shape = shape
	query.transform = transform
	var result := space_state.intersect_shape(query, 4)
	return not result.is_empty()
	

static func get_world_height_from_node(p: Node3D, x: float, z: float, no_hit := Ptr.new(false)) -> float:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), 1)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		no_hit.data = true
		return 0
	else:
		no_hit.data = false
		return result.get("position", Vector3.ZERO).y
	
static func get_world_height(space_state: PhysicsDirectSpaceState3D, x: float, z: float, no_hit := Ptr.new(false)) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), 1)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		no_hit.data = true
		return 0
	else:
		no_hit.data = false
		return result.get("position", Vector3.ZERO).y
		
static func get_world_normal_height(space_state: PhysicsDirectSpaceState3D, x: float, z: float, no_hit := Ptr.new(false)) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), 1)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		no_hit.data = true
		return {}
	else:
		no_hit.data = false
		return result
	
static func build_graph(p: Node3D, current_position: Vector3, target: Vector3) -> Dictionary:
	var obj := get_ray_intersection(p, current_position, target)
	if obj == null:
		return {}
		
	var obstacles := {obj: true}
	var shape: Shape3D = obj.shape
	var candidates := edges(obj, shape)
	fully_connect(p, current_position, candidates)
	var stack := candidates.keys()
	var visited := {}
	
	while not stack.is_empty():
		var candidate_edge: VectorEdge = stack.pop_back()
		
		var candidate := candidate_edge.p
		if not visited.get(candidate, false):
			obj = get_ray_intersection(p, candidate, target)
			if obj == null:
				candidates[VectorEdge.new(candidate, target)] = true
			elif not obstacles.get(obj, false):
				var new_candidates := edges(obj, obj.shape)
				stack.append_array(new_candidates.keys())
				fully_connect(p, candidate, new_candidates)
				candidates.merge(new_candidates)
		
		candidate = candidate_edge.q
		if not visited.get(candidate, false):
			obj = get_ray_intersection(p, candidate, target)
			if obj == null:
				candidates[VectorEdge.new(candidate, target)] = true
			elif not obstacles.get(obj, false):
				var new_candidates := edges(obj, obj.shape)
				stack.append_array(new_candidates.keys())
				fully_connect(p, candidate, new_candidates)
				candidates.merge(new_candidates)
		
	return candidates
		
static func dfs(graph: Dictionary, start: Vector3, target: Vector3) -> Array[Vector3]:
	var visited := {}
	var stack: Array[Vector3] = [start]
	while not stack.is_empty():
		var v: Vector3 = stack.pop_back()
		if not visited.get(v, false):
			visited[v] = true
			var temp_stack := []
			for e: VectorEdge in graph:
				if e.p == v:
					temp_stack.append(e.q)
					if e.q == target:
						return stack
				if e.q == v:
					temp_stack.append(e.p)
					if e.p == target:
						return stack
			temp_stack.sort_custom(func(a: Vector3, b: Vector3) -> float: return a.distance_squared_to(target) < b.distance_squared_to(target))
			stack.append_array(temp_stack)
					
	return []
	
static func find_path(p: Node3D, target: Vector3) -> Vector3:
	var start_position := p.global_position
	var graph := build_graph(p, start_position, target)
	var path := dfs(graph, start_position, target)
	if path.is_empty():
		return target
	var next := path[0]
	while not path.is_empty():
		var x := Vector2(p.global_position.x, p.global_position.z)
		var y := Vector2(next.x, next.z)
		if x.distance_squared_to(y) > 2:
			break
		next = path.pop_front()
		
	return next
	
static func minimum_score(nodes: Dictionary, scores: Dictionary) -> Vector3:
	var result := Vector3.ZERO
	var best := INF
	for v: Vector3 in nodes:
		if scores.get(v, INF) < best:
			best = scores[v]
			result = v
	return result
	
static func reconstruct_path(came_from: Dictionary, target: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = [target]
	var current := target
	while came_from.has(current):
		current = came_from[current]
		result.insert(0, current)
	return result
	
static func neighbours(p: Node3D, from: Vector3, directions: int, distance: float, target: Vector3, margin: float = 0.0) -> Array[Vector3]:
	var result: Array[Vector3] = [from + Vector3(0, distance, 0), from + Vector3(0, -distance, 0)]
	var direction := (target - from)
	direction.y = 0.0
	direction = direction.normalized()
	var angle := 2 * PI / float(directions)
	var shape := SphereShape3D.new()
	shape.radius = margin
	var transform := Transform3D.IDENTITY
	for a in range(directions):
		for it in range(1, 3):
			var to := from + direction * distance * it
			to.y = get_world_height_from_node(p, to.x, to.z)
			if not get_shape_intersection(p, from, to, shape, transform.translated(to)):
				result.append(to)
				break
		direction = direction.rotated(Vector3.UP, angle)
			
	return result
	
static func astar(p: Node3D, target: Vector3, margin_from_target: float = 1.0, max_step_distance: float = 2.0, margin_from_obs: float = 0.0) -> Array[Vector3]:	
	var start := p.global_position
	var open := {start: true}
	var came_from := {}
	var g_score := {}
	g_score[start] = 0.0
	var f_score := {}
	f_score[start] = start.distance_to(target)
	var distance := max_step_distance
	var max_look_up := 200.0 / distance
	
	var best_distance := INF
	var closest_point := start
	while open.size() > 0:
		var current := minimum_score(open, f_score)
		
		var current_distance := current.distance_to(target)
		if current_distance < best_distance:
			best_distance = current_distance
			closest_point = current
		if current_distance <= margin_from_target:
			return reconstruct_path(came_from, current)
			
		distance = min(current_distance / 2.0, max_step_distance)
			
		open.erase(current)
		for n in neighbours(p, current, 8, distance, target, margin_from_obs):
			var tentative: float = g_score[current] + distance
			if tentative < g_score.get(n, INF):
				came_from[n] = current
				g_score[n] = tentative
				f_score[n] = tentative + n.distance_to(target)
				if not open.has(n):
					open[n] = true
					
		max_look_up -= 1
		if max_look_up <= 0:
			# Maybe use `closest_point` instead? But that could lead to the agent
			# getting stuck in a local minima. Using the current path adds some 
			# non-determinism to help the agent find other paths?
			# return reconstruct_path(came_from, current)
			
			return reconstruct_path(came_from, closest_point)
				
	return [target]
	
static func will_collide(p: Node3D, target: Vector3) -> bool:
	return get_ray_intersection(p, p.global_position, target) != null
	
static func find_target(p: Node3D, target: Vector3, margin_from_target: float = 2.0, step_distance: float = 2.0, margin_from_obs: float = 3.0) -> Vector3:
	if p.global_position.distance_to(target) > 200.0 / step_distance:
		return target
	if not will_collide(p, target):
		return target
	var target_in_shape := get_point_intersection(p, target)
	if target_in_shape != null:
		var candidates := vertices(target_in_shape, target_in_shape.shape)
		if candidates.size() <= 0:
			return target
		var result: Vector3 = candidates[0]
		var max_res := INF
		for c in candidates:
			if c.distance_to(target) < max_res:
				max_res = c.distance_to(target)
				result = c
		target = result
				
	var path := astar(p, target, margin_from_target, step_distance, margin_from_obs)
	if path.is_empty():
		return target
	var next: Vector3 = path[0]
	while not path.is_empty():
		var x := Vector2(p.global_position.x, p.global_position.z)
		var y := Vector2(next.x, next.z)
		if x.distance_squared_to(y) > 2:
			break
		next = path.pop_front()
		
	for pos in path:
		DebugDraw3D.draw_sphere(pos, 0.5, Color(1, 0, 0), 0.5)
		
	return next 
	
