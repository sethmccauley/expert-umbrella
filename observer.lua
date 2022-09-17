local MobObject = require('lang/mobobject')
local PlayerObject = require('lang/playerobject')
local Utilities = require('lang/utilities')
local packets = require('packets')

local ObserverObject = {}
ObserverObject.__index = ObserverObject

function ObserverObject:constructObserver(player_obj)
    if not player_obj then return end

    local self = setmetatable({}, ObserverObject)

    self.player = player_obj
    self.claim_ids = self:setPartyClaimIds()
    self.last_target_update_time = 0
    self.party = self:setPartyMembers()

    self.aggro = T{}
    self.targets = T{}
    self.target_list = T{}

    self.ignore_list = T{}
    self.scan_range = 50

    self.nearest_target = nil
    self.mob_to_fight = T{}
    self.target_update_time = 0

    self.last_atk_pkt = 0
    self.last_atk_pkt_issued = nil
    self.last_target_pkt = 0
    self.last_target_pkt_issued = nil
    self.last_switch_pkt = 0

    self.is_casting = nil
    self.is_busy = false
    self.last_busy_start = 0
    self.last_engage_time = 0
    self.force_unbusy_time = 0.5

    return self
end

function ObserverObject:setPartyClaimIds()
    local party_table = windower.ffxi.get_party()
    local party_ids = T{}

    if party_table == nil then self.claim_ids = T{} return end

    for _,member in pairs(party_table) do
        if type(member) == 'table' and member.mob then
            party_ids:append(member.mob.id)
            if member.mob.pet_index then
                local pet = windower.ffxi.get_mob_by_index(member.mob.pet_index) or nil
                if pet then
                    party_ids:append(pet.id)
                end
            end
        end
    end

    self.claim_ids = party_ids
    return party_ids
end
function ObserverObject:setPartyMembers()
    local party_table = windower.ffxi.get_party()
    local party = T{}

    if party_table == nil then self.party = T{} return end

    for _,member in pairs(party_table) do
        if type(member) == 'table' and member.mob then
            party:append(member)
            if member.mob.pet_index then
                local pet = windower.ffxi.get_mob_by_index(member.mob.pet_index) or nil
                if pet then
                    party:append(member)
                end
            end
        end
    end

    self.party = party
    return party
end
function ObserverObject:setScanRange(value)
    if not value or value < 0 or value > 50 then return nil end
    self.scan_range = value
end
function ObserverObject:setAtkPkt()
    self.last_atk_pkt = os.clock()
end
function ObserverObject:setTargetPkt()
    self.last_target_pkt = os.clock()
end
function ObserverObject:setTargetList(new_target_list)
    if type(new_target_list) ~= 'table' then return end

    for i,v in pairs(new_target_list) do
        if i == 'names' then self.target_list = v
        elseif i == 'ignore' then self.ignore_list = v
        elseif i == 'range' then self.scan_range = v
        end
    end
end
function ObserverObject:setMobToFight(target_mob)
    -- notice('Set Mob To Fight: '..target_mob.name..' '..target_mob.index)
    self.mob_to_fight = target_mob
end
function ObserverObject:setLastSwitchRequest()
    self.last_switch_pkt = os.clock()
end
function ObserverObject:timeSinceLastSwitch()
    return (os.clock() - self.last_switch_pkt)
end
function ObserverObject:setLastEngageTime()
    self.last_engage_time = 0
end
function ObserverObject:timeSinceLastEngage()
    return (os.clock() - self.last_engage_time)
end

function ObserverObject:updateMobs(navigation_obj)
    if not self.player then return nil end

    self.player:update()

    if os.clock() - self.last_target_update_time < 0.1 then return nil end

    self.targets = self:findTargets(self.target_list, navigation_obj)
end
function ObserverObject:findTargets(mob_table_list, navigation_obj)

    if next(self.target_list) == nil then return T{} end

    local builder_marray = mob_table_list or nil
    local target_array = T{}
    local nodes = navigation_obj and navigation_obj.nodes or T{}
    if not builder_marray then return end

    for i,v in pairs(builder_marray) do
        if i == 'name' then
            if table.length(v) > 0 then
                for _,val in pairs(v) do
                    local mobs = self:getMArray(val)
                    for ke,va in pairs(mobs) do
                        local mob = MobObject:constructMob(va)
                        if not target_array[ke] and mob and mob:isValidTarget(self.player.mob) and self:isCloseEnough(mob, self.player.mob, nodes, self.scan_range) and mob:isAllianceClaimed(self.claim_ids) then
                            target_array[ke] = {
                                ['name'] = mob.details.name,
                                ['index'] = mob.index,
                                ['obj'] = mob
                            }
                        end
                    end
                end
            end
        elseif i == 'hex' then
            if table.length(v) > 0 then
                for _,val in pairs(v) do
                    local index = tonumber(val, 16)
                    local mob = MobObject:constructMob(index)
                    if not target_array[index] and mob and mob:isValidTarget(self.player.mob) and self:isCloseEnough(mob, self.player.mob, nodes, self.scan_range) and mob:isAllianceClaimed(self.claim_ids) then
                        target_array[mob.index] = {
                            ['name'] = mob.details.name,
                            ['index'] = mob.index,
                            ['obj'] = mob,
                        }
                    end
                end
            end
        end
    end

    return target_array
end
function ObserverObject:pickNearest(mob_table)
	local dist_target = 999
    local closest_index = 0
	local marray = mob_table or self.targets or self:getMArray()

	for k,v in pairs(marray) do
        local mob = {}
        if v.details then mob = v.details else mob = windower.ffxi.get_mob_by_index(v.index) end
		if math.sqrt(mob['distance']) < dist_target then
			closest_index = k
			dist_target = math.sqrt(mob['distance'])
		end
	end

	return marray[closest_index] or T{}
end
function ObserverObject:hasDeclaredTarget()
    if self.mob_to_fight and self.mob_to_fight.obj and self.mob_to_fight.obj:isValidTarget(self.player.mob) then
        return true
    end
    return false
end

function ObserverObject:determineTarget(Actions, StateController)
    self.player:update()

    self:validateAggroTable()
    self:validateTargetsTable()

    local hasCurrentTarget = self:hasCurrentTarget()

    -- No Target
    if hasCurrentTarget == 0 or next(self.mob_to_fight) == nil then
        if next(self.targets) == nil then
            self:setMobToFight(self:pickNearest(self.aggro))
        else
            self:setMobToFight(self:pickNearest(self.targets))
        end
    else
        -- Have Target
        -- Is my target my mob_to_fight and is it still valid?
        if self.mob_to_fight and self.mob_to_fight.index and self.mob_to_fight.index == hasCurrentTarget then
            -- notice(self.mob_to_fight.index..' '..hasCurrentTarget)
            -- notice('Claimed? '..tostring(self.mob_to_fight.obj:isAllianceClaimed(self.claim_ids)))
            -- Is it still a valid target?
            if self.mob_to_fight.obj:isValidTarget(self.player.mob) and self.mob_to_fight.obj:isAllianceClaimed(self.claim_ids) then
                -- It's Still valid!
                return
            else
                -- My Mob to fight is my current Target but it is now not valid.
                notice('Setting mob to fight to empty.')
                self:setMobToFight(T{})
            end
        elseif self.mob_to_fight and self.mob_to_fight.index and self.mob_to_fight.index ~= hasCurrentTarget then
            -- My current target is not my mob_to_fight
            if self.mob_to_fight.obj:isValidTarget(self.player.mob) and self.mob_to_fight.obj:isAllianceClaimed(self.claim_ids) then
                -- My mob_to_fight is still valid, why do I have a different current target?
                -- Need to send a switch target command
                if (os.clock() - self.last_switch_pkt) > 4 then
                    notice('Time since last switch invoked: '..(os.clock() - self.last_switch_pkt))
                    notice('Switch Target To: '..self.mob_to_fight.index)
                    self:setLastSwitchRequest()
                    Actions:switchTarget(self.mob_to_fight.obj)
                end
            else
                -- My mob_to_fight is not valid, I have a different target, let's change targets
                local possible_target = MobObject:constructMob(hasCurrentTarget)
                if possible_target and possible_target:isValidTarget(self.player.mob) and possible_target:isAllianceClaimed(self.claim_ids) then
                    notice('Not Valid, pls change')
                    self:setMobToFight(possible_target)
                end
            end
        end
    end
end
function ObserverObject:hasCurrentTarget()
    local target = windower.ffxi.get_mob_by_target('t')
    if target == nil or (target and (target.id == self.player.id or target.spawn_type ~= 16)) then
        return 0
    end
    return target.index
end
function ObserverObject:getCurrentTargetID()
    return self.mob_to_fight and self.mob_to_fight.obj and self.mob_to_fight.obj.id or nil
end
function ObserverObject:clearMobToFight()
    self.mob_to_fight = T{}
end

function ObserverObject:updateParty()
    -- Update alliance entries here as well
    self.claim_ids = self:setPartyClaimIds()
end

function ObserverObject:addToAggro(id)
    local mob = windower.ffxi.get_mob_by_id(id) or nil
    if not mob then return end
    local index = tonumber(mob.id, 16)

    if Utilities:arrayContains(self.ignore_list, mob.name) or Utilities:arrayContains(self.ignore_list, mob.index) then return end
    if mob.claim_id ~= 0 and not Utilities:arrayContains(self.claim_ids, mob.claim_id) then return end

    if not table.containskey(self.aggro, mob.index) then
        self.aggro[mob.index] = {
            ['name'] = mob.name,
            ['index'] = mob.index,
            ['obj'] = MobObject:constructMob(mob)
        }
    end
end
function ObserverObject:timeSinceLastTarget()
    return os.clock() - self.last_target_pkt
end
function ObserverObject:timeSinceLastAttack()
    return os.clock() - self.last_atk_pkt
end
function ObserverObject:printQT()
    if not self.targets then return nil end

    local printString = ''
    for i,v in pairs(self.targets) do
        printString = printString..'('..i..' '..v.name..') '
    end
    notice(printString)
end

--[[
    Collects all mobs loaded into memory and optionally trims them down based on the name or names given

    names = 'Locus Colibri'
        or
    names = {
        [1] = 'Locus Colibri',
        [2] = 'Locus Wivre'
    }

]]
function ObserverObject:getMArray(names)
    local marray = windower.ffxi.get_mob_array()
    local target_names = T{}

    if type(names) == 'table' then 
        for i,v in pairs(names) do
            target_names[i] = {['name'] = v:lower()}
        end
    elseif type(names) == 'string' then 
        target_names = T{[1] = {['name'] = names and names:lower() or nil}} 
    end

    for i,v in pairs(marray) do
        if v.id == 0 or v.index == 0 or v.status == 3 then
            marray[i] = nil
        else
            marray[i] = v
        end
    end

    if names then
        for i,v in pairs(marray) do
            local delete = false
            if not target_names:with('name', v.name:lower()) then
                delete = true
            end
            if delete then
                marray[i] = nil
            end
        end
    end

    return marray
end
function ObserverObject:differenceZ(mob_obj, player_mob)
    if not mob_obj or not player_mob then return nil end

    local difference = 0
    difference = math.abs(player.z - mob_obj.z)

    return difference
end

function ObserverObject:validateTargetsTable()
    for i,v in pairs(self.targets) do
        if v and not v.obj:isValidTarget(self.player.mob) or not v.obj:isAllianceClaimed(self.claim_ids) then
            self.targets[i] = nil
        end
    end
end
function ObserverObject:validateAggroTable()
    for i,v in pairs(self.aggro) do
        if v and not v.obj:isValidTarget(self.player.mob) or not v.obj:isAllianceClaimed(self.claim_ids) then
            notice('removed from aggro '..v.obj.index)
            self.aggro[i] = nil
        end
    end
end

function ObserverObject:isCloseEnough(mob_obj, player_mob, path_nodes, range_limit)
    if not mob_obj or not player_mob then return nil end

    local nodes = {}
    if table.length(path_nodes) > 0 then
        nodes = path_nodes
    else
        nodes = {player_mob}
    end

    local dist_target = 999
    local closest_index = 0

    for i,v in ipairs(nodes) do
        if self:distanceBetween(mob_obj.details, v) < dist_target then
            closest_index = i
            dist_target = self:distanceBetween(mob_obj.details, v)
        end
    end
    
    if dist_target < range_limit then
        return true
    end

    return false
end
function ObserverObject:distanceBetween(pos1, pos2)
    if pos1 and pos2 then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        return math.sqrt(dx*dx + dy*dy)
    else
        return 0
    end
end
function ObserverObject:setBusy()
    self.is_busy = true
    self.last_busy_start = os.clock()
end
function ObserverObject:setCasting()
    self.is_casting = true
end
function ObserverObject:checkUnbusy()
    if (os.clock() - self.last_busy_start) > 4 and self.is_busy then
        self:forceUnbusy()
    end
end
function ObserverObject:forceUnbusy()
    self.is_busy = false
    self.is_casting = false
end
function ObserverObject:canFight(mob_obj)
    self:setPartyClaimIds()
    self.player:update()
    mob_obj:updateValidTarget(self.player.mob)

    if mob_obj.valid_target and mob_obj:isAllianceClaimed(self.claim_ids) then
        return true
    end

    return false
end
function ObserverObject:notifyMobDeath(id,data,modified,injected,blocked, Actions)
    local p = packets.parse('incoming',data)
    local target_id = p['Target'] --data:unpack('I',0x09)
    local player_id = p['Actor'] 
    local target_index = p['Target Index']
    local message_id = p['Message']
    local party_ids = self:setPartyClaimIds()

    if message_id == 6 or message_id == 20 then -- Dies or Falls

        for i,v in pairs(self.targets) do
            if v.index == target_index then self.targets[i] = nil end
        end
        for i,v in pairs(self.aggro) do
            if v.index == target_index then self.aggro[i] = nil end
        end

        if self.mob_to_fight and self.mob_to_fight.index == target_index then
            self.mob_to_fight = T{}
            coroutine.schedule(function() Actions:emptyOncePerCombat() end, 1)
        end
        coroutine.schedule(function() self:forceUnbusy() end , 2)
    end
end
function ObserverObject:watchResonation(id,data,modified,injected,blocked)
    local p = packets.parse('incoming', data)
    if self:getCurrentTargetID() == p['Target 1 ID'] then
        Utilities:determineResonation(p, self.mob_to_fight.obj)
    end
end

function ObserverObject:inParty(name)
	local name = name or 'None'
	local party = windower.ffxi.get_party()

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() then
                return true
            end
        end
    end
	return false
end
function ObserverObject:playersTarget(name)
    if name == nil then return nil end
	local name = name
	local party = windower.ffxi.get_party()

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() then
                if member and member.mob and member.mob ~= nil and member.mob.target_index ~= 0 or member.mob.target_index ~= nil then
                    return windower.ffxi.get_mob_by_index(member.mob.target_index) and windower.ffxi.get_mob_by_index(member.mob.target_index).index
                end
            end
        end
    end
	return 0
end
function ObserverObject:playersStatus(name)
    if name == nil then return nil end
	local name = name
	local party = windower.ffxi.get_party()

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() then
                if member.mob and member.mob ~= nil and member.mob.status then
                    return member.mob.status
                end
            end
        end
    end
	return nil
end
function ObserverObject:playersPos(name)
    if name == nil then return nil end
	local name = name
	local party = windower.ffxi.get_party()

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() then
                if member.mob and member.mob ~= nil then
                    return member.mob
                end
            end
        end
    end
	return nil
end
function ObserverObject:inCity()
    local world = windower.ffxi.get_info()
    if Utilities:arrayContains(Utilities._cities, Utilities.res.zones[world.zone].en) then
        return true
    end
    return false
end
function ObserverObject:getFileContents()
    return {
        ["range"]= self.scan_range,
        ["names"]= self.target_list,
        ["ignore"]= self.ignore_list
    }
end

return ObserverObject