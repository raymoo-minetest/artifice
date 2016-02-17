
local run_chain = artifice.exec.run_chain


-- Spell shapes

-- Touch
artifice.register_spell_component("touch",{
	type = "shape",
	disp_name = "Touch",
	description = "Very short range effect application",
	texture = "artifice_shape_back.png^artifice_touch.png",
	affinities = {},
	calc_cost = function() return 1 end,
	material_costs = { "default:clay",
			   "artifice:mana_dust",
	},
	executor = function(env, input, tail, param)
		if input.type == "pointed" then
			local p_pos = source_pos
			local pointed = input.pointed_thing

			if pointed.type == "node" then
				if vector.distance(p_pos, pointed.under) > 3 then
					return
				end
				
				local inout = {
					type == "node",
					source_pos = p_pos,
					above = pointed.above,
					under = pointed.under,
				}

				run_chain(tail, env, inout)
			elseif pointed.type == "object" then
				if vector.distance(p_pos, pointed.ref:getpos()) > 3 then
					return
				end
				
				local inout = {
					type == "entity",
					source_pos = p_pos,
					entity = pointed.ref,
				}

				run_chain(tail, env, inout)
			end
		end
	end,
	priority = "first",
})
