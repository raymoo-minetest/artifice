
artifice.savedir = minetest.get_worldpath() .. "/artifice_save/"
minetest.mkdir(artifice.savedir)

-- Returns true on success, false on failure
function artifice.save_data(name, data)
	local save_file = io.open(artifice.savedir .. name, "wb")

	save_file:write(data)
	save_file:close()
end
		

-- Returns the string on success, nil on failure
function artifice.load_data(name)
	local save_file = io.open(artifice.savedir .. name, "rb")

	if save_file == nil then return end

	local contents = save_file:read("*a")

	save_file:close()

	return contents
end
