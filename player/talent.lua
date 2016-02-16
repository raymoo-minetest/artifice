
-- Talent trees

artifice.talent_tree = {}

local tt = artifice.talent_tree
local pt = progress_tree


-- A talent tree is a tree of skills a player may progress through. It is a
-- table with these fields:
--   prog_tree: The underlying progress tree
--   background: Texture name of the background
--   width: Width in formspec units
--   height: Height in formspec units
--   node_defs: Map from node names to node definitions


local tt_methods = {}
local tt_meta = { __index = tt_methods }


-- A new, empty talent tree.
function tt.new_tree(width, height, background_texture)
	local ret = { prog_tree = pt.new_tree(),
		      background = background_texture,
		      width = width,
		      height = height,
		      node_defs = {},
		    }

	setmetatable(ret, tt_meta)
	return ret
end


-- A talent definition has these fields:
--   description: A string to be displayed to the user
--   icon: An icon for the talent
--   x: x position in the formspec
--   y: y position in the formspec
--   parents: A list of prerequisite talents
--   can_learn(player_name): A function returning a boolean whether the talent is
--                      learnable. For example, checking skill points.
--   on_learn(player_name): A function doing whatever learning the talent does.
--                          This function should be idempotent, so that it can
--                          be reapplied safely when a player rejoins.


-- Adds a talent to a talent tree. Use like tree:(talent_name, talent_def)
function tt_methods.add(self, name, talent_def)
	self.prog_tree:add(name, talent_def.parents)
	self.node_defs[name] = talent_def
end


local d_methods = {}
local d_meta = { __index = d_methods }


-- A talent data is a table with:
--   datas - map from player name to prog tree data
--   tree - the talent tree
function tt_methods.new_data(self)
	local ret = { tree = self,
		      datas = {},
	}

	setmetatable(ret, d_meta)
	return ret
end


-- Storage format - map from player names to serialized prog tree data
function tt_methods.deserialize_data(self, serialized)
	local deserialized = minetest.deserialize(serialized)
	if not deserialized then return end

	local datas = {}
	
	for p_name, p_str in pairs(deserialized) do
		datas[p_name] = self.prog_tree:deserialize_player_data(p_str)
	end

	local ret = { tree = self,
		      datas = datas,
	}
	
	setmetatable(ret, d_meta)
	return ret
end


function d_methods.serialize(self)
	local store_tab = {}
	local datas = self.datas

	for p_name, p_data in pairs(datas) do
		store_tab[p_name] = p_data:serialize()
	end

	return minetest.serialize(store_tab)
end


function d_methods.get_p_data(self, p_name)
	local datas = self.datas
	local p_data = datas[p_name]

	if p_data then return p_data end

	datas[p_name] = self.tree.prog_tree:new_player_data()

	return datas[p_name]
end


function d_methods.knows(self, p_name, node_name)
	local p_data = self:get_p_data(p_name)

	return p_data:knows(node_name)
end


-- Checks both that prerequisites are filled, and the registered can_learn.
function d_methods.can_learn(self, p_name, node_name)
	local p_data = self:get_p_data(p_name)
	local intern_can = p_data:can_learn(node_name)
	
	if not intern_can then return false end

	local def = self.tree.node_defs[node_name]
	if not def then return false end

	local can_learn = def.can_learn

	-- If no can_learn callback, it is always allowed
	if not can_learn then return true end

	return can_learn(p_name)
end


-- Does the learning. Returns false on failure, true on success. This bypasses
-- can_learn, in case you want to give a talent out of order.
function d_methods.learn(self, p_name, node_name)
	local p_data = self:get_p_data(p_name)
	local intern_succ = p_data:learn(node_name)

	if not intern_succ then return false end

	local def = self.tree.node_defs[node_name]
	if not def then
		error("Node " .. node_name .. " in internal tree not in talent tree")
	end

	local on_learn = def.on_learn

	if not on_learn then return true end

	on_learn(p_name)

	return true
end


function d_methods.player_nodes(self, p_name)
	local p_data = self:get_p_data(p_name)

	return p_data.learned
end


-- state is "available", "learned", or "unavailable"
local function node_button(name, def, state, off_x, off_y)
	local icon = def.icon

	if state == "learned" then
		icon = icon .. "^progress_tree_check.png^[colorize:#00FF00:50"
	end

	if state == "unavailable" then
		icon = icon .. "^[colorize:#000000:180"
	end

	local icon_s = minetest.formspec_escape(icon)

	local fs = "image_button[" .. def.x + off_x .. "," .. def.y + off_y .. ";1,1;"
		.. icon_s .. ";" .. name .. ";]"
	local tooltip = "tooltip[" .. name .. ";" .. def.description .. "]"

	return fs .. tooltip
end


-- Returns a formspec string, so you can modify it. It does not include the
-- size, so you can embed it in another formspec.
function d_methods.build_formspec(self, p_name, off_x, off_y)
	off_x = off_x or 0
	off_y = off_y or 0

	local tree = self.tree

	local background = tree.background
	local width = tree.width
	local height = tree.height
	local node_defs = tree.node_defs

	local acc = {}

	local bg_str = minetest.formspec_escape(background)
	local bg_fs = "background["
		.. off_x .. "," .. off_y
		.. ";" .. width .. "," .. height .. ";"
		.. bg_str .. "]"
	table.insert(acc, bg_fs)

	for name, def in pairs(node_defs) do
		local state

		if self:knows(p_name, name) then
			state = "learned"
		elseif self:can_learn(p_name, name) then
			state = "available"
		else
			state = "unavailable"
		end

		table.insert(acc, node_button(name, def, state, off_x, off_y))
	end

	return table.concat(acc)
end


-- Does not reshow the formspec.
function d_methods.handle_fields(self, p_name, fields)
	local defs = self.tree.node_defs
	
	for name, content in pairs(fields) do
		if self:can_learn(p_name, name) then
			self:learn(p_name, name)
		end
	end
end


dofile(artifice.playerpath .. "talent_test.lua")
