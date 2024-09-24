class_name World

enum Biome {
	WATER,
	GRASSLAND, TAIGA, FOREST, DESERT, JUNGLE, SAVANNAH, TUNDRA,
	OTHERWORLD, HFIL
}

enum Enemy {
	# !! WARNING: When adding new cases ensure `world_enemy_enum` method on `Enemy` 
	# is updated to reflect new case added here. 
	# As well as `generate_enemy` and `spawn_enemy`, in population.gd
	NONE, UNDEAD, MOLE, WALKER, BIRDMAN, FISHMAN, BLUEMON, FROG, MUSHKING, RABBIT,
	BAT, DRAGON, DRAGOON, GHOST, GHOSTLY,
	FISH, BIRD, FUNGI, HOT_BLOB, MUSHROOM,
}

enum Foliage {
	NONE,
	TREE_PYRAMID, TREE_ROUND, TREE_CHRISTMAS, TREE_SAFARI, TREE_BRANCHED
}

enum Building {
	NONE,
	FANTASY_VALLEY_SINGLE, FANTASY_VALLEY_DOUBLE,
	FANTASY_WELL
}

enum Item {
	NONE,
	TARGET, KEY, ARTIFACT, COIN, SPELL
}
