
local tt = artifice.talent_tree

local comp_tree = tt.new_tree(9, 9, "default_stone.png")

local save

local function make_callbacks(ap_cost)
	local function check_cb (p_name)
		return artifice.get_ap(p_name) >= ap_cost
	end

	local function use_cb (p_name)
		artifice.subtract_ap(p_name, ap_cost)
		save()
	end

	return check_cb, use_cb
end


-- Takes basically the same thing as a talent definition, but replace can_learn,
-- on_learn with just ap_cost.
local function add_component(name, def)
	local actual_comp = {}
	for k, v in pairs(def) do
		actual_comp[k] = v
	end
	
	local can_learn, on_learn = make_callbacks(def.ap_cost)
	actual_comp.can_learn = can_learn
	actual_comp.on_learn = on_learn
	actual_comp.description = def.description .. " (Cost: " .. def.ap_cost .. ")"
	
	comp_tree:add(name, actual_comp)
end


-- Insert component registrations here --
add_component("touch", {
	description = "Touch",
	icon = "artifice_shape_back.png^artifice_touch.png",
	x = 4.5,
	y = 0.5,
	parents = {},
	ap_cost = 1,
})

add_component("dig", {
	description = "Dig",
	icon = "artifice_shape_back.png^artifice_dig.png",
	x = 4.5,
	y = 1.5,
	parents = { touch = "straight",
	},
	ap_cost = 1,
})

	
-- End component registrations --


local maybe_string = artifice.load_data("comp_tree")
local datas = (maybe_string and comp_tree:deserialize_data(maybe_string))
	or comp_tree:new_data()


function save()
	artifice.save_data("comp_tree", datas:serialize())
end


function artifice.show_skills(p_name)
	local ap = artifice.get_ap(p_name)
	local ap_text = minetest.formspec_escape("AP: " .. ap)
	local fs = "size[9,10.5]"
	fs = fs .. "label[4,0.5;" .. ap_text .. "]"
	fs = fs .. datas:build_formspec(p_name, 0, 1.5)

	minetest.show_formspec(p_name, "artifice:comp_tree", fs)
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "artifice:comp_tree" then return end

	local p_name = player:get_player_name()

	if not fields["quit"] then
		datas:handle_fields(p_name, fields)
		artifice.show_skills(p_name)
	end

	return true
end)


function artifice.known_components(p_name)
	return datas:player_nodes(p_name)
end


--[[
minetest.register_on_joinplayer(function(player)
	artifice.show_skills(player:get_player_name())
end)
]]--
