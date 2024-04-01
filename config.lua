---Extends `dest` with the contents of `src` replacing existing values
---@param dest table
---@param src table
---@return table
local function tbl_extend(dest, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dest[k]) == "table" then
			tbl_extend(dest[k], v)
		else
			dest[k] = v
		end
	end

	return dest
end

local CONFIG_NAME = "tracker"

if not settings.getDetails(CONFIG_NAME).description then
	settings.define(CONFIG_NAME, {
		description = "Config details for `tracker`",
		type = "table",
	})
end

local nicks = {} ---@type { [string]: string }
local user ---@type string

---@class AppConfig
local M = { }

---@class ConfigColors
local Colors = {
	primary = colors.lime,
	secondary = colors.yellow,
	setting = colors.purple,
	info = colors.blue,
}

function M.save()
	settings.set(CONFIG_NAME, {
		colors = Colors,
		nicks = nicks,
		user = user,
	})
	settings.save()
end

function M.load()
	local saved = settings.get(CONFIG_NAME, {})
	if saved.nicks then
		tbl_extend(nicks, saved.nicks)
	end
	if saved.colors then
		tbl_extend(Colors, saved.colors)
	end
	user = saved.user or user
end

---@class NicksConf
M.nicks = {}

---Returns the username associated with `nick`
---@param nick string
---@return string?
function M.nicks.get(nick)
	return nicks[nick:lower()]
end

---Changes `nick` to be associated to `user`
---@param nick string
---@param username string?
function M.nicks.change(nick, username)
	nicks[nick:lower()] = username
	M.save()
end

---Returns all the saved nicks
---@return string[]
function M.nicks.all()
	local result = {}
	for nick, _ in pairs(nicks) do
		table.insert(result, nick)
	end
	return result
end


---@class UserConf
M.user = {}

---Changes the apps user to `username`
---@param username string
function M.user.change(username)
	user = username
	M.save()
end

---Gets the user of the app
---@return string?
function M.user.get()
	return user
end

---Returns the app colors
---@return ConfigColors
function M.colors()
	return Colors
end

return M
