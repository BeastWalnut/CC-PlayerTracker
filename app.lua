local pretty = require("cc.pretty")
local pprint = pretty.print
local pwrite = pretty.write

local Tracker = require("api")
local utils = require("utils")
---@type AppConfig
local config = require("config")
-- local text = utils.text
local prompt = utils.prompt

config.load()
local user = config.user.get()
local c = config.colors()

local text = {}

---Wrap string with `primary_color`
---@param str string
---@return Doc
function text.primary(str)
	return pretty.text(str, c.primary)
end

---Wrap string with `secondary_color`
---@param str string
---@return Doc
function text.secondary(str)
	return pretty.text(str, c.secondary)
end

---Wrap string with `info_color`
---@param str string
---@return Doc
function text.info(str)
	return pretty.text(str, c.info)
end

---Wrap string with `setting_color`
---@param str string
---@return Doc
function text.setting(str)
	return pretty.text(str, c.setting)
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

local DIMENSIONS = {
	["minecraft:overworld"] = "Overworld",
	["minecraft:the_nether"] = "The Nether",
	["minecraft:the_end"] = "The End",
}

---@param str string
---@return string, string?
local function split_ws(str)
	local start, rest = str:match("(%S+)%s*(.*)")
	if rest == "" then
		rest = nil
	end
	return start, rest
end

---@param rest string?
---@param prompt_str Doc
---@param values? string[] | fun(): string[]
---@param color? color
---@param history? string[]
---@param repl? string
---@param default? string
---@return string, string?
local function rest_or_prompt(rest, prompt_str, values, color, history, repl, default)
	if rest then
		return split_ws(rest)
	else
		return prompt(prompt_str, values, color, history, repl, default)
	end
end

---@param doc Doc
local function print_last(doc)
	local _, h = term.getSize()
	term.setCursorPos(1, h)
	pwrite(doc)
end

---@param time number
---@return boolean
local function key_wait(time)
	print_last(text.secondary("Press any key to continue."))
	local timer_id = os.startTimer(time)
	repeat
		local event, id = os.pullEvent()
		if event == "key" then
			return true
		end
	until id == timer_id
	return false
end

---@param tracker Tracker
---@param rest? string
---@return string
local function change_user(tracker, rest)
	local username
	username, rest = rest_or_prompt(rest, text.setting("Choose the new user:"), function()
		return tracker:get_online()
	end, c.info)

	config.user.change(username)
	if not username:find("%S") then
		pwrite(text.info("Successfully unset user."))
	else
		pwrite(text.info("Successfully changed user to: "))
		pprint(text.setting("`" .. username .. "`"))
	end
	tracker:change_user(username)
	key_wait(2)
	return username
end

---Pretty prints `postion`.
---@param position FoundPos
local function print_pos(position)
	pwrite(text.primary("X: "))
	pprint(text.info(tostring(position.x)))

	pwrite(text.primary("Y: "))
	pprint(text.info(tostring(position.y)))

	pwrite(text.primary("Z: "))
	pprint(text.info(tostring(position.z)))

	local dimension = DIMENSIONS[position.dimension] or "Unknown"
	pwrite(text.primary("In "))
	pprint(text.info(dimension))

	if position.distance then
		local distance = ("%.1f"):format(position.distance)
		pwrite(text.info(distance))
		pprint(text.primary(" blocks away."))
	end
	if position.direction then
		local direction = math.round(position.direction / 45)

		local hi = colors.toBlit(c.info) -- High
		local lo = colors.toBlit(colors.gray) -- Low
		local e = " " -- Empty

		---@type string[][]
		local direction_arr = {
			{ lo, lo, e, e, e, lo, e, e, e, lo, lo },
			{ lo, e, e, e, lo, lo, lo, e, e, e, lo },
			{ e, e, e, e, e, e, e, e, e, e, e },
			{ e, e, e, e, e, e, e, e, e, e, e },
			{ e, lo, e, e, e, e, e, e, e, lo, e },
			{ lo, lo, e, e, e, e, e, e, e, lo, lo },
			{ e, lo, e, e, e, e, e, e, e, lo, e },
			{ e, e, e, e, e, e, e, e, e, e, e },
			{ e, e, e, e, e, e, e, e, e, e, e },
			{ lo, e, e, e, lo, lo, lo, e, e, e, lo },
			{ lo, lo, e, e, e, lo, e, e, e, lo, lo },
		}
		if (direction % 2) == 0 then
			direction_arr[1][6] = hi
			direction_arr[2][5] = hi
			direction_arr[2][6] = hi
			direction_arr[2][7] = hi
			direction = direction / 2
		else
			direction_arr[1][10] = hi
			direction_arr[1][11] = hi
			direction_arr[2][11] = hi
			direction = (direction - 1) / 2
		end
		if direction < 0 then
			direction = direction + 8
		end

		local rotated = utils.rotate2d(direction_arr, direction)

		local w, _ = term.getSize()
		local _, y = term.getCursorPos()
		local image = paintutils.parseImage(utils.concat2d(rotated))
		paintutils.drawImage(image, math.round((w - 10) / 2), y)
		term.setBackgroundColor(colors.black)
	end
end

---@param tracker Tracker
local function print_online(tracker)
	local online = tracker:get_online()
	pprint(text.primary("Online players:"))
	if #online == 0 then
		pprint(text.error("\n  You are all alone."))
	else
		for _, name in ipairs(online) do
			pwrite(text.info(" -"))
			pprint(text.info(name))
		end
	end
	print("")
end

local ACTION_NAMES = {
	"find",
	"track",
	"user",
	"nick",
	"help",
	"exit",

	"locate",
	"stalk",
}

---@type { [string]: fun(tracker: Tracker, rest: string?) }
local ACTIONS = {}
function ACTIONS.unknown()
	pprint(text.error("Unknown action."))
	pprint(pretty.concat(text.info("Use"), text.setting(" `Help` "), text.info("to get the list of commands.")))
	print_last(text.secondary("Press any key to continue."))
	os.pullEvent("key")
end

function ACTIONS.find(tracker, rest)
	local target = rest_or_prompt(rest, text.secondary("Choose player to find:"), function()
		local online = tracker:get_online()
		table.insert(online, "Nearest")
		table.insert(online, "nearest")
		return online
	end, colors.red)
	target = config.nicks.get(target) or target

	if target:lower() == "nearest" then
		target = tracker:get_nearest()
	end

	if not target then
		pprint(text.error("  No players in this dimension."))
	elseif not target:find("%S") then
		pprint(text.error("  Idiot forgot to write a name."))
	else
		local target_pos = tracker:relative_find(target)
		if target_pos then
			Clear()
			pwrite(text.info(target))
			pprint(text.secondary(" Is at:\n"))
			print_pos(target_pos)

			print_last(text.secondary("Press any key to continue."))

			os.pullEvent("key")
			return
		else
			pwrite(text.info("`" .. target .. "`"))
			if tracker:is_online(target) then
				pprint(text.error(" is in another dimension."))
			else
				pprint(text.error(" is offline."))
			end
		end
	end

	key_wait(2)
end

ACTIONS.locate = ACTIONS.find

function ACTIONS.track(tracker, rest)
	local target = rest_or_prompt(rest, text.secondary("Choose player to find:"), function()
		local online = tracker:get_online()
		table.insert(online, "Nearest")
		table.insert(online, "nearest")
		return online
	end, colors.red)
	target = config.nicks.get(target) or target
	local enabled = true

	local find_nearest = target:lower() == "nearest"
	if find_nearest then
		target = tracker:get_nearest()
	end

	if not target then
	elseif not target:find("%S") then
		pprint(text.error("  Idiot forgot to write a name."))
		enabled = false
	elseif not tracker:is_online(target) then
		pwrite(text.info("`" .. target .. "`"))
		pprint(text.error(" is offline."))
		enabled = false
	end

	while enabled do
		Clear()
		if find_nearest then
			target = tracker:get_nearest()
		end
		if target then
			local target_pos = tracker:relative_find(target)
			if target_pos then
				pwrite(text.secondary("Tracking: "))
				pprint(text.info(target .. "\n"))
				print_pos(target_pos)
			else
				pwrite(text.info("`" .. target .. "`"))
				if tracker:is_online(target) then
					pprint(text.error(" is in another dimension."))
				else
					pprint(text.error(" logged off."))
				end
			end
		else
			local w, h = term.getSize()
			local str = "No players in this dimension"
			term.setCursorPos(math.round((w - #str) / 2), math.round(h / 2))
			pprint(text.error(str))
		end

		if key_wait(3) then
			return
		end
	end
	print_last(text.secondary("Press any key to continue."))
	os.pullEvent("key")
end

ACTIONS.stalk = ACTIONS.track

function ACTIONS.user(tracker, rest)
	user = change_user(tracker, rest)
end

---@param nick string
---@param username string?
local function set_nick(nick, username)
	config.nicks.change(nick, username)
	key_wait(2)
end

function ACTIONS.nick(tracker, rest)
	local subcommands = { "add", "change", "get", "remove", "help" }
	local action
	action, rest = rest_or_prompt(rest, text.secondary("Select a subcommand"), subcommands, colors.gray)

	if action == "help" then
		local ENTRIES = {
			help = {
				name = text.info("Help"),
				desc = pretty.text("Prints this message"),
			},
			add = {
				name = text.info("Add/Change"),
				desc = pretty.concat(pretty.text("Changes the username associated with "), text.setting("`nick`")),
			},
			remove = {
				name = text.error("Remove"),
				desc = pretty.concat(pretty.text("Removes the username associated with "), text.setting("`nick`")),
			},
			get = {
				name = text.info("Get"),
				desc = pretty.concat(pretty.text("Prints the username associated with "), text.setting("`nick`")),
			},
		}
		ENTRIES.change = ENTRIES.add

		---@param name string
		local function print_entry(name)
			local entry = ENTRIES[name]
			pwrite(entry.name)
			pwrite(text.secondary("->"))
			pprint(entry.desc)
			print("")
		end

		if rest then
			local name = split_ws(rest)
			if ENTRIES[name:lower()] then
				print_entry(name:lower())
			else
				pwrite(text.error("Unknown entry: "))
				pprint(text.info("`" .. name .. "`"))
			end
		else
			Clear()

			ENTRIES.change = nil
			for name, _ in pairs(ENTRIES) do
				print_entry(name)
			end
		end

		while not key_wait(1) do
		end
		return
	elseif not table.contains(subcommands, action) then
		if rest then
			local username = split_ws(rest)
			set_nick(action, username)
		else
			set_nick(action, nil)
		end
		return
	end
	if table.contains({ "add", "change" }, action) then
		local nick
		nick, rest = rest_or_prompt(rest, text.setting("Nickname to add/change:"), config.nicks.all, colors.blue)
		local username =
			rest_or_prompt(rest, text.setting("Select a username for this nick:"), tracker:get_online(), colors.blue)
		set_nick(nick, username)
	elseif action == "get" then
		local nick = rest_or_prompt(rest, text.secondary("Select username to get:"), config.nicks.all, colors.gray)
		pwrite(text.setting("`" .. nick .. "`"))
		pwrite(text.primary(" is set to: "))
		pprint(text.info(tostring(config.nicks.get(nick))))
		key_wait(2)
	elseif action == "remove" then
		set_nick(rest_or_prompt(rest, text.setting("Select nick to remove"), config.nicks.all(), colors.red), nil)
	end
end

function ACTIONS.help(_, rest)
	local ENTRIES = {
		help = {
			name = text.info("Help"),
			desc = pretty.text("Prints this message"),
		},
		find = {
			name = text.info("Find"),
			desc = pretty.concat(pretty.text("Finds and prints the coords of "), text.setting("`player`")),
		},
		track = {
			name = text.info("Track"),
			desc = pretty.concat(pretty.text("Continuously finds and prints the coords of "), text.setting("`player`")),
		},
		nearest = {
			name = text.primary("Nearest"),
			desc = pretty.concat(
				pretty.text("Use instead of "),
				text.setting("`player`"),
				pretty.text(" to find the nearest one instead")
			),
		},
		user = {
			name = text.info("User"),
			desc = pretty.concat(pretty.text("Use to change the user of the program to "), text.setting("`player`")),
		},
		nick = {
			name = text.info("Nick"),
			desc = pretty.text("Use to add username shortcuts"),
		},
	}

	---@param name string
	local function print_entry(name)
		local entry = ENTRIES[name]
		pwrite(entry.name)
		pwrite(text.secondary("->"))
		pprint(entry.desc)
		print("")
	end

	if rest then
		local name = split_ws(rest)
		if ENTRIES[name:lower()] then
			print_entry(name:lower())
		else
			pwrite(text.error("Unknown entry: "))
			pprint(text.info("`" .. name .. "`"))
		end
	else
		Clear()

		for name, _ in pairs(ENTRIES) do
			print_entry(name)
		end
	end

	while not key_wait(1) do
	end
end

function ACTIONS.exit() end

local tracker = Tracker:new(user or "")
if not user then
	pprint(text.info("This program has no user."))

	local answer = prompt(
		text.setting("Do you want to set the user for this program: (y/n)"),
		utils.prompt_args({ "Yes", "Y", "No", "N" }),
		colors.blue
	):lower()
	if table.contains({ "yes", "y" }, answer) then
		user = change_user(tracker)
	else
		config.user.change("")
	end
end

local history = {}
repeat
	Clear()
	print_online(tracker)
	local answer = prompt(text.secondary("Choose an action: "), utils.prompt_args(ACTION_NAMES), colors.gray, history)
	local action, rest = split_ws(answer)

	if ACTIONS[action:lower()] then
		table.insert(history, action)
		ACTIONS[action:lower()](tracker, rest)
	else
		ACTIONS.unknown(tracker, rest)
	end
until action:lower() == "exit"

Clear()
local tc = term.getTextColor()
term.setTextColor(colors.red)

write(("Exiting %s"):format(arg[0]))
textutils.slowPrint("...", 5)

term.setTextColor(tc)
