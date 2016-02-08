
-- A mana battery
--
-- The node in the world has a "charge" metadata int field, as well as a
-- "sources" string, that is really a serialized table of source positions.

local max_charge = 500000
local packet_size = 1000

local function set_charge(meta, charge)
	meta:set_int("charge", charge)

	meta:set_string("infotext", "Charge: " .. charge .. "/" .. max_charge)
end


local function take_battery_energy(pos, amt, requestor)
	local meta = minetest.get_meta(pos)
	local charge = meta:get_int("charge")

	local real_amt = math.floor(amt)

	local taken = math.min(charge, real_amt)

	set_charge(meta, charge - taken)

	artifice.make_energy_puff(pos, taken, requestor)

	return taken
end


local function link(pos, in_pos)
	local meta = minetest.get_meta(pos)
	local sources = meta:get_string("sources")

	local src_tab = minetest.deserialize(sources)

	src_tab = src_tab or {}

	src_tab[minetest.hash_node_position(in_pos)] = in_pos

	meta:set_string("sources", minetest.serialize(src_tab))
end


local function remove_battery_links(pos)
	local meta = minetest.get_meta(pos)

	meta:set_string("sources", "")
end


minetest.register_node("artifice:battery",
	{ description = "Mana Battery",
	  groups = {cracky=3, oddly_breakable_by_hand=2, energyproducer=1, linkoutput=1},
	  tiles = {"artifice_battery.png"},

	  on_construct = function(pos)
		  local meta = minetest.get_meta(pos)

		  set_charge(meta, 0)
	  end,
	  
	  on_rightclick = function(pos)
		  minetest.swap_node(pos, {name = "artifice:battery_charging"})
	  end,

	  energyproducer =
		  { take_energy = take_battery_energy },

	  linkoutput = { on_link = link,
			 remove_links = remove_battery_links,
	  },
})


minetest.register_node("artifice:battery_charging",
	{ description = "Mana Battery (Charging)",
	  groups = { cracky = 3,
		     oddly_breakable_by_hand = 2,
		     energyproducer = 1,
		     linkoutput = 1,
		     not_in_creative_inventory = 1,
	  },
	  tiles = {"artifice_battery_charging.png"},
	  drop = "artifice:battery",

	  on_rightclick = function(pos)
		  minetest.swap_node(pos, {name = "artifice:battery"})
	  end,

	  energyproducer =
		  { take_energy = take_battery_energy },

	  linkoutput = { on_link = link,
			 remove_links = remove_battery_links,
	  },
})


minetest.register_abm({
	nodenames = {"artifice:battery_charging"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)

		local charge = meta:get_int("charge")
		local sources = minetest.deserialize(meta:get_string("sources")) or {}

		local amt = math.min(max_charge - charge, packet_size)
		local taken = 0

		local requestor = { type = "node",
				    pos = pos,
		}

		for i, source in pairs(sources) do
			local taken_once = artifice.request_energy(source, amt - taken, requestor)

			taken = taken + taken_once
		end

		local new_charge = charge + taken

		set_charge(meta, new_charge)
	end,
})
