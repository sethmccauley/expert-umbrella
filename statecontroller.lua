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
    'postcombat',
    'dead'
}

function StateController:constructState()
    local self = setmetatable({}, StateController)

    self.state = 'idle'
    self.last_state = 'idle'
    self.last_state_time = 0

    self.role = 'master'
    self.assist = nil
    self.last_assist_check = 0

    self.profile = nil
    self.profile_file = ''
    self.route_file = ''
    self.targets_file = ''
    self.domain_file = ''

    self.on_switch = 0

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
function StateController:setProfile(file_contents, file_name)
    if type(file_contents) ~= 'table' then return false end
    self.profile = file_contents
    if file_name and type(file_name) == 'string' then
        self.profile_file = file_name
    end
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

    if self.state == 'combat' or (next(Observer.aggro) ~= nil or next(Observer.targets) ~= nil) then
        if self.state == 'combat' and next(Observer.aggro) == nil and next(Observer.targets) == nil then
            self:setState('postcombat')
            return
        end
        self:setState('combat')
        return
    end

    -- This needs adjustment to include if the current target is an ignorable mob
    if self.state == 'postcombat' or (self.state == 'combat' and next(Observer.aggro) == nil and next(Observer.targets) == nil and next(Observer.mob_to_fight) == nil) then
        notice(Utilities:secondsToReadable(os.clock())..' All targets dead.')
        Actions:emptyToUse()
        self:setState('idle')
        return
    end

    if self.state == 'idle' or self.state == 'travel' then
        Navigation:update()

        if self.role == 'slave' then
            self:determineSlaveTravel(Player, Observer, Navigation)
        end

        if next(Navigation.route) ~= nil then
            if self.state ~= 'travel' then
                if Navigation.current_node <= #Navigation.route then
                    Navigation.current_node = Navigation:determineClosestWaypoint()
                end
            end
            self:setState('travel')
            return
        end
    end

end

function StateController:determineSlaveState(Player, Observer, MobObject)
    if self.assist == nil and (os.clock() - self.last_assist_check) < 0.5 then return end

    if Observer:inParty(self.assist) then
        local mob = Observer:playersTarget(self.assist)
        local assist_status = Observer:playersStatus(self.assist)

        if mob and mob ~= 0 then
            mob = MobObject:constructMob(mob)
        end

        if mob and mob ~= 0 then
            if mob:isValidTarget(Player.mob) and mob:isAllianceClaimed(Observer.claim_ids) then
                if assist_status == 1 then
                    if not Utilities:arrayContains(Observer.aggro, mob.id) then
                        notice(Utilities:secondsToReadable(os.clock())..' Master found target '..mob.name..' '..mob.index..'')
                        Observer:addToAggro(mob.id)
                    end
                    -- if Observer.mob_to_fight and Observer.mob_to_fight.index ~= mob.index then
                    --     Observer:setMobToFight(mob)
                    -- end
                end
            else
                if Utilities:arrayContains(Observer.aggro, mob.id) then
                    for i,v in pairs(self.aggro) do
                        if v.index == mob.index then self.aggro[i] = nil end
                    end
                end
                if Observer.mob_to_fight and Observer.mob_to_fight.index == mob.index then
                    Observer:setMobToFight(T{})
                end
            end
        end
    end
    self:setLastAssistCheckTime()
end

function StateController:determineSlaveTravel(Player, Observer, Navigation)
    if self.assist == nil then return end

    if Observer:inParty(self.assist) then
        local assist_status = Observer:playersStatus(self.assist)
        local assist_pos = Observer:playersPos(self.assist)

        if assist_pos then
            Navigation.route[1] = {['x'] = assist_pos.x, ['y'] = assist_pos.y, ['z'] = assist_pos.z}
        end
    end
end

return StateController