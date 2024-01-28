local Tracker = require("api");
local USER = "BeastWalnut";
local TARGET = "Beast";
local DIRECTIONS = {
	[-4] = "Back",
	[-3] = "Back Left",
	[-2] = "Left",
	[-1] = "Front Left",
	[0] = "Front",
	[1] = "Front Right",
	[2] = "Right",
	[3] = "Back right",
	[4] = "Back",
};

term.clear();
term.setCursorPos(1, 1);

if type(arg[1]) == "string" then
	TARGET = arg[1];
end

local tracker = Tracker:new(USER);
local is_online = tracker:is_online(USER);
if not is_online then
	print("User:" .. USER .. " Is not online.");
	return;
end

local online_players = tracker:get_online();
if #online_players == 0 then
	print("You are all alone.");
	return;
else
	print("Online players:")
	for _, player in ipairs(online_players) do
		print(" -" .. player);
	end
end

print("Finding: " .. TARGET);
local position = tracker:relative_find(TARGET);
if (not position) and (not tracker:is_online(TARGET)) then
	print("Target: " .. TARGET .. " Is not online.");
	return;
end

if not position then
	print(TARGET .. " Is in another dimension.");
	return;
end

print("X: " .. position.x);
print("Y: " .. position.y);
print("z: " .. position.z);

if position.distance then
	print("Distance: " .. math.ceil(position.distance));
end
if position.direction then
	local direction = DIRECTIONS[math.round(position.direction / 45)] or "Error";
	print("Direction: " .. direction);

	print("Angle: " .. math.floor(position.direction) .. " degrees");
end
