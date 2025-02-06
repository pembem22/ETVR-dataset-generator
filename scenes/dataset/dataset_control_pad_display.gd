extends Control

@onready var start_button = $"TabContainer/Dataset Collection/VBoxContainer/HBoxContainer/StartButton"
@onready var end_button = $"TabContainer/Dataset Collection/VBoxContainer/HBoxContainer/EndButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_fov_h_slider_value_changed(value: float) -> void:
	EventBus.h_fov_updated.emit(value)


func _on_fov_v_slider_value_changed(value: float) -> void:
	EventBus.v_fov_updated.emit(value)


func _on_offset_h_slider_value_changed(value: float) -> void:
	EventBus.h_off_updated.emit(value)


func _on_offest_v_slider_value_changed(value: float) -> void:
	EventBus.v_off_updated.emit(value)


func _on_barrel_x_slider_value_changed(value: float) -> void:
	EventBus.barrel_x_updated.emit(value)


func _on_barrel_y_slider_value_changed(value: float) -> void:
	EventBus.barrel_y_updated.emit(value)


func _on_collection_start_pressed() -> void:
	start_button.disabled = true
	end_button.disabled = false
	EventBus.collection_state_changed.emit(true)


func _on_collection_end_pressed() -> void:
	end_button.disabled = true
	start_button.disabled = false
	EventBus.collection_state_changed.emit(true)
