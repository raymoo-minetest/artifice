
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
	local can_learn, on_learn = make_callbacks(def.ap_cost)
	def.can_learn = can_learn
	def.on_learn = on_learn
	def.description = def.description .. " (Cost: " .. def.ap_cost .. ")"
	
	comp_tree:add(name, def)
end


function artifice.components(p_name)
	return comp_tree:player_nodes(p_name)
end


-- Insert component registrations here --


-- End component registrations --


local maybe_string = artifice.load_data("comp_tree")
local datas = (maybe_string and comp_tree:deserialize_data(maybe_string))
	or comp_tree:new_data()


function save()
	artifice.save_data("comp_tree", datas:serialize())
end


function artifice.show_skills(p_name)
	local fs = "size[9,9]"
	fs = fs .. datas:build_formspec(p_name)

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
