extends Node3D

const TuningScript = preload("res://scripts/Tuning.gd")
const GameStateScript = preload("res://scripts/GameState.gd")
const DebugForceOverlayScript = preload("res://scripts/DebugForceOverlay.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")

var tuning = TuningScript.new()
var game_state = GameStateScript.new()

@onready var mountain = $Mountain
@onready var player = $Player
@onready var stone: RigidBody3D = $Stone
@onready var camera: Camera3D = $Camera3D
@onready var status_label: Label = $HUD/Status
@onready var prompt_label: Label = $HUD/Prompt
@onready var trail_root: Node3D = $TrailGrowth

var _last_phase = -1
var _trail_visual_count: int = 0
var _debug_overlay: Node3D
var _debug_visible: bool = false
var _auto_push_verify: bool = false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	game_state.tuning = tuning
	mountain.tuning = tuning
	mountain.build()
	_debug_overlay = DebugForceOverlayScript.new()
	_debug_overlay.visible = _debug_visible
	add_child(_debug_overlay)
	_place_starting_actors()
	player.setup(tuning, mountain, game_state, stone, camera)
	_apply_stone_physics()
	_auto_push_verify = OS.get_cmdline_user_args().has("--auto-push")
	if _auto_push_verify:
		_enable_auto_push_verification()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_debug_visible = not _debug_visible
		_debug_overlay.visible = _debug_visible


func _physics_process(delta: float) -> void:
	if _auto_push_verify:
		_apply_auto_push_verification()
	var before_phase: int = game_state.phase
	game_state.advance(delta, player.global_position, stone.global_position, stone.linear_velocity)
	if before_phase != game_state.phase:
		_on_phase_changed(before_phase, game_state.phase)
	_update_trail_growth()
	_update_debug_overlay()
	_update_hud()


func _place_starting_actors() -> void:
	var player_z: float = tuning.front_base_z + 4.8
	player.global_position = Vector3(0.0, mountain.height_at(player_z) + 0.05, player_z)
	player.camera_yaw = 0.0
	player.camera_pitch = -0.08

	var stone_z: float = tuning.front_base_z + 1.1
	stone.global_position = Vector3(0.0, mountain.height_at(stone_z) + tuning.stone_radius + 0.12, stone_z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	stone.freeze = true

	camera.global_position = player.global_position + Vector3(0.8, 1.6, tuning.shoulder_distance)
	camera.look_at(stone.global_position + Vector3(0, 0.5, 0), Vector3.UP)


func _apply_stone_physics() -> void:
	stone.mass = tuning.stone_mass
	stone.gravity_scale = tuning.stone_gravity_scale
	stone.linear_damp = tuning.stone_linear_damp
	stone.angular_damp = tuning.stone_angular_damp
	stone.continuous_cd = true
	stone.contact_monitor = true
	stone.max_contacts_reported = 8
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.friction = tuning.stone_friction
	material.bounce = 0.01
	stone.physics_material_override = material


func _on_phase_changed(_previous, next) -> void:
	if next == GameStateScript.Phase.ASCENT:
		stone.freeze = false
	elif next == GameStateScript.Phase.RELEASE:
		prompt_label.text = "Stone crossed the ridge. Do not push it now; follow it down the far side."
	elif next == GameStateScript.Phase.DESCENT:
		prompt_label.text = "Walk down the back slope. The stone is waiting below."
	elif next == GameStateScript.Phase.COMPLETE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _update_trail_growth() -> void:
	if game_state.phase != GameStateScript.Phase.DESCENT and game_state.phase != GameStateScript.Phase.COMPLETE:
		return

	while _trail_visual_count < game_state.trail_points.size():
		var point: Vector3 = game_state.trail_points[_trail_visual_count]
		var patch: MeshInstance3D = MeshInstance3D.new()
		var mesh: CylinderMesh = CylinderMesh.new()
		mesh.top_radius = 0.32
		mesh.bottom_radius = 0.32
		mesh.height = 0.015
		mesh.radial_segments = 7
		patch.mesh = mesh
		patch.position = Vector3(point.x, mountain.height_at(point.z) + 0.035, point.z)
		patch.rotation.x = PI * 0.5
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.64, 0.59, 0.39, 0.72)
		material.roughness = 0.9
		patch.material_override = material
		trail_root.add_child(patch)
		_trail_visual_count += 1


func _update_hud() -> void:
	var force_uphill := 0.0
	var gravity_downhill := 0.0
	var contact_quality := 0.0
	if player.push_frame != null:
		force_uphill = player.push_frame.force_uphill_component
		gravity_downhill = player.push_frame.gravity_downhill_component
		contact_quality = player.push_frame.contact_quality
	status_label.text = "Phase: %s | Rollbacks: %d | Stability: %.2f" % [
		game_state.label(),
		game_state.rollback_count,
		game_state.stability_score,
	]
	status_label.text += " | Angle %.0f%% | Push %.0f / Gravity %.0f | Speed %.2f" % [
		contact_quality * 100.0,
		force_uphill,
		gravity_downhill,
		stone.linear_velocity.length(),
	]
	if _debug_visible:
		status_label.text += " | DEBUG VECTORS"

	match game_state.phase:
		GameStateScript.Phase.APPROACH:
			prompt_label.text = "WASD move. Mouse/trackpad drag or Q/E turns. Walk to the stone. F3 shows debug-only force vectors."
		GameStateScript.Phase.ASCENT:
			prompt_label.text = "Hold W to keep pushing. Your camera center is where both hands press."
		GameStateScript.Phase.RELEASE:
			prompt_label.text = "The stone is crossing the ridge. Let gravity take it."
		GameStateScript.Phase.DESCENT:
			prompt_label.text = "Descend the back side. No teleport: walk down from the ridge."
		GameStateScript.Phase.COMPLETE:
			prompt_label.text = "Loop complete. The first Godot slice is playable."


func _update_debug_overlay() -> void:
	if _debug_overlay == null or player.push_frame == null:
		return
	_debug_overlay.update_debug(stone.global_position, player.push_frame, mountain.uphill_tangent_at(stone.global_position.z))


func _enable_auto_push_verification() -> void:
	_debug_visible = true
	_debug_overlay.visible = true
	game_state.phase = GameStateScript.Phase.ASCENT
	stone.freeze = false
	player.set_physics_process(false)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.55
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	player.camera_yaw = atan2(-downhill.x, downhill.z)
	player.camera_pitch = -0.06
	player.push_engaged = true
	player.camera_push_blend = 1.0
	_position_push_verification_camera(mountain.uphill_tangent_at(stone.global_position.z), stone.global_position + Vector3.UP * 0.45)


func _apply_auto_push_verification() -> void:
	if game_state.phase != GameStateScript.Phase.ASCENT:
		return
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	var target: Vector3 = stone.global_position + downhill * tuning.stone_radius * 1.55
	target.y = mountain.height_at(target.z) + 0.05
	player.global_position = player.global_position.lerp(target, 0.25)
	var camera_direction: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
	var frame = player.apply_reticle_aligned_push(camera_direction, true, 0.0, 999.0)
	player.push_frame = frame
	player.push_engaged = true
	player._near_stone = true
	player._is_walking = true
	player._update_arm_visual(1.0 / 60.0, frame.aim_direction)
	_position_push_verification_camera(frame.aim_direction, frame.contact_point)
	player._update_first_person_hands(frame.aim_direction)


func _position_push_verification_camera(camera_direction: Vector3, target: Vector3) -> void:
	var forward: Vector3 = Vector3(camera_direction.x, 0.0, camera_direction.z).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized()
	camera.global_position = player.global_position + forward * tuning.push_camera_distance + right * tuning.push_camera_side_offset + Vector3.UP * tuning.push_camera_height
	camera.look_at(target, Vector3.UP)
