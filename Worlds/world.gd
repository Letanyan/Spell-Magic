class_name World

enum Biome {
	WATER,
	GRASSLAND, TAIGA, FOREST, DESERT, JUNGLE, SAVANNAH, TUNDRA,
	OTHERWORLD, HFIL
}

enum Enemy {
	# !! WARNING: When adding new cases ensure `world_enemy_enum` method on `Enemy` 
	# is updated to reflect new case added here. As well as, in population.gd
	NONE, UNDEAD, BAT, MOLE, HUMAN, WALKER, FISH, BIRDMAN
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

