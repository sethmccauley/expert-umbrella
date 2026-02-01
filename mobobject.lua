local MobObject = {}
MobObject.__index = MobObject

function MobObject:constructMob(mob_or_index)
    if not mob_or_index then return nil end

    local self = setmetatable({}, MobObject)

    local mob = mob_or_index
    if type(mob) ~= 'table' then
        mob = windower.ffxi.get_mob_by_index(mob_or_index)
    end
    if type(mob) ~= 'table' or not mob.id then return nil end

    self.id = mob.id
    self.index = mob.index
    self.name = mob.name
    self.details = mob
    self.valid_target = false
    self.alliance_claimed = false
    self.claimed_at_time = 0
    self.last_update_time = 0
    self.resonating = T{}
    self.resonating_step = 0
    self.resonating_window = 0
    self.resonating_start_time = 0

    return self
end

function MobObject:getFlatCopy()
    local flat = {}
    if self.details then
        for k, v in pairs(self.details) do
            flat[k] = v
        end
    end
    for k, v in pairs(self) do
        if k ~= 'details' then
            flat[k] = v
        end
    end
    return flat
end
function MobObject:updateDetails()
    if not self.index then return nil end

    if os.clock() - self.last_update_time < 0.1 then return end

    local mob = windower.ffxi.get_mob_by_index(self.index)
    if not mob then return nil end

    self.details = mob

    if mob.claim_id and mob.claim_id > 0 and self.claimed_at_time == 0 then
        self.claimed_at_time = os.clock()
    end

    self:updateLastUpdateTime()
end
function MobObject:setResonatingValues(t, step, window, time)
    if not t or not step then return end
    self.resonating = t
    self.resonating_step = step
    if not window then self.resonating_window = (10 - self.resonating_step) else self.resonating_window = window end
    if not time then self.resonating_start_time = os.clock() else self.resonating_start_time = time end
end

function MobObject:updateLastUpdateTime()
    self.last_update_time = os.clock()
end
function MobObject:isValidTarget(player_mob)
    if not player_mob then return nil end

    self:updateDetails()
    if self:validVitals() and self:validStatus() and self:differenceZ(player_mob) < 6 then
        self.valid_target = true
        return true
    end
    self.valid_target = false
    return false
end
function MobObject:validVitals()
    if not self.details then return false end
    return self.details.hpp > 0
end
function MobObject:validStatus()
    if not self.details then return false end
    return (self.details.valid_target == true) and self.details.spawn_type == 16 and (self.details.status ~= 2 or self.details.status ~= 3)
end
function MobObject:isAllianceClaimed(alliance_ids)
    if not alliance_ids then return nil end

    self:updateDetails()
    local claim_id_check = T{}
    if type(alliance_ids) ~= 'table' then 
        claim_id_check[1] = alliance_ids
    else
        claim_id_check = alliance_ids
    end

    if self:helperArrayContains(claim_id_check, self.details.claim_id) or self.details.claim_id == 0 then
        self.alliance_claimed = true
        return true
    end

    self.alliance_claimed = false
    return false
end
function MobObject:isTrulyClaimed(alliance_ids)
    if not alliance_ids then return nil end

    self:updateDetails()
    local claim_id_check = T{}
    if type(alliance_ids) ~= 'table' then 
        claim_id_check[1] = alliance_ids
    else
        claim_id_check = alliance_ids
    end

    if self:helperArrayContains(claim_id_check, self.details.claim_id) then
        self.alliance_claimed = true
        return true
    end

    self.alliance_claimed = false
    return false
end

function MobObject:differenceZ(player_mob)
    if not player_mob then return nil end

    local difference = 0
    difference = math.abs(player_mob.z - self.details.z)

    return difference
end

function MobObject:helperArrayContains(t, value)
    if not t or not value then return nil end
    for i,v in pairs(t) do
        if v == value or v == tostring(value):lower() or tostring(v):lower() == tostring(value):lower() then return true end
        if type(v) == 'table' then
            if self:arrayContains(v, value) then return true end
        end
    end
    return false
end

return MobObject