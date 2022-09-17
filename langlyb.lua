--[[

    Author: Langly

        Handling game data and entities
        Behavioral resolution
        Queue Handling
        
--]]

langlyb_ver = 1.15
langlyb_date = '08.31.2022'

require('tables')
require('logger')
require('strings')
require('sets')
require('actions')
require('extdata')
require('lang/langly_mobs')
require('lang/langly_actions')
require('lang/langly_text')

trust_table = {['AAEV'] = 'ArkEV', ['AATT'] = 'ArkTT', ['AAHM'] = 'ArkHM', ['AAGK'] = 'ArkGK', ['AAMR'] = 'ArkMR'}

cities = {
    "Ru'Lude Gardens",
    "Upper Jeuno",
    "Lower Jeuno",
    "Port Jeuno",
    "Port Windurst",
    "Windurst Waters",
    "Windurst Woods",
    "Windurst Walls",
    "Heavens Tower",
    "Port San d'Oria",
    "Northern San d'Oria",
    "Southern San d'Oria",
    "Port Bastok",
    "Bastok Markets",
    "Bastok Mines",
    "Metalworks",
    "Aht Urhgan Whitegate",
    "Tavanazian Safehold",
    "Nashmau",
    "Selbina",
    "Mhaura",
    "Norg",
    "Eastern Adoulin",
    "Western Adoulin",
    "Kazham",
    "Leafallia"
}

slot_map = T{'main','sub','range','ammo','head','body','hands','legs','feet','neck','waist','left_ear', 'right_ear', 'left_ring', 'right_ring','back'}

--[[
    Buff Table Information
--]]
function has_buff(buff, strength)
    local tier = 0
    local strength = strength or 1
	local buffs = convert_buff_list(windower.ffxi.get_player()['buffs'])
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

    if tier >= strength then
        return true
    end
	return false
end

function convert_buff_list(bufflist)
    local buffarr = {}
    for i,v in pairs(bufflist) do
        if res.buffs[v] then
            buffarr[#buffarr+1] = res.buffs[v].english:lower()
        end
    end
    return buffarr
end

function can_act()
    local player = windower.ffxi.get_player()
    local actable_statuses = S{0,1} -- Idle/Engaged
    if actable_statuses:contains(player.status) then
        return true
    end
    return false
end

function can_cast_spells()
    local haltables = {'Sleep','Petrifaction','Charm','Terror','Lullaby','Stun','Silence','Mute'}

    for _,v in pairs(haltables) do
        if has_buff(v) and can_act() then
            return false
        end
    end
    return true
end

function can_jaws()
    local haltables = {'Sleep','Petrifaction','Charm','Terror','Lullaby','Stun','Amnesia'}

    for _,v in pairs(haltables) do
        if has_buff(v) and can_act() then
            return false
        end
    end
    return true
end

--[[
    Navigation Commands
--]]
function runto(target)
	local self = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0)
	local angle = (math.atan2((target.y - self.y), (target.x - self.x))*180/math.pi)*-1
	windower.ffxi.run((angle):radian())
end

function distance_between(pos1, pos2)
    if pos1 and pos2 then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        return math.sqrt(dx*dx + dy*dy)
    else
        return 0
    end
end

function distance_to(x, y)
	local self = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0) or {['x'] = 0, ['y'] = 0}
	local dx = x - self.x
	local dy = y - self.y
	return math.sqrt(dx*dx + dy*dy)
end

function headingto(x,y)
    if x == nil or y == nil then return end
	local x = x - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).x
	local y = y - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).y
	local h = math.atan2(x,y)
	return h - 1.5708
end

function face_target(mob)
	local target = {}
	if mob then
		target = windower.ffxi.get_mob_by_index(mob or 0)
	else 
		target = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index or 0)
	end
	local self_vector = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0)
	if target then
		local angle = (math.atan2((target.y - self_vector.y), (target.x - self_vector.x))*180/math.pi)*-1
		windower.ffxi.turn((angle):radian())
	end
end

function close_in(target)
    local mob = target
    local t_id = target.id or 0
    local self = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0) 
	local distance = windower.ffxi.get_mob_by_id(t_id).distance:sqrt()
	if distance > 2.3 and info.busy == false then
        windower.ffxi.run(false)
        face_target(mob.index)
        local angle = (math.atan2((mob.y - self.y), (mob.x - self.x))*180/math.pi)*-1
        windower.ffxi.run((angle):radian())
	elseif distance < .5 then
        windower.ffxi.run(false)
        face_target(mob.index)
        local angle = (math.atan2((mob.y - self.y), (mob.x - self.x))*180/math.pi)*-1
        windower.ffxi.run((angle+180):radian())
    else
		windower.ffxi.run(false)
	end
end

function determine_closest_waypoint(list)
	local dist_target = 999
    local closest_index = 0
    
    for i,v in ipairs(list) do
        local z = height_difference(v.z or 0)
        if distance_to(v.x, v.y) < dist_target and z < 10 then
            closest_index = i
            dist_target = distance_to(v.x, v.y)
        end
    end

	return closest_index
end

function height_difference(z)
    local self = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
    local z = z or 10000
    local difference = math.abs(self.z - z)
    return difference
end

--[[
    Utility
--]]
function round(num, dec)
    local mult = 10^(dec or 0)
    return math.floor(num * mult + 0.5) / mult
end

function get_party_claimids()
    local party_table = windower.ffxi.get_party()
    local party_ids = T{}
    
    if party_table == nil then return T{} end
    
    for _,member in pairs(party_table) do
        if type(member) == 'table' and member.mob then
            party_ids:append(member.mob.id)
            if member.mob.pet_index then
                local pet = windower.ffxi.get_mob_by_index(member.mob.pet_index) or nil
                if pet then
                    party_ids:append(pet.id)
                end
            end
        end
    end

    return party_ids
end

function party_claimed(target)
    local party_ids = get_party_claimids()
    local mob = target
    if array_contains(party_ids, mob.claim_id) then
        return true
    end
    return false
end

function valid_targetable(mob)
    local party_ids = get_party_claimids()
    local entity = mob or {['name'] = 'none', ['index'] = '0'}
    local mob = windower.ffxi.get_mob_by_index(entity.index)
    -- notice(T(mob):tovstring())
    if mob and mob.valid_target and mob.hpp > 0 and mob.status ~= 3 and (party_ids:contains(mob.claim_id) or mob.claim_id == 0) and close_enough(mob) and difference_z(mob) < 6 and distance_to(mob.x, mob.y) < targets.settings.range then
        return true
    end
    return false
end

function valid_entity(mob)
    local party_ids = get_party_claimids()
    local entity = mob or {['name'] = 'none', ['index'] = '0'}
    local mob = windower.ffxi.get_mob_by_index(entity.index)
    if mob and mob.valid_target and mob.hpp > 0 and mob.status ~= 3 and (party_ids:contains(mob.claim_id) or mob.claim_id == 0) and difference_z(mob) < 6 and mob.spawn_type == 16 then
        return true
    end
    return false
end

function array_contains(t, value)
    for i,v in pairs(t) do
        if v == value or v == tostring(value):lower() then return true end
        if type(v) == 'table' then
            if array_contains(v, value) then return true end
        end
    end
    return false
end

function value_at_key(t, key)
    for i,v in pairs(t) do
        if i == key or i == tostring(key):lower() then return v end
        if type(v) == 'table' then
            if value_at_key(v, key) then return v[key] end
        end
    end
    return nil
end

function reverse_this(tbl)
    for i=1, math.floor(#tbl / 2) do
        tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
    end
end

function is_blank(x)
    return not not tostring(x):find("^%s*$")
end

function is_dead()
    local player = windower.ffxi.get_player()
    if player.status == 2 or player.status == 3 then
        return true
    end
    return false
end

function have_item(id)
	local items = windower.ffxi.get_items()
	local bags = {'inventory'}

	for k, v in pairs(bags) do
        for index = 1, items["max_%s":format(v)] do
            if items[v][index].id == id then
                return true
            end
        end
	end
	return false
end

function check_trusts(list)
    local party = windower.ffxi.get_party()
    local name = ''
    local trust_count = #info.settings.trusts
    local free_spaces = 6 - party.party1_count
    
    for i,v in ipairs(list) do
        if v.name:find('(UC)') then 
            name = v.name:sub(1,-6) 
        elseif v.name:find('II') then
            name = v.name:sub(1, -4)
        elseif v.name:find('[S]') then
            name = v.name:sub(1, -5)
        else
            name = v.name
        end
        if trust_table[v.name] then
            name = trust_table[v.name]
        end
        
        name = name:gsub("%s+", "")

        if not in_party(name) and free_spaces > 0 then
            free_spaces = free_spaces - 1
            test_actions({[1] = v}, 'trust')
        end
    end
end

function is_party_lead()
    local party = windower.ffxi.get_party()
    local player = windower.ffxi.get_player()
    if player.id == party.party1_leader then
        return true
    end    
    return false
end

function in_alliance()
    local party = windower.ffxi.get_party()
    if party.party2_count > 0 or party.party3_count > 0 then
        return true
    end
    return false
end

function in_party(name)
	local name = name or 'None'
	local party = windower.ffxi.get_party()
	
    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() then
                return true
            end
        end
    end
	return false
end

function players_target(name)
    if name == nil then return nil end
	local name = name
	local party = windower.ffxi.get_party()

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() then
                if member and member.mob and member.mob ~= nil and member.mob.target_index ~= 0 or member.mob.target_index ~= nil then
                    return windower.ffxi.get_mob_by_index(member.mob.target_index)
                end
            end
        end
    end
	return nil
end

function players_status(name)
    if name == nil then return nil end
	local name = name
	local party = windower.ffxi.get_party()

    for i = 0,5 do
        local member = party['p'..i]
        if member ~= nil then
            if member.name:lower() == name:lower() then
                if member.mob and member.mob ~= nil and member.mob.status then
                    return member.mob.status
                end
            end
        end
    end
	return nil
end

function is_solo()
    local party = windower.ffxi.get_party()
    if party.party1_count == 1 and not in_alliance() then
        return true
    end
    return false
end

function in_city()
    local world = windower.ffxi.get_info()
    if array_contains(cities, res.zones[world.zone].en) then
        return true
    end
    return false
end

function is_equipped(item)
    local items = windower.ffxi.get_items()
    local item_id, item = res.items:find(function(v) if v.name == item then return true end end)
    if item_id == nil then return false end
    local equipment = T{}
    for id,name in pairs(slot_map) do
        equipment[name] = {
            ['slot'] = items.equipment[name],
            ['bag_id'] = items.equipment[name..'_bag']
            }
        if equipment[name].slot == 0 then equipment[name].slot = 'empty' end
    end
    for i,v in pairs(equipment) do
        if v.slot ~= 'empty' then
            if items[fix_bag(res.bags[v.bag_id].english)][v.slot].id == item_id then
                return true
            end
        end
    end
    return false
end

function fix_bag(bag)
    local new = bag:gsub(' ','')
    return new:lower()
end

function is_enchant_ready(--[[name of item]]item)
	local item_id, item = res.items:find(function(v) if v.name == item then return true end end)
	local inventory = windower.ffxi.get_items()
	local usable_bags = T{'inventory','wardrobe','wardrobe2','wardrobe3','wardrobe4'}
	local itemdata = {}
	
	for i,v in pairs(inventory) do
		if usable_bags:contains(i) then
			for key,val in pairs(v) do
				if type(val) == 'table' and val.id == item_id then
					itemdata = extdata.decode(val)
				end
			end
		end
	end
	
	if itemdata and itemdata.charges_remaining then
		if itemdata.activation_time - itemdata.next_use_time > item.cast_delay then
			return true
		end
	end
	return false
end

function is_usable(item)
	local item_id, item = res.items:find(function(v) if v.name == item then return true end end)
	local inventory = windower.ffxi.get_items()
	local usable_bags = T{'inventory','wardrobe','wardrobe2','wardrobe3','wardrobe4'}
	local itemdata = {}
	
	for i,v in pairs(inventory) do
		if usable_bags:contains(i) then
			for key,val in pairs(v) do
				if type(val) == 'table' and val.id == item_id then
					itemdata = extdata.decode(val)
				end
			end
		end
	end
    if itemdata['usable'] then return itemdata['usable'] end
    return false
end

function has_charges(--[[name of item]]item)
	local item_id, item = res.items:find(function(v) if v.name == item then return true end end)
	local inventory = windower.ffxi.get_items()
	local bags = T{'inventory','safe','safe2','storage','satchel','locker','sack','case','wardrobe','wardrobe2','wardrobe3','wardrobe4'}
	local itemdata = {}
	
	for i,v in pairs(inventory) do
		if bags:contains(i) then
			for key,val in pairs(v) do
				if type(val) == 'table' and val.id == item_id then
					itemdata = extdata.decode(val)
				end
			end
		end
	end
	
	if itemdata and itemdata.charges_remaining then
		if itemdata.charges_remaining > 0 then
			return true
		end
	end
	return false
end