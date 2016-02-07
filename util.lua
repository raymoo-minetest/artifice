
function artifice.node_field(name, field)
	local node_def = minetest.registered_nodes[name]
	
	if not node_def then return end

	return node_def[field]
end
