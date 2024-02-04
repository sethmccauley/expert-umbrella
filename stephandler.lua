local StepHandler = {}
StepHandler.__index = StepHandler

local Utilities = require('lang/utilities')

StepHandler._triggers = T{
    'pos','posisnt','text','sparksoraccoladesgt',
    'sparksgt','sparkslt','accoladesgt','accoladeslt','gilgt','gillt','conquestsgt','conquestwgt','conquestbgt',
    'haveitem','zoneis','zoneisnt','NPC','itemequipped','chargeready',
    'validtarget','haski','meritsgt','meritslt','buffpresent','buffabsent',
    'partyispresent',
    'usabledistance',
    'wait',
}

StepHandler._actionTypes = T{
    'raw',
    'pos',
    '01A',
    'send_packet',
    'goto',
    'stop',
}

function StepHandler:constructHandler(Observer, Player, Navigation)
    local self = setmetatable({}, StepHandler)

    self.observer = Observer
    self.player = Player
    self.navigation = Navigation

    self.steps = T{}
    self.fileName = ''

    self.stepQueue = T{}

    self.switch = false
    self.busy = false
    self.verbose = false
    self.state = 'None'

    self.loop = false
    self.loopTime = 0
    self.startTime = 0
    self.currentStep = 1
    self.stepNames = T{}

    self.startTime = 0

    self.shortCourse = T{['current_node'] = 0, ['steps'] = T{}}
    self.awaitedText = T{['active'] = false, ['value'] = '', ['received'] = false}
    self.awaitedPacket = T{['active'] = false, ['index'] = 0, ['received'] = false, ['return'] = false}
    self.receivedPacket = T{}

    self.lastIssuer = Player.name
    self.lastIssuerNotified = false

    return self
end

function StepHandler:setCurrentStep(value)
    local found_step = value or 1
    if type(value) == 'string' then
        if self.stepNames[value] then
            found_step = self.stepNames[value]
        end
    end
    self.currentStep = found_step
end
function StepHandler:setState(value)
    self.state = value
end
function StepHandler:setSwitch(value)
    self.switch = value
end
function StepHandler:setStartTime(value)
    self.startTime = value
end
function StepHandler:setBusy(value)
    self.busy = value or false
end
function StepHandler:setZoning()
    if self.switch then
        self:setState('zoneing')
        coroutine.schedule(function() self:setBusy(false) end, 8)
    end
end
function StepHandler:setStepList(steps)
    self.steps = steps
    for i=1,#steps,1 do
        self.stepQueue[i] = {['triggered'] = false, ['performed'] = false, ['executed'] = 0, ['validated'] = false, ['skipped'] = false, ['notified'] = false}
    end
    self:buildStepNames()
end
function StepHandler:setStepFile(name)
    self.fileName = name
end
function StepHandler:buildStepNames()
    self.stepNames = T{}
    for i,v in ipairs(self.steps) do
        if v.name or v.nickname then
            local step_name = v.name or v.nickname
            self.stepNames[step_name] = i
        end
    end
end
function StepHandler:setVerbosity(value)
    self.verbose = value
end
function StepHandler:setLoop(value)
    self.loop = value
end
function StepHandler:setLoopTime(value)
    self.loopTime = value
end
function StepHandler:resetStepState()
    self.state = 'None'
    self.fileName = ''
    self.currentStep = 0
    self.steps = T{}
    self.stepQueue = T{}
end
function StepHandler:setIssuer(name)
    local me = self.player.name
    self.lastIssuer = name
    if name == me then
        self.lastIssuerNotified = true
    else
        self.lastIssuerNotified = false
    end
end

function StepHandler:handleStep()
    local active_step = self.currentStep or 0
    local max_steps = #self.steps
    local task = self.steps[active_step] or nil

    if self.state ~= 'idle' then return end

    -- Current Step Check
    if task then
        if active_step == 1 then
            -- Set up our Start Time
            if self.startTime == 0 then
                self.startTime = os.clock()
            end
        end
        if not self.stepQueue[active_step] then
            self.stepQueue[active_step] = {
                ['triggered'] = false,
                ['performed'] = false,
                ['executed'] = 0,
                ['validated'] = false,
                ['skipped'] = false,
                ['notified'] = false,
            }
        end
    else
        if self.loop then
            if (os.clock() - self.startTime) > tonumber(self.loopTime) then
                self.currentStep = 1
                self.startTime = 0
                self.stepQueue = T{}
            end
        end
        return
    end

    -- Trigger Checking (Have trigger and not yet triggered and not yet performed)
    if task.trigger and next(task.trigger) ~= nil and not self.stepQueue[active_step].triggered then
        local trigger_success = self:validateCondition(task, 'trigger')

        if not trigger_success then
            if task.trigger.skip_on_fail and (task.trigger.skip_on_fail == 'yes' or task.trigger.skip_on_fail) then
                self.stepQueue[active_step].skipped = true
                self.currentStep = self.currentStep + 1
            end
            return
        else
            self.stepQueue[active_step].triggered = true
        end
    else
        self.stepQueue[active_step].triggered = true
    end

    -- Action Instigation (Have step_type and triggered and not performed)
    if task.type and task.action and self.stepQueue[active_step].triggered and not self.stepQueue[active_step].performed and not self.busy then
        self:executeTask(task)

        if active_step ~= self.currentStep then
            return
        end
    end

    -- Action Success Test (if validate and have performed, test based on action type)
    if task.validation and next(task.validation) ~= nil and self.stepQueue[active_step].performed then
        local validation_success = self:validateCondition(task, 'validation')

        if validation_success then
            self.stepQueue[active_step].validated = true
            self.currentStep = self.currentStep + 1
        else
            if task.timeout and task.timeout == 0 then task.timeout = nil end
            if (os.clock() - self.stepQueue[active_step].executed) > (task.timeout or 30) then
                -- Create a fail case condition
                if task.timeout_type == "goto" and task.timeout_step then
                    self:goToStep(task.timeout_step)
                else
                    self.stepQueue[active_step].performed = false
                end
            end
        end
    else
        self.currentStep = self.currentStep +1
    end
end

function StepHandler:goToStep(step)
    local cur_step = self.currentStep
    local step_lookup = 0

    if type(step) == 'string' then
        if self.stepNames and self.stepNames[step] then
            step_lookup = self.stepNames[step]
        end
    else
        step_lookup = step
    end

    if tonumber(step_lookup) < tonumber(cur_step) then
        for i=step_lookup,cur_step,1 do
            self.stepQueue[i] = {['triggered'] = false, ['performed'] = false, ['executed'] = 0, ['validated'] = false, ['skipped'] = false}
        end
    end
    self.currentStep = step_lookup
    self.stepQueue[step_lookup] = {['triggered'] = false, ['performed'] = false, ['executed'] = 0, ['validated'] = false, ['skipped'] = false}
end

function StepHandler:validateCondition(step, operation)
    local validation = false

    local task = step or nil
    if task == nil then notice('No task passed to trigger test.') return end
    local operation = operation or 'trigger'
    local type_ref = operation and task[operation].type or task.trigger.type
    if not Utilities:arrayContains(self._triggers, type_ref) then self:NotifyLast('No type of '..type_ref..' found in conditions.') return end

    local world = windower.ffxi.get_info()
    local value = operation and task[operation].value or task.trigger.value

    local func_map = {
        ['pos'] = function(value)
            if next(value) ~= nil then
                if value.x and value.y and value.z and Observer:distanceBetween(value, self.player.mob) < 2 and Observer:differenceZ(value, self.player.mob) < 2 then
                    return true
                end
            end
            return false
        end,
        ['posisnt'] = function(value)
            if next(value) ~= nil then
                if value.x and value.y and value.z and Observer:distanceBetween(value, self.player.mob) > 2 then
                    self.stepQueue[self.currentStep].triggered = true
                end
            end
            return false
        end,
        ['text'] = function(value) -- In line adjustments for handling incoming triggers.
            if not Utilities:isBlank(value) then
                self.awaitedText.active = true
                self.awaitedText.value = value
                if self.awaitedText.received then
                    self.stepQueue[self.currentStep].triggered = true
                    self.awaitedText = T{['active'] = false, ['value'] = '', ['received'] = false}
                end
                return false
            end
        end,
        ['sparksoraccoladesgt'] = function(value)
            if not Utilities:isBlank(value) then
                if (tonumber(self.sparks) > tonumber(value)) or (tonumber(self.accolades) > tonumber(value)) then return true end
            end
            return false
        end,
        ['accoladesgt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.accolades) > tonumber(value) then return true end
            end
            return false
        end,
        ['accoladeslt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.accolades) < tonumber(value) then return true end
            end
            return false
        end,
        ['sparksgt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.sparks) > tonumber(value) then return true end
            end
            return false
        end,
        ['sparkslt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.sparks) < tonumber(value) then return true end
            end
            return false
        end,
        ['gilgt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.gil) > tonumber(value) then return true end
            end
            return false
        end,
        ['gillt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.gil) < tonumber(value) then return true end
            end
            return false
        end,
        ['conquestsgt'] =  function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.conquest.s) > tonumber(value) then return true end
            end
            return false
        end,
        ['conquestbgt'] =  function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.conquest.b) > tonumber(value) then return true end
            end
        end,
        ['conquestwgt'] =  function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.conquest.w) > tonumber(value) then return true end
            end
            return false
        end,
        ['haveitem'] = function(value)
            if not Utilities:isBlank(value) then
                local resolved_item = Utilities.res.items:with('en',value:lower()) or Utilities.res.items:with('enl',value:lower()) or nil
                if resolved_item and Utilities:haveItem(resolved_item) then return true end
            end
            return false
        end,
        ['zoneis'] = function(value)
            if not Utilities:isBlank(value) then
                if world.zone == value then return true end
            end
            return false
        end,
        ['zoneisnt'] = function(value)
            if not Utilities:isBlank(value) then
                if world.zone ~= value then return true end
            end
            return false
        end,
        ['NPC'] = function(value) -- In line adjustments for handling incoming packet based triggers.
            if not Utilities:isBlank(value) then
                self.awaitedPacket.active = true
                local targ = self.observer:pickNearest(self.observer:getMArray(task[operation].npc))
                if targ and targ.index then
                    self.awaitedPacket.index = targ.index
                end
                if task.trigger['return'] then
                    self.awaitedPacket['return'] = true
                end
                if self.awaitedPacket.received then
                    self.stepQueue[self.currentStep].triggered = true
                    self.awaitedPacket = T{['active'] = false, ['index'] = 0, ['received'] = false, ['return'] = false,}
                end
                return false
            end
        end,
        ['itemequipped'] = function(value)
            if not Utilities:isBlank(value) then
                if Utilities:isEquipped(value) then return true end
            end
            return false
        end,
        ['chargeready'] = function(value)
            if not Utilities:isBlank(value) then
                if Utilities:isEquipped(value) and Utilities:isUsable(value) then return true end
            end
            return false
        end,
        ['validtarget'] = function(value)
            if not Utilities:isBlank(value) then
                local party_ids = self.observer.claim_ids
                local entities = self.observer:getMArray(value) or {['name'] = 'none', ['index'] = '0'}
                for i,v in pairs(entities) do
                    local mob = windower.ffxi.get_mob_by_index(v.index)
                    if mob and mob.valid_target and mob.hpp > 0 and mob.status ~= 3 and (party_ids:contains(mob.claim_id) or mob.claim_id == 0) and self.observer:differenceZ(mob, self.player.mob) < 6 and (mob.spawn_type == 16 or mob.spawn_type == 2) then
                        return true
                    end
                end
                return false
            end
            return false
        end,
        ['usabledistance'] = function(value)
            if not Utilities:isBlank(value) then
                local entities = self.observer:getMArray(value, true) or {['name'] = 'none', ['index'] = '0'}
                for i,v in pairs(entities) do
                    local mob = windower.ffxi.get_mob_by_index(v.index)
                    if mob and mob.valid_target and mob.hpp > 0 and mob.status ~= 3 and self.observer:differenceZ(mob, self.player.mob) < 6 and (mob.spawn_type == 16 or mob.spawn_type == 2) and self.observer:distanceBetween(mob, self.player.mob) < 5 then
                        return true
                    end
                end
                return false
            end
            return false
        end,
        ['haski'] = function(value)
            if not Utilities:isBlank(value) then
                if Utilities:haveKI(value) then return true end
            end
            return false
        end,
        ['meritsgt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.merits) > tonumber(value) then return true end
            end
            return false
        end,
        ['meritslt'] = function(value)
            if not Utilities:isBlank(value) then
                if tonumber(self.observer.merits) < tonumber(value) then return true end
            end
            return false
        end,
        ['buffpresent'] = function(value)
            if not Utilities:isBlank(value) then
                self.player:update()
                if self.player:has_buff(value) then return true end
            end
            return false
        end,
        ['buffabsent'] = function(value)
            if not Utilities:isBlank(value) then
                self.player:update()
                if not self.player:has_buff(value) then return true end
            end
            return false
        end,
        ['partyispresent'] = function() return Utilities:partyIsPresent() end,
        ['wait'] = function(value)
            if not Utilities:isBlank(value) then
                if (os.clock() - self.stepQueue[self.currentStep].executed) > (value) then
                    return true
                end
            end
            return false
        end,
    }

    if func_map[type_ref] ~= nil then
        validation = func_map[type_ref](value)
    end

    return validation
end

function StepHandler:executeTask(task)
    local task = task or nil
    if task == nil then notice('No task passed to task execution.') return end
    if Utilities:isBlank(task.type) then notice('Task type missing, type must be declared.') return end
    local type = task.type
    local action = task.action
    local player = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index)
    local world = windower.ffxi.get_info()
    local go_flag = false

    local func_map = {
        ['pos'] = function(task)
            if next(task.action) == nil then return end
            self.navigation:setShortCourse(task.action)
            self.navigation:setNeedClosestNode(true)
            self.navigation:update()
            self:setState('pos')
        end,
        ['01A'] = function(task)
            if Utilities:isBlank(task.action) then return end
            local target = self.observer:pickNearest(self.observer:getMArray(action))
            if target and target.id then
                self:pokeNPC(target.id, target.index)
            end
        end,
        ['raw'] = function(task)
            windower.send_command(task.action)
        end,
        ['send_packet'] = function(task)
            if next(task.action) == nil then return end
            self:sendPacket(task.action)
        end,
        ['goto'] = function(task)
            if Utilities:isBlank(task.action) then return end
            go_flag = true
        end,
        ['update'] = function()
            self.observer:queueCurrencyUpdate()
        end,
        ['stop'] = function()
            self.switch = 0
            self:resetStepState()
        end
    }

    if func_map[type] ~= nil then
        func_map[type](task)
    end

    if self.switch == 0 then return end

    if task.state then -- Used for zoning actions mostly.
        self.state = task.state
    end

    self.stepQueue[self.currentStep].executed = os.clock()
    self.stepQueue[self.currentStep].performed = true
    if go_flag then
        self:goToStep(task.action)
    end
end

function StepHandler:packetDelegate(id,data,modified,injected,blocked)
    if id == 0x034 then -- Mog Garden NPC Interaction Tests
        local p = packets.parse('incoming', data)
        if (p['Menu ID'] == 1012 or p['Menu ID'] == 1013 or p['Menu ID'] == 1014) and p['Zone'] == 280 then
            local i = p['Menu Parameters']:unpack('I', 13)
            local min = math.floor(i / 60)..":"..string.format("%02d", (i % 60))
            notice(min)
        end
    end
    if id == 0x110 then -- Update Current Sparks via 110
        local p = packets.parse('incoming',data)
        self.observer:setCurrency('sparks', p['Sparks Total'])
    end
    if id == 0x113 then  -- Update Current Accolades
        local p = packets.parse('incoming',data)
        self.observer:setCurrency('accolades', p['Unity Accolades'])
    end
	if id == 0x113 then
        local p = packets.parse('incoming',data)
        self.observer:setCurrency({['name'] = 'conquest', ['sub'] = 's'}, p['Conquest Points (San d\'Oria)'])
        self.observer:setCurrency({['name'] = 'conquest', ['sub'] = 'b'}, p['Conquest Points (Bastok)'])
        self.observer:setCurrency({['name'] = 'conquest', ['sub'] = 'w'}, p['Conquest Points (Windurst)'])
	end
    if id == 0x061 then
        local calc_val = math.floor(data:byte(0x5A)/4) + data:byte(0x5B)*2^6 + data:byte(0x5C)*2^14
        self.observer:setCurrency('accolades', calc_val)
    end
    if id == 0x63 and data:byte(5) == 2 then
        -- local current = data:unpack('H',9)
        self.observer:setCurrency('merits', data:byte(11)%128)
        -- local maximum_merits = data:byte(0x0D)%128
    end
    if id == 0x02D then -- Looking for incoming Merit Msg Information
        local p = packets.parse('incoming', data)

        local self = windower.ffxi.get_player()
        if p['Player'] == self.id and p['Target'] ~= self.id and p['Message'] == 50 then
            self.observer:setCurrency('merits',  p['Param 1'])
        end
    end
    if not self.switch then return end
    if id == 0x034 or id == 0x032 then -- Incoming NPC interaction
        local r_type = false
        if self.awaitedPacket.active and not self.awaitedPacket.received then
            local p = packets.parse('incoming',data)
            if p['NPC Index'] == self.awaitedPacket.index then
                self.awaitedPacket.received = true
                r_type = self.awaitedPacket['return']
                for i,v in pairs(p) do
                    self.receivedPacket[i] = v
                end
            end
        end
        if r_type then
            return r_type
        else
            return
        end
    end
end
function StepHandler:incomingTextDelegate(original, modified, original_mode, modified_mode, blocked)
    if not self.switch then return end
    local msg = original:lower();
    if self.awaitedText.active then
        if msg:find(self.awaitedText.value:lower()) then
            self.awaitedText.received = true
        end
    end
end

function StepHandler:sendPacket(task)
    local packet_col = task
    if not packet_col then notice('Missing arguments within action field for current step.') return end
    local player = self.player
    player:update()
    for i,v in ipairs(packet_col) do
        if not v['packet_type'] then return end
        coroutine.sleep(.5)
        local packet = packets.new('outgoing', v['packet_type'])

        if v['packet_type'] == 0x05B or v['packet_type'] == 0x05C then
            packet['Target'] = v['Target'] or self.receivedPacket['NPC']
            packet['Target Index'] = v['Target Index'] or self.receivedPacket['NPC Index']
            packet['Menu ID'] = v['Menu ID'] or self.receivedPacket['Menu ID']
            packet['Zone'] = v['Zone'] or self.receivedPacket['Zone']
        end

        for key,val in pairs(v) do
            if key ~= 'packet_type' then
                if val == 'self.id' then
                    val = tonumber(player.id)
                elseif val == 'self.index' then
                    val = tonumber(player.index)
                end
                packet[key] = val or self.receivedPacket[key]
            end
        end
        packets.inject(packet)
    end
    self.receivedPacket = T{}
end
function StepHandler:pokeNPC(id, index)
	if id and index then
		local packet = packets.new('outgoing', 0x01A, {
			["Target"]=id,
			["Target Index"]=index,
			["Category"]=0,
			["Param"]=0,
			["_unknown1"]=0})
		packets.inject(packet)
	end
end

function StepHandler:notifyLast(message)
    local me = self.player.name
    if self.lastIssuer ~= me and self.lastIssuerNotified == false then
        windower.send_command('input /t '..self.lastIssuer..' '..message)
        self:setIssuer(me)
    end
end

return StepHandler