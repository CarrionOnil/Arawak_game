@tool
class_name DualGridTerrain
extends TileMapLayer
## Auto-tiling for the 16-tile corner template ("dual grid").
##
## Paint on THIS layer with just two tiles: the all-soil tile and the all-moss
## tile. The child "Display" layer, shifted half a tile, draws the right edge
## and corner tiles for you, in the editor and in game.
## Game logic (collisions, "is this soil?") can read this layer's simple grid.

## The all-soil tile's position in your tileset (column, row).
@export var soil_tile := Vector2i(2, 1):
	set(value):
		soil_tile = value
		refresh()
## The all-moss tile's position in your tileset (column, row).
@export var moss_tile := Vector2i(0, 3):
	set(value):
		moss_tile = value
		refresh()
## Show the simple painting grid on top (handy while painting).
@export var show_paint_grid := false:
	set(value):
		show_paint_grid = value
		self_modulate.a = 0.35 if value else 0.0

# Which tile to use for each combination of corners (1 = soil, 0 = moss),
# in the same layout as the template: [top-left, top-right, bottom-left, bottom-right].
const TEMPLATE := [
	[[0,0,1,0], [0,1,0,1], [1,0,1,1], [0,0,1,1]],
	[[1,0,0,1], [0,1,1,1], [1,1,1,1], [1,1,1,0]],
	[[0,1,0,0], [1,1,0,0], [1,1,0,1], [1,0,1,0]],
	[[0,0,0,0], [0,0,0,1], [0,1,1,0], [1,0,0,0]],
]
var _tile_for := {}


func _ready() -> void:
	self_modulate.a = 0.35 if show_paint_grid else 0.0
	if not changed.is_connected(refresh):
		changed.connect(refresh)
	refresh()


func _get_display() -> TileMapLayer:
	return get_node_or_null("Display") as TileMapLayer


func refresh() -> void:
	var display := _get_display()
	if display == null or tile_set == null:
		return
	if _tile_for.is_empty():
		for row in 4:
			for col in 4:
				var c: Array = TEMPLATE[row][col]
				_tile_for[c[0] * 8 + c[1] * 4 + c[2] * 2 + c[3]] = Vector2i(col, row)

	display.tile_set = tile_set
	display.position = -Vector2(tile_set.tile_size) / 2.0
	display.clear()

	var todo := {}
	for cell in get_used_cells():
		for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			todo[cell + offset] = true

	var source := get_cell_source_id(get_used_cells()[0]) if not todo.is_empty() else 0
	for d in todo:
		var key := _soil(d + Vector2i(-1, -1)) * 8 + _soil(d + Vector2i(0, -1)) * 4 \
			+ _soil(d + Vector2i(-1, 0)) * 2 + _soil(d)
		display.set_cell(d, source, _tile_for[key])


func _soil(cell: Vector2i) -> int:
	return 1 if get_cell_atlas_coords(cell) == soil_tile else 0
