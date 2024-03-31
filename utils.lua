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
---@param values? string[]
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

---@class ConfigColors
local config_colors = {
	primary = colors.lime,
	secondary = colors.yellow,
	setting = colors.purple,
	info = colors.blue,
}

local CONFIG_NAME = "tracker"
---@class AppConfig
---@field user? string
---@field colors ConfigColors
local config = { colors = config_colors }

---Loads or defines the config file.
local function load_settings()
	if not settings.getDetails(CONFIG_NAME).description then
		settings.define(CONFIG_NAME, {
			description = "Config details for `tracker`",
			type = "table",
		})
	end
	config = settings.get(CONFIG_NAME, config)
end

local function save_settings()
	settings.set(CONFIG_NAME, config)
	settings.save()
end

---Changes the user for the tracker.
---@param new_user string
local function change_user(new_user)
	config.user = new_user
	save_settings()
end

---Gets the current user of the tracker.
---@return string | nil
local function get_user()
	return config.user
end

local function get_colors()
	return config.colors
end

local text = {}

---Wrap string with `primary_color`
---@param str string
---@return Doc
function text.primary(str)
	return pretty.text(str, config.colors.primary)
end

---Wrap string with `secondary_color`
---@param str string
---@return Doc
function text.secondary(str)
	return pretty.text(str, config.colors.secondary)
end

---Wrap string with `info_color`
---@param str string
---@return Doc
function text.info(str)
	return pretty.text(str, config.colors.info)
end

---Wrap string with `setting_color`
---@param str string
---@return Doc
function text.setting(str)
	return pretty.text(str, config.colors.setting)
end

---Wrap string with `red`
---@param str string
---@return Doc
function text.error(str)
	return pretty.text(str, colors.red)
end

---Wrap string with `gray`
---@param str string
---@return Doc
function text.gray(str)
	return pretty.text(str, colors.gray)
end

---@generic T
---@param arr `T`[][]
---@param rotations integer
---@return `T`[][]
local function rotate2d(arr, rotations)
	---@type `T`[][]
	local result = {}

	rotations = rotations % 4

	for _, row in ipairs(arr) do
		local new_row = {}
		---@diagnostic disable-next-line: no-unknown
		for _, v in ipairs(row) do
			table.insert(new_row, v)
		end
		table.insert(result, new_row)
	end

	for _ = 1, rotations do
		---@type `T`[][]
		local rotated = {}
		for x, row in ipairs(result) do
			---@diagnostic disable-next-line: no-unknown
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
	get_user = get_user,
	change_user = change_user,
	load_config = load_settings,
	text = text,
	prompt = prompt,
	prompt_args = promt_args,
	get_colors = get_colors,
	rotate2d = rotate2d,
	concat2d = concat2d,
}
