extends OSCReceiver

@export var target: Node3D
@export var index: int = 0

var last_message = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target_server.incoming_messages.has(osc_address):
		target.visible = true
		target.rotation_degrees.x = 90 - target_server.incoming_messages[osc_address][2 * index + 0]
		target.rotation_degrees.y = -target_server.incoming_messages[osc_address][2 * index + 1]
		last_message = Time.get_ticks_msec()
	elif Time.get_ticks_msec() - last_message > 100:
		target.visible = false
