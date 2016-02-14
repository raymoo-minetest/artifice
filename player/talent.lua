
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


local pd_methods = {}
local pd_meta = { __index = pd_methods }


-- A talent player data is just a progress tree player data, but wrapped so
-- a different method table can be used. It has two fields: data, for the
-- prog tree player data, and tree, for the talent tree.
function tt_methods.new_p_data(self, learned)
	local ret = { data = self.prog_tree:new_player_data(learned),
		      tree = self,
		    }

	setmetatable(ret, pd_meta)
	return ret
end


function tt_methods.deserialize_p_data(self, serialized)
	local ret = { data = self.prog_tree:deserialize_player_data(serialized),
		      tree = self,
		    }

	setmetatable(ret, pd_meta)
	return ret
end


function pd_methods.serialize(self)
	return self.data:serialize()
end


function pd_methods.knows(self, node_name)
	return self.data:knows(node_name)
end


-- Checks both that prerequisites are filled, and the registered can_learn.
function pd_methods.can_learn(self, node_name, p_name)
	local intern_can = self.data:can_learn(node_name)
	
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
function pd_methods.learn(self, node_name, p_name)
	local intern_succ = self.data:learn(node_name)

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
function pd_methods.build_formspec(self, p_name, off_x, off_y)
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

		if self:knows(name) then
			state = "learned"
		elseif self:can_learn(name, p_name) then
			state = "available"
		else
			state = "unavailable"
		end

		table.insert(acc, node_button(name, def, state, off_x, off_y))
	end

	return table.concat(acc)
end


-- Does not reshow the formspec.
function pd_methods.handle_fields(self, p_name, fields)
	local defs = self.tree.node_defs
	
	for name, content in pairs(fields) do
		if self:can_learn(name, p_name) then
			self:learn(name, p_name)
		end
	end
end


dofile(artifice.playerpath .. "talent_test.lua")
