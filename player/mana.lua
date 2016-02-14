
local start_max_mana = tonumber(minetest.setting_get("mana_default_max")) or 100
local start_mana_regen = tonumber(minetest.setting_get("mana_default_regen"))
	or mana.settings.regen_timer


local function max_for_level(level)
	return start_max_mana * level
end


local function regen_for_level(level)
	return start_mana_regen * level / math.sqrt(level)
end


local function apply_stats(p_name, multiplier)
	multiplier = multiplier or 1
	local p_level = artifice.get_level(p_name)
	mana.setmax(p_name, max_for_level(p_level) * multiplier)
	mana.setregen(p_name, regen_for_level(p_level) * multiplier)
end


minetest.register_on_joinplayer(function(player)
		apply_stats(player:get_player_name())
end)


artifice.register_on_levelup(function(p_name, level)
		apply_stats(p_name)
		mana.set(p_name, max_for_level(level))
end)
