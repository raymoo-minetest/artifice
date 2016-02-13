
-- Experience points and levels

-- A single player's experience profile is a table with these fields:
--   level: The player's current level
--   xp: The player's current experience points (above the level)

-- When a player's experience increases past the threshold for the next
-- level, her level is raised, and the xp used up is subtracted.

-- The experience needed to advance is 20 * current_level^1.5


local function load_xps()
	local ser = artifice.load_data("xp")
	return (ser and minetest.deserialize(ser)) or {}
end


local function save_xps(xps)
	local ser = minetest.serialize(xps)
	return artifice.save_data("xp", ser)
end


local xps = load_xps()

local level_callbacks = {}


local function init_player_xp(p_name)
	xps[p_name] = { level = 1, xp = 0 }
end


local function xp_to_advance(level)
	return 20 * level * math.sqrt(level)
end


function artifice.get_xp(p_name)
	return (xps[p_name] and xps[p_name].xp) or 0
end


function artifice.get_level(p_name)
	return (xps[p_name] and xps[p_name].level) or 1
end


function artifice.xp_remaining(p_name)
	return xp_to_advance(artifice.get_level(p_name)) - artifice.get_xp(p_name)
end


local function execute_callbacks(p_name, new_lev)
	for i, cb in ipairs(level_callbacks) do
		cb(p_name, new_lev)
	end
end


function artifice.give_xp(p_name, amt)
	if not xps[p_name] then init_player_xp(p_name) end

	local cur_xp = artifice.get_xp(p_name)
	local cur_lev = artifice.get_level(p_name)

	local new_xp = cur_xp + amt
	local xp_needed = xp_to_advance(cur_lev)

	if new_xp >= xp_needed then
		xps[p_name].level = cur_lev + 1
		xps[p_name].xp = 0
		execute_callbacks(p_name, cur_lev + 1)

		artifice.give_xp(p_name, amt - xp_needed)
	else
		xps[p_name].xp = new_xp
	end
end


-- Takes a func(player_name, new_level)
-- Do not do anything adding experience or levels in this callback.
function artifice.register_on_levelup(cb)
	table.insert(level_callbacks, cb)
end


minetest.register_privilege("givexp", "Ability to dole out xp")


minetest.register_chatcommand("givexp", {
	params = "<name> <xp>",
	description = "Give experience points to player",
	privs = { givexp = true },
	func = function(name, param)
		local name_s, name_e = param:find("%w+")

		if name_s == nil then return false, "Specify a player or xp" end

		local target_name = param:sub(name_s, name_e)
		local xp_s = artifice.trim(param:sub(name_e + 1, -1))

		local xp
		local target
		if xp_s == "" then
			target = name
			xp = tonumber(artifice.trim(target_name))
		else
			target = artifice.trim(target_name)
			xp = tonumber(artifice.trim(xp_s))
		end

		if xp == nil then return false, "Bad number" end

		artifice.give_xp(target, xp)
		minetest.chat_send_player(name, "XP given.")
	end,
})
	

artifice.register_on_levelup(function(p_name, level)
	minetest.chat_send_player(p_name, "You leveled up!")
	minetest.chat_send_player(p_name, "Welcome to level " .. level .. ".")
end)


local save_interval = 10
local elapsed = 0

minetest.register_globalstep(function(dtime)
	elapsed = elapsed + dtime

	if elapsed >= save_interval then
		save_xps(xps)
		elapsed = 0
	end
end)


minetest.register_on_shutdown(function()
	save_xps(xps)
end)
