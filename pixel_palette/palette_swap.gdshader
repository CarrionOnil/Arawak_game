// Palette swap + look map shader for pixel art (Godot 4).
//
// 1. Palette swap: every pixel whose color is in `source_palette` is replaced by
//    the color in the same slot of `target_palette`. Works on Sprite2D,
//    AnimatedSprite2D, TileMapLayer, anything that draws a texture.
// 2. Look map (optional, for characters): the sprite's pixels store a position
//    (red = x, green = y) inside `look_texture`, and the color comes from there.
//    Repaint the look texture once and every animation frame updates.
//
// You normally don't touch this file: PaletteSwapMaterial fills in the uniforms.
shader_type canvas_item;

const int MAX_COLORS = 64;

uniform sampler2D source_palette : filter_nearest;
uniform sampler2D target_palette : filter_nearest;
uniform int color_count = 0;
// Colors closer than this count as "the same color". Keep it tiny so two
// colors that differ by 1 (out of 255) stay separate slots.
uniform float match_tolerance = 0.002;

uniform bool use_look_map = false;
uniform sampler2D look_texture : filter_nearest;

varying vec4 modulate_color;

void vertex() {
	// Keep the node's modulate / self_modulate working.
	modulate_color = COLOR;
}

void fragment() {
	vec4 px = texture(TEXTURE, UV);

	if (use_look_map && px.a > 0.0) {
		ivec2 cell = ivec2(round(px.rg * 255.0));
		px = texelFetch(look_texture, cell, 0);
	}

	vec3 rgb = px.rgb;
	for (int i = 0; i < MAX_COLORS; i++) {
		if (i >= color_count) {
			break;
		}
		vec3 src = texelFetch(source_palette, ivec2(i, 0), 0).rgb;
		if (distance(src, px.rgb) < match_tolerance) {
			rgb = texelFetch(target_palette, ivec2(i, 0), 0).rgb;
			break;
		}
	}

	COLOR = vec4(rgb, px.a) * modulate_color;
}
