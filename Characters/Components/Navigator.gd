class_name Navigator
	
static func shape_max_bound(shape: Shape3D) -> float:
	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		return max(box.size.x, box.size.y, box.size.z)
	elif shape is SphereShape3D:
		return (shape as SphereShape3D).radius * 2.0
	elif shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		return max(capsule.radius * 2.0, capsule.height)
	return 1.0
	
static func shape_bounds(shape: Shape3D) -> Vector3:
	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		return box.size
	elif shape is SphereShape3D:
		var r := (shape as SphereShape3D).radius * 2.0
		return Vector3(r, r, r)
	elif shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		return Vector3(capsule.radius * 2.0, capsule.height, capsule.radius * 2.0)
	elif shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		return Vector3(cylinder.radius * 2.0, cylinder.height, cylinder.radius * 2.0)
	return Vector3(1, 1, 1)
	
static func shape_height(shape: Shape3D) -> float:
	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		return box.size.y
	elif shape is SphereShape3D:
		return (shape as SphereShape3D).radius * 2.0
	elif shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		return capsule.height
	return 1.0
	
static func shape_increase(shape: Shape3D, amount: float) -> Shape3D:
	var result := shape.duplicate()
	if result is BoxShape3D:
		var box := result as BoxShape3D
		box.size += Vector3(amount, amount, amount)
		return box
	elif result is SphereShape3D:
		var sphere := result as SphereShape3D
		sphere.radius += amount
		return sphere
	elif result is CapsuleShape3D:
		var capsule := result as CapsuleShape3D
		capsule.height += amount
		capsule.radius += amount
		return capsule
	return shape

static func get_point_intersection(p: CollisionObject3D, target: Vector3) -> CollisionShape3D:
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

static func get_collisions_from_shape(p: CollisionObject3D, shape: Shape3D, transform: Transform3D, mask: int, exclude: Array[RID] = []) -> PackedVector3Array:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = mask
	query.shape = shape
	query.transform = transform
	query.exclude = [p.get_rid()] + exclude
	return space_state.collide_shape(query)
	
static func get_intersections_from_shape(p: CollisionObject3D, shape: Shape3D, transform: Transform3D, mask: int = ~1, exclude: Array[RID] = []) -> Array[Dictionary]:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = mask
	query.shape = shape
	query.transform = transform
	query.exclude = [p.get_rid()] + exclude
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

static func get_ray_collision(p: CollisionObject3D, from: Vector3, direction: Vector3, mask: int) -> Vector3:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + direction, mask, [p.get_rid()])
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return Vector3.ZERO
	return result.get("position")
	
static func get_ray_intersection(p: CollisionObject3D, from: Vector3, target: Vector3) -> CollisionShape3D:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from + Vector3(0, 1, 0), target + Vector3(0, 1, 0), ~1, [p.get_rid()])
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
	
static func get_ray_intersection_from_spell_body(p: SpellBody, from: Vector3, target: Vector3) -> CollisionShape3D:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from + Vector3(0, 1, 0), target + Vector3(0, 1, 0), ~1, [])
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
	
static func get_shape_intersection(p: CollisionObject3D, from: Vector3, target: Vector3, shape: Shape3D, exclude_ground: bool) -> bool:
	var space_state := p.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.collision_mask = ~(1 if exclude_ground else 0)
	query.exclude = [p.get_rid()]
	query.shape = shape
	query.transform = Transform3D.IDENTITY.translated(target)
	var result := space_state.intersect_shape(query, 4)
	return not result.is_empty()

static func get_shape_distance_away(p: CollisionObject3D, from: Vector3, target: Vector3, shape: Shape3D, exclude_ground: bool) -> PackedFloat32Array:
	var space_state := p.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.collision_mask = ~(1 if exclude_ground else 0)
	query.exclude = [p.get_rid()]
	query.shape = shape
	query.transform = Transform3D.IDENTITY.translated(from)
	query.motion = target - from
	var result := space_state.cast_motion(query)
	return result
	
static func get_shape_collides(p: CollisionObject3D, from: Vector3, target: Vector3, shape: Shape3D, exclude_ground: bool) -> bool:
	var result := get_shape_distance_away(p, from, target, shape, exclude_ground)
	return not (result[0] == 1.0 and result[1] == 1.0)

static func get_world_height_from_node(p: CollisionObject3D, x: float, z: float, no_hit := Globals.Ref.new(false)) -> float:
	var space_state := p.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), 1)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		no_hit.data = true
		return 0
	else:
		no_hit.data = false
		return result.get("position", Vector3.ZERO).y
	
static func get_world_height(space_state: PhysicsDirectSpaceState3D, x: float, z: float, no_hit := Globals.Ref.new(false)) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), Globals.Layer.WORLD)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		no_hit.data = true
		return 0
	else:
		no_hit.data = false
		return result.get("position", Vector3.ZERO).y
		
static func get_platform_height(space_state: PhysicsDirectSpaceState3D, x: float, z: float, no_hit := Globals.Ref.new(false)) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), Globals.Layer.WORLD & Globals.Layer.OBJECT)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		no_hit.data = true
		return 0
	else:
		no_hit.data = false
		return result.get("position", Vector3.ZERO).y
		
static func get_world_normal_height(space_state: PhysicsDirectSpaceState3D, x: float, z: float, no_hit := Globals.Ref.new(false)) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 5000, z), Vector3(x, -5000, z), 1)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		no_hit.data = true
		return {}
	else:
		no_hit.data = false
		return result
	
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
	
# options is MovementOption set
static func neighbours(p: CollisionObject3D, from: Vector3, directions: int, distance: float, target: Vector3, shape: Shape3D, options: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var direction := (target - from)
	direction.y = 0.0
	direction = direction.normalized()
	var angle := 2 * PI / float(directions)
	for a in range(directions):
		var to := from + direction * distance
		if options & MovementOptions.CAN_FLY == 0:
			to.y = get_world_height_from_node(p, to.x, to.z) + shape_height(shape) / 2.0 + 0.05
		to = to.snapped(Vector3(distance, distance, distance))
		var distance_away := get_shape_distance_away(p, from, to, shape, (options & MovementOptions.UNDERGROUND) != 0)
		if distance_away[0] == 1.0 and distance_away[1] == 1.0:
			result.append(to)
		elif distance_away[0] >= 0.1 and not get_shape_collides(p, from, to, shape, (options & MovementOptions.UNDERGROUND) != 0):
			result.append(from.lerp(to, distance_away[0]))
		direction = direction.rotated(Vector3.UP, angle)
		
	var final_result: Array[Vector3] = []
	if options & MovementOptions.CAN_FLY != 0:
		for r in result:
			final_result.append(r + Vector3(0, distance, 0))
	if options & MovementOptions.UNDERGROUND != 0:
		for r in result:
			final_result.append(r + Vector3(0, -distance, 0))
	for r in result:
		final_result.append(r)	
			
	return final_result
	
const debug = false
enum MovementOptions { CAN_FLY = 1 << 0, UNDERGROUND = 1 << 1 }
# options is MovementOption set
static func astar(p: CollisionObject3D, target: Vector3, shape: Shape3D, options: int, margin_from_target: float = 1.0, margin_from_obs: float = 0.0) -> Array[Vector3]:	
	var start := p.global_position
	var open := {start: true}
	var came_from := {}
	var g_score := {}
	g_score[start] = 0.0
	var f_score := {}
	f_score[start] = start.distance_to(target)
	var distance := shape_max_bound(shape)
	var max_look_up := 1200.0 / distance
	
	var best_distance := INF
	var closest_point := start
	while open.size() > 0:
		var current := minimum_score(open, f_score)
		
		var current_distance := current.distance_to(target)
		if current_distance < best_distance:
			best_distance = current_distance
			closest_point = current
		if current_distance <= distance:
			if debug: print("astar: A")
			return reconstruct_path(came_from, current)
			
		open.erase(current)
		var new_points := neighbours(p, current, 8, distance, target, shape, options)
		for n in new_points:
			var tentative: float = g_score[current] + distance
			if tentative < g_score.get(n, INF):
				if debug:
					DebugDraw3D.draw_sphere(n, shape_max_bound(shape) / 2.0, Color(0, 1, 0), 0.5)
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
			if debug: print("astar: B")
			#print(open)
			return reconstruct_path(came_from, closest_point)
				
	if debug: print("astar: C")
	return [target]
	
static func will_collide(p: CollisionObject3D, shape: Shape3D, target: Vector3, exclude_ground: bool) -> bool:
	if debug: print("will_collide: ", target, exclude_ground)
	return get_shape_collides(p, p.global_position, target, shape, exclude_ground)
	
# options is MovementOption set
static func find_target_path(p: CollisionObject3D, target: Vector3, shape: Shape3D, options: int, margin_from_target: float = 2.0, margin_from_obs: float = 0.5) -> Array[Vector3]:
	var new_shape := shape_increase(shape, margin_from_obs)
	if p.global_position.distance_to(target) > 100.0:
		if debug: print("find_target_path: A")
		return [target]
	if not will_collide(p, new_shape, target, (options & MovementOptions.UNDERGROUND) != 0):
		if debug: print("find_target_path: B")
		return [target]
				
	var path := astar(p, target, new_shape, options, margin_from_target, margin_from_obs)
	if path.is_empty():
		if debug: print("find_target_path: C")
		return [target]
	
	if debug:
		for pos in path:
			DebugDraw3D.draw_sphere(pos, shape_max_bound(new_shape) / 2.0, Color(1, 0, 0), 0.5)
		
	if debug: print("find_target_path: D")
	return path 
	
static func find_next_target_from_path(path: PackedVector3Array, current: Vector3, p: CollisionObject3D, target: Vector3) -> Vector3:
	if path.is_empty():
		if debug: print("D")		
		return target
	var next: Vector3 = path[0]
	while not path.is_empty() and next.is_equal_approx(current):
		#var x := Vector2(p.global_position.x, p.global_position.z)
		#var y := Vector2(next.x, next.z)
		#if x.distance_squared_to(y) > 2:
			#break
		next = path[0]
		path.remove_at(0)
	return next
	
static func path_distance(path: PackedVector3Array) -> float:
	var result := 0.0
	var i := 0
	while i < path.size() - 1:
		result += path[i].distance_to(path[i + 1])
		i += 1
	return result
	
# options is MovementOption set
static func find_target(current: Vector3, p: CollisionObject3D, target: Vector3, shape: Shape3D, options: MovementOptions, margin_from_target: float = 2.0, margin_from_obs: float = 3.0) -> Vector3:
	var path := find_target_path(p, target, shape, options, margin_from_target, margin_from_obs)
	return find_next_target_from_path(path, current, p, target)
