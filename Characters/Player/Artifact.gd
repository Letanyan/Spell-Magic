class_name Artifact

enum Effect {
	NONE,
	BOOST_PERCENTAGE,
	BOOST_FLAT,
	REDUCE_PERCENTAGE,
	REDUCE_FLAT
}

enum Event {
	NONE,
	RECEIVE,
	DEAL
}

enum Element {
	ANY, FIRE, WATER, AIR, ROCK, ELECTRIC, ICE,
	MANA, HEALTH
}

class Option:
	var effect: Effect
	var event: Event
	var element: Element
	var amount: float
	
	static func empty() -> Option:
		return Option.new(Effect.NONE, Event.NONE, Element.ANY, 0)
		
	static func make_event(ev: Event, el: Element, am: float) -> Option:
		return Option.new(Effect.NONE, ev, el, am)
		
	static func make_effect(ef: Effect, el: Element, am: float) -> Option:
		return Option.new(ef, Event.NONE, el, am)
	
	func _init(ef: Effect, ev: Event, el: Element, am: float):
		effect = ef
		event = ev
		element = el
		amount = am

var name: String
var top: Option = null
var right: Option = null
var bottom: Option = null
var left: Option = null
