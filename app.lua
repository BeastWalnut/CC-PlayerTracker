local pretty = require("cc.pretty");
local pprint = pretty.print;
local pwrite = pretty.write;

local Tracker = require("api");
local utils = require("utils");
local text = utils.text;
local prompt = utils.prompt;

utils.load_config();
local user = utils.get_user();

local DIMENSIONS = {
	["minecraft:overworld"] = "Overworld",
	["minecraft:the_nether"] = "The Nether",
	["minecraft:the_end"] = "The End",
};

---@param doc Doc
local function print_last(doc)
	local _, h = term.getSize();
	term.setCursorPos(1, h);
	pwrite(doc)
end

---@param tracker Tracker
---@return string
local function change_user(tracker)
	local online = tracker:get_online();
	local new_user = prompt(
		text.setting("Choose the new user:"),
		online,
		colors.blue
	);

	utils.change_user(new_user);
	tracker:change_user(new_user);
	return new_user;
end

---Pretty prints `postion`.
---@param position FoundPos
local function print_pos(position)
	pwrite(text.primary("X: "));
	pprint(text.info(tostring(position.x)));

	pwrite(text.primary("Y: "));
	pprint(text.info(tostring(position.y)));

	pwrite(text.primary("Z: "));
	pprint(text.info(tostring(position.z)));

	local dimension = DIMENSIONS[position.dimension] or "Unknown";
	pwrite(text.primary("In "));
	pprint(text.info(dimension));

	if position.distance then
		local distance = ("%.1f"):format(position.distance);
		pwrite(text.info(distance));
		pprint(text.primary(" blocks away."));
	end
	if position.direction then
		local direction = math.round(position.direction / 45);

		local c = utils.get_colors();
		local hi = colors.toBlit(c.info); -- High
		local lo = colors.toBlit(colors.gray);             -- Low
		local e = " ";              -- Empty

		---@type string[][]
		local direction_arr = {
			{},
			{},
			{ e,  e,  e, e, e,  e,  e,  e, e, e,  e },
			{ e,  e,  e, e, e,  e,  e,  e, e, e,  e },
			{ e,  lo, e, e, e,  e,  e,  e, e, lo, e },
			{ lo, lo, e, e, e,  e,  e,  e, e, lo, lo },
			{ e,  lo, e, e, e,  e,  e,  e, e, lo, e },
			{ e,  e,  e, e, e,  e,  e,  e, e, e,  e },
			{ e,  e,  e, e, e,  e,  e,  e, e, e,  e },
			{ lo, e,  e, e, lo, lo, lo, e, e, e,  lo },
			{ lo, lo, e, e, e,  lo, e,  e, e, lo, lo },
		};
		if (direction % 2) == 0 then
			direction_arr[1] = { lo, lo, e, e, e, hi, e, e, e, lo, lo };
			direction_arr[2] = { lo, e, e, e, hi, hi, hi, e, e, e, lo };
			direction = direction / 2;
		else
			direction_arr[1] = { lo, lo, e, e, e, lo, e, e, e, hi, hi };
			direction_arr[2] = { lo, e, e, e, lo, lo, lo, e, e, e, hi };
			direction = (direction - 1) / 2;
		end
		if direction < 0 then
			direction = direction + 4;
		end

		local rotated = utils.rotate2d(direction_arr, direction);

		local w, _ = term.getSize();
		local _, y = term.getCursorPos();
		local image = paintutils.parseImage(utils.concat2d(rotated));
		paintutils.drawImage(image, math.round((w - 10) / 2), y);
		term.setBackgroundColor(colors.black);
	end
end

---@param tracker Tracker
local function print_online(tracker)
	local online = tracker:get_online();
	pprint(text.primary("Online players:"));
	if #online == 0 then
		pprint(text.error("\n  You are all alone."));
	else
		for _, name in ipairs(online) do
			pwrite(text.info(" -"));
			pprint(text.info(name));
		end
	end
	print("");
end

local ACTION_NAMES = {
	"find", "track",
	"user",
	"help",
	"exit",

	"locate", "stalk",
};

---@type { [string]: fun(tracker: Tracker) }
local ACTIONS = {};
function ACTIONS.unknown()
	pprint(text.error("Unknown action."));
	pprint(pretty.concat(
		text.info("Use"),
		text.setting(" Help "),
		text.info("to get the known commands.")
	));
	print_last(text.secondary("Press any key to continue."));
	os.pullEvent("key");
end

function ACTIONS.find(tracker)
	local online = tracker:get_online();
	table.insert(online, "Nearest");
	table.insert(online, "nearest");
	local target = prompt(
		text.secondary("Choose player to find:"),
		online,
		colors.red
	);
	local enabled = true;

	if target:lower() == "nearest" then
		target = tracker:get_nearest();
	end

	if not target then
		pprint(text.error("  No players in this dimension."));
		enabled = false;
	elseif not target:find("%S") then
		pprint(text.error("  Idiot forgot to write a name."));
	elseif enabled then
		local target_pos = tracker:relative_find(target);
		if target_pos then
			Clear();
			pwrite(text.info(target));
			pprint(text.secondary(" Is at:\n"));
			print_pos(target_pos);

			print_last(text.secondary("Press any key to continue."))

			os.pullEvent("key");
			return;
		elseif tracker:is_online(target) then
			pwrite(text.info(target));
			pprint(text.error(" is in another dimension."))
		else
			pwrite(text.info(target));
			pprint(text.error(" is offline."))
		end
	end

	print_last(text.secondary("Press any key to continue."))
	local timer_id = os.startTimer(2);
	repeat
		local event, id = os.pullEvent();
		if event == "key" then break; end
	until id == timer_id
end

ACTIONS.locate = ACTIONS.find;

function ACTIONS.track(tracker)
	local online = tracker:get_online();
	table.insert(online, "Nearest");
	table.insert(online, "nearest");
	local target = prompt(
		text.secondary("Choose player to find:"),
		online,
		colors.red
	);
	local enabled = true;

	local find_nearest = target:lower() == "nearest";
	if find_nearest then
		target = tracker:get_nearest();
	end

	if not target then
	elseif not target:find("%S") then
		pprint(text.error("  Idiot forgot to write a name."));
		enabled = false;
	elseif not tracker:is_online(target) then
		pwrite(text.info(target));
		pprint(text.error(" is offline."))
		enabled = false;
	end

	while enabled do
		Clear();
		if find_nearest then
			target = tracker:get_nearest();
		end
		if target then
			local target_pos = tracker:relative_find(target);
			if target_pos then
				pwrite(text.secondary("Tracking: "));
				pprint(text.info(target .. "\n"));
				print_pos(target_pos);
			elseif tracker:is_online(target) then
				pwrite(text.info(target));
				pprint(text.error(" is in another dimension."))
			else
				pwrite(text.info(target));
				pprint(text.error(" logged off."))
			end
		elseif find_nearest then
			pprint(text.error("  No players in this dimension."))
		end

		print_last(text.secondary("Press any key to continue."))
		local timer_id = os.startTimer(3);
		repeat
			local event, id = os.pullEvent();
			if event == "key" then return; end
		until id == timer_id
	end
	print_last(text.secondary("Press any key to continue."))
	os.pullEvent("key");
end

ACTIONS.stalk = ACTIONS.track;

function ACTIONS.user(tracker)
	user = change_user(tracker);
end

function ACTIONS.help()
	Clear();

	local ENTRIES = {
		{
			name = text.info("Help"),
			desc = pretty.text("Prints this message"),
		},
		{
			name = text.info("Find"),
			desc = pretty.concat(
				pretty.text("Finds and prints the coords of "),
				text.setting("`player`")
			),
		},
		{
			name = text.info("Track"),
			desc = pretty.concat(
				pretty.text("Continuously finds and prints the coords of "),
				text.setting("`player`")
			),
		},
		{
			name = text.primary("Nearest"),
			desc = pretty.concat(
				pretty.text("Use instead of "),
				text.setting("`player`"),
				pretty.text(" to find the nearest one instead")
			),
		},
		{
			name = text.info("Nick"),
			desc = text.error("Not yet implemented"),
		},
		{
			name = text.info("User"),
			desc = pretty.concat(
				pretty.text("Use to change the user of the program to "),
				text.setting("`player`")
			),
		},
	};

	for _, entry in ipairs(ENTRIES) do
		pwrite(entry.name);
		pwrite(text.secondary("->"));
		pprint(entry.desc);
		print("")
	end

	print_last(text.secondary("Press any key to continue."));
	os.pullEvent("key");
end

function ACTIONS.exit() end

---@type Tracker
local tracker;
if not user then
	local answers = utils.promt_args({
		"yes", "y",
		"no", "n"
	});
	pprint(text.info("This program has no user."));
	local answer = prompt(text.setting("Do you want to set the user for this program: (y/n)"), answers, colors.blue);
	tracker = Tracker:new("");
	if table.contains({ "yes", "y" }, answer:lower()) then
		user = change_user(tracker);
	else
		utils.change_user("");
	end
else
	tracker = Tracker:new(user);
end

local history = {};
repeat
	Clear();
	print_online(tracker);
	local action = string.lower(
		prompt(
			text.secondary("Choose an action: "),
			utils.promt_args(ACTION_NAMES),
			colors.gray,
			history
		)
	);

	if ACTIONS[action] then
		table.insert(history, action);
		ACTIONS[action](tracker);
	else
		ACTIONS.unknown(tracker);
	end
until action == "exit";

Clear();
local c = term.getTextColor();
term.setTextColor(colors.red);

write(("Exiting %s"):format(arg[0]));
textutils.slowPrint("...", 5);

term.setTextColor(c);
