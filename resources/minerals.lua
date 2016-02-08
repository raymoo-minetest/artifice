
-- Mana Crystals

minetest.register_craftitem("artifice:mana_crystal",
	{ description = "Mana Crystal",
	  inventory_image = "artifice_mana_crystal.png",
})

minetest.register_node("artifice:stone_with_mana",
	{ description = "Mana Crystal Ore",
	  tiles = {"default_stone.png^artifice_mineral_mana.png"},
	  paramtype = "light",
	  groups = {cracky=1},
	  drop = "artifice:mana_crystal",
	  sounds = default.node_sound_stone_defaults(),
	  light_source = 2,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "artifice:stone_with_mana",
	wherein = "default:stone",
	clust_scarcity = 16 * 16 * 16,
	clust_num_ores = 3,
	clust_size = 2,
	y_min = -31000,
	y_max = -100,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "artifice:stone_with_mana",
	wherein = "default:stone",
	clust_scarcity = 32 * 32 * 32,
	clust_num_ores = 20,
	clust_size = 5,
	y_min = -31000,
	y_max = -200,
})
