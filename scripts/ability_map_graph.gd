extends GraphEdit

const db_path := "res://assets/dao.sqlite"
const unselected_color := Color.WHITE
const selected_color := Color.GREEN
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
func tree_selected(tree: String):
	# Before we can delete GraphNodes, we need to disconnect them. 
	# The connections get upset and throw an error for each end of the connection
	# if the GraphNode is deleted beforehand
	for con in get_connection_list():
		disconnect_node(con.from, con.from_port, con.to, con.to_port)
	for child in get_children():
		if child is GraphNode:
			remove_child(child)
			child.queue_free()
		if child is Panel:
			remove_child(child)
			child.queue_free()
	
	instantiate_dao_from_db(tree)

func instantiate_dao_from_db(tree: String):
	var db := SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("SELECT tiers.name, tier, parent, prerequisites FROM tiers RIGHT JOIN dao ON dao.name=tiers.name WHERE path LIKE '%" + str(tree) + "%' ORDER BY tier DESC, path ASC, tiers.name ASC")
	var length := len(db.query_result)
	var num_in_tier := {}
	for i in 6:
		num_in_tier[i] = 0
	
	for i in length:
		var dao := str(db.query_result[i]["name"])
		var parent := str(db.query_result[i]["parent"])
		var tier: int = db.query_result[i]["tier"]
		var prerequisites := str(db.query_result[i]["prerequisites"])

		if not get_node_or_null(dao):
			num_in_tier[tier] += 1
			add_dao(dao, tier, num_in_tier, prerequisites)
		
		if parent != "<null>":
			connect_node(dao, 0, parent, 0)
			
	db.close_db()

func add_dao(dao: String, tier: int, num_in_tier: Dictionary, prerequisites: String = ""):
	# Set up basic settings for new GraphNode that represents a single dao
	var newDao := GraphNode.new()
	newDao.name = dao
	newDao.title = dao
	newDao.draggable = false
	newDao.resizable = false
	newDao.show_close = false
	newDao.position_offset.x = tier * 300
	newDao.position_offset.y = num_in_tier[tier] * 70 * tier
	
	if tier > 1:
		newDao.tooltip_text = "Name: " + dao + "\nTier: " + str(tier) + "\nType: Filler" + "\nPrerequisites: Own at least one connected Tier " + str(tier-1) + " Dao."
	else:
		newDao.tooltip_text = "Name: " + dao + "\nTier: " + str(tier) + "\nType: Filler" + "\nPrerequisites: The Skill " + prerequisites

	# Override the stylebox for GraphNodes. This is complicated and annoying when we want to
	# programmatically override the background color of the node. Normally, we could use a theme
	# for the vast majority of this, but the stylebox settings for GraphNodes when creating the new
	# theme don't contain the correct settings, so we have to set all the relevant settings manually
	# any time we want to programmatically change a single poperty of the StyleBoxFlat.
	var frame := StyleBoxFlat.new()
	
	# This is a recreation of the default values used by Godot for GraphNodes
	frame.border_width_top = 30
	frame.corner_radius_top_left = 3
	frame.corner_radius_top_right = 3
	frame.corner_radius_bottom_left = 3
	frame.corner_radius_bottom_right = 3
	frame.corner_detail = 5
	frame.content_margin_left = 18
	frame.content_margin_top = 42
	frame.content_margin_right = 18
	frame.content_margin_bottom = 12
	
	# Custom Settings. Who doesn't love drop shadows?
	frame.shadow_color = "#00000044"
	frame.shadow_size = 6
	frame.shadow_offset.x=4
	frame.shadow_offset.y=4
	
	# Colors below are from the cretaceous-16 swatch from Lospec
	# border_color = Title Bar
	# bg_color = Lower Content Section
	match tier:
		1:
			frame.border_color = "#31343299" # Dark Grey
			frame.bg_color = "#323e42" # Dark Turquise
		2:
			frame.border_color = "#3a5f3b99" # Medium Green?
			frame.bg_color = "#516b4399" # Light-Medium Green?
		3:
			frame.border_color = "#67523999" # Dark Orange
			frame.bg_color = "#9e805c99" # Yellow-Tan
		4:
			frame.border_color = "#796c6499" # Light Red
			frame.bg_color = "#ac908699" # Lighter Red
		5:
			frame.border_color = "#62505599" # Desaturated Plum? Mauve? Who knows?
			frame.bg_color = "#7c454599" # Medium Red
	
	# Overwrite the stylebox with our custom one
	newDao.add_theme_stylebox_override("frame", frame)
	
	# This adds the handles (slot) to the GraphNode. Without it, adding 
	# connections is weird
	newDao.add_child(Control.new())
	
	# Don't put an input (left) connector slot on tier 1 nodes.
	if tier == 1:
		newDao.set_slot(0, false, 0, unselected_color, true, 0, unselected_color)
	else:
		newDao.set_slot(0, true, 0, unselected_color, true, 0, unselected_color)
	
	# Set up the ability to change connection colors when a node is selected
	newDao.connect("node_selected", _dao_selected)
	newDao.connect("node_deselected", _dao_deselected)
	
	add_child(newDao)

func set_dao_slot_color(dao: Node, color: Color, left: bool = true, right: bool = true):
	if left:
		dao.set_slot_color_left(0, color)
	if right:
		dao.set_slot_color_right(0, color)

func _dao_selected():
	var children = get_children()
	for child in children:
		if child.selected:
			set_dao_slot_color(child, selected_color)
			
			for con in get_connection_list():
				if con.to == child.name:
					set_dao_slot_color(get_node(str(con.from)), selected_color, false , true)
				if con.from == child.name:
					set_dao_slot_color(get_node(str(con.to)), selected_color, true, false)
			
func _dao_deselected():
	var children = get_children()
	for child in children:
		if child is GraphNode:
			if child.is_slot_enabled_right(0):
				if child.get_connection_output_color(0) == selected_color:
					set_dao_slot_color(child, unselected_color)
			if child.is_slot_enabled_left(0):
				if child.get_connection_input_color(0) == selected_color:
					set_dao_slot_color(child, unselected_color)
