# ==============================================================================
# [!!!] Card dimensions must equal 400x600
# ==============================================================================
extends Control
# ==============================================================================

# Font settings presets
var font_serif = preload("res://Presets/Serif.tres")
var font_sans = preload("res://Presets/Sans.tres")

var name_font
var name_font_size = 24
var name_upper = true

var title_font
var title_font_size = 16
var title_upper = true

var DATA = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var BUFFER = [[], [], [], [], [], [], [], [], [], []]
var SHIRTS = {}			# Pattern ID : node
var last_changed = -1	# Param of last changed id, if same - merge to BUFFER[1]
var circle = "•"		# Symbol to enclose name and title
var image = Image.new()
var image_tex = ImageTexture.new()
var image_temp = Image.new()
var min_scale = 1.0		# 80% of calculated scale to fit image in frame
var init_data = false	# Do not write in DATA if values changed while is true
var switch_type = false	# Same for ChangeType()
var capture				# Viewport screenshot
var await				# Expected loaded image extension
var mpos				# Mouse position
var modal_open = false	# Used in RequestImageFromWeb()
var show_orb = false	# Hello 2hu people
# Keyboard 1-0 scancodes for picking patterns
var DigiKeys = {KEY_1 : 1,
				KEY_2 : 2,
				KEY_3 : 3,
				KEY_4 : 4,
				KEY_5 : 5,
				KEY_6 : 6,
				KEY_7 : 7,
				KEY_8 : 8,
				KEY_9 : 9}

onready var Port = $Card/Portrait
onready var Outline = $Card/Outline
onready var Name = $Card/Name
onready var Title = $Card/TitleBar/Title
onready var TitleBig = $Card/TitleBig
onready var Foil = $Card/FrameGradient
onready var Pattern = $Card/Pattern
onready var Shadow = $Card/Shadow
onready var TokenBarBottom = $Card/TokenBarBottom
onready var TokensBottom = $Card/TokenBarBottom/TokensBottom
onready var TokenBarTop = $Card/TokenBarTop
onready var TokensTop = $Card/TokenBarTop/TokensTop
onready var TitleBar = $Card/TitleBar
onready var Emboss = $Card/Emboss
onready var NovelAI = $Card/Logo/NovelAI
onready var Flash = $Flash
onready var FlashTween = $Flash/Tween

onready var NameInput = $GUI/NameInput
onready var NameSize = $GUI/NameSize
onready var NameSizeHint = $GUI/NameSize/Size
onready var NameUpper = $GUI/NameUpper

onready var TitleInput = $GUI/TitleInput
onready var TitleSize = $GUI/TitleSize
onready var TitleSizeHint = $GUI/TitleSize/Size
onready var TitleUpper = $GUI/TitleUpper
onready var TitleToggle = $GUI/TitleToggle

onready var TypeA = $GUI/TypeA
onready var TypeB = $GUI/TypeB
onready var TypeC = $GUI/TypeC
onready var Upload = $GUI/Upload
onready var Shirts = $GUI/ScrollContainer/Shirts
onready var ShirtOpacity = $GUI/ShirtOpacity
onready var InvertTop = $GUI/InvertTop
onready var InvertBot = $GUI/InvertBot
onready var RotateFoil = $GUI/FoilRotate
onready var AdjustFoil = $GUI/FoilAdjust
onready var OffsetFoil = $GUI/FoilOffset
onready var ColorA = $GUI/ColorA
onready var SampleA = $GUI/ColorA/SampleA
onready var PanelA = $GUI/PickerPanelA
onready var PickerA = $GUI/PickerPanelA/PickerA
onready var ColorB = $GUI/ColorB
onready var SampleB = $GUI/ColorB/SampleB
onready var PanelB = $GUI/PickerPanelB
onready var PickerB = $GUI/PickerPanelB/PickerB
onready var Mono = $GUI/Mono
onready var Swap = $GUI/Swap
onready var Tokens = $GUI/Tokens
onready var TokenPos = $GUI/TokenPos
onready var UpdateTokens = $GUI/UpdateTokens
onready var EmbossToggle = $GUI/EmbossToggle

onready var FaceMask = $Card/FaceMask
onready var FrameMask = $Card/FrameMask
onready var CardMask = $Card/CardMask

onready var ImageX = $GUI/ImageX
onready var ImageY = $GUI/ImageY
onready var ImageRotate = $GUI/ImageRotate
onready var ImageScale = $GUI/ImageScale
onready var Flip = $GUI/Flip
onready var Lock = $GUI/Lock

onready var Reset = $GUI/Reset
onready var Download = $GUI/Download
onready var Export = $GUI/Export
onready var Import = $GUI/Import
onready var Undo = $GUI/Undo
onready var SaveDialog = $GUI/SaveDialog
onready var LoadDialog = $GUI/LoadDialog
onready var ErrorText = $GUI/ErrorText
onready var Source = $GUI/Source
onready var URL = $GUI/URL
onready var HTTP = $HTTPRequest
onready var RequestTimeout = $Timer

onready var ExportDialog = $ExportDialog
onready var CodeField = $ExportDialog/CodeField
onready var Clipboard = $ExportDialog/Clipboard
onready var Nais = $ExportDialog/Nais

export var shirt_sample: PackedScene

var field_theme = preload("res://Presets/field_normal.tres")

# ==============================================================================
func _ready():
	randomize()	# Get random seed for random operations
	HTML5.root = self	# Link this script to HTML5.gd module's root variable
	
	# SpinBox nested InputField is darker for some reason, replacing the theme
	Tokens.get_line_edit().set("custom_styles/normal", field_theme)
	
	get_tree().connect("files_dropped", self, "FilesDropped")
	
	NameInput.connect("text_changed", self, "ChangeName")
	NameSize.connect("value_changed", self, "UpdateNameFontSize")
	NameUpper.connect("toggled", self, "ToggleNameUppercase")
	
	TitleInput.connect("text_changed", self, "ChangeTitle")
	TitleSize.connect("value_changed", self, "UpdateTitleFontSize")
	TitleUpper.connect("toggled", self, "ToggleTitleUppercase")
	
	RotateFoil.connect("value_changed", self, "RotateGradient")
	AdjustFoil.connect("value_changed", self, "AdjustGradient")
	OffsetFoil.connect("value_changed", self, "AdjustGradient")
	EmbossToggle.connect("toggled", self, "ToggleEmboss")
	FlashTween.connect("tween_all_completed", Flash, "hide")
	FlashTween.connect("tween_all_completed", Download, "set_disabled", [false])
	
	ColorA.connect("toggled", PanelA, "set_visible")
	ColorB.connect("toggled", PanelB, "set_visible")
	PickerA.connect("color_changed", self, "ColorGradient", [0])
	PickerB.connect("color_changed", self, "ColorGradient", [1])
	PickerA.connect("hide", ColorA, "set_pressed", [false])
	PickerB.connect("hide", ColorB, "set_pressed", [false])
	
	ShirtOpacity.connect("value_changed", self, "PatternOpacity") 
	InvertTop.connect("toggled", self, "InvertPatternTop")
	InvertBot.connect("toggled", self, "InvertPatternBot")
	Swap.connect("pressed", self, "ColorSwap")
	TitleToggle.connect("toggled", self, "ToggleTitle")
	TokenPos.connect("toggled", self, "MoveTokens")
	Tokens.connect("value_changed", self, "ChangeTokens")
	Tokens.get_line_edit().connect("text_entered", self, "FreeTokens")
	Tokens.get_line_edit().connect("focus_exited", self, "FreeTokens")
	Tokens.connect("mouse_exited", self, "FreeTokens")
	UpdateTokens.connect("toggled", $GUI/UpdateMode, "set_visible")
	
	TypeA.connect("toggled", self, "ChangeType", [0])
	TypeB.connect("toggled", self, "ChangeType", [1])
	TypeC.connect("toggled", self, "ChangeType", [2])
	Upload.connect("pressed", self, "RequestImageFromWeb")
	Source.connect("meta_clicked", self, "CopyImageName")
	
	$GUI/ImageX/Reset.connect("pressed", self, "SetImageOffsetX")
	$GUI/ImageY/Reset.connect("pressed", self, "SetImageOffsetY")
	$GUI/ImageRotate/Reset.connect("pressed", self, "SetImageRotation")
	$GUI/ImageScale/Reset.connect("pressed", self, "SetImageScale")
	
	$GUI/ImageX/Focus.connect("pressed", ImageX, "grab_focus")
	$GUI/ImageY/Focus.connect("pressed", ImageY, "grab_focus")
	$GUI/ImageRotate/Focus.connect("pressed", ImageRotate, "grab_focus")
	$GUI/ImageScale/Focus.connect("pressed", ImageScale, "grab_focus")
	
	$GUI/FoilRotate/Reset.connect("pressed", RotateFoil, "set_value", [55])
	$GUI/FoilAdjust/Reset.connect("pressed", AdjustFoil, "set_value", [0.12])
	$GUI/FoilOffset/Reset.connect("pressed", OffsetFoil, "set_value", [0])
	
	$GUI/FoilRotate/Focus.connect("pressed", RotateFoil, "grab_focus")
	$GUI/FoilAdjust/Focus.connect("pressed", AdjustFoil, "grab_focus")
	$GUI/FoilOffset/Focus.connect("pressed", OffsetFoil, "grab_focus")
	
	$GUI/FoilRotate/Rot0.connect(  "pressed", self, "RotateGradient", [0])
	$GUI/FoilRotate/Rot90.connect( "pressed", self, "RotateGradient", [90])
	$GUI/FoilRotate/Rot180.connect("pressed", self, "RotateGradient", [180])
	$GUI/FoilRotate/Rot270.connect("pressed", self, "RotateGradient", [270])
	$GUI/FoilRotate/Rot360.connect("pressed", self, "RotateGradient", [360])
	
	$Card/TitleBar/TitleTrigger.connect("mouse_entered", TitleInput, "set_modulate", [Color(1.2, 1.2, 1.2)])
	$Card/TitleBar/TitleTrigger.connect("mouse_exited", TitleInput, "set_modulate", [Color.white])
	$Card/TitleBigTrigger.connect("mouse_entered", TitleInput, "set_modulate", [Color(1.2, 1.2, 1.2)])
	$Card/TitleBigTrigger.connect("mouse_exited", TitleInput, "set_modulate", [Color.white])
	$Card/NameTrigger.connect("mouse_entered", NameInput, "set_modulate", [Color(1.2, 1.2, 1.2)])
	$Card/NameTrigger.connect("mouse_exited", NameInput, "set_modulate", [Color.white])
	$Card/TokenBarTop/TokensTopTrigger.connect("mouse_entered", Tokens, "set_modulate", [Color(1.2, 1.2, 1.2)])
	$Card/TokenBarTop/TokensTopTrigger.connect("mouse_exited", Tokens, "set_modulate", [Color.white])
	$Card/TokenBarBottom/TokensBottomTrigger.connect("mouse_entered", Tokens, "set_modulate", [Color(1.2, 1.2, 1.2)])
	$Card/TokenBarBottom/TokensBottomTrigger.connect("mouse_exited", Tokens, "set_modulate", [Color.white])
	
	$GUI/Clover.connect("pressed", OS, "shell_open", ["https://boards.4channel.org/vg/"])
	$GUI/Random.connect("pressed", self, "Randomize")
	$ExportDialog/Cancel.connect("pressed", ExportDialog, "hide")
	ImageX.connect("value_changed", self, "SetImageOffsetX")
	ImageY.connect("value_changed", self, "SetImageOffsetY")
	ImageRotate.connect("value_changed", self, "SetImageRotation")
	ImageScale.connect("value_changed", self, "SetImageScale")
	Flip.connect("toggled", self, "SetImageMirror")
	Lock.connect("toggled", self, "ToggleLock")

	Reset.connect("pressed", self, "ResetImage")
	Download.connect("pressed", Download, "set_disabled", [true])
	Download.connect("pressed", self, "GenerateImage")
	SaveDialog.connect("dir_selected", self, "DownloadImage")
	SaveDialog.connect("file_selected", self, "DownloadImage")
	LoadDialog.connect("file_selected", self, "ImportImage")
	HTTP.connect("request_completed", self, "LoadImageFromWeb")
	RequestTimeout.connect("timeout", self, "Error", ["Connection timed out, make sure the image is public"])
	
	Export.connect("pressed", self, "GenerateCode")
	Import.connect("pressed", self, "EnterCode")
	Undo.connect("pressed", self, "UndoAction")
	
	CodeField.connect("focus_entered", CodeField, "select_all")
	Clipboard.connect("pressed", self, "CodeToClipboard")
	Nais.connect("pressed", self, "DownloadData")
	NovelAI.connect("pressed", OS, "shell_open", ["https://novelai.net"])
	
	# Fill "Shirts" container with samples
	var patterns_count = 0
	var patterns_dir = Directory.new()
	patterns_dir.open("res://Patterns")
	patterns_dir.list_dir_begin()
	# Count all patterns within folder
	while true:
		var file = patterns_dir.get_next()
		if file.get_file().left(4) == "patt" and file.get_extension() == "png":
			patterns_count += 1
		if file == "":
			break
	patterns_dir.list_dir_end()
	# Generate patterns
	for i in patterns_count:
		var new_shirt = shirt_sample.instance()
		Shirts.add_child(new_shirt)
		var prev_path = str("preview", i + 1, ".png")
		new_shirt.Btn.texture_normal = load("res://Patterns/" + prev_path)
		new_shirt.Frame(false)	# Disable highlight
		new_shirt.Btn.connect("pressed", self, "PatternSet", [i + 1])
		new_shirt.set_name(str("A", i + 1))
		SHIRTS[i + 1] = new_shirt
	
	# Apply default settings and UI states
	InitData()
	ToggleLock(false)
	Title.text = "TITLE"
	TitleBig.text = circle + "TITLE" + circle
	Name.text = circle + "NAME" + circle
	TokensTop.text = "???"
	TokensBottom.text = "???"
	PanelA.visible = false
	PanelB.visible = false
	PickerA.rect_position = Vector2(6, 5)
	PickerB.rect_position = Vector2(6, 5)
	if !HTML5.js: Upload.disabled = true
	$GUI/UpdateMode.visible = false
	
	var username
	if OS.has_environment("USERNAME"):
		username = OS.get_environment("USERNAME")
	else:
		username = "User"
	SaveDialog.current_dir = "/" + username + "/Desktop"
	SaveDialog.current_path = SaveDialog.current_dir + "/card.png"

# ==============================================================================
func _input(event):
	if Input.is_action_just_pressed("undo") and \
	!TitleInput.has_focus() and !NameInput.has_focus() and !Tokens.has_focus() and !Tokens.get_line_edit().has_focus():
		UndoAction()
	elif Input.is_action_just_pressed("toggle_lock") and \
	!TitleInput.has_focus() and !NameInput.has_focus() and !Tokens.has_focus() and !Tokens.get_line_edit().has_focus():
		ToggleLock()
	elif Input.is_action_just_pressed("export_nais"):
		GenerateCode(false)	# Create string first to download it from LineEdit
		DownloadData()
	elif Input.is_action_just_pressed("hide_tokens"):
		TokenBarTop.visible = false
		TokenBarBottom.visible = false
	elif Input.is_action_just_pressed("import_url"):
		RequestImageFromWeb()
	elif Input.is_action_just_pressed("import"):
		EnterCode()
	elif Input.is_action_just_pressed("export"):
		GenerateCode()
	elif Input.is_action_just_pressed("ui_accept"):
		TitleInput.release_focus()
		NameInput.release_focus()
		Tokens.release_focus()
	elif Input.is_action_just_pressed("random"):
		Randomize()
	elif Input.is_action_just_pressed("toggle_orb"):
		show_orb = !show_orb
		if show_orb:
			if !TypeB.pressed: ChangeType(0, 1)
			$Card/Orb.visible = true
		else:
			$Card/Orb.visible = false
	elif event is InputEventKey and event.pressed and \
	!TitleInput.has_focus() and !NameInput.has_focus() and !Tokens.has_focus() and !Tokens.get_line_edit().has_focus():
		var ev = event.scancode
		if ev in DigiKeys:
			PatternSet(DigiKeys[ev])
		
	if Input.is_action_just_pressed("left_click"):
		mpos = get_viewport().get_mouse_position()
		if mpos.x < PanelA.rect_global_position.x or \
		mpos.x > PanelA.rect_global_position.x + PanelA.rect_size.x or \
		mpos.y < PanelA.rect_global_position.y or \
		mpos.y > PanelA.rect_global_position.y + PanelA.rect_size.y:
			if mpos.x < ColorA.rect_global_position.x or \
			mpos.x > ColorA.rect_global_position.x + ColorA.rect_size.x or \
			mpos.y < ColorA.rect_global_position.y or \
			mpos.y > ColorA.rect_global_position.y + ColorA.rect_size.y:
				PanelA.visible = false
			if mpos.x < ColorB.rect_global_position.x or \
			mpos.x > ColorB.rect_global_position.x + ColorB.rect_size.x or \
			mpos.y < ColorB.rect_global_position.y or \
			mpos.y > ColorB.rect_global_position.y + ColorB.rect_size.y:
				PanelB.visible = false

# ==============================================================================
# Default settings
# [!!!] Gotta replace 10 with gradient colors list, 11 with invert flags
func InitData():
	UpdateNameFontSize()								# 0,3 Continues to ChangeName()
	UpdateTitleFontSize()								# 1,4 Continues to ChangeTitle()
	ChangeTokens(Tokens.value)							# 2
	ToggleTitle(TitleToggle.pressed)					# 5
	MoveTokens(TokenPos.pressed)						# 6
	ChangeType(0, 0)									# 7
	PatternSet(1)										# 8
	PatternOpacity(ShirtOpacity.value)					# 9
	ColorGradient(SampleA.color, 0)						# 10
	ColorGradient(SampleB.color, 1)						# 11
	RotateGradient(RotateFoil.value)					# 12
	AdjustGradient()									# 13
	SetImageOffsetX(ImageX.value)						# 14
	SetImageOffsetY(ImageY.value)						# 15
	SetImageRotation(ImageRotate.value)					# 16
	SetImageScale(ImageScale.value)						# 17
	SetImageMirror(0)									# 18
	ToggleEmboss(0)										# 19
	BUFFER = [[], [], [], [], [], [], [], [], [], []]
	BUFFER[0] = DATA.duplicate(true)
	Undo.disabled = true





# ==============================================================================
func __________UTILITY(): pass

# ==============================================================================
# Display a custom error message (add [×n] if it's a repeated message)
func Error(text=""):
	Source.visible = false
	if !text:
		ErrorText.text = ""
		ErrorText.visible = false
		return
	var split = ErrorText.text.split("​")
	if text == split[0]:
		var num = split[-1]
		if num:
			num = int(split[-1].lstrip(" [×").rstrip("]")) + 1
			text += "​ [×" + str(num) + "]"
		else:
			text += "​ [×2]"
	else:
		text += "​"
	ErrorText.text = text
	ErrorText.visible = true

# ==============================================================================
# Check if two values and their type are identic
func IsEqual(varianta, variantb):
	if typeof(varianta) != typeof(variantb): return false
	if varianta != variantb: return false
	return true

# ==============================================================================
# Parse raw image bytes for embed lorebook data to display a warning
func SearchForMeta(byte):
	var header = [110, 97, 105, 100, 97, 116, 97]
	for i in byte.size():
		for n in 7:
			if byte[i + n] != header[n]:
				break
			return i
	return false

# ==============================================================================
# Create window screenshot and crop it by card dimensions
func GetCapture():
	capture = get_viewport().get_texture().get_data()
	capture.flip_y()
	capture.convert(Image.FORMAT_RGBA8)
	capture.crop(400, 600)

# ==============================================================================
# Short white flash effect to play after "Download" button is pressed 
func DoFlash():
	Flash.visible = true
	FlashTween.interpolate_property(Flash, "modulate:a", 1.0, 0.0, 0.7, Tween.TRANS_SINE, Tween.EASE_OUT)
	FlashTween.start()





# ==============================================================================
func __________IMPORT(): pass

# ==============================================================================
# Process drag & dropped file (image or nais/txt with template data)
func FilesDropped(files, _screen=0):
	Error()	# Hide last error message
	# File is of image type
	if files[0].get_extension().to_lower() in ["jpg", "jpeg", "png", "bmp", "tga", "webp"]:
		if UpdateTokens.pressed:
			image_temp.load(files[0])
			if image_temp.get_size() != Vector2(400, 600):
				Error("Card must have size of 400×600 pixels")
				return
			OriginalSetAlpha()
			return
		image = Image.new()
		image.load(files[0])
		# Is readable
		if image:
			# Check if there is NAI data appended to an image
			var file = File.new()
			file.open(files[0], file.READ)
			var byte = Array(file.get_buffer(128))
			var istart = SearchForMeta(byte)
			if istart: Error("This card has embed data that will NOT be saved")
			# Write template info and load image to the viewport
			SetData(files[0].get_file(), 20)
			LoadImage()
		
		else:
			image = null
			Error("Cannot read this file")
	
	# File is of text type
	elif files[0].get_extension().to_lower() in ["txt", "nais"]:
		var file = File.new()
		file.open(files[0], file.READ)
		# Check SetData() for formatting details
		var raw = file.get_line()
		if raw.split("&&").size() > 21:
			LoadData(raw)
		else:
			Error("Data has wrong format")
	
# ==============================================================================
# Try to request background image from web link if it ends with image extension
func RequestImageFromWeb():
	var link = JavaScript.eval('prompt("ENTER the direct LINK to an image.\\r\\nLink should end with an extension and have a public access.");')
#	link = OS.get_clipboard()	# [!!!!!]
	if modal_open: return	# Prevent multiple ongoing cycles
	modal_open = true
	while !link:
		yield(get_tree(), "idle_frame")
	modal_open = false
	
	await = link.rstrip("\\/").get_extension().to_lower()
	if !await in ["jpg", "jpeg", "png", "bmp", "tga", "webp"]:
		Error("Direct image link required (ends with extension)")
		return
	HTTP.request(link)
	Error("Requesting image...")
	RequestTimeout.start()

# ==============================================================================
func LoadImageFromWeb(_result, response_code, _headers, body):
	RequestTimeout.stop()
	Error("Downloading...")
	image = Image.new()
	if await in ["jpg", "jpeg"]:
		if image.load_jpg_from_buffer(body) != OK:
			Error(str("Unidentified compression method"))
			return
	elif await == "png":
		if image.load_png_from_buffer(body) != OK:
			Error(str("Unidentified compression method"))
			return
	elif await == "webp":
		if image.load_webp_from_buffer(body) != OK:
			Error(str("Unidentified compression method"))
			return
	elif await == "bmp":
		if image.load_bmp_from_buffer(body) != OK:
			Error(str("Unidentified compression method"))
			return
	elif await == "tga":
		if image.load_tga_from_buffer(body) != OK:
			Error(str("Unidentified compression method"))
			return
	if image:
		Error()
		LoadImage()
	else:
		if response_code == 404:
			Error(str("Error ", response_code, ": Image not found"))
		else:
			Error(str("Error ", response_code))

# ==============================================================================
# File import via file dialog (not used anymore)
func ImportImage(path):
	Error()	# Clear errors
	image = Image.new()
	image.load(path)
	if image:
		SetData(path.get_file(), 20)
		LoadImage()
	else:
		image = null
		Error("Manual import failed: try to drag and drop instead")

# ==============================================================================
# Update tokens count for an existing card (small green button)
# Cut out a fragment of uploaded image at token bar's position
func OriginalSetAlpha():
	var upper = Rect2(298, 28, 77, 27)
	var lower_a = Rect2(298, 506, 77, 27)
	var lower_b = Rect2(298, 466, 77, 27)
	var alpha
	var color
	image_temp.lock()
	
	alpha = 1 - int(TokenPos.pressed)
	for y in range(upper.position.y, upper.position.y + upper.size.y):
		for x in range(upper.position.x, upper.position.x + upper.size.x):
			color = image_temp.get_pixel(x, y)
			color.a = alpha
			image_temp.set_pixel(x, y, color)
	alpha = int(TypeB.pressed)
	if TokenPos.pressed: alpha = 1
	for y in range(lower_a.position.y, lower_a.position.y + lower_a.size.y):
		for x in range(lower_a.position.x, lower_a.position.x + lower_a.size.x):
			color = image_temp.get_pixel(x, y)
			color.a = alpha
			image_temp.set_pixel(x, y, color)
	alpha = int(TypeA.pressed)
	if TokenPos.pressed: alpha = 1
	for y in range(lower_b.position.y, lower_b.position.y + lower_b.size.y):
		for x in range(lower_b.position.x, lower_b.position.x + lower_b.size.x):
			color = image_temp.get_pixel(x, y)
			color.a = alpha
			image_temp.set_pixel(x, y, color)
	
	image_temp.unlock()
	var image_tex_temp = ImageTexture.new()
	image_tex_temp.create_from_image(image_temp)
	$GUI/UpdateMode/Original.set_texture(image_tex_temp)
	Download.disabled = false

# ==============================================================================
# Set image scale slider's values according to uploaded image's pixel size
func UpdateScaleRange(keep=true):
	ImageScale.min_value = min_scale * 0.8
	if !keep: ImageScale.value = stepify(min_scale, 0.01)
	
# ==============================================================================
func LoadImage():
	if !image:
		Error("No image provided")
		return
	if image.get_width() == 0 or image.get_height() == 0:
		Error("Image has null size")
		return
	var size = image.get_size()
	# Keep 1:1 if image is another card presumably to fit the portrait
	if size == Vector2(400, 600):
		min_scale = 1.0
	else:
		var lesser = [360.0/size.x, 560.0/size.y]
		lesser.sort()
		min_scale = lesser[1]
	
	image_tex.create_from_image(image)
	image_tex.set_flags(13)
	Port.set_texture(image_tex)
	
	if !Lock.pressed: ResetTransforms()
	UpdateScaleRange(Lock.pressed)
	
#	show_orb = false
#	$Card/Orb.visible = false
	ExportDialog.hide()
	PanelA.hide()
	PanelB.hide()
	Download.disabled = false
#	Reset.disabled = false

# ==============================================================================
# Update DATA with provided values and change colors and sliders on scene
func LoadData(code):
	init_data = true
	var current_img = DATA[20]
	var DATA_RAW = code.split("&&")
	for i in DATA.size():
		DATA[i] = DATA_RAW[i]
	for i in [2,3,4,5,6,7,8,9,12,13,14,15,16,17,18,19]:
		DATA[i] = float(DATA[i])
	
	ResetMaker()
	if !image:
		ResetImage(false)
	
	UpdateNameFontSize( DATA[3], DATA[0])	# 0,3 Continues to ChangeName()
	UpdateTitleFontSize(DATA[4], DATA[1])	# 1,4 Continues to ChangeTitle()
	ChangeTokens(DATA[2])					# 2
	ToggleTitle(DATA[5])					# 5
	MoveTokens(DATA[6])						# 6
	ChangeType(0, DATA[7])					# 7
	PatternSet(DATA[8])						# 8
	PatternOpacity(DATA[9])					# 9
	ColorGradient(DATA[10], 0, false)		# 10
	ColorGradient(DATA[11], 1, false)		# 11
	RotateGradient(DATA[12])				# 12
	AdjustGradient(0, DATA[13])				# 13
	if !Lock.pressed:
		SetImageOffsetX(DATA[14])			# 14
		SetImageOffsetY(DATA[15])			# 15
		SetImageRotation(DATA[16])			# 16
		SetImageScale(DATA[17])				# 17
		SetImageMirror(DATA[18])			# 18
	ToggleEmboss(DATA[19])					# 19
	if !IsEqual(str(DATA[20]), "0") and !IsEqual(current_img, DATA[20]):
		Source.clear()
		Source.push_meta(DATA[20])
		Source.add_text(DATA[20])
		Source.pop()
		Source.visible = true
	show_orb = false
	$Card/Orb.visible = false
	init_data = false
#	Lock.pressed = true

# ==============================================================================
# Open JS dialog to paste nais code or read clipboard if run from desktop
func EnterCode():
	var code
	if HTML5.js:
		code = JavaScript.eval('prompt("ENTER a card preset CODE or drag&drop a .nais file.\\r\\nRemember to lock transforms before loading an image.");')
		while !code:
			yield(get_tree(), "idle_frame")
	else:
		code = OS.get_clipboard()
	if !code or code.split("&&").size() < 21:
		if HTML5.js:
			Error("Cannot read the format")
		else:
			Error("Clipboard empty or wrong template format")
		return
	LoadData(code)





# ==============================================================================
func __________EXPORT(): pass

# ==============================================================================
func GenerateImage():
	Error()	# Clean errors
	# Display a warning if trying to generate card with no token count specified
	if TokensTop.text == "???":
		Error("Please specify the tokens count")
		# Flicker VFX
		var tween = Tokens.get_node("Line2D/Tween")
		var frame = Tokens.get_node("Line2D")
		tween.stop_all()
		tween.interpolate_property(frame, "default_color", Color.red, Color(0.56,0.56,0.56), 0.7, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(Tokens, "modulate", Color(3, 1, 1), Color.white, 0.7, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.start()
		return
	
	GetCapture()	# Make a screenshot of a window
	capture.lock()	# Lock screenshot for applying alpha
	# Generate alpha mask for rounding card's corners
	var mask = CardMask.texture.get_data()
	mask.lock()		# Lock mask for reading
	var outline = Outline.color	# Card outline (averaged background color)
	var color		# Current pixel's color
	var alpha		# Current pixel's alpha according to mask
	for x in 400:
		for y in 600:
			alpha = mask.get_pixel(x, y).a
			# If not transparent (not a corner), keep original color
			if alpha == 1:	# [!] Why is card transparent without this check???
				color = capture.get_pixel(x, y)	# Read pixel of a screenshot
				color.a = 1
				capture.set_pixel(x, y, color)
				continue # Proceed to next pixel
			# Otherwise apply outline's color
			outline.a = alpha
			capture.set_pixel(x, y, outline)
	mask.unlock()
	
	# I forgot what this does   (o_ o )
#	if !image:
#		var shadow = Shadow.texture.get_data()
#		var outcol = Foil.texture.gradient.interpolate(0.5)
#		mask = FaceMask.texture.get_data()
#		shadow.lock()
#		mask.lock()
#		for x in 400:
#			for y in 600:
#				alpha = mask.get_pixel(x, y).a
#				if alpha:
#					color = outcol
#					color *= 1 - alpha
#					color.a = 1 - alpha
#					color += shadow.get_pixel(x, y)
#					capture.set_pixel(x, y, color)
#		shadow.unlock()
#		mask.unlock()
		
	capture.unlock()
	DownloadImage()
	
# ==============================================================================
# Save generated card as PNG at browser's default download path
func DownloadImage(_path=""):
	var file_name = NameInput.text.to_upper().replace(" ", "-")	# Spaces bad
	if !file_name: file_name = "card"
	
	if HTML5.js: HTML5.SaveImage(capture, file_name)
	else:
		capture.save_png("res://" + file_name + ".PNG")	# Application directory
		DoFlash()

# ==============================================================================
# Only works via javascript (check HTML5.gd)
func CodeToClipboard(text=CodeField.text):
	if HTML5.js: HTML5.ToClipboard(text)
	else: OS.set_clipboard(text)
	ExportDialog.hide()

# ==============================================================================
func GenerateCode(popup=true):
	# Add timestamp
	var time = OS.get_datetime()
	DATA[21] = str(
		time["year"], "-",
		"0".left(int(time["month"] < 10)), time["month"], "-",
		"0".left(int(time["day"] < 10)), time["day"], "|",
		"0".left(int(time["hour"] < 10)), time["hour"], ":",
		"0".left(int(time["minute"] < 10)), time["minute"], ":",
		"0".left(int(time["second"] < 10)), time["second"])
	var code = ""
	for par in DATA:
		code += str(par) + "&&"
	if show_orb:
		code += "1"
	code = code.rstrip("&")
	CodeField.text = code
	if popup: ExportDialog.popup()

# ==============================================================================
# Save formatted DATA as .nais file
func DownloadData(code=CodeField.text):
	var file_name = NameInput.text.to_upper().replace(" ", "-")	# Spaces bad
	if !file_name: file_name = "card"
	if HTML5.js: HTML5.SaveData(code, file_name)
	else:
		var file = File.new()
		file.open("res://" + file_name + ".NAIS", file.WRITE)
		file.store_string(code)
		file.close()
	ExportDialog.hide()





# ==============================================================================
func __________DATA(): pass

# ==============================================================================
# Change DATA value at certain position (bools are written as ints)
# When exported as code, everything is converted to string with "&&" delimiter
#
#  0: Name (String)
#  1: Title (String)
#  2: Tokens amount (int)
#  3: Name font size (int)
#  4: Title font size (int)
#  5: Title visibility for Type A template (int) 0=off 1=on
#  6: Token bar position (int) 0=bottom 1=top
#  7: Card template type (int) 0=thin+bar 1=solid
#  8: Pattern id (int) from 1 to 10
#  9: Pattern opacity (int) as alpha in range 0...255
# 10: Card color A (String) first gradient color in format #??????
# 11: Card color B (String) second gradient color in format #??????
# 12: Card gradient angle degrees (int) 0...360 
# 13: Gradient shift and traisition (float) read info under [*] below
# 14: Image offset horizontal (int)
# 15: Image offset vertical (int)
# 16: Image rotation degrees (int)
# 17: Image scale modifier (float)
# 18: Image horizontal flip (int) 0=original 1=mirrored
# 19: Emboss effect (int) 0=off 1=on
# 20: Used image name and extension (String) i.e. unnamed.png
# 21: Time and date (String) doesn't affect anything
#
# [*] Card colors are stored in Gradient resource with 4 nodes
#     0 and 1 are of color A, 2 and 3 are of color B
#     Nodes 0 and 3 have fixed positions while 1 and 2 can be moved around
#     DATA[13] stores a float that consists of two values:
#     Whole number (?.X, range -50...50) defines an offset to left or right
#     Fraction (X.?, range 0.05...0.5) defines distance between nodes 1 and 2
#     Fraction is independant and number -25.12 results in same distance as 9.12
func SetData(value, id):
	if init_data: return
	
	# Changed the same parameter as last time
	if last_changed == id and id != 8 and BUFFER[1]:
		# Update the latest entry of undo history
		BUFFER[0] = DATA.duplicate(true)
		DATA[id] = value	# WRITE DATA
	# Changed new paramter
	else:
		DATA[id] = value	# WRITE DATA
		# Add new entry to undo history
		if BUFFER[0] != DATA:
			# [[latest], [...], [oldest]] ---> [[latest], [...]]
			BUFFER.pop_back()
			# [[latest], [...]] ---> [[current], [latest], [...]]
			BUFFER.push_front(DATA.duplicate(true))
			last_changed = id
	
	Undo.disabled = true
	if BUFFER[1] != []:
		Undo.disabled = false

# ==============================================================================
func ChangeName(text=NameInput.text):
	text = text.to_upper()
	if !text: text = "NAME"
	if !NameInput.has_focus(): NameInput.text = text	# CHANGE FIELD
	Name.text = circle + text + circle
	$Card/NameBackdrop1.text = circle + text + circle
	$Card/NameBackdrop2.text = circle + text + circle
	$Card/NameBackdrop3.text = circle + text + circle
	SetData(text.to_upper(), 0)

# ==============================================================================
func ChangeTitle(text=TitleInput.text):
	text = text.to_upper()
	if !text: text = "TITLE"
	if !TitleInput.has_focus(): TitleInput.text = text	# CHANGE FIELD
	Title.text = text
	TitleBig.text = circle + text + circle
	$Card/TitleBigBackdrop1.text = circle + text + circle
	$Card/TitleBigBackdrop2.text = circle + text + circle
	$Card/TitleBigBackdrop3.text = circle + text + circle
	SetData(text.to_upper(), 1)

# ==============================================================================
func ChangeTokens(val=200):
	Error()
	Tokens.value = val	# CHANGE FIELD
	TokensBottom.text = str(val)
	TokensTop.text = str(val)
	Download.disabled = false
	SetData(val, 2)

# ==============================================================================
func UpdateNameFontSize(size=NameSize.value, text=""):
	NameSize.value = size	# CHANGE FIELD
	
	name_font = font_serif.duplicate()
	name_font.set_size(size)
	name_font.set_outline_size(1)
	name_font.set_outline_color(Color(0, 0, 0, 0.060 + size / 1600.0))
	Name.add_font_override("font", name_font)
	
	name_font = font_serif.duplicate()
	name_font.set_size(size)
	name_font.set_outline_size(2)
	name_font.set_outline_color(Color(0, 0, 0, 0.045 + size / 2400.0))
	$Card/NameBackdrop1.add_font_override("font", name_font)
	
	name_font = font_serif.duplicate()
	name_font.set_size(size)
	name_font.set_outline_size(3 + int(size > 42))
	name_font.set_outline_color(Color(0, 0, 0, 0.030 + size / 3600.0))
	$Card/NameBackdrop2.add_font_override("font", name_font)
	
	name_font = font_serif.duplicate()
	name_font.set_size(size)
	name_font.set_outline_size(4 + int(size > 30) + int(size > 42))
	name_font.set_outline_color(Color(0, 0, 0, 0.015 + size / 4200.0))
	$Card/NameBackdrop3.add_font_override("font", name_font)
	
	# Fix position if label rect transforms due to too long name
	var newpos = -(Name.rect_size.x - 400) / 2
	$Card/NameBackdrop1.rect_size.x = Name.rect_size.x
	$Card/NameBackdrop2.rect_size.x = Name.rect_size.x
	$Card/NameBackdrop3.rect_size.x = Name.rect_size.x
	$Card/NameBackdrop1.rect_position.x = newpos
	$Card/NameBackdrop2.rect_position.x = newpos
	$Card/NameBackdrop3.rect_position.x = newpos
	Name.rect_position.x = newpos
	
	# Font size displayed on a slider
	NameSizeHint.text = str(size)
	if size == NameSize.max_value: NameSizeHint.text += "  "
	
	if text: ChangeName(text)
	else: ChangeName()
	SetData(size, 3)
	
# ==============================================================================
func UpdateTitleFontSize(size=TitleSize.value, text=""):
	TitleSize.value = size	# CHANGE FIELD
	
	title_font = font_serif.duplicate()
	title_font.set_size(size)
	title_font.set_outline_size(1)
	title_font.set_outline_color(Color(0, 0, 0, 0.060 + size / 1600.0))
	Title.add_font_override("font", title_font)
	TitleBig.add_font_override("font", title_font)
	
	title_font = font_serif.duplicate()
	title_font.set_size(size)
	title_font.set_outline_size(2)
	title_font.set_outline_color(Color(0, 0, 0, 0.045 + size / 2400.0))
	$Card/TitleBigBackdrop1.add_font_override("font", title_font)
	
	title_font = font_serif.duplicate()
	title_font.set_size(size)
	title_font.set_outline_size(3)
	title_font.set_outline_color(Color(0, 0, 0, 0.030 + size / 3600.0))
	$Card/TitleBigBackdrop2.add_font_override("font", title_font)
	
	title_font = font_serif.duplicate()
	title_font.set_size(size)
	title_font.set_outline_size(4 + int(size > 30))
	title_font.set_outline_color(Color(0, 0, 0, 0.015 + size / 4200.0))
	$Card/TitleBigBackdrop3.add_font_override("font", title_font)
	
	# Fix position if label rect transforms due to too long title
	var newpos = -(TitleBig.rect_size.x - 400) / 2
	$Card/TitleBigBackdrop1.rect_size.x = TitleBig.rect_size.x
	$Card/TitleBigBackdrop2.rect_size.x = TitleBig.rect_size.x
	$Card/TitleBigBackdrop3.rect_size.x = TitleBig.rect_size.x
	$Card/TitleBigBackdrop1.rect_position.x = newpos
	$Card/TitleBigBackdrop2.rect_position.x = newpos
	$Card/TitleBigBackdrop3.rect_position.x = newpos
	TitleBig.rect_position.x = newpos
	
	# Font size displayed on a slider
	TitleSizeHint.text = str(size)
	if size == TitleSize.max_value: TitleSizeHint.text += "  "
	
	if text: ChangeTitle(text)
	else: ChangeTitle()
	SetData(size, 4)

# ==============================================================================
func ToggleTitle(state=null):
	TitleBar.visible = state
	TitleToggle.pressed = TitleBar.visible	# CHANGE FIELD
	TitleToggle.text = ["SHOW", "HIDE"][int(TitleBar.visible)]
	SetData(int(TitleBar.visible), 5)

# ==============================================================================
func MoveTokens(state):
	TokenPos.pressed = state	# CHANGE FIELD
	state = bool(state)
	TokenBarBottom.visible = !state
	TokenBarTop.visible = state
	TokenPos.get_node("Hint").align = 0 if state else 2
	if UpdateTokens.pressed: OriginalSetAlpha()	# [!] Update mode
	SetData(int(state), 6)

# ==============================================================================
func ChangeType(_state, type):
	if switch_type: return
	SetData(type, 7)
	switch_type = true
	if type == 0:	# A
		TypeA.pressed = true	# CHANGE FIELD
		TypeB.pressed = false	# CHANGE FIELD
		TitleBig.visible = false
		$Card/TitleBigTrigger.visible = false
		TitleBar.visible = true
		Title.visible = true
		TitleToggle.disabled = false
		TokenBarBottom.position.y = 538
		FaceMask.texture = load("res://Card/mask_face_A.png")
		FrameMask.texture = load("res://Card/mask_frame_A.png")
		Shadow.texture = load("res://Card/shadow_A.png")
		Emboss.texture = load("res://Card/emboss_A.png")
		$Card/Orb.visible = false
	elif type == 1:	# B
		TypeB.pressed = true	# CHANGE FIELD
		TypeA.pressed = false	# CHANGE FIELD
		TitleBig.visible = true
		$Card/TitleBigTrigger.visible = true
		TitleBar.visible = false
		Title.visible = false
		TitleToggle.disabled = true
		TokenBarBottom.position.y = 498
		FaceMask.texture = load("res://Card/mask_face_B.png")
		FrameMask.texture = load("res://Card/mask_frame_B.png")
		Shadow.texture = load("res://Card/shadow_B.png")
		Emboss.texture = load("res://Card/emboss_B.png")
		if show_orb: $Card/Orb.visible = true
	if UpdateTokens.pressed: OriginalSetAlpha()	# [!] Update mode
	switch_type = false

# ==============================================================================
func PatternSet(id):
	var shirt_picked = SHIRTS.get(id)
	shirt_picked.Activate()	# CHANGE FIELD
	var path = str("pattern", id)
	Pattern.texture = load("res://Patterns/" + path + ".png")
	SetData(id, 8)
	
# ==============================================================================
func PatternOpacity(alpha):
	ShirtOpacity.value = alpha	# CHANGE FIELD
	Pattern.visible = false if !alpha else true
	Pattern.modulate.a = alpha/256.0
	SetData(alpha, 9)

# ==============================================================================
func InvertPatternTop(arg):
	var mat = Pattern.get_material()
	mat.set_shader_param("invert_top", arg)

# ==============================================================================
func InvertPatternBot(arg):
	var mat = Pattern.get_material()
	mat.set_shader_param("invert_bot", arg)

# ==============================================================================
func ColorGradient(color, id, link=true):
	if color is String: color = Color("#" + color)
	if !id:	# A
		Foil.texture.gradient.set_color(0, color)
		Foil.texture.gradient.set_color(1, color)
		SetColorA(color)		# CHANGE FIELD
		if Mono.pressed and link:
			color *= 0.6
			color.a = 1
			SetColorB(color)	# CHANGE FIELD
			Foil.texture.gradient.set_color(2, color)
			Foil.texture.gradient.set_color(3, color)
		SetData(color.to_html(false).to_upper(), 10)
	else:	# B
		Foil.texture.gradient.set_color(2, color)
		Foil.texture.gradient.set_color(3, color)
		SetColorB(color)		# CHANGE FIELD
		if Mono.pressed and link:
			color *= 1.8
			color.a = 1
			SetColorA(color)	# CHANGE FIELD
			Foil.texture.gradient.set_color(0, color)
			Foil.texture.gradient.set_color(1, color)
		SetData(color.to_html(false).to_upper(), 11)
	ColorOutline()

# ==============================================================================
func RotateGradient(angle=60):
	RotateFoil.value = angle	# CHANGE FIELD
	Foil.rotation_degrees = angle
	SetData(angle, 12)

# ==============================================================================
func AdjustGradient(_value=0, force=0):
	var adjust = fmod(AdjustFoil.value, 1)
	var offset = int(OffsetFoil.value)
	if adjust < 0.05:  adjust = 0.05
	elif adjust > 0.5: adjust = 0.5
	if force:
		adjust = abs(fmod(force, 1))
		offset = int(force)
		if adjust < 0.05:  adjust = 0.05
		elif adjust > 0.5: adjust = 0.5
		AdjustFoil.value = adjust	# CHANGE FIELD
		OffsetFoil.value = offset	# CHANGE FIELD
	var combine = abs(offset) + adjust
	if offset < 0: combine *= -1
	SetData(combine, 13)
	
	offset /= 75.0
	var left = adjust
	var right = 1 - adjust
	if offset < 0:
		left -= left * abs(offset)
		right -= right * abs(offset)
	else:
		left += adjust * abs(offset)
		right += adjust * abs(offset)
	
	# Do it twice because some bizarre rounding error (variables are correct)
	Foil.texture.gradient.set_offset(1, left)
	Foil.texture.gradient.set_offset(2, right)
	Foil.texture.gradient.set_offset(1, left)
	Foil.texture.gradient.set_offset(2, right)
	
	ColorGradient(SampleA.color, 0, false)
	ColorGradient(SampleB.color, 1, false)

# ==============================================================================
func SetImageOffsetX(x=0):
	ImageX.value = x	# CHANGE FIELD
	Port.position.x = 200 + x
	SetData(x, 14)

# ==============================================================================
func SetImageOffsetY(y=0):
	ImageY.value = y	# CHANGE FIELD
	Port.position.y = 300 + y
	SetData(y, 15)

# ==============================================================================
func SetImageRotation(angle=0):
	ImageRotate.value = angle	#CHANGE FIELD
	Port.rotation_degrees = angle
	SetData(angle, 16)

# ==============================================================================
func SetImageScale(scale=min_scale):
	ImageScale.value = scale	# CHANGE FIELD
	Port.scale = Vector2(1, 1) * scale
	SetData(scale, 17)

# ==============================================================================
func SetImageMirror(state=!Port.flip_h):
	Port.flip_h = state
	SetData(int(Port.flip_h), 18)





# ==============================================================================
func __________EDITOR(): pass

# ==============================================================================
func ToggleEmboss(state):
	EmbossToggle.pressed = state	# CHANGE FIELD
	Emboss.visible = state
	EmbossToggle.get_node("Hint").align = 0 if state else 2
	SetData(int(state), 19)

# ==============================================================================
func ColorOutline():
	Outline.color = Foil.texture.gradient.interpolate(0.5)

# ==============================================================================
func ColorSwap():
	var buffer = PickerA.color
	SetColorA(PickerB.color)	# CHANGE FIELD
	SetColorB(buffer)			# CHANGE FIELD
	Foil.texture.gradient.set_color(0, PickerA.color)
	Foil.texture.gradient.set_color(1, PickerA.color)
	Foil.texture.gradient.set_color(2, PickerB.color)
	Foil.texture.gradient.set_color(3, PickerB.color)

# ==============================================================================
func ResetTransforms():
	ImageX.value = 0
	ImageY.value = 0
	ImageRotate.value = 0
	ImageScale.value = 1
	SetImageMirror(false)

# ==============================================================================
func ResetImage(flush=true):
	image = null
	Port.texture = null
	Download.text = "DOWNLOAD"
	Download.disabled = false	# [!] Inverted
	if flush: DATA[20] = 0
	if !Lock.pressed: ResetTransforms()
	
# ==============================================================================
func ResetMaker():
	ExportDialog.hide()
	PanelA.hide()
	PanelB.hide()
	Mono.pressed = false
#	Reset.disabled = true
	
# ==============================================================================
func SetColorA(color):
	SampleA.color = color
	PickerA.color = color

# ==============================================================================
func SetColorB(color):
	SampleB.color = color
	PickerB.color = color

# ==============================================================================
# Release focus from tokens text box
func FreeTokens(_omit=0):
	Tokens.get_line_edit().release_focus()
	Tokens.release_focus()

# ==============================================================================
# Roll a random design
func Randomize():
	ColorGradient(Color(randf(), randf(), randf()), 0)
	ColorGradient(Color(randf(), randf(), randf()), 1)
	RotateGradient(randi() % 360)
	AdjustGradient(0, (randi() % 30 + 0.05 + randf() / 4.0) * [1, -1][randi() % 2])
	PatternSet(randi() % Shirts.get_child_count() + 1)
	PatternOpacity(randi() % 96)

# ==============================================================================
# Lock image rotation & position on new image import
func ToggleLock(state=!Lock.pressed):
	Lock.pressed = state
	if state:
		Lock.get_node("Line2D").visible = true
		Lock.self_modulate = Color("#99BB99")
	else:
		Lock.get_node("Line2D").visible = false
		Lock.self_modulate = Color("#AA7777")

# ==============================================================================
# Image source is displayed on template import, clicking it will copy the path
func CopyImageName(text):
	CodeToClipboard(text)
	Source.hide()	# Hide image reference info displayed instead of errors line

# ==============================================================================
# Load previously saved DATA array from BUFFER
func UndoAction():
	BUFFER.pop_front()
	BUFFER.push_back([])
	var i = 0
	if BUFFER[0]:
		init_data = true
		UpdateNameFontSize( BUFFER[i][3], BUFFER[i][0])	# 0,3 Continues to ChangeName()
		UpdateTitleFontSize(BUFFER[i][4], BUFFER[i][1])	# 1,4 Continues to ChangeTitle()
		ChangeTokens(BUFFER[i][2])						# 2
		ToggleTitle(BUFFER[i][5])						# 5
		MoveTokens(BUFFER[i][6])						# 6
		ChangeType(0, BUFFER[i][7])						# 7
		PatternSet(BUFFER[i][8])						# 8
		PatternOpacity(BUFFER[i][9])					# 9
		ColorGradient(BUFFER[i][10], 0, false)			# 10
		ColorGradient(BUFFER[i][11], 1, false)			# 11
		RotateGradient(BUFFER[i][12])					# 12
		AdjustGradient(0, BUFFER[i][13])				# 13
		SetImageOffsetX(BUFFER[i][14])					# 14
		SetImageOffsetY(BUFFER[i][15])					# 15
		SetImageRotation(BUFFER[i][16])					# 16
		SetImageScale(BUFFER[i][17])					# 17
		SetImageMirror(BUFFER[i][18])					# 18
		ToggleEmboss(BUFFER[i][19])						# 19
		init_data = false
		DATA = BUFFER[i].duplicate(true)
	Undo.disabled = true
	if BUFFER[1]:
		Undo.disabled = false
