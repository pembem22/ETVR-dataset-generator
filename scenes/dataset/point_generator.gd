extends Node3D

const DISTANCE = 1

@export var h_points = 2
@export var v_points = 2

@export var distance = 0.2

@export var h_fov = 90.0
@export var v_fov = 90.0

@export var h_offset = 0.0
@export var v_offset = 0.0

@export var x_barrel = -1.0
@export var y_barrel = -1.0

@export var samples_per_point = 3

@export var point_prefab: Node3D

@export var audio_player: AudioStreamPlayer
@export var ok_sound: AudioStream
@export var skip_sound: AudioStream
@export var completed_sound: AudioStream

@onready var camera: XRCamera3D = XRHelpers.get_xr_camera(self)
@onready var origin: XROrigin3D = XRHelpers.get_xr_origin(self)
@onready var interface = XRServer.find_interface("OpenXR")

var tcp = StreamPeerTCP.new()

var X = 0
var Y = 0
var I = 0

var tracking_point: Node3D
var preview_points: Array[Node3D]

var is_previewing: bool = true

var rng = RandomNumberGenerator.new()

func safe_divide(a: float, b: float) -> float:
	if abs(b) < 0.0001:
		return 1.0
	else:
		return a / b

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.h_fov_updated.connect(set_h_fov)
	EventBus.v_fov_updated.connect(set_v_fov)
	EventBus.h_off_updated.connect(set_h_off)
	EventBus.v_off_updated.connect(set_v_off)
	EventBus.barrel_x_updated.connect(set_h_bar)
	EventBus.barrel_y_updated.connect(set_v_bar)
	EventBus.collection_state_changed.connect(collection_state_changed)
	
	print("connected ", tcp.connect_to_host("127.0.0.1", 7070) == OK)
	
	tracking_point = point_prefab.duplicate()
	add_child(tracking_point)
	
	update()

func collection_state_changed(value: bool):
	is_previewing = !value
	update()

func set_h_fov(value: float):
	h_fov = value
	update()
func set_v_fov(value: float):
	v_fov = value
	update()
func set_h_off(value: float):
	h_offset = value
	update()
func set_v_off(value: float):
	v_offset = value
	update()
func set_h_bar(value: float):
	x_barrel = value
	update()
func set_v_bar(value: float):
	y_barrel = value
	update()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_previewing:
		tracking_point.look_at(camera.global_position)
	
	tcp.poll()
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		tcp.set_no_delay(true)
		
func update():
	if is_previewing:
		tracking_point.visible = false
		
		var preview_points_cnt = 5 * h_points * v_points
		if preview_points.size() < preview_points_cnt:
			for i in range(preview_points.size(), preview_points_cnt):
				var point = tracking_point.duplicate()
				add_child(point)
				preview_points.append(point)
				
		for j in preview_points.size():
			var point = preview_points[j]
			var i = j / 5 # zone id, 5 points per zone
			var x = i % h_points # zone x
			var y = i / h_points # zone y
			
			#print(j % 5, " ", x, " ", y)
			
			point.visible = y < h_points # hide unused points 
			
			var coords: Vector2
			match j % 5:
				0:
					coords = calc_point_coords_rad(x - 0.5, y + 0.5)
				1:
					coords = calc_point_coords_rad(x + 0.5, y + 0.5)
				2:
					coords = calc_point_coords_rad(x, y)
				3:
					coords = calc_point_coords_rad(x - 0.5, y - 0.5)
				4:
					coords = calc_point_coords_rad(x + 0.5, y - 0.5)
					
			move_point(point, coords, false)
		
	else:
		update_tracking_point(false)
		
		tracking_point.visible = true
		
		for j in preview_points.size():
			var point = preview_points[j]
			point.visible = false # hide unused points 

func calc_point_coords_rad(x_grid: float, y_grid: float, random_offset: bool = false) -> Vector2:
	if random_offset:
		x_grid += rng.randf_range(-0.5, 0.5)
		y_grid += rng.randf_range(-0.5, 0.5)
	
	var x = (x_grid + 0.5) / h_points - 0.5
	var y = (y_grid + 0.5) / v_points - 0.5
	var r = sqrt(x * x + y * y)
	
	var apply_barrel = func(value: float, r: float, barrel: float) -> float:
		if barrel == 0.0:
			return value
		return safe_divide(value, (2 * r * r * barrel)) * (1 - sqrt(1 - 4 * barrel * r * r))
	
	var x_fact = safe_divide(0.5, apply_barrel.call(0.5, 0.5, x_barrel))
	var y_fact = safe_divide(0.5, apply_barrel.call(0.5, 0.5, y_barrel))
	
	x = apply_barrel.call(x, r, x_barrel) * x_fact
	y = apply_barrel.call(y, r, y_barrel) * y_fact
	
	return Vector2(
		deg_to_rad(lerpf(-h_fov, h_fov, x + 0.5) / 2 + h_offset),
		deg_to_rad(lerpf(-v_fov, v_fov, y + 0.5) / 2 + v_offset),
	)
	
func move_point(point: Node3D, coords_rad: Vector2, do_tween: bool = true):
	var pos = Vector3.FORWARD
	pos = pos.rotated(Vector3.UP,    coords_rad[0])
	pos = pos.rotated(Vector3.RIGHT, coords_rad[1])
	pos *= DISTANCE
	
	if do_tween:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CIRC)
		tween.tween_property(point, "position", pos, 0.5)
		
		# happens before the animation finished, do every frame instead
		#point.look_at(camera.global_position)
	else:
		point.position = pos
		point.look_at(camera.global_position)
	
	var fac = distance / DISTANCE
	self.scale = Vector3(fac, fac, fac)


func update_tracking_point(do_tween: bool = true):
	move_point(tracking_point, calc_point_coords_rad(X, Y, true), do_tween)

func next_point(skip: bool = false):
	I += 1
	if I == samples_per_point:
		I = 0
		X += 1
	if X == h_points:
		X = 0
		Y += 1
	if Y == v_points:
		Y = 0
	
		audio_player.stop()
		audio_player.stream = completed_sound
		audio_player.play()

func generate_json(l_pitch: float, l_yaw: float, r_pitch: float, r_yaw: float):
	#var eyelid = 1.00 # wide
	#var eyelid = 0.75 # neutral
	var eyelid = 0.00 # closed
	
	var squint = 0.0 # neutral
	#var squint = 1.0 # e.g. smile
	
	#var eyebrow = -1.0 # frown
	var eyebrow = 0.0 # neutral
	#var eyebrow = 1.0 # up
	
	return JSON.stringify(
		{
			"l": {
				"pitch": l_pitch, 
				"yaw": l_yaw, 
				"eyelid": eyelid,
				"eyebrow": eyebrow,
				"squint": squint,
			}, 
			"r": {
				"pitch": r_pitch, 
				"yaw": r_yaw, 
				"eyelid": eyelid,
				"eyebrow": eyebrow,
				"squint": squint,
			}
		}
	)

func send_direction():
	var l_transform = interface.get_transform_for_view(0, origin.global_transform)
	var r_transform = interface.get_transform_for_view(1, origin.global_transform)
	
	var target_pos = tracking_point.global_position
	
	var l_vector = (target_pos * l_transform).normalized()
	var r_vector = (target_pos * r_transform).normalized()
	
	var l_pitch = rad_to_deg(asin(-l_vector.y))
	var l_yaw = rad_to_deg(atan2(l_vector.x, -l_vector.z))
	
	var r_pitch = rad_to_deg(asin(-r_vector.y))
	var r_yaw = rad_to_deg(atan2(r_vector.x, -r_vector.z))
	
	var json = generate_json(l_pitch, l_yaw, r_pitch, r_yaw)
	EventBus.show_json.emit(json)
	
	tcp.put_data((json + "\n").to_utf8_buffer())
	
	tcp.get_data(2) # b"k\n"
	
	#print(l_pitch, " ", l_yaw)


func _on_right_controller_button_pressed(name):
	if is_previewing:
		return
	
	if name != "trigger_click":
		return
	
	send_direction()
	
	audio_player.stream = ok_sound
	audio_player.play()
	
	next_point()
	update_tracking_point()


func _on_left_controller_button_pressed(name):
	if is_previewing:
		return

	if name != "trigger_click":
		return
	
	audio_player.stream = skip_sound
	audio_player.play()
	
	#send_direction()
	next_point(true)
	update_tracking_point()
