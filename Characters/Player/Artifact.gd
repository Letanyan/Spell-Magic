class_name Artifact

# only applies to Element (ANY, FIRE, WATER, ROCK, AIR, ICE, ELECTRIC)
# ignore otherwise
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
	FIRE, ROCK, ELECTRIC, WATER, AIR, ICE,
	HEALTH, MANA, ATTACK, DEFENCE, CRIT_RATE, CRIT_DMG,
	SPELL_VELOCITY, DURATION, RUNNING_SPEED,
	SPELL_RADIUS, COUNT, POWER, 
	HEALTH_BUMP, MANA_BUMP,
}
const SpellElements: Array[Element] = [Element.ANY, Element.FIRE, Element.ROCK, Element.ELECTRIC, Element.WATER, Element.AIR, Element.ICE]

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
		
	# tier between [1,10]
	static func make_event(ev: Event, el: Element, tier: int, pt: Pattern) -> Option:
		return Option.new(Effect.NONE, ev, el, event_amount_at_tier(absi(tier), ev, el), pt)
		
	# tier between [1,10] and [-1,-10]
	static func make_effect(ef: Effect, el: Element, tier: int, pt: Pattern) -> Option:
		return Option.new(ef, Event.NONE, el, effect_amount_at_tier(tier, ef, el), pt)
		
	static func make_random(
		is_ef: float = 0.5, 
		ef_prob: Dictionary = {Effect.BOOST_PERCENTAGE: 0.1, Effect.BOOST_FLAT: 0.1, Effect.RESISTANCE_PERCENTAGE: 0.1, Effect.RESISTANCE_FLAT: 0.1}, 
		ev_prob: Dictionary = {Event.RECEIVE: 0.1, Event.DEAL: 0.1}, 
		el_prob: Dictionary = {Element.FIRE: 0.1, Element.WATER: 0.1, Element.ROCK: 0.1, Element.AIR: 0.1, 
		Element.ICE: 0.1, Element.ELECTRIC: 0.1, Element.MANA: 0.1, Element.HEALTH: 0.1, Element.ANY: 0.1,
		Element.POWER: 0.1, Element.COUNT: 0.1, Element.DURATION: 0.1, Element.MANA_BUMP: 0.1, Element.ATTACK: 0.1,
		Element.SPELL_VELOCITY: 0.1, Element.SPELL_RADIUS: 0.1, Element.DEFENCE: 0.1, Element.RUNNING_SPEED: 0.1, Element.HEALTH_BUMP: 0.1, 
		Element.CRIT_RATE: 0.1, Element.CRIT_DMG: 0.1}, 
		tier_range: Vector2i = Vector2i(-10, 10), 
		pt_prob: Dictionary = {Pattern.CIRCLE: 0.1, Pattern.SQUARE: 0.1, Pattern.TRIANGLE: 0.1}) -> Option:
		var flip := Population.random_entity_from_distribution(randf(), {true: is_ef, false: 1 - is_ef}, false) as bool
		var ef := Population.random_entity_from_distribution(randf(), ef_prob, Effect.BOOST_FLAT) as Effect
		var ev := Population.random_entity_from_distribution(randf(), ev_prob, Event.DEAL) as Event
		var el: Element
		if el_prob.size() == 21:
			if flip:
				el = Population.random_entity_from_distribution(randf(), el_prob, Element.ANY) as Element
			else:
				el_prob = {Element.FIRE: 0.1, Element.WATER: 0.1, Element.ROCK: 0.1, Element.AIR: 0.1, 
				Element.ICE: 0.1, Element.ELECTRIC: 0.1, Element.ANY: 0.1}
				el = Population.random_entity_from_distribution(randf(), el_prob, Element.ANY) as Element
		else:
			el = Population.random_entity_from_distribution(randf(), el_prob, Element.ANY) as Element
		var tier := randi_range(tier_range.x, tier_range.y)
		var am: int
		if not flip: # is event
			am = event_amount_at_tier(absi(tier), ev, el)
		else:
			am = effect_amount_at_tier(tier, ef, el)
		var pt := Population.random_entity_from_distribution(randf(), pt_prob, Pattern.CIRCLE) as Pattern
		return Option.new(Effect.NONE if not flip else ef, Event.NONE if flip else ev, el, am, pt)
	
	# tier between [1,10]
	static func event_amount_at_tier(tier: int, ev: Event, el: Element) -> int:
		match ev:
			Event.NONE: return 0
			Event.RECEIVE, Event.DEAL:
				match el:
					Element.ANY, Element.FIRE, Element.ROCK, Element.ELECTRIC, Element.WATER, Element.AIR, Element.ICE: 
						return roundi(tier * (tier + 1.0) / 2.0)
		return 0
		
	# tier between [1,10] and [-1,-10]
	static func effect_amount_at_tier(tier: int, ef: Effect, el: Element) -> int:
		var mult := signi(tier)
		tier = absi(tier)
		match ef:
			Effect.NONE: return 0
			Effect.BOOST_PERCENTAGE, Effect.RESISTANCE_PERCENTAGE:
				return tier * tier * mult
			Effect.BOOST_FLAT, Effect.RESISTANCE_FLAT:
				match el:
					Element.ANY, Element.FIRE, Element.ROCK, Element.ELECTRIC, Element.WATER, Element.AIR, Element.ICE: 
						return tier * tier * mult
					Element.HEALTH: 
						return tier * tier * tier * mult
					Element.MANA: 
						return tier * tier * tier * mult
					Element.ATTACK: 
						return tier * tier * mult
					Element.DEFENCE: 
						return tier * tier * mult
					Element.CRIT_RATE:
						return roundi(tier * tier / 4.0) * mult
					Element.CRIT_DMG:
						return tier * tier * mult
					Element.SPELL_VELOCITY:
						return tier * tier * mult
					Element.DURATION:
						return roundi(tier * tier / 4.0) * mult
					Element.RUNNING_SPEED:
						return tier * mult
					Element.SPELL_RADIUS:
						return roundi(tier * tier / 20.0) * mult
					Element.COUNT:
						return roundi(tier * tier / 4.0) * mult
					Element.POWER:
						return tier * tier * mult
					Element.HEALTH_BUMP:
						return tier * tier * tier * mult
					Element.MANA_BUMP:
						return tier * tier * tier * mult
		return 0
	
	func _init(ef: Effect, ev: Event, el: Element, am: int, pt: Pattern) -> void:
		effect = ef
		event = ev
		element = el
		amount = am
		pattern = pt
		
	func save_dict() -> Dictionary:
		return {"effect": effect, "event": event, "element": element, "amount": amount, "pattern": pattern}
		
	func load_dict(dict: Dictionary) -> void:
		effect = dict["effect"] as Effect
		event = dict["event"] as Event
		element = dict["element"] as Element
		amount = dict["amount"]
		pattern = dict.get("pattern", 0)
		
	func save_int() -> int:
		var mag := absi(amount) & 0x7FFF_FFFF
		var smag := (0x8000_0000 if amount < 0 else 0) | mag
		return (effect << 55) | (event << 47) | (element << 39) | (pattern << 31) | smag
		
	func load_int(dict: int) -> void:
		effect = ((dict >> 55) & 0xFF) as Effect
		event  = ((dict >> 47) & 0xFF) as Event
		element = ((dict >> 39) & 0xFF) as Element
		pattern = ((dict >> 31) & 0xFF) as Pattern
		amount = dict & 0x7FFF_FFFF
		if (dict & 0x8000_0000) != 0:
			amount *= -1
		
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
		
	func direction_texture() -> Texture2D:
		if effect != Effect.NONE:
			return effect_texture()
		elif event != Event.NONE:
			return event_texture()
		return null
		
	func is_effect() -> bool:
		if effect != Effect.NONE:
			return true
		else:
			return false
		
	func effect_texture() -> Texture2D:
		if element == Element.ANY or element == Element.FIRE or element == Element.WATER or \
		element == Element.AIR or element == Element.ROCK or element == Element.ICE or \
		element == Element.ELECTRIC:
			match effect:
				Effect.BOOST_PERCENTAGE, Effect.BOOST_FLAT:
					return preload("res://GUI/Images/sword.svg")
				Effect.RESISTANCE_PERCENTAGE, Effect.RESISTANCE_FLAT:
					return preload("res://GUI/Images/shield.svg")
		return null
		
	func event_texture() -> Texture2D:
		match event:
			Event.RECEIVE:
				return preload("res://GUI/Images/take.svg")
			Event.DEAL:
				return preload("res://GUI/Images/deal.svg")
		return preload("res://GUI/Images/deal.svg")
		
	func amount_description() -> String:
		if effect == Effect.NONE:
			return ""
		var result := ("+" if amount > 0 else "") + ("%d" % amount)
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
		
	func element_texture() -> Texture2D:
		match element:
			Element.ANY:
				return preload("res://GUI/Images/infinity.svg")
			Element.FIRE:
				return preload("res://GUI/Images/fire.svg")
			Element.WATER:
				return preload("res://GUI/Images/water.svg")
			Element.AIR:
				return preload("res://GUI/Images/wind.svg")
			Element.ROCK:
				return preload("res://GUI/Images/rock.svg")
			Element.ELECTRIC:
				return preload("res://GUI/Images/electric.svg")
			Element.ICE:
				return preload("res://GUI/Images/ice.svg")
			Element.HEALTH:
				return preload("res://GUI/Images/health.svg")
			Element.MANA:
				return preload("res://GUI/Images/mana.svg")
			Element.ATTACK:
				return preload("res://GUI/Images/sword.svg")
			Element.DEFENCE:
				return preload("res://GUI/Images/shield.svg")
			Element.CRIT_RATE:
				return preload("res://GUI/Images/cubes.svg")
			Element.CRIT_DMG:
				return preload("res://GUI/Images/hypersonic.svg")
			Element.POWER:
				return preload("res://GUI/Images/power.svg")
			Element.DURATION:
				return preload("res://GUI/Images/time.svg")
			Element.COUNT:
				return preload("res://GUI/Images/count.svg")
			Element.MANA_BUMP:
				return preload("res://GUI/Images/mana-outline.svg")
			Element.HEALTH_BUMP:
				return preload("res://GUI/Images/health-outline.svg")
			Element.SPELL_VELOCITY:
				return preload("res://GUI/Images/velocity.svg")
			Element.SPELL_RADIUS:
				return preload("res://GUI/Images/radius.svg")
			Element.RUNNING_SPEED:
				return preload("res://GUI/Images/velocity.svg")
		return preload("res://GUI/Images/infinity.svg")
		
	func element_color() -> Color:
		return Artifact.color_for_element(element)
		
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
			
		var element_text := ""
		match element:
			Element.ANY: element_text = "Any"
			Element.FIRE: element_text = "Fire"
			Element.WATER: element_text = "Water"
			Element.AIR: element_text = "Wind"
			Element.ROCK: element_text = "Rock"
			Element.ELECTRIC: element_text = "Electric"
			Element.ICE: element_text = "Ice"
			Element.HEALTH: element_text = "Health"
			Element.MANA: element_text = "Mana"
			Element.ATTACK: element_text = "Attack"
			Element.DEFENCE: element_text = "Defence"
			Element.CRIT_RATE: element_text = "Crit Rate"
			Element.CRIT_DMG: element_text = "Crit Damage"
			Element.POWER: element_text = "P"
			Element.DURATION: element_text = "T"
			Element.COUNT: element_text = "N"
			Element.MANA_BUMP: element_text = "Max Mana"
			Element.HEALTH_BUMP: element_text = "Max Health"
			Element.SPELL_VELOCITY: element_text = "v"
			Element.SPELL_RADIUS: element_text = "r"
			Element.RUNNING_SPEED: element_text = "S"
			
		var result := ""
		if effect != Effect.NONE:
			var direction := "Increase" if amount > 0 else "Decrease"
			var am := absi(amount)
			var buff := ("Damage" if effect == Effect.BOOST_PERCENTAGE or effect == Effect.BOOST_FLAT else "Resistance")
			var perc := ("%" if effect == Effect.BOOST_PERCENTAGE or effect == Effect.RESISTANCE_PERCENTAGE else "")
			if SpellElements.has(element):
				return "%s %s %s by %d%s" % [direction, element_text, buff, am, perc]
			else:
				return "%s %s by %d%s" % [direction, element_text, am, perc]
		elif event != Event.NONE:
			match event:
				Event.RECEIVE:
					result = "Receive " + element_text + " Damage"
				Event.DEAL:
					result = "Deal " + element_text + " Damage"
		
		return result
	
	func matching_effect_to_event(other: Option) -> bool:
		return other.event != Artifact.Event.NONE and effect != Artifact.Effect.NONE
		
	func matching_event_to_effect(other: Option) -> bool:
		return other.effect != Artifact.Effect.NONE and event != Artifact.Event.NONE
		
	func matching_event_to_or_from_effect(other: Option) -> bool:
		return matching_effect_to_event(other) or matching_event_to_effect(other)
		
	func matching_pattern(other: Option) -> bool:
		return other.pattern == pattern
		
	func matching_connection(other: Option) -> bool:
		return matching_event_to_or_from_effect(other) and matching_pattern(other)
						
					
var name: String
var top: Option
var right: Option
var bottom: Option
var left: Option

func _init(n: String, t: Option = Option.empty(), r: Option = Option.empty(), b: Option = Option.empty(), l: Option = Option.empty()) -> void:
	name = n
	top = t
	right = r
	bottom = b
	left = l

func save_dict() -> Dictionary:
	return {"name": name, "top": top.save_dict(), "left": left.save_dict(), 
	"right": right.save_dict(), "bottom": bottom.save_dict()}
	
func load_dict(dict: Dictionary) -> void:
	name = dict["name"]
	top = Option.empty()
	top.load_dict(dict["top"] as Dictionary)
	left = Option.empty()
	left.load_dict(dict["left"] as Dictionary)
	right = Option.empty()
	right.load_dict(dict["right"] as Dictionary)
	bottom = Option.empty()
	bottom.load_dict(dict["bottom"] as Dictionary)
	
static func color_for_element(element: Element) -> Color:
	match element:
		Element.ANY:
			return Color("FFFFFF")
		Element.FIRE:
			return Color("FF0000")
		Element.WATER:
			return Color("0080FF")
		Element.AIR:
			return Color("00FF80")
		Element.ROCK:
			return Color("FF8000")
		Element.ELECTRIC:
			return Color("FF0080")
		Element.ICE:
			return Color("00FFFF")
		Element.HEALTH:
			return Color("00AA00")
		Element.MANA:
			return Color("AA00AA")
		Element.ATTACK:
			return Color("AA0000")
		Element.DEFENCE:
			return Color("00AAAA")
		Element.CRIT_RATE:
			return Color("0000AA")
		Element.CRIT_DMG:
			return Color("#AAAA00")
		Element.POWER:
			return Color("0008FF")
		Element.DURATION:
			return Color("00FF08")
		Element.COUNT:
			return Color("F700FF")
		Element.MANA_BUMP:
			return Color("AA77AA")
		Element.HEALTH_BUMP:
			return Color("77AA77")
		Element.SPELL_VELOCITY:
			return Color("77FF00")
		Element.SPELL_RADIUS:
			return Color("7700FF")
		Element.RUNNING_SPEED:
			return Color("F6FF00")
	return Color.DEEP_PINK
