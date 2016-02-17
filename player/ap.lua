
-- Ability points

local function load_aps()
	local ser = artifice.load_data("ap")
	return (ser and minetest.deserialize(ser)) or {}
end

local aps = load_aps()

local function save_aps(aps)
	local ser = minetest.serialize(aps)
	return artifice.save_data("ap", ser)
end


-- An ability point record for a player is a table with these fields:
--   points_spent: A nonnegative integer


local function calc_ap(level)
	return level
end


function artifice.get_ap(p_name)
	local rec = aps[p_name]
	local base = calc_ap(artifice.get_level(p_name))

	if not rec then
		return base
	end
	return base - rec.points_spent
end


local function change_spent(p_name, amt)
	local rec = aps[p_name]
	if not rec then
		aps[p_name] = { points_spent = amt }
	else
		rec.points_spent = amt + rec.points_spent
	end

	save_aps(aps)
end


-- Returns true on success, false on fail
function artifice.subtract_ap(p_name, amt)
	local limit = artifice.get_ap(p_name)

	if limit < amt then return false end
	
	change_spent(p_name, amt)
	return true
end
