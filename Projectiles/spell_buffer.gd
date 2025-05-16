extends Node

const packed_scenes: Array[PackedScene] = [
	preload("res://Projectiles/void.tscn"),
	preload("res://Projectiles/fire.tscn"),
	preload("res://Projectiles/rock.tscn"),
	preload("res://Projectiles/electric.tscn"),
	preload("res://Projectiles/water.tscn"),
	preload("res://Projectiles/air.tscn"),
	preload("res://Projectiles/ice.tscn"),
]
const turret = preload("res://Projectiles/turret/turret.tscn")

var projectiles: Array[EntityManager.EntityBuffer] = []
var turrets: EntityManager.EntityBuffer


func _ready() -> void:
	var deinit_spell := func(body: SpellBody) -> void:
		pass
	for el: int in Spell.Element.values():
		var buffer := EntityManager.EntityBuffer.new(20, func() -> SpellBody: return packed_scenes[el].instantiate(), deinit_spell, str(Spell.Element.keys()[el]))
		projectiles.append(buffer)

	var deinit_turret := func(body: SpellTurret) -> void:
		pass		
	turrets = EntityManager.EntityBuffer.new(10, func() -> SpellTurret: return turret.instantiate(), deinit_turret, "TURRET")

func get_projectile(element: Spell.Element) -> SpellBody:
	var result := projectiles[element].get_entity() as SpellBody
	result.time_stamp = -1
	result.name = Spell.Element.keys()[element] + Rand.id(5, Time.get_ticks_usec())
	return result
	
func get_turret() -> SpellTurret:
	var result := turrets.get_entity() as SpellTurret
	return result
	
func free_projectile(s: SpellBody) -> void:
	s.free_when_ready = NAN
	s.position.y = 1000
	projectiles[s.spell.element].free_entity(s)
	SignalBus.spell_removed_from_world.emit(s)

func free_turrent(t: SpellTurret) -> void:
	t.position.y = -1000
	turrets.free_entity(t)
