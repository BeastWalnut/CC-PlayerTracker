---@param tbl table
---@param val any
---@return boolean
local function contains(tbl, val)
	---@diagnostic disable-next-line: no-unknown
	for _, v in ipairs(tbl) do
		if v == val then
			return true;
		end
	end
	return false
end

---Get the current user.
---@return string
local function get_user()
	-- TODO
end

---Sets the current user.
---@param name string
local function set_user(name)
	--TODO
end

return {
	contains = contains,
	get_user = get_user,
	set_user = set_user,
}
