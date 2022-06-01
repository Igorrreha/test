@tool
extends EditorScript


enum AxisBit {
	X = 1 << 0,
	X_NEGATIVE = 1 << 1,
	Y = 1 << 2,
	Y_NEGATIVE = 1 << 3,
	Z = 1 << 4,
	Z_NEGATIVE = 1 << 5,
}

var _root_node: Node
var _block_tscn: PackedScene

var _meshes := []

var _mesh_parts := {
	AxisBit.X: [
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(1, 1, 0),
		Vector3(1, 0, 1),
		Vector3(1, 1, 1),
		Vector3(1, 1, 0),
	],
	AxisBit.X_NEGATIVE: [
		Vector3(0, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(0, 1, 1),
	],
	AxisBit.Y: [
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(0, 1, 1),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1),
	],
	AxisBit.Y_NEGATIVE: [
		Vector3(0, 0, 0),
		Vector3(0, 0, 1),
		Vector3(1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(1, 0, 1),
	],
	AxisBit.Z: [
		Vector3(0, 0, 1),
		Vector3(0, 1, 1),
		Vector3(1, 0, 1),
		Vector3(1, 0, 1),
		Vector3(0, 1, 1),
		Vector3(1, 1, 1),
	],
	AxisBit.Z_NEGATIVE: [
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(1, 0, 0),
		Vector3(1, 1, 0),
		Vector3(0, 1, 0),
	],
}

var _axis_normals := {
	AxisBit.X: Vector3(1, 0, 0),
	AxisBit.X_NEGATIVE: Vector3(-1, 0, 0),
	AxisBit.Y: Vector3(0, 1, 0),
	AxisBit.Y_NEGATIVE: Vector3(0, -1, 0),
	AxisBit.Z: Vector3(0, 0, 1),
	AxisBit.Z_NEGATIVE: Vector3(0, 0, -1),
}


func _run():
	var memory_start = _get_memory()
	
	_root_node = get_scene()
	_block_tscn = preload("res://block.tscn")
	
	var _chunks_container = _root_node.get_node("Node3D")
	var chunk_size = 32
	
	for node in _chunks_container.get_children():
		node.queue_free()
	
	for x in range(2):
		for y in range(2):
			for z in range(2):
				var chunk_position := Vector3i(x, y, z)
				var chunk_node := MeshInstance3D.new()
				chunk_node.mesh = _generate_chunk(chunk_position, chunk_size)
				
				chunk_node.position = chunk_position * chunk_size
				_chunks_container.add_child(chunk_node)
				chunk_node.owner = _root_node
	
	var memory_end = _get_memory()
	print((memory_end - memory_start) / 8)


func _generate_chunk(chunk_position: Vector3i, chunk_size: int) -> ArrayMesh:
	var layers = _fill_layers_array(chunk_size, Vector3i(chunk_position.y, chunk_position.z, chunk_position.x) * chunk_size)
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	
	for layer_idx in layers.size():
		var layer = layers[layer_idx]
		for line_idx in layer.size():
			var line = layer[line_idx]
			for cell_idx in line.size():
				
				# current cell is empty
				if not line[cell_idx]:
					continue
				
				# create neighbours bitmask
				var neighbors_bitmask: int
				
				if cell_idx > 0 and line[cell_idx - 1]:
					neighbors_bitmask |= AxisBit.X_NEGATIVE
				if cell_idx < line.size() - 1 and line[cell_idx + 1]:
					neighbors_bitmask |= AxisBit.X
				
				if layer_idx > 0 and layers[layer_idx - 1][line_idx][cell_idx]:
					neighbors_bitmask |= AxisBit.Y_NEGATIVE
				if layer_idx < layers.size() - 1 and layers[layer_idx + 1][line_idx][cell_idx]:
					neighbors_bitmask |= AxisBit.Y
				
				if line_idx > 0 and layer[line_idx - 1][cell_idx]:
					neighbors_bitmask |= AxisBit.Z_NEGATIVE
				if line_idx < layer.size() - 1 and layer[line_idx + 1][cell_idx]:
					neighbors_bitmask |= AxisBit.Z
				
				var block_position = Vector3(cell_idx, layer_idx, line_idx)
				
				# generate mesh
				for axis_bit in AxisBit.values():
					if not neighbors_bitmask & axis_bit:
						vertices.append_array(_mesh_parts[axis_bit].map(func(vector: Vector3):
								return vector + block_position))
						
						var normal = _axis_normals[axis_bit]
						normals.append(normal)
						normals.append(normal)
						normals.append(normal)
						normals.append(normal)
						normals.append(normal)
						normals.append(normal)
	
	return _create_mesh(vertices, normals)


func _fill_layers_array(chunk_size: int, offset: Vector3i) -> Array:
	var layers := []
	var noise3d = preload("res://noise.tres")
	
	var position_range := range(-chunk_size / 2, chunk_size / 2)
	for x in position_range:
		var current_layer := []
		layers.append(current_layer)
		
		for y in position_range:
			var current_line: Array[bool] = []
			current_layer.append(current_line)
			
			for z in position_range:
				var position = Vector3i(x, y, z)
				var noise_value = noise3d.get_noise_3dv(position + offset)
				
#				current_line.append(position.length() <= radius)
				current_line.append(abs(noise_value) < 0.2)
	
	return layers


func _create_mesh(vertices: PackedVector3Array, normals: PackedVector3Array) -> Mesh:
	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals

	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return arr_mesh


func _get_memory():
	return Performance.get_monitor(Performance.MEMORY_STATIC)
