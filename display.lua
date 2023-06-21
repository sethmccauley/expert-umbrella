local Utilities = require('lang/utilities')

local Display = {}
Display.__index = Display
Display.texts = require('texts')

function Display:constructDisplay(Player, Observer, StateController, Actions, Navigation, config) 
    local self = setmetatable({}, Display)

    self.player = Player
    self.observer = Observer
    self.statecontroller = StateController
    self.actions = Actions
    self.navigation = Navigation

    self.display_settings = {}
    self.text_box = {}

    if config then self:setDisplaySettings(config) end

    for box,__ in pairs(self.display_settings) do
        self:createText(box)
    end

	return self
end

function Display:setDisplaySettings(config)
    self.display_settings = config
end
function Display:setVisibility(box_type, visibility)
    if self.display_settings[box_type] then
        self.display_settings[box_type]['visible'] = visibility
    end
end

function Display:createText(box_type)
    self.text_box[box_type] = Display.texts.new(self.display_settings[box_type])
    self.text_box[box_type]:hide()

    if self.text_box[box_type] and self.display_settings[box_type] then
        self:updateText(self.display_settings[box_type]['type'])
    end
end
function Display:updateText(box_type)
    if not self.text_box[box_type] or not self.display_settings[box_type] or not self.display_settings[box_type].visible or not windower.ffxi.get_info().logged_in then
		return
	end

    local information = {}
	local head = L{}

    if self.display_settings[box_type]['type'] == 'agent' then
        head:append('\\cs('..self:labels(box_type)..')'..string.format('%10s','| ${title} | ')..'\\cr')
        head:append(string.format('%-8s','File: ')..string.format('%10s','${file_name|None} '))
        head:append(string.format('%-12s','Step Cnt.: ')..string.format('%10s','${current_step|0}/${total_steps|0}'))
        head:append(string.format('%-12s','Step Type: ')..string.format('%10s','${step_type|N/A}'))
        head:append(string.format('%-12s','Triggered: ')..string.format('%10s','${triggered|false}'))
        head:append(string.format('%-12s','Performed: ')..string.format('%10s','${performed|false}'))
        head:append(string.format('%-12s','Validated: ')..string.format('%10s','${validated|false}'))
        information['title'] = box_type:upper()
        information['triggered'] = nil
        information['performed'] = nil
        information['validated'] = nil
        if next(steps) ~= nil and next(info) ~= nil then
            information['file_name'] = string.sub(info.file_name,1,12)
            information['current_step'] = info.current_step
            information['total_steps'] = #steps
            if steps[info.current_step] then
                information['step_type'] = steps[info.current_step].type or 'None'
                if info.steps[info.current_step] then
                    information['triggered'] = info.steps[info.current_step].triggered or nil
                    information['performed'] = info.steps[info.current_step].performed or nil
                    information['validated'] = info.steps[info.current_step].validated or nil
                end
            end
        end
    end
    if self.display_settings[box_type]['type'] == 'bb' then
        head:append('\\cs('..self:labels(box_type)..') | ${title} | \\cr')
        head:append('\\cs(200,190,220) Character\\cr>  ${player_name|None}                \\cs(200,75,75)Busy\\cr: ${busy|false}')
        head:append(' HP/MP/TP > {\\cs(175,100,100)HPP\\cr: ${player_hpp|0}, \\cs(200,200,100)MPP\\cr: ${player_mpp|0}, \\cs(100,200,200)TP\\cr: ${player_tp|0}}')
        head:append(' Position > {X: ${player_x|0}, Y: ${player_y|0}, Z: ${player_z|0}}')
        head:append('\\cs(150,200,150) State: \\cr'..string.format('%-10s','${state|false} '))
        head:append(' Route Loaded:   '..string.format('%-15s','${route_file|None}')..string.format('%12s',' Nodes: ')..'${route_nodes|0}')
        head:append(' Current Node:   '..string.format('%-15s','${current_node|0} '))
        head:append(' Targets Loaded: '..string.format('%-15s','${targets_file|None}')..string.format('%12s',' Targets: ')..'${target_totals|0}')
        head:append(' Actions Loaded: '..string.format('%-15s','${profile|None}')..string.format('%12s',' #Actions: ')..'${action_totals|0}')

        self.player:update()

        local player = self.player
        local position = self.player.mob or {x=0,y=0,z=0}

        information.title = box_type:upper()
        information.player_name = player.name
        information.player_status = Utilities.res.statuses[player.status].en
        information.player_hpp = player.vitals.hpp
        information.player_mpp = player.vitals.mpp
        information.player_tp = player.vitals.tp
        information.player_x = string.format('%.2f', tostring(position.x or 0))
        information.player_y = string.format('%.2f', tostring(position.y or 0))
        information.player_z = string.format('%.2f', tostring(position.z or 0))
        information.busy = self.observer.is_busy

        if self.statecontroller.profile_file then information.profile = string.format('%-15s', self.statecontroller.profile_file) end

        information.route_file = string.format('%-15s','None')
        information.targets_file = string.format('%-15s','None')
        information.state = self.statecontroller.state

        if self.statecontroller.route_file ~= '' then
            information.route_file = string.sub(string.format('%-15s',self.statecontroller.route_file),1,15)
            information.route_nodes = #self.navigation.route
            information.current_node = self.navigation.current_node
        end
        if self.statecontroller.targets_file ~= '' then
            information.targets_file = string.sub(string.format('%-15s',self.statecontroller.targets_file),1,15)
            information.target_totals = #self.observer.target_list.name + #self.observer.target_list.hex
        end
        if self.actions then
            information.action_totals = #self.actions.combat_actions + #self.actions.precombat_actions + #self.actions.postcombat_actions + #self.actions.noncombat_actions
        end
    end

    if self.display_settings[box_type]['type'] == 'to use' then
        head:append('\\cs(150,255,150)| ${title} | \\cr')
        local collection = T{}
        if next(self.actions.to_use) ~= nil then
            for _,v in pairs(self.actions.to_use) do
                collection:append(v.name)
            end
        end
        head:append(T(collection):tovstring())

        information.title = box_type:upper()
    end

    if self.text_box[box_type] then
        self.text_box[box_type]:clear()
        self.text_box[box_type]:append(head:concat('\n'))
        self.text_box[box_type]:append('\n')
        self.text_box[box_type]:update(information)

        if self.display_settings[box_type].visible then
            self.text_box[box_type]:show()
        end
    end
end

function Display:labels(this)
    local r, b, g = 255, 255, 255

    if self.display_settings.label[this] then
        r = self.display_settings.label[this].red or 255
        b = self.display_settings.label[this].blue or 255
        g = self.display_settings.label[this].green or 255
    end

    return tostring(r)..','..tostring(g)..','..tostring(b)
end

function Display:destroy()
    for i,v in pairs(self.text_box) do
        v:destroy()
    end
end

return Display