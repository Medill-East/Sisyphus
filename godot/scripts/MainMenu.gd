extends Control

const VERTICAL_SLICE_SCENE_PATH := "res://scenes/VerticalSlice.tscn"

@onready var play_button: Button = $Panel/Content/PlayButton
@onready var quit_button: Button = $Panel/Content/QuitButton


func _ready() -> void:
	play_button.pressed.connect(start_vertical_slice)
	quit_button.pressed.connect(quit_game)
	play_button.grab_focus()


func vertical_slice_scene_path() -> String:
	return VERTICAL_SLICE_SCENE_PATH


func start_vertical_slice() -> void:
	get_tree().change_scene_to_file(VERTICAL_SLICE_SCENE_PATH)


func quit_game() -> void:
	get_tree().quit()
