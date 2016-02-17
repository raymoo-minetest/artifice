
local function revipairs(tab)
	local end_i = #tab

	local iterator = function(s, i)
		if i == 0 then return end

		return i - 1, tab[i]
	end

	return iterator, nil, end_i
end
	


-- Design table for spells


-- Parses a list of strings into a shape recipe. Returns success boolean, and
-- also an error string if it failed. Second return value is the parsed recipe
-- if it succeeded.
local function parse_recipe(comp_list)
	local cur_tail = nil
	local cur_effs = {}
	local cur_mods = {}

	-- Start at the back of the list
	for i, str in revipairs(comp_list) do
		local def = artifice.components[str]

		-- Modifier
		if def == nil then
			minetest.log("error", "Unknown spell component " .. str)
		elseif def.type == "effect" then -- Effect
			local new_effect = { name = str,
					     modifiers = cur_mods,
			}
			table.insert(cur_mods, new_effect)
			cur_mods = {}
		elseif def.type == "shape" then -- Shape

			-- The last shape has no effect
			if cur_tail == nil and next(cur_effs) == nil then
				return false, "The last shape must have an effect."
			end

			if cur_tail ~= nil and def.priority == "exclusive" then
				return false, def.disp_name .. " must be the only shape."
			end

			if cur_tail ~= nil and def.priority == "last" then
				return false, def.disp_name .. " must be the last shape."
			end

			if i ~= 1 and def.priority == "first" then
				return false, def.disp_name .. " must be the first shape."
			end

			local new_shape = { name = str,
					    modifiers = cur_mods,
					    effects = cur_effs,
					    tail = cur_tail,
			}

			cur_mods = {}
			cur_effs = {}
			cur_tail = new_shape
		elseif def.type == "modifer" then
			cur_mods[str] = true
		else -- Error
			error("Component " .. str .. " of unknown type " .. def.type)
		end
	end
		
	-- No shapes
	if cur_tail == nil then
		return false, "Needs at least one shape."
	end

	if next(cur_effs) ~= nil then
		return false, "All effects must come after a shape"
	end

	if next(cur_mods) ~= nil then
		return false, "All modifiers must come after a shape or effect."
	end

	return true, cur_tail
end


-- components is a list of component names
local function check_known(p_name, components)
	local known_comps = artifice.known_components(p_name)

	for i, comp in ipairs(components) do
		if not known_comps[comp] then return false end
	end

	return true
end


minetest.register_craftitem("artifice:recipe", {
	description = "Spell Recipe",
	groups = { not_in_creative_inventory = 1 },
	inventory_image = "artifice_recipe.png",
	stack_max = 1,
})


local function calc_material_cost(recipe)
end


local function make_recipe_item(recipe)
	local stack = ItemStack("artifice:recipe")
	local meta = recipe
	stack:set_metadata(minetest.serialize(meta))
	return stack
end


-- Design workspaces
local workspaces = {}

local function get_workspace(p_name)
	return workspaces[p_name] or {}
end


local function add_to_workspace(p_name, comp)
	local ws = get_workspace(p_name)

	table.insert(ws, comp)
	workspaces[p_name] = ws
end


local function remove_from_workspace(p_name, idx)
	local ws = get_workspace(p_name)

	table.remove(ws, idx)
	workspaces[p_name] = ws
end


local function clear_workspace(p_name)
	workspaces[p_name] = nil
end


local function comp_button(component, x, y, key)
	local def = artifice.components[component]
	if def == nil then return "" end
	key = key or component

	local name = def.disp_name
	local icon_s = minetest.formspec_escape(def.texture)

	local fs = "image_button[" .. x .. "," .. y .. ";0.5,0.5"
		.. icon_s .. ";" .. key .. ";]"
	local tooltip = "tooltip[" .. key .. ";" .. name .. "]"

	return fs .. tooltip
end


local function comp_top_buttons(comps, x, y, w)
	local cur_x = x
	local cur_y = y
	local x_bound = x + w - 0.5
	local fs = ""
	
	for k in pairs(comps) do
		fs = fs .. comp_button(k, cur_x, cur_y)

		cur_x = cur_x + 0.5
		if cur_x > x_bound then
			cur_x = x
			cur_y = cur_y + 0.5
		end
	end

	return fs
end


local function comp_bot_buttons(comps, x, y, w)
	local cur_x = x
	local cur_y = y
	local x_bound = x + w - 0.5
	local fs = ""

	for i, comp in ipairs(comps) do
		fs = fs .. comp_button(k, cur_x, cur_y, i)

		cur_x = cur_x + 0.5
		if cur_x > x_bound then
			cur_x = x
			cur_y = cur_y + 0.5
		end
	end
	
	return fs
end


local function make_formspec(p_name, spell_name, err_str)

	spell_name = spell_name or "New Spell"
	local known_comps = artifice.known_components(p_name)
	local ws = get_workspace(p_name)

	local fs = "size[9,9]"

	-- Name field
	fs = fs .. "field[0.5,0.5;8,1;name_field;Name: ;" .. spell_name .. "]"

	-- Component buttons
	fs = fs .. comp_top_buttons(known_comps, 0.5, 2, 8)
	fs = fs .. comp_bot_buttons(ws, 0.5, 4, 8)

	-- Create button
	fs = fs .. "button[0.5,6.5;2,1;butt_create;Create]"

	-- Clear button
	fs = fs .. "button[3.5,6.5;2,1;butt_clear;Clear]"

	if err_str then
		fs = fs .. "label[0.5,8;Error: " .. err_str .. "]"
	end

	return fs
end


-- Returns true and recipe on success, false and error string on fail
local function make_recipe_for_player(player, name, comps)
	local p_name = player:get_player_name()

	if name == "" then
		return false, "You must specify a name."
	end
	
	local all_known = check_known(p_name, comps)
	if not all_known then
		return false, "Some components not learned."
	end

	local inv = player:get_inventory()
	local has_paper = inv:contains_item("main", "default:paper")
	if not has_paper then
		return false, "No paper."
	end
		
	local succ, result = parse_recipe(comps)

	if not succ then
		return false, result
	end

	local recipe = { name = name,
			 owner = player:get_player_name(),
			 recipe = result,
	}
			 
	
	inv:remove_item("main", "default:paper")
	return true, make_recipe_item(recipe)
end


local table_form = "artifice:design_table"


local function show_table_form(p_name, spell_name, err_str)
	minetest.show_formspec(p_name, table_form, make_formspec(p_name, spell_name, err_str))
end


local function handle_fields(player, formname, fields)
	if formname ~= table_form then return end

	local p_name = player:get_player_name()

	if fields["butt_create"] then
		local ws = get_workspace(p_name)
		local succ, result = make_recipe_for_player(player, fields.name_field, ws)

		if not succ then
			show_table_form(p_name, fields.name_field, result)
		else
			minetest.add_item(player:getpos(), result)
		end

		return true
	end

	if fields["butt_clear"] then
		clear_workspace(p_name)

		show_table_form(p_name, fields.name_field)
		return true
	end

	-- Component buttons
	local known_comps = artifice.known_components(p_name)
	local ws = get_workspace(p_name)

	for k in pairs(fields) do
		if known_comps[k] then
			add_to_workspace(p_name, k)
			show_table_form(p_name, fields.name_field)

			return true
		end

		local number = tonumber(k)

		if number then
			remove_from_workspace(p_name, number)
			show_table_form(p_name, fields.name_field)

			return true
		end
	end
end
	

minetest.register_on_player_receive_fields(handle_fields)

--[[
minetest.register_on_joinplayer(function(player)
	show_table_form(player:get_player_name())
end)
]]--
