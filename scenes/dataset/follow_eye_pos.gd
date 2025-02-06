extends Node3D

@onready var origin: XROrigin3D = XRHelpers.get_xr_origin(self)
@onready var interface = XRServer.find_interface("OpenXR")

@export var index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var transform = interface.get_transform_for_view(index, origin.global_transform)
	self.transform = transform
