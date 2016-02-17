
local exec = artifice.exec

-- Spells

artifice.spellpath = artifice.modpath .. "/spell/"
local sp = artifice.spellpath

artifice.components = {}


-- A spell component is a table with a field type of either "shape" or "effect",
-- based on whether they were registered as a spell shape or an effect. They will
-- also have the fields they were registered with.


-- An effect recipe represents a spell effect. It is a table with fields:
--   name: Registered name of the spell effect
--   modifiers: Set of string modifier tags


-- A shape recipe represents a spell shape and its associated tail. It is a table
-- with fields:
--   name: Registered name of the spell shape
--   modifiers: Set of string modifier tags
--   effects: A list of effect recipes
--   tail: Another shape recipe (May be nil)


-- A spell recipe is a template for creating spells. It is a table with fields:
--   name: Name of the recipe (used for display)
--   owner: Name of the creator
--   recipe: A shape recipe


-- A spell description has the following fields:
--   name: Name of the spell (used for display)
--   owner: Name of the creator
--   uid: Unique (enough) ID. Use math.rand or something. This can be used
--        for prorating experience gained from repeated casts
--   mana_cost: A positive integer
--   affinities: A map from affinity names to nonnegative numbers
--   chain: An executor chain for the spell


local function compile_effect(eff_rep)
	local def = artifice.components[eff_rep.name]
	if def == nil then
		minetest.log("error", "Unknown spell component: " .. eff_rep.name)
	end

	if def.type ~= "effect" then
		minetest.log("error", "Expected effect, got "
				     .. eff_rep.type .. " "
				     .. eff_rep.name)
	end

	local chain = single(def.executor, {
				     modifiers = eff_rep.modifiers,
				     affinities = def.affinities or {}
	})
	local cost = def.calc_cost(eff_rep.modifiers)
	local affinities = def.affinities or {}

	return chain, cost, affinities
end


local function mix_affinities(affs1, affs2)
	local ret = {}
	for k, v in pairs(affs1) do
		ret[k] = v
	end

	for k, v in pairs(affs2) do
		ret[k] = (ret[k] and ret[k] + v) or v
	end
end


local function compile_helper(shape_rep)
	local single = exec.singleton
	local andThen = exec.andThen
	local both = exec.both
	
	if shape_rep == nil then return exec.empty, 0, {} end

	local shape_def = artifice.components[shape_rep.name]

	if shape_def == nil then
		minetest.log("error", "Unknown spell component: " .. shape_rep.name)
		return exec.empty, 0, {}
	end

	if shape_def.type ~= "shape" then
		minetest.log("error", "Expected shape, got "
				     .. shape_def.type .. " "
				     .. shape_def.name)
		return exec.empty, 0, {}
	end

	local tail_chain, tail_cost, tail_aff = compile_helper(shape_rep.tail)

	local effect_chain = exec.empty
	local base_cost = tail_cost
	local affinities = {}
	affinities = mix_affinities(affinities, tail_aff)

	for i, eff_rep in ipairs(shape_rep.effects) do
		local e_chain, e_cost, e_affs = compile_effect(eff_rep)

		effect_chain = both(effect_chain, e_chain)
		base_cost = base_cost + e_cost
		affinities = mix_affinities(affinities, e_affs)
	end

	local mult = shape_def.calc_multiplier(shape_rep.modifiers)
	local cost = base_cost * mult
	local final_tail_chain = both(effect_chain, tail_chain)

	local this_single = single(shape_def.executor, {
					   modifiers = shape_rep.modifiers,
					   affinities = affinities
	})

	local chain = this_single:andThen(final_tail_chain)

	return chain, cost, affinities
end


-- Takes a spell recipe and returns a spell description
function artifice.compile_spell_recipe(recipe)
	local chain, cost, affinities = compile_helper(recipe.recipe)

	return { name = recipe.name,
		 owner = recipe.owner,
		 uid = math.random(1, 1000000000),
		 mana_cost = cost,
		 affinities = affinities,
		 chain = chain,
	}
end


-- An executor function for giving xp/affinities. Input is a number, param
-- does not matter. Tail is not called.
exec.register_executor("artifice:give_xp", function(env, input, tail, param)
	local owner = env.owner
	local xp_to_give = input

	artifice.give_xp(owner, xp_to_give)
end)
	
-- The most general spell-casting function. Directly takes a shape_inout for
-- custom spell applications. Player name is an optional argument that should
-- be input when a particular player casts. spell is a spell description.
-- This function does not handle mana costs.
function artifice.cast_spell(spell, quality, cast_mode, shape_inout, p_name)
	local spell_chain = spell.chain
	local chain = exec.andThen(spell.chain, single("artifice:give_xp", {}))

	local env = { player = p_name,
		      owner = spell.owner,
		      spell_id = spell.uid,
		      cast_mode = cast_mode,
		      quality = quality,
	}

	exec.run_chain(chain, env, shape_inout, exec.empty)
end


function artifice.cast_pointed(spell, quality, cast_mode, pointed_thing, pointer)
	local inout = { type == "pointed",
			source_pos = pointer:getpos(),
			pointed_thing = pointed_thing,
	}

	artifice.cast_spell(spell, quality, cast_mode, inout, pointer:get_player_name())
end


local function spell_cost(base, cast_mode)
	if cast_mode == 1 then
		return base * 0.5
	elseif cast_mode == 3 then
		return base * 1.5
	else
		return base
	end
end


-- What will probably be used most of the time. Like cast_pointed, but has mana
-- cost. Returns success.
function artifice.cast_player(spell, quality, cast_mode, pointed_thing, player)
	local p_name = player:get_player_name()

	local taken = mana.subtract(p_name, spell_cost(spell.mana_cost, cast_mode))
	if not taken then return false end
	
	artifice.cast_pointed(spell, quality, cast_mode, pointed_thing, player)
	return true
end

dofile(sp .. "registration.lua")
dofile(sp .. "component_tree.lua")
dofile(sp .. "design_table.lua")
