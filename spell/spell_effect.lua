
-- "spell_env" refers to a table holding these fields:
--   - player - casting player's name
--   - spell_id - Unique numerical ID of the spell

-- "shape_inout" refers to a table with these fields:
--   - type - Either "initial", "loc", or "entity"
--   - pointed_thing - holds a pointed_thing, only if type == "initial"
--   - dir - holds a direction, if type is "loc" or "entity". Might be nil.
--   - loc - holds a position, if type == "loc"
--   - entity - holds an ObjectRef, if type == "entity".

-- "local_env" is a table with these fields:
--   - modifiers - A set of string modifier tags
--   - affinity - A map from affinity names to levels (adds up to 1)

-- Effect definition is a table with fields:
--   - disp_name: Display name
--   - description: A description of the effect
--   - texture: An icon for the item
--   - sound: Sound to play (optional)
--   - executor: Name of an executor with env type spell_env, input type
--     shape_inout, output type number, param type local_env

artifice.effects = {}

function artifice.register_effect(name,def)
	artifice.effects[name] = def
	local i_name = "artifice:effect_" .. name

	minetest.register_craftitem(i_name,
		{ description = "Effect: " .. def.disp_name,
		  groups = { spell_effect = 1, not_in_creative_inventory = 1 },
		  effect = name,
		  inventory_image = def.texture,
		  stack_max = 1,
	})

end
