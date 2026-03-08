class_name SettingsMenu
extends Window

const PATH_TRANSLATIONS: String = "res://translations/"
const CURRENCIES: Array[Array] = [ ## [ Display, character, separator, decimal, char is prefix]
	["EUR (€1.000,00)", "€", ".", ",", true], 		["USD ($1,000.00)", "$", ",", ".", true],
	["GBP (£1,000.00)", "£", ",", ".", true],		["JPY (¥1000)", "¥", ",", "", true],
	["CNY (¥1,000.00)", "¥", ",", ".", true],		["KRW (₩1,000)", "₩", ",", "", true],
	["INR (₹1,000.00)", "₹", ",", ".", true],		["RUB (₽1 000,00)", "₽", " ", ",", true],
	["CHF (CHF 1’000.00)", "CHF", "’", ".", true],	["SEK (1 000,00 kr)", "kr", " ", ",", false],
	["NOK (1 000,00 kr)", "kr", " ", ",", false],	["DKK (1.000,00 kr)", "kr", ".", ",", false],
	["PLN (1 000,00 zł)", "zł", " ", ",", false],	["TRY (₺1.000,00)", "₺", ".", ",", true],
	["BRL (R$ 1.000,00)", "R$", ".", ",", true],	["MXN ($1,000.00)", "$", ",", ".", true],
	["CAD ($1,000.00)", "$", ",", ".", true],		["AUD ($1,000.00)", "$", ",", ".", true],
	["NZD ($1,000.00)", "$", ",", ".", true],		["ZAR (R1 000.00)", "R", " ", ".", true],
	["SGD ($1,000.00)", "$", ",", ".", true],		["HKD ($1,000.00)", "$", ",", ".", true],
	["IDR (Rp1.000,00)", "Rp", ".", ",", true],		["THB (฿1,000.00)", "฿", ",", ".", true],
	["VND (₫1.000)", "₫", ".", "", true]
]

@export var option_button_language: OptionButton
@export var option_button_currency: OptionButton
@export var line_edit_encryption_password: LineEdit
@export var slider_display_scale: HSlider


var languages: PackedStringArray = []



func _ready() -> void:
	close_requested.connect(_on_cancel_button_pressed)

	setup_language_setting()
	setup_currency_setting()
	setup_encryption_password_setting()


func setup_language_setting() -> void:
	# Language setting.
	option_button_language.add_item("English")
	languages.append("en")

	# Add custom languages.
	for file_name: String in DirAccess.get_files_at(PATH_TRANSLATIONS):
		if file_name.get_extension().to_lower() == "po":
			var locale: String = file_name.get_basename().get_file()
			option_button_language.add_item(TranslationServer.get_locale_name(locale))
			languages.append(locale)

	var index: int = languages.find(Main.instance.setting_language)
	option_button_language.selected = index


func setup_currency_setting() -> void:
	for details: PackedStringArray in CURRENCIES:
		option_button_currency.add_item(details[0])


func setup_encryption_password_setting() -> void:
	line_edit_encryption_password.text = Main.instance._password


#---- Setting buttons ----

func _on_language_option_button_item_selected(index: int) -> void:
	TranslationServer.set_locale(languages[index])


func _on_secret_button_pressed() -> void:
	line_edit_encryption_password.secret = !line_edit_encryption_password.secret


func _on_display_scale_h_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Main.instance.scale_display(slider_display_scale.value)
		await RenderingServer.frame_post_draw
		var container: Control = get_child(0)
		size = container.get_combined_minimum_size()
		move_to_center()


#---- Main Buttons ----

func _on_save_settings_button_pressed() -> void:
	Main.instance.setting_language = languages[option_button_language.get_selected_id()]

	var currency_details: Array = CURRENCIES[option_button_currency.get_selected_id()]
	Main.instance.setting_currency_symbol = currency_details[1]
	Main.instance.setting_currency_separator = currency_details[2]
	Main.instance.setting_currency_decimal_separator = currency_details[3]
	Main.instance.setting_currency_prefix = currency_details[4]

	Main.instance._password = line_edit_encryption_password.text
	Main.instance.setting_display_scale = slider_display_scale.value

	Main.instance.update_settings()
	self.queue_free()


func _on_cancel_button_pressed() -> void:
	Main.instance.update_settings()
	self.queue_free()


func _on_close_requested() -> void:
	Main.instance.update_settings()
	self.queue_free()

