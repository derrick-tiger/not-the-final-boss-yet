extends CanvasLayer

@export_file("*.tscn") var initial_scene: String


func _ready() -> void:
	$Screen/CenterContainer/Menu/PlayButton.grab_focus()


func _on_play_button_pressed() -> void:
	$Screen/CenterContainer/Menu/PlayButton.disabled = true
	SceneLoader.load_scene(initial_scene)
