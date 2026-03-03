class_name ThemeUpdater
extends Node
## Theme Updater is a way to adjust your theme to look correct at different
## display scales. Look at each function to see how you can use this class.
## [br]
## [u]This works best on a theme which has all elements filled in![/u]
## [br]
## Future updates might include functions to change the base color and/or
## accent color.


#------------------------------------------------------------------------------
#---- SCALING -----------------------------------------------------------------
#------------------------------------------------------------------------------

## For the default scale, pass 1.0 for `ui_scale`. Be certain that you pass a
## new instance of your theme and not your currently in use theme as the
## scaling will be applied on the previously scaled values.
## [br]
## Here's how this function would be used:
## [code]
## var template_theme: Theme = load("uid://bx4m4dhs6t40")
## var new_theme: Theme = template_theme.duplicate(true)
## ThemeUpdater.apply_scale(new_theme, ui_scale)
## self.theme = new_theme
## [/code]
static func apply_scale(new_theme: Theme, ui_scale: float) -> void:
	ui_scale = maxf(0.1, ui_scale) # Can't be null.
	new_theme.default_font_size = roundi(new_theme.default_font_size * ui_scale)

	var processed: PackedInt64Array = [] ## So we can avoid scaling same resource.
	for type_name: String in new_theme.get_type_list():
		for font_type_name: String in new_theme.get_font_size_list(type_name):
			var current_size: int = new_theme.get_font_size(font_type_name, type_name)
			var new_size: int = roundi(current_size * ui_scale)
			new_theme.set_font_size(font_type_name, type_name, new_size)
		for const_type_name: String in new_theme.get_constant_list(type_name):
			var current_const: int = new_theme.get_constant(const_type_name, type_name)
			var new_const: int = roundi(current_const * ui_scale)
			new_theme.set_constant(const_type_name, type_name, new_const)
		for stylebox_name: String in new_theme.get_stylebox_list(type_name):
			var stylebox: StyleBox = new_theme.get_stylebox(stylebox_name, type_name)
			var id: int = stylebox.get_instance_id()
			if not processed.has(id):
				_scale_stylebox(stylebox, ui_scale)
				processed.append(id)


static func _scale_stylebox(stylebox: StyleBox, ui_scale: float) -> void:
	stylebox.content_margin_top *= ui_scale
	stylebox.content_margin_left *= ui_scale
	stylebox.content_margin_right *= ui_scale
	stylebox.content_margin_bottom *= ui_scale

	if stylebox is StyleBoxFlat:
		var stylebox_flat: StyleBoxFlat = stylebox
		stylebox_flat.border_width_top = roundi(stylebox_flat.border_width_top * ui_scale)
		stylebox_flat.border_width_left = roundi(stylebox_flat.border_width_left * ui_scale)
		stylebox_flat.border_width_right = roundi(stylebox_flat.border_width_right * ui_scale)
		stylebox_flat.border_width_bottom = roundi(stylebox_flat.border_width_bottom * ui_scale)

		stylebox_flat.corner_radius_top_left = roundi(stylebox_flat.corner_radius_top_left * ui_scale)
		stylebox_flat.corner_radius_top_right = roundi(stylebox_flat.corner_radius_top_right * ui_scale)
		stylebox_flat.corner_radius_bottom_left = roundi(stylebox_flat.corner_radius_bottom_left * ui_scale)
		stylebox_flat.corner_radius_bottom_right = roundi(stylebox_flat.corner_radius_bottom_right * ui_scale)

		stylebox_flat.expand_margin_left *= ui_scale
		stylebox_flat.expand_margin_right *= ui_scale
		stylebox_flat.expand_margin_top *= ui_scale
		stylebox_flat.expand_margin_bottom *= ui_scale
	elif stylebox is StyleBoxTexture:
		var stylebox_tex: StyleBoxTexture = stylebox
		stylebox_tex.texture_margin_left *= ui_scale
		stylebox_tex.texture_margin_right *= ui_scale
		stylebox_tex.texture_margin_top *= ui_scale
		stylebox_tex.texture_margin_bottom *= ui_scale

		stylebox_tex.expand_margin_left *= ui_scale
		stylebox_tex.expand_margin_right *= ui_scale
		stylebox_tex.expand_margin_top *= ui_scale
		stylebox_tex.expand_margin_bottom *= ui_scale
	elif stylebox is StyleBoxLine:
		var stylebox_line: StyleBoxLine = stylebox
		stylebox_line.thickness = round(stylebox_line.thickness * ui_scale)
		stylebox_line.grow_begin *= ui_scale
		stylebox_line.grow_end *= ui_scale
