
local tt = artifice.talent_tree

local tree = tt.new_tree(8, 8, "artifice_talent_test.png")


local function dumb_learn(name)
	return function(p_name)
		minetest.chat_send_player(p_name, "You learned " .. name)
	end
end


tree:add("wood", {
	description = "Wood",
	icon = "default_tree.png",
	x = 1,
	y = 0,
	parents = {},
	on_learn = dumb_learn("Wood"),
})


tree:add("stone", {
	description = "Stone",
	icon = "default_stone.png",
	x = 5,
	y = 0,
	parents = {},
	on_learn = dumb_learn("Stone"),
})


tree:add("plank", {
	description = "Plank",
	icon = "default_wood.png",
	x = 4,
	y = 2,
	parents = {"wood"},
	on_learn = dumb_learn("Plank"),
})


tree:add("cobble", {
	description = "Cobblestone",
	icon = "default_cobble.png",
	x = 6,
	y = 2,
	parents = {"stone"},
	on_learn = dumb_learn("Cobblestone"),
})


tree:add("stonestick", {
	description = "Stone on a Stick",
	icon = "default_tool_stoneaxe.png",
	x = 2,
	y = 2,
	parents = {"wood", "stone"},
	on_learn = dumb_learn("Stone"),
})


tree:add("diamond", {
	description = "Diamond",
	icon = "default_diamond.png",
	x = 3,
	y = 4,
	parents = {"cobble", "stonestick", "plank"},
	on_learn = dumb_learn("Diamond"),
})


local maybe_string = artifice.load_data("talent_test")
local data = tree:deserialize_p_data(maybe_string) or tree:new_p_data()


local function show_tree(p_name)
	local fs = "size[9,9]"
	fs = fs .. data:build_formspec(p_name, 0.5, 0.5)

	minetest.show_formspec(p_name, "artifice:test_talent", fs)
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "artifice:test_talent" then return end

	local p_name = player:get_player_name()
	
	if not fields["quit"] then
		data:handle_fields(p_name, fields)
		artifice.save_data("talent_test", data:serialize())
		show_tree(p_name)
	end

	return true
end)


minetest.register_craftitem("artifice:test_talent", {
	description = "Ultimate Talents",
	groups = { not_in_creative_inventory = 1 },
	inventory_image = "default_book.png",

	on_use = function(itemstack, player)
		show_tree(player:get_player_name())
	end,
})
