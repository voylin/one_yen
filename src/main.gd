class_name Main
extends PanelContainer
## Values get stored in int, even values like 12.40 EUR will get stored as 1240.

signal on_display_scaled(ui_scale: float)

const PATH: String = "user://data"

const COLOR_SAVED: Color = Color.WHITE
const COLOR_UNSAVED: Color = Color.RED
const COLOR_POSITIVE: Color = Color.DARK_GREEN
const COLOR_NEGATIVE: Color = Color.DARK_RED


static var instance: Main


@export var button_save: Button

@export var option_button_year: OptionButton
@export var option_button_month: OptionButton

@export var text_edit_memo: TextEdit

@export_group("Tree's")
@export var tree_monthly_income: Tree
@export var tree_monthly_expenses: Tree
@export var tree_summary: Tree
@export var tree_total: Tree
@export var tree_receipts: Tree


#---- YEAR/MONTH DATA ---------------------------------------------------------
var ids: PackedInt32Array ## 202601 (Year-month).
var memos: PackedStringArray ## Monthly memos.
var monthly_income: Array[PackedInt64Array] ## [[0, ...], ...] - 5 entries.
var monthly_expenses: Array[PackedInt64Array] ## [[0, ...], ...] - 10 entries.

#---- YEAR SOURCES ------------------------------------------------------------
# Income sources and monthly expenses don't change each year.
# There is a max of 5 income sources which can be set, and a max of 10 monthly
# expenses which can be set.
var monthly_income_sources: Dictionary[int, PackedStringArray] ## { year + month date: [5 sources]}.
var monthly_expense_sources: Dictionary[int, PackedStringArray] ## { year + month date: [10 sources]}.

#---- RECEIPT DATA ------------------------------------------------------------
var receipt_ids: PackedInt32Array ## Incremented unique number.
var receipt_dates: PackedInt32Array ## 20260101 (Year-month-day).
var descriptions: PackedStringArray ## Purchase/Income description
var expense_amount: PackedInt64Array ## Amount paid.
var income_amount: PackedInt64Array ## Amount received.

var current_receipt_id: int = 0 ## Will always get +1 to not cause issues.

#---- SETTINGS ----------------------------------------------------------------
var setting_currency_symbol: String = "¥"
var setting_currency_separator: String = "," ## For separating large amounts (1.000).
var setting_currency_decimal_separator: String = "" ## If empty, currency doesn't use decimals.
var setting_currency_prefix: bool = true ## true = prefix, false = suffix.
var setting_language: String = "en"
var setting_theme_base_color: Color = Color.SEASHELL
var setting_theme_accent_color: Color = Color.SEA_GREEN
var setting_display_scale: float = 1.0

#---- PRIVATE VARS ------------------------------------------------------------
var _password: String = "" ## Password for the file. If password is lost ... too bad.
var _current_index: int = 0 ## The currently viewed ids index.
var _current_date: int = 0 ## The currently viewed date.



func _ready() -> void:
	if !instance:
		instance = self
	get_window().min_size = Vector2i(1150, 640)

	tree_monthly_income.item_edited.connect(_on_monthly_income_item_edited)
	tree_monthly_expenses.item_edited.connect(_on_monthly_expenses_item_edited)

	tree_monthly_income.set_column_title(0, tr("Income source", &"Tree monthly income header"))
	tree_monthly_income.set_column_title(1, tr("Amount", &"Tree monthly income header"))

	tree_monthly_expenses.set_column_title(0, tr("Fixed expenses", &"Tree monthly expenses header"))
	tree_monthly_expenses.set_column_title(1, tr("Cost", &"Tree monthly expenses header"))

	tree_summary.set_column_title(0, tr("Summary", &"Tree summary header"))
	tree_summary.set_column_title(1, tr("Total", &"Tree summary header"))

	tree_total.set_column_title(0, tr("Year's total", &"Tree total header"))
	tree_total.set_column_title(1, tr("Month's total", &"Tree total header"))

	tree_receipts.set_column_title(0, tr("Day", &"Tree receipts header"))
	tree_receipts.set_column_title(1, tr("Description", &"Tree receipts header"))
	tree_receipts.set_column_title(2, tr("Income", &"Tree receipts header"))
	tree_receipts.set_column_title(3, tr("Expense", &"Tree receipts header"))
	tree_receipts.set_column_expand(0, false)
	tree_receipts.set_column_custom_minimum_width(0, 40)
	tree_receipts.set_column_expand(2, false)
	tree_receipts.set_column_custom_minimum_width(2, 80)
	tree_receipts.set_column_expand(3, false)
	tree_receipts.set_column_custom_minimum_width(3, 80)
	tree_receipts.item_activated.connect(_on_receipt_item_activated)

	load_data()
	update_settings()


func update_settings() -> void:
	TranslationServer.set_locale(setting_language)
	scale_display(setting_display_scale)


func scale_display(ui_scale: float) -> void:
	var template: Theme = load("uid://bx4m4dhs6t40")
	var new_theme: Theme = template.duplicate(true)

	ThemeUpdater.apply_scale(new_theme, ui_scale)
	self.theme = new_theme
	on_display_scaled.emit(ui_scale)


#---- Data handling ----

func save_data() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	var data: Dictionary[String, Variant] = {
			#--- Year/month data ---
			"ids": ids,
			"memos": memos,
			"monthly_income": monthly_income,
			"monthly_expenses": monthly_expenses,

			#--- YEAR SOURCES ---
			"monthly_income_sources": monthly_income_sources,
			"monthly_expense_sources": monthly_expense_sources,

			#--- Receipts data ---
			"receipt_ids": receipt_ids,
			"receipt_dates": receipt_dates,
			"descriptions": descriptions,
			"expense_amount": expense_amount,
			"income_amount": income_amount,
			"current_receipt_id": current_receipt_id,

			#--- SETTINGS ---
			"setting_currency_symbol": setting_currency_symbol,
			"setting_currency_separator": setting_currency_separator,
			"setting_currency_decimal_separator": setting_currency_decimal_separator,
			"setting_currency_prefix": setting_currency_prefix,
			"setting_language": setting_language,
			"setting_theme_base_color": setting_theme_base_color,
			"setting_theme_accent_color": setting_theme_accent_color,
			"setting_display_scale": setting_display_scale,
	}
	if !file.store_string(var_to_str(data)):
		return printerr("Something went wrong storing data to file: ", PATH)
	button_save.modulate = COLOR_SAVED
	button_save.text = tr("Save", &"Save button text")


func load_data() -> void:
	if !FileAccess.file_exists(PATH):
		return _after_load_data()

	var file: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if file.get_32() == 0x43454447: # Godot's magic number for pass encrypted.
		file.close() # File is encrypted.
		var password_scene: PackedScene = load("uid://b7mynmv77kcqs")
		var password_node: Window = password_scene.instantiate()
		add_child(password_node)
		password_node.popup_centered()
	else:
		_load_data() # Continue loading data as file isn't encrypted.


func _load_data() -> void:
	var file: FileAccess
	if _password.is_empty():
		file = FileAccess.open(PATH, FileAccess.READ)
	else:
		file = FileAccess.open_encrypted_with_pass(PATH, FileAccess.READ, _password)

	var data: Dictionary = str_to_var(file.get_as_text())
	for key: String in data.keys():
		set(key, data[key])
	_after_load_data()


func _after_load_data() -> void:
	# Collecting list of all years which have data and populate option button.
	var current_year: int = Time.get_date_dict_from_system().year
	var current_year_added: bool = false

	option_button_year.clear()
	for id: int in ids: # Each id is build with year-month (202601).
		var year: int = floori(id / 100.0)
		option_button_year.add_item(str(year), year)
		if current_year == year:
			current_year_added = true
	if !current_year_added:
		# When the current year isn't added, we add the year with all months.
		_add_year(current_year)

	# Setting up the UI.
	var date: Dictionary = Time.get_date_dict_from_system()
	for index: int in option_button_year.item_count:
		if int(option_button_year.get_item_text(index)) == date.year:
			option_button_year.selected = index
			break

	_refresh_option_button_year()
	_on_option_button_item_selected()


#---- Handling - Memo's ----

func _on_memo_text_edit_text_changed() -> void:
	if _current_index > memos.size():
		memos.resize(_current_index) # Shouldn't happen, just in case.
	memos[_current_index] = text_edit_memo.text
	_unsaved_changes()


#---- Handling - monthly income/expenses ----

func _on_monthly_income_item_edited() -> void:
	var item: TreeItem = tree_monthly_income.get_selected()
	if not item:
		return

	# TODO: Update amount in tree based on setting_currency_separator if we need to add ','.
	var idx: int = item.get_index()
	if idx < monthly_income_sources[_current_date].size():
		monthly_income_sources[_current_date][idx] = item.get_text(0)
		monthly_income[_current_index][idx] = int(item.get_text(1))
		_unsaved_changes()


func _on_monthly_expenses_item_edited() -> void:
	var item: TreeItem = tree_monthly_expenses.get_selected()
	if not item:
		return

	# TODO: Update amount in tree based on setting_currency_separator if we need to add ','.
	var idx: int = item.get_index()
	if idx < monthly_expense_sources[_current_date].size():
		monthly_expense_sources[_current_date][idx] = item.get_text(0)
		monthly_expenses[_current_index][idx] = int(item.get_text(1))
		_unsaved_changes()


#---- Handling - Receipts ----

func add_receipt(date: int, desc: String, income: int, expense: int) -> void:
	var year_month: int = floori(date / 100.0)
	if !ids.has(year_month):
		_add_year(floori(year_month / 100.0))

	receipt_ids.append(current_receipt_id)
	receipt_dates.append(date)
	descriptions.append(desc)
	income_amount.append(income)
	expense_amount.append(expense)

	current_receipt_id += 1 # Increase for next receipt.
	_load_receipts() # For updating the UI.
	_unsaved_changes()


func update_receipt(index: int, date: int, desc: String, income: int, expense: int) -> void:
	if index < 0 or index >= receipt_dates.size():
		return
	var year_month: int = floori(date / 100.0) # Add year if doesn't exist.
	if !ids.has(year_month):
		_add_year(floori(year_month / 100.0))
		_refresh_option_button_year()

	receipt_dates[index] = date
	descriptions[index] = desc
	income_amount[index] = income
	expense_amount[index] = expense
	_load_receipts()
	_unsaved_changes()


func delete_receipt(index: int) -> void:
	if index < 0 or index >= receipt_dates.size():
		return
	receipt_ids.remove_at(index)
	receipt_dates.remove_at(index)
	descriptions.remove_at(index)
	income_amount.remove_at(index)
	expense_amount.remove_at(index)
	_load_receipts()
	_unsaved_changes()


func _on_receipt_item_activated() -> void:
	var item: TreeItem = tree_receipts.get_selected()
	var index: int = item.get_metadata(0)
	if index == -1:
		_open_popup_panel("uid://cd5ss8wxdm763")
		return
	var edit_scene: PackedScene = load("res://menus/edit_receipt_menu.tscn")
	var edit_menu: EditReceiptMenu = edit_scene.instantiate()
	add_child(edit_menu)
	edit_menu.popup_centered()
	edit_menu.setup(index, receipt_dates[index], descriptions[index], income_amount[index], expense_amount[index])


#---- Buttons ----

## This is basically a "load the entire UI" kinda function at this point.
func _on_option_button_item_selected() -> void:
	_current_date = get_year() * 100 + get_month()
	_current_index = ids.find(_current_date)
	_load_memo()
	_load_income()
	_load_monthly_expenses()
	_load_receipts()
	_update_amounts()


func _open_popup_panel(uid: String) -> void:
	var popup_scene: PackedScene = load(uid)
	var popup_node: Window = popup_scene.instantiate()
	add_child(popup_node)
	popup_node.popup_centered()


#---- Loaders ----

func _load_memo() -> void:
	var date: int = get_year() * 100 + get_month()
	var index: int = ids.find(date)
	if index != -1:
		text_edit_memo.text = memos[index]


func _load_income() -> void:
	tree_monthly_income.clear()
	var root: TreeItem = tree_monthly_income.create_item()
	var empty: String = format_currency(0)

	for index: int in monthly_income_sources[_current_date].size():
		var tree_item: TreeItem = root.create_child()
		var source: String = monthly_income_sources[_current_date][index]
		var amount: String = format_currency(monthly_income[_current_index][index])
		tree_item.set_text(0, source)
		if amount != empty:
			tree_item.set_text(1, amount)
			tree_item.set_tooltip_text(1, amount)
		tree_item.set_editable(0, true)
		tree_item.set_editable(1, true)
		tree_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)


func _load_monthly_expenses() -> void:
	tree_monthly_expenses.clear()
	var root: TreeItem = tree_monthly_expenses.create_item()
	var empty: String = format_currency(0)

	for index: int in monthly_expense_sources[_current_date].size():
		var tree_item: TreeItem = root.create_child()
		var source: String = monthly_expense_sources[_current_date][index]
		var amount: String = format_currency(monthly_expenses[_current_index][index])
		tree_item.set_text(0, source)
		if amount != empty:
			tree_item.set_text(1, amount)
		tree_item.set_editable(0, true)
		tree_item.set_editable(1, true)
		tree_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)


func _load_receipts() -> void:
	tree_receipts.clear()
	var root: TreeItem = tree_receipts.create_item()

	var indexes: Array = []
	for index: int in receipt_dates.size():
		if floori(receipt_dates[index] / 100.0) == _current_date:
			indexes.append(index)
	indexes.sort_custom(_sort_receipts)

	for index: int in indexes:
		var tree_item: TreeItem = root.create_child()
		var day: int = receipt_dates[index] % 100
		tree_item.set_metadata(0, index)
		tree_item.set_text(0, "%02d" % day)
		tree_item.set_text(1, descriptions[index])

		if income_amount[index] > 0:
			tree_item.set_text(2, format_currency(income_amount[index]))
		if expense_amount[index] > 0:
			tree_item.set_text(3, format_currency(expense_amount[index]))

		tree_item.set_tooltip_text(1, descriptions[index])
		tree_item.set_tooltip_text(2, format_currency(income_amount[index]))
		tree_item.set_tooltip_text(3, format_currency(expense_amount[index]))
		tree_item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)
		tree_item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)
		tree_item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_RIGHT)
		tree_item.set_selectable(0, false)
		tree_item.set_selectable(1, false)
		tree_item.set_selectable(2, false)
		tree_item.set_selectable(3, false)

	if indexes.size() < 30: # Having some empty entries makes UI look cleaner.
		for i: int in 30 - indexes.size():
			var empty: TreeItem = root.create_child()
			empty.set_selectable(0, false)
			empty.set_metadata(0, -1)
	_update_amounts()


func _sort_receipts(index_a: int, index_b: int) -> bool:
	return receipt_dates[index_a] < receipt_dates[index_b]


## Update the total year amount of what the total is at that month, and update
## the month amount of the current viewing month.
func _update_amounts() -> void:
	var year: int = get_year()

	var year_total: int = 0
	var month_total: int = 0
	var month_income_receipts: int = 0
	var month_expense_receipts: int = 0

	for index: int in receipt_dates.size():
		var receipt_date: int = floori(receipt_dates[index] / 100.0)
		if floori(receipt_date / 100.0) != year or receipt_date > _current_date:
			continue # Out of scope.

		var income: int = income_amount[index]
		var expense: int = expense_amount[index]
		var total: int = income + expense

		if receipt_date < _current_date:
			year_total += total
		elif receipt_date == _current_date:
			year_total += total
			month_total += total
			month_income_receipts += income
			month_expense_receipts += expense

	var month_fixed_income: int = 0
	var month_fixed_expenses: int = 0
	for i: int in monthly_income[_current_index].size():
		month_fixed_income += monthly_income[_current_index][i]
	for i: int in monthly_expenses[_current_index].size():
		month_fixed_expenses += monthly_expenses[_current_index][i]

	tree_summary.clear()
	var root: TreeItem  = tree_summary.create_item()
	var items: Array = [
			[tr("Fixed income", &"Tree summary"), month_fixed_income],
			[tr("Fixed expenses", &"Tree summary"), month_fixed_expenses],
			[tr("Receipt income", &"Tree summary"), month_income_receipts],
			[tr("Receipt expenses", &"Tree summary"), month_expense_receipts]]

	for item: Array in items:
		var tree_item: TreeItem = root.create_child()
		var category: String = item[0]
		var amount_int: int = item[1]
		var amount_str: String = format_currency(amount_int)
		tree_item.set_text(0, category)
		tree_item.set_text(1, amount_str)
		tree_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
		tree_item.set_tooltip_text(1, amount_str)

	tree_total.clear()
	var item: TreeItem = tree_total.create_item().create_child()
	item.set_text(0, format_currency(year_total))
	item.set_text(1, format_currency(month_total))
	item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_RIGHT)
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	item.set_custom_bg_color(0, COLOR_POSITIVE if year_total >= 0 else COLOR_NEGATIVE)
	item.set_custom_bg_color(1, COLOR_POSITIVE if month_total >= 0 else COLOR_NEGATIVE)


#---- Helper functions ----

func get_year() -> int:
	return option_button_year.get_selected_id() # The id is the year.


func get_month() -> int:
	return option_button_month.get_selected_id() + 1


func _refresh_option_button_year() -> void:
	var years: PackedInt32Array = []
	for index: int in option_button_year.item_count:
		years.append(option_button_year.get_item_id(index))
	years.sort()
	option_button_year.clear()
	for year: int in years:
		option_button_year.add_item(str(year), year)


func _unsaved_changes() -> void:
	button_save.text = tr("Save", &"Save button text") + "*"
	button_save.modulate = COLOR_UNSAVED


func _add_year(year: int) -> void:
	var full_year: int = year * 100
	for i: int in 12:
		var id: int = full_year + i + 1 # 202601 (Year-month).
		ids.append(id)
		memos.append("")

		monthly_income.append([])
		monthly_expenses.append([])
		monthly_income[-1].resize(5)
		monthly_expenses[-1].resize(10)

		monthly_income_sources[id] = []
		monthly_expense_sources[id] = []
		monthly_income_sources[id].resize(5)
		monthly_expense_sources[id].resize(10)
	option_button_year.add_item(str(year), year)


func format_currency(value: int) -> String:
	var decimal_str: String = ""
	var whole: int = value

	# Split into whole and decimal parts if decimals are used.
	if not setting_currency_decimal_separator.is_empty():
		whole = floori(value / 100.0)
		var cents: int = value % 100
		decimal_str = setting_currency_decimal_separator + "%02d" % cents

	var whole_str: String = str(whole)
	var formatted: String = ""

	# Apply thousand separators.
	if setting_currency_separator.is_empty():
		formatted = whole_str
	else:
		var count: int = 0
		for i: int in range(whole_str.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				formatted = setting_currency_separator + formatted
			formatted = whole_str[i] + formatted
			count += 1
	formatted += decimal_str

	# Add symbol.
	if setting_currency_prefix:
		return setting_currency_symbol + formatted
	else:
		return "%s %s" % [formatted, setting_currency_symbol]
