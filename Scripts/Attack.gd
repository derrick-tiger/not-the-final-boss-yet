extends Resource
class_name AttackResource

@export var name : String
@export var damage : int
@export var crit_bonus : int
@export var mana_cost : int
enum type {MELEE, MAGIC}
@export var attack_type : type
@export var fx_frames : SpriteFrames
@export var projectile : Texture2D
