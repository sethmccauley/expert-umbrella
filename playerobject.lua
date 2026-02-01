local PlayerObject = {}
PlayerObject.__index = PlayerObject

local Utilities = require('lang/utilities')

function PlayerObject:constructPlayer() 
    local player_obj = windower.ffxi.get_player()
    if not player_obj then return nil end

    local player_mob = windower.ffxi.get_mob_by_id(player_obj.id)
    if not player_mob then return nil end

    local self = setmetatable({}, PlayerObject)

    self.id = player_mob.id
    self.index = player_mob.index
    self.self = true
    self.name = player_obj.name
    self.status = player_mob.status
    self.vitals = player_obj.vitals
    self.buffs = player_obj.buffs
    self.mob = player_mob
    self.is_trust = false
    self.details = player_obj
    self.buff_durations = T{}

    self.last_update_time = 0

    return self
end

function PlayerObject:constructPartyPC(member)
    if not member and not member.mob then return nil end

    local self = setmetatable({}, PlayerObject)

    self.id = member.mob.id
    self.name = member.name
    self.index = member.mob.index
    self.self = false
    self.status = member.mob.status
    self.is_trust = (member.mob.spawn_type == 14)
    self.mob = member.mob

    -- Job tracking (populated via packet 0x0DF)
    self.main_job = nil     -- {english, short} from Utilities._job_ids
    self.sub_job = nil

    -- Buff tracking (populated via packet 0x076)
    self.buffs = T{}

    return self
end

function PlayerObject:setJobs(main_job, sub_job)
    self.main_job = main_job
    self.sub_job = sub_job
end

function PlayerObject:setBuffs(buffs)
    self.buffs = buffs or T{}
end

function PlayerObject:setLastUpdateTime()
    self.last_update_time = os.clock()
end

function PlayerObject:update()
    if self.id == 0 then return end

    -- if os.clock() - self.last_update_time < 0.1 then return nil end

    local player_mob = windower.ffxi.get_mob_by_id(self.id)
    if not player_mob then return nil end

    if self.self then
        local player_obj = windower.ffxi.get_player()
        if not player_obj then return nil end

        self.buffs = player_obj.buffs
        self.id = player_obj.id
        self.index = player_obj.index
        self.status = player_mob.status
        self.vitals = player_obj.vitals
        self.mob = player_mob
        self.target_index = player_obj.target_index
        self.details = player_obj
    else
        self.id = player_mob.id
        self.index = player_mob.index
        self.status = player_mob.status
        self.mob = player_mob
        self.target_index = player_mob.target_index
    end

    self:setLastUpdateTime()
end

function PlayerObject:hasBuff(buff, strength)
    local tier = 0
    local strength = strength or 1
    local buffs = self:convertBuffList(self.buffs)
    local raw_buffs = self.buffs

    if type(buff) == 'string' then
        local wildcard = buff:find('*')
        if wildcard then
            local newbuff = buff:gsub('*', ''):lower()
            for i,v in pairs(buffs) do
                if v:find(newbuff) then
                    tier = tier + 1
                end
            end
        else
            for _,v in pairs(buffs) do
                if v == buff:lower() then
                    tier = tier + 1
                end
            end
        end
    else
        for _,v in pairs(raw_buffs) do
            if v == buff then
                tier = tier + 1
            end
        end
    end

    if tier >= strength then
        return true
    end
    return false
end
function PlayerObject:convertBuffList(bufflist)
    local buffarr = {}
    for i,v in pairs(bufflist) do
        if Utilities.res.buffs[v] then
            buffarr[#buffarr+1] = Utilities.res.buffs[v].english:lower()
        end
    end
    return buffarr
end
function PlayerObject:buffTimeLeft(buff)
    local now = os.time()
    local b_array = {}
    local lowest_remaining = 9999
    if next(self.buff_durations) then
        for _,v in pairs(self.buff_durations) do
            if type(buff) == 'string' then
                if Utilities.res.buffs[v.id] and Utilities.res.buffs[v.id].english:lower() == buff then
                    table.append(b_array, {id = v.id, endtime = v.endtime})
                end
            else
                if v.id == buff then
                    table.append(b_array, {id = v.id, endtime = v.endtime})
                end
            end
        end
        for _,val in pairs(b_array) do
            if val.endtime and (val.endtime - now) < lowest_remaining then
                lowest_remaining = (val.endtime - now)
            end
        end
    end
    return lowest_remaining
end

function PlayerObject:canAct()
    local actable_statuses = S{0,1} -- Idle/Engaged
    if actable_statuses:contains(self.status) then
        return true
    end
    return false
end
function PlayerObject:canCastSpells()
    local haltables = {'Sleep','Petrifaction','Charm','Terror','Lullaby','Stun','Silence','Mute'}

    for _,v in pairs(haltables) do
        if self:hasBuff(v) and self:canAct() then
            return false
        end
    end
    return true
end
function PlayerObject:canJaWs()
    local haltables = {'Sleep','Petrifaction','Charm','Terror','Lullaby','Stun','Amnesia'}

    for _,v in pairs(haltables) do
        if self:hasBuff(v) and self:canAct() then
            return false
        end
    end
    return true
end

function PlayerObject:getStatus()
    if not self.mob then return nil end
    return self.mob.status
end
function PlayerObject:currentTarget()
    if not self.target_index then return nil end
    return self.target_index
end

function PlayerObject:isPartyLead()
    local party = windower.ffxi.get_party()
    if self.id == party.party1_leader then
        return true
    end    
    return false
end
function PlayerObject:inAlliance()
    local party = windower.ffxi.get_party()
    if party.party2_count > 0 or party.party3_count > 0 then
        return true
    end
    return false
end
function PlayerObject:isSolo()
    local party = windower.ffxi.get_party()
    return party.party1_leader == nil
end
function PlayerObject:isDead()
    if self.status == 2 or self.status == 3 then
        return true
    end
    return false
end

return PlayerObject