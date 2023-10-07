class_name Artifact

enum Effect {
	NONE,
	# refers to increases players damage
	BOOST_PERCENTAGE,
	BOOST_FLAT,
	# refers to lowering players resistance
	RESISTANCE_PERCENTAGE,
	RESISTANCE_FLAT
}

enum Event {
	NONE,
	RECEIVE,
	DEAL
}

enum Element {
	ANY, # is used as an offset so the next 6 elements map to Spell.Element 
	FIRE, WATER, ROCK, AIR, ICE, ELECTRIC,
	MANA, HEALTH,
	POWER, COUNT, DURATION, MANA_BUMP,
	SPELL_VELOCITY, SPELL_RADIUS
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
		
	static func make_random(
		is_ef: float = 0.5, 
		ef_prob: Dictionary = {Effect.BOOST_PERCENTAGE: 0.1, Effect.BOOST_FLAT: 0.1, Effect.RESISTANCE_PERCENTAGE: 0.1, Effect.RESISTANCE_FLAT: 0.1}, 
		ev_prob: Dictionary = {Event.RECEIVE: 0.1, Event.DEAL: 0.1}, 
		el_prob: Dictionary = {Element.FIRE: 0.1, Element.WATER: 0.1, Element.ROCK: 0.1, Element.AIR: 0.1, 
		Element.ICE: 0.1, Element.ELECTRIC: 0.1, Element.MANA: 0.1, Element.HEALTH: 0.1, Element.ANY: 0.1,
		Element.POWER: 0.1, Element.COUNT: 0.1, Element.DURATION: 0.1, Element.MANA_BUMP: 0.1, 
		Element.SPELL_VELOCITY: 0.1, Element.SPELL_RADIUS: 0.1}, 
		amount_range: Vector2i = Vector2i(0, 100), 
		pt_prob: Dictionary = {Pattern.CIRCLE: 0.1, Pattern.SQUARE: 0.1, Pattern.TRIANGLE: 0.1}) -> Option:
		var flip := Population.random_entity_from_distribution(randf(), {true: is_ef, false: 1 - is_ef}, false) as bool
		var ef := Population.random_entity_from_distribution(randf(), ef_prob, Effect.BOOST_FLAT) as Effect
		var ev := Population.random_entity_from_distribution(randf(), ev_prob, Event.DEAL) as Event
		var el := Population.random_entity_from_distribution(randf(), el_prob, Element.ANY) as Element
		var am := randi_range(amount_range.x, amount_range.y)
		var pt := Population.random_entity_from_distribution(randf(), pt_prob, Pattern.CIRCLE) as Pattern
		return Option.new(Effect.NONE if not flip else ef, Event.NONE if flip else ev, el, am, pt)
	
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
			Effect.BOOST_PERCENTAGE, Effect.RESISTANCE_PERCENTAGE:
				return Vector2(0, amount)
			Effect.BOOST_FLAT, Effect.RESISTANCE_FLAT:
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
				Effect.RESISTANCE_PERCENTAGE, Effect.RESISTANCE_FLAT:
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
		var result := ("+" if effect == Effect.BOOST_PERCENTAGE or effect == Effect.BOOST_FLAT else "-") + ("%d" % amount)
		if effect == Effect.BOOST_PERCENTAGE or effect == Effect.RESISTANCE_PERCENTAGE:
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
			Element.POWER:
				return "P"
			Element.DURATION:
				return "T"
			Element.COUNT:
				return "N"
			Element.MANA_BUMP:
				return "M+"
			Element.SPELL_VELOCITY:
				return "v"
			Element.SPELL_RADIUS:
				return "r"
		return ""
		
	func element_color() -> Color:
		match element:
			Element.ANY:
				return Color.NAVAJO_WHITE
			Element.FIRE:
				return Color.RED
			Element.WATER:
				return Color.BLUE
			Element.AIR:
				return Color.GREEN
			Element.ROCK:
				return Color.SADDLE_BROWN
			Element.ELECTRIC:
				return Color.YELLOW
			Element.ICE:
				return Color.DEEP_SKY_BLUE
			Element.HEALTH:
				return Color.DARK_GREEN
			Element.MANA:
				return Color.DARK_BLUE
			Element.POWER:
				return Color.REBECCA_PURPLE
			Element.DURATION:
				return Color.TEAL
			Element.COUNT:
				return Color.DARK_ORANGE
			Element.MANA_BUMP:
				return Color.MIDNIGHT_BLUE
			Element.SPELL_VELOCITY:
				return Color.GREEN_YELLOW
			Element.SPELL_RADIUS:
				return Color.DARK_RED
		return Color.DEEP_PINK
		
	func color() -> Color:
		var result := element_color()
		if effect != Effect.NONE:
			return result.lightened(0.5)
		elif event != Event.NONE:
			return result
		return result
				
	
	func description() -> String:
		if effect == Effect.NONE and event == Event.NONE:
			return ""
		
		var result := ""
		if effect != Effect.NONE:
			result = ("DMG" if effect == Effect.BOOST_PERCENTAGE or effect == Effect.BOOST_FLAT else "RES") + ("%d " % amount)
			match effect:
				Effect.BOOST_PERCENTAGE:
					result += "%"
				Effect.RESISTANCE_PERCENTAGE:
					result += "%"
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
				result += "F"
			Element.WATER:
				result += "W"
			Element.AIR:
				result += "A"
			Element.ROCK:
				result += "R"
			Element.ELECTRIC:
				result += "E"
			Element.ICE:
				result += "I"
			Element.HEALTH:
				result += "H"
			Element.MANA:
				result += "M"
			Element.POWER:
				result += "P"
			Element.DURATION:
				result += "T"
			Element.COUNT:
				result += "N"
			Element.MANA_BUMP:
				result += "M+"
			Element.SPELL_VELOCITY:
				result += "v"
			Element.SPELL_RADIUS:
				result += "r"
				
		return result
						
					
var name: String
var top: Option
var right: Option
var bottom: Option
var left: Option

func _init(n: String, t: Option = Option.empty(), r: Option = Option.empty(), b: Option = Option.empty(), l: Option = Option.empty()):
	name = n
	top = t
	right = r
	bottom = b
	left = l

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
