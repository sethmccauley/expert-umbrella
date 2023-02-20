require('extdata')

local Utilities = {}
Utilities.__index = Utilities

Utilities.res = require('resources')
Utilities._cities = {
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
Utilities._skillchains = L{
    [288] = 'Light',
    [289] = 'Darkness',
    [290] = 'Gravitation',
    [291] = 'Fragmentation',
    [292] = 'Distortion',
    [293] = 'Fusion',
    [294] = 'Compression',
    [295] = 'Liquefaction',
    [296] = 'Induration',
    [297] = 'Reverberation',
    [298] = 'Transfixion',
    [299] = 'Scission',
    [300] = 'Detonation',
    [301] = 'Impaction',
    [385] = 'Light',
    [386] = 'Darkness',
    [387] = 'Gravitation',
    [388] = 'Fragmentation',
    [389] = 'Distortion',
    [390] = 'Fusion',
    [391] = 'Compression',
    [392] = 'Liquefaction',
    [393] = 'Induration',
    [394] = 'Reverberation',
    [395] = 'Transfixion',
    [396] = 'Scission',
    [397] = 'Detonation',
    [398] = 'Impaction',
    [767] = 'Radiance',
    [768] = 'Umbra',
    [769] = 'Radiance',
    [770] = 'Umbra',
}

function Utilities:constructUtilities() 
    local self = setmetatable({}, Utilities)

    return self
end

function Utilities:arrayContains(t, value)
    if not t or not value then return nil end
    for i,v in pairs(t) do
        if v == value or v == tostring(value):lower() or tostring(v):lower() == tostring(value):lower() then return true end
        if type(v) == 'table' then
            if self:arrayContains(v, value) then return true end
        end
    end
    return false
end

function Utilities:valueAtKey(t, key)
    for i,v in pairs(t) do
        if i == key or i == tostring(key):lower() then return v end
        if type(v) == 'table' then
            if value_at_key(v, key) then return v[key] end
        end
    end
    return nil
end

function Utilities:reverseThis(tbl)
    for i=1, math.floor(#tbl / 2) do
        tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
    end
    return tbl
end

function Utilities:round(num, dec)
    local mult = 10^(dec or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Utilities:haveItem(item)
    local items = windower.ffxi.get_items()
    local bags = {'inventory'}

    for k, v in pairs(bags) do
        for index = 1, items["max_%s":format(v)] do
            if items[v][index].id == item then
                return true
            end
        end
    end
    return false
end

function Utilities:determineResonation(packet, mob_obj)
    if not mob_obj or not mob_obj.setResonatingValues then return end
    local report = T{}
    -- WS Finish
    if packet['Category'] == 3 then
        report.ability = Utilities.res.weapon_skills[packet.Param]
        if report.ability and report.ability.skillchain_a and report.ability.skillchain_a ~= '' then
            -- Skillchain Occured now resonating with sc
            if packet['Target 1 Action 1 Has Added Effect'] and Utilities._skillchains[packet['Target 1 Action 1 Added Effect Message']] then
                local reso = T{Utilities._skillchains[packet['Target 1 Action 1 Added Effect Message']]}
                local step = mob_obj.resonating_step + 1
                local window = (10 - mob_obj.resonating_step)
                local time = os.clock()
                mob_obj:setResonatingValues(reso, step, window, time)
            elseif self:arrayContains({110,161,162,185,187}, packet['Target 1 Action 1 Message']) then -- WS without SC?
                local reso = T{report.ability.skillchain_a,report.ability.skillchain_b,report.ability.skillchain_c}
                local step = 1
                local window = (10 - mob_obj.resonating_step)
                local time = os.clock()
                mob_obj:setResonatingValues(reso, step, window, time)
            elseif packet['Target 1 Action 1 Message'] == 317 then -- No idea
                local reso = T{report.ability.skillchain_a}
                local step = mob_obj.resonating_step + 1
                local window = (10 - mob_obj.resonating_step)
                local time = os.clock()
                mob_obj:setResonatingValues(reso, step, window, time)
            end
        end
    elseif packet['Category'] == 4 and packet['Target 1 Action 1 Message'] ~= 252 then -- Casting Finish
        -- notice('Casting Finish')
        -- notice(packet['Target 1 ID'])
    elseif packet['Category'] == 6 then -- JA
        -- notice('JA Finish')
        -- notice(packet['Target 1 ID'])
    elseif packet['Category'] == 11 then -- NPC TP Finish
        -- notice('NPC TP Finish')
        -- notice(packet['Target 1 ID'])
    elseif packet['Category'] == 13 then -- Avatar
        -- notice('Avatar Finish')
        -- notice(packet['Target 1 ID'])
    end
    return nil
end

function Utilities:secondsToReadable(seconds)
    local s = tonumber(seconds)

    if s <= 0 then
        return "00:00:00";
    else
        local hrs = string.format("%02.f", math.floor(s/3600))
        local mins = string.format("%02.f", math.floor(s/60 - (hrs*60)))
        local sec = string.format("%02.f", math.floor(s - hrs*3600 - mins*60))
        return '['..hrs..':'..mins..':'..sec..']'
    end
end

function Utilities:printTime(seconds)
    local date = os.date("*t", seconds)
    return tostring('['..date.hour..':'..date.min..':'..date.sec..']')
end

return Utilities