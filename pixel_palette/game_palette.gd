@tool
class_name GamePalette
extends Resource
## Your whole game palette, split into ramps by job (skin, moss, metal...).
##
## Save one of these as a .tres file and point every PaletteSwapMaterial at it.
## Change a ramp here and every sprite, tile and item using it updates, in the
## editor and while the game runs.

const MAX_COLORS := 64

## Each ramp is one job in your palette. A color should only appear in one ramp.
@export var ramps: Array[PaletteRamp] = []:
	set(value):
		_disconnect_ramps()
		ramps = value
		_connect_ramps()
		_rebuild()

@export_group("Whole palette")
## Rotate every color's hue (degrees). Good for night, poison, or special areas.
@export_range(-180.0, 180.0, 1.0) var hue_rotate: float = 0.0:
	set(value):
		hue_rotate = value
		_rebuild()

@export_range(0.0, 2.0, 0.05) var saturation: float = 1.0:
	set(value):
		saturation = value
		_rebuild()

@export_range(0.0, 2.0, 0.05) var brightness: float = 1.0:
	set(value):
		brightness = value
		_rebuild()

@export_group("Setup helper")
## Drop a sprite sheet or tileset here, then press the button below. Any colors
## that aren't in a ramp yet are added as a new ramp you can rename or split up.
@export var scan_texture: Texture2D
@export_tool_button("Add missing colors as a new ramp", "Add") var add_missing_button := add_missing_colors_from_scan

## Built from the ramps. PaletteSwapMaterial passes these to the shader.
var source_texture: ImageTexture
var target_texture: ImageTexture
var color_count := 0


func _init() -> void:
	_rebuild()


## Find a ramp by name so game code can recolor it, e.g.
## palette.find_ramp("Native skin").new_base = Color("e0679f")
func find_ramp(ramp_name: String) -> PaletteRamp:
	for ramp in ramps:
		if ramp and ramp.ramp_name == ramp_name:
			return ramp
	return null


func add_missing_colors_from_scan() -> void:
	if scan_texture == null:
		push_warning("GamePalette: set 'Scan Texture' first.")
		return
	var img := scan_texture.get_image()
	if img == null:
		push_warning("GamePalette: couldn't read that texture.")
		return
	if img.is_compressed():
		img.decompress()

	var known := {}
	for ramp in ramps:
		if ramp:
			for c in ramp.source_colors:
				known[c.to_html(false)] = true

	var found := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var key := c.to_html(false)
			if not known.has(key):
				found[key] = Color(c.r, c.g, c.b)

	if found.is_empty():
		print("GamePalette: every color in that texture is already in a ramp.")
		return

	var colors := found.values()
	colors.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	var ramp := PaletteRamp.new()
	ramp.ramp_name = "New colors from " + scan_texture.resource_path.get_file()
	ramp.source_colors = PackedColorArray(colors)
	var new_ramps := ramps.duplicate()
	new_ramps.append(ramp)
	ramps = new_ramps
	notify_property_list_changed()
	print("GamePalette: added %d new colors as '%s'." % [colors.size(), ramp.ramp_name])


func _connect_ramps() -> void:
	for ramp in ramps:
		if ramp and not ramp.changed.is_connected(_rebuild):
			ramp.changed.connect(_rebuild)


func _disconnect_ramps() -> void:
	for ramp in ramps:
		if ramp and ramp.changed.is_connected(_rebuild):
			ramp.changed.disconnect(_rebuild)


func _adjust(c: Color) -> Color:
	if hue_rotate == 0.0 and saturation == 1.0 and brightness == 1.0:
		return c
	return Color.from_hsv(
		fposmod(c.h + hue_rotate / 360.0, 1.0),
		clampf(c.s * saturation, 0.0, 1.0),
		clampf(c.v * brightness, 0.0, 1.0),
		c.a)


func _rebuild() -> void:
	var src := Image.create_empty(MAX_COLORS, 1, false, Image.FORMAT_RGBA8)
	var dst := Image.create_empty(MAX_COLORS, 1, false, Image.FORMAT_RGBA8)
	color_count = 0
	var owner_of := {}

	for ramp in ramps:
		if ramp == null:
			continue
		var out := ramp.get_output_colors()
		for i in ramp.source_colors.size():
			var c := ramp.source_colors[i]
			var key := c.to_html(false)
			if owner_of.has(key):
				push_warning("GamePalette: #%s is in both '%s' and '%s'. Only the first one is used." % [key, owner_of[key], ramp.ramp_name])
				continue
			if color_count >= MAX_COLORS:
				push_warning("GamePalette: more than %d colors. The extra colors won't be recolored." % MAX_COLORS)
				break
			owner_of[key] = ramp.ramp_name
			src.set_pixel(color_count, 0, c)
			dst.set_pixel(color_count, 0, _adjust(out[i]))
			color_count += 1

	if source_texture == null:
		source_texture = ImageTexture.create_from_image(src)
		target_texture = ImageTexture.create_from_image(dst)
	else:
		source_texture.update(src)
		target_texture.update(dst)
	emit_changed()
