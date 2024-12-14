extends Node

signal pick_up_world_item_spell(spell: Spell, message: String)
signal pick_up_world_item_artifact(artifact: Artifact, message: String)
signal pick_up_world_item_key(key: int, message: String)
signal pick_up_world_item_coin(coin: int, message: String)
signal pick_up_world_item_red_cross(health: float, message: String)
signal pick_up_world_item_scroll_note(note_id: String, message: String)

signal projectile_hit(origin: Node3D, collision_object: CollisionObject3D, spell: Spell, time: float, p: SpellBody, damage: Dictionary)
signal not_enough_mana_for_spell(spell: Spell) 


signal enemy_death(enemy: Enemy)

signal level_up_world(player: Player, new_world_level: int)
