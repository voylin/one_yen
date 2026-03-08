class_name EditReceiptMenu
extends Window

@export var tree: Tree


var _index: int = -1



func setup(index: int, date: int, desc: String, income: int, expense: int) -> void:
	close_requested.connect(queue_free)
	tree.item_edited.connect(_on_item_edited)

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

	_index = index
	var root: TreeItem = tree.create_item()
	var item: TreeItem = root.create_child()
	item.set_text(0, str(floori(date / 10000.0)))
	item.set_text(1, str(floori((date % 10000) / 1000.0)))
	item.set_text(2, str(date % 100))
	item.set_text(3, desc)
	item.set_text(4, Main.instance.format_currency(income))
	item.set_text(5, Main.instance.format_currency(expense))
	item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_text_alignment(4, HORIZONTAL_ALIGNMENT_RIGHT)
	item.set_text_alignment(5, HORIZONTAL_ALIGNMENT_RIGHT)
	tree.grab_focus()
	tree.set_selected(item, 3)
	await RenderingServer.frame_post_draw
	tree.edit_selected()


func _on_item_edited() -> void:
	var item: TreeItem = tree.get_selected()
	var column: int = tree.get_selected_column()
	if column == 4 or column == 5:
		var value: int = Main.instance.correct_input(item.get_text(column))
		item.set_text(column, Main.instance.format_currency(value))


func _on_cancel_button_pressed() -> void:
	queue_free()


func _on_delete_button_pressed() -> void:
	Main.instance.delete_receipt(_index)
	queue_free()


func _on_confirm_button_pressed() -> void:
	var item: TreeItem = tree.get_root().get_child(0)
	var desc: String = item.get_text(3)
	var income: int = Main.instance.correct_input(item.get_text(4))
	var expenses: int = Main.instance.correct_input(item.get_text(5))
	var date: int = int(item.get_text(0)) * 10000
	date += int(item.get_text(1)) * 100
	date += int(item.get_text(2))

	Main.instance.update_receipt(_index, date, desc, income, expenses)
	queue_free()
