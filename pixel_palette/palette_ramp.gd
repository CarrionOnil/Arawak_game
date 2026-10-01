@tool
class_name PaletteRamp
extends Resource
## One "job" in your palette (skin, moss, metal, water...).
##
## List the exact colors you painted that job with, darkest first. To recolor it,
## turn on `recolor` and pick a new base color: the shadows and highlights are
## rebuilt around it using the same shading steps you drew with.

## A name that says what these colors are for, e.g. "Native skin".
@export var ramp_name: String = "New ramp":
	set(value):
		ramp_name = value
		resource_name = value
		emit_changed()

## The exact colors you painted with, ordered darkest -> lightest.
@export var source_colors: PackedColorArray = PackedColorArray():
	set(value):
		source_colors = value
		emit_changed()

## Which source color is the "main" color of this ramp (0 = the first/darkest).
## The other colors are treated as its shadows (darker) and highlights (lighter).
@export var base_index: int = 0:
	set(value):
		base_index = value
		emit_changed()

@export_group("Recolor")
## Off = keep the original colors. On = rebuild the ramp from `new_base`.
@export var recolor: bool = false:
	set(value):
		recolor = value
		emit_changed()

## The new main color. Use the color wheel; shadows and highlights follow it.
@export var new_base: Color = Color.WHITE:
	set(value):
		new_base = value
		emit_changed()

## 1 = same shading contrast as your drawing. Higher = deeper shadows and
## brighter highlights. Lower = flatter.
@export_range(0.0, 2.0, 0.05) var contrast: float = 1.0:
	set(value):
		contrast = value
		emit_changed()

## Extra hue rotation (degrees) from the darkest to the lightest color.
## Pixel artists often shift shadows and highlights toward different hues.
@export_range(-90.0, 90.0, 1.0) var hue_shift: float = 0.0:
	set(value):
		hue_shift = value
		emit_changed()


## The colors this ramp should display right now (same order as source_colors).
func get_output_colors() -> PackedColorArray:
	if not recolor or source_colors.is_empty():
		return source_colors.duplicate()

	var out := PackedColorArray()
	var n := source_colors.size()
	var bi := clampi(base_index, 0, n - 1)
	var base := source_colors[bi]

	for i in n:
		var src := source_colors[i]

		# Hue: keep the hue difference the artist used between this shade and the base.
		# (Grays have no real hue, so they just take the new base hue.)
		var dh := 0.0
		if src.s > 0.05 and base.s > 0.05:
			dh = wrapf(src.h - base.h, -0.5, 0.5)
		var t := 0.0 if n == 1 else float(i - bi) / float(n - 1)
		var h := fposmod(new_base.h + dh + t * hue_shift / 360.0, 1.0)

		# Saturation: keep the same offset from the base.
		var s := clampf(new_base.s + (src.s - base.s), 0.0, 1.0)

		# Brightness: shadows keep their "how much darker" ratio, highlights keep
		# their "how far toward white" ratio, so nothing clips.
		var v: float
		if src.v >= base.v:
			var k := 0.0 if base.v >= 0.999 else (src.v - base.v) / (1.0 - base.v)
			k = clampf(k * contrast, 0.0, 1.0)
			v = lerpf(new_base.v, 1.0, k)
		else:
			var k := 1.0 - src.v / maxf(base.v, 0.001)
			k = clampf(k * contrast, 0.0, 1.0)
			v = new_base.v * (1.0 - k)

		out.append(Color.from_hsv(h, s, v, src.a))
	return out
