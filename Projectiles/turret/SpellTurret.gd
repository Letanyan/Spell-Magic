class_name SpellTurret
extends Node3D

#var body: Node3D
#var spell_caster: SpellCaster
#var fixed_vars: Vars
#var spell: Spell
#var charge: float
#var projectile: SpellBody
#
#func update_position(delta: float) -> void:
	#charge += delta
	#spell_caster.spell_variables(fixed_vars, body, SpellCaster.SpellVariableKind.FIXED, projectile, spell)
	#spell_caster.spell_variables(fixed_vars, body, SpellCaster.SpellVariableKind.TIMED, projectile, spell)
	#fixed_vars.set_value(Vars.t, 0.0)
	#fixed_vars.set_value(Vars.frame_time, delta)
	#fixed_vars.set_value(Vars.C, charge)
	#spell.compute_expressions(fixed_vars, projectile.expression_vars, false)
	#projectile.position = spell.calculate_location(fixed_vars)
