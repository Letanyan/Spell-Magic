class_name Foliage

const HIDEY = -1000

const tree_pyramid_mesh = preload("res://Models/Nature/tree_pyramid.mesh") as ArrayMesh
const tree_round_mesh = preload("res://Models/Nature/tree_round.mesh") as ArrayMesh
const tree_christmas_mesh = preload("res://Models/Nature/tree_christmas.mesh") as ArrayMesh
const tree_safari_mesh = preload("res://Models/Nature/tree_safari.mesh") as ArrayMesh
const tree_branched_mesh = preload("res://Models/Nature/tree_branched.mesh") as ArrayMesh
const rock_egg_mesh = preload("res://Models/Nature/rock_egg.mesh") as ArrayMesh
const rock_flattop_mesh = preload("res://Models/Nature/rock_flattop.mesh") as ArrayMesh
const rock_overhang_mesh = preload("res://Models/Nature/rock_overhang.mesh") as ArrayMesh
const rock_squashed_mesh = preload("res://Models/Nature/rock_squashed.mesh") as ArrayMesh
const rock_tall_mesh = preload("res://Models/Nature/rock_tall.mesh") as ArrayMesh
const bush_round_mesh = preload("res://Models/Nature/bush_round.mesh") as ArrayMesh
const bush_sprout_mesh = preload("res://Models/Nature/bush_sprout.mesh") as ArrayMesh
const bush_tall_mesh = preload("res://Models/Nature/bush_tall.mesh") as ArrayMesh
const flowers_sun2_mesh = preload("res://Models/Nature/flowers_sun2.mesh") as ArrayMesh
const flowers_sun3_mesh = preload("res://Models/Nature/flowers_sun3.mesh") as ArrayMesh
const grass_reed_mesh = preload("res://Models/Nature/grass_reed.mesh") as ArrayMesh
const grass_shrub_mesh = preload("res://Models/Nature/grass_shrub.mesh") as ArrayMesh
const mushroom_bulb_mesh = preload("res://Models/Nature/mushroom_bulb.mesh") as ArrayMesh
const mushroom_pointed_mesh = preload("res://Models/Nature/mushroom_pointed.mesh") as ArrayMesh

var tree_pyramid_multimesh: MultiMeshInstance3D
var tree_round_multimesh: MultiMeshInstance3D
var tree_christmas_multimesh: MultiMeshInstance3D
var tree_safari_multimesh: MultiMeshInstance3D
var tree_branched_multimesh: MultiMeshInstance3D
var rock_egg_multimesh: MultiMeshInstance3D
var rock_flattop_multimesh: MultiMeshInstance3D
var rock_overhang_multimesh: MultiMeshInstance3D
var rock_squashed_multimesh: MultiMeshInstance3D
var rock_tall_multimesh: MultiMeshInstance3D
var bush_round_multimesh: MultiMeshInstance3D
var bush_sprout_multimesh: MultiMeshInstance3D
var bush_tall_multimesh: MultiMeshInstance3D
var flowers_sun2_multimesh: MultiMeshInstance3D
var flowers_sun3_multimesh: MultiMeshInstance3D
var grass_reed_multimesh: MultiMeshInstance3D
var grass_shrub_multimesh: MultiMeshInstance3D
var mushroom_bulb_multimesh: MultiMeshInstance3D
var mushroom_pointed_multimesh: MultiMeshInstance3D

var tree_pyramid_static_bodies: EntityManager.EntityBuffer
var tree_round_static_bodies: EntityManager.EntityBuffer
var tree_christmas_static_bodies: EntityManager.EntityBuffer
var tree_safari_static_bodies: EntityManager.EntityBuffer
var tree_branched_static_bodies: EntityManager.EntityBuffer
var rock_egg_static_bodies: EntityManager.EntityBuffer
var rock_flattop_static_bodies: EntityManager.EntityBuffer
var rock_overhang_static_bodies: EntityManager.EntityBuffer
var rock_squashed_static_bodies: EntityManager.EntityBuffer
var rock_tall_static_bodies: EntityManager.EntityBuffer
var bush_round_static_bodies: EntityManager.EntityBuffer
var bush_sprout_static_bodies: EntityManager.EntityBuffer
var bush_tall_static_bodies: EntityManager.EntityBuffer
var flowers_sun2_static_bodies: EntityManager.EntityBuffer
var flowers_sun3_static_bodies: EntityManager.EntityBuffer
var grass_reed_static_bodies: EntityManager.EntityBuffer
var grass_shrub_static_bodies: EntityManager.EntityBuffer
var mushroom_bulb_static_bodies: EntityManager.EntityBuffer
var mushroom_pointed_static_bodies: EntityManager.EntityBuffer

#var index_map: Dictionary = {} ## [World.Foliage][]int
var slot_markings: Dictionary = {} ## [World.Foliage][]bool
var opened_slots: Dictionary = {} ## [World.Foliage][]int

var static_body_map: Dictionary = {} ## [Vector2i]StaticBody3D

func _init() -> void:
	var tree_pyramid_multi := MultiMesh.new(); tree_pyramid_multi.mesh = tree_pyramid_mesh; tree_pyramid_multimesh = MultiMeshInstance3D.new(); tree_pyramid_multimesh.multimesh = tree_pyramid_multi; tree_pyramid_multi.visible_instance_count = -1;
	var tree_round_multi := MultiMesh.new(); tree_round_multi.mesh = tree_round_mesh; tree_round_multimesh = MultiMeshInstance3D.new(); tree_round_multimesh.multimesh = tree_round_multi; tree_round_multi.visible_instance_count = -1;
	var tree_christmas_multi := MultiMesh.new(); tree_christmas_multi.mesh = tree_christmas_mesh; tree_christmas_multimesh = MultiMeshInstance3D.new(); tree_christmas_multimesh.multimesh = tree_christmas_multi; tree_christmas_multi.visible_instance_count = -1;
	var tree_safari_multi := MultiMesh.new(); tree_safari_multi.mesh = tree_safari_mesh; tree_safari_multimesh = MultiMeshInstance3D.new(); tree_safari_multimesh.multimesh = tree_safari_multi; tree_safari_multi.visible_instance_count = -1;
	var tree_branched_multi := MultiMesh.new(); tree_branched_multi.mesh = tree_branched_mesh; tree_branched_multimesh = MultiMeshInstance3D.new(); tree_branched_multimesh.multimesh = tree_branched_multi; tree_branched_multi.visible_instance_count = -1;
	var rock_egg_multi := MultiMesh.new(); rock_egg_multi.mesh = rock_egg_mesh; rock_egg_multimesh = MultiMeshInstance3D.new(); rock_egg_multimesh.multimesh = rock_egg_multi; rock_egg_multi.visible_instance_count = -1;
	var rock_flattop_multi := MultiMesh.new(); rock_flattop_multi.mesh = rock_flattop_mesh; rock_flattop_multimesh = MultiMeshInstance3D.new(); rock_flattop_multimesh.multimesh = rock_flattop_multi; rock_flattop_multi.visible_instance_count = -1;
	var rock_overhang_multi := MultiMesh.new(); rock_overhang_multi.mesh = rock_overhang_mesh; rock_overhang_multimesh = MultiMeshInstance3D.new(); rock_overhang_multimesh.multimesh = rock_overhang_multi; rock_overhang_multi.visible_instance_count = -1;
	var rock_squashed_multi := MultiMesh.new(); rock_squashed_multi.mesh = rock_squashed_mesh; rock_squashed_multimesh = MultiMeshInstance3D.new(); rock_squashed_multimesh.multimesh = rock_squashed_multi; rock_squashed_multi.visible_instance_count = -1;
	var rock_tall_multi := MultiMesh.new(); rock_tall_multi.mesh = rock_tall_mesh; rock_tall_multimesh = MultiMeshInstance3D.new(); rock_tall_multimesh.multimesh = rock_tall_multi; rock_tall_multi.visible_instance_count = -1;
	var bush_round_multi := MultiMesh.new(); bush_round_multi.mesh = bush_round_mesh; bush_round_multimesh = MultiMeshInstance3D.new(); bush_round_multimesh.multimesh = bush_round_multi; bush_round_multi.visible_instance_count = -1;
	var bush_sprout_multi := MultiMesh.new(); bush_sprout_multi.mesh = bush_sprout_mesh; bush_sprout_multimesh = MultiMeshInstance3D.new(); bush_sprout_multimesh.multimesh = bush_sprout_multi; bush_sprout_multi.visible_instance_count = -1;
	var bush_tall_multi := MultiMesh.new(); bush_tall_multi.mesh = bush_tall_mesh; bush_tall_multimesh = MultiMeshInstance3D.new(); bush_tall_multimesh.multimesh = bush_tall_multi; bush_tall_multi.visible_instance_count = -1;
	var flowers_sun2_multi := MultiMesh.new(); flowers_sun2_multi.mesh = flowers_sun2_mesh; flowers_sun2_multimesh = MultiMeshInstance3D.new(); flowers_sun2_multimesh.multimesh = flowers_sun2_multi; flowers_sun2_multi.visible_instance_count = -1;
	var flowers_sun3_multi := MultiMesh.new(); flowers_sun3_multi.mesh = flowers_sun3_mesh; flowers_sun3_multimesh = MultiMeshInstance3D.new(); flowers_sun3_multimesh.multimesh = flowers_sun3_multi; flowers_sun3_multi.visible_instance_count = -1;
	var grass_reed_multi := MultiMesh.new(); grass_reed_multi.mesh = grass_reed_mesh; grass_reed_multimesh = MultiMeshInstance3D.new(); grass_reed_multimesh.multimesh = grass_reed_multi; grass_reed_multi.visible_instance_count = -1;
	var grass_shrub_multi := MultiMesh.new(); grass_shrub_multi.mesh = grass_shrub_mesh; grass_shrub_multimesh = MultiMeshInstance3D.new(); grass_shrub_multimesh.multimesh = grass_shrub_multi; grass_shrub_multi.visible_instance_count = -1;
	var mushroom_bulb_multi := MultiMesh.new(); mushroom_bulb_multi.mesh = mushroom_bulb_mesh; mushroom_bulb_multimesh = MultiMeshInstance3D.new(); mushroom_bulb_multimesh.multimesh = mushroom_bulb_multi; mushroom_bulb_multi.visible_instance_count = -1;
	var mushroom_pointed_multi := MultiMesh.new(); mushroom_pointed_multi.mesh = mushroom_pointed_mesh; mushroom_pointed_multimesh = MultiMeshInstance3D.new(); mushroom_pointed_multimesh.multimesh = mushroom_pointed_multi; mushroom_pointed_multi.visible_instance_count = -1;
	
	tree_pyramid_multi.use_colors = true; tree_pyramid_multi.use_custom_data = false; tree_pyramid_multi.transform_format = MultiMesh.TRANSFORM_3D; tree_pyramid_multi.instance_count = 1000
	tree_round_multi.use_colors = true; tree_round_multi.use_custom_data = false; tree_round_multi.transform_format = MultiMesh.TRANSFORM_3D; tree_round_multi.instance_count = 1000
	tree_christmas_multi.use_colors = true; tree_christmas_multi.use_custom_data = false; tree_christmas_multi.transform_format = MultiMesh.TRANSFORM_3D; tree_christmas_multi.instance_count = 1000
	tree_safari_multi.use_colors = true; tree_safari_multi.use_custom_data = false; tree_safari_multi.transform_format = MultiMesh.TRANSFORM_3D; tree_safari_multi.instance_count = 1000
	tree_branched_multi.use_colors = true; tree_branched_multi.use_custom_data = false; tree_branched_multi.transform_format = MultiMesh.TRANSFORM_3D; tree_branched_multi.instance_count = 1000
	rock_egg_multi.use_colors = true; rock_egg_multi.use_custom_data = false; rock_egg_multi.transform_format = MultiMesh.TRANSFORM_3D; rock_egg_multi.instance_count = 1000
	rock_flattop_multi.use_colors = true; rock_flattop_multi.use_custom_data = false; rock_flattop_multi.transform_format = MultiMesh.TRANSFORM_3D; rock_flattop_multi.instance_count = 1000
	rock_overhang_multi.use_colors = true; rock_overhang_multi.use_custom_data = false; rock_overhang_multi.transform_format = MultiMesh.TRANSFORM_3D; rock_overhang_multi.instance_count = 1000
	rock_squashed_multi.use_colors = true; rock_squashed_multi.use_custom_data = false; rock_squashed_multi.transform_format = MultiMesh.TRANSFORM_3D; rock_squashed_multi.instance_count = 1000
	rock_tall_multi.use_colors = true; rock_tall_multi.use_custom_data = false; rock_tall_multi.transform_format = MultiMesh.TRANSFORM_3D; rock_tall_multi.instance_count = 1000
	bush_round_multi.use_colors = true; bush_round_multi.use_custom_data = false; bush_round_multi.transform_format = MultiMesh.TRANSFORM_3D; bush_round_multi.instance_count = 1000
	bush_sprout_multi.use_colors = true; bush_sprout_multi.use_custom_data = false; bush_sprout_multi.transform_format = MultiMesh.TRANSFORM_3D; bush_sprout_multi.instance_count = 1000
	bush_tall_multi.use_colors = true; bush_tall_multi.use_custom_data = false; bush_tall_multi.transform_format = MultiMesh.TRANSFORM_3D; bush_tall_multi.instance_count = 1000
	flowers_sun2_multi.use_colors = true; flowers_sun2_multi.use_custom_data = false; flowers_sun2_multi.transform_format = MultiMesh.TRANSFORM_3D; flowers_sun2_multi.instance_count = 1000
	flowers_sun3_multi.use_colors = true; flowers_sun3_multi.use_custom_data = false; flowers_sun3_multi.transform_format = MultiMesh.TRANSFORM_3D; flowers_sun3_multi.instance_count = 1000
	grass_reed_multi.use_colors = true; grass_reed_multi.use_custom_data = false; grass_reed_multi.transform_format = MultiMesh.TRANSFORM_3D; grass_reed_multi.instance_count = 1000
	grass_shrub_multi.use_colors = true; grass_shrub_multi.use_custom_data = false; grass_shrub_multi.transform_format = MultiMesh.TRANSFORM_3D; grass_shrub_multi.instance_count = 1000
	mushroom_bulb_multi.use_colors = true; mushroom_bulb_multi.use_custom_data = false; mushroom_bulb_multi.transform_format = MultiMesh.TRANSFORM_3D; mushroom_bulb_multi.instance_count = 1000
	mushroom_pointed_multi.use_colors = true; mushroom_pointed_multi.use_custom_data = false; mushroom_pointed_multi.transform_format = MultiMesh.TRANSFORM_3D; mushroom_pointed_multi.instance_count = 1000
	
	var tree_pyramid_index_map := PackedByteArray([]); tree_pyramid_index_map.resize(tree_pyramid_multi.instance_count); for i in tree_pyramid_multi.instance_count: tree_pyramid_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); tree_pyramid_index_map.set(i, 0)
	slot_markings[World.Foliage.TREE_PYRAMID] = tree_pyramid_index_map
	var tree_round_index_map := PackedByteArray([]); tree_round_index_map.resize(tree_round_multi.instance_count); for i in tree_round_multi.instance_count: tree_round_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); tree_round_index_map.set(i, 0)
	slot_markings[World.Foliage.TREE_ROUND] = tree_round_index_map
	var tree_christmas_index_map := PackedByteArray([]); tree_christmas_index_map.resize(tree_christmas_multi.instance_count); for i in tree_christmas_multi.instance_count: tree_christmas_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); tree_christmas_index_map.set(i, 0)
	slot_markings[World.Foliage.TREE_CHRISTMAS] = tree_christmas_index_map
	var tree_safari_index_map := PackedByteArray([]); tree_safari_index_map.resize(tree_safari_multi.instance_count); for i in tree_safari_multi.instance_count: tree_safari_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); tree_safari_index_map.set(i, 0)
	slot_markings[World.Foliage.TREE_SAFARI] = tree_safari_index_map
	var tree_branched_index_map := PackedByteArray([]); tree_branched_index_map.resize(tree_branched_multi.instance_count); for i in tree_branched_multi.instance_count: tree_branched_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); tree_branched_index_map.set(i, 0)
	slot_markings[World.Foliage.TREE_BRANCHED] = tree_branched_index_map
	var rock_egg_index_map := PackedByteArray([]); rock_egg_index_map.resize(rock_egg_multi.instance_count); for i in rock_egg_multi.instance_count: rock_egg_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); rock_egg_index_map.set(i, 0)
	slot_markings[World.Foliage.ROCK_EGG] = rock_egg_index_map
	var rock_flattop_index_map := PackedByteArray([]); rock_flattop_index_map.resize(rock_flattop_multi.instance_count); for i in rock_flattop_multi.instance_count: rock_flattop_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); rock_flattop_index_map.set(i, 0)
	slot_markings[World.Foliage.ROCK_FLATTOP] = rock_flattop_index_map
	var rock_overhang_index_map := PackedByteArray([]); rock_overhang_index_map.resize(rock_overhang_multi.instance_count); for i in rock_overhang_multi.instance_count: rock_overhang_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); rock_overhang_index_map.set(i, 0)
	slot_markings[World.Foliage.ROCK_OVERHANG] = rock_overhang_index_map
	var rock_squashed_index_map := PackedByteArray([]); rock_squashed_index_map.resize(rock_squashed_multi.instance_count); for i in rock_squashed_multi.instance_count: rock_squashed_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); rock_squashed_index_map.set(i, 0)
	slot_markings[World.Foliage.ROCK_SQUASHED] = rock_squashed_index_map
	var rock_tall_index_map := PackedByteArray([]); rock_tall_index_map.resize(rock_tall_multi.instance_count); for i in rock_tall_multi.instance_count: rock_tall_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); rock_tall_index_map.set(i, 0)
	slot_markings[World.Foliage.ROCK_TALL] = rock_tall_index_map
	var bush_round_index_map := PackedByteArray([]); bush_round_index_map.resize(bush_round_multi.instance_count); for i in bush_round_multi.instance_count: bush_round_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); bush_round_index_map.set(i, 0)
	slot_markings[World.Foliage.BUSH_ROUND] = bush_round_index_map
	var bush_sprout_index_map := PackedByteArray([]); bush_sprout_index_map.resize(bush_sprout_multi.instance_count); for i in bush_sprout_multi.instance_count: bush_sprout_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); bush_sprout_index_map.set(i, 0)
	slot_markings[World.Foliage.BUSH_SPROUT] = bush_sprout_index_map
	var bush_tall_index_map := PackedByteArray([]); bush_tall_index_map.resize(bush_tall_multi.instance_count); for i in bush_tall_multi.instance_count: bush_tall_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); bush_tall_index_map.set(i, 0)
	slot_markings[World.Foliage.BUSH_TALL] = bush_tall_index_map
	var flowers_sun2_index_map := PackedByteArray([]); flowers_sun2_index_map.resize(flowers_sun2_multi.instance_count); for i in flowers_sun2_multi.instance_count: flowers_sun2_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); flowers_sun2_index_map.set(i, 0)
	slot_markings[World.Foliage.FLOWERS_SUN2] = flowers_sun2_index_map
	var flowers_sun3_index_map := PackedByteArray([]); flowers_sun3_index_map.resize(flowers_sun3_multi.instance_count); for i in flowers_sun3_multi.instance_count: flowers_sun3_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); flowers_sun3_index_map.set(i, 0)
	slot_markings[World.Foliage.FLOWERS_SUN3] = flowers_sun3_index_map
	var grass_reed_index_map := PackedByteArray([]); grass_reed_index_map.resize(grass_reed_multi.instance_count); for i in grass_reed_multi.instance_count: grass_reed_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); grass_reed_index_map.set(i, 0)
	slot_markings[World.Foliage.GRASS_REED] = grass_reed_index_map
	var grass_shrub_index_map := PackedByteArray([]); grass_shrub_index_map.resize(grass_shrub_multi.instance_count); for i in grass_shrub_multi.instance_count: grass_shrub_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); grass_shrub_index_map.set(i, 0)
	slot_markings[World.Foliage.GRASS_SHRUB] = grass_shrub_index_map
	var mushroom_bulb_index_map := PackedByteArray([]); mushroom_bulb_index_map.resize(mushroom_bulb_multi.instance_count); for i in mushroom_bulb_multi.instance_count: mushroom_bulb_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); mushroom_bulb_index_map.set(i, 0)
	slot_markings[World.Foliage.MUSHROOM_BULB] = mushroom_bulb_index_map
	var mushroom_pointed_index_map := PackedByteArray([]); mushroom_pointed_index_map.resize(mushroom_pointed_multi.instance_count); for i in mushroom_pointed_multi.instance_count: mushroom_pointed_multi.set_instance_transform(i, T.I.translated(Vec3.y(HIDEY))); mushroom_pointed_index_map.set(i, 0)
	slot_markings[World.Foliage.MUSHROOM_POINTED] = mushroom_pointed_index_map
	
	for kind: World.Foliage in World.Foliage.values(): opened_slots[kind] = EntityManager.EntityBuffer.new(20, func() -> int: return -1, func(item: int) -> void: pass)
	
	var alloc_static_body := func(shape_template: Shape3D) -> Callable:
		var fn := func() -> StaticBody3D:
			var result := StaticBody3D.new()
			result.collision_layer = Globals.Layer.OBJECT
			var shape := CollisionShape3D.new()
			shape.shape = shape_template
			shape.name = "shape"
			shape.disabled = true
			result.add_child(shape)
			return result
		return fn
	var deinit_static_body := func(body: StaticBody3D) -> void:
		var shape := body.get_node("shape") as CollisionShape3D
		shape.disabled = true
		
	@warning_ignore("unsafe_call_argument")
	tree_pyramid_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.TREE_PYRAMID] as ShapeTemplate).make_shape()), deinit_static_body, "tree_pyramid_static_bodies")
	@warning_ignore("unsafe_call_argument")
	tree_round_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.TREE_ROUND] as ShapeTemplate).make_shape()), deinit_static_body, "tree_round_static_bodies")
	@warning_ignore("unsafe_call_argument")
	tree_christmas_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.TREE_CHRISTMAS] as ShapeTemplate).make_shape()), deinit_static_body, "tree_christmas_static_bodies")
	@warning_ignore("unsafe_call_argument")
	tree_safari_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.TREE_SAFARI] as ShapeTemplate).make_shape()), deinit_static_body, "tree_safari_static_bodies")
	@warning_ignore("unsafe_call_argument")
	tree_branched_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.TREE_BRANCHED] as ShapeTemplate).make_shape()), deinit_static_body, "tree_branched_static_bodies")
	@warning_ignore("unsafe_call_argument")
	rock_egg_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.ROCK_EGG] as ShapeTemplate).make_shape()), deinit_static_body, "rock_egg_static_bodies")
	@warning_ignore("unsafe_call_argument")
	rock_flattop_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.ROCK_FLATTOP] as ShapeTemplate).make_shape()), deinit_static_body, "rock_flattop_static_bodies")
	@warning_ignore("unsafe_call_argument")
	rock_overhang_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.ROCK_OVERHANG] as ShapeTemplate).make_shape()), deinit_static_body, "rock_overhang_static_bodies")
	@warning_ignore("unsafe_call_argument")
	rock_squashed_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.ROCK_SQUASHED] as ShapeTemplate).make_shape()), deinit_static_body, "rock_squashed_static_bodies")
	@warning_ignore("unsafe_call_argument")
	rock_tall_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.ROCK_TALL] as ShapeTemplate).make_shape()), deinit_static_body, "rock_tall_static_bodies")
	@warning_ignore("unsafe_call_argument")
	bush_round_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.BUSH_ROUND] as ShapeTemplate).make_shape()), deinit_static_body, "bush_round_static_bodies")
	@warning_ignore("unsafe_call_argument")
	bush_sprout_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.BUSH_SPROUT] as ShapeTemplate).make_shape()), deinit_static_body, "bush_sprout_static_bodies")
	@warning_ignore("unsafe_call_argument")
	bush_tall_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.BUSH_TALL] as ShapeTemplate).make_shape()), deinit_static_body, "bush_tall_static_bodies")
	@warning_ignore("unsafe_call_argument")
	flowers_sun2_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.FLOWERS_SUN2] as ShapeTemplate).make_shape()), deinit_static_body, "flowers_sun2_static_bodies")
	@warning_ignore("unsafe_call_argument")
	flowers_sun3_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.FLOWERS_SUN3] as ShapeTemplate).make_shape()), deinit_static_body, "flowers_sun3_static_bodies")
	@warning_ignore("unsafe_call_argument")
	grass_reed_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.GRASS_REED] as ShapeTemplate).make_shape()), deinit_static_body, "grass_reed_static_bodies")
	@warning_ignore("unsafe_call_argument")
	grass_shrub_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.GRASS_SHRUB] as ShapeTemplate).make_shape()), deinit_static_body, "grass_shrub_static_bodies")
	@warning_ignore("unsafe_call_argument")
	mushroom_bulb_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.MUSHROOM_BULB] as ShapeTemplate).make_shape()), deinit_static_body, "mushroom_bulb_static_bodies")
	@warning_ignore("unsafe_call_argument")
	mushroom_pointed_static_bodies = EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[World.Foliage.MUSHROOM_POINTED] as ShapeTemplate).make_shape()), deinit_static_body, "mushroom_pointed_static_bodies")
	
func add_all_meshes(node: Node3D) -> void:
	node.add_child(tree_pyramid_multimesh)
	node.add_child(tree_round_multimesh)
	node.add_child(tree_christmas_multimesh)
	node.add_child(tree_safari_multimesh)
	node.add_child(tree_branched_multimesh)
	node.add_child(rock_egg_multimesh)
	node.add_child(rock_flattop_multimesh)
	node.add_child(rock_overhang_multimesh)
	node.add_child(rock_squashed_multimesh)
	node.add_child(rock_tall_multimesh)
	node.add_child(bush_round_multimesh)
	node.add_child(bush_sprout_multimesh)
	node.add_child(bush_tall_multimesh)
	node.add_child(flowers_sun2_multimesh)
	node.add_child(flowers_sun3_multimesh)
	node.add_child(grass_reed_multimesh)
	node.add_child(grass_shrub_multimesh)
	node.add_child(mushroom_bulb_multimesh)
	node.add_child(mushroom_pointed_multimesh)

func make(kind: World.Foliage) -> int:
	var result := -1
	@warning_ignore("unsafe_method_access")
	if opened_slots.has(kind) and not opened_slots[kind].is_empty():
		@warning_ignore("unsafe_method_access")
		var index := opened_slots[kind].pop_back() as int
		slot_markings[kind][index] = 1
		result = index
	else:
		var markings := slot_markings[kind] as PackedByteArray
		for i in markings.size():
			if markings[i] == 0:
				slot_markings[kind][i] = 1
				result = i
				break
	@warning_ignore("unsafe_method_access")
	if opened_slots[kind].is_empty() and result < slot_markings[kind].size() - 1 and slot_markings[kind][result + 1] == 0:
		@warning_ignore("unsafe_method_access")
		opened_slots[kind].append(result + 1)
	return result
		
func remove(kind: World.Foliage, index: int) -> void:
	match kind:
		World.Foliage.TREE_PYRAMID: tree_pyramid_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.TREE_ROUND: tree_round_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.TREE_CHRISTMAS: tree_christmas_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.TREE_SAFARI: tree_safari_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.TREE_BRANCHED: tree_branched_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.ROCK_EGG: rock_egg_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.ROCK_FLATTOP: rock_flattop_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.ROCK_OVERHANG: rock_overhang_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.ROCK_SQUASHED: rock_squashed_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.ROCK_TALL: rock_tall_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.BUSH_ROUND: bush_round_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.BUSH_SPROUT: bush_sprout_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.BUSH_TALL: bush_tall_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.FLOWERS_SUN2: flowers_sun2_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.FLOWERS_SUN3: flowers_sun3_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.GRASS_REED: grass_reed_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.GRASS_SHRUB: grass_shrub_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.MUSHROOM_BULB: mushroom_bulb_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		World.Foliage.MUSHROOM_POINTED: mushroom_pointed_multimesh.multimesh.set_instance_transform(index, T.I.translated(Vec3.y(HIDEY)))
		_: push_error("no such enum for foliage")
	slot_markings[kind][index] = 0
	# FIXME: speed up. use a buffered array like EntityBuffer but with packed storage
	@warning_ignore("unsafe_method_access")
	opened_slots[kind].append(index)
	
	
func setup(kind: World.Foliage, index: int, position: Vector3, rng: RandomNumberGenerator, biome: World.Biome) -> void:
	var s := rng.randf_range(2, 5) * mesh_scales[kind] as float
	if biome == World.Biome.JUNGLE and World.Foliage.TREE_BRANCHED == kind:
		s *= rng.randf_range(5, 10)
		
	var transform := T.I
	
	var result := transform.scaled(Vector3(s, s, s))
	var r := rng.randf_range(0, 2 * PI)
	result = result.rotated(Vector3.UP, r)
	result = result.translated(position)
	
	match kind:
		World.Foliage.TREE_PYRAMID: tree_pyramid_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.TREE_ROUND: tree_round_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.TREE_CHRISTMAS: tree_christmas_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.TREE_SAFARI: tree_safari_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.TREE_BRANCHED: tree_branched_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.ROCK_EGG: rock_egg_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.ROCK_FLATTOP: rock_flattop_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.ROCK_OVERHANG: rock_overhang_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.ROCK_SQUASHED: rock_squashed_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.ROCK_TALL: rock_tall_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.BUSH_ROUND: bush_round_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.BUSH_SPROUT: bush_sprout_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.BUSH_TALL: bush_tall_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.FLOWERS_SUN2: flowers_sun2_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.FLOWERS_SUN3: flowers_sun3_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.GRASS_REED: grass_reed_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.GRASS_SHRUB: grass_shrub_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.MUSHROOM_BULB: mushroom_bulb_multimesh.multimesh.set_instance_transform(index, result)
		World.Foliage.MUSHROOM_POINTED: mushroom_pointed_multimesh.multimesh.set_instance_transform(index, result)
		_: push_error("no such enum for foliage")
		
	#collision_is_active = maxf(transform.x, maxf(transform.y, transform.z)) * s > 1.0
		
func set_albedo_blend(kind: World.Foliage, index: int, color: Color) -> void:
	match kind:
		World.Foliage.TREE_PYRAMID: tree_pyramid_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.TREE_ROUND: tree_round_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.TREE_CHRISTMAS: tree_christmas_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.TREE_SAFARI: tree_safari_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.TREE_BRANCHED: tree_branched_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.ROCK_EGG: rock_egg_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.ROCK_FLATTOP: rock_flattop_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.ROCK_OVERHANG: rock_overhang_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.ROCK_SQUASHED: rock_squashed_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.ROCK_TALL: rock_tall_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.BUSH_ROUND: bush_round_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.BUSH_SPROUT: bush_sprout_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.BUSH_TALL: bush_tall_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.FLOWERS_SUN2: flowers_sun2_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.FLOWERS_SUN3: flowers_sun3_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.GRASS_REED: grass_reed_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.GRASS_SHRUB: grass_shrub_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.MUSHROOM_BULB: mushroom_bulb_multimesh.multimesh.set_instance_color(index, color)
		World.Foliage.MUSHROOM_POINTED: mushroom_pointed_multimesh.multimesh.set_instance_color(index, color)
		_: push_error("no such enum for foliage")
	
func get_transform(kind: World.Foliage, index: int) -> Transform3D:
	match kind:
		World.Foliage.TREE_PYRAMID: return tree_pyramid_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.TREE_ROUND: return tree_round_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.TREE_CHRISTMAS: return tree_christmas_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.TREE_SAFARI: return tree_safari_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.TREE_BRANCHED: return tree_branched_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.ROCK_EGG: return rock_egg_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.ROCK_FLATTOP: return rock_flattop_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.ROCK_OVERHANG: return rock_overhang_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.ROCK_SQUASHED: return rock_squashed_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.ROCK_TALL: return rock_tall_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.BUSH_ROUND: return bush_round_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.BUSH_SPROUT: return bush_sprout_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.BUSH_TALL: return bush_tall_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.FLOWERS_SUN2: return flowers_sun2_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.FLOWERS_SUN3: return flowers_sun3_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.GRASS_REED: return grass_reed_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.GRASS_SHRUB: return grass_shrub_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.MUSHROOM_BULB: return mushroom_bulb_multimesh.multimesh.get_instance_transform(index)
		World.Foliage.MUSHROOM_POINTED: return mushroom_pointed_multimesh.multimesh.get_instance_transform(index)
		_: push_error("no such enum for foliage"); return T.I
		
func make_static_body(g: Vector2i) -> StaticBody3D:
	var body: StaticBody3D
	match g.x as World.Foliage:
		World.Foliage.TREE_PYRAMID: body = tree_pyramid_static_bodies.get_entity() 
		World.Foliage.TREE_ROUND: body = tree_round_static_bodies.get_entity() 
		World.Foliage.TREE_CHRISTMAS: body = tree_christmas_static_bodies.get_entity() 
		World.Foliage.TREE_SAFARI: body = tree_safari_static_bodies.get_entity() 
		World.Foliage.TREE_BRANCHED: body = tree_branched_static_bodies.get_entity() 
		World.Foliage.ROCK_EGG: body = rock_egg_static_bodies.get_entity() 
		World.Foliage.ROCK_FLATTOP: body = rock_flattop_static_bodies.get_entity() 
		World.Foliage.ROCK_OVERHANG: body = rock_overhang_static_bodies.get_entity() 
		World.Foliage.ROCK_SQUASHED: body = rock_squashed_static_bodies.get_entity() 
		World.Foliage.ROCK_TALL: body = rock_tall_static_bodies.get_entity() 
		World.Foliage.BUSH_ROUND: body = bush_round_static_bodies.get_entity() 
		World.Foliage.BUSH_SPROUT: body = bush_sprout_static_bodies.get_entity() 
		World.Foliage.BUSH_TALL: body = bush_tall_static_bodies.get_entity() 
		World.Foliage.FLOWERS_SUN2: body = flowers_sun2_static_bodies.get_entity() 
		World.Foliage.FLOWERS_SUN3: body = flowers_sun3_static_bodies.get_entity() 
		World.Foliage.GRASS_REED: body = grass_reed_static_bodies.get_entity() 
		World.Foliage.GRASS_SHRUB: body = grass_shrub_static_bodies.get_entity() 
		World.Foliage.MUSHROOM_BULB: body = mushroom_bulb_static_bodies.get_entity() 
		World.Foliage.MUSHROOM_POINTED: body = mushroom_pointed_static_bodies.get_entity()
	var base := get_transform(g.x, g.y)
	var off := base_shapes[g.x] as ShapeTemplate
	var shape := body.get_node("shape") as CollisionShape3D
	static_body_map[g] = body
	body.transform = base.scaled_local(Vec3.a(1.0 / mesh_scales[g.x] as float))
	shape.transform = T.I.translated(off.transform.origin) # FIXME: Apply `off` rotation
	return body
		
func free_static_body(g: Vector2i) -> void:
	if not static_body_map.has(g):
		return
	var body := static_body_map[g] as StaticBody3D
	match g.x as World.Foliage:
		World.Foliage.TREE_PYRAMID: tree_pyramid_static_bodies.free_entity(body) 
		World.Foliage.TREE_ROUND: tree_round_static_bodies.free_entity(body) 
		World.Foliage.TREE_CHRISTMAS: tree_christmas_static_bodies.free_entity(body) 
		World.Foliage.TREE_SAFARI: tree_safari_static_bodies.free_entity(body) 
		World.Foliage.TREE_BRANCHED: tree_branched_static_bodies.free_entity(body) 
		World.Foliage.ROCK_EGG: rock_egg_static_bodies.free_entity(body) 
		World.Foliage.ROCK_FLATTOP: rock_flattop_static_bodies.free_entity(body) 
		World.Foliage.ROCK_OVERHANG: rock_overhang_static_bodies.free_entity(body) 
		World.Foliage.ROCK_SQUASHED: rock_squashed_static_bodies.free_entity(body) 
		World.Foliage.ROCK_TALL: rock_tall_static_bodies.free_entity(body) 
		World.Foliage.BUSH_ROUND: bush_round_static_bodies.free_entity(body) 
		World.Foliage.BUSH_SPROUT: bush_sprout_static_bodies.free_entity(body) 
		World.Foliage.BUSH_TALL: bush_tall_static_bodies.free_entity(body) 
		World.Foliage.FLOWERS_SUN2: flowers_sun2_static_bodies.free_entity(body) 
		World.Foliage.FLOWERS_SUN3: flowers_sun3_static_bodies.free_entity(body) 
		World.Foliage.GRASS_REED: grass_reed_static_bodies.free_entity(body) 
		World.Foliage.GRASS_SHRUB: grass_shrub_static_bodies.free_entity(body) 
		World.Foliage.MUSHROOM_BULB: mushroom_bulb_static_bodies.free_entity(body) 
		World.Foliage.MUSHROOM_POINTED: mushroom_pointed_static_bodies.free_entity(body)
	static_body_map.erase(g)
		
func get_collision_shape(g: Vector2i) -> CollisionShape3D:
	var body := static_body_map.get(g, null) as StaticBody3D
	if body == null:
		return null
	var shape := body.get_node("shape") as CollisionShape3D
	return shape
				
static var base_shapes := {
	World.Foliage.BUSH_ROUND: ShapeTemplate.capsule(0.65, 1.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.314))),
	World.Foliage.BUSH_SPROUT: ShapeTemplate.cylinder(0.5, 0.9, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.252))),
	World.Foliage.BUSH_TALL: ShapeTemplate.capsule(0.55, 1.2, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.214))),
	World.Foliage.FLOWERS_SUN2: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.469))),
	World.Foliage.FLOWERS_SUN3: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.495))),
	World.Foliage.GRASS_REED: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.496))),
	World.Foliage.GRASS_SHRUB: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.484))),
	World.Foliage.MUSHROOM_BULB: ShapeTemplate.cylinder(0.8, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.429))),
	World.Foliage.MUSHROOM_POINTED: ShapeTemplate.capsule(0.35, 1.0, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.428))),
	World.Foliage.ROCK_EGG: ShapeTemplate.capsule(1.2, 3.2, Transform3D(Basis(Quaternion(0, 0, 0.627, 0.779)), Vector3(0.07, 0.691, 0.079))),
	World.Foliage.ROCK_FLATTOP: ShapeTemplate.cylinder(1.5, 1.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.048, 0.474, 0.023))),
	World.Foliage.ROCK_OVERHANG: ShapeTemplate.cylinder(1.6, 1.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(0.026, 0.366, 0))),
	World.Foliage.ROCK_SQUASHED: ShapeTemplate.cylinder(1.4, 1.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.005, 0.4, 0.039))),
	World.Foliage.ROCK_TALL: ShapeTemplate.capsule(1.2, 2.8, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.073, 0.906, 0.016))),
	World.Foliage.TREE_BRANCHED: ShapeTemplate.cylinder(4.0, 0.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_CHRISTMAS: ShapeTemplate.cylinder(4.0, 0.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_PYRAMID: ShapeTemplate.cylinder(4.0, 0.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_ROUND: ShapeTemplate.cylinder(4.0, 0.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_SAFARI: ShapeTemplate.cylinder(4.0, 0.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),	
}

const mesh_scales = {
	World.Foliage.BUSH_ROUND: 2.0,
	World.Foliage.BUSH_SPROUT: 1.0,
	World.Foliage.BUSH_TALL: 1.0,
	World.Foliage.FLOWERS_SUN2: 2.5,
	World.Foliage.FLOWERS_SUN3: 2.5,
	World.Foliage.GRASS_REED: 4.0,
	World.Foliage.GRASS_SHRUB: 2.75,
	World.Foliage.MUSHROOM_BULB: 2.5,
	World.Foliage.MUSHROOM_POINTED: 4,
	World.Foliage.ROCK_EGG: 1.0,
	World.Foliage.ROCK_FLATTOP: 10.0,
	World.Foliage.ROCK_OVERHANG: 3.0,
	World.Foliage.ROCK_SQUASHED: 15.0,
	World.Foliage.ROCK_TALL: 2.0,
	World.Foliage.TREE_BRANCHED: 1.0,
	World.Foliage.TREE_CHRISTMAS: 1.0,
	World.Foliage.TREE_PYRAMID: 1.0,
	World.Foliage.TREE_ROUND: 1.0,
	World.Foliage.TREE_SAFARI: 1.0,
}
