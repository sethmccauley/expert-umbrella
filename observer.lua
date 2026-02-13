local MobObject = require('lang/mobobject')
local Utilities = require('lang/utilities')
local packets = require('packets')

local ObserverObject = {}
ObserverObject.__index = ObserverObject

function ObserverObject:constructObserver(entity_store)
    if not entity_store then return end

    local self = setmetatable({}, ObserverObject)

    self.entities = entity_store
    self.party_jobs = T{}

    self.last_target_update_time = 0

    -- Party buff tracking (separate from EntityStore party members)
    self.party = {
        by_id = {},
        by_name = {},
    }

    -- IPC State
    self.multi_box_present = false
    self.local_entities = S{}
    self.ipc_active = false

    -- Target scanning
    self.target_list = T{}
    self.ignore_list = T{}
    self.scan_range = 50

    -- Timing
    self.mtf_update_time = 0
    self.last_atk_pkt = 0
    self.last_target_pkt = 0
    self.last_switch_pkt = 0
    self.last_engage_time = 0
    self.last_attack_swing = 0
    self.attack_round_calc = 0

    -- Busy state
    self.is_casting = nil
    self.is_busy = false
    self.last_busy_start = 0
    self.next_action_ready = 0

    -- Misc state
    self.is_zoning = false
    self.ally_dependency = nil
    self.combat_positioning = T{}
    self.server_offset = self:serverOffset()

    -- Currency tracking
    self.sparks = 0
    self.accolades = 0
    self.conquest = { ['s'] = 0, ['b'] = 0, ['w'] = 0 }
    self.merits = 0
    self.gil = 0

    -- Kill Counts
    self.kill_counts = {}

    -- Initialize party data
    self:setPartyMembers()
    self.entities:syncParty()

    return self
end

-------------------------------------------------
-- Party Management
-------------------------------------------------

function ObserverObject:setPartyMembers()
    local party_table = windower.ffxi.get_party()
    local current_names = S{}

    self.party.by_id = {}

    if not party_table then return end

    for _,member in pairs(party_table) do
        if type(member) == 'table' and member.mob then
            self.party.by_id[member.mob.id] = member
            current_names:add(member.name)

            if not self.party.by_name[member.name] then
                self.party.by_name[member.name] = {buffs = T{}, debuffs = T{}}
            end
            if member.mob.pet_index then
                local pet = windower.ffxi.get_mob_by_index(member.mob.pet_index)
                if pet then
                    self.party.by_id[pet.id] = pet
                end
            end
        end
    end

    for name in pairs(self.party.by_name) do
        if not current_names:contains(name) then
            self.party.by_name[name] = nil
        end
    end
end
function ObserverObject:updateParty()
    self:setPartyMembers()
    self.entities:updateClaimIds()

    local remove_me = {}
    for name, _ in pairs(self.party_jobs) do
        if not self.party.by_name[name] then
            table.insert(remove_me, name)
        end
    end
    for _, name in ipairs(remove_me) do
        self.party_jobs[name] = nil
    end
end
function ObserverObject:updatePartyJobs(id,data,modified,injected)
    local p = packets.parse('incoming', data)
    local claim_ids = self.entities.claim_ids
    if not claim_ids:contains(p['ID']) then return end

    local index = p['Index']
    local mob = windower.ffxi.get_mob_by_index(index)
    if not mob then return end

    local resolved_name = mob.name

    local main_job, sub_job

    -- Check if this is a trust
    local found_trust = 0
    for i,v in pairs(Utilities._trust_job_list) do
        if v.name:lower() == resolved_name:lower() then
            found_trust = i
            break
        end
    end

    if found_trust > 0 then
        main_job = Utilities._job_ids[Utilities._trust_job_list[found_trust].mjob]
        sub_job = nil
    else
        main_job = Utilities._job_ids[p['Main job']]
        sub_job = Utilities._job_ids[p['Sub job']]
    end

    -- Update EntityStore
    self.entities:updatePlayerJobByIndex(index, main_job, sub_job)

    -- Keep legacy tracking for now (can remove later)
    self.party_jobs[resolved_name] = {['main'] = main_job, ['sub'] = sub_job}
end
function ObserverObject:updatePartyBuffs(id,data,modified,injected)
    for k = 0, 4 do
        local member_id = data:unpack('I', k*48+5)
        if member_id ~= 0 then
            local buffs = T{}
            for i = 1, 32 do
                local buff = data:byte(k*48+5+16+i-1) + 256*( math.floor( data:byte(k*48+5+8+ math.floor((i-1)/4)) / 4^((i-1)%4) )%4) -- Credit: Byrth, GearSwap
                if buff ~= 255 and buff ~= 0 then
                    buffs:append(buff)
                end
            end

            -- Update EntityStore
            self.entities:updatePlayerBuffs(member_id, buffs)

            -- Keep legacy tracking for now (can remove later)
            local member = self.party.by_id[member_id]
            if member and member.name and self.party.by_name[member.name] then
                self.party.by_name[member.name].buffs = buffs
            end
        end
    end
end
function ObserverObject:partyContains(job_name, type)
    -- Delegate to EntityStore
    return self.entities:partyContainsJob(job_name, type)
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
function ObserverObject:memberInZone(name)
    local name = name or 'None'
    local party = windower.ffxi.get_party()

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() and member.zone == windower.ffxi.get_info().zone then
                return true
            end
        end
    end
    return false
end
function ObserverObject:isPartyLead()
    return self.entities.me:isPartyLead()
end
function ObserverObject:isSolo()
    return self.entities.me:isSolo()
end
function ObserverObject:inAlliance()
    return self.entities.me:inAlliance()
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

-------------------------------------------------
-- MTF (Mob To Fight) Operations
-------------------------------------------------

function ObserverObject:setMobToFight(mob_id)
    if not mob_id or mob_id == 0 then
        if self.entities.mtf then
            notice(Utilities:printTime(os.time())..' Set Mob To Fight: empty')
        end
        self.entities:clearMTF()
        self.mtf_update_time = os.clock()
        return nil
    end

    if os.clock() - self.mtf_update_time < 0.75 then return nil end

    local mob_obj
    if mob_id then
        mob_obj = self.entities:setMTF(mob_id)
    end

    if mob_obj then
        mob_obj:updateDetails()
        notice(Utilities:printTime(os.time())..' Set Mob To Fight: '..mob_obj.name..' '..mob_obj.index)
        self.entities:addToIndex('aggro', mob_obj.id)
    end

    self.mtf_update_time = os.clock()
    return mob_obj
end
function ObserverObject:hasDeclaredTarget()
    local mtf = self.entities.mtf
    if mtf and mtf:isValidTarget(self.entities.me.mob) then
        return true
    end
    return false
end
function ObserverObject:getCurrentTargetID()
    return self.entities.mtf and self.entities.mtf.id or nil
end
function ObserverObject:hasCurrentTarget()
    local target = windower.ffxi.get_mob_by_target('t')
    if target == nil or (target and (target.id == self.entities.me.id or target.spawn_type ~= 16)) then
        return 0
    end
    return target.index
end

-------------------------------------------------
-- Target Scanning & Selection
-------------------------------------------------

function ObserverObject:setTargetList(new_target_list)
    if type(new_target_list) ~= 'table' then return end

    for i,v in pairs(new_target_list) do
        if i == 'names' then self.target_list = v
        elseif i == 'ignore' then self.ignore_list = v
        elseif i == 'range' then self.scan_range = v
        end
    end
end
function ObserverObject:setScanRange(value)
    if not value or value < 0 or value > 50 then return nil end
    self.scan_range = value
end
function ObserverObject:isIgnored(mob)
    if not mob or not self.ignore_list then return false end
    if self.ignore_list.name then
        for _, name in pairs(self.ignore_list.name) do
            if name:lower() == mob.name:lower() then return true end
        end
    end
    if self.ignore_list.hex then
        for _, hex in pairs(self.ignore_list.hex) do
            if tonumber(hex, 16) == mob.index then return true end
        end
    end
    return false
end
function ObserverObject:setAggroEmpty()
    self.entities:clearIndex('aggro')
end
function ObserverObject:updateMobs(navigation_obj)
    if not self.entities.me then return nil end

    self.entities.me:update()

    if os.clock() - self.last_target_update_time < 0.1 then return nil end

    self:findTargets(self.target_list, navigation_obj)
end
function ObserverObject:findTargets(mob_table_list, navigation_obj)
    if next(self.target_list) == nil then return T{} end

    local builder_marray = mob_table_list or nil
    local nodes = navigation_obj and navigation_obj.nodes or T{}
    if not builder_marray then return end

    local claim_ids = self.entities.claim_ids

    local base_marray = self:getBaseMArray()

    for i,v in pairs(builder_marray) do
        if i == 'name' then
            if table.length(v) > 0 then
                for _,val in pairs(v) do
                    local mobs = self:filterMArray(base_marray, val)
                    for _,va in pairs(mobs) do
                        local existing = va.id and self.entities:getMob(va.id)
                        if existing and self.entities:isInIndex('targets', va.id) then
                            existing:updateDetails()
                            if existing:isTrulyClaimed(claim_ids) and existing.claimed_at_time == 0 then
                                existing.claimed_at_time = os.clock()
                            end
                        elseif not self.entities:isInIndex('targets', va.id) then
                            local mob = MobObject:constructMob(va)
                            if mob and mob:isValidTarget(self.entities.me.mob) and self:isCloseEnough(mob, self.entities.me.mob, nodes, self.scan_range) and mob:isAllianceClaimed(claim_ids) then
                                self.entities:addMob(mob, 'targets')
                            end
                        end
                    end
                end
            end
        elseif i == 'hex' then
            if table.length(v) > 0 then
                for _,val in pairs(v) do
                    local index = tonumber(val, 16)
                    local mob = MobObject:constructMob(index)
                    if mob then
                        local existing = self.entities:getMob(mob.id)
                        if existing and self.entities:isInIndex('targets', mob.id) then
                            existing:updateDetails()
                            if existing:isTrulyClaimed(claim_ids) and existing.claimed_at_time == 0 then
                                existing.claimed_at_time = os.clock()
                            end
                        end
                        if not self.entities:isInIndex('targets', mob.id) and mob:isValidTarget(self.entities.me.mob) and self:isCloseEnough(mob, self.entities.me.mob, nodes, self.scan_range) and mob:isAllianceClaimed(claim_ids) then
                            self.entities:addMob(mob, 'targets')
                        end
                    end
                end
            end
        end
    end
end
function ObserverObject:pickNearest(category)
    local cat = category or 'targets'
    self.entities.me:update()
    return self.entities:pickNearest(cat, self.entities.me.mob)
end
function ObserverObject:addToAggro(id)
    local mob = windower.ffxi.get_mob_by_id(id)
    if not mob then return end

    local claim_ids = self.entities.claim_ids
    if mob.claim_id ~= 0 and not Utilities:arrayContains(claim_ids, mob.claim_id) then return end

    if not self.entities:isInIndex('aggro', mob.id) then
        self.entities:addMob(mob, 'aggro')
    end
end
function ObserverObject:determineTarget(Actions, StateController)
    self.entities.me:update()

    self:validateAggroTable()
    self:validateTargetsTable()
    self:validateMobToFight()

    if self:timeSinceLastAttackPkt() < 4 then return end

    local claim_ids = self.entities.claim_ids

    -- Slave Targeting Considerations
    if StateController.role == 'slave' then
        if StateController.assist == nil then return end

        local is_local_slave = self:isMBP() and self.local_entities:contains(StateController.assist)

        -- NON IPC Assist Target Checking
        if not is_local_slave then
            if (os.clock() - StateController.last_assist_check) < 0.5 then return end -- Throttled
            if self:inParty(StateController.assist) then
                local master_target_index = self:playersTarget(StateController.assist)
                local assist_status = self:playersStatus(StateController.assist)

                if master_target_index and master_target_index ~= 0 then
                    if assist_status == 1 then -- Master is Engaged
                        local potential_target = MobObject:constructMob(master_target_index)
                        if potential_target and potential_target:isValidTarget(self.entities.me.mob) and potential_target:isAllianceClaimed(claim_ids) then
                            if not self.entities:isInIndex('aggro', potential_target.id) then
                                self:addToAggro(potential_target.id)
                            end
                            local mtf = self.entities.mtf
                            if (not mtf or (mtf.index ~= master_target_index)) and not self:isIgnored(potential_target) then
                                self:setMobToFight(potential_target.id)
                                Actions:emptyOncePerTables()
                            end
                        else
                            -- Somehow master's target invalid
                            if potential_target and self.entities:isInIndex('aggro', potential_target.id) then
                                self.entities:removeFromIndex('aggro', potential_target.id)
                            end
                            local mtf = self.entities.mtf
                            if mtf and potential_target and mtf.index == potential_target.index then
                                self:setMobToFight(nil)
                            end
                        end
                    else
                        if self.entities:hasAggro() then
                            self:setAggroEmpty()
                        end
                        if self.entities:hasMTF() then
                            self:setMobToFight(nil)
                        end
                        if self.entities.me and self.entities.me.status == 1 and Actions.mirror_masters_engage then
                            self:setAggroEmpty()
                            self:setMobToFight(nil)
                            Actions:disengageMob()
                        end
                    end
                end
            end
        end
        StateController:setLastAssistCheckTime()
        return
    end

    -- Master Targeting Logic
    local hasCurrentTarget = self:hasCurrentTarget()

    -- MTF is Empty
    if not self.entities:hasMTF() then
        if hasCurrentTarget ~= 0 then
            if self.entities.me.status == 1 then
                local possible_target = MobObject:constructMob(hasCurrentTarget)
                if possible_target and possible_target:isValidTarget(self.entities.me.mob) and possible_target:isAllianceClaimed(claim_ids) and not self:isIgnored(possible_target) then
                    self:setMobToFight(possible_target.id)
                    Actions:emptyOncePerTables()
                    if self:isMBP() and StateController.role == 'master' and possible_target.index then
                        Utilities.sendIPC('mtf '..possible_target.index, self.entities.me.name)
                    end
                    return
                end
            end
        end

        if not self.entities:hasTargets() then
            if self.entities:hasAggro() then
                local nearest_mob = self:pickNearest('aggro')
                if nearest_mob and not self:isIgnored(nearest_mob) then
                    self:setMobToFight(nearest_mob.id)
                    Actions:emptyOncePerTables()
                    if self:isMBP() and StateController.role == 'master' and nearest_mob.index then
                        Utilities.sendIPC('mtf '..nearest_mob.index, self.entities.me.name)
                    end
                end
            end
        else
            local nearest_mob = self:pickNearest('targets')
            if nearest_mob and not self:isIgnored(nearest_mob) then
                self:setMobToFight(nearest_mob.id)
                Actions:emptyOncePerTables()
                if self:isMBP() and StateController.role == 'master' and nearest_mob.index then
                    Utilities.sendIPC('mtf '..nearest_mob.index, self.entities.me.name)
                end
            end
        end
    else
        -- MTF is Populated, Check for current Target
        if hasCurrentTarget ~= 0 then
            local mtf = self.entities.mtf
            if mtf and mtf.index ~= hasCurrentTarget then
                if self.entities.me.status == 1 then
                    local possible_target = MobObject:constructMob(hasCurrentTarget)
                    if possible_target and possible_target:isValidTarget(self.entities.me.mob) and possible_target:isAllianceClaimed(claim_ids) and not self:isIgnored(possible_target) then
                        notice(Utilities:printTime()..' setting mob to fight MTF ~= CT, VALID CT, Engaged')
                        notice(T(possible_target):tovstring())
                        self:setMobToFight(possible_target.id)
                        Actions:emptyOncePerTables()
                        if self:isMBP() and StateController.role == 'master' and possible_target.index then
                            Utilities.sendIPC('mtf '..possible_target.index, self.entities.me.name)
                        end
                    end
                end
            end
        end
    end
end
function ObserverObject:validateTargetsTable()
    self.entities:validateTargets(self.entities.me.mob)
end
function ObserverObject:validateAggroTable()
    self.entities:validateAggro(self.entities.me.mob)
end
function ObserverObject:validateMobToFight()
    local mtf = self.entities.mtf
    if mtf then
        mtf:updateDetails()
        local claim_ids = self.entities.claim_ids
        if not mtf:isValidTarget(self.entities.me.mob) or not mtf:isAllianceClaimed(claim_ids) then
            self:setMobToFight(nil)
        end
    end
end
function ObserverObject:printQT()
    local targets = self.entities:getTargets()
    if not targets or #targets == 0 then return nil end

    local printString = ''
    for _,v in pairs(targets) do
        printString = printString..'('..v.index..' '..v.name..') '
    end
    notice(printString)
end

-------------------------------------------------
-- Mob Array Utilities
-------------------------------------------------

--[[
    Collects all mobs loaded into memory and optionally trims them down based on the name or names given
    names = 'Locus Colibri'
        or
    names = {
        [1] = 'Locus Colibri',
        [2] = 'Locus Wivre'
    }
]]
function ObserverObject:getBaseMArray()
    local marray = windower.ffxi.get_mob_array()
    for i,v in pairs(marray) do
        if v.id == 0 or v.index == 0 or v.status == 3 then
            marray[i] = nil
        end
    end
    return marray
end

function ObserverObject:filterMArray(marray, names, loose)
    local result = {}
    local wildcard = loose or false
    local target_names = T{}

    if type(names) == 'table' then
        for i,v in pairs(names) do
            target_names[i] = {['name'] = v:lower()}
        end
    elseif type(names) == 'string' then
        target_names = T{[1] = {['name'] = names and names:lower() or nil}}
    end

    if not names then
        for i,v in pairs(marray) do
            result[i] = v
        end
        return result
    end

    for i,v in pairs(marray) do
        local match = false
        if wildcard then
            for _,val in pairs(target_names) do
                if v.name:lower():find(val.name:lower()) then
                    match = true
                    break
                end
            end
        else
            if target_names:with('name', v.name:lower()) then
                match = true
            end
        end
        if match then
            result[i] = v
        end
    end

    return result
end

function ObserverObject:getMArray(names, loose)
    local marray = self:getBaseMArray()
    return self:filterMArray(marray, names, loose)
end

-------------------------------------------------
-- IPC (Inter-Process Communication)
-------------------------------------------------

function ObserverObject:setIPCActive(value)
    if type(value) ~= 'boolean' then return end
    self.ipc_active = value
end
function ObserverObject:isIPCActive()
    return self.ipc_active
end
function ObserverObject:setMBP(value)
    if type(value) ~= 'boolean' then return end
    self.multi_box_present = value
end
function ObserverObject:isMBP()
    return self.multi_box_present
end
function ObserverObject:registerIPCEntities()
    Utilities:sendIPC('register', self.entities.me.name)
end
function ObserverObject:addLocalEntity(name)
    if name ~= nil and not self.local_entities:contains(name) then
        self.local_entities:add(name:lower())
        self.multi_box_present = true
    end
end
function ObserverObject:removeLocalEntity(name)
    if self.local_entities:contains(name) then
        self.local_entities:remove(name)
    end
end

-------------------------------------------------
-- Timing & Packet Tracking
-------------------------------------------------

function ObserverObject:setAtkPkt()
    self.last_atk_pkt = os.clock()
end
function ObserverObject:setTargetPkt()
    self.last_target_pkt = os.clock()
end
function ObserverObject:timeSinceLastAttackPkt()
    return os.clock() - self.last_atk_pkt
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
function ObserverObject:setActionDelay(action_type, override)
    self.next_action_ready = os.clock() + (override or Utilities._global_delays[action_type] or 2.0)
end
function ObserverObject:canAct()
    return (os.clock() >= self.next_action_ready)
end

-------------------------------------------------
-- Busy State Management
-------------------------------------------------

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
    self.entities:updateClaimIds()
    self.entities.me:update()
    mob_obj:updateValidTarget(self.entities.me.mob)

    local claim_ids = self.entities.claim_ids
    if mob_obj.valid_target and mob_obj:isAllianceClaimed(claim_ids) then
        return true
    end

    return false
end

-------------------------------------------------
-- Packet Handlers
-------------------------------------------------

function ObserverObject:notifyMobDeath(id,data,modified,injected,blocked, Actions)
    local p = packets.parse('incoming',data)
    local target_id = p['Target']
    local player_id = p['Actor']
    local target_index = p['Target Index']
    local message_id = p['Message']

    if message_id == 17 or message_id == 18 then -- Unable to cast?
        self:setActionDelay('spell', 1)
    end

    if message_id == 6 or message_id == 20 then -- Dies or Falls
        local dead_mob = self.entities:getMobByIndex(target_index)
        if dead_mob then
            local name = dead_mob.name
            self.kill_counts[name] = (self.kill_counts[name] or 0) + 1
            self.entities:removeMob(dead_mob.id)
        end

        local mtf = self.entities.mtf
        if mtf and mtf.index == target_index then
            self.entities:clearMTF()
            coroutine.schedule(function() Actions:emptyOncePerCombat() end, 1)
        end
        coroutine.schedule(function() self:forceUnbusy() end , 1)
    end
end
function ObserverObject:watchResonation(id,data,modified,injected,blocked)
    local p = packets.parse('incoming', data)
    local mtf = self.entities.mtf
    if mtf and mtf.id == p['Target 1 ID'] then
        Utilities:determineResonation(p, mtf)
    end
end

-------------------------------------------------
-- Buff & Status Tracking
-------------------------------------------------

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
                self.entities.me.buff_durations[i] = { id = status_id }
            end
        end
        for i = 1, 32 do
            if self.entities.me.buff_durations[i] then
                local index = 0x49 + ((i-1) * 0x04)
                local endtime = data:unpack('I', index)
                if endtime <= 3 then
                    self.entities.me.buff_durations[i] = nil
                else
                    self.entities.me.buff_durations[i].endtime = math.floor(self:fromServerTime(endtime))
                end
            end
        end
    end
end

-------------------------------------------------
-- Ally Dependency
-------------------------------------------------

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
    for _,v in pairs(party_members or {}) do
        if v == self.ally_dependency then
            return true
        end
    end
    return false
end
function ObserverObject:handleMissingDependant()
    self.entities:clearIndex('targets')
end

-------------------------------------------------
-- Distance & Position Helpers
-------------------------------------------------

function ObserverObject:distanceBetween(pos1, pos2)
    if pos1 and pos2 then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        return math.sqrt(dx*dx + dy*dy)
    else
        return 0
    end
end
function ObserverObject:differenceZ(mob_obj, player_mob)
    if not mob_obj or not player_mob then return nil end
    return math.abs(player_mob.z - mob_obj.z)
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

    for i,v in ipairs(nodes) do
        if self:distanceBetween(mob_obj.details, v) < dist_target then
            dist_target = self:distanceBetween(mob_obj.details, v)
        end
    end

    if dist_target < range_limit then
        return true
    end

    return false
end
function ObserverObject:setCombatPosition(x, y)
    if x == nil and y == nil then
        self.combat_positioning = T{}
        return
    end
    self.combat_positioning = T{['x'] = x, ['y'] = y}
end
function ObserverObject:determinePointInSpace(target, distance, degrees)
    local radians = degrees * math.pi / 180
    radians = radians - target.facing

    local new_x = target.x + distance * math.cos(radians)
    local new_y = target.y + distance * math.sin(radians)

    return new_x, new_y
end
function ObserverObject:getAngle(object_1, object_2)
    local player = object_2 or self.entities.me.mob
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
function ObserverObject:inCity()
    local world = windower.ffxi.get_info()
    if Utilities:arrayContains(Utilities._cities, Utilities.res.zones[world.zone].en) then
        return true
    end
    return false
end

-------------------------------------------------
-- Currency & Merit Tracking
-------------------------------------------------

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

-------------------------------------------------
-- File I/O
-------------------------------------------------

function ObserverObject:getFileContents()
    return {
        ["range"]= self.scan_range,
        ["names"]= self.target_list,
        ["ignore"]= self.ignore_list
    }
end

return ObserverObject
