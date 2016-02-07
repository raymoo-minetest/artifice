
-- A tool for linking energy nodes

local texture = "artifice_linking_wand.png"
local name = "artifice:linking_wand"
local description = "Linking Wand"


local function source_sparkles(pos, player)
	minetest.add_particlespawner({
		amount = 20,
		time = 0.1,
		minpos = pos,
		maxpos = pos,
		minvel = {x=-2, y=-2, z=-2},
		maxvel = {x=2, y=2, z=2},
		texture = "artifice_source_sparkle.png",
		playername = player:get_player_name(),
	})
end


local function sink_sparkles(pos, player)
	minetest.add_particlespawner({
		amount = 20,
		time = 0.1,
		minpos = pos,
		maxpos = pos,
		minvel = {x=-2, y=-2, z=-2},
		maxvel = {x=2, y=2, z=2},
		texture = "artifice_sink_sparkle.png",
		playername = player:get_player_name(),
	})
end
		


minetest.register_craftitem(name,
	{ description = description,
	  inventory_image = texture,
	  wield_image = texture,
	  stack_max = 1,
	  on_use = function(stack, user, pointed_thing)
		  if pointed_thing.type ~= "node" then return end

		  local pos = pointed_thing.under
		  local node = minetest.get_node(pos)
		  
		  local old_meta = stack:get_metadata()

		  local keys = user:get_player_control()

		  if keys.aux1 then
			  local suc = artifice.unlink_node(pos)
			  if suc then
				  minetest.chat_send_player(user:get_player_name(), "Links removed.")
			  end
		  elseif old_meta == "" then
			  local gp = minetest.get_item_group(node.name, "energyproducer")
			  if gp == 0 then return end

			  source_sparkles(pos, user)
			  
			  stack:set_metadata(minetest.pos_to_string(pos))
			  return stack
		  else
			  local src_pos = minetest.string_to_pos(old_meta)

			  local gp = minetest.get_item_group(node.name, "linkoutput")
			  if gp == 0 then
				  stack:set_metadata("")
				  minetest.chat_send_player(user:get_player_name(), "Linking Aborted.")
				  return stack
			  end

			  local suc = artifice.link_nodes(src_pos, pos)

			  if not suc then
				  minetest.chat_send_player(user:get_player_name(), "Linking Failed.")
			  end

			  stack:set_metadata("")

			  sink_sparkles(pos, user)

			  return stack
		  end
	  end,
})
