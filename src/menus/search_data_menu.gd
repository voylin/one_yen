class_name SearchDataMenu
extends Window

@export var line_edit_search: LineEdit
@export var tree: Tree



func _ready() -> void:
	close_requested.connect(queue_free)

	tree.set_column_title(0, tr("Date"))
	tree.set_column_title(1, tr("Description"))
	tree.set_column_title(2, tr("Income"))
	tree.set_column_title(3, tr("Expense"))

	tree.set_column_expand(0, false)
	tree.set_column_custom_minimum_width(0, 90)
	tree.set_column_expand(2, false)
	tree.set_column_custom_minimum_width(2, 60)
	tree.set_column_expand(3, false)
	tree.set_column_custom_minimum_width(3, 60)

	_on_search_line_edit_text_changed("")


func _on_search_line_edit_text_changed(new_text: String) -> void:
	tree.clear()
	var root: TreeItem = tree.create_item()
	var search_term = new_text.to_lower()

	for index: int in Main.instance.receipt_dates.size():
		var description: String = Main.instance.descriptions[index]
		var income: int = Main.instance.income_amount[index]
		var expense: int = Main.instance.expense_amount[index]

		var match_description: bool = search_term.is_empty() or search_term in description.to_lower()
		var match_value: bool = false
		if search_term.is_valid_int():
			match_value = str(income) == search_term or str(expense) == search_term

		if match_description or match_value:
			var item: TreeItem = root.create_child()
			var date: String = str(Main.instance.receipt_dates[index]).insert(6, "-").insert(4, "-")

			item.set_text(0, date)
			item.set_text(1, description)
			item.set_text(2, Main.instance.format_currency(income) if income > 0 else "")
			item.set_text(3, Main.instance.format_currency(expense) if expense > 0 else "")

			if income > 0: item.set_custom_color(2, Main.COLOR_POSITIVE)
			if expense > 0: item.set_custom_color(3, Main.COLOR_NEGATIVE)
