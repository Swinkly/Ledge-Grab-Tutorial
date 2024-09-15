extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var debug: Label = $Debug

@export var movement_speed: float = 260.0
@export var acceleration: float = 400.0
@export var friction: float = 2000.0
@export var jump_velocity: float = -350.0
@export var air_resistance: float = 150.0
@export var air_acceleration: float = 275.0

enum states {
	IDLE,
	RUN,
	JUMP,
	FALL,
	LEDGE_GRAB,
}

const state_names := [
	"IDLE",
	"RUN",
	"JUMP",
	"FALL",
	"LEDGE_GRAB"
]

var state = states.IDLE

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		$JumpBuffer.start()

func _physics_process(delta: float) -> void:
	
	# Directional input
	var input_axis = Input.get_axis("move_left", "move_right")

	# Check if on floor before move_and_slide
	var was_on_floor = is_on_floor()

	# Flip sprite if we need to
	if input_axis != 0 and state != states.LEDGE_GRAB:
		anim.flip_h = (input_axis < 0)

	# Disable ledgegrab collider unless it's needed
	$LedgeGrab.disabled = state in [states.RUN, states.IDLE] or velocity.y < 0 or (state != states.LEDGE_GRAB and $TopCheck.is_colliding())

	# Check for ledge grab in airborne states
	if state in [states.JUMP, states.FALL]:
		check_ledge_grab()

	# Check if landing, switch state as necessary
	if is_on_floor() and state != states.LEDGE_GRAB:
		if velocity.x != 0:
			state = states.RUN
		if velocity.x == 0:
			state = states.IDLE

	# Check if falling
	if !is_on_floor() and state in [states.IDLE, states.RUN]:
		state = states.FALL

	# In-air states movement
	if state in [states.JUMP, states.FALL]:
		handle_jump_input()
		apply_gravity(delta)
		handle_air_acceleration(input_axis, delta)
		apply_air_resistance(input_axis, delta)

	# Grounded state movement
	if state in [states.IDLE, states.RUN]:
		handle_jump_input()
		handle_acceleration(input_axis, delta)
		apply_friction(input_axis, delta)

	# State-specific behavior
	match state:
		states.IDLE:
			anim.play("idle")
		states.RUN:
			anim.play("run")
		states.JUMP:
			pass
		states.FALL:
			anim.play("fall")
		states.LEDGE_GRAB:
			if $FloorCheck.is_colliding():
				state = states.IDLE
			velocity.x = 0
			var collider = $WallCheck.get_collision_normal(0)
			if collider.x == -1:
				anim.flip_h = false
				if not is_on_wall():
					velocity.x = 25
			else:
				anim.flip_h = true
				if not is_on_wall():
					velocity.x = -25
			anim.play("ledge_grab")
			if $TopCheck.is_colliding():
				velocity.y = 80
			handle_jump_input()

	# Apply movement
	move_and_slide()

	# Start coyote timer if just left ledge
	if !is_on_floor() and was_on_floor:
		$CoyoteTimer.start()

	# Debug label
	debug.text = str(state_names[state])

func apply_gravity(delta: float) -> void:
	if not is_on_floor() and velocity.y < 700:
		velocity.y += gravity * delta

func handle_acceleration(input_axis, delta) -> void:
	# Acceleration is multiplied when changing direction to avoid a slippery feeling. Else, default acceleration is used
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, acceleration * delta)

func apply_friction(input_axis, delta) -> void:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_air_acceleration(input_axis, delta) -> void:
	# Same case as floor acceleration: acceleration is much quicker when turning around
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis,air_acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, air_acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, air_acceleration * delta)

func apply_air_resistance(input_axis, delta) -> void:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, air_resistance * delta)

func handle_jump_input() -> void:
	if is_on_floor() or $CoyoteTimer.time_left > 0:
		if $JumpBuffer.time_left > 0:
			velocity.y = jump_velocity
			anim.play("jump")
			state = states.JUMP
			$JumpBuffer.stop()

func check_ledge_grab() -> void:
	if $WallCheck.is_colliding() and not $FloorCheck.is_colliding() and velocity.y == 0:
		state = states.LEDGE_GRAB
