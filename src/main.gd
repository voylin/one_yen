extends PanelContainer

# TODO: If any data changes, we should update the 'button_save'
#	button_save.modulate = COLOR_SAVED
#	button_save.text = "Save"


const PATH: String = "user://data"

const COLOR_SAVED: Color = Color.WHITE
const COLOR_UNSAVED: Color = Color.RED


@export var button_save: Button

@export var option_button_year: OptionButton
@export var option_button_month: OptionButton

@export var text_edit_memo: TextEdit

@export var tree_income: Tree
@export var tree_monthly_expenses: Tree
@export var tree_expenses: Tree
@export var tree_receipts: Tree

@export var label_year_amount: Label
@export var label_month_amount: Label


#---- YEAR/MONTH DATA ---------------------------------------------------------
var ids: PackedInt32Array ## 202601 (Year-month).
var memos: PackedStringArray ## Monthly memos.
var income_sources: Array[Dictionary] ## [{ Source: amount }].
var monthly_expenses: Array[Dictionary] ## [{ Source: amount }].


var receipt_ids: PackedInt32Array #---- RECEIPT DATA --------------------------
var receipt_dates: PackedInt32Array ## 20260101 (Year-month-day).
var descriptions: PackedStringArray ## Purchase/Income description
var expense_amount: PackedInt32Array ## Amount paid.
var income_amount: PackedInt32Array ## Amount received.
var paid_by_card: Array[bool] ## Paid by credit card or cash


var _current_index: int = 0 ## The currently viewed ids index.
var _current_date: int = 0 ## The currently viewed date.

var _current_receipt_id: int = 0 ## Will always get +1 to not cause issues.



func _ready() -> void:
	load_data() # Loading data if any + adding current year to option button.

	# Setting up the UI.
	var date: Dictionary = Time.get_date_dict_from_system()
	for index: int in option_button_year.item_count:
		if option_button_year.get_item_text(index) == date.year:
			# Setting the year and month.
			# - We have to emit the signal for the month so the UI gets updated.
			option_button_year.set_pressed_no_signal(index)
			option_button_month.set_pressed(date.month - 1)
			break


#---- Data handling ----

func save_data() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if !file.store_string(var_to_str({
		#--- Year/month data ---
		"ids": ids,
		"memos": memos,
		"income_sources": income_sources,
		"monthly_expenses": monthly_expenses,

		#--- Receipts data ---
		"receipt_ids": receipt_ids,
		"receipt_dates": receipt_dates,
		"descriptions": descriptions,
		"expense_amount": expense_amount,
		"income_amount": income_amount,
		"paid_by_card": paid_by_card,
	})): printerr("Something went wrong storing data to file: ", PATH)
	button_save.modulate = COLOR_SAVED
	button_save.text = "Save"


func load_data() -> void:
	# TODO: If encryption is added, when loading we should check if the file is
	# encrypted. If it is, we have to show a popup first to enter the password.
	if FileAccess.file_exists(PATH):
		var file: FileAccess = FileAccess.open(PATH, FileAccess.READ)
		if !FileAccess.get_open_error(): # Quick check for safety.
			var data: Dictionary = str_to_var(file.get_as_text())
			for key: String in data.keys():
				set(key, data[key])

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
		option_button_year.add_item(str(current_year), current_year)
	_refresh_option_button_year()


#---- Handling - Memo's ----

func _on_memo_text_edit_text_changed() -> void:
	memos[_current_index] = text_edit_memo.text
	_unsaved_changes()


#---- Handling - Receipts ----

func _add_receipt(date: int, desc: String, expense: int, income: int, card: bool) -> void:
	# Add data to receipt arrays.
	receipt_ids.append(_current_receipt_id)
	receipt_dates.append(date)
	descriptions.append(desc)
	expense_amount.append(expense)
	income_amount.append(income)
	paid_by_card.append(card)

	_current_receipt_id += 1 # Increase for next receipt.
	_load_receipts() # For updating the UI.


#---- Buttons ----

## This is basically a "load the entire UI" kinda function at this point.
func _on_option_button_item_selected() -> void:
	_current_date = _get_year() * 100 + _get_month()
	_current_index = ids.find(_current_date)
	_load_memo()
	_load_income()
	_load_monthly_expenses()
	_load_receipts()
	_update_amounts()


func _on_add_receipts_button_pressed() -> void:
	var add_receipt_node: PopupPanel = load("uid://cd5ss8wxdm763").instantiate()
	add_child(add_receipt_node)
	add_receipt_node.popup_centered()


func _on_search_data_button_pressed() -> void:
	var search_data_node: PopupPanel = load("uid://8a24yq231diy").instantiate()
	add_child(search_data_node)
	search_data_node.popup_centered()


func _on_export_data_button_pressed() -> void:
	var export_data_node: PopupPanel = load("uid://dmq7ckygnn8lx").instantiate()
	add_child(export_data_node)
	export_data_node.popup_centered()


func _on_settings_button_pressed() -> void:
	var settings_node: PopupPanel = load("uid://btinkb6jw6dn3").instantiate()
	add_child(settings_node)
	settings_node.popup_centered()


#---- Loaders ----

func _load_memo() -> void:
	var date: int = _get_year() * 100 + _get_month()
	var index: int = ids.find(date)
	if index != -1:
		text_edit_memo.text = memos[index]


func _load_income() -> void:
	pass


func _load_monthly_expenses() -> void:
	pass


func _load_receipts() -> void:
	var indexes: PackedInt32Array = []
	for index: int in receipt_dates:
		if floori(receipt_dates[index] / 100.0) == _current_date:
			indexes.append(index)
	# TODO: Sort data.
	# TODO: Load data into receipt tree.

	# TODO: After loading receipts, we have to update expenses.


## Update the total year amount of what the total is at that month, and update
## the month amount of the current viewing month.
func _update_amounts() -> void:
	var year: int = _get_year()
	var year_total: int = 0
	var month_total: int = 0
	for index: int in receipt_dates.size():
		var receipt_date: int = floori(receipt_dates[index] / 100.0)
		if floori(receipt_date / 100.0) != year:
			continue # Out of scope.

		var total: int = income_amount[index] - expense_amount[index]
		if receipt_date > _current_date:
			year_total += total
		if receipt_date == _current_date:
			year_total += total
			month_total += total

	label_year_amount.text = str(year_total) # TODO: Add curreny marking.
	label_month_amount.text = str(month_total) # TODO: Add curreny marking.


#---- Helper functions ----

func _get_year() -> int:
	return option_button_year.get_selected_id() # The id is the year.


func _get_month() -> int:
	return option_button_year.get_selected_id() + 1


func _refresh_option_button_year() -> void:
	var years: PackedInt32Array = []
	for index: int in option_button_year.item_count:
		years.append(option_button_year.get_item_id(index))
	years.sort()
	option_button_year.clear()
	for year: int in years:
		option_button_year.add_item(str(year), year)


func _unsaved_changes() -> void:
	button_save.text = "Save*"
	button_save.modulate = COLOR_UNSAVED
