local _utils = require("utils");

---@class FoundPos
---@field x number
---@field y number
---@field z number
---@field dimension string
---@field direction? number
---@field distance? number
---@field pitch? number

---@class Tracker
---@field user string
---@field finder PlayerDetector
local Tracker = {};
Tracker.__index = Tracker;

---Returns a new instance of `Tracker`.
---@param user string
---@return Tracker
function Tracker:new(user)
	if type(user) ~= "string" then
		error("User must be a string");
	end

	---@type PlayerDetector
	local finder = peripheral.find("playerDetector");
	if not finder then error("Player detector not found"); end

	return setmetatable({
		user = user,
		finder = finder
	}, self);
end

---Changes the user for the tracker
---@param player string
function Tracker:change_user(player)
	self.user = player;
end

---Returns true if `player` is online.
---@param player string
---@return boolean
function Tracker:is_online(player)
	return table.contains(self.finder.getOnlinePlayers(), player);
end

---Returns a list of online players excluding the user
---@return string[]
function Tracker:get_online()
	local online = {};
	for _, player in ipairs(self.finder.getOnlinePlayers()) do
		if player ~= self.user then
			table.insert(online, player);
		end
	end
	return online;
end

---Returns the direction of the given coordinates
---@param user PlayerPos
---@param x number
---@param z number
---@return number yaw
function Tracker.get_direction(user, x, z)
	local abs_yaw = math.atan2(x, -z) * (180 / math.pi);
	local yaw = abs_yaw - user.yaw;

	if yaw > 180 then
		return yaw - 180;
	end

	return yaw;
end

---Returns the distance of the given coordinates
---@param user PlayerPos
---@param target PlayerPos
---@return number? dist
---@return number? delta-x 
---@return number? delta-z
function Tracker.get_distance(user, target)
	if user.dimension ~= target.dimension then return; end

	local delta_x = user.x - target.x;
	local delta_z = user.z - target.z;
	local dist = math.sqrt((delta_z ^ 2) + (delta_x ^ 2));

	return dist, delta_x, delta_z;
end

---Gets the coordinates of `player`.
---@param player string
---@return PlayerPos | nil
function Tracker:find(player)
	local player_pos = self.finder.getPlayerPos(player);
	if player_pos.dimension then
		return player_pos;
	else
		return;
	end
end

---Get the coordinates of `user`
---@return PlayerPos | nil
function Tracker:user_pos()
	if self.user == "gps" then
		return Todo("Get position from gps");
	end
	return self:find(self.user);
end

---Get the nearest player to `user`
---@return string
function Tracker:get_nearest()
	local user_pos = self:user_pos();
	local online = self:get_online();

	local nearest = online[1];
	if not user_pos then return nearest; end

	local min_distance = math.huge;
	for _, player in ipairs(online) do
		local player_pos = self:find(player);
		if player_pos then
			local dist, _, _ = self.get_distance(user_pos, player_pos);
			if dist and dist < min_distance then
				min_distance = dist;
				nearest = player;
			end
		end
	end
	return nearest;
end

---Gets the relative coordinates of `target`.
---@param target string
---@return FoundPos | nil
function Tracker:relative_find(target)
	local target_pos = self:find(target);
	if not target_pos then return; end

	---@type FoundPos
	local result = {
		x = target_pos.x,
		y = target_pos.y,
		z = target_pos.z,
		dimension = target_pos.dimension,
	}

	local user = self:user_pos();
	if not user then return result; end

	local dist, delta_x, delta_z = self.get_distance(user, target_pos);
	if dist then
		result.distance = dist;
		---@diagnostic disable-next-line: param-type-mismatch
		result.direction = self.get_direction(user, delta_x, delta_z);
	end

	return result;
end

return Tracker;
