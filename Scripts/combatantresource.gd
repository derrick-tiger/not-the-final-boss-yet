extends Resource
class_name CombatantResource

@export var max_health : int
@export var level : int = 1
@export var combatant_name : String
@export var is_enemy : bool
@export var attacks : Array[AttackResource]
@export_file("*.tscn") var scene: String
@export var simplified_frames : SpriteFrames
@export var atk : int
@export var def : int
@export var res : int
@export var item_drops : Dictionary[ItemData,int]
@export var pretaken_damage : int
