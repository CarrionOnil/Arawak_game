# Pixel Palette: recolor your pixel art without repainting

Draw your art once, then change its colors from the Godot inspector (or from
game code). Built and tested in Godot 4.5.1. It needs **Godot 4.4 or newer**
because the setup buttons use `@export_tool_button`.

## Try the demo

1. Open this folder in Godot and press **Play**.
2. Keys: **1-4** change the native's skin, **0** puts the original skin back,
   **P** poisons or heals the world, **Q / E** rotate every hue.
3. Stop the game and open `demo/world_palette.tres` in the inspector. Expand a
   ramp (for example *Foliage*), tick **Recolor** and drag **New Base** around
   the color wheel. The scene updates live in the editor.

## What's in `pixel_palette/`

| File | What it is |
|---|---|
| `palette_ramp.gd` | **PaletteRamp**: the colors for one job (skin, moss, metal...), darkest to lightest. Pick one new base color and it rebuilds the shadows and highlights. |
| `game_palette.gd` | **GamePalette**: all your ramps, plus sliders that adjust the whole palette. Save it as a `.tres` file. |
| `palette_swap_material.gd` | **PaletteSwapMaterial**: put it on any Sprite2D, AnimatedSprite2D or TileMapLayer. |
| `palette_swap.gdshader` | The shader that does the swap. You don't need to edit it. |
| `look_map_baker.gd` | **LookMapBaker**: the look-map method, for characters. |

## Setting it up in your own game

1. Copy the `pixel_palette` folder into your project.
2. In **Project Settings → Rendering → Textures**, set **Default Texture Filter** to **Nearest**.
3. In the FileSystem dock: right-click → **New Resource… → GamePalette** and save it (e.g. `palette.tres`).
4. Put the palette on your art: select your TileMapLayer or Sprite2D, go to
   **Material → New PaletteSwapMaterial**, and drag your `palette.tres` into its **Palette** slot.
   Save that material as a `.tres` file and reuse it on everything that should share colors.
5. Add your colors: in the palette, drag a tileset or sprite sheet into
   **Setup Helper → Scan Texture** and press **Add missing colors as a new ramp**.
   Then split that list into ramps by job (moss, soil, skin...), darkest color
   first, and give each ramp a name.
6. Recolor: tick **Recolor** on a ramp and pick **New Base**.

### The one rule: one color = one job

The shader recolors by color, so every pixel with the same color changes
together. If your native's hair and the night sky use the same dark blue, they
recolor together. Give each job its own colors. Two colors that differ by just
1 (for example `#1a1a3a` and `#1a1a3b`) count as separate colors, so they look
identical in Pixquare but can be recolored separately.

## The look-map method (characters)

Use this when you want to change a character's **details**, not just its
colors (add a headband, a scar or armor), and have it appear on every frame
of every animation.

1. Draw the **look**: one frame of each direction side by side. See
   `demo/art/native_look.png`: front, back and side, each 16×24.
2. Create a **LookMapBaker** resource. Set **Look** and **Map Path**, then press **1. Make map**.
   You get a **map** (`demo/art/native_map.png`): the same shape, but every pixel
   has its own unique color.
3. In Pixquare, import the map as a layer and animate using **only colors picked
   from it** with the eyedropper. Keep the pixels in the same places on the body
   (knee pixel stays on the knee, and so on). Export the sprite sheet. Example:
   `demo/art/native_walk_drawn_with_map.png`.
4. In the baker, set **Animation Drawn With Map** and **Baked Path**, then press **2. Bake animation**.
5. Use the baked PNG in your AnimatedSprite2D. Give that node a
   PaletteSwapMaterial with **Look Texture** set to your look PNG.

Now edit only `native_look.png` and every frame updates. A detail you draw on the
side view shows only when the character faces sideways. The palette still
applies on top, so ramps recolor the character too.

## Changing colors from game code

```gdscript
var skin := palette.find_ramp("Native skin")
skin.new_base = Color("e0679f")
skin.recolor = true
palette.hue_rotate = 30.0   # the whole world
```
`demo/demo.gd` has a working example, including poisoning and healing the world.

## Limits

- Up to 64 colors per palette. To allow more, raise `MAX_COLORS` in both
  `game_palette.gd` and `palette_swap.gdshader`.
- Keep the PNG import compression at **Lossless** (the default). VRAM compression changes colors slightly, and then they won't match.
- Leave **HDR 2D** off (the default) when using look maps.

## Your tileset: `demo/my_tiles.tscn`

Open `demo/my_tiles.tscn` to see your own 16-tile set painted as a map.

- **Ground** is where you paint. Select it, open the **TileMap** panel at the
  bottom, and paint with only two tiles: the all-soil tile and the all-moss
  tile. Turn on **Show Paint Grid** to see what you're painting.
- **Display** (a child of Ground) redraws automatically with the correct edge and
  corner tiles. It's shifted half a tile. That's the "dual grid" trick your
  template was designed for.
- Display uses the palette material, so the Foliage and Rock & soil ramps
  recolor your tiles.

To use it in your own scene, add a TileMapLayer, attach
`pixel_palette/dual_grid_terrain.gd`, give it your tileset, and add a child
TileMapLayer named exactly **Display**.
If you redraw the tileset in a different order, update **Soil Tile** and
**Moss Tile** in the inspector to point at the all-soil and all-moss tiles.
