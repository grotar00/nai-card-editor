# ==============================================================================
extends Control
# ==============================================================================

export var spectrum: Gradient

# ==============================================================================
func _ready():
	update()
	$TextureRect.texture.gradient = spectrum

# ==============================================================================
func _draw():
	draw_rect(Rect2(0, 0, 150, 50), Color.black, false, 2)
	
	for id in spectrum.get_point_count():
		var offset = spectrum.get_offset(id) * 150
		draw_rect(Rect2(offset - 4, 15, 8, 20), Color.black, false, 1)
	
# ==============================================================================
func Synchronize():
	for handle in get_children():
		handle.queue_free()
