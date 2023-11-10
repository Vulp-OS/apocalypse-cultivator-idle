extends VBoxContainer

const db_path = "res://assets/dao.sqlite"
# Called when the node enters the scene tree for the first time.
func _ready():
	add_trees()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func add_trees():
	var bg = ButtonGroup.new()
	var db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("SELECT name FROM tiers WHERE path NOT LIKE '%/%'")
	var length = len(db.query_result)
	for i in length:
		var newPath = Button.new()
		newPath.toggle_mode = true
		newPath.button_group = bg
		newPath.text = db.query_result[i]["name"]
		newPath.connect("toggled", _button_toggled)
		get_node("HBoxContainer").add_child(newPath)

func _button_toggled(pressed):
	if pressed:
		var buttons = get_node("HBoxContainer").get_children()
		for button in buttons:
			if button.is_pressed():
				$dao_graph.tree_selected(button.text)
