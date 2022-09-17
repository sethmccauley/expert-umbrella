--[[

    Mob table Information
    
--]]

langly_mobs_ver = 1.13
langly_mobs_date = '11.17.2018'

function get_marray(--[[optional]]names)
	local marray = windower.ffxi.get_mob_array()
	local target_names = T{}
    local new_marray = T{}

    if type(names) == 'table' then 
        for i,v in pairs(names) do
            target_names[i] = {['name'] = v:lower()}
        end
    elseif type(names) == 'string' then target_names = T{[1] = {['name'] = names and names:lower() or nil}} end
    
	for i,v in pairs(marray) do
		if v.id == 0 or v.index == 0 or v.status == 3 then
			marray[i] = nil
		end
	end

    if names then
        for i,v in pairs(marray) do
            local delete = false
            if not target_names:with('name', v.name:lower()) then
                delete = true
            end
            if delete then
                marray[i] = nil
            end
        end
    end

	return marray
end

function pick_nearest(--[[optional]]mob_table)
    local dist_target = 999
    local closest_index = 0
    local marray = mob_table or get_marray()

    for k,v in pairs(marray) do
        local mob = windower.ffxi.get_mob_by_index(v.index)
        if math.sqrt(mob['distance']) < dist_target then
            closest_index = k
            dist_target = math.sqrt(mob['distance'])
        end
    end

    return marray[closest_index]
end

function add_to_aggro(id)
    local mob = windower.ffxi.get_mob_by_id(id) or nil
    if not mob then return end
    local index = tonumber(mob.id, 16)
    local ignore_list = targets.settings.ignore.name or {}
    local ignore_hex = targets.settings.ignore.hex or {}
    if array_contains(ignore_list, mob.name) or array_contains(ignore_hex, index) then return end

    if not info.aggro:contains('id', mob.id) then
        info.aggro[mob.index] = {
            ['name'] = mob.name,
            ['index'] = mob.index,}
    end
end

function find_targets(mob_table_template)
    local builder_marray = mob_table_template or nil
    local target_array = T{}
    if not builder_marray then return end

    for i,v in pairs(builder_marray) do
        if i == 'name' then
            if table.length(v) > 0 then
                for _,val in pairs(v) do
                    local mobs = get_marray(val)
                    for ke,va in pairs(mobs) do
                        if not info.targets[ke] and valid_targetable(va) then
                            info.targets[ke] = {
                                ['name'] = va.name,
                                ['index'] = va.index,}
                        end
                    end
                end
            end
        elseif i == 'hex' then
            if table.length(v) > 0 then
                for _,val in pairs(v) do
                    local mob = {}
                    local index = tonumber(val, 16)
                    mob = windower.ffxi.get_mob_by_index(index)
                    if not info.targets[index] and valid_targetable(mob) then
                        info.targets[mob.index] = {
                            ['name'] = mob.name,
                            ['index'] = mob.index}
                    end
                end
            end
        end
    end
    return
end

function validate_targets()
    for i,v in pairs(info.targets) do
        if v and not valid_targetable(v) then
            info.targets[i] = nil
        end
    end

    for i,v in pairs(info.aggro) do
        if v and not valid_targetable(v) then
            info.aggro[i] = nil
        end
    end

    if next(info.mob_to_fight) ~= nil and not info.targets[info.mob_to_fight.index] and not info.aggro[info.mob_to_fight.index] then
        info.mob_to_fight = {}
        coroutine.schedule(empty_one_per_fight, 1)
    end
end

function difference_z(mob)
    local difference = 0
    local mob = windower.ffxi.get_mob_by_index(mob.index)
    local self = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
    difference = math.abs(self.z - mob.z)
    return difference
end

function close_enough(mob)
    local self = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
    local nodes = {}
    if table.length(route.settings.steps) > 0 then
        nodes = route.settings.steps
    else
        nodes = {self}
    end
    local mob = windower.ffxi.get_mob_by_index(mob.index)
    
    local dist_target = 999
    local closest_index = 0

    for i,v in ipairs(nodes) do
        if distance_between(mob, v) < dist_target then
            closest_index = i
            dist_target = distance_between(mob, v)
        end
    end
    
    if dist_target < targets.settings.range then
        return true
    end

    return false
end