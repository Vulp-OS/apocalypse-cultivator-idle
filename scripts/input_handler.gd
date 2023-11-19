extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(_event):
	var nextscene = "res://scenes/main.tscn"
	var scene = get_tree().get_current_scene().name

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("ui_focus_next"):
		match scene:
			"Main":
				nextscene = "res://scenes/ui/ability_map.tscn"
			"AbilityMap":
				nextscene = "res://scenes/levels/test_level.tscn"
			"TestLevel":
				nextscene = "res://scenes/main.tscn"
		get_tree().change_scene_to_file(nextscene)
