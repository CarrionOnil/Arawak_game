@tool
class_name PaletteSwapMaterial
extends ShaderMaterial
## Put this material on any Sprite2D, AnimatedSprite2D or TileMapLayer.
##
## - Palette: the GamePalette .tres to use. Share it between materials so one
##   change recolors everything.
## - Look Texture: only for characters drawn with the look-map method
##   (see LookMapBaker). Leave empty for tiles, items and normal sprites.

const PALETTE_SHADER := preload("palette_swap.gdshader")

@export var palette: GamePalette:
	set(value):
		if palette and palette.changed.is_connected(_apply):
			palette.changed.disconnect(_apply)
		palette = value
		if palette and not palette.changed.is_connected(_apply):
			palette.changed.connect(_apply)
		_apply()

@export var look_texture: Texture2D:
	set(value):
		look_texture = value
		_apply()


func _init() -> void:
	if shader == null:
		shader = PALETTE_SHADER
	_apply()


func _apply() -> void:
	set_shader_parameter("use_look_map", look_texture != null)
	set_shader_parameter("look_texture", look_texture)
	if palette == null:
		set_shader_parameter("color_count", 0)
		return
	set_shader_parameter("source_palette", palette.source_texture)
	set_shader_parameter("target_palette", palette.target_texture)
	set_shader_parameter("color_count", palette.color_count)

