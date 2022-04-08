# ==============================================================================
# From https://github.com/Pukkah/HTML5-File-Exchange-for-Godot
extends Node
# ==============================================================================

signal InFocus
var root
var js = true

# ==============================================================================
func _ready():
	if OS.get_name() == "HTML5" and OS.has_feature('JavaScript'):
		InitJS()
	else:
		js = false
		printerr("JavaScript will not work unless app is run in HTML5 environment")

# ==============================================================================
func _notification(notification:int) -> void:
	if notification == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		emit_signal("InFocus")

# ==============================================================================
func InitJS()->void:
	JavaScript.eval("""
	var fileName;
	
	function download(fileName, byte) {
		var buffer = Uint8Array.from(byte);
		var blob = new Blob([buffer], { type: 'image/png'});
		var link = document.createElement('a');
		link.href = window.URL.createObjectURL(blob);
		link.download = fileName;
		link.click();
	};
	function download_data(fileName, text_data) {
		var blob = new Blob([text_data], { type: 'text/plain;charset=utf-8'});
		var link = document.createElement('a');
		link.href = window.URL.createObjectURL(blob);
		link.download = fileName;
		link.click();
	};
	function to_clipboard(text_data) {
		navigator.clipboard.writeText(text_data);
	};
	function to_clipboard_alt(text_data) {
		const elem = document.createElement('textarea');
		elem.value = text_data;
		document.body.appendChild(elem);
		elem.select();
		document.execCommand('copy');
		document.body.removeChild(elem);
	};
	""", true)

# ==============================================================================
func SaveImage(image:Image, file_name:String = "export"):
	if !js:
		return false
	var path = "user://" + file_name + ".PNG"
	
	image.clear_mipmaps()
	if image.save_png(path):	# Create temporary image file
		return false
	
	var file = File.new()
	if file.open(path, File.READ):	# Open with file to read its data
		return false
	
	var png_data = Array(file.get_buffer(file.get_len()))	# Convert image data to PoolByteArray
	file.close()
	var dir = Directory.new()
	dir.remove(path)	# Clear temporary file
	JavaScript.eval("download('%s', %s);" % [file_name, str(png_data)], true)
	
	# Saving VFX
	root.DoFlash()
	
	return true

# ==============================================================================
func SaveData(data:String, file_name:String = "export"):#->void:
	JavaScript.eval("download_data('%s', '%s');" % [file_name + ".NAIS", data], true)
	return true

# ==============================================================================
func ToClipboard(text_data):
	JavaScript.eval("to_clipboard('%s');" % [text_data], true)
	JavaScript.eval("to_clipboard_alt('%s');" % [text_data], true)
