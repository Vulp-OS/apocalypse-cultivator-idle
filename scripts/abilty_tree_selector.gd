extends VBoxContainer

const db_path := "res://assets/dao.sqlite"

# Called when the node enters the scene tree for the first time.
func _ready():
	add_tree_nav_buttons()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# Add a series of buttons to the top of the window that represent each top-level
# parent in the Dao Tree.
func add_tree_nav_buttons():
	# Toggle-style buttons must be in a ButtonGroup together in order to
	# automatically un-toggle when a different button is clicked
	var bg := ButtonGroup.new()
	var db := SQLite.new()
	db.path = db_path
	db.open_db()
	
	# This finds all entries in the SQL view 'tiers' that don't have any other
	# dao besides themselves in the path column
	db.query("SELECT name FROM tiers WHERE path NOT LIKE '%/%'")
	var length := len(db.query_result)
	for i in length:
		var newPath := Button.new()
		newPath.toggle_mode = true
		newPath.button_group = bg
		newPath.text = db.query_result[i]["name"]
		newPath.connect("toggled", _button_toggled)
		get_node("ButtonBar").add_child(newPath)

# This is connected to all buttons created in the add_tree_nav_buttons() function
# it finds the button that was toggled down, and asks for that tree to be drawn
# in the script attached to the DaoGraph (GraphEdit) node
func _button_toggled(pressed: bool):
	if pressed:
		var buttons = get_node("ButtonBar").get_children()
		for button in buttons:
			if button.is_pressed():
				$DaoGraph.tree_selected(button.text)
