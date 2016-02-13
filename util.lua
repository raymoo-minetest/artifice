
function artifice.node_field(name, field)
	local node_def = minetest.registered_nodes[name]
	
	if not node_def then return end

	return node_def[field]
end


function artifice.obj_center(obj)
	if obj:is_player() then
		return vector.add(obj:getpos(), {x=0,y=1,z=0})
	else
		return obj:getpos()
	end
end


function artifice.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end


-- Reference
-- 1: -x
-- 2: -y
-- 3: -z
-- 4: +x
-- 5: +y
-- 6: +z
function artifice.colliding(obj1, obj2, fudge)
	fudge = fudge or 0.1
	local p1 = artifice.obj_center(obj1)
	local p2 = artifice.obj_center(obj2)

	local box1 = obj1:get_properties().collisionbox
	local box2 = obj2:get_properties().collisionbox

	local x_inter = (p1.x + box1[1]) - (p2.x + box2[4]) <= fudge
		and(p2.x + box2[1]) - (p1.x + box1[4]) <= fudge
	
	local y_inter = (p1.y + box1[2]) - (p2.y + box2[5]) <= fudge
		and (p2.y + box2[2]) - (p1.y + box1[5]) <= fudge
	
	local z_inter = (p1.z + box1[3]) - (p2.z + box2[6]) <= fudge
		and (p2.z + box2[3]) - (p1.z + box1[6]) <= fudge

	return x_inter and y_inter and z_inter
end


-- Distance between two object centers
function artifice.center_distance(obj1, obj2)
	return vector.distance(artifice.obj_center(obj1), artifice.obj_center(obj2))
end
