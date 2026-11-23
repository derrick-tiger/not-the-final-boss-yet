extends Control

@onready var name_label : = $Name
@onready var description_label : = $Description
@onready var image : = $Image

var assigned_data : CardData

signal selected(data:CardData)

func setup_card(data : CardData):
	image.texture = data.card_image
	name_label.text = data.card_name
	description_label.text = data.description
	assigned_data = data

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit(assigned_data)
