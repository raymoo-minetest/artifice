
-- Resources
minetest.register_craft({
	type = "shapeless",
	output = "artifice:mana_dust 2",
	recipe = { "artifice:mana_crystal" },
})


-- Generators
minetest.register_craft({
	output = "artifice:mana_magnet",
	recipe = {
		{ "", "default:steel_ingot", ""},
		{ "group:wood", "artifice:mana_crystal", "group:wood"},
		{ "group:wood", "group:wood", "group:wood" },
	},
})
