
-- An unlimited energy source for use in creative mode.

minetest.register_node("artifice:creative_producer",
	{ description = "Box of Unlimited Power",
	  groups = {oddly_breakable_by_hand=3, energyproducer=1},
	  tiles = {"artifice_creative_producer.png",
		   "artifice_creative_producer.png",
		   "artifice_creative_producer.png",
		   "artifice_creative_producer.png",
		   "artifice_creative_producer.png",
		   "artifice_creative_producer.png",
	  },

	  energyproducer =
		  { take_energy = function(pos, amt, requestor)
			    artifice.make_energy_puff(pos, amt, requestor)
			    return amt
		  end},
})


minetest.register_node("artifice:creative_sink",
	{ description = "Power Sink",
	  groups = {oddly_breakable_by_hand=3, linkoutput=1},
	  tiles = {"artifice_creative_sink.png",
		   "artifice_creative_sink.png",
		   "artifice_creative_sink.png",
		   "artifice_creative_sink.png",
		   "artifice_creative_sink.png",
		   "artifice_creative_sink.png",
	  },

	  linkoutput = { on_link = function(pos, in_pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("source", minetest.pos_to_string(in_pos))
	  end,
			 remove_links = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("source", "")
end}})


minetest.register_abm({
	nodenames = {"artifice:creative_sink"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)

		local src_string = meta:get_string("source")

		local src_pos = minetest.string_to_pos(src_string)

		if src_pos == nil then return end

		artifice.request_energy(src_pos, 1000, { type = "node",
							 pos = pos,
		})
	end,
})
