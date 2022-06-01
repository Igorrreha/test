extends CharacterBody3D


const SPEED = 10.0

@export_node_path(Camera3D) var _camera_path
@onready var _camera: Camera3D = get_node(_camera_path)


func _physics_process(delta):
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		var view_rotation = _camera.global_transform.basis.get_euler()
		var move_direction = (Vector3.FORWARD
				.rotated(Vector3.RIGHT, view_rotation.x)
				.rotated(Vector3.UP, view_rotation.y)
				.rotated(Vector3.BACK, view_rotation.z))
		
		velocity = move_direction * SPEED
		move_and_slide()


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.008)
		_camera.rotate_x(-event.relative.y * 0.008)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
