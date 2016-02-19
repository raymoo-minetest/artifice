
-- Recipe items

-- Data about the recipe each player is currently viewing
local p_viewing = {}


local function mod_desc(mod_name)
	local def = artifice.components[mod_name]

	local disp_name = def and def.disp_name or mod_name

	return "        - " .. disp_name .. "\n"
end


local function eff_desc(recipe)
	local def = artifice.components[recipe.name]

	local disp_name = def and def.disp_name or recipe.name

	local fs = ""
	fs = fs .. "    - " .. disp_name .. "\n"

	for k in pairs(recipe.modifiers) do
		fs = fs .. mod_desc(k)
	end

	return fs
end


-- Returns a string listing the spell components under a shape.
local function shape_desc(recipe)
	local def = artifice.components[recipe.name]
	local disp_name = def and def.disp_name or recipe.name

	local fs = ""
	fs = fs .. "- " .. disp_name .. "\n"

	for k in pairs(recipe.modifiers) do
		fs = fs .. mod_desc(k)
	end
	
	for i, eff_recipe in ipairs(recipe.effects) do
		fs = fs .. eff_desc(eff_recipe)
	end

	if recipe.tail then
		fs = fs .. shape_desc(recipe.tail)
	end

	return fs
end


local function mats_string(recipe)
	local acc = {}
	
	for i, itemstr in ipairs(recipe.material_costs) do
		local old = acc[itemstr]
		if old then
			acc[itemstr] = old + 1
		else
			acc[itemstr] = 1
		end
	end

	local str_acc = {}

	for itemstr, amt in pairs(acc) do
		local def = ItemStack(itemstr):get_definition()
		local desc = def and def.description or itemstr

		table.insert(str_acc, "- " .. desc .. " x" .. amt .. "\n")
	end

	return table.concat(str_acc)
end


local function label(x,y,text)
	return "label[" .. x .. "," .. y .. ";" .. minetest.formspec_escape(text) .. "]"
end


-- Takes a spell recipe and makes a formspec header with name and author.
local function header(recipe)
	return "size[8,8]" .. label(0, 0, recipe.name .. ", designed by " .. recipe.owner)
end


local function button(x,y,w,h,name,label)
	return "button[" .. x .. "," .. y .. ";"
		.. w .. "," .. h .. ";"
		.. name .. ";" .. minetest.formspec_escape(label) .. "]"
end


local buttons =
	button(0.5, 6.5, 2, 1, "comp_butt", "Components")
	.. button(3, 6.5, 2, 1, "mat_butt", "Materials")


local function textarea(x,y,w,h,name,label,default)
	default = default or ""
	return "textarea[" .. x .. "," .. y .. ";"
		.. w .. "," .. h .. ";" .. name .. ";"
		.. minetest.formspec_escape(label) .. ";"
		.. minetest.formspec_escape(default) .. "]"
end


local function components_page(recipe, header)
	return header
		.. textarea(0.25, 1, 7, 6, "comp_text", "Components:", shape_desc(recipe.recipe))
		.. buttons
end


local function materials_page(recipe, header)
	return header
		.. textarea(0.25, 1, 7, 6, "mat_text", "Materials:", mats_string(recipe))
		.. buttons
end


local recipe_form = "artifice:recipe"


local function show_recipe(p_name, recipe)
	local state = p_viewing[p_name]
	if not state then
		state = { page = "components",
		}
		p_viewing[p_name] = state
	end

	-- Called with no new recipe 
	if not recipe then
		if state.page == "components" and state.comp_page then
			minetest.show_formspec(p_name, recipe_form, state.comp_page)
		elseif state.page == "materials" and state.mat_page then
			minetest.show_formspec(p_name, recipe_form, state.mat_page)
		end
	else -- New recipe
		local header = header(recipe)
		state.comp_page = components_page(recipe, header)
		state.mat_page = materials_page(recipe, header)

		show_recipe(p_name)
	end
end


local function handle_fields(player, formname, fields)
	if formname ~= recipe_form then return end

	local p_name = player:get_player_name()
	local state = p_viewing[p_name]

	if not state then return end

	if fields.comp_butt then
		state.page = "components"
		show_recipe(p_name)
	elseif fields.mat_butt then
		state.page = "materials"
		show_recipe(p_name)
	end

	return true
end

minetest.register_on_player_receive_fields(handle_fields)


minetest.register_craftitem("artifice:recipe", {
	description = "Spell Recipe",
	groups = { not_in_creative_inventory = 1 },
	inventory_image = "artifice_recipe.png",
	stack_max = 1,
	on_use = function(stack, user)
		local p_name = user:get_player_name()
		local meta = stack:get_metadata()
		local recipe = minetest.deserialize(meta)

		if not recipe then
			return
		end

		show_recipe(p_name, recipe)
	end,
})
