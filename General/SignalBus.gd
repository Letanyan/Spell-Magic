extends Node

signal pick_up_world_item_spell(spell: Spell, message: String)
signal pick_up_world_item_artifact(artifact: Artifact, message: String)
signal pick_up_world_item_key(key: int, message: String)
signal pick_up_world_item_coin(coin: int, message: String)
signal pick_up_world_item_red_cross(health: float, message: String)

signal projectile_hit(origin: Node3D, collision_layer: int, spell: Spell, time: float, p: SpellBody)
signal not_enough_mana_for_spell(spell: Spell) 


signal enemy_death(enemy: Enemy)
