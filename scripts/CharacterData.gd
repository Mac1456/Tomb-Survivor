extends Resource
class_name CharacterData

# Character stats structure
class Character:
	var name: String
	var description: String
	var strength: int
	var speed: int
	var armor: int
	var health: int
	var primary_attack_type: String  # "melee" or "ranged"
	var special_ability_name: String
	var special_ability_description: String
	var ultimate_ability_name: String
	var ultimate_ability_description: String
	var sprite_path: String  # Path to character sprite folder
	var vfx_primary: String  # VFX for primary attack
	var vfx_special: String  # VFX for special ability
	var vfx_ultimate: String  # VFX for ultimate ability
	var vfx_dodge: String  # VFX for dodge roll
	
	func _init(n: String, desc: String, strength_val: int, spd: int, arm: int, hp: int, 
			   primary_type: String, special_name: String, special_desc: String,
			   ultimate_name: String, ultimate_desc: String, sprite: String,
			   vfx_prim: String, vfx_spec: String, vfx_ult: String, vfx_d: String):
		name = n
		description = desc
		strength = strength_val
		speed = spd
		armor = arm
		health = hp
		primary_attack_type = primary_type
		special_ability_name = special_name
		special_ability_description = special_desc
		ultimate_ability_name = ultimate_name
		ultimate_ability_description = ultimate_desc
		sprite_path = sprite
		vfx_primary = vfx_prim
		vfx_special = vfx_spec
		vfx_ultimate = vfx_ult
		vfx_dodge = vfx_d

# Static array of 4 medieval fantasy characters
static var characters: Array[Character] = []

# Initialize characters data
static func _static_init():
	characters = [
		Character.new(
			"Knight",
			"A holy paladin wielding sword and shield with divine protection",
			9, 7, 8, 8,
			"melee",
			"Divine Shield",
			"Creates a protective barrier that heals and damages nearby enemies",
			"Divine Storm",
			"Massive divine energy blast that heals and damages all enemies",
			"res://assets/characters/knight/sprites/",
			"",
			"",
			"",
			""
		),
		Character.new(
			"Berserker",
			"A fierce warrior who becomes stronger as battle intensifies",
			10, 7, 4, 8,
			"melee",
			"Blood Rage",
			"Sacrifices health for massive damage and attack speed boost",
			"Berserker's Wrath",
			"Large shockwave that damages all nearby enemies",
			"res://assets/characters/berserker/Sprites/",
			"",
			"",
			"",
			""
		),
		Character.new(
			"Huntress",
			"A skilled archer with deadly precision and trap-setting abilities",
			7, 8, 4, 7,
			"ranged",
			"Piercing Shot",
			"Homing shot that seeks enemies and pierces through targets",
			"Rain of Arrows",
			"Massive barrage of arrows that fall over a large area",
			"res://assets/characters/huntress/Sprites/",
			"",
			"",
			"",
			""
		),
		Character.new(
			"Wizard",
			"A wise sorcerer wielding powerful elemental magic and arcane knowledge",
			8, 8, 6, 6,
			"ranged",
			"Arcane Orb",
			"Swirling magical orb that explodes on impact",
			"Meteor Storm",
			"Multiple meteors rain down over a massive area",
			"res://assets/characters/wizard/sprites/",
			"",
			"",
			"",
			""
		)
	]

# Get character by index
static func get_character(index: int) -> Character:
	if index >= 0 and index < characters.size():
		return characters[index]
	return null

# Get character by name
static func get_character_by_name(name: String) -> Character:
	for character in characters:
		if character.name == name:
			return character
	return null

# Get total number of characters
static func get_character_count() -> int:
	return characters.size()

# Get all character names
static func get_character_names() -> Array[String]:
	var names: Array[String] = []
	for character in characters:
		names.append(character.name)
	return names 
