local Utilities = require('lang/utilities')

local Display = {}
Display.__index = Display
Display.texts = require('texts')
Display.images = require('images')

function Display:constructDisplay(Player, Observer, StateController, Actions, Navigation, config)
    local self = setmetatable({}, Display)

    self.player = Player
    self.observer = Observer
    self.statecontroller = StateController
    self.actions = Actions
    self.navigation = Navigation

    self.display_settings = {}
    self.text_box = {}
    self.images = {}

    -- Storage for new-style image-backed displays (keyed by box_type)
    self.image_displays = {}

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
        self:updateText(self.display_settings[box_type]['type'], true)
    end
    if box_type == 'bb' then
        local pos_x = self.display_settings[box_type].pos and self.display_settings[box_type].pos.x or 300
        local pos_y = self.display_settings[box_type].pos and self.display_settings[box_type].pos.y or 300
        self:createImageDisplay(box_type, pos_x, pos_y, nil, self.display_settings)
    end
end
function Display:createImageBackedDisplay(box_type)
    local settings = self.display_settings[box_type]
    local pos_x = settings.pos.x or 0
    local pos_y = settings.pos.y or 0

    self.images = self.images or {}

    local y_offset = 0
    local bg_height = 16  -- height per bg tile row

    -- Top bar
    self.images[box_type..'_top'] = Display.images.new({
        texture = {path = 'data/assets/top.png'},
        pos = {x = pos_x, y = pos_y + y_offset},
        size = {width = 300}
    })
    y_offset = y_offset + 20  -- top image height

    -- 4x bg tiles
    for i = 1, 4 do
        self.images[box_type..'_bg'..i] = Display.images.new({
            texture = {path = 'data/assets/bg.png'},
            pos = {x = pos_x, y = pos_y + y_offset},
            size = {width = 300, height = bg_height}
        })
        y_offset = y_offset + bg_height
    end

    -- Separator
    self.images[box_type..'_sep'] = Display.images.new({
        texture = {path = 'data/assets/separator.png'},
        pos = {x = pos_x, y = pos_y + y_offset},
        size = {width = 300}
    })
    y_offset = y_offset + 4  -- separator height

    -- 4x more bg tiles
    for i = 5, 8 do
        self.images[box_type..'_bg'..i] = Display.images.new({
            texture = {path = 'data/assets/bg.png'},
            pos = {x = pos_x, y = pos_y + y_offset},
            size = {width = 300, height = bg_height}
        })
        y_offset = y_offset + bg_height
    end

    -- Bottom bar
    self.images[box_type..'_bottom'] = Display.images.new({
        texture = {path = 'data/assets/bottom.png'},
        pos = {x = pos_x, y = pos_y + y_offset},
        size = {width = 300}
    })

    -- Text overlay (no background, sits on top of images)
    local text_settings = {
        pos = {x = pos_x + 10, y = pos_y + 22},
        bg = {visible = false},
        text = {size = 10, font = 'Consolas'},
        flags = {draggable = false}
    }
    self.text_box[box_type] = Display.texts.new(text_settings)

    -- Show all images for this box
    for key, img in pairs(self.images) do
        if key:find(box_type) then img:show() end
    end
end

function Display:updateBBDisplay(box_type)
    local disp = self.image_displays[box_type]
    if not disp then return end

    if not self.player then return end
    self.player:update()

    local information = {}
    local player = self.player
    local line_width = 35
    local file_line_prefix = 16
    local file_totals_width = line_width - file_line_prefix - 1

    information.role = self.statecontroller.role or 'Master'
    information.slave_to = self.statecontroller.assist ~= nil and (' >> '..self.statecontroller.assist) or ''
    information.busy = string.format('%-5s', tostring(not self.observer:canAct()))

    -- (35 - 6 - 5 - 1 = 23 chars)
    local c_style_width = 23
    local c_style_text = self.statecontroller.current_style and ('['..string.sub(self.statecontroller.current_style:lower(), 1, c_style_width - 2)..']') or ''
    information.c_style = string.format('%'..c_style_width..'s', c_style_text)

    information.route_file = string.format('%-15s', 'None')
    information.state = self.statecontroller.state

    if self.statecontroller.route_file ~= '' then
        information.route_file = string.format('%-15s', string.sub(self.statecontroller.route_file, 1, 15))
    end
    information.route_nodes = #self.navigation.route or 0
    information.current_node = self.navigation.current_node or 0

    local target_count = 0
    if self.statecontroller.targets_file ~= '' then
        target_count = #self.observer.target_list.name + #self.observer.target_list.hex
    end
    local target_count_len = string.len(tostring(target_count)) + 2
    local target_file_width = file_totals_width - target_count_len
    local target_file = self.statecontroller.targets_file ~= '' and self.statecontroller.targets_file or 'None'
    information.targets_file = string.format('%-'..target_file_width..'s', string.sub(target_file, 1, target_file_width))
    information.target_totals = '('..target_count..')'

    local action_count = 0
    if self.actions then
        action_count = #self.actions.combat_actions + #self.actions.noncombat_actions
    end
    local action_count_len = string.len(tostring(action_count)) + 2
    local profile_width = file_totals_width - action_count_len
    local profile_file = self.statecontroller.profile_file or 'None'
    information.profile = string.format('%-'..profile_width..'s', string.sub(profile_file, 1, profile_width))
    information.action_totals = '('..action_count..')'

    disp.info_text:update(information)

    -- Update image elements (switch icon, etc.)
    self:updateImageDisplay(box_type)
end

function Display:updateAgentDisplay(box_type, create)
    local head = L{}
    local information = {}

    if create then
        head:append('\\cs('..self:labels(box_type)..')'..string.format('%10s','| ${title} v1.2 | ')..'\\cr')
        head:append(string.format('%-8s','File: ')..string.format('%10s','${file_name|None} '))
        head:append(string.format('%-12s','Step Cnt.: ')..string.format('%10s','${current_step|0}/${total_steps|0}'))
        head:append(string.format('%-12s','Step Type: ')..string.format('%10s','${step_type|N/A}'))
        head:append(string.format('%-12s','Triggered: ')..string.format('%10s','${triggered|false}'))
        head:append(string.format('%-12s','Performed: ')..string.format('%10s','${performed|false}'))
        head:append(string.format('%-12s','Validated: ')..string.format('%10s','${validated|false}'))
    end

    information['title'] = box_type:upper()
    information['triggered'] = nil
    information['performed'] = nil
    information['validated'] = nil
    if self.statecontroller ~= nil and next(self.statecontroller.steps) ~= nil then
        information['file_name'] = string.sub(self.statecontroller.fileName,1,12)
        information['current_step'] = self.statecontroller.currentStep
        information['total_steps'] = #self.statecontroller.steps
        if self.statecontroller.steps[self.statecontroller.currentStep] then
            information['step_type'] = self.statecontroller.steps[self.statecontroller.currentStep].type or 'None'
            if self.statecontroller.stepQueue[self.statecontroller.currentStep] then
                information['triggered'] = self.statecontroller.stepQueue[self.statecontroller.currentStep].triggered or nil
                information['performed'] = self.statecontroller.stepQueue[self.statecontroller.currentStep].performed or nil
                information['validated'] = self.statecontroller.stepQueue[self.statecontroller.currentStep].validated or nil
            end
        end
    end

    return head, information
end

function Display:updateToUseDisplay(box_type, create)
    local head = L{}
    head:append('\\cs(150,255,150)| TO USE | \\cr')
    local collection = T{}
    if self.actions and self.actions.to_use and next(self.actions.to_use) ~= nil then
        for _,v in pairs(self.actions.to_use) do
            if (v.queue_type and v.queue_type == 'enqueue') then
                local targeting = v and v.targeting or ''
                collection:append('\\cs(80,180,100)'..v.name..' '..targeting..'\\cr')
            else
                local targeting = v and v.targeting or ''
                collection:append(v.name..' '..targeting)
            end
        end
    end
    head:append(T(collection):tovstring())
    return head, {}, true  -- Always recreate for this type
end

function Display:updateNodesDisplay(box_type, create)
    local head = L{}
    head:append('\\cs(150,255,150)| NODES | \\cr')
    local collection = T{}
    if self.navigation and self.navigation.route and next(self.navigation.route) ~= nil then
        for _,v in pairs(self.navigation.route) do
            collection:append(string.format('%.2f',v.x)..' '..string.format('%.2f',v.y)..' '..(v.tolerance or self.navigation.node_tolerance))
        end
    end
    head:append(T(collection):tovstring())
    return head, {}, true  -- Always recreate for this type
end

function Display:updateNyzulDisplay(box_type, create)
    local head = L{}
    local information = {}

    head:append('\\cs('..self:labels(box_type)..')'..string.format('%10s','| ${title} | ')..'\\cr')
    head:append('\\cs(150,200,150) Switch: \\cr'..string.format('%-10s','${switch|off} (${role|none})'))
    head:append('\\cs(150,200,150) State: \\cr'..string.format('%-10s','${state|off} '))
    head:append('\\cs(150,200,150) Time: \\cr'..string.format('%-10s', self.statecontroller.time_remaining))
    head:append(' Floor: '..string.format('%-10s', self.statecontroller.current_floor))
    head:append(' Sub Map: '..string.format('%s', self.statecontroller.current_submap))
    head:append(' Floor Obj.: '..string.format('%-10s','${objective|None} '))

    if windower.ffxi.get_info().zone == 77 then
        head:append(' Completion: '..string.format('%-10s','${completion|0} '))

        self.statecontroller.player:update()
        head:append(' \\cs(249,236,236)Runes: \\cs(75,253,116)[')
        for _,v in pairs(self.statecontroller.rune_info) do
            if v and type(v) == 'table' and v['mob'] and v['mob'].x ~= nil and v['mob'].y ~= nil then
                local distance = Observer:distanceBetween(v['mob'], self.statecontroller.player.mob)
                local angle = Observer:getAngle(v['mob'])
                local direction = Observer:getCardinalDirection(angle)
                local temp = string.format("    \\cs(249,236,236) [Idx: %s  Dist.: %02.01f  Activated: %s  Dir: %s  Valid: %s ]", v['mob']["index"], distance, tostring(v["activated"]), direction, tostring(v.mob.valid_target))
                head:append(temp)
            end
        end
        head:append(" \\cs(75,253,116)]")

        if (self.statecontroller.current_floor_goal):contains('Lamps') then
            head:append(' \\cs(249,236,236)Lamps: \\cs(75,253,116)[')
            for _,v in pairs(self.statecontroller.current_floor_lamp_info) do
                if v and type(v) == 'table' and v['mob'] and v['mob'].x ~= nil and v['mob'].y ~= nil then
                    local distance = Observer:distanceBetween(v['mob'], self.statecontroller.player.mob)
                    local angle = Observer:getAngle(v['mob'])
                    local direction = Observer:getCardinalDirection(angle)
                    local temp = string.format("    \\cs(249,236,236) [Idx: %s  Dist.: %02.01f  Activated: %s  Dir: %s  Valid: %s ]", v['mob']["index"], distance, tostring(v["activated"]), direction, tostring(v.mob.valid_target))
                    head:append(temp)
                end
            end
            head:append(" \\cs(75,253,116)]")
        end

        if (self.statecontroller.current_floor_goal):contains('Leader') then
            head:append(' \\cs(249,236,236)Leader: \\cs(75,253,116)[')
            for _,v in pairs(self.statecontroller.current_floor_enemy_leader) do
                if v and type(v) == 'table' and v['mob'] and v['mob'].x ~= nil and v['mob'].y ~= nil then
                    local distance = Observer:distanceBetween(v['mob'], self.statecontroller.player.mob)
                    local angle = Observer:getAngle(v['mob'])
                    local direction = Observer:getCardinalDirection(angle)
                    local temp = string.format("    \\cs(249,236,236) [Name: %s  Dist.: %02.01f Dir: %s  Valid: %s ]", v['mob']["name"], distance, direction, tostring(v.mob.valid_target))
                    head:append(temp)
                end
            end
            head:append(" \\cs(75,253,116)]")
        end

        if self.statecontroller.current_floor_goal == 'Spec. Enemies' then
            head:append(' \\cs(249,236,236)Spec. Enemies: \\cs(75,253,116)[')
            for _,v in pairs(self.statecontroller.current_floor_spec_enemies) do
                if v and type(v) == 'table' and v['mob'] and v['mob'].x ~= nil and v['mob'].y ~= nil then
                    local distance = Observer:distanceBetween(v['mob'], self.statecontroller.player.mob)
                    local angle = Observer:getAngle(v['mob'])
                    local direction = Observer:getCardinalDirection(angle)
                    local temp = string.format("    \\cs(249,236,236) [Name: %s  Dist.: %02.01f Dir: %s  Valid: %s ]", v['mob']["name"], distance, direction, tostring(v.mob.valid_target))
                    head:append(temp)
                end
            end
            head:append(" \\cs(75,253,116)]")
        end

        if next(self.statecontroller.current_floor_navigation_history) ~= nil then
            head:append(' \\cs(249,236,236)Nav Hist.: \\cs(75,253,116)[')
            local display_string = "\\cs(249,236,236)"
            for _,v in pairs(self.statecontroller.current_floor_navigation_history) do
                display_string = display_string.. " [X:"..v.x.." Y:"..v.y.."] "
            end
            head:append(display_string)
            head:append(" \\cs(75,253,116)]")
        end
    end

    information['switch'] = 'off'
    if self.statecontroller.on_switch == 1 then
        information['switch'] = 'on'
        if windower.ffxi.get_info().zone == self.statecontroller._nyzulZone then
            information['switch'] = 'on+'
        end
    end
    information['role'] = self.statecontroller.role
    information['state'] = self.statecontroller.state
    information['objective'] = self.statecontroller.current_floor_goal .. ' ' .. self.statecontroller.current_floor_lamp_goal
    information['completion'] = self.statecontroller.current_floor_goal_status
    information['title'] = box_type:upper()

    return head, information
end

function Display:updateText(box_type, create)
    if not self.display_settings[box_type] or not self.display_settings[box_type].visible or not windower.ffxi.get_info().logged_in then
        return
    end

    local display_type = self.display_settings[box_type]['type']
    local head, information, force_create

    if display_type == 'bb' then
        -- BB uses the new image-backed display system
        self:updateBBDisplay(box_type)
        return
    elseif display_type == 'agent' then
        head, information = self:updateAgentDisplay(box_type, create)
    elseif display_type == 'to use' then
        head, information, force_create = self:updateToUseDisplay(box_type, create)
        if force_create then create = true end
    elseif display_type == 'nodes' then
        head, information, force_create = self:updateNodesDisplay(box_type, create)
        if force_create then create = true end
    elseif display_type == 'fucknyzul' then
        head, information = self:updateNyzulDisplay(box_type, create)
    else
        return  -- Unknown type
    end

    -- Update the text box with the gathered information
    if self.text_box[box_type] then
        if create and head then
            self.text_box[box_type]:clear()
            self.text_box[box_type]:append(head:concat('\n'))
            self.text_box[box_type]:append('\n')
        end

        if information then
            self.text_box[box_type]:update(information)
        end

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
    -- Clean up image displays
    for box_type, _ in pairs(self.image_displays) do
        self:destroyImageDisplay(box_type)
    end
end

function Display:hideAll()
    for _, v in pairs(self.text_box) do
        v:hide()
    end
    for _, disp in pairs(self.image_displays) do
        for _, img in pairs(disp.images) do
            img:hide()
        end
        if disp.drag_overlay then disp.drag_overlay:hide() end
        if disp.name_text then disp.name_text:hide() end
        if disp.info_text then disp.info_text:hide() end
    end
end

function Display:showAll()
    for box_type, _ in pairs(self.text_box) do
        if self.display_settings[box_type] and self.display_settings[box_type].visible then
            self.text_box[box_type]:show()
        end
    end
    for box_type, disp in pairs(self.image_displays) do
        if self.display_settings[box_type] and self.display_settings[box_type].visible then
            for key, img in pairs(disp.images) do
                if #key >= 3 and key:sub(1,3) == 'pos' then

                else
                    img:show()
                end
            end
            if disp.drag_overlay then disp.drag_overlay:show() end
            if disp.name_text then disp.name_text:show() end
            if disp.info_text then disp.info_text:show() end
            self:updateImageDisplay(box_type)
        end
    end
end

function Display:createImageElement(box_type, key, texture_file, pos_x, pos_y, x_offset, y_offset, width, height, alpha, asset_path)
    local img = Display.images.new({
        texture = {path = asset_path .. texture_file},
        pos = {x = pos_x + x_offset, y = pos_y + y_offset},
        size = {width = width, height = height},
        color = {alpha = alpha},
        draggable = false
    })
    self.image_displays[box_type].images[key] = img
    self.image_displays[box_type].offsets[key] = {x = x_offset, y = y_offset}
    return img
end

function Display:createImageDisplay(box_type, pos_x, pos_y, asset_path, settings)
    pos_x = pos_x or 100
    pos_y = pos_y or 100
    asset_path = asset_path or windower.addon_path..'data/assets/'
    settings = settings or {}

    -- Initialize instance storage for this box_type
    self.image_displays[box_type] = {
        images = {},
        offsets = {},
        base_pos = {x = pos_x, y = pos_y},
        drag_overlay = nil,
        name_text = nil,
        info_text = nil,
        text_padding = 4,
        last_pos = nil,
        mouse_event = nil,
        asset_path = asset_path
    }
    local disp = self.image_displays[box_type]

    -- Pull label colors from settings, fallback to defaults
    local label = settings.label and settings.label[box_type] or {red = 150, green = 255, blue = 150}
    local text_settings = settings[box_type] and settings[box_type].text or {size = 9, font = 'Consolas'}
    local player_name = windower.ffxi.get_player() and windower.ffxi.get_player().name or ''

    local y_offset = 0
    local bg_height = 8
    local alpha = 250
    local display_width = 250

    self:createImageElement(box_type, 'top', 'top.png', pos_x, pos_y, 0, y_offset, display_width, nil, alpha, asset_path)

    y_offset = y_offset + 8
    self:createImageElement(box_type, 'bg1', 'bg.png', pos_x, pos_y,  0, y_offset, display_width, bg_height, alpha, asset_path)


    y_offset = y_offset + bg_height
    self:createImageElement(box_type, 'sep', 'separator.png', pos_x, pos_y,  0, y_offset, display_width, nil, alpha, asset_path)

    y_offset = y_offset + 8
    self:createImageElement(box_type, 'switch', 'on.png', pos_x, pos_y, 230, 2, 20, 0, 250, asset_path)
    for i = 2, 14 do
        self:createImageElement(box_type, 'bg'..i, 'bg.png', pos_x, pos_y, 0, y_offset, display_width, bg_height, alpha, asset_path)
        y_offset = y_offset + bg_height
    end
    self:createImageElement(box_type, 'bottom', 'bottom.png', pos_x, pos_y, 0, y_offset, display_width, nil, alpha, asset_path)
    local total_height = y_offset + 8

    for _, img in pairs(disp.images) do
        img:show()
    end

    self:createImageElement(box_type, 'pos2', 'ipc.png', pos_x , pos_y, 200, 42, 24, 28, 255, asset_path)
    self:createImageElement(box_type, 'pos1', 'follow.png', pos_x , pos_y, 224, 42, 24, 28, 255, asset_path)
    self:createImageElement(box_type, 'pos3', 'frog.png', pos_x , pos_y, 176, 42, 24, 28, 255, asset_path)
    self:createImageElement(box_type, 'pos4', 'closein.png', pos_x , pos_y, 212, 62, 24, 28, 255, asset_path)
    self:createImageElement(box_type, 'pos5', 'engage.png', pos_x , pos_y, 188, 62, 24, 28, 255, asset_path)

    -- Create a draggable text overlay that covers the whole display
    local line_height = 9
    local num_lines = math.ceil(total_height / line_height)
    local spaces_per_line = math.ceil(display_width / 6)
    local filler = string.rep(' ', spaces_per_line)

    -- Build header with box_type label
    local header_text = '| ' .. box_type:upper() .. ' |'
    local text_content = header_text .. string.rep('\n' .. filler, num_lines - 1)

    local text_padding = disp.text_padding
    disp.drag_overlay = Display.texts.new({
        pos = {x = pos_x + text_padding, y = pos_y + 2},
        bg = {alpha = 0, visible = true},
        text = {
            size = text_settings.size or 9,
            font = text_settings.font or 'Consolas',
            alpha = 255,
            red = label.red or 150,
            green = label.green or 255,
            blue = label.blue or 150,
            stroke = {
                width = text_settings.stroke and text_settings.stroke.width or 1,
                alpha = text_settings.stroke and text_settings.stroke.alpha or 200,
                red = 0,
                green = 0,
                blue = 0
            }
        },
        flags = {draggable = true, bold = text_settings.bold or false}
    })
    disp.drag_overlay:text(text_content)
    disp.drag_overlay:show()

    -- Character name text
    local name_x_offset = 45
    disp.name_text = Display.texts.new({
        pos = {x = pos_x + text_padding + name_x_offset, y = pos_y + 1},
        bg = {alpha = 0, visible = false},
        text = {
            size = (text_settings.size or 9) + 1,
            font = text_settings.font or 'Consolas',
            alpha = 255,
            red = 250,
            green = 250,
            blue = 250,
            stroke = {
                width = text_settings.stroke and text_settings.stroke.width or 1,
                alpha = text_settings.stroke and text_settings.stroke.alpha or 200,
                red = 0,
                green = 0,
                blue = 0
            },
        },
        flags = {draggable = false, bold = true, italic = true}
    })
    disp.name_text:text(player_name)
    disp.name_text:show()
    disp.offsets['name_text'] = {x = text_padding + name_x_offset, y = 0}

    disp.info_text = Display.texts.new({
        pos = {x = pos_x + text_padding + 4, y = pos_y + 24},
        bg = {alpha = 0, visible = false},
        text = {
            size = 9,
            font = 'Consolas',
            alpha = 255,
            red = 255,
            green = 255,
            blue = 255,
            stroke = {
                width = 1,
                alpha = 200,
                red = 0,
                green = 0,
                blue = 0
            }
        },
        flags = {draggable = false},
    })
    local head = '\\cs(200,75,75)Busy\\cr: ${busy|} ${c_style|}'
        ..'\n\\cs(200,190,220)Role\\cr: ${role|}${slave_to|}'
        ..'\n\\cs(150,200,150)State:\\cr ${state|}'
        ..'\nRoute Loaded: ${route_file|}'
        ..'\nCurrent Node: ${current_node|} / ${route_nodes|}'
        ..'\nTargets Loaded: ${targets_file|} ${target_totals|}'
        ..'\nActions Loaded: ${profile|} ${action_totals|}'
    disp.info_text:text(head)
    disp.info_text:show()
    disp.offsets['info_text'] = {x = text_padding + 4, y = 24}

    -- Track last known position for detecting movement
    disp.last_pos = {x = pos_x + text_padding, y = pos_y + 2}

    -- Register mouse event to sync images when text overlay moves
    disp.mouse_event = windower.register_event('mouse', function(type, _, _, _, _)
        if type == 0 and disp.drag_overlay then
            local text_x, text_y = disp.drag_overlay:pos()
            if text_x ~= disp.last_pos.x or text_y ~= disp.last_pos.y then
                disp.last_pos.x = text_x
                disp.last_pos.y = text_y
                local img_base_x = text_x - disp.text_padding
                for key, img in pairs(disp.images) do
                    local offset = disp.offsets[key]
                    img:pos(img_base_x + offset.x, text_y + offset.y)
                end
                if disp.name_text then
                    local name_offset = disp.offsets['name_text']
                    disp.name_text:pos(img_base_x + name_offset.x, text_y + name_offset.y)
                end
                if disp.info_text then
                    local info_offset = disp.offsets['info_text']
                    disp.info_text:pos(img_base_x + info_offset.x, text_y + info_offset.y)
                end
            end
        end
        return false
    end)

    -- Initial update
    self:updateImageDisplay(box_type)
end

function Display:updateImageDisplay(box_type)
    local disp = self.image_displays[box_type]
    if not disp then return end
    -- Update switch icon based on on_switch state
    if self.statecontroller.on_switch == 1 then
        disp.images['switch']:path(disp.asset_path .. 'on.png')
    else
        disp.images['switch']:path(disp.asset_path .. 'off.png')
    end

    local position = 1

    if self.statecontroller.role == 'slave' then
        if self.statecontroller.on_switch == 1 then
            if self.statecontroller.follow_master == true then
                disp.images['pos'..position]:path(disp.asset_path .. 'follow.png')
            else
                disp.images['pos'..position]:path(disp.asset_path .. 'nofollow.png')
            end
        else
            disp.images['pos'..position]:path(disp.asset_path .. 'nofollow.png')
        end
        disp.images['pos'..position]:show()
        position = position + 1
    end
    if self.observer:isIPCActive() then
        disp.images['pos'..position]:path(disp.asset_path..'ipc.png')
        disp.images['pos'..position]:show()
        position = position + 1
    else
        disp.images['pos'..position]:hide()
    end
    if self.statecontroller.frog then
        disp.images['pos'..position]:path(disp.asset_path .. 'frog.png')
        disp.images['pos'..position]:show()
    else
        disp.images['pos'..position]:hide()
    end

    position = 4
    if self.statecontroller.allow_combat_movement then
        disp.images['pos'..position]:path(disp.asset_path .. 'closein.png')
        disp.images['pos'..position]:show()
        position = position + 1
    else
        disp.images['pos'..position]:hide()
    end
    if self.actions.should_engage then
        disp.images['pos'..position]:path(disp.asset_path .. 'engage.png')
        disp.images['pos'..position]:show()
    else
        disp.images['pos'..position]:hide()
    end
    if position == 4 then
        disp.images['pos5']:hide()
    end
end

function Display:destroyImageDisplay(box_type)
    local disp = self.image_displays[box_type]
    if not disp then return end

    for _, img in pairs(disp.images) do
        img:destroy()
    end
    if disp.drag_overlay then
        disp.drag_overlay:destroy()
    end
    if disp.name_text then
        disp.name_text:destroy()
    end
    if disp.info_text then
        disp.info_text:destroy()
    end
    if disp.mouse_event then
        windower.unregister_event(disp.mouse_event)
    end

    self.image_displays[box_type] = nil
end

return Display