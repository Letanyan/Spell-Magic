class_name PathStyle

enum CoordY { 
	GROUND, ## movement is fixed to ground 
	GROUND_AIR_AND_DIRT, ## movement is allowed above and below ground
	GROUND_AND_AIR, ## movement is allowed on ground or above ground
	GROUND_AND_DIRT, ## movement is allowed on ground or below ground
	AIR, ## movement is allowed above ground (flying)
	ORIGIN, ## movement is allowed above and below ground. y aligned to origin.
}
enum Mover { PHYSICS, ABSOLUTE }
enum LookAt { VELOCITY, PLAYER, PLAYER_XZ, NOTHING }
enum OriginKind { ABSOLUTE, PLAYER, ME, VISION }
enum PlayerVisionAngle { CAMERA, BODY_ROTATION, LINE_OF_SIGHT }

enum InitialPositionCanUpdate {
	ON_GROUND = 1 << 0,
	UNDERGROUND = 1 << 1,
	IN_AIR = 1 << 2,
	AT_INTERCHANGE = 1 << 3,
	WHEN_LOOP = 1 << 4,
	
	ON_GROUND_AND_UNDER = 0b011,
	ON_GROUND_AND_AIR = 0b101,
	UNDERGROUND_AND_AIR = 0b110,
	ALWAYS = 0b1111,
	AT_START = 0b0
}

var origin := Vector3.ZERO
var path: Pathway = null
var origin_kind: OriginKind
var rng: RandomNumberGenerator
var mover: Mover = Mover.ABSOLUTE
var coord_y: CoordY = CoordY.GROUND
var lookat: LookAt = LookAt.VELOCITY
var stored_loops: int = 0
var loop_count_start: int = 0
var last_path_segment_index: int = 0
var time: float = NAN
var old_position: Vector4 = Vector4.ZERO
var old_origin: Vector3 = Vector3.ZERO
var is_on_path: bool = false
var is_on_path_position: bool = false

var when_initial_position_can_update: int = InitialPositionCanUpdate.ALWAYS
var can_update_initial_position_now: bool = true

var me_start_position: Variant = null # used to store entity position (Vec3) at start of movement

var previous_path_index: int = -1 # previous path index used to update `player_start_position`
var player_start_position: Variant = null # used to store entity position (Vec3) at start of movement for each path
var player_start_vision_rotation: Variant = null # used to store entity rotation (float) at start of movement for each path

# (theta, radius, min_margin, max_margin) pair to describe offset from player. +theta is ccw from 
# straight of player view. -theta is cw from player view. radius is distance away
# from player. (min|max)_margin are the radi of disc with center (theta, radius)
var player_vision_offset: Vector4 = Vector4.ZERO
var player_vision_angle: PlayerVisionAngle = PlayerVisionAngle.BODY_ROTATION

func _init(_seed: int = randi(), _origin: Vector3 = Vector3.ZERO) -> void:
	origin = _origin
	rng = RandomNumberGenerator.new()
	rng.seed = _seed
	origin_kind = OriginKind.ABSOLUTE
	path = Pathway.empty_default
	
func reset() -> void:
	time = NAN
	previous_path_index = -1
	player_start_position = null
	player_start_vision_rotation = null
	me_start_position = null
	stored_loops = loop_count_start
		
static var still_path_default := still_path()
static func still_path() -> PathStyle:
	var result := PathStyle.new()
	result.origin_is_me()
	result.align_y_to_origin()
	result.path = Pathway.empty_default
	return result
	
func set_origin(o: Vector3) -> PathStyle: origin = o; return self

func look_at_player() -> PathStyle: lookat = LookAt.PLAYER; return self
func look_at_direction() -> PathStyle: lookat = LookAt.VELOCITY; return self
func look_at_player_xz() -> PathStyle: lookat = LookAt.PLAYER_XZ; return self
func look_at_nothing() -> PathStyle: lookat = LookAt.NOTHING; return self
	
func move_with_physics() -> PathStyle: mover = Mover.PHYSICS; return self
func move_with_absolute() -> PathStyle: mover = Mover.ABSOLUTE; return self
	
func initial_position_can_update_on_ground() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.ON_GROUND; return self
func initial_position_can_update_underground() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.UNDERGROUND; return self
func initial_position_can_update_in_air() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.IN_AIR; return self
func initial_position_can_update_at_interchange() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.AT_INTERCHANGE; return self
func initial_position_can_update_when_loop() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.WHEN_LOOP; return self
func initial_position_can_update_on_ground_and_under() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.ON_GROUND_AND_UNDER; return self
func initial_position_can_update_on_ground_and_air() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.ON_GROUND_AND_AIR; return self
func initial_position_can_update_underground_and_air() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.UNDERGROUND_AND_AIR; return self
func initial_position_can_update_always() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.ALWAYS; return self
func initial_position_can_update_at_start() -> PathStyle: when_initial_position_can_update = InitialPositionCanUpdate.AT_START; return self

func origin_is_absolute(o: Vector3) -> PathStyle: origin_kind = OriginKind.ABSOLUTE; origin = o; return self
func origin_is_player() -> PathStyle: origin_kind = OriginKind.PLAYER; return self
func origin_is_me() -> PathStyle: origin_kind = OriginKind.ME; return self
	
func player_vision_is_body_rotation(a: float, r: float, min_m: float = 0.0, max_m: float = min_m) -> PathStyle:
	player_vision_angle = PlayerVisionAngle.BODY_ROTATION
	player_vision_offset = Vector4(a, r, min_m, max_m)
	origin_kind = OriginKind.VISION
	origin = Vector3.ZERO
	return self
	
func player_vision_is_camera(a: float, r: float, min_m: float = 0.0, max_m: float = min_m) -> PathStyle:
	player_vision_angle = PlayerVisionAngle.CAMERA
	player_vision_offset = Vector4(a, r, min_m, max_m)
	origin_kind = OriginKind.VISION
	origin = Vector3.ZERO
	return self
	
func player_vision_is_line_of_sight(a: float, r: float, min_m: float = 0.0, max_m: float = min_m) -> PathStyle:
	player_vision_angle = PlayerVisionAngle.LINE_OF_SIGHT
	player_vision_offset = Vector4(a, r, min_m, max_m)
	origin_kind = OriginKind.VISION
	origin = Vector3.ZERO
	return self
	
func align_y_to_ground_air_and_dirt() -> PathStyle: coord_y = CoordY.GROUND_AIR_AND_DIRT; return self
func align_y_to_ground() -> PathStyle: coord_y = CoordY.GROUND; return self
func align_y_to_ground_and_air() -> PathStyle: coord_y = CoordY.GROUND_AND_AIR; return self
func align_y_to_ground_and_dirt() -> PathStyle: coord_y = CoordY.GROUND_AND_DIRT; return self
func align_y_to_air() -> PathStyle: coord_y = CoordY.AIR; return self
func align_y_to_origin() -> PathStyle: coord_y = CoordY.ORIGIN; return self
	
func towards_player(speed: float, mn: float, mx: float) -> PathStyle:
	player_vision_angle = PlayerVisionAngle.BODY_ROTATION
	player_vision_offset = Vector4(0.0, 0.0, mn, mx)
	origin_kind = OriginKind.VISION
	origin = Vector3.ZERO
	path = Pathway.empty(speed)
	return self
	
func follow_path(pathway: Pathway) -> PathStyle:
	path = pathway
	return self
	
func transform_path(transform: Variant) -> PathStyle:
	if transform is Transform3D:
		path.apply_transform(transform as Transform3D)
	elif transform is Array[Transform3D]:
		for t: Transform3D in (transform as Array):
			path.apply_transform(t)
	else:
		push_error("Expected Transform3D/Array[Transform3D] for transform")
	return self
	
# me: xyz = position, w = bounds.y
# return: xyz = position, w = speed
func next_position(delta: float, me: Vector4, player: Variant, is_done: Globals.Ref = null, direct_space_state: PhysicsDirectSpaceState3D = null) -> Vector4:
	if is_nan(time):
		time = 0.0
	else:
		time += delta
	if is_done:
		is_done.data = false
	var me_pos := Vec3.xyz(me)
	if me_start_position == null:
		me_start_position = me_pos
		me_start_position.y -= me.w / 2.0
	if player_start_position == null:
		if player is Player:
			player_start_position = (player as Player).position
			player_start_position.y -= (player as Player).bounds.y / 2.0
		elif player is Vector3:
			player_start_position = player
	if origin_kind == OriginKind.VISION and player_start_vision_rotation == null:
		if player is Player:
			if player_vision_angle == PlayerVisionAngle.CAMERA:
				player_start_vision_rotation = ((player as Player).get_node("CamPivot") as Node3D).rotation.y
			elif player_vision_angle == PlayerVisionAngle.BODY_ROTATION:
				player_start_vision_rotation = ((player as Player).get_node("Pivot") as Node3D).rotation.y
			elif player_vision_angle == PlayerVisionAngle.LINE_OF_SIGHT:
				player_start_vision_rotation = Vec2.xz((player as Player).position).angle_to_point(Vector2(me.x, me.z)) - PI / 2
		else:
			player_start_vision_rotation = 0.0
	var temp_origin := Vector3.ZERO
	if origin_kind == OriginKind.PLAYER or origin_kind == OriginKind.VISION:
		temp_origin = player_start_position as Vector3
	elif origin_kind == OriginKind.ME:
		temp_origin = me_start_position as Vector3
	elif origin_kind == OriginKind.ABSOLUTE:
		temp_origin = origin
	
	var transform := Transform3D.IDENTITY
	if origin_kind == OriginKind.VISION:
		var ang := player_start_vision_rotation as float + player_vision_offset.x
		var off: Vector3 = Vector3(0, 0, -player_vision_offset.y).rotated(Vector3.UP, ang)
		var rel_off := off + Vec3.xz_y(player_start_position as Vector3, 0)
		var dist := me_pos.distance_to(rel_off)
		if dist > player_vision_offset.w + 0.1:
			off = rel_off.lerp(me_pos, player_vision_offset.w / dist) - Vec3.xz_y(player_start_position as Vector3, 0)
		elif dist < player_vision_offset.z + 0.1:
			off = rel_off.lerp(me_pos, player_vision_offset.z / dist) - Vec3.xz_y(player_start_position as Vector3, 0)
		#temp_origin += off
		transform = transform.translated(Vector3(0, 0, -off.length())).rotated(Vector3.UP, ang)
		
		
	var time_was_up := false
	# don't use positions to determine completion as we might get stuck if time near total_duration
	if time >= path.total_duration: # and me_pos.is_equal_approx(Vector3(v.x, y, v.z)):
		if can_update_initial_position_now or (when_initial_position_can_update & InitialPositionCanUpdate.AT_INTERCHANGE != 0):
			me_start_position = null
		time_was_up = true
		time = 0.0
		if is_done:
			is_done.data = true
		stored_loops += 1
	
	var y: float
	var duration := clampf(time, 0, path.total_duration)
	var index := Globals.Ref.new(0)
	var v := path.position_at_time_with_transform(duration, transform, index) + Vec3.xz_y(temp_origin, 0)
	if direct_space_state != null:
		y = next_y_position(me, v.x, v.y, v.z, direct_space_state, temp_origin.y)
	else:
		y = next_y_position(me, v.x, v.y, v.z, (player as Player).get_world_3d().direct_space_state, temp_origin.y)
	if time_was_up and (when_initial_position_can_update & InitialPositionCanUpdate.WHEN_LOOP != 0):
		player_start_vision_rotation = null
		player_start_position = null
	if previous_path_index != index.data or is_zero_approx(time) or (player is Player and player.position != player_start_position) or (player is Vector3 and player != player_start_position):
		if can_update_initial_position_now or (when_initial_position_can_update & InitialPositionCanUpdate.AT_INTERCHANGE != 0):
			player_start_vision_rotation = null
			player_start_position = null
		previous_path_index = index.data
		
	if not is_on_path and delta > 1.0:
		time = clampf(time - delta, 0.0, path.total_duration)
	is_on_path_position = Vec3.xyz(old_position).distance_squared_to(me_pos) < 0.001
	is_on_path = is_on_path_position and old_origin.distance_to(temp_origin) < 0.1
	old_position = Vector4(v.x, y, v.z, path.speed_at_time(time, delta, is_on_path))
	old_origin = temp_origin
	
	if player is Player:
		DebugDraw3D.draw_sphere(Vector3(v.x, y, v.z), 0.2, Color.RED, delta)
		for segment: Segment in path.segments:
			var s := segment.position_at_time_with_transform(0.0, transform) + Vec3.xz_y(temp_origin, 0)
			s.y = next_y_position(me, v.x, v.y, v.z, (player as Player).get_world_3d().direct_space_state, temp_origin.y)
			var e := segment.position_at_time_with_transform(1.0, transform) + Vec3.xz_y(temp_origin, 0)
			e.y = next_y_position(me, v.x, v.y, v.z, (player as Player).get_world_3d().direct_space_state, temp_origin.y)
			DebugDraw3D.draw_sphere(s, 0.1, Color.BLUE, delta)
			DebugDraw3D.draw_sphere(e, 0.1, Color.BLUE, delta)
	return old_position

func next_y_position(me: Vector4, x: float, y: float, z: float, direct_space_state: PhysicsDirectSpaceState3D, origin_offset: float) -> float:
	var me_y := me.w
		
	var result := 0.0
	var actual_y := y
	match coord_y:
		CoordY.GROUND:
			var g := Navigator.get_world_height(direct_space_state, x, z) + me_y / 2.0
			result = g
			actual_y = 0.0
		CoordY.GROUND_AND_DIRT:
			var g := Navigator.get_world_height(direct_space_state, x, z) + me_y / 2.0
			var off := origin_offset - g
			if y + off > 0:
				result = g
				actual_y = 0.0
			else:
				result = g + y + off
		CoordY.GROUND_AND_AIR:
			var g := Navigator.get_world_height(direct_space_state, x, z) + me_y / 2.0
			var off := origin_offset - g
			if y + off < 0:
				result = g
				actual_y = 0.0
			else:
				result = g + y + off
		CoordY.GROUND_AIR_AND_DIRT: 
			var g := Navigator.get_world_height(direct_space_state, x, z) + me_y / 2.0
			var off := origin_offset - g
			result = g + y + off
		CoordY.AIR:
			var g := Navigator.get_world_height(direct_space_state, x, z) + me_y / 2.0
			var off := origin_offset - g
			if y + off <= me_y / 2.0:
				result = g + me_y / 2.0
				actual_y = me_y / 2.0
			else:
				result = g + y + off
		CoordY.ORIGIN:
			result = y + origin_offset

	if actual_y > 0.001:
		can_update_initial_position_now = when_initial_position_can_update & InitialPositionCanUpdate.IN_AIR != 0
	elif actual_y < -0.001:
		can_update_initial_position_now = when_initial_position_can_update & InitialPositionCanUpdate.UNDERGROUND != 0
	else:
		can_update_initial_position_now = when_initial_position_can_update & InitialPositionCanUpdate.ON_GROUND != 0
		
	return result
