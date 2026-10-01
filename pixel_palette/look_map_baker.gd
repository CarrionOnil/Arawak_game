@tool
class_name LookMapBaker
extends Resource
## The "look map" method for characters (one per character).
##
## Step 1. Draw the LOOK: one frame of each direction side by side (front, back,
##         side...). Set `look`, press "1. Make map". You get a MAP: the same
##         shape, but every pixel has its own unique color.
## Step 2. In Pixquare, animate using ONLY colors picked from the map (import the
##         map as a layer and use the eyedropper). Export the sprite sheet.
## Step 3. Set `animation_drawn_with_map`, press "2. Bake animation".
## Step 4. Use the baked PNG in your AnimatedSprite2D, with a PaletteSwapMaterial
##         whose Look Texture is your look PNG.
## From then on, repaint the look PNG and every frame of every animation updates.

@export_group("1. Look -> Map")
## Your character's look sheet (max 256 x 256 pixels).
@export var look: Texture2D
## Where to save the generated map.
@export_file("*.png") var map_path: String = "res://character_map.png"
@export_tool_button("1. Make map", "ImageTexture") var make_map_button := make_map

@export_group("2. Animation -> Baked sprite sheet")
## The sprite sheet you animated using the map's colors.
@export var animation_drawn_with_map: Texture2D
## Where to save the baked sprite sheet (the one you actually use in the game).
@export_file("*.png") var baked_path: String = "res://character_baked.png"
@export_tool_button("2. Bake animation", "Bake") var bake_button := bake


func make_map() -> void:
	var img := _read(look)
	if img == null:
		push_warning("LookMapBaker: set 'Look' first.")
		return
	var w := img.get_width()
	var h := img.get_height()
	if w > 256 or h > 256:
		push_error("LookMapBaker: the look must be 256 x 256 pixels or smaller.")
		return

	# Red = x and green = y (spread out so they're easy to tell apart). Blue follows
	# the look's brightness plus stripes every 2 rows, so the map still reads as
	# your character when you animate with it.
	var sx := 255 / maxi(1, w - 1)
	var sy := 255 / maxi(1, h - 1)
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var stripe := 50 if (y / 2) % 2 == 0 else 0
			var b := clampi(int(c.get_luminance() * 180.0) + 20 + stripe, 0, 255)
			out.set_pixel(x, y, Color8(x * sx, y * sy, b))
	_save(out, map_path)


func bake() -> void:
	var map_img: Image = null
	if FileAccess.file_exists(map_path):
		map_img = Image.load_from_file(ProjectSettings.globalize_path(map_path))
	var anim := _read(animation_drawn_with_map)
	if map_img == null or anim == null:
		push_warning("LookMapBaker: make the map first and set 'Animation Drawn With Map'.")
		return
	map_img.convert(Image.FORMAT_RGBA8)

	var lookup := {}
	for y in map_img.get_height():
		for x in map_img.get_width():
			var c := map_img.get_pixel(x, y)
			if c.a >= 0.5:
				lookup[c.to_html(false)] = Vector2i(x, y)

	var out := Image.create_empty(anim.get_width(), anim.get_height(), false, Image.FORMAT_RGBA8)
	var missing := 0
	for y in anim.get_height():
		for x in anim.get_width():
			var c := anim.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var key := c.to_html(false)
			if lookup.has(key):
				var p: Vector2i = lookup[key]
				out.set_pixel(x, y, Color8(p.x, p.y, 0))
			else:
				missing += 1
				if missing <= 5:
					push_warning("LookMapBaker: pixel (%d, %d) is #%s, which isn't on the map. It will be invisible." % [x, y, key])
	if missing > 0:
		push_warning("LookMapBaker: %d pixels weren't map colors." % missing)
	_save(out, baked_path)


func _read(tex: Texture2D) -> Image:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, path: String) -> void:
	var err := img.save_png(path)
	if err != OK:
		push_error("LookMapBaker: couldn't save %s (error %d)." % [path, err])
		return
	print("LookMapBaker: saved ", path)
	if Engine.is_editor_hint() and Engine.has_singleton("EditorInterface"):
		Engine.get_singleton("EditorInterface").get_resource_filesystem().scan()
