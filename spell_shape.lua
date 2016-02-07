
local exec = dofile(artifice.modpath .. "executor.lua")

local doNothing = exec.doNothing

local provide = exec.provide

local passThrough = exec.passThrough

local andThen = exec.andThen

local both = exec.both


artifice.shapes = {}

-- spell_env and shape_inout are specified in spell_effect.lua

-- Shape Def: a table with fields:
--   priority: A number denoting what position the shape should be in. Can also
--     be "first", "last", or "exclusive".
--   disp_name: Display name
--   description: Description of the shape
--   texture: An icon for the item
--   sound: Sound to play (optional)
--   executor: Name of an executor with env type spell_env, input type
--     shape_inout, output type shape_inout


function artifice.register_shape(name, def)
	artifice.shapes[name] = def
	local i_name = "artifice:shape_" .. name

	minetest.register_craftitem(i_name,
		{ description = "Shape: " .. def.disp_name,
		  groups = { spell_shape = 1, not_in_creative_inventory = 1 },
		  shape = name,
		  inventory_image = def.texture,
		  stack_max = 1,
	})
end


-- Example:

artifice.exec.register_executor("fizzle", function(env, input, tail)
	-- Don't do anything
end)
					
local fizzle =
	{ priority = "last", -- Place at the end, so as to make everything fail.
	  disp_name = "Fizzle",
	  description = "Causes your spell to fail",
	  texture = "default_stone.png",
	  executor = "fizzle",
	}
artifice.register_shape("fizzle", fizzle)	
	
