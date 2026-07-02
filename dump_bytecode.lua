local script_cache = {}
local output_dir = "bytecode_dump"
pcall(function() delfolder(output_dir) end)

local count = 0
local function walk(inst, path)
	for _, child in next, inst:GetChildren() do
		local child_path = path .. "/" .. child.Name:gsub("[<>:\"/\\|?*]", "_")
		if child:IsA("LuaSourceContainer") then
			local ok, bc = pcall(getscriptbytecode, child)
			if ok and bc and bc ~= "" then
				writefile(output_dir .. "/" .. child.ClassName .. "_" .. child.Name:gsub("[<>:\"/\\|?*]", "_") .. "_" .. tostring(count) .. ".luauc", bc)
				writefile(output_dir .. "/" .. child.ClassName .. "_" .. child.Name:gsub("[<>:\"/\\|?*]", "_") .. "_" .. tostring(count) .. ".txt", child:GetFullName())
				count = count + 1
			end
		end
		walk(child, child_path)
	end
end

walk(game, "game")
if count == 0 then
	warn("No scripts found or getscriptbytecode unavailable")
else
	print("Dumped " .. count .. " scripts to " .. output_dir)
end
