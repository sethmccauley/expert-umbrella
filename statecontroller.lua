local StateController = {}
StateController.__index = StateController

local Utilities = require('lang/utilities')

StateController._roles = S{
    'master',
    'slave'
}

StateController._allowedStates = S{
    'idle',
    'travel',
    'precombat',
    'combat',
    'combat positioning',
    'postcombat',
    'dead',
}

function StateController:constructState()
    local self = setmetatable({}, StateController)

    self.state = 'idle'
    self.last_state = 'idle'
    self.last_state_time = 0

    self.role = 'master'
    self.assist = nil
    self.assist_last_pos = nil
    self.catch_up_node_pushed = false
    self.last_assist_check = 0

    self.allow_combat_movement = true
    self.follow_master = true

    self.profile = nil
    self.current_style = 'default'
    self.profile_file = ''
    self.route_file = ''
    self.targets_file = ''
    self.domain_file = ''

    self.on_switch = 0

    self.frog = false

    return self
end

function StateController:setOnSwitch(value)
    if value == nil or (value > 1 or value < 0) then return end
    self.on_switch = value
end
function StateController:setState(new_state)
    if self.state == new_state then return true end
    if not StateController._allowedStates:contains(new_state) then return false end

    self.last_state = self.state
    self.state = new_state
    self.last_state_time = os.clock()
end
function StateController:setLastState(old_state)
    self.last_state = old_state
end
function StateController:setRole(role, assist)
    if not StateController._roles:contains(role) then return false end

    self.role = role
    if role == 'master' then
        self.assist = nil
    end

    if role == 'slave' then
        if not assist then return false end
        self.assist = assist
    end
end
function StateController:setProfile(file_contents, file_name, Actions)
    if type(file_contents) ~= 'table' then return false end

    if file_name and type(file_name) == 'string' then
        self.profile_file = file_name
    end

    -- Check if new format, migrate if not
    if not self:isNewStyleFormat(file_contents) then
        file_contents = self:migrateToNewFormat(file_contents, file_name)
    end

    -- Merge global + default style into working profile
    self.profile = self:mergeStyle(file_contents, 'default')
    self.current_style = 'default'

    -- Apply role/assist from merged profile
    if self.profile.role and self.profile.assist and self.profile.assist ~= '' then
        self:setRole('slave', self.profile.assist)
    end

    self.allow_combat_movement = self.profile.allow_combat_movement ~= false
end
function StateController:setRouteFile(file_name)
    if type(file_name) ~= 'string' then return false end
    self.route_file = file_name
end
function StateController:setTargetsFile(file_name)
    if type(file_name) ~= 'string' then return false end
    self.targets_file = file_name
end
function StateController:setDomainFile(file_name)
    if type(file_name) ~= 'string' then return false end
    self.domain_file = file_name
end
function StateController:setLastAssistCheckTime()
    self.last_assist_check = os.clock()
end
function StateController:setFollowMaster(value)
    if type(value) ~= 'boolean' then return nil end
    self.follow_master = value
end
function StateController:setCombatMovement(value)
    if type(value) ~= 'boolean' then return nil end
    self.allow_combat_movement = value
end

function StateController:determineState(Player, Observer, Actions, Navigation, MobObject)
    -- States: (idle | travel) >> (Pre | Combat | Post) >> (idle | travel)
    --
    --  (PreCombat|Combat) Trigger:
    --  Aggro Table, Targets table are populated
    --      *Clear precombat table upon range detection of mob.
    --      *Clear Combat Tables Upon mob_to_fight death.
    --
    --  (PostCombat) Trigger:
    --  Aggro table, Targets table, mob_to_fight are empty
    --      *Clear PostCombat (once per) table when before returning to idle/travel.
    --
    --  (Idle|Travel) Trigger:
    --  Aggro Table, Targets table, mob_to_fight are empty and post combat actions have been processed.
    --      *Clear noncombat (once per) table when moving to combat

    local haveAggro = next(Observer.aggro)
    local haveTargets = next(Observer.targets)
    local haveMTF = next(Observer.mob_to_fight)

    if self.state == 'combat positioning' then
        if next(Observer.combat_positioning) ~= nil then
            if Observer:distanceBetween(Player.mob, Observer.combat_positioning) < .7 then
                Observer:setCombatPosition(nil,nil)
                Observer:forceUnbusy()
                self:setState('combat')
            end
        else
            self:setState('combat')
            return
        end
        return
    end

    -- Slave Adjustment
    local shouldEnterCombat = (haveAggro ~= nil or haveTargets ~= nil or haveMTF ~= nil)
    if self.role == 'slave' then
        shouldEnterCombat = (haveMTF ~= nil)
    end

    if self.state == 'combat' or shouldEnterCombat then
        if self.state == 'combat' and haveAggro == nil and haveTargets == nil and haveMTF == nil then
            self:setState('postcombat')
            return
        end
        self:setState('combat')
        return
    end

    -- This needs adjustment to include if the current target is an ignorable mob
    if self.state == 'postcombat' or (self.state == 'combat' and haveAggro == nil and haveTargets == nil and haveMTF == nil) then
        notice(Utilities:printTime()..' All targets dead.')
        Actions:emptyToUse()
        Actions:emptyOncePerCombat()
        if self.role == 'slave' then
            Navigation:setShortCourse({})
        end
        self:setState('idle')
        return
    end

    if self.state == 'idle' or self.state == 'travel' then
        Navigation:update()

        if next(Navigation.route) ~= nil then
            if self.state ~= 'travel' then
                if Navigation.current_node <= #Navigation.route then
                    Navigation:setNeedClosestNode(true)
                    Navigation:update()
                end
            end
            self:setState('travel')
            return
        end
    end

end

function StateController:determineSlaveTravel(Player, Observer, Navigation)
    if self.assist == nil then return end
    if Observer.multi_box_present and Observer.local_entities:contains(self.assist:lower()) then return end

    if Observer:inParty(self.assist) and Observer:memberInZone(self.assist) then

        local assist_status = Observer:playersStatus(self.assist)
        local assist_pos = Observer:playersPos(self.assist)

        if not assist_pos then return end

        local assist_height_difference = Navigation:heightDifference(assist_pos.z or 0)
        -- First if they're on a different height than us don't attempt to chase after them. I guess.
        if (assist_height_difference >= 8) then
            return false
        end
        -- Second if they're too far away, don't attempt to track them. I guess.
        local distance_to_assist = Navigation:distanceTo(assist_pos.x, assist_pos.y)
        if distance_to_assist >= 30 then
            return false
        end

        local assist_pos_difference = 0
        if self.assist_last_pos then
            assist_pos_difference = Navigation:distanceBetween(assist_pos, self.assist_last_pos)
        else
            self.assist_last_pos = assist_pos
        end

        if assist_pos and assist_pos_difference >= 2.75 then
            self.assist_last_pos = assist_pos
            Navigation:pushNode(assist_pos)
            -- Navigation.route[1] = {['x'] = assist_pos.x, ['y'] = assist_pos.y, ['z'] = assist_pos.z}
        elseif assist_pos_difference <= 0.4 and distance_to_assist > 4 and distance_to_assist < 30 then
            if not self.catch_up_node_pushed then
                local catch_up = {x = assist_pos.x, y = assist_pos.y, z = assist_pos.z, tolerance = 2.5}
                Navigation:pushNode(catch_up)
                self.catch_up_node_pushed = true
            end
        else
            if assist_pos_difference >= 0.5 then
                self.catch_up_node_pushed = false
            end
        end

    end
end

function StateController:isNewStyleFormat(profile)
    return profile and profile['global'] ~= nil
end
function StateController:getAvailableStyles()
    -- Re-read raw profile from file
    local raw_profile = require('data/'..self.profile_file)
    package.loaded['data/'..self.profile_file] = nil

    if not self:isNewStyleFormat(raw_profile) then return {'default'} end
    local styles = {}
    for key, _ in pairs(raw_profile) do
        if key ~= 'global' then
            table.insert(styles, key)
        end
    end
    table.sort(styles)
    return styles
end
function StateController:mergeStyle(profile, style_name)
    if not self:isNewStyleFormat(profile) then return profile end

    local global = profile['global'] or {}
    local style = profile[style_name] or {}
    local merged = {}

    -- Copy all global settings first
    for key, value in pairs(global) do
        if type(value) == 'table' then
            merged[key] = T(value):copy()
        else
            merged[key] = value
        end
    end

    -- Override/merge with style-specific settings
    for key, value in pairs(style) do
        if type(value) == 'table' and type(merged[key]) == 'table' then
            -- For arrays like combat/noncombat, concatenate style actions after global
            if key == 'combat' or key == 'noncombat' or key == 'precombat' or key == 'postcombat' or key == 'trusts' then
                for _, v in ipairs(value) do
                    table.insert(merged[key], v)
                end
            else
                -- For other tables, do a shallow merge
                for k, v in pairs(value) do
                    merged[key][k] = v
                end
            end
        else
            merged[key] = value
        end
    end

    return merged
end
function StateController:migrateToNewFormat(profile, profile_file)
    if self:isNewStyleFormat(profile) then return profile end

    local new_format = {
        ['global'] = profile,
        ['default'] = {
            ['combat'] = {},
            ['noncombat'] = {}
        }
    }
    local file = files.new('data/'..profile_file..'.lua')
    file:write('return ' .. T(new_format):tovstring())
    notice('Profile migrated to new styles format.')

    return new_format
end
function StateController:applyStyle(style_name, Actions, Navigation)
    -- Re-read raw profile from file
    local raw_profile = require('data/'..self.profile_file)
    package.loaded['data/'..self.profile_file] = nil

    if not self:isNewStyleFormat(raw_profile) then
        notice('Profile does not support styles. Please update your profile format.')
        return false
    end

    local styles = self:getAvailableStyles()
    local found = false
    for _, s in ipairs(styles) do
        if s == style_name then found = true break end
    end

    if not found then
        notice('Style "'..style_name..'" not found.')
        notice('Available styles: '..table.concat(styles, ', '))
        return false
    end

    local merged = self:mergeStyle(raw_profile, style_name)
    self.profile = merged
    self.current_style = style_name

    -- Apply profile settings
    self.allow_combat_movement = merged.allow_combat_movement ~= false
    if merged.role and merged.assist and merged.assist ~= '' then
        self:setRole('slave', merged.assist)
    end

    -- Rebuild actions
    Actions:setActionList(self.profile)

    -- Re-apply slave settings if needed
    if self.assist ~= nil and self.role == 'slave' then
        Navigation.pause = 999999
        Navigation.node_tolerance = 2
        Navigation:setMode('slave')
    end

    notice('Style "'..style_name..'" applied.')
    return true
end

return StateController