
-- Nodes for generating mana

local max_gen_charge = 1000


-- Standard charge-setting function, which updates infotext too.
local function set_charge(meta, charge)
	meta:set_int("charge", charge)
	meta:set_string("infotext", "Charge: " .. charge .. "/" .. max_gen_charge)
end


-- Standard take_energy, which assumes there is a string field "charge"
local function def_take_energy(throughput)
	return function(pos, amt, requestor)
		local meta = minetest.get_meta(pos)
		local charge = meta:get_int("charge")

		local real_amt = math.floor(amt)

		local taken = math.min(charge, real_amt, throughput)

		set_charge(meta, charge - taken)

		artifice.make_energy_puff(pos, taken, requestor)

		return taken
	end
end


local function def_on_construct(pos)
	local meta = minetest.get_meta(pos)
	set_charge(meta, 0)
end


-- Mana Leech - Takes mana from nearby players. Turns off after a couple minutes.

local mana_leech_base = {-0.5, -0.5, -0.5, 0.5, 0, 0.5}
local mana_leech_pole = {-0.125, 0, -0.125, 0.125, 0.5, 0.125}

local mana_leech_nodebox = { type = "fixed", fixed = {mana_leech_base, mana_leech_pole} }


minetest.register_node("artifice:mana_leech", {
	description = "Mana Leech",
	groups = {choppy=3, oddly_breakable_by_hand=2, energyproducer=1},
	drawtype = "nodebox",
	paramtype = "light",
	tiles = {"artifice_mana_leech_top.png",
		 "default_wood.png",
		 "artifice_mana_leech_side.png",
		 "artifice_mana_leech_side.png",
		 "artifice_mana_leech_side.png",
		 "artifice_mana_leech_side.png",
	},
	node_box = mana_leech_nodebox,

	on_construct = def_on_construct,

	on_rightclick = function(pos)
		local timer = minetest.get_node_timer(pos)
		minetest.swap_node(pos, {name = "artifice:mana_leech_charging"})
		timer:start(120)
	end,

	energyproducer =
		{ take_energy = def_take_energy(100) },

	-- If mesecons is used, don't shut off automatically
	mesecons = {effector = {
		action_on = function(pos, node)
			minetest.swap_node(pos, {name = "artifice:mana_leech_charging"})
		end,
	}},
})


minetest.register_node("artifice:mana_leech_charging", {
	description = "Mana Leech",
	groups = { choppy = 3,
		   oddly_breakable_by_hand = 2,
		   energyproducer = 1,
		   not_in_creative_inventory = 1
	},
	drawtype = "nodebox",
	paramtype = "light",
	tiles = {"artifice_mana_leech_top.png^[colorize:#6600FF:127",
		 "default_wood.png^[colorize:#6600FF:127",
		 "artifice_mana_leech_side.png^[colorize:#6600FF:127",
		 "artifice_mana_leech_side.png^[colorize:#6600FF:127",
		 "artifice_mana_leech_side.png^[colorize:#6600FF:127",
		 "artifice_mana_leech_side.png^[colorize:#6600FF:127",
	},
	node_box = mana_leech_nodebox,
	drop = "artifice:mana_leech",

	on_rightclick = function(pos)
		local timer = minetest.get_node_timer(pos)
		minetest.swap_node(pos, {name = "artifice:mana_leech"})
		timer:stop()
	end,

	on_timer = function(pos)
		minetest.swap_node(pos, {name = "artifice:mana_leech"})
	end,

	energyproducer =
		{ take_energy = def_take_energy(100) },

	mesecons = {effector = {
		action_off = function(pos, node)
			local timer = minetest.get_node_timer(pos)
			minetest.swap_node(pos, {name = "artifice:mana_leech"})
			timer:stop()
		end,
	}},
})


minetest.register_abm({
	nodenames = {"artifice:mana_leech_charging"},
	interval = 5,
	chance = 1,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)

		local charge = meta:get_int("charge")
		local entities = minetest.get_objects_inside_radius(pos, 5)

		local amt = math.min(max_gen_charge - charge, 1000)
		local taken = 0

		local requestor = { type = "node",
				    pos = pos,
		}

		for i, entity in ipairs(entities) do
			if entity:is_player() then
				local to_take = math.min(50, amt - taken)
				
				local suc, missing =
					mana.subtract_up_to(entity:get_player_name(), to_take)
				local taken_once = to_take - missing
				
				if suc then
					taken = taken + taken_once
					local p_pos = vector.add(entity:getpos(), {x=0,y=1,z=0})
					artifice.make_energy_puff(p_pos, taken_once, requestor)
				end
			end
		end

		local new_charge = charge + taken
		set_charge(meta, new_charge)
	end,
})


-- Mana Magnet - Right click to give mana
minetest.register_node("artifice:mana_magnet", {
	description = "Mana Magnet",
	groups = {choppy=3, oddly_breakable_by_hand=2, energyproducer=1},
	drawtype = "nodebox",
	paramtype = "light",
	tiles = {"artifice_mana_magnet_top.png",
		 "default_wood.png",
		 "artifice_mana_magnet_side.png",
		 "artifice_mana_magnet_side.png",
		 "artifice_mana_magnet_side.png",
		 "artifice_mana_magnet_side.png",
	},
	node_box = mana_leech_nodebox,

	on_construct = def_on_construct,

	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		local charge = meta:get_int("charge")
		
		local amt = math.min(max_gen_charge - charge, 50)

		local requestor = { type = "node",
				    pos = pos,
		}

		local suc, missing = mana.subtract_up_to(clicker:get_player_name(), amt)

		if suc then
			local taken = amt - missing
			local p_pos = vector.add(clicker:getpos(), {x=0,y=1,z=0})
			artifice.make_energy_puff(p_pos, taken, requestor)
			set_charge(meta, charge + taken)
		end
	end,

	energyproducer =
		{ take_energy = def_take_energy(10) },
})
