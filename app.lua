local pretty = require("cc.pretty");

local Tracker = require("api");
local utils = require("utils");
local text = utils.text;
local prompt = utils.prompt;

local DIMENSIONS = {
	["minecraft:overworld"] = "Overworld",
	["minecraft:the_nether"] = "The Nether",
	["minecraft:the_end"] = "The End",
};

---Pretty prints `postion`.
---@param position FoundPos
local function print_pos(position)
	pretty.write(text.primary("X: "));
	pretty.print(text.info(tostring(position.x)));

	pretty.write(text.primary("Y: "));
	pretty.print(text.info(tostring(position.y)));

	pretty.write(text.primary("Z: "));
	pretty.print(text.info(tostring(position.z)));

	local dimension = DIMENSIONS[position.dimension] or "Unknown";
	pretty.write(text.primary("In "));
	pretty.print(text.info(dimension));

	if position.distance then
		local distance = ("%.1f"):format(position.distance);
		pretty.write(text.info(distance));
		pretty.print(text.primary(" blocks away."));
	end
	if position.direction then
		--TODO: Todo("Print `direction`");
	end
end

utils.load_config();
local user = utils.get_user();
local tracker = Tracker:new(user);

local ACTIONS = {};
function ACTIONS.find()
	local target = prompt(
		text.secondary("Choose player to find:"),
		tracker:get_online(),
		colors.red
	);

	if not target:find("%S") then
		pretty.print(text.error("  Idiot forgot to write a name."));
		return;
	end

	local target_pos = tracker:relative_find(target);
	if target_pos then
		shell.run("clear");
		pretty.write(text.info(target));
		pretty.print(text.secondary(" Is at:"));
		print_pos(target_pos);
	elseif tracker:is_online(target) then
		Todo("`target` is in another dimension");
	else
		Todo("`target` is offline");
	end
end

ACTIONS.locate = ACTIONS.find;

function ACTIONS.track()
	local target = Todo("Ask for user to find");
	while true do
		local target_pos = tracker:relative_find(target);
		if target_pos then
			Todo("Print: Finding `target`")
			print_pos(target_pos);
		elseif tracker:is_online(target) then
			Todo("`target` is in another dimension");
		else
			Todo("`target` is offline");
		end
		Todo("check exit cond");
	end
end

ACTIONS.stalk = ACTIONS.track;

local ACTION_NAMES = {
	"find", "locate",
	"track", "stalk",
	"help", "exit"
};

function ACTIONS.help()
	Todo("Print help str");
end

function ACTIONS.exit()
	shell.run("clear");
	local c = term.getTextColor();
	term.setTextColor(colors.red);

	write(("Exiting %s"):format(arg[0]));
	textutils.slowPrint("...", 5);

	term.setTextColor(c);
	error("", 0);
end

local function print_online()
	local online = tracker:get_online();
	pretty.print(text.primary("Online players:"));
	if #online == 0 then
		pretty.print(text.error("\n  You are all alone."));
	else
		for _, name in ipairs(online) do
			pretty.write(text.info(" -"));
			pretty.print(text.info(name));
		end
	end
	print("");
end

local history = {};

while true do
	shell.run("clear");
	print_online();
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
		ACTIONS[action]();
	else
		Todo("Unknown action (maybe print or suggest `help`)");
	end
	Todo("check exit cond");
end
