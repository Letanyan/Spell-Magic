class_name Hormones

# Each individual has some preferred level of 'social', 'satisfaction' and 'pride'. We choose
# actions that bring the current value of these 3 values closer to the preferred levels.
var social: Vitals.Stat # increased by helping other individuals/groups. decreased by damaging/hurting others
var satisfaction: Vitals.Stat # increased by increasing needs such as thirst/hunger/health. decreases as such needs mentioned previously decrease
var pride: Vitals.Stat # increased through personal achievement such as hunting. decrease by doing embarrasing things such as stealing/scavanging

var ideal_social: float
var ideal_satisfaction: float
var ideal_pride: float

# risk manipulates the probability of choosing actions by preferring actions with the most large changes
# that bring the 3 values above closest to it's preferred levels.
var risk: float # increased as pride and satisifaction goes down (desperation increases).   

func _init(s: float, ss: float, p: float, r: float):
	social = Vitals.Stat.new(0, -1, 1)
	satisfaction = Vitals.Stat.new(0, -1, 1)
	pride = Vitals.Stat.new(0, -1, 1)
	ideal_social = s
	ideal_satisfaction = ss
	ideal_pride = p
	risk = r
	
func weight_for_stat(stat: Vitals.Stat, change: float, ideal: float) -> float:
	return abs(ideal - stat.amount_of_change(change))
	
func weight_for_action(action: Knowledge.Action, vitals: Vitals) -> float:
	match action.kind:
		Knowledge.ActionKind.WALK:
			if action.entity.kind == EntityInfo.Kind.BASE:
				return weight_for_stat(social, 0.1, ideal_social)
		Knowledge.ActionKind.DRINK:
			return weight_for_stat(satisfaction, action.entity.liquid_amount, ideal_satisfaction) * Globals.invf(vitals.thirst.percentage())
			
	return 0.0

func update_from_action(action: Knowledge.Action):
	match action.kind:
		Knowledge.ActionKind.WALK:
			if action.entity.kind == EntityInfo.Kind.BASE:
				social.apply(0.1)
		Knowledge.ActionKind.DRINK:
			satisfaction.apply(action.entity.liquid_amount)
