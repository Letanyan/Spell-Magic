extends Node

signal pick_up_world_item_spell(spell: Spell, message: String)
signal pick_up_world_item_artifact(artifact: Artifact, message: String)

signal projectile_hit(origin: Node3D, spell: Spell, time: float)
signal not_enough_mana_for_spell(spell: Spell) 


signal enemy_death(enemy: Enemy)
