# This script is based on the default CharacterBody2D template. Not much interesting happening here.
extends CharacterBody2D

@onready var grapple: Grapple = $Grapple
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var mist_particles_2d: GPUParticles2D = $MistParticles2D
@onready var ice_clone_scene: PackedScene = preload("res://root/Objects/IceClone.tscn")

const JUMP_FORCE = 500			# Force applied on jumping
const MOVE_SPEED = 500			# Speed to walk with
const MAX_SPEED = 1000			# Maximum speed the player is allowed to move
const FRICTION_AIR = 0.95		# The friction while airborne
const FRICTION_GROUND = 0.85	# The friction while on the ground
const CHAIN_PULL = 0            # The force applied to pull the player towards the grapple point
const MIST_SLOW = Vector2(0.1, 0.9)
const MIST_LIFT = 150

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var animation: String

var reset_position: Vector2
# Indicates that the player has an event happening and can't be controlled.
var event: bool
var is_mist: bool = false
var is_in_mist: bool = false

var abilities: Array[StringName]
var double_jump: bool
var prev_on_floor: bool
var grapple_velocity: Vector2 = Vector2(0, 0)


func _ready() -> void:
	on_enter()


func _physics_process(delta: float) -> void:
	if event:
		return

	if Input.is_action_just_pressed("power_2"):
		is_mist = !is_mist
		
	if is_mist:
		mist_particles_2d.visible = true
		sprite.visible = false
		grapple.can_hook = false
	else:
		mist_particles_2d.visible = false
		sprite.visible = true

	if grapple.is_hooked and CHAIN_PULL == 0:
		# Grapple is like a rope swing
		# TODO: Fix collision issues with floor
		global_position = grapple.rigid_body_2d.global_position
		velocity = grapple.rigid_body_2d.linear_velocity

	if Input.is_action_just_pressed("power_3") and !is_mist:
		# Bump the player forward a bit
		# velocity.x = 500 * (1 if sprite.flip_h else -1)
		var clone = ice_clone_scene.instantiate()
		clone.global_position = global_position
		var clone_sprite: Sprite2D = sprite.duplicate()
		clone_sprite.modulate = Color(0, 0.5, 1)
		clone.add_child(clone_sprite)
		var clone_animation_player: AnimationPlayer = animation_player.duplicate()
		clone_animation_player.speed_scale = 0
		clone.add_child(animation_player.duplicate())
		get_parent().add_child(clone)

	if Input.is_action_pressed("power_1") and grapple.can_hook:
		grapple.set_hook()
	elif Input.is_action_just_released("power_1") and grapple.is_hooked:
		grapple.unhook()
	
	if not is_on_floor() and not grapple.is_hooked and not (is_mist and is_in_mist):
		velocity.y += gravity * delta
	elif not prev_on_floor and &"double_jump" in abilities:
		# Some simple double jump implementation.
		double_jump = true
	
	if Input.is_action_just_pressed("ui_accept") and !is_mist and (is_on_floor() or double_jump):
		if not is_on_floor():
			double_jump = false
		
		if Input.is_action_pressed("ui_down"):
			position.y += 8
		else:
			velocity.y = -JUMP_FORCE
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)

	if grapple.is_hooked:
		# Apply pendulum physics to swing while grapple is hooked
		var grapple_position = to_local(grapple.rigid_body_2d.global_position)
		var angle = atan2(grapple_position.y, grapple_position.x)
		var distance = grapple_position.length()
		var max_distance = grapple.chain_length
		var pull = distance - max_distance
		var pull_force = pull * 0.1
		var pull_vector = Vector2(cos(angle), sin(angle)) * pull_force
		# TODO: Get swinging right
		grapple.rigid_body_2d.linear_velocity += pull_vector * -direction
		grapple.rigid_body_2d.linear_velocity.x = clamp(grapple.rigid_body_2d.linear_velocity.x, -MAX_SPEED, MAX_SPEED)

		# Grapple is like a spring
		var grapple_direction = to_local(grapple.hook_point).normalized()
		grapple_velocity = grapple_direction * CHAIN_PULL
		
		if grapple_velocity.y > 0:
			# Pulling down isn't as strong
			grapple_velocity.y *= 0.55
		else:
			# Pulling up is stronger
			grapple_velocity.y *= 1.65
		if sign(grapple_velocity.x) != sign(velocity.x):
			# if we are trying to walk in a different
			# direction than the chain is pulling
			# reduce its pull
			grapple_velocity.x *= 0.7
	else:
		# Not hooked -> no chain velocity
		grapple_velocity = Vector2(0,0)

	velocity += grapple_velocity * delta

	if is_mist:
		velocity.x *= MIST_SLOW.x
		if is_in_mist:
			# Apply upwards force to float upwards slowly
			velocity.y -= MIST_LIFT * delta
		elif velocity.y > 0:
			velocity.y -= gravity * MIST_SLOW.y * delta

	velocity.y = clamp(velocity.y, -MAX_SPEED, MAX_SPEED)	# Make sure we are in our limits
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)

	prev_on_floor = is_on_floor()
	move_and_slide()
	
	var new_animation = &"Idle"
	if velocity.y < 0:
		new_animation = &"Jump"
	elif velocity.y >= 0 and not is_on_floor():
		new_animation = &"Fall"
	elif absf(velocity.x) > 1:
		new_animation = &"Run"
	
	if new_animation != animation:
		animation = new_animation
		animation_player.play(new_animation)
	
	if velocity.x > 1:
		sprite.flip_h = false
	elif velocity.x < -1:
		sprite.flip_h = true


func kill():
	# Player dies, reset the position to the entrance.
	position = reset_position
	Game.get_singleton().load_room(MetSys.get_current_room_name())


func on_enter():
	# Position for kill system. Assigned when entering new room (see Game.gd).
	reset_position = position

func set_is_in_mist(value: bool):
	is_in_mist = value


func _on_despawn_timer_timeout():
	print("Shadow despawned!")
	queue_free()
