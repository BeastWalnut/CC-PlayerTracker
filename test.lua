local Tracker = require("api");
local USER = "BeastWalnut";
local TARGET = "Beast";

if type(arg[1]) == "string" then
	TARGET = arg[1]
end

local tracker = Tracker:new(USER);
local is_online = tracker:is_online(USER);
if not is_online then
	print("User:" .. USER .. " Is not online.");
	return;
end

local position = tracker:relative_find(TARGET);
if (not position) and (not tracker:is_online(TARGET)) then
	print("Target: " .. TARGET .. " Is not online.")
	return;
end

if not position then
	print(TARGET .. " Is in another dimension.")
	return;
end

print("X: " .. position.x);
print("Y: " .. position.y);
print("z: " .. position.z);

if position.distance then
	print("Distance: " .. position.distance);
end
if position.direction then
	print("Direction: " .. position.direction .. " degrees")
end
