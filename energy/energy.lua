
artifice.energy_path = artifice.modpath .. "energy/"

-- Energy in Artifice is a pull-based system.
--
-- A requestor is a table with fields:
--   type: Either "entity" or "node"
--   pos: A location, if type == "node"
--   obj: An ObjectRef, if type == "entity"
-- It can also be nil.
--
-- A node that can provide energy should be in the group "energyproducer", and
-- should have a field "energyproducer" that is a table with the following
-- fields:
--   take_energy(pos, amount, requestor): Handles the request of amount units
--     of energy. Should return the amount successfully obtained. The requestor
--     argument is to facilitate visual effect (e.g. energy orb entity)


-- Requests energy from a node
function artifice.request_energy(pos, amount, requestor)
	local node = minetest.get_node(pos)
	local energy_def = artifice.node_field(node.name, "energyproducer")

	if energy_def == nil then return end
	
	return energy_def.take_energy(pos, amount, requestor)
end


-- A node linkable as an output to energy sources should be in the group
-- "linkoutput" and have a table "linkoutput" with the fields:
--   - on_link(pos, input_pos): Performs the link.
--   - remove_links(pos): Removes links.


-- Links two nodes (no-op if one is not linkable), returning a boolean success
-- value.
function artifice.link_nodes(src, dst)
	local src_node = minetest.get_node(src)
	local dst_node = minetest.get_node(dst)

	local src_gp = minetest.get_item_group(src_node.name, "energyproducer")
	local dst_gp = minetest.get_item_group(dst_node.name, "linkoutput")

	if src_gp == 0 or dst_gp == 0 then return false end

	local dst_out = artifice.node_field(dst_node.name, "linkoutput")

	dst_out.on_link(dst, src)

	return true
end


-- Unlinks a node from its inputs
function artifice.unlink_node(pos)
	local node = minetest.get_node(pos)
	local unlinker = artifice.node_field(node.name, "linkoutput")

	if unlinker then
		unlinker.remove_links(pos)
		return true
	else
		return false
	end
end

dofile(artifice.energy_path .. "linker.lua")
dofile(artifice.energy_path .. "puff.lua")
dofile(artifice.energy_path .. "creative.lua")
