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
	FIRE, WATER, ROCK, AIR, ICE, ELECTRIC,
	MANA, HEALTH, ANY
}

enum Pattern {
	CIRCLE, SQUARE, TRIANGLE
}

class Option:
	var effect: Effect
	var event: Event
	var element: Element
	var amount: int
	var pattern: Pattern
	
	static func empty() -> Option:
		return Option.new(Effect.NONE, Event.NONE, Element.ANY, 0, Pattern.CIRCLE)
		
	static func make_event(ev: Event, el: Element, am: int, pt: Pattern) -> Option:
		return Option.new(Effect.NONE, ev, el, am, pt)
		
	static func make_effect(ef: Effect, el: Element, am: int, pt: Pattern) -> Option:
		return Option.new(ef, Event.NONE, el, am, pt)
		
	static func make_random() -> Option:
		var flip := randi_range(0, 1)
		return Option.new(randi_range(1, 4) * flip, randi_range(1, 2) * (1 - flip), randi_range(0, 8), randi_range(1, 100), randi_range(0, Pattern.size() - 1))
	
	func _init(ef: Effect, ev: Event, el: Element, am: int, pt: Pattern):
		effect = ef
		event = ev
		element = el
		amount = am
		pattern = pt
		
	func save_dict() -> Dictionary:
		return {"effect": effect, "event": event, "element": element, "amount": amount, "pattern": pattern}
		
	func load_dict(dict: Dictionary):
		effect = dict["effect"] as Effect
		event = dict["event"] as Event
		element = dict["element"] as Element
		amount = dict["amount"]
		pattern = dict.get("pattern", 0)
		
	func amount_as_tuple() -> Vector2:
		match effect:
			Effect.BOOST_PERCENTAGE, Effect.REDUCE_PERCENTAGE:
				return Vector2(0, amount)
			Effect.BOOST_FLAT, Effect.REDUCE_FLAT:
				return Vector2(amount, 0)
		return Vector2.ZERO
		
	func element_event() -> Vector2i:
		return Vector2i(amount, event * Element.size() + element)
	
	func element_effect() -> int:
		return effect * Element.size() + element
		
	func player_deals_damage() -> int:
		if effect != Effect.NONE:
			match effect:
				Effect.BOOST_PERCENTAGE, Effect.BOOST_FLAT:
					return 1
				Effect.REDUCE_PERCENTAGE, Effect.REDUCE_FLAT:
					return -1
		elif event != Event.NONE:
			match event:
				Event.RECEIVE:
					return -1
				Event.DEAL:
					return 1		
		return 0
		
	func amount_description() -> String:
		if effect == Effect.NONE:
			return ""
		var result := ("+" if amount > 0 else "-") + ("%d" % amount)
		if effect == Effect.BOOST_PERCENTAGE or effect == Effect.REDUCE_PERCENTAGE:
			result += "%"
		return result
		
	func duration_description() -> String:
		return ("%d" % amount) + "s"
		
	func pattern_description() -> String:
		match pattern:
			Pattern.CIRCLE: return "()"
			Pattern.SQUARE: return "[]"
			Pattern.TRIANGLE: return "/\\"
		return "X"
		
	func element_description() -> String:
		match element:
			Element.ANY:
				return "X"
			Element.FIRE:
				return "F"
			Element.WATER:
				return "W"
			Element.AIR:
				return "A"
			Element.ROCK:
				return "R"
			Element.ELECTRIC:
				return "E"
			Element.ICE:
				return "I"
			Element.HEALTH:
				return "H"
			Element.MANA:
				return "M"
		return ""
	
	func description() -> String:
		if effect == Effect.NONE and event == Event.NONE:
			return ""
		
		var result := ""
		var effect_desc := ""
		if effect != Effect.NONE:
			result = ("+" if amount > 0 else "-") + ("%d" % amount)
			match effect:
				Effect.BOOST_PERCENTAGE:
					result += "%"
					effect_desc = " =>"
				Effect.BOOST_FLAT:
					effect_desc = " =>"
				Effect.REDUCE_PERCENTAGE:
					result += "%"
					effect_desc = " <="
				Effect.REDUCE_FLAT:
					effect_desc = " <="
			result += " "
		elif event != Event.NONE:
			match event:
				Event.RECEIVE:
					result = "<= "
				Event.DEAL:
					result = "=> "
		
		match element:
			Element.ANY:
				result += "A"
			Element.FIRE:
				result += "F" + effect_desc
			Element.WATER:
				result += "W" + effect_desc
			Element.AIR:
				result += "A" + effect_desc
			Element.ROCK:
				result += "R" + effect_desc
			Element.ELECTRIC:
				result += "E" + effect_desc
			Element.ICE:
				result += "I" + effect_desc
			Element.HEALTH:
				result += "H"
			Element.MANA:
				result += "M"
				
		return result
					
					
					

var name: String
var top: Option = Option.empty()
var right: Option = Option.empty()
var bottom: Option = Option.empty()
var left: Option = Option.empty()

func save_dict() -> Dictionary:
	return {"name": name, "top": top.save_dict(), "left": left.save_dict(), 
	"right": right.save_dict(), "bottom": bottom.save_dict()}
	
func load_dict(dict: Dictionary):
	name = dict["name"]
	top = Option.empty()
	top.load_dict(dict["top"])
	left = Option.empty()
	left.load_dict(dict["left"])
	right = Option.empty()
	right.load_dict(dict["right"])
	bottom = Option.empty()
	bottom.load_dict(dict["bottom"])
