
-- Messier version of executor that permits serialization

local executors = {}
local exports = {}

-- No type tags: An execute is just a function that looks like
--   func(env, input, tail, param)
--
--   Tail is a chain to run afterwords, with the form
--     { type = "base" or "parallel" or "serial" or "nothing",
--       base = "base_name", -- If type == "base"
--       param = <some parameter data> -- If type == "base"
--       op1 = chain1, -- If type == "parallel" or "serial"
--       op2 = chain2,
--     }
--
-- param is a parameter specific to the executor. param could be nil if the
-- particular executor does not need one.
--
-- Chains are the composable units of execution.

function exports.register_executor(name, func)
	executors[name] = func
end

exports.empty = { type = "nothing" }

function exports.singleton(name, param)
	return { type = "base",
		 base = name,
		 param = param,
	}
end

local singleton = exports.singleton

function exports.andThen(chain1, chain2)
	return { type = "serial",
		 op1 = chain1,
		 op2 = chain2,
	}
end

local andThen = exports.andThen

function exports.both(chain1, chain2)
	return { type = "parallel",
		 op1 = chain1,
		 op2 = chain2,
	}
end

local both = exports.both

-- Takes a chain and runs it with the arguments.
local function run_chain(chain, env, input, tail)
	local typ = chain.type

	if typ == "base" then
		executors[chain.base](env, input, tail, chain.param)
	elseif typ == "parallel" then
		run_chain(chain.op1, env, input, tail)
		run_chain(chain.op2, env, input, tail)
	elseif typ == "serial" then
		run_chain(chain.op1, env, input, chain.op2:andThen(tail))
	end
end

exports.run_chain = run_chain

-- Example
exports.register_executor("passThrough", function(env, input, chain)
	exports.run_chain(chain, env, input, exports.empty)
end)


artifice.exec = exports
