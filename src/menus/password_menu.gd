class_name PasswordMenu
extends PopupPanel


@export var line_edit: LineEdit



func _on_line_edit_text_submitted(password: String) -> void:
	FileAccess.open_encrypted_with_pass(Main.PATH, FileAccess.READ, password)
	var error: int = FileAccess.get_open_error()
	if error == OK:
		Main.instance._password = password
		self.queue_free()
	else:
		line_edit.text = ""
		line_edit.placeholder_text = tr("Incorrect password") + " (%s)" % error


func _on_confirm_button_pressed() -> void:
	_on_line_edit_text_submitted(line_edit.text)


func _on_close_button_pressed() -> void:
	get_tree().quit(1)
