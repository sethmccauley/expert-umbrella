--[[

    Text Controls
    
]]

langly_text_ver = 1.12
langly_text_date = '11.8.2018'

function initialize_texts()
    for box,__ in pairs(settings.display) do
        create_text(box)
    end
end

function create_text(box_type)
    local t_settings = settings.display[box_type]

    text_box[box_type] = texts.new(t_settings)
    text_box[box_type]:hide()
    update_text(text_box[box_type])
end

function update_text(box_type)
	if not text_box[box_type] or not settings.display[box_type] or not settings.display[box_type].visible or not windower.ffxi.get_info().logged_in then
		return
	end

    local information = {}
	local head = L{}

    if settings.display[box_type]['type'] == 'agent' then
        head:append('\\cs('..labels(box_type)..')'..string.format('%10s','| ${title} | ')..'\\cr')
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
    
    if settings.display[box_type]['type'] == 'bb' then
        head:append('\\cs('..labels(box_type)..') | ${title} | \\cr')
        head:append('\\cs(200,190,220) Character\\cr>  ${player_name|None}                \\cs(200,75,75)Busy\\cr: ${busy|false}')
        head:append(' HP/MP/TP > {\\cs(175,100,100)HPP\\cr: ${player_hpp|0}, \\cs(200,200,100)MPP\\cr: ${player_mpp|0}, \\cs(100,200,200)TP\\cr: ${player_tp|0}}')
        head:append(' Position > {X: ${player_x|0}, Y: ${player_y|0}, Z: ${player_z|0}}')
        head:append('\\cs(150,200,150) State: \\cr'..string.format('%-10s','${state|false} ')..string.format('%31s',' Current Node: ')..'${current_node|0} ')
        head:append(' Route Loaded:   '..string.format('%-15s','${route_file|None}')..string.format('%12s',' Nodes: ')..'${route_nodes|0}')
        head:append(' Targets Loaded: '..string.format('%-15s','${target_file|None}')..string.format('%12s',' Targets: ')..'${target_totals|0}')
        head:append(' Actions Loaded: '..string.format('%-15s','${profile|None}')..string.format('%12s',' #Actions: ')..'${action_totals|0}')
        
        local player = windower.ffxi.get_player()
        local position = windower.ffxi.get_mob_by_index(player.index) or {x=0,y=0,z=0}
        information.title = box_type:upper()
        information.player_name = player.name
        information.player_status = res.statuses[player.status].en
        information.player_hpp = player.vitals.hpp
        information.player_mpp = player.vitals.mpp
        information.player_tp = player.vitals.tp
        information.player_x = string.format('%.2f', tostring(position.x or 0))
        information.player_y = string.format('%.2f', tostring(position.y or 0))
        information.player_z = string.format('%.2f', tostring(position.z or 0))
        if info.profile then information.profile = string.format('%-15s',info.profile) end
        information.route_file = string.format('%-15s','None')
        information.target_file = string.format('%-15s','None')
        information.state = info.state
        if route.route_file then
            information.route_file = string.sub(string.format('%-15s',route.route_file),1,15)
            information.route_nodes = route.route_nodes
            information.current_node = route.current_node
        end
        if targets.target_file then
            information.target_file = string.sub(string.format('%-15s',targets.target_file),1,15)
            information.target_totals = targets.target_totals
        end
        if info.settings then
            information.action_totals = #info.settings.combat + #info.settings.noncombat + #info.settings.precombat + #info.settings.postcombat
            targets.target_totals = #targets.settings.names.name + #targets.settings.names.hex
        end
    end
    
    if settings.display[box_type]['type'] == 'to use' then
        head:append('\\cs(150,255,150)| ${title} | \\cr')
        head:append(T(to_use):tovstring())
        
        information.title = box_type:upper()
    end
    
    if text_box[box_type] then
        text_box[box_type]:clear()
        text_box[box_type]:append(head:concat('\n'))
        text_box[box_type]:append('\n')
        text_box[box_type]:update(information)
        
        if settings.display[box_type].visible then
            text_box[box_type]:show()
        end
    end    
end

function labels(this)
    local r, b, g = 255, 255, 255
    
    if defaults.label[this] then
        r = defaults.label[this].red or 255
        b = defaults.label[this].blue or 255
        g = defaults.label[this].green or 255
    end
    
    return tostring(r)..','..tostring(g)..','..tostring(b)
end

function update_texts()
    for v,__ in pairs(text_box) do
        update_text(v)
    end
end