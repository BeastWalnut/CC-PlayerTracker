local pretty = require("cc.pretty")
local completion = require("cc.completion")

---Returns true if `tbl` contains `val`
---@param tbl table
---@param val any
---@return boolean
function table.contains(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

---Rounds and returns `number`
---@param number number
---@return integer
function math.round(number)
	return math.floor(number + 0.5)
end

---@return any
function Todo(str)
	local err_msg = ("Not implemented: %s"):format(str)
	error(err_msg, 2)
end

---Clears the screen.
function Clear()
	term.clear()
	term.setCursorPos(1, 1)
end

---Prints `text` and then prompts for some input.
---@param prompt_str Doc
---@param values? string[] | fun(): string[]
---@param color? color
---@param history? string[]
---@param repl? string
---@param default? string
---@return string
local function prompt(prompt_str, values, color, history, repl, default)
	pretty.print(prompt_str)
	local c = term.getTextColor()

	term.setTextColor(color or colors.gray)
	write("> ")

	term.setTextColor(color or colors.white)
	local answer = read(repl, history, function(str)
		if type(values) == "function" then
			values = values()
		end
		return completion.choice(str, values or {})
	end, default)
	print("")

	term.setTextColor(c)
	return answer
end

---@param values string[]
---@return string[]
local function promt_args(values)
	local results = {}
	for _, str in ipairs(values) do
		local as_upper = str:lower():gsub("^%l", string.upper)
		table.insert(results, as_upper)
		table.insert(results, str:lower())
	end
	return results
end

---@generic T
---@param arr T[][]
---@param rotations integer
---@return T[][]
local function rotate2d(arr, rotations)
	local result = {}

	rotations = rotations % 4

	for _, row in ipairs(arr) do
		local new_row = {}
		for _, v in ipairs(row) do
			table.insert(new_row, v)
		end
		table.insert(result, new_row)
	end

	for _ = 1, rotations do
		---@generic T
		---@type T[][]
		local rotated = {}
		for x, row in ipairs(result) do
			for y, v in ipairs(row) do
				rotated[y] = rotated[y] or {}
				local idx = (#row - x) + 1
				rotated[y][idx] = v
			end
		end
		result = rotated
	end

	return result
end

---@param arr string[][]
---@return string
local function concat2d(arr)
	local result = {}

	for _, row in ipairs(arr) do
		local line = table.concat(row)
		table.insert(result, line)
	end

	return table.concat(result, "\n")
end

return {
	prompt = prompt,
	prompt_args = promt_args,
	rotate2d = rotate2d,
	concat2d = concat2d,
}
