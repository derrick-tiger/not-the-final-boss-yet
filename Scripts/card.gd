extends Control

@onready var name_label : = $Name
@onready var description_label : = $Description
@onready var image : = $Image
@onready var outline : = $Outline
@onready var button : = $Button

var assigned_data : CardData

var active : bool = true

signal selected(data:CardData,node)

func setup_card(data : CardData):
	image.texture = data.card_image
	name_label.text = data.card_name
	description_label.text = data.description
	assigned_data = data

func _on_button_pressed() -> void:
	active = false
	button.visible = false
	outline.visible = false
	selected.emit(assigned_data,self)
