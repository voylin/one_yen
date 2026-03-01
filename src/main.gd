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


#---- YEAR/MONTH DATA ---------------------------------------------------------
var ids: PackedInt64Array ## 202601 (Year-month).
var memos: PackedStringArray ## Monthly memos.
var income: Dictionary[String, int] ## Income sources.
var monthly_expenses: Dictionary[String, int] ## Monthly expenses (rent, ...).


var receipt_ids: PackedInt64Array #---- RECEIPT DATA --------------------------
var receipt_dates: PackedInt64Array ## 20260101 (Year-month-day).
var descriptions: PackedStringArray ## Purchase/Income description
var expense_amount: PackedInt64Array ## Amount paid.
var income_amount: PackedInt64Array ## Amount received.
var paid_by_card: bool ## Paid by credit card or cash



func _ready() -> void:
	load_data()
	var date: Dictionary = Time.get_date_dict_from_system()

	# Setting the year.
	for index: int in option_button_year.item_count:
		if option_button_year.get_item_text(index) == date.year:
			option_button_year.set_pressed_no_signal(index)
			break
	if option_button_year.selected == -1:
		option_button_year.add_item(date.year, date.year)

	# Setting the month.
	option_button_month.set_pressed_no_signal(date.month - 1)

	# TODO: Load memo data
	_load_memo()



#---- Data handling ----

func save_data() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if !file.store_string(var_to_str({
		#--- Year/month data ---
		"ids": ids,
		"memos": memos,
		"income": income,
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
	var file: FileAccess
	var data: Dictionary

	if !FileAccess.file_exists(PATH):
		return
	file = FileAccess.open(PATH, FileAccess.READ)
	if !FileAccess.get_open_error():
		data = str_to_var(file.get_as_text())
		for key: String in data.keys():
			set(key, data[key])

	# Collecting list of all years which have data and populate option button.
	var years: PackedInt32Array = []
	var current_year: int = Time.get_date_dict_from_system().year

	option_button_year.clear()
	for id: int in ids: # Each id is build with year-month (202601)
		var year: int = floori(id / 100.0)
		option_button_year.add_item(str(year), year)
		years.append(year)
	if !years.has(current_year):
		years.append(current_year)
	_refresh_option_button_year()


#---- Handling - Memo's ----

func _on_memo_text_edit_text_changed() -> void:
	# Get the year.
	# Get the month.
	pass # Replace with function body.



#---- Buttons ----

func _on_option_button_item_selected() -> void:
	_load_memo()
	_load_income()
	_load_monthly_expenses()
	_load_receipts()


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

func _load_income() -> void:
	pass


func _load_monthly_expenses() -> void:
	pass


func _load_receipts() -> void:
	pass


func _load_memo() -> void:
	var date: int = _get_year() * 100 + _get_month()
	var index: int = ids.find(date)
	if index != -1:
		text_edit_memo.text = memos[index]

#---- Helper functions ----

func _get_year() -> int:
	return option_button_year.get_selected_id() ## The id is the year.


func _get_month() -> int:
	return option_button_year.get_selected_id() + 1


func _refresh_option_button_year() -> void:
	var years: PackedInt32Array = []
	for i: int in option_button_year.item_count:
		years.append(option_button_year.get_item_id(i))
	years.sort()
	option_button_year.clear()
	for year: int in years:
		option_button_year.add_item(str(year), year)
