extends Node

signal pick_up_world_item_spell(entity: SpellPaper, spell: Spell, message: String)
signal pick_up_world_item_artifact(entity: ArtifactCube, artifact: Artifact, message: String)
signal pick_up_world_item_key(entity: KeyPrism, key: int, message: String)
signal pick_up_world_item_coin(entity: CoinDisc, coin: int, message: String)
signal pick_up_world_item_red_cross(entity: RedCross, health: float, message: String)
signal pick_up_world_item_scroll_note(entity: ScrollNote, note_id: String, message: String)
signal observe_world_item_scroll_note(entity: ScrollNote, note_id: String, message: String)
signal pick_up_world_item_flag(entity: Flag, flag: int, message: String)

signal projectile_hit(origin: Node3D, collision_object: Node3D, collision_layer: int, spell: Spell, time: float, p: SpellBody, damage: Dictionary)
signal not_enough_mana_for_spell(spell: Spell) 

signal enemy_death(enemy: Enemy)

signal level_up_world(player: Player, new_world_level: int)
signal key_collected(player: Player)
signal player_is_ready(player: Player)

signal spell_from_global_book_exported(spell: Spell)

signal spell_added_to_world(projectile: SpellBody)
signal spell_removed_from_world(projectile: SpellBody)
signal item_added_to_world(item: WorldItem)
signal item_removed_from_world(item: WorldItem)
signal enemy_added_to_world(enemy: Enemy)
signal enemy_removed_from_world(enemy: Enemy)
