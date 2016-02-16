
-- "spell_env" refers to a table holding these fields:
--   - player - casting player's name. Could be nil if not a player.
--   - owner - Creator of the spell
--   - spell_id - Unique numerical ID of the spell
--   - cast_mode - Either 1, 2, or 3
--   - quality - Build quality. A nonnegative integer.

-- "shape_inout" refers to a table with these fields:
--   - type - Either "pointed", "directional", "node", or "entity"
--   - source_pos - Where the effect is coming from
--   - pointed_thing - if type == "pointed"
--   - direction - Only if type == "directional"
--   - above - If type == "node" (Might be nil)
--   - below - If type == "node" (Not nil)
--   - entity - An ObjectRef, and only if type == "entity"

-- "local_env" is a table with these fields:
--   - modifiers - A map from modifier names to levels
--   - affinities - A map from affinity names to levels (adds up to 1)

-- Effect definition is a table with fields:
--   - disp_name: Display name
--   - description: A description of the effect
--   - texture: An icon for the item
--   - affinities: A map from affinity names to nonnegative integers
--   - calc_cost: Takes a modifier set as input, and outputs a mana cost. As a
--                guideline, output the value for a touch-based cast on a medium
--                power setting.
--   - material_costs: A list of item names to spend during spell creation
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
