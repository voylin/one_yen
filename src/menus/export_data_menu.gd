class_name ExportDataMenu
extends Window
# TODO: Add a way to define a "from" and a "to"

static var previous_path: String = ""


@export var line_edit_path: LineEdit



func _ready() -> void:
	close_requested.connect(queue_free)
	line_edit_path.text = previous_path


#---- Path line edit ----

func _on_path_line_edit_text_submitted() -> void:
	_on_export_button_pressed()


#---- Buttons ----

func _on_select_path_button_pressed() -> void:
	var dialog: FileDialog = FileDialog.new()
	dialog.title = tr("Select path", &"File dialog for selecting export data path.")
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = ["*.csv; CSV Files"]
	dialog.use_native_dialog = true

	if previous_path.is_empty():
		dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	else:
		dialog.current_dir = previous_path.get_base_dir()

	add_child(dialog)
	dialog.popup_centered()
	dialog.file_selected.connect(func(path: String) -> void: line_edit_path.text = path)


func _on_export_button_pressed() -> void:
	var path: String = line_edit_path.text
	if path.is_empty():
		return
	if path.get_extension().to_lower() != ".csv":
		path += ".csv"
	if !DirAccess.dir_exists_absolute(path.get_base_dir()):
		printerr("Invalid folder for exporting data to! '%s'" % path.get_base_dir())
		self.queue_free()
		return

	var headers: PackedStringArray = ["Date", "Description", "Income", "Expense"]
	var data: Array[PackedStringArray] = []
	for index: int in Main.instance.receipt_dates.size():
		var corrected_date: String = str(Main.instance.receipt_dates[index])
		corrected_date = corrected_date.insert(6, "-").insert(4, "-")
		data.append([
				corrected_date,
				str(Main.instance.descriptions[index]),
				str(Main.instance.income_amount[index]),
				str(Main.instance.expense_amount[index])])

	# Adding monthly income and monthly expenses on the first day of
	# the month so they always appear on top of each month.
	for index: int in Main.instance.ids.size():
		var id: int = Main.instance.ids[index]
		var corrected_date: String = str(id).insert(4, "-")
		corrected_date += "-01"

		# Add income.
		for source_index: int in Main.instance.monthly_income_sources.size():
			var source: String = Main.instance.monthly_income_sources.get(id)[source_index]
			data.append([
					corrected_date, source,
					str(Main.instance.monthly_income[index]), 0])

		# Add expenses sources.
		for source_index: int in Main.instance.monthly_income_sources.size():
			var source: String = Main.instance.monthly_income_sources.get(id)[source_index]
			data.append([
					corrected_date, source,
					0, str(Main.instance.monthly_expenses[index])])

	data.sort_custom(_sort)

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_line(",".join(headers))
	for entry: Array in data:
		file.store_line(",".join(entry))

	previous_path = path
	self.queue_free()


func _sort(a: Array, b: Array) -> bool:
	return a[1] < b[1] if a[0] == b[0] else a[0] < b[0]
