class_name GameSettings

enum ReadyState { NOT, IN, IS }
enum NotesUnlockSettings { IN_GAME, SHOW_ALL, HIDE_ALL }
enum NotesSortSettings { CHRONOLOGICAL, ALPHABETICAL }
enum Tutorials { CONTROLS, SPELLS, ARTIFACTS, COINS, NOTES, WANDS, KEYS, GOT_UPGRADE }

var last_world: String
var default_world_settings: WorldSettings
var user_functions: Dictionary
var user_functions_text: String
var unlocked_notes: Dictionary
var notes_unlock_settings: NotesUnlockSettings
var notes_sort_settings: NotesSortSettings
var saved_worlds: Dictionary
var tutorials_shown: Dictionary ## [Tutorials]bool
var username: String
var password: String
var user_id: int

func save() -> void:
	var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
	
	file.store_var({
		"last_world": last_world, "user_functions_text": user_functions_text,
		"default_world_settings": default_world_settings.save_dict(),
		"unlocked_notes": unlocked_notes, "notes_unlock_settings": notes_unlock_settings,
		"notes_sort_settings": notes_sort_settings, "saved_worlds": saved_worlds,
		"tutorials_shown": tutorials_shown, "username": username, "password": password, 
		"user_id": user_id,
	})

func read() -> void:
	var file := FileAccess.open("user://settings.json", FileAccess.READ)
	var data: Dictionary
	if file != null:
		data = file.get_var()
	else:
		data = {}
	last_world = data.get("last_world", "")
	
	default_world_settings = WorldSettings.new(null)
	default_world_settings.load_dict(data.get("default_world_settings", {}) as Dictionary)
	
	unlocked_notes = data.get("unlocked_notes", {"spell Copy and Load": true, "spell Save and Load": true}) as Dictionary
	notes_unlock_settings = data.get("notes_unlock_settings", NotesUnlockSettings.IN_GAME) as NotesUnlockSettings
	notes_sort_settings = data.get("notes_sort_settings", NotesSortSettings.CHRONOLOGICAL) as NotesSortSettings
	
	tutorials_shown = data.get("tutorials_shown", {}) as Dictionary
	
	build_user_functions(data.get("user_functions_text", "") as String)
	
	saved_worlds = data.get("saved_worlds", {}) as Dictionary
	
	username = data.get("username", "")
	password = data.get("password", Rand.id(20, Time.get_ticks_usec() + 3))
	user_id = data.get("user_id", -1)
	
func build_user_functions(text: String) -> void:
	user_functions_text = text
	var lines := text.split("\n")
	user_functions.clear()
	for line in lines:
		build_user_function(line)
	
func build_user_function(text: String) -> void:
	if not text.contains("="):
		return
		
	var parts := text.split("=", false, 2)
	if parts.size() != 2:
		return
		
	var decl := parts[0]
	var defn := parts[1]
	
	var args := decl.split(" ", false)
	var spell_name := ""
	var spell_args := PackedStringArray([])
	if args.size() >= 1:
		spell_name = args[0]
		for i in range(1, args.size()):
			spell_args.append(args[i])
			
	GlobalData.game_settings.set_user_function(spell_name, spell_args, defn)
	
func set_user_function(fn: String, args: PackedStringArray, expr: String) -> void:
	var gdexpr := Expr.new(expr)
	args.reverse()
	user_functions[fn] = {"args": args, "expr": gdexpr.back, "defn": expr}

func remove_user_function(fn: String) -> void:
	user_functions.erase(fn)

static func get_world_names() -> Array:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	dir.change_dir("worlds")
	var worlds := dir.get_directories()
	var times: Array[Array] = []
	for world in worlds:
		var file := dir.get_current_dir(true) + "/" + world + "/settings.json"
		if not FileAccess.file_exists(file):
			continue
		if world != "test+arena":
			var unix := FileAccess.get_modified_time(file)
			times.append([world, unix])
		
	times.sort_custom(func(a: Array[Variant], b: Array[Variant]) -> bool: return a[1] > b[1])
	return times

enum NoteKind { ANY, FUNC, ARTIFACT, SPELL, VARIABLE, WAND, UPGRADES }
func get_unfound_note(prefix_kind: NoteKind = NoteKind.ANY) -> String:
	var prefix := (NoteKind.keys()[prefix_kind] as String).to_lower()
	if prefix == "any":
		prefix = ""
	var key_samples := notes.keys()
	key_samples.shuffle()
	for key: String in key_samples:
		if not unlocked_notes.has(key) and (prefix.is_empty() or key.begins_with(prefix)):
			return key
	return ""

static var notes := {
	"func rot": "{rot(a, v, p)} returns the vector {p} rotated around vector {v} by angle {a}.",
	"func rot_x, rot_y, rot_z": "{rot_#(a, vx, vy, vz, px, py, pz)} can be used to rotate a point around a vector and returns the {#} component. The parameters of the functions are defined as, {a} which is the angle around the vector and {(vx, vy, vz)} which the point {(px, py, pz)} is rotated around.",
	"func lerp": "{lerp(t, A, B)} is defined as {A+t*(B-A)}.",
	"func segment2, segment3, segment4, segment5": "{segment#(t, x1, x2, ..., xn, d1, d2, ..., d(n-1) )} interpolates between the values of {x} over time periods of {d} where {t} describes the current time. For example when {dk} <= {t} < {d(k+1)} then return {lerp(t - sum(d1, ..., dk), x(k+1), x(k+2))}. If {t} < {d1} then return {lerp(t, d1, d2)}.",
	"func unit": "{unit(v)} returns the unit vector of {v}. he exact definition of the function is {v/sqrt(v.x*v.x+v.y*v.y+v.z*v.z)}",
	"func unit_x, unit_y, unit_z": "{unit_#(vx, vy, vz)} returns the {#} component of the unit vector of {(vx,vy,vz)}. The exact definition of the function is {v#/sqrt(vx*vx+vy*vy+vz*vz)}",
	"func dot": "{dot(v, w)} returns the dot product of {v} and {w}. The exact definition of the function is {v.x*w.x+v.y*w.y+v.z*w.z}.",
	"func dot2, dot3": "{dot2(vx,vy,wx,wy)} and {dot3(vx,vy,vz,wx,wy,wz)} returns the dot product of the parameters. The exact definition of the functions are {vx*wx+vy*wy} and {vx*wx+vy*wy+vz*wz} respectively.",
	"func len" : "{len(v)} return the length of {v}. The exact definition of the function is {sqrt(v.x*w.x+v.y*w.y+v.z*w.z)}",
	"func len2, len3": "{len2(vx, vy)} and {len3(vx, vy, vz)} returns the length of the parameters. The exact definitions of the functions are {sqrt(vx*vx+vy*vy)} and {sqrt(vx*vx+vy*vy+vz*vz)} respectively.",
	"func cross": "{cross(v, w)} returns the cross product of vector v and w. The exact defintion of the function is {vec(v.x*w.y - v.y*w.x, v.z*w.x - v.x*w.z, v.y*w.z - v.z*w.y)}.",
	"func cross_x, cross_y, cross_z": "{cross_#(vx,vy,vz,wx,wy,wz)} returns the {#} component of the cross product of 2 vectors {(vx,vy,vz)} and {(wx,wy,wz)}. The exact defintion for each function {cross_x}, {cross_y} and {cross_z} is {(vx*wy - vy*wx)}, {(vz*wx - vx*wz)} and {(vy*wz - vz*wy)} respectively",
	"func proj": "{proj(v, w)} return the projection of vector {w} onto the plane defined by the normal vector {v}.",
	"func proj_x, proj_y, proj_z": "{proj_#(vx,vy,vz,wx,wy,wz)} returns the {#} component of the projected vector {(wx,wy,wz)} onto the plane defined by the normal vector {(vx,vy,vz)}.",
	"func quad, cubic": "{quad(t, A, B, C)} and {cubic(t, A, B, C, D)} returns a point on the quadratic and cubic bezier curve. The curves are defined by the points {A}, {B}, {C} and {t} is the interpolation amount between {0} and {1}.",
	"func clamp": "{clamp(A, B, C)} returns {A} if it is between {B} and {C}. If {A} is less than {B} then {B} is returned or if {A} is greater than {C} then {C} is returned.",
	"func if": "{if(cond, T, F)} returns {T} if {cond} is equal to {0} else {F} is returned.",
	"func cube": "{cube(x)} returns {x*x*x}.",
	"func cbrt": "{cbrt(x)} returns the cube root of {x}.",
	"func sqr": "{sqr(x)} returns {x*x}.",
	"func sqrt": "{sqrt(x)} returns the square root of {x}.",
	"func abs": "{abs(x)} returns the absolute value of {x}. If {x} is less than {0} then return {-x} else return {x}.",
	"func logN": "{logN(x)} returns the natural log ({e}) of x.",
	"func log10": "{log10} returns the log base 10 of {x}",
	"func pow": "{pow(x,y)} returns {x} raised to the power of {y}",
	"func min": "{min(x,y)} returns the smallest value between {x} and {y}",
	"func max": "{max(x,y)} returns the largest value between {x} and {y}",
	"func not": "{not(x)} returns {0} if x is equal to {1} else {1} is returned.",
	"func eq": "{eq(x,y)} returns {1} if {x} is equal to {y} else {0} is returned.",
	"func neq": "{neq(x,y)} returns {1} if {x} is not equal to {y} else {0} is returned.",
	"func lt": "{lt(x,y)} returns {1} if {x} is less than {y} else {0} is returned.",
	"func lte": "{lte(x,y)} returns {1} if {x} is less than or equal to {y} else {0} is returned.",
	"func gt": "{lt(x,y)} returns {1} if {x} is greater than {y} else {0} is returned.",
	"func gte": "{gte(x,y)} returns {1} if {x} is greater than or equal {y} else {0} is returned.",
	"func ceil": "{ceil(x)} returns the value of {x} rounded towards the next largest whole number.",
	"func round": "{round(x)} returns the value of {x} rounded towards the nearest whole number.",
	"func floor": "{floor(x)} returns the value of {x} rounded towards the smallest whole number.",
	"func div": "{div(x,y)} returns the whole number part of {x} divided by {y}.",
	"func mod": "{mod(x,y)} returns the remainder of {x} divided by {y}.",
	"func inv": "{inv(x)} returns {1/x}. If {x} is {0} then {0} is returned.",
	"func sin, cos, tan": "{sin(x)}, {cos(x)} and {tan(x)} returns the sine, cosine and tangent of {x}",
	"func asin, acos, atan": "{asin(x)}, {acos(x)} and {atan(x)} returns the inverse sine, cosine and tangent of {x}",
	"func sinh, cosh, tanh": "{sinh(x)}, {cosh(x)} and {tanh(x)} returns the hyperbolic sine, cosine and tangent of {x}",
	"func atan2": "{atan2(y,x)} returns the angle between the line from (0,0) to (x,y) and the positive x-axis.",
	"func vec": "{vec(x,y,z)} returns a 3 dimensional vector. You can access each component using the {'.'} operator. The {.} operator take a vector on the left side ({lhs}) and a number on the right ({rhs}). The result will be the {rhs}th component of {lhs} (components are 0 indexed). Example {vec(101, 202, 303).0} will return {101}, {vec(101, 202, 303).1} will return {202} and {vec(101, 202, 303).2} will return {303}",
	"func perp": "{perp(v)} returns some vector that is perpendicular to {v}",
	"func perp_x, perp_y, perp_z": "{perp_#(v)} returns the {#} component of some vector that is perpendicular to {v}",
	"func snap": "{snap(x, y)} returns {x} rounded to the nearest {y}. For example, you can use {snap(x, 1)} to return the the nearest whole number to {x}. Or, you could have {snap(x, 0.1)} to return x to 1 decimal place.",
	
	"artifact Pattern": "Each artifact has either a {circle}, {square} or {triangle} on each of its 4 sides of the artifact. Artifacts can only join on to other artifacts that have the same shape between the connecting edges.",
	"artifact Connections": "An artifact can either have an event or effect on each of its 4 sides. Connecting artifact edges requires one to be an event and the other an effect.",
	"artifact Event": "Events can be either be receiving or dealing damage. The damage dealt must be of some element defined for the event. Each event has an associated duration for which the connected effect will last.",
	"artifact Effect": "Effects either increase or decrease stats. Each effect applies to one of the following {Fire}, {Rock}, {Electric}, {Water}, {Wind}, {Ice} resistance or damage buff. A special 'any' element effect can buff all 6 elements damage or resistance. Other stats such as current health and mana can be changed, as well as, max health and mana. Attack, defence, crit rate, crit damage, spell movement speed, spell duration, spell max radius, spell projectile count, spell max power and player running speed can also be changed.",
	"artifact Crit Rate and Crit Damage": "Buffs and debuffs for crit stats apply to all projectiles of a spell when cast. The effects on all projectiles will last even after the buff/debuffs have expired on the player.",
	"artifact Spell Movement Speed, Duration, Max Radius, Projectile Count and Max Power": "These effects increase the max limits of a spell. The limits are only increased while the effects are active. Spells already cast will not be effected however.",
	"artifact Running Speed": "This will increase/decrease your running speed for some amount of time.",
	"artifact Current Health and Mana": "These are permanant changes to your current health and mana.",
	"artifact Max Health and Mana": "These will change your max health and mana for a temporary period. Any excess current health or mana will be lost after a decrease to maximum health or mana respectively.",
	
	"spell r": "The radius of every projectile for the spell.",
	"spell D": "The time delay in seconds for each projectile of the spell.",
	"spell T": "The duration for all projectiles of the spell.",
	"spell N": "The total number of projectiles for the spell.",
	"spell P": "The base damage multipler for all projectiles of the spell.",
	"spell CR": "The crit rate for all projectiles of the spell. Crit rate defines some probability to possibly deal additional damage.",
	"spell CD": "The crit damage for all projectiles of the spell. Crit damage is the amount of additional damage dealt if a critical hit is dealt.",
	"spell chain": "A chain spell is a spell (with optional parameters) that is automatically cast based on one of the options selected. {At Start} and {At End} are called at the start at end for each projectile. {On Hit} is called when a projectile hits an object.",
	"spell M": "The amount of mana the spell will cost to cast. Increasing mana put into the spell will decrease the spell's cooldown time. Any excess mana that no longer decreases the cooldown will increase elemental application up to a certain point.",
	"spell Player is Origin": "By default a projectiles origin is at the players reticule. Setting {Player is Origin} will make the spell's origin the center of the players feet.",
	"spell Is Bomb": "By default a projectiles origin will only be set when it enters the world after a delay if any. Setting {Is Bomb} will fix the origin for each projectile to the point when the spell is first cast.",
	"spell Follow Player": "By default a projectile will not be effected by a players movement once it enters the world. Setting {Follow Player} will make the projectile's movement relative to the players movement.",
	"spell Use Spherical Coordinates": "Changes the calculation of {x},{y},{z} with {x} being the horizontal angle, {y} the vertical angle and {z} the distance.",
	"spell Elemental Application": "Certain elements have additional effects. Namely {Fire} applies {Burn}, {Water} applies {Wet}, {Ice} applies {Freeze}, {Electric} applies {Stun} and {Wind} applies {Feather}.",
	"spell Cooldown": "The time before the spell can be cast again.",
	"spell Variables": "A list of your variables which can be used in the x, y, z and D expressions. You can use these variables to simplify your other expressions.",
	"spell Mana Return": "Spells that have complicated movement will return some amount of mana back to the player. The amount returned is proportional to the complexity of the spells movement. The complexity of a spell is vaguely defined as how different it is from a spell which travels in a straight line.",
	"spell Save and Load": "Spells can be saved, using [img=l,24x24]res://GUI/Images/cloud-upload.svg[/img], to your '{Universal Magic Book}' (which can be found in the settings menu). From your '{Universal Magic Book}' you can use the [img=l,24x24]res://GUI/Images/cloud-download.svg[/img] button to load the spell into your current games '{Magic Book}'.",
	"spell Copy and Load": "Spells can be copied to your clipboard using the [img=l,24x24]res://GUI/Images/scroll.svg[/img] button. You can use this code to share spells and use other shared spells. To load a shared spell you must have it copied and then click the '{Create New Button}' on your '{Magic Book}.' When asked 'Do you want to load spell from Clipboard?' click 'Yes.'",
	"spell Environment Effects": "Some environments have effects that can effect your spells or effect you. Some effects may by evaporating {Water} spells or {Wind} spells knocking you back. Status effects such as having {Freeze} or {Wet} applied to you may also occur.",
	"spell Burning": """{Burning} applies damage over time.
The following effects occur when a {Burning} character is hit by the following:
[ul]{Water}: The amount of {Burning} is reduced and incoming {Water} damage is decreased. [i]Note: Only once all {Burning} is removed can a character become {Wet}.[/i][/ul]
[ul]{Ice}: The amount of {Burning} is reduced and incoming {Ice} damage is decreased. [i]Note: Only once all {Burning} is removed can {Freeze} be applied.[/i][/ul]
[ul]{Electric}: The amount of {Burning} is reduced and incoming {Electric} damage is increased. [/ul]
[ul]{Wind}: The amount of {Burning} is increased. [/ul]""",
	"spell Wet": """The following effects occur when a {Wet} character is hit by the following:
[ul]{Fire}: The amount of {Wet} is reduced and incoming {Fire} damage is increased. [i]Note: Only once all {Wet} is removed can a character start {Burning}.[/i][/ul]
[ul]{Ice}: Some amount {Wet} is converted into {Freeze}. [/ul]
[ul]{Electric}: The hitbox of a {Wet} character is increased for {Electric} attacks. The {Stun} amount is increased by some amount of {Wet} and {Wet} is reduced. [/ul]
[ul]{Wind}: The amount of {Wet} is decreased. [/ul]""",
	"spell Freeze": """{Freeze} causes characters to move slower. The amount of slow down is from none to completly still relative to the amount of {Freeze}.
The following effects occur when a character with {Freeze} is hit by the following:
[ul]{Fire}: The amount of {Freeze} is reduced and incoming {Fire} damage is increased. [i]Note: Only once all {Freeze} is removed can a character start {Burning}.[/i][/ul]
[ul]{Water}: The amount of {Freeze} is increased. [/ul]
[ul]{Electric}: The {Stun} amount is increased by some amount of {Freeze} and {Freeze} is reduced. [/ul]
[ul]{Wind}: The amount of {Freeze} is decreased. [/ul]""",
	"spell Stun": "{Stun} shocks a character still for a small period of time. The amount of time scales with the amount of {Stun}.",
	"spell Feather": "{Feather} reduces the weight of a character to the {Wind} attack being applied. Increasing the amount of {Feather} increases the push applied.",
	"spell Is Infinite": "[i]Only available in the level editor.[/i] Spells will stay in the world forever. The duration of a spell will still be respected. However, when the projectile exceeds its defined duration the will reset to 0 and start again.",
	
	"variable uvw, u, v, w": "A unit vector {(u,v,w)} describing the direction from the player to the camera aim. {uvw} is the vector combination.",
	"variable UVW, U, V, W": "A unit vector {(U,V,W)} decsribing the direction from the player to an enemy that was in line with the players aim when the spell was cast. {UVW} is the vector combination.",
	"variable ruvw, ru, rv, rw": "{ru} describes the angle from the positive {x} axis to the {x} axis of the players aim. Similarily {rv} describes the {z} axis angle. While {rw} describes the angle to the {y} axis. {ruvw} is the vector combination.",
	"variable rUVW, rU, rV, rW": "{rU} describes the angle from the positive {x} axis to the {x} axis of an enemy that was in line with the player aim when the spell was cast. Similarily {rV} and {rW} describes the angle for the {z} and {y} axis. {rUVW} is the vector combination.",
	"variable ijk, i, j, k": "A unit vector {(i,j,k)} describing the direction the player is moving. {ijk} is the vector combination.",
	"variable IJK, I, J, K": "A unit vector {(I,J,K)} describing the direction from the player to the projectile. {IJK} is the vector combination.",
	"variable rijk, ri, rj, rk": "{ri} describes the angle from the positive {x} axis to the {x} axis of the players direction of movement. Similarily {rj} describes the {z} axis angle. While {rk} describes the angle to the {y} axis. {rijk} is the vector combination.",
	"variable rIJK, rI, rJ, rK": "{rI} describes the angle from the positive {x} axis to the {x} axis of each spell projectile. Similarily {rJ} describes the {z} axis angle. While {rK} describes the angle to the {y} axis. {rIJK} is the vector combination.",
	"variable tuvw, tu, tv, tw, tUVW, tU, tV, tW, tijk, ti, tj, tk, tIJK, tI, tJ, tK, truvw, tru, trv, trw, trUVW, trU, trV, trW, trijk, tri, trj, trk, trIJK, trI, trJ, trK": "Each of these values are the same as their values if you strip the 't' prefix. However these values will be updated at each time step {t}",
	"variable Tuvw, Tu, Tv, Tw, TUVW, TU, TV, TW, Tijk, Ti, Tj, Tk, TIJK, TI, TJ, TK, Truvw, Tru, Trv, Trw, TrUVW, TrU, TrV, TrW, Trijk, Tri, Trj, Trk, TrIJK, TrI, TrJ, TrK": "Each of these values are the same as their values if you strip the 'T' prefix. However these values will only be updated once when the projectile enters the world.",
	"variable Bxyz, Bx, By, Bz, Br": "{Bx}, {By} and {Bz} describe the size of the caster where each describes the width, height and depth. {Bxyz} is the vector combination of {Bx}, {By} and {Bz}. {Br} is the length of the diagonal from the center of the caster to corner of the rectangle with width and length {Bx}x{Bz}.",
	"variable n": "The index of this projectile. {0} is the lowest index and {count-1} is the highest index.",
	"variable N": "The total number of projectiles.",
	"variable T": "The total duration of the spell.",
	"variable t": "The current time in seconds since the projectile entered the world.",
	"variable r": "The size of each projectile of the spell.",
	"variable rn0, rn1, rn2, rn3, rn4, rn5, rn6, rn7, rn8, rn9": "Each represents a different random number between {0} and {1} for each different projectile cast.",
	"variable r0, r1, r2, r3, r4, r5, r6, r7, r8, r9": "Each represents a different random number between {0} and {1} for each spell cast.",
	"variable D": "The delay for each projectile.",
	"variable P": "The base damage multipler for all projectiles of the spell.",
	"variable M": "The base mana cost for this spell",
	"variable C": "The charge time in seconds. Spell must be set to a {Charged Cast} on the {Wand}.",
	"variable size": "{size} is either a vector or number that describes the ratio to the radius of each projectile. When {size} is a vector it describes the ratio, {(a normalized vector)}, of {width},{height} and {depth} to the radius of a spell respectivly. When {size} is just a number it describes the ratio, {([0, 1])}, of each projectile in all dimensions. {size} only takes effect when each projectile is cast. {size} can only be set in the variables field of the spell.",
	"variable spinrate": "{spinrate} describe the rotation speed of {Rock} spells if the projectile has velocity. If a projectile is not moving {spinrate} will define the angle the projectile faces. Limited to {[-tau, tau]}. {spinrate} can only be set in the variables field of the spell.",
	"variable x, y, z": "These are typically used with the {'.'} operator. Since {x=0},{y=1} and {z=2} you can use them to get the corrosponding component of a vector.",
	"variable position": "{position} is a vector that describes the position of the player in the world.",
	"variable pi and tau": "{pi} and {tau} are constants defined as approximatly {3.14} and {6.28} respectively.",
	
	"wand Cast": "Casts the assigned spell immediatly once keys are released.",
	"wand Charged Cast": "Keys can be held and then released to cast the assigned spell. The time spent holding the keys will be set in the variable {C} to be used in the spell.",
	"wand Rapid Cast": "Keys can be held and the assigned spell will continuosly be cast when ready.",
	"wand Choose": "Iterate through the list of spells and set the next spell as {Chosen}. Spells must be separated by commas to be part of the list. Holding the key will bring up a selection wheel.",
	"wand Cast Chosen": "Casts the {Chosen} spell immdiatly once the keys are release.",
	"wand Charged Chosen": "Keys can be held and then released to cast the {Chosen} spell. The time spent holding the keys will be set in the variable {C} to be used in the spell.",
	"wand Rapid Chosen": "Keys can be held and the {Chosen} spell will continuosly be cast when ready.",
	"wand Modifier Key": "The key will become a modifier key for all other non modifier keys. Use this to increase the availble key combinations.",
	"wand Spell Parameters": "Sometimes you might want to cast a spell but with only a few changes. You can do this using spell parameters. Each spell can have a set of customised parameters set from a wand action. Parameters must be set inside a pair of parentheses '()' which appear after the spell name. Parameters are a set of '=' separated key-value pairs separated by commas. For example, if we have a spell called 'Blast', we can set its values by declaring the spell like 'Blast(N=5, element=ice, speed=10).' In this example we change 'N' to 5, change the element of the spell to {Ice} and change its custom variable 'speed' to 10.",
	"wand Cast Spell Lists": "Using a comma separated list for {Cast}, {Charged Cast} and {Rapid Cast} will auto rotate to the next spell after each cast.",
	"wand Remove": "[i]Only available in the level editor.[/i] When cast will remove the nearest spell or item intersecting the player reticule.",
	"wand Place": """[i]Only available in the level editor.[/i]
Place items in the world. You can assign spells using their name in text field. For other items you can use the special syntax described below.
{Spells}: Add a spell item into the world. Use the normal syntax for casting a spell to describe the spell that a player will receive when picked up.
{Health}: Add a health item into the world. Use the syntax '{health(x)}' to place an item that restores '{x%}' health when picked up.
{Coin}: Add a coin item into the world. Use the syntax '{coin(x)}' to place an item that gives the player '{x}' money when picked up. 
""",
	
	"upgrades Max Health": "The maximum health of the player.",
	"upgrades Max M": "The maximum mana of the player.",
	"upgrades Attack": "The attack of the player.",
	"upgrades Defence": "The defence of the player.",
	"upgrades Max Velocity": "The maximum speed a projectile can reach.",
	"upgrades Max r": "The maximum radius of a projectile.",
	"upgrades Max T": "The maximum duration a spell can have.",
	"upgrades Max N": "The maximum number of projectiles a spell can cast.",
	"upgrades Max Speed": "The speed a player can move.",
	"upgrades Max P": "The maximum base damage multipler a spell can have.",
	"upgrades Auto M Regeneration": "The rate at which the players mana regenerates each second.",
	"upgrades Max Active Spells": "The total number of spells which can be assigned to a Wand.",
	"upgrades Elements": "The elements which can be assigned to a spell.",
	"upgrades Chain Methods": "The ways a spell can be chained to another spell.",
}

func mark_tutorial(tutorial: Tutorials) -> void:
	tutorials_shown[tutorial] = true
	save()
	
