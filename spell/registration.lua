
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

-- A spell component definition is a table with fields:
--   - type: Either "shape", "effect", or "modifier"
--   - disp_name: Display name
--   - description: A description of the effect
--   - texture: An icon for the component
--   - affinities: A map from affinity names to nonnegative integers
--   - calc_cost: A function taking a set of modifiers as input, outputting
--                a mana cost. In the case of type == "shape", this is a
--                multiplier applied to forward effects/shapes. If this is
--                type == "effect", then it is just a straight value, which you
--                should aim to be the casting cost of a medium casting mode
--                using a touch-based shape. This field has no effect for
--                modifiers.
--  - material_costs: A list of item names to spend during spell creation
--  - executor: An executor function with env type spell_env, param type
--              local_env, and input type shape_inout. For shapes, the
--              output is also shape_inout, but for effects it is a number,
--              representing XP gain. This field has no effect for modifiers.
--
--              **NOTE**: Once registered, this is just a string registered as
--              an executor.
--  - priority: An optional field, either "first", "last", or "exclusive". Only
--              for shapes.


-- Takes a component name and definition
function artifice.register_spell_component(name, def)
	local actual_def = {}

	for k,v in pairs(def) do
		actual_def[k] = v
	end

	local actual_exec = def.type .. "_" .. name
	
	artifice.exec.register_executor(actual_exec, def.executor)

	actual_def.executor = actual_exec

	artifice.components[name] = actual_def
end
