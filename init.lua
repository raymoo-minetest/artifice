artifice = {}
artifice.save = {}

artifice.modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

dofile(artifice.modpath .. "util.lua")
dofile(artifice.modpath .. "executor_reified.lua")
dofile(artifice.modpath .. "energy/energy.lua")
