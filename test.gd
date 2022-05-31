@tool
extends EditorScript

var _root_node: Node
var _dots_container: Node3D
var _block_tscn: PackedScene

var _layers := []
var _meshes := []

enum AxisBit {
	X = 1 << 0,
	X_NEGATIVE = 1 << 1,
	Y = 1 << 2,
	Y_NEGATIVE = 1 << 3,
	Z = 1 << 4,
	Z_NEGATIVE = 1 << 5,
}


func _run():
	var memory_start = _get_memory()
	
	_root_node = get_scene()
	_dots_container = _root_node.get_node("Node3D")
	_block_tscn = preload("res://block.tscn")
	var noise3d = preload("res://noise.tres")
	
	for node in _dots_container.get_children():
		node.queue_free()
	
	_fill_layers_array()
	_generate_meshes(_layers)
	
	var memory_end = _get_memory()
	print((memory_end - memory_start) / 8)


func _fill_layers_array():
	_layers.clear()
	
	var radius := 8
	var radius_range := range(-radius + 1, radius)
	for x in radius_range:
		var current_layer := []
		_layers.append(current_layer)
		
		for y in radius_range:
			var current_line: Array[bool] = []
			current_layer.append(current_line)
			
			for z in radius_range:
				var position = Vector3i(x, y, z)
				current_line.append(position.length() <= radius)


func _generate_meshes(layers: Array):
	var vertices := []
	for layer_idx in layers.size():
		var layer = layers[layer_idx]
		for line_idx in layer.size():
			var line = layer[line_idx]
			for block_idx in line.size():
				if line[block_idx]:
					continue
				
				var neighbors_bitmask: int
				if block_idx > 0 and line[block_idx - 1]:
					neighbors_bitmask |= AxisBit.X_NEGATIVE
				if block_idx < line.size() - 1 and line[block_idx + 1]:
					neighbors_bitmask |= AxisBit.X
				
				if layer_idx > 0 and layers[layer_idx - 1]:
					neighbors_bitmask |= AxisBit.Y_NEGATIVE
				if layer_idx < layers.size() - 1 and layers[layer_idx + 1]:
					neighbors_bitmask |= AxisBit.Y
				
				if line_idx > 0 and layer[line_idx - 1]:
					neighbors_bitmask |= AxisBit.Z_NEGATIVE
				if line_idx < layer.size() - 1 and layer[line_idx + 1]:
					neighbors_bitmask |= AxisBit.Z
				
				if neighbors_bitmask:
					_create_block(Vector3i(block_idx, layer_idx, line_idx))
#				if neighbors_bitmask & AxisBit.X:
#					vertices.append(Vector3(0, 0, 0))


func _create_block(position: Vector3i) -> void:
	var node = _block_tscn.instantiate()
	node.position = position
	_dots_container.add_child(node)
	node.set_owner(_root_node)


func _get_memory():
	return Performance.get_monitor(Performance.MEMORY_STATIC)
