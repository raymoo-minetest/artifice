
-- "spell_env" refers to a table holding these fields:
--   - player - casting player's name
--   - spell_id - Unique numerical ID of the spell

-- "shape_inout" refers to a table with these fields:
--   - type - Either "directional", "node", or "entity"
--   - source_pos - Where the effect is coming from
--   - direction - Only if type == "directional"
--   - node_pos - Only if type == "node"
--   - entity - An ObjectRef, and only if type == "entity"

-- "local_env" is a table with these fields:
--   - modifiers - A map from modifier names to levels
--   - affinity - A map from affinity names to levels (adds up to 1)

-- Effect definition is a table with fields:
--   - disp_name: Display name
--   - description: A description of the effect
--   - texture: An icon for the item
--   - executor: Name of an executor with env type spell_env, input type
--     shape_inout, output type number, param type local_env


function artifice.register_effect(name, def)
	def.type = "effect"
	artifice.components[name] = def
	local i_name = "artifice:effect_" .. name

	minetest.register_craftitem(i_name,
		{ description = "Effect: " .. def.disp_name,
		  groups = { spell_effect = 1,
			     not_in_creative_inventory = 1,
			     spell_component = 1,
		  },
		  effect = name,
		  inventory_image = def.texture,
		  stack_max = 1,
	})

end
