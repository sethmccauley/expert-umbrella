local MobObject = require('lang/mobobject')
local PlayerObject = require('lang/playerobject')

local EntityStore = {}
EntityStore.__index = EntityStore

function EntityStore:constructEntityStore(player_obj)
    local self = setmetatable({}, EntityStore)

    -- Primary storage keyed by ID for O(1) lookup
    self.mobs = {}              -- [mob_id] = MobObject
    self.players = {}           -- [player_id] = PlayerObject

    -- Quick reference pointers (references into mobs/players, not copies)
    self.mtf = nil              -- Current mob to fight
    self.me = player_obj        -- The Player.lua object (passed in)

    -- Index sets for fast category queries (stores IDs, not objects)
    self.indexes = {
        aggro = {},             -- Mobs we're actively fighting (aggro table)
        targets = {},           -- Mobs on our target list (scan targets)
        party = {},             -- Party member IDs
        alliance = {},          -- Alliance member IDs (includes party)
        pets = {},              -- Pet IDs (keyed by owner_id for lookup)
        trusts = {},            -- Trust IDs
    }

    self.counts = {
        aggro = 0,
        targets = 0,
        party = 0,
        alliance = 0,
        pets = 0,
        trusts = 0,
    }

    -- Claim tracking
    self.claim_ids = T{}         -- Array of IDs that count as "our" claim

    return self
end

-------------------------------------------------
-- Mob Operations
-------------------------------------------------

function EntityStore:addMob(mob_or_index, category)
    local mob_obj = MobObject:constructMob(mob_or_index)
    if not mob_obj then return nil end

    local existing = self.mobs[mob_obj.id]
    if existing then
        existing:updateDetails()
        mob_obj = existing
    else
        self.mobs[mob_obj.id] = mob_obj
    end

    if category then
        self:addToIndex(category, mob_obj.id)
    end

    return mob_obj
end
function EntityStore:getMob(mob_id)
    return self.mobs[mob_id]
end
function EntityStore:getMobByIndex(index)
    for _, mob in pairs(self.mobs) do
        if mob.index == index then
            return mob
        end
    end
    return nil
end
function EntityStore:updateMob(mob_id)
    local mob_obj = self.mobs[mob_id]
    if mob_obj then
        mob_obj:updateDetails()
    end
    return mob_obj
end
function EntityStore:removeMob(mob_id)
    if not self.mobs[mob_id] then return false end

    -- Clear from all indexes (use removeFromIndex to maintain counts)
    for category in pairs(self.indexes) do
        self:removeFromIndex(category, mob_id)
    end

    -- Clear MTF if this was it
    if self.mtf and self.mtf.id == mob_id then
        self.mtf = nil
    end

    self.mobs[mob_id] = nil
    return true
end

-------------------------------------------------
-- Player Operations
-------------------------------------------------

function EntityStore:addPlayer(member, category)
    if not member or not member.mob then return nil end

    local existing = self.players[member.mob.id]
    if existing then
        existing:update()
        return existing
    end

    local player_obj = PlayerObject:constructPartyPC(member)
    if not player_obj then return nil end

    self.players[player_obj.id] = player_obj

    if category then
        self:addToIndex(category, player_obj.id)
    end

    -- Check for pet
    if member.mob.pet_index then
        self:addPetForOwner(player_obj.id, member.mob.pet_index)
    end

    return player_obj
end
function EntityStore:getPlayer(player_id)
    return self.players[player_id]
end
function EntityStore:getPlayerByName(name)
    if not name then return nil end
    local lower_name = name:lower()
    for _, player in pairs(self.players) do
        if player.name and player.name:lower() == lower_name then
            return player
        end
    end
    return nil
end
function EntityStore:updatePlayer(player_id)
    local player_obj = self.players[player_id]
    if player_obj then
        player_obj:update()
    end
    return player_obj
end
function EntityStore:removePlayer(player_id)
    if not self.players[player_id] then return false end

    -- Clear from indexes (use removeFromIndex to maintain counts)
    for category in pairs(self.indexes) do
        self:removeFromIndex(category, player_id)
    end

    -- Remove associated pet (pets index is keyed by owner_id, not pet_id)
    if self.indexes.pets[player_id] then
        self.indexes.pets[player_id] = nil
        self.counts.pets = self.counts.pets - 1
    end

    self.players[player_id] = nil
    return true
end

-------------------------------------------------
-- Pet Operations (pets are mobs, keyed by owner)
-------------------------------------------------

function EntityStore:addPetForOwner(owner_id, pet_index)
    local pet_mob = windower.ffxi.get_mob_by_index(pet_index)
    if not pet_mob then return nil end

    local pet_obj = self:addMob(pet_mob)
    if pet_obj then
        -- pets index is special: keyed by owner_id -> pet_id
        if not self.indexes.pets[owner_id] then
            self.counts.pets = self.counts.pets + 1
        end
        self.indexes.pets[owner_id] = pet_obj.id
    end
    return pet_obj
end
function EntityStore:getPetForOwner(owner_id)
    local pet_id = self.indexes.pets[owner_id]
    if pet_id then
        return self.mobs[pet_id]
    end
    return nil
end
function EntityStore:getMyPet()
    if not self.me then return nil end
    return self:getPetForOwner(self.me.id)
end
function EntityStore:getPetIds()
    return self.indexes.pets
end

-------------------------------------------------
-- MTF (Mob To Fight) Operations
-------------------------------------------------

function EntityStore:setMTF(mob_id)
    if mob_id == nil then
        self.mtf = nil
        return nil
    end

    local mob = self.mobs[mob_id]
    if not mob then
        -- Auto-add if not in store
        mob = self:addMob(mob_id, 'aggro')
    end

    self.mtf = mob
    return mob
end
function EntityStore:setMTFByIndex(index)
    local mob = self:getMobByIndex(index)
    if mob then
        self.mtf = mob
        return mob
    end

    -- Not in store, create and add
    mob = self:addMob(index, 'aggro')
    self.mtf = mob
    return mob
end
function EntityStore:getMTF()
    return self.mtf
end
function EntityStore:clearMTF()
    self.mtf = nil
end

-------------------------------------------------
-- Universal Lookup
-------------------------------------------------

function EntityStore:get(id)
    return self.mobs[id] or self.players[id]
end
function EntityStore:getByIndex(index)
    local mob = self:getMobByIndex(index)
    if mob then return mob end

    for _, player in pairs(self.players) do
        if player.index == index then
            return player
        end
    end
    return nil
end

-------------------------------------------------
-- Category Queries
-------------------------------------------------

function EntityStore:getAggro()
    local result = {}
    for mob_id in pairs(self.indexes.aggro) do
        local mob = self.mobs[mob_id]
        if mob then
            result[#result + 1] = mob
        end
    end
    return result
end
function EntityStore:getTargets()
    local result = {}
    for mob_id in pairs(self.indexes.targets) do
        local mob = self.mobs[mob_id]
        if mob then
            result[#result + 1] = mob
        end
    end
    return result
end
function EntityStore:getParty()
    local result = {}
    for player_id in pairs(self.indexes.party) do
        local player = self.players[player_id]
        if player then
            result[#result + 1] = player
        end
    end
    return result
end
function EntityStore:getAlliance()
    local result = {}
    for player_id in pairs(self.indexes.alliance) do
        local player = self.players[player_id]
        if player then
            result[#result + 1] = player
        end
    end
    return result
end
function EntityStore:getTrusts()
    local result = {}
    for player_id in pairs(self.indexes.trusts) do
        local player = self.players[player_id]
        if player then
            result[#result + 1] = player
        end
    end
    return result
end
function EntityStore:getAllPets()
    local result = {}
    for owner_id, pet_id in pairs(self.indexes.pets) do
        local pet = self.mobs[pet_id]
        if pet then
            result[#result + 1] = pet
        end
    end
    return result
end

-------------------------------------------------
-- Party Job/Buff Management
-------------------------------------------------

function EntityStore:updatePlayerJob(player_id, main_job, sub_job)
    local player = self.players[player_id]
    if player then
        player:setJobs(main_job, sub_job)
        return true
    end
    return false
end

function EntityStore:updatePlayerJobByIndex(index, main_job, sub_job)
    for _, player in pairs(self.players) do
        if player.index == index then
            player:setJobs(main_job, sub_job)
            return true
        end
    end
    return false
end

function EntityStore:updatePlayerBuffs(player_id, buffs)
    local player = self.players[player_id]
    if player then
        player:setBuffs(buffs)
        return true
    end
    return false
end

function EntityStore:partyContainsJob(job_short, which)
    which = which or 'main'
    local job_lower = job_short:lower()

    for player_id in pairs(self.indexes.party) do
        local player = self.players[player_id]
        if player then
            if which == 'main' and player.main_job and player.main_job.short then
                if player.main_job.short:lower() == job_lower then
                    return true
                end
            elseif which == 'sub' and player.sub_job and player.sub_job.short then
                if player.sub_job.short:lower() == job_lower then
                    return true
                end
            end
        end
    end

    -- Also check trusts
    for player_id in pairs(self.indexes.trusts) do
        local player = self.players[player_id]
        if player then
            if which == 'main' and player.main_job and player.main_job.short then
                if player.main_job.short:lower() == job_lower then
                    return true
                end
            end
        end
    end

    return false
end

-------------------------------------------------
-- Index Management
-------------------------------------------------

function EntityStore:addToIndex(category, id)
    if self.indexes[category] and not self.indexes[category][id] then
        self.indexes[category][id] = true
        self.counts[category] = self.counts[category] + 1
    end
end
function EntityStore:removeFromIndex(category, id)
    if self.indexes[category] and self.indexes[category][id] then
        self.indexes[category][id] = nil
        self.counts[category] = self.counts[category] - 1
    end
end
function EntityStore:isInIndex(category, id)
    return self.indexes[category] and self.indexes[category][id] == true
end
function EntityStore:clearIndex(category)
    if self.indexes[category] then
        self.indexes[category] = {}
        self.counts[category] = 0
    end
end
function EntityStore:getCount(category)
    return self.counts[category] or 0
end

-------------------------------------------------
-- Claim ID Management
-------------------------------------------------

function EntityStore:updateClaimIds()
    local party_table = windower.ffxi.get_party()
    local claim_ids = T{}

    if not party_table then
        self.claim_ids = T{}
        return T{}
    end

    for _, member in pairs(party_table) do
        if type(member) == 'table' and member.mob then
            claim_ids[#claim_ids + 1] = member.mob.id
            -- Also add pets as valid claimers
            if member.mob.pet_index then
                local pet = windower.ffxi.get_mob_by_index(member.mob.pet_index)
                if pet then
                    claim_ids[#claim_ids + 1] = pet.id
                end
            end
        end
    end

    self.claim_ids = claim_ids
    return claim_ids
end
function EntityStore:isOurClaim(claim_id)
    if claim_id == 0 then return true end -- Unclaimed counts as ours
    for _, id in ipairs(self.claim_ids) do
        if id == claim_id then return true end
    end
    return false
end

-------------------------------------------------
-- Bulk Sync Operations (called by Observer)
-------------------------------------------------

function EntityStore:syncParty()
    local party_table = windower.ffxi.get_party()

    -- Clear old indexes using clearIndex to reset counts
    self:clearIndex('party')
    self:clearIndex('alliance')
    self:clearIndex('trusts')
    self:clearIndex('pets')

    -- Clear old player entries that aren't self.me
    local to_remove = {}
    for id, player in pairs(self.players) do
        if not player.self then
            to_remove[#to_remove + 1] = id
        end
    end
    for _, id in ipairs(to_remove) do
        self.players[id] = nil
    end

    if not party_table then return end

    for _, member in pairs(party_table) do
        if type(member) == 'table' and member.mob then
            local player = self:addPlayer(member)
            if player then
                -- Categorize using addToIndex for count tracking
                if player.is_trust then
                    self:addToIndex('trusts', player.id)
                else
                    self:addToIndex('party', player.id)
                end
                self:addToIndex('alliance', player.id)
            end
        end
    end

    self:updateClaimIds()
end
function EntityStore:syncAggro(aggro_entries)
    -- aggro_entries is expected to be keyed by index: { [index] = {name, index, obj}, ... }
    self:clearIndex('aggro')

    for index, entry in pairs(aggro_entries) do
        local mob = entry.obj or self:addMob(index)
        if mob then
            self.mobs[mob.id] = mob
            self:addToIndex('aggro', mob.id)
        end
    end
end
function EntityStore:syncTargets(target_entries)
    -- target_entries keyed by index: { [index] = {name, index, obj}, ... }
    self:clearIndex('targets')

    for index, entry in pairs(target_entries) do
        local mob = entry.obj or self:addMob(index)
        if mob then
            self.mobs[mob.id] = mob
            self:addToIndex('targets', mob.id)
        end
    end
end

-------------------------------------------------
-- Validation & Cleanup
-------------------------------------------------

function EntityStore:validateMob(mob_id, player_mob)
    local mob = self.mobs[mob_id]
    if not mob then return false end

    mob:updateDetails()
    return mob:isValidTarget(player_mob) and mob:isAllianceClaimed(self.claim_ids)
end
function EntityStore:cleanup(player_mob)
    -- Remove invalid mobs from store and indexes
    local to_remove = {}

    for mob_id, mob in pairs(self.mobs) do
        mob:updateDetails()
        if not mob:validVitals() then
            to_remove[#to_remove + 1] = mob_id
        end
    end

    for _, mob_id in ipairs(to_remove) do
        self:removeMob(mob_id)
    end

    -- Validate MTF
    if self.mtf then
        self.mtf:updateDetails()
        if not self.mtf:validVitals() then
            self.mtf = nil
        end
    end
end
function EntityStore:validateAggro(player_mob)
    local to_remove = {}

    for mob_id in pairs(self.indexes.aggro) do
        if not self:validateMob(mob_id, player_mob) then
            to_remove[#to_remove + 1] = mob_id
        end
    end

    for _, mob_id in ipairs(to_remove) do
        self:removeFromIndex('aggro', mob_id)
    end
end
function EntityStore:validateTargets(player_mob)
    local to_remove = {}

    for mob_id in pairs(self.indexes.targets) do
        if not self:validateMob(mob_id, player_mob) then
            to_remove[#to_remove + 1] = mob_id
        end
    end

    for _, mob_id in ipairs(to_remove) do
        self:removeFromIndex('targets', mob_id)
    end
end

-------------------------------------------------
-- Clear Operations
-------------------------------------------------

function EntityStore:clearEnemies()
    for mob_id in pairs(self.indexes.aggro) do
        self:removeMob(mob_id)
    end
    -- removeMob already clears from indexes, but ensure clean state
    self:clearIndex('aggro')
end
function EntityStore:clearTargets()
    -- Only remove from targets index, mob may still be in aggro
    self:clearIndex('targets')
end
function EntityStore:clearAll()
    self.mobs = {}
    self.players = {}
    self.mtf = nil

    for category in pairs(self.indexes) do
        self:clearIndex(category)
    end
end

-------------------------------------------------
-- Query Helpers (O(1) via counts)
-------------------------------------------------

function EntityStore:countAggro()
    return self.counts.aggro
end
function EntityStore:countTargets()
    return self.counts.targets
end
function EntityStore:countParty()
    return self.counts.party
end
function EntityStore:countAlliance()
    return self.counts.alliance
end
function EntityStore:countTrusts()
    return self.counts.trusts
end
function EntityStore:countPets()
    return self.counts.pets
end
function EntityStore:hasAggro()
    return self.counts.aggro > 0
end
function EntityStore:hasTargets()
    return self.counts.targets > 0
end
function EntityStore:hasMTF()
    return self.mtf ~= nil
end

-------------------------------------------------
-- Distance Helpers
-------------------------------------------------

function EntityStore:pickNearest(category, player_mob)
    local entities = {}

    if category == 'aggro' then
        entities = self:getAggro()
    elseif category == 'targets' then
        entities = self:getTargets()
    elseif category == 'party' then
        entities = self:getParty()
    end

    if #entities == 0 then return nil end

    local nearest = nil
    local nearest_dist = 999

    for _, entity in ipairs(entities) do
        local mob_data = entity.details or entity.mob
        if mob_data then
            local dist = self:distanceBetween(player_mob, mob_data)
            if dist < nearest_dist then
                nearest = entity
                nearest_dist = dist
            end
        end
    end

    return nearest
end
function EntityStore:distanceBetween(pos1, pos2)
    if pos1 and pos2 and pos1.x and pos2.x then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        return math.sqrt(dx * dx + dy * dy)
    end
    return 999
end

-------------------------------------------------
-- Debug
-------------------------------------------------

function EntityStore:debug()
    local lines = {
        'EntityStore Status:',
        '  Total Mobs: ' .. self:tableCount(self.mobs),
        '  Me: ' .. self.me.name .. ' ' .. self.me.id,
        '  Players: ' .. self:tableCount(self.players),
        '  MTF: ' .. (self.mtf and self.mtf.name or 'nil'),
        '  Aggro: ' .. self:countAggro(),
        '  Targets: ' .. self:countTargets(),
        '  Party: ' .. self:countParty(),
        '  Claim IDs: ' .. T(self.claim_ids):tostring(),
    }
    return table.concat(lines, '\n')
end
function EntityStore:tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

return EntityStore
