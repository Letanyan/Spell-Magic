class_name World

enum Biome {
	WATER,
	GRASSLAND, TAIGA, FOREST, DESERT, JUNGLE, SAVANNAH, TUNDRA,
	OTHERWORLD, HFIL
}

enum Enemy {
	# !! WARNING: When adding new cases ensure `world_enemy_enum` and `make` method on `Enemy` 
	# is updated to reflect new case added here. 
	# As well as `generate_enemy` and `spawn_enemy`, in population.gd
	NONE, UNDEAD, MOLE, WALKER, BIRDMAN, FISHMAN, BLUEMON, FROG, MUSHKING, RABBIT,
	BAT, DRAGON, DRAGOON, GHOST, GHOSTLY, BATTY, BEE, BUMBLE_BEE, UNDEAD_HEAD,
	FISH, BIRD, FUNGI, HOT_BLOB, MUSHROOM, SNOT_BLOB, SNOT_SPIKE, WALKER_HEAD, WIZARD,
}

enum Foliage {
	# !! WARNING: When adding new cases ensure to update `spawn_foliage` in `Population` and add methods in entity_manager.gd
	NONE,
	TREE_PYRAMID, TREE_ROUND, TREE_CHRISTMAS, TREE_SAFARI, TREE_BRANCHED,
	ROCK_EGG, ROCK_FLATTOP, ROCK_OVERHANG, ROCK_SQUASHED, ROCK_TALL,
	BUSH_ROUND, BUSH_SPROUT, BUSH_TALL, 
	FLOWERS_SUN2, FLOWERS_SUN3,
	GRASS_REED, GRASS_SHRUB,
	MUSHROOM_BULB, MUSHROOM_POINTED,
}

enum Building {
	# !! WARNING: When adding new cases ensure to update `spawn_building` in `Population` and add methods in entity_manager.gd
	NONE,
	FANTASY_VALLEY_SINGLE, FANTASY_VALLEY_DOUBLE,
	FANTASY_WELL
}

enum Item {
	# !! WARNING: When adding new cases ensure to update `spawn_world_item` in `Population` and add methods in entity_manager.gd
	NONE,
	TARGET, KEY, ARTIFACT, COIN, SPELL, HEALTH, NOTE
}
