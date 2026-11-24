extends Resource
class_name CardData

@export var card_image : Texture2D
@export var card_name : String
@export var slime : CombatantResource
@export var description : String
@export var moves : Array[AttackResource]
@export var def_bonus : int
@export var atk_bonus : int
@export_file("*.res","*.tres") var evolutions : Array[String]
