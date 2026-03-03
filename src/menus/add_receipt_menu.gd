class_name AddReceiptMenu
extends Window

@export var tree: Tree

@export var button_add_new: Button



func _ready() -> void:
	tree.set_column_title(0, "Year")
	tree.set_column_title(1, "Month")
	tree.set_column_title(2, "Day")
	tree.set_column_title(3, "Description")
	tree.set_column_title(4, "Income")
	tree.set_column_title(5, "Expense")

	tree.set_column_expand(0, false)
	tree.set_column_custom_minimum_width(0, 40)
	tree.set_column_expand(1, false)
	tree.set_column_custom_minimum_width(1, 40)
	tree.set_column_expand(2, false)
	tree.set_column_custom_minimum_width(2, 40)
	tree.set_column_expand(4, false)
	tree.set_column_custom_minimum_width(4, 60)
	tree.set_column_expand(5, false)
	tree.set_column_custom_minimum_width(5, 60)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and key_event.keycode == KEY_TAB:
			var current_focus: Control = get_viewport().gui_get_focus_owner()
			if current_focus == tree or tree.is_ancestor_of(current_focus):
				_handle_tree_tab_navigation(key_event.shift_pressed)


func _handle_tree_tab_navigation(is_shift: bool) -> void:
	var item: TreeItem = tree.get_selected()
	if not item:
		return

	var current_column: int = tree.get_selected_column()
	var next_column: int
	var next_item: TreeItem = item

	if is_shift: # Go backwards.
		next_column = current_column - 1
		if next_column < 0:
			next_column = 5 # Last column index.
			next_item = item.get_prev()
	else: # Go forwards.
		next_column = current_column + 1
		if next_column > 5: # Last column index passed.
			next_column = 0 # First column index.
			next_item = item.get_next()

	if next_item:
		next_item.select(next_column)
		tree.scroll_to_item(next_item)
		tree.edit_selected()
		get_viewport().set_input_as_handled()
	elif not is_shift and next_column == 0:
		button_add_new.grab_focus()


#---- Buttons ----

func _on_cancel_button_pressed() -> void:
	self.queue_free()


## Create a new tree item and set the year + month to save work typing it.
func _on_add_button_pressed() -> void:
	var root: TreeItem = tree.get_root()
	var id: int = root.get_child_count()
	var tree_item: TreeItem = root.create_child()

	for i: int in 6:
		tree_item.set_editable(i, true)

	if id == 0:
		# First item, get current date.
		var date: Dictionary = Time.get_date_dict_from_system()
		tree_item.set_text(0, str(date.year))
		tree_item.set_text(1, str(date.month))
	else:
		# Get year and month from previous entry.
		var prev: TreeItem = tree.get_root().get_child(id - 1)
		tree_item.set_text(0, prev.get_text(0))
		tree_item.set_text(1, prev.get_text(1))

	# Set focus to the empty day box.
	tree.grab_focus()
	tree_item.select(2)
	tree.edit_selected()


func _on_confirm_button_pressed() -> void:
	for tree_item: TreeItem in tree.get_root().get_children():
		# Getting date vars.
		var year: int = int(tree_item.get_text(0))
		var month: int = int(tree_item.get_text(1))
		var day: int = int(tree_item.get_text(2))

		# Getting needed data.
		var date: int = (year * 10000) + (month * 100) + day
		var desc: String = tree_item.get_text(3)
		var income: int = int(tree_item.get_text(4))
		var expense: int = int(tree_item.get_text(5))

		# Check if not invalid.
		if income > 0 or expense > 0:
			Main.instance.add_receipt(date, desc, income, expense)
	self.queue_free()
