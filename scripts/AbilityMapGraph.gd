extends GraphEdit

const db_path = "res://assets/dao.sqlite"
# Called when the node enters the scene tree for the first time.
func _ready():
	get_zoom_hbox().visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
		
func tree_selected(tree):
	for con in get_connection_list():
		disconnect_node(con.from, con.from_port, con.to, con.to_port)
	for child in get_children():
		remove_child(child)
		
	instantiate_dao_from_db(tree)
	arrange_nodes()

func instantiate_dao_from_db(tree):
	var db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("SELECT name, tier, parent FROM tiers WHERE path LIKE '%" + str(tree) + "%' ORDER BY tier DESC;")
	var length = len(db.query_result)
	for i in length:
		var dao = str(db.query_result[i]["name"])
		var parent = str(db.query_result[i]["parent"])
		var tier = db.query_result[i]["tier"]

		if not get_node_or_null(dao):
			add_dao(dao, tier)

		if parent != "<null>":
			if not get_node_or_null(parent):
				add_dao(parent, tier)
			connect_node(dao, 0, parent, 0)

	db.close_db()

func add_dao(dao, tier):
	var newDao = GraphNode.new()
	newDao.name = dao
	newDao.title = dao
	newDao.add_child(Control.new())
	
	var tierLabel = Label.new()
	tierLabel.text = "Tier: " + str(tier)
	
	newDao.add_child(tierLabel)
	if tier == 1:
		newDao.set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)
	else:
		newDao.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	
	
	newDao.connect("node_selected", _dao_selected)
	newDao.connect("node_deselected", _dao_deselected)
	
	add_child(newDao)

func _dao_selected():
	var children = get_children()
	for child in children:
		if child.selected:
			var left_enabled = child.is_slot_enabled_left(0)
			
			child.set_slot(0, left_enabled, 0, Color.GREEN, true, 0, Color.GREEN)
			
func _dao_deselected():
	var children = get_children()
	for child in children:
		if child.get_connection_output_color(0) == Color.GREEN:
			var left_enabled = child.is_slot_enabled_left(0)
			child.set_slot(0, left_enabled, 0, Color.WHITE, true, 0, Color.WHITE)
