
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
				if vector.distance(p_pos, pointed.under) > 2 then
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
				if vector.distance(p_pos, pointed.ref:getpos()) > 2 then
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


-- Spell Effects

-- Dig
local function dig_xp(mode)
	if mode == 1 then return 5 end
	if mode == 2 then return 20 end
	if mode == 3 then return 50 end

	return 0
end

artifice.register_spell_component("dig", {
	type = "effect",
	disp_name = "Dig",
	description = "Digs a node",
	texture = "artifice_shape_back.png^artifice_dig.png",
	affinities = { earth = 1 },
	calc_cost = function() return 10 end,
	material_costs = { "default:pick_bronze", "default:shovel_bronze" },
	executor = function(env, input, tail, param)
		-- Must target a node
		if input.type ~= "node" then return end
		
		-- Only dig if the player is present
		local player = minetest.get_player_by_name(env.player)
		if not player then return end

		local node = minetest.get_node(input.under)
		local node_level = minetest.get_item_group(node.name, "level")

		-- Casting mode is the "tool level" for the spell.
		if node_level <= env.cast_mode then
			minetest.node_dig(input.under, node, player)
			run_chain(tail, env, dig_xp(cast_mode))
		end
	end,
})

		
