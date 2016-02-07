
-- An entity to represent energy puffness. Size is sqrt(amt) * 0.1, capped at 1.

minetest.register_entity("artifice:energy_puff",
	{ physical = false,
	  visual = "sprite",
	  collisionbox = {0,0,0,0,0,0},
	  textures = {"artifice_energy_puff.png"},

	  target_type = nil,
	  target_pos = nil,
	  target_obj = nil,

	  lifetime = 10,

	  on_step = function(self, dtime)
		  self.lifetime = self.lifetime - dtime
		  
		  if self.target_type == nil then
			  self.object:remove()
			  return
		  end

		  local go_here
		  local threshold

		  if self.target_type == "node" then
			  go_here = self.target_pos
			  threshold = 0.2
		  end

		  if self.target_type == "obj" then
			  go_here = self.target_obj:getpos()
			  threshold = 0.5
		  end

		  if self.lifetime <= 0 then
			  self.object:remove()
			  return
		  end

		  if vector.distance(go_here, self.object:getpos()) < threshold then
			  self.object:remove()
			  return
		  end

		  local self_pos = self.object:getpos()
		  local dir = vector.direction(self_pos, go_here)

		  self.object:setacceleration(vector.multiply(dir, 10))

		  local vel = self.object:getvelocity()

		  if vector.length(vel) > 3 then
			  local new_vel = vector.multiply(vector.normalize(vel), 3)
			  self.object:setvelocity(new_vel)
		  end
	  end,
})


function artifice.make_energy_puff(pos, amt, requestor)
	if amt == 0 then return end
	
	local obj = minetest.add_entity(pos, "artifice:energy_puff")

	local ent = obj:get_luaentity()

	if requestor.type == "entity" then
		ent.target_type = "obj"
		ent.target_obj = requestor.obj
	end

	if requestor.type == "node" then
		ent.target_type = "node"
		ent.target_pos = requestor.pos
	end

	local scale = math.min(math.sqrt(amt) * 0.05, 1)
	
	obj:set_properties({visual_size = {x=scale, y=scale}})
	
	obj:set_armor_groups({immortal = 1})
end
