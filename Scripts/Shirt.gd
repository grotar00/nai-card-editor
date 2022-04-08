# ==============================================================================
extends Control
# ==============================================================================

onready var Btn = $TextureButton
onready var L2D = $TextureButton/Line2D

# ==============================================================================
func _ready():
	Btn.connect("mouse_entered", self, "Highlight", [true])
	Btn.connect("mouse_exited", self, "Highlight")
	Btn.connect("pressed", self, "Activate")

# ==============================================================================
# When pattern sample clicked, remove selection from other samples in container
func Activate():
	for shirt in get_parent().get_children():
		shirt.Frame()
	Frame(true)	# Add selection to this one
	Highlight()	# Undo the shift

# ==============================================================================
# Visualize selection (green outline)
func Frame(arg=false):
	L2D.visible = false
	if arg:
		L2D.visible = true

# ==============================================================================
# Shift by 1 pixel diagonally on mouse hover
func Highlight(arg=false):
	Btn.rect_position = Vector2(0, 0)
	if arg and !L2D.visible:
		Btn.rect_position = Vector2(1, 1)
