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
    self.mtf_update_time = 0
    self.mtf_claim_start = 0

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

    self.attack_round_calc = 0
    self.last_attack_swing = 0

    self.server_offset = self:serverOffset()

    self.ally_dependency = nil

    self.combat_positioning = T{}

    self.sparks = 0
    self.accolades = 0
    self.conquest = {
        ['s'] = 0,
        ['b'] = 0,
        ['w'] = 0,
    }
    self.merits = 0
    self.gil = 0

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
function ObserverObject:setAggroEmpty()
    self.aggro = T{}
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
    if next(target_mob) ~= nil then
        notice(Utilities:printTime(os.time())..' Set Mob To Fight: '..target_mob.name ..' '..target_mob.index)
    else
        notice(Utilities:printTime(os.time())..' Set Mob To Fight: empty')
    end
    if os.clock() - self.mtf_update_time < 0.75 then return nil end

    self.mtf_update_time = os.clock()
    self.mob_to_fight = target_mob
end
function ObserverObject:setLastSwitchRequest()
    self.last_switch_pkt = os.clock()
end
function ObserverObject:timeSinceLastSwitch()
    return (os.clock() - self.last_switch_pkt)
end
function ObserverObject:setLastEngageTime()
    self.last_engage_time = os.clock()
end
function ObserverObject:timeSinceLastEngage()
    return (os.clock() - self.last_engage_time)
end
function ObserverObject:setLastAttackRoundTime()
    self.last_attack_swing = os.clock()
end
function ObserverObject:timeSinceLastAttackRound()
    return (os.clock() - self.last_attack_swing)
end
function ObserverObject:setAttackRoundCalcTime()
    self.attack_round_calc = self:timeSinceLastAttackRound()
    if self.attack_round_calc > 10 then
        self.attack_round_calc = 0
    end
end
function ObserverObject:setCombatPosition(x, y)
    if x == nil and y == nil then
        self.combat_positioning = T{}
        return
    end
    self.combat_positioning = T{['x'] = x, ['y'] = y}
end

function ObserverObject:setCurrency(currency_type, value)
    if type(currency_type) == 'table' then
        if currency_type and currency_type.name == 'conquest' and currency_type.sub and value then
            self.conquest[currency_type.sub] = value
        end
        return
    end
    local allowed = T{'accolades', 'gil', 'merits', 'sparks'}
    if allowed:contains(currency_type) then
        self[currency_type] = value
    end
end

function ObserverObject:updateMobs(navigation_obj)
    if not self.player then return nil end

    self.player:update()

    if os.clock() - self.last_target_update_time < 0.1 then return nil end

    self:findTargets(self.target_list, navigation_obj)
end
function ObserverObject:findTargets(mob_table_list, navigation_obj)

    if next(self.target_list) == nil then return T{} end

    local builder_marray = mob_table_list or nil
    local nodes = navigation_obj and navigation_obj.nodes or T{}
    if not builder_marray then return end

    for i,v in pairs(builder_marray) do
        if i == 'name' then
            if table.length(v) > 0 then
                for _,val in pairs(v) do
                    local mobs = self:getMArray(val)
                    for ke,va in pairs(mobs) do
                        local mob = MobObject:constructMob(va)
                        if self.targets[ke] and self.targets[ke]['obj'] then
                            self.targets[ke]['obj']:updateDetails()
                            if self.targets[ke]['obj']:isTrulyClaimed(self.claim_ids) and self.targets[ke]['obj'].claimed_at_time == 0 then
                                self.targets[ke]['obj'].claimed_at_time = os.clock()
                            end
                        end
                        if not self.targets[ke] and mob and mob:isValidTarget(self.player.mob) and self:isCloseEnough(mob, self.player.mob, nodes, self.scan_range) and mob:isAllianceClaimed(self.claim_ids) then
                            self.targets[ke] = {
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
                    if self.targets[mob.index] and self.targets[mob.index]['obj'] then
                        self.targets[mob.index]['obj']:updateDetails()
                        if self.targets[mob.index]['obj']:isTrulyClaimed(self.claim_ids) and self.targets[mob.index]['obj'].claimed_at_time == 0 then
                            self.targets[mob.index]['obj'].claimed_at_time = os.clock()
                        end
                    end
                    if not self.targets[mob.index] and mob and mob:isValidTarget(self.player.mob) and self:isCloseEnough(mob, self.player.mob, nodes, self.scan_range) and mob:isAllianceClaimed(self.claim_ids) then
                        self.targets[mob.index] = {
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
    local player = self.player
    player:update()

	for k,v in pairs(marray) do
        local mob = {}
        if v.details then mob = v.details else mob = windower.ffxi.get_mob_by_index(v.index) end
        local distance_to = self:distanceBetween(player.mob, mob)
		if distance_to < dist_target then
			closest_index = k
			dist_target = distance_to
		end
	end

	return marray[closest_index] or T{}
end
function ObserverObject:hasDeclaredTarget()
    if self.mob_to_fight and self.mob_to_fight.obj and self.mob_to_fight.obj.isValidTarget and self.mob_to_fight.obj:isValidTarget(self.player.mob) then
        return true
    end
    return false
end

function ObserverObject:determineTarget(Actions, StateController)
    self.player:update()

    self:validateAggroTable()
    self:validateTargetsTable()
    self:validateMobToFight()

    if self:timeSinceLastAttackPkt() < 4 then return end

    local hasCurrentTarget = self:hasCurrentTarget()
    -- Slave Targeting Considerations
    if StateController.role == 'slave' then
        if StateController.assist == nil then return end
        if (os.clock() - StateController.last_assist_check) < 0.5 then return end

        if self:inParty(StateController.assist) then
            hasCurrentTarget = self:playersTarget(StateController.assist)
            local assist_status = self:playersStatus(StateController.assist)

            if hasCurrentTarget and hasCurrentTarget ~= 0 then
                if assist_status == 1 then
                    local potential_target = MobObject:constructMob(hasCurrentTarget)
                    if potential_target:isValidTarget(self.player.mob) and potential_target:isAllianceClaimed(self.claim_ids) then
                        if not Utilities:arrayContains(self.aggro, hasCurrentTarget) then
                            -- notice(Utilities:printTime()..' Master found target '..hasCurrentTarget..' adding to aggro table.')
                            self:addToAggro(potential_target.id)
                        end
                        if self.mob_to_fight and self.mob_to_fight.obj then
                            if self.mob_to_fight.obj.claimed_at_time and self.mob_to_fight.obj.claimed_at_time == 0 then
                                self.mob_to_fight.obj.claimed_at_time = os.clock()
                            end
                        end
                    else
                        if Utilities:arrayContains(self.aggro, potential_target.id) then
                            for i,v in pairs(self.aggro) do
                                if v.index == potential_target.index then self.aggro[i] = nil end
                            end
                        end
                        if self.mob_to_fight and self.mob_to_fight.index == potential_target.index then
                            -- notice(Utilities:printTime()..' clearing Mob to fight due to invalid mob')
                            self:setMobToFight(T{})
                        end
                    end
                else
                    if next(self.aggro) ~= nil then
                        -- notice(Utilities:printTime()..' clearing aggro as assist target is idle')
                        self:setAggroEmpty()
                    end
                    if next(self.mob_to_fight) ~= nil then
                        -- notice(Utilities:printTime()..' clearing mob to fight as assist target is idle')
                        self:setMobToFight(T{})
                    end
                end
            end
        end
        StateController:setLastAssistCheckTime()
    end

    -- MTF is Empty
    if next(self.mob_to_fight) == nil then
        if hasCurrentTarget ~= 0 then
            if self.player.status == 1 then
                local possible_target = MobObject:constructMob(hasCurrentTarget)
                if possible_target and possible_target:isValidTarget(self.player.mob) and possible_target:isAllianceClaimed(self.claim_ids) then
                    -- notice(Utilities:printTime()..' setting mob to fight NIL MTF, VALID CT, Engaged')
                    self:setMobToFight(T{['name'] = possible_target.name, ['index'] = possible_target.index, ['obj'] = possible_target})
                    Actions:emptyOncePerTables()
                    return
                end
            end
        end

        if next(self.targets) == nil then
            if next(self.aggro) ~= nil then
                -- notice(Utilities:printTime()..' setting mob to fight from nearest aggro table')
                self:setMobToFight(self:pickNearest(self.aggro))
                Actions:emptyOncePerTables()
            end
        else
            -- notice(Utilities:printTime()..' setting mob to fight from nearest target table')
            self:setMobToFight(self:pickNearest(self.targets))
            Actions:emptyOncePerTables()
        end
    else
    -- MTF is Populated, Check for current Target
        if hasCurrentTarget ~= 0 then
            -- Test for MTF ~= CT
            if self.mob_to_fight and self.mob_to_fight.index and self.mob_to_fight.index ~= hasCurrentTarget then
                if self.player.status == 1 then
                    local possible_target = MobObject:constructMob(hasCurrentTarget)
                    if possible_target and possible_target:isValidTarget(self.player.mob) and possible_target:isAllianceClaimed(self.claim_ids) then
                            notice(Utilities:printTime()..' setting mob to fight MTF ~= CT, VALID CT, Engaged')
                            notice(T(possible_target):tovstring())
                        self:setMobToFight(T{['name'] = possible_target.name, ['index'] = possible_target.index, ['obj'] = possible_target})
                        Actions:emptyOncePerTables()
                    end
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

function ObserverObject:validTargetable(name)

end

function ObserverObject:updateParty()
    -- Update alliance entries here as well
    self.claim_ids = self:setPartyClaimIds()
end
function ObserverObject:hasBit(data, x)
    return data:unpack('q', math.floor(x/8)+1, x%8+1)
end
function ObserverObject:serverOffset()
    local vana_time = os.time() - 1009810800
    return math.floor(os.time() - (vana_time * 60 % 0x100000000) / 60)
end
function ObserverObject:fromServerTime(t)
    return t / 60 + self.server_offset
end
function ObserverObject:toServerTime(t)
    return (t - self.server_offset) * 60
end
function ObserverObject:storeBuffDurationRemaining(id,data,modified,injected)
    if id == 0x063 then
        for i = 1, 32 do
            local index = 0x09 + ((i-1) * 0x02)
            local status_id = data:unpack('H', index)

            if status_id ~= 255 then
                self.player.buff_durations[i] = { id = status_id }
            end
        end

        for i = 1, 32 do
            if self.player.buff_durations[i] then
                local index = 0x49 + ((i-1) * 0x04)
                local endtime = data:unpack('I', index)

                if endtime <= 4 then
                    self.player.buff_durations[i] = nil
                else
                    self.player.buff_durations[i].endtime = math.floor(self:fromServerTime(endtime))
                end
            end
        end
    end
    -- if id == 0x037 then
    --     local p = packets.parse('incoming', data)
    --     if p['Timestamp'] and p['Time offset?'] then
    --         local vana_time = p['Timestamp'] * 60 - math.floor(p['Time offset?'])
    --         self.server_offset = math.floor(os.time() - vana_time % 0x100000000 / 60)
    --     end

    --     for i = 1, 32 do
    --         local index = 0x05 + (i-1)
    --         local status_id = data:unpack('b8', index)

    --         if status_id ~= 255 then
    --             self.player.buff_durations[i] = { id = status_id }
    --         end
    --     end

    --     for i = 1, 32 do
    --         local index = 0x04C * 8 + (i-1)*2
    --         local n = self:hasBit(data, index) and 1 or 0
    --         n = n + (self:hasBit(data, index + 1) and 2 or 0)
    --         if self.player.buff_durations[i] then
    --             self.player.buff_durations[i].id = self.player.buff_durations[i].id + n*256
    --         end
    --     end
    -- end
end

function ObserverObject:setAllyDependency(ally_name)
    if ally_name == nil then return false end
    self.ally_dependency = ally_name
    return true
end
function ObserverObject:getAllyDependency()
    return self.ally_dependency or false
end
function ObserverObject:isAllyDependencyPresent()
    if self.ally_dependency == nil then return true end
    local party_members = self:setPartyMembers()
    for _,v in pairs(party_members) do
        if v == self.ally_dependency then
            return true
        end
    end
    return false
end
function ObserverObject:handleMissingDependant()
    self.targets = T{}
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
function ObserverObject:timeSinceLastAttackPkt()
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
function ObserverObject:getMArray(names, loose)
    local marray = windower.ffxi.get_mob_array()
    local target_names = T{}
    local wildcard = loose or false

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
            if wildcard then
                local temp_check = false
                for _,val in pairs(target_names) do
                    if v.name:lower():find(val.name:lower()) then
                        temp_check = true
                    end
                end
                if not temp_check then
                    delete = true
                end
            else
                if not target_names:with('name', v.name:lower()) then
                    delete = true
                end
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
    difference = math.abs(player_mob.z - mob_obj.z)

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
function ObserverObject:validateMobToFight()
    if table.containskey(self.mob_to_fight, 'obj') then
        if self.mob_to_fight.obj.isValidTarget and (not self.mob_to_fight.obj:isValidTarget(self.player.mob) or not self.mob_to_fight.obj:isAllianceClaimed(self.claim_ids)) then
            self:setMobToFight(T{})
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
        coroutine.schedule(function() self:forceUnbusy() end , 1)
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
function ObserverObject:isPartyLead()
    return self.player:isPartyLead()
end
function ObserverObject:isSolo()
    return self.player:isSolo()
end
function ObserverObject:inAlliance()
    return self.player:inAlliance()
end
function ObserverObject:playersTarget(name)
    if name == nil then return nil end
	local name = name
	local party = windower.ffxi.get_party()
    local my_zone = windower.ffxi.get_info().zone

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() and member.zone == my_zone then
                if member and member.mob and (member.mob ~= nil) and (member.mob.target_index ~= nil or member.mob.target_index ~= 0) then
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

function ObserverObject:determinePointInSpace(target, distance, degrees)
    -- No protection, just raw dog it.

    -- Get the difference from its heading to the new angle
    local radians = degrees * math.pi / 180
    radians = radians - target.facing

    local new_x = target.x + distance * math.cos(radians)
    local new_y = target.y + distance * math.sin(radians)

    return new_x, new_y
end
function ObserverObject:getAngle(object_1, object_2)
    local player = object_2 or self.player.mob
    if object_1 and object_1.x and object_1.y and player then
        local dx = object_1.x - player.x
        local dy = object_1.y - player.y
        local theta = math.atan2(dy, dx)
        theta = theta * 180 / math.pi
        if theta < 0 then
            theta = theta + 360
        end
        return theta
    end
    return 0
end
function ObserverObject:getCardinalDirection(angle)
    if angle then
        if angle >= 337.5 or angle < 22.5 then
            return "E"
        elseif angle >= 22.5 and angle < 67.5 then
            return "NE"
        elseif angle >= 67.5 and angle < 112.5 then
            return "N"
        elseif angle >= 112.5 and angle < 157.5 then
            return "NW"
        elseif angle >= 157.5 and angle < 202.5 then
            return "W"
        elseif angle >= 202.5 and angle < 247.5 then
            return "SW"
        elseif angle >= 247.5 and angle < 292.5 then
            return "S"
        elseif angle >= 292.5 and angle < 337.5 then
            return "SE"
        end
    end
end
function ObserverObject:queueCurrencyUpdate()
    local packet = packets.new('outgoing', 0x117, {["_unknown2"]=0})
    packets.inject(packet)
    local packet2 = packets.new('outgoing', 0x10F, {})
    packets.inject(packet2)
end
function ObserverObject:queueMeritUpdate()
    local packet = packets.new('outgoing', 0x061, {["_unknown1"]=0})
    packets.inject(packet)
end

return ObserverObject