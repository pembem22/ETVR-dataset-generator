extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.show_json.connect(set_text)

#func set_text(text: String) -> void:
	#self.text = text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
