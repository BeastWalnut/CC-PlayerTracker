local utils = require("utils");

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

---Returns a new instance of <Tracker>
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
function Tracker:change_host(player)
	self.user = player;
end

---Returns true if <player> is online.
---@param player string
---@return boolean
function Tracker:is_online(player)
	return utils.contains(self.finder.getOnlinePlayers(), player);
end

---Returns the direction of the given coordinates
---@param user PlayerPos
---@param x number
---@param z number
---@return number yaw
function Tracker.get_direction(user, x, z)
	local abs_yaw = math.atan2(x, -z) * (180 / math.pi);
	local yaw = abs_yaw - user.yaw;

	if yaw > 180 then yaw = yaw - 180; end

	return yaw;
end

---Returns the distance of the given coordinates
---@param user PlayerPos
---@param target PlayerPos
---@return number dist
---@return number delta-x
---@return number delta-z
function Tracker.get_distance(user, target)
	local delta_x = user.x - target.x;
	local delta_z = user.z - target.z;
	local dist = math.sqrt((delta_z ^ 2) + (delta_x ^ 2));

	return dist, delta_x, delta_z;
end

---Gets the coordinates of <player>
---@param player string
---@return PlayerPos | nil
function Tracker:find(player)
	return self.finder.getPlayerPos(player)
end

---Gets the relative coordinates of <player>
---@param player string
---@return FoundPos | nil
function Tracker:relative_find(player)
	local target = self:find(player);
	if not target then return; end

	---@type FoundPos
	local result = {
		x = target.x,
		y = target.y,
		z = target.z,
		dimension = target.dimension,
	}

	local user = self:find(self.user);
	if not user then return result; end

	if user.dimension == target.dimension then
		local dist, delta_x, delta_z = self.get_distance(user, target);
		result.distance = math.ceil(dist);
		result.direction = self.get_direction(user, delta_x, delta_z);
	end

	return result;
end

return Tracker;
