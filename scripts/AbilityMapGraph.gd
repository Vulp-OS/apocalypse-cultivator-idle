extends GraphEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	#get_zoom_hbox().visible = false
	instantiate_dao_map()
	arrange_nodes()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_connection_request(from_node, from_port, to_node, to_port):
	# Don't connect to input that is already connected
	push_warning(from_node)
	
	for con in get_connection_list():
		if con.to == to_node and con.to_port == to_port:
			return
	
	connect_node(from_node, from_port, to_node, to_port)

func instantiate_dao_map():
	var file = FileAccess.open("res://assets/daoConnections.txt", FileAccess.READ)
	
	while not file.eof_reached():
		var line = file.get_line()
		if line == "":
			continue
		else:
			var dao = line.get_slice(",",0)
			var parent = line.get_slice(",",1)
			if dao != "" and not get_node_or_null(dao):
				add_dao(dao)
			if parent != "" and not get_node_or_null(parent):
				add_dao(parent)
			
			connect_node(dao, 0, parent, 0)

func add_dao(dao):
	var newDao = GraphNode.new()
	print(dao)
	newDao.name = dao
	newDao.title = dao
	newDao.add_child(Control.new())
	newDao.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	newDao.connect("node_selected", _dao_selected)
	newDao.connect("node_deselected", _dao_deselected)
	
	add_child(newDao)

func _dao_selected():
	var children = get_children()
	for child in children:
		if child.selected:
			child.set_slot(0, true, 0, Color.YELLOW, true, 0, Color.YELLOW)
			
func _dao_deselected():
	var children = get_children()
	for child in children:
		if child.get_connection_input_color(0) == Color.YELLOW:
			child.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
