extends GraphEdit

const db_path = "res://assets/dao.sqlite"
# Called when the node enters the scene tree for the first time.
func _ready():
	# Disable the GraphEdit control bar
	get_zoom_hbox().visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
		
# This is kind of being treated like a function responding to a signal. 
# We're not using signals because I didn't want to figure out how to make my own
# This is called when a button from the ButtonBar is toggled. It receives,
# as an argument, the name of the button (which is a top-level Dao in SQLite)
func tree_selected(tree):
	# Before we can delete GraphNodes, we need to disconnect them. 
	# The connections get upset and throw an error for each end of the connection
	# if the GraphNode is deleted beforehand
	for con in get_connection_list():
		disconnect_node(con.from, con.from_port, con.to, con.to_port)
	for child in get_children():
		if (child is GraphNode):
			remove_child(child)
			child.queue_free()
	
	instantiate_dao_from_db(tree)
	
	# This is a built-in function for the GraphEdit node.
	# We either need to fix it, or write something ourselves that works better.
	# TODO: don't use this
	# arrange_nodes()

func instantiate_dao_from_db(tree):
	var db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("SELECT name, tier, parent FROM tiers WHERE path LIKE '%" + str(tree) + "%' ORDER BY tier DESC, path ASC, name ASC")
	var length = len(db.query_result)
	var num_in_tier = Dictionary()
	for i in 6:
		num_in_tier[i] = 0
	
	for i in length:
		var dao = str(db.query_result[i]["name"])
		var parent = str(db.query_result[i]["parent"])
		var tier = db.query_result[i]["tier"]

		if not get_node_or_null(dao):
			num_in_tier[tier] += 1
			add_dao(dao, tier, num_in_tier[tier])
		
		if parent != "<null>":
			connect_node(dao, 0, parent, 0)

	db.close_db()

func add_dao(dao, tier, y_offset_factor):
	# Set up basic settings for new GraphNode that represents a single dao
	var newDao = GraphNode.new()
	newDao.name = dao
	newDao.title = dao
	newDao.draggable = false
	newDao.resizable = false
	newDao.show_close = false
	newDao.position_offset.x = tier * 300
	newDao.position_offset.y = y_offset_factor * 100
	
	# This adds the handles (slot) to the GraphNode. Without it, adding 
	# connections is weird
	newDao.add_child(Control.new())

	var tierLabel = Label.new()
	tierLabel.text = "Tier: " + str(tier)

	# This container helps make sure that nodes are arranged predictably
	var textContainer = VBoxContainer.new()	
	textContainer.add_child(tierLabel)
	
	newDao.add_child(textContainer)
	
	# Don't put an input (left) connector slot on tier 1 nodes.
	if tier == 1:
		newDao.set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)
	else:
		newDao.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	
	# Set up the ability to change connection colors when a node is selected
	newDao.connect("node_selected", _dao_selected)
	newDao.connect("node_deselected", _dao_deselected)
	
	add_child(newDao)

func _dao_selected():
	var children = get_children()
	for child in children:
		if child.selected:
			var left_enabled = child.is_slot_enabled_left(0)
			child.set_slot(0, left_enabled, 0, Color.GREEN, true, 0, Color.GREEN)
			
			for con in get_connection_list():
				if con.to == child.name:
					var leftNode = get_node(str(con.from))
					var left_left_enabled = leftNode.is_slot_enabled_left(0)
					leftNode.set_slot(0, left_left_enabled, 0, Color.WHITE, true, 0, Color.GREEN)
				if con.from == child.name:
					var rightNode = get_node(str(con.to))
					rightNode.set_slot(0, true, 0, Color.GREEN, true, 0, Color.WHITE)
			
func _dao_deselected():
	var children = get_children()
	for child in children:
		if child.get_connection_output_color(0) == Color.GREEN && child is GraphNode:
			var left_enabled = child.is_slot_enabled_left(0)
			child.set_slot(0, left_enabled, 0, Color.WHITE, true, 0, Color.WHITE)
		if child.is_slot_enabled_left(0):
			if child.get_connection_input_color(0) == Color.GREEN && child is GraphNode:
				child.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
