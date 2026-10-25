extends Node3D

var left: Node3D
var right: Node3D

func _ready():
    left = preload("res://aircraft.gd").new()
    add_child(left)
    right = preload("res://aircraft.gd").new()
    add_child(right)

func follow(leader_position: Vector3, yaw: float, pitch: float):
    left.position = leader_position + Vector3(-38, 6, 22).rotated(Vector3.UP, yaw)
    right.position = leader_position + Vector3(38, 6, 22).rotated(Vector3.UP, yaw)
    left.rotation = Vector3(pitch, yaw, 0)
    right.rotation = Vector3(pitch, yaw, 0)
