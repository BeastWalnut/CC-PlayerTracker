---Returns true if `tbl` contains `val`
---@param tbl table
---@param val any
---@return boolean
function table.contains(tbl, val)
	---@diagnostic disable-next-line: no-unknown
	for _, v in ipairs(tbl) do
		if v == val then
			return true;
		end
	end
	return false
end

---Rounds and returns `number`
---@param number number
---@return integer
function math.round(number)
	return math.floor(number + .5);
end

return {}
