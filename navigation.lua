local Utilities = require('lang/utilities')

local NavigationObject = {}
NavigationObject.__index = NavigationObject

function NavigationObject:constructNavigation(player_obj)
    if not player_obj then return end

    local self = setmetatable({}, NavigationObject)

    self.player = player_obj

    self.route = {}
    self.pause = 0
    self.current_node = 0
    self.navigation_mode = 'loop'
    self.start_time = 0

    self.last_update_time = 0

    self.node_tolerance = 2

    self.recording = false
    self.paused = false

    return self
end

function NavigationObject:setRoute(route_obj)
    if type(route_obj) ~= 'table' then return nil end
    for i,v in pairs(route_obj) do
        if i == 'steps' then self.route = v
        elseif i == 'mode' then self.navigation_mode = v
        elseif i == 'pause' then self.pause = v
        end
    end
end
function NavigationObject:setMode(style)
    if type(style) ~= 'string' then return end
    self.navigation_mode = style
end
function NavigationObject:setLastUpdateTime()
    self.last_update_time = os.clock()
end
function NavigationObject:setModeTolerance(num)
    self.mode_tolerance = tonumber(num)
end
function NavigationObject:setRecording(boolean)
    self.recording = boolean
end
function NavigationObject:recordPosition(single)
    self.player:update()
    local length = #self.route
    local pos1 = {['x'] = self.player.mob.x, ['y'] = self.player.mob.y, ['z'] = self.player.mob.z}
    local pos2 = {['x'] = 0, ['y'] = 0, ['z'] = 0}

    if #self.route > 0 then
        pos2 = self.route[length]
    end

    if self:distanceBetween(pos1, pos2) > 4 then
        self.route[length +1] = {['x'] = Utilities:round(pos1.x, 2), ['y'] = Utilities:round(pos1.y, 2), ['z'] = Utilities:round(pos1.z, 2)}

        if single then notice('At camp mode.') return end
        if length % 5 == 0 then
            notice('At '..length..' nodes.')
        end
    end
end

function NavigationObject:update()
    self.player:update()

    if os.clock() - self.last_update_time < 0.1 then return nil end

    self.current_node = self:determineClosestWaypoint()
    self:setLastUpdateTime()
end

function NavigationObject:determineClosestWaypoint()
	local dist_target = 999
    local closest_index = 1

    for i,v in ipairs(self.route) do
        local z = self:heightDifference(v.z or 0)
        if self:distanceTo(v.x, v.y) < dist_target and z < 10 then
            closest_index = i
            dist_target = self:distanceTo(v.x, v.y)
        end
    end

	return closest_index
end

-- Spatial Helpers
function NavigationObject:heightDifference(z)
    self.player:update()
    local z = z or 10000
    local difference = math.abs(self.player.mob.z - z)
    return difference
end
function NavigationObject:distanceTo(x, y)
	local dx = x - self.player.mob.x
	local dy = y - self.player.mob.y
	return math.sqrt(dx*dx + dy*dy)
end
function NavigationObject:headingTo(x,y)
    if x == nil or y == nil then return end
	local x = x - self.player.mob.x
	local y = y - self.player.mob.y
	local h = math.atan2(x,y)
	return h - 1.5708
end
function NavigationObject:distanceBetween(pos1, pos2)
    if pos1 and pos2 then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        return math.sqrt(dx*dx + dy*dy)
    else
        return 0
    end
end

-- Position Manipulation
function NavigationObject:faceTarget(mob)
	local self_vector = self.player.mob
	if mob then
		local angle = (math.atan2((mob.y - self_vector.y), (mob.x - self_vector.x))*180/math.pi)*-1
		windower.ffxi.turn((angle):radian())
	end
end
function NavigationObject:closeIn(mob_obj)
    if not mob_obj then return end

    self.player:update()
    mob_obj:updateDetails()
    local mob = mob_obj.details
    local player_mob = self.player.mob

	if mob.distance:sqrt() > 2.4 then
        windower.ffxi.run(false)
        self:faceTarget(mob)
        local angle = (math.atan2((mob.y - player_mob.y), (mob.x - player_mob.x))*180/math.pi)*-1
        windower.ffxi.run((angle):radian())
	elseif mob.distance < .5 then
        windower.ffxi.run(false)
        self:faceTarget(mob)
        local angle = (math.atan2((mob.y - player_mob.y), (mob.x - player_mob.x))*180/math.pi)*-1
        windower.ffxi.run((angle+180):radian())
    else
		windower.ffxi.run(false)
	end
end
function NavigationObject:runTrack(StateController)
    if StateController.is_casting == true then return end
    local max_steps = #self.route or 0
    local currentstep = self.current_node
    local pause_time = tonumber(self.pause)

    if currentstep > max_steps and self.start_time == 0 and pause_time > 0 then
        self.start_time = os.clock()
        self.paused = true
    end

    if currentstep > max_steps then
        if self.navigation_mode then
            if self.navigation_mode == 'loop' then
                if self.paused then
                    if not (os.clock() - self.start_time > pause_time) then
                        windower.ffxi.run(false)
                        return
                    end
                end
                currentstep, self.current_node = 1,1
                self.start_time = 0
                self.paused = false
            elseif self.navigation_mode == 'bounce' then
                if self.paused then
                    if not (os.clock() - self.start_time > pause_time) then
                        windower.ffxi.run(false)
                        return
                    end
                end
                self.route = Utilities:reverseThis(self.route)
                currentstep, self.current_node = 1,1
                self.start_time = 0
                self.paused = false
            end
        end
    end

    if self:distanceTo(self.route[currentstep].x, self.route[currentstep].y) < self.node_tolerance then
        if self.navigation_mode and self.navigation_mode == 'camp' then windower.ffxi.run(false) return end
        self.current_node = self.current_node + 1
    else
        self:runTo(self.route[currentstep])
    end
end
function NavigationObject:runTo(target)
    self.player:update()
    local angle = (math.atan2((target.y - self.player.mob.y), (target.x - self.player.mob.x))*180/math.pi)*-1
    windower.ffxi.run((angle):radian())
end

-- Get Settings Ouput
function NavigationObject:getFileContents()
    return {
        ['steps'] = self.route,
        ['pause'] = self.pause,
        ['mode'] = self.navigation_mode
    }
end

return NavigationObject