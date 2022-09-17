--[[

    Action Handling
    
--]]

langly_actions_ver = 1.16
langly_actions_date = '11.27.2020'

to_use = T{}
one_per_combat = T{}
one_per_precombat = T{}
one_per_postcombat = T{}
one_per_noncombat = T{}

last = T{
    ['last_weaponskill'] = '',
    ['last_jobability'] = '',
    ['last_spell'] = '',
    ['last_action'] = '',
    ['last_item_time'] = 0,
    ['last_monster_abil'] = '',
    ['last_monster_time'] = 0,
    ['last_action_added_time'] = 0,
    ['last_prefix_used'] = '',
}

local range_mult = {
    [0] = 1,
    [2] = 1.55,
    [3] = 1.490909,
    [4] = 1.44,
    [5] = 1.377778,
    [6] = 1.30,
    [7] = 1.15,
    [8] = 1.25,
    [9] = 1.377778,
    [10] = 1.45,
    [11] = 1.454545454545455,
    [12] = 1.666666666666667,
}

local bst_animations = T{
    ['DroopyDortwin'] = {['Foot Kick'] = 4, ['Dust Cloud'] = 6, ['Whirl Claws'] = 4, ['Wild Carrot'] = 8},
    ['PonderingPeter'] = {['Foot Kick'] = 4, ['Dust Cloud'] = 6, ['Whirl Claws'] = 4, ['Wild Carrot'] = 8},
    ['SunburstMalfik'] = {['Big Scissors'] = 5, ['Bubble Shower'] = 6},
    ['AgedAngus'] = {['Big Scissors'] = 5, ['Bubble Shower'] = 6},
    ['HeraldHenry'] = {['Big Scissors'] = 5, ['Bubble Shower'] = 6},
    ['WarlikePatrick'] = {['Tail Blow'] = 5, ['Brain Crush'] = 6, ['Blockhead'] = 5, ['Fireball'] = 7},
    ['ScissorlegXerin'] = {['Sensilla Blades'] = 5, ['Tegmina Buffet'] = 6},
    ['BouncingBertha'] = {['Sensilla Blades'] = 5, ['Tegmina Buffet'] = 6},
    ['RhymingShizuna'] = {['Lamb Chop'] = 6, ['Sheep Charge'] = 4},
    ['AttentiveIbuki'] = {['Molting Plumage'] = 6, ['Swooping Frenzy'] = 6, ['Pentapeck'] = 7},
    ['SwoopingZhivago'] = {['Molting Plumage'] = 6, ['Swooping Frenzy'] = 6, ['Pentapeck'] = 7},
    ['AmiableRoche'] = {['Recoil Dive'] = 5},
    ['BrainyWaluis'] = {['Frogkick'] = 4},
    ['SuspiciousAlice'] = {['Nimble Snap'] = 5, ['Cyclotail'] = 4},
    ['HeadbreakerKen'] = {['Cursed Sphere'] = 6, ['Somersault'] = 5},
    ['RedolentCandi'] = {['Tickling Tendrils'] = 6, ['Stink Bomb'] = 7, ['Nectarous Deluge'] = 7, ['Nepenthic Plunge'] = 7},
    ['AlluringHoney'] = {['Tickling Tendrils'] = 6, ['Stink Bomb'] = 7, ['Nectarous Deluge'] = 7, ['Nepenthic Plunge'] = 7},
    ['CaringKiyomaro'] = {['Sweeping Gouge'] = 5},
    ['VivaciousVickie'] = {['Sweeping Gouge'] = 5},
    ['AnklebiterJedd'] = {['Double Claw'] = 5, ['Grapple'] = 6, ['Spinning Top'] = 6},
    ['HurlerPercival'] = {['Power Attack'] = 5, ['Rhino Attack'] = 5},
    ['BlackbeardRandy'] = {['Razor Fang'] = 4, ['Claw Cyclone'] = 6},
    ['FleetReinhard'] = {['Scythe Tail'] = 5, ['Ripper Fang'] = 5, ['Chomp Rush'] = 6},
    ['ColibriFamiliar'] = {['Pecking Flurry'] = 5},
    ['ChoralLeera'] = {['Pecking Flurry'] = 5},
    ['SpiderFamiliar'] = {['Sickle Slash'] = 4, ['Acid Spray'] = 6},
    ['GussyHachirobe'] = {['Sickle Slash'] = 4, ['Acid Spray'] = 6},
    ['CursedAnnabelle'] = {['Mandibular Bite'] = 4},
    ['SurgingStorm'] = {['Wing Slap'] = 6, ['Beak Lunge'] = 5},
    ['SubmergedIyo'] = {['Wing Slap'] = 6, ['Beak Lunge'] = 5},
    ['ThreestarLynn'] = {['Spiral Spin'] = 4, ['Sudden Lunge'] = 6},
    ['GenerousArthur'] = {['Purulent Ooze'] = 6, ['Corrosive Ooze'] = 6},
    ['SharpwitHermes'] = {['Head Butt'] = 5, ['Wild Oats'] = 5, ['Leaf Dagger'] = 6},
    ['AcuexFamiliar'] = {['Foul Waters'] = 7, ['Pestilent Plume'] = 7},
    ['FluffyBredo'] = {['Foul Waters'] = 7, ['Pestilent Plume'] = 7},
    ['MosquitoFamilia'] = {['Infected Leech'] = 7, ['Gloom Spray'] = 6},
    ['Left-HandedYoko'] = {['Infected Leech'] = 7, ['Gloom Spray'] = 6},
}

local jaws_castable_prefixes = T{'/pet','/jobability','/weaponskill'}
local magic_castable_prefixes = T{'/magic','/ninjutsu','/song'}
local action_types = T{'spells','job_abilities','weapon_skills'}
local res = require('resources')

function get_last_prefix_used()
    if not is_blank(last_prefix_used) then
        return last_prefix_used
    end
    return nil
end

function target(target)
    if not target and target.id and target.index then return end
    local player = windower.ffxi.get_player()
    local packet = packets.new('incoming', 0x058, {
        ["Player"]=player.id,
        ["Player Index"]=player.index,
        ["Target"]=target.id})
    packets.inject(packet)
end

function attack(target)
    if not target and target.id and target.index then return end
    local player = windower.ffxi.get_player()
    local packet = packets.new('outgoing', 0x01A, {
        ["Category"]=2,
        ["Target Index"]=target.index,
        ["Target"]=target.id})
    packets.inject(packet)
end

function switch(target)
    if not target and target.id and target.index then return end
    local packet = packets.new('outgoing', 0x01A, {
        ["Category"]=15,
        ["Target Index"]=target.index,
        ["Target"]=target.id})
    packets.inject(packet)
end

function cmd(str)
    local cmd = str or nil
    if cmd then
        windower.send_command(cmd)
    end
end

function can_use(ability)
    -- True if spell/ability is available on current job combination.
    local player = windower.ffxi.get_player()
    if (player == nil) or (ability == nil) then return false end
    local learned = windower.ffxi.get_spells()[ability.id]
    
    if array_contains(magic_castable_prefixes, ability.prefix) then
        if learned then
            local main_id, sub_id = player.main_job_id, player.sub_job_id
            local jp_allocated = player.job_points[player.main_job:lower()].jp_spent
            local main_requirement = ability.levels[main_id]
            local sub_requirement = ability.levels[sub_id]
            local main_castable, sub_castable = false, false
            if main_requirement ~= nil then
                main_castable = (main_requirement <= player.main_job_level) or (main_requirement <= jp_allocated)
            end
            if sub_requirement ~= nil then
                sub_castable = (sub_requirement <= player.sub_job_level)
            end
            return main_castable or sub_castable
        else
            -- warning('Ability unusable by main/sub combination
        end
    elseif S{'/jobability', '/pet'}:contains(ability.prefix) then
        local available_ja = T(windower.ffxi.get_abilities().job_abilities)
        return available_ja:contains(ability.id)
    elseif ability.prefix == '/weaponskill' then
        local available_ws = T(windower.ffxi.get_abilities().weapon_skills)
        return available_ws:contains(ability.id)
    elseif ability.prefix == '/item' then
        return true
    elseif ability.prefix == '/ra' then
        return true
    end
    return false
end

function test_recast(ability)
    -- True if spell/ability is ready to be used or enough charges are present/mp to cast/tp to use.
    if (ability ~= nil) and can_use(ability) then
        local recast = 99
        local player = windower.ffxi.get_player()
        if (player == nil) then return false end
        if array_contains(magic_castable_prefixes, ability.prefix) and can_cast_spells() then
            recast = windower.ffxi.get_spell_recasts()[ability.recast_id]
            return (recast == 0) and (player.vitals.mp >= ability.mp_cost)
        elseif ability.prefix == '/jobability' and can_jaws() then 
            recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
            -- Need Ninjutsu Shihei/Tool checks
            return (recast == 0) and (player.vitals.tp >= ability.tp_cost)
        elseif ability.prefix == '/weaponskill' and can_jaws() then
            return (player.status == 1) and (player.vitals.tp > 999)
        elseif ability.prefix == '/pet' and can_jaws() then
            if ability.type == 'Monster' then
                local charges_left = 0
                local charges_required = ability.mp_cost
                local recast = windower.ffxi.get_spell_recasts()[ability.recast_id]
                local pet = windower.ffxi.get_mob_by_target('pet')
                charges_left = math.floor(((15 * 3) - recast) / 15)
                if not pet then return false end
                return (charges_left >= charges_required) and (pet.status == 1) and (os.clock() - last.last_monster_time > (value_at_key(bst_animations, last.last_monster_abil) or 5))
            else
                recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
                return recast == 0
            end
        elseif ability.prefix == '/item' and can_jaws() then
            if (os.clock() - last.last_item_time > 8) then
                recast = 0
            end
            local resolved_item = res.items:with('en',ability['name']:lower()) or res.items:with('enl',ability['name']:lower()) or nil
            if resolved_item and not have_item(resolved_item.id) then
                recast = 99
            end
            return recast == 0
        elseif ability.prefix == '/ra' and can_jaws() then
            recast = 0
            return recast == 0
        end
    end
    return false
end

function resolve_ability(ability)
    -- Returns action entry table from resources if exists
    local action = {}
    local lower_name = ability.name:lower()
    
    if array_contains(magic_castable_prefixes, ability.prefix) then
        action = res.spells:with('en',ability['name']) or res.spells:with('enl',ability['name']:lower()) or nil
        if next(action) ~= nil then
            return action
        end
    elseif S{'/jobability', '/pet'}:contains(ability.prefix) then
        action = res.job_abilities:with('en',ability['name']) or res.job_abilities:with('enl',ability['name']:lower()) or nil
        if next(action) ~= nil then
            return action
        end
    elseif ability.prefix == '/weaponskill' then
        action = res.weapon_skills:with('en',ability['name']) or nil
        if next(action) ~= nil then
            return action
        end
    elseif ability.prefix == '/item' then
        action = ability
        action.range = 12
        if next(action) ~= nil then
            return action
        end
    elseif ability.prefix == '/ra' then
        action = ability
        action.range = 22
        if next(action) ~= nil then
            return action
        end
    end
    return false
end

function in_range(action)
    if action == nil then return false end
    local self = windower.ffxi.get_mob_by_target('me')
    local targ = windower.ffxi.get_mob_by_target(action.declared_target)
    if action.prefix == '/pet' then
        local pet = windower.ffxi.get_mob_by_target('pet')
        if pet then 
            targ = pet
        end
    end

    if not targ or next(targ) == nil then return false end

    local distance = distance_between(self, targ)
    if action.prefix == '/ra' then
        if distance < (action.range * range_mult[0] + self.model_size) then
            return true
        end
    end
    if distance < (targ.model_size + action.range * range_mult[action.range] + self.model_size) then
        return true
    end
    return false
end

function test_actions(list, ltype)
    local list_type = ltype or 'combat'
    local actions = list or nil
    local player = windower.ffxi.get_player()
    local self = windower.ffxi.get_mob_by_target('me')
    local mob = {}
    if list_type == 'combat' or list_type == 'precombat' then
        mob = windower.ffxi.get_mob_by_index(info.mob_to_fight.index) or nil
    end

    for i,v in ipairs(actions) do
        local action = {}
        local target = windower.ffxi.get_mob_by_target(v.target) or mob

        action = resolve_ability(v)
        action.declared_target = v.target
        if action and next(action) ~= nil then  -- Resolve Ability
            if test_recast(action) then         -- Test Recast Time/Charges/Inventory/MP/can act
                if in_range(action) then        -- Test target is in range

                    if action.type == 'Trust' then
                        if not array_contains(to_use, v.name) then
                            table.append(to_use, v)
                        end
                    end

                    if action.type ~= 'Trust' and test_conditions(action, v) then

                        if v.prefix == '/ra' and not array_contains(one_per_combat, v) then
                            table.append(one_per_combat, v)
                            table.append(to_use, v)
                        end
                        if not array_contains(to_use, v.name) then
                            if array_contains(v, 'once') then
                                if list_type == 'combat' and not array_contains(one_per_combat, v) then
                                    table.append(one_per_combat, v)
                                elseif list_type == 'noncombat' and not array_contains(one_per_noncombat, v) then
                                    table.append(one_per_noncombat, v)
                                elseif list_type == 'precombat' and not array_contains(one_per_precombat, v) then
                                    table.append(one_per_precombat, v)
                                elseif list_type == 'postcombat' and not array_contains(one_per_postcombat, v) then
                                    table.append(one_per_postcombat, v)
                                end
                            end
                            table.append(to_use, v)
                        end
                    end
                end
            end        
        end
    end
end

function test_conditions(resolved_ability, ability, source)
    local conditions = ability.conditions
    local player = windower.ffxi.get_player()
    local action = resolved_ability or resolve_ability(ability)
    local src = source or nil

    if not conditions then return true end 
    if conditions and next(conditions) == nil then return false end
    
    for i,v in pairs(conditions) do
        local cond = v.condition
        local value = v.value or ''
        if not cond then return false end
        
        if cond == 'tpgt' then
            if player.vitals.tp < v.value then
                return false
            end
        elseif cond == 'tplt' then
            if player.vitals.tp > v.value then
                return false
            end
        elseif cond == 'ready' then
            if not test_recast(action) then
                return false
            end            
        elseif cond == 'hppgt' then
            if player.vitals.hpp < v.value then
                return false
            end
        elseif cond == 'hpplt' then
            if player.vitals.hpp > v.value then
                return false
            end
        elseif cond == 'mppgt' then
            if player.vitals.mpp < v.value then
                return false
            end
        elseif cond == 'mpplt' then
            if player.vitals.mpp > v.value then
                return false
            end
        elseif cond == 'mobhpplt' then
            local mobinfo = windower.ffxi.get_mob_by_target('t') or nil
            if mobinfo and mobinfo.hpp > tonumber(v.value) then
                return false
            end 
        elseif cond == 'mobhppgt' then
            local mobinfo = windower.ffxi.get_mob_by_target('t') or nil
            if mobinfo and mobinfo.hpp < tonumber(v.value) then
                return false
            end
        elseif cond == 'once' then
            local flag = false
            if src and src == 'to_use' then
                flag = true
            end
            if array_contains(one_per_combat, v.name) and not flag then
                return false
            end
        elseif cond == 'absent' then
            if v.value:lower() == 'pet' then
                local pet = windower.ffxi.get_mob_by_target('pet') or nil
                if pet then
                    return false
                end
            end
            if has_buff(v.value:lower()) and v.value ~= 'pet' then
                return false
            end
        elseif cond == 'present' then
            if v.value:lower() == 'pet' then
                local pet = windower.ffxi.get_mob_by_target('pet') or nil
                if not pet then
                    return false
                end
            end
            if not has_buff(v.value:lower()) and v.value ~= 'pet' then
                return false
            end
        elseif cond == 'pethpplt' then
            local pet = windower.ffxi.get_mob_by_target('pet') or nil
            if pet and pet.hpp > tonumber(v.value) then
                return false
            end
        elseif cond == 'pethppgt' then
            local pet = windower.ffxi.get_mob_by_target('pet') or nil
            if pet and pet.hpp < tonumber(v.value) then
                return false
            end
        elseif cond == 'petstatus' then
            local pet = windower.ffxi.get_mob_by_target('pet') or nil
            if pet and pet.status ~= v.value then
                return false
            end
        elseif cond == 'inqueue' then
            if not array_contains(to_use, v.value) then
                return false
            end
        elseif cond == 'notinqueue' then
            if array_contains(to_use, v.value) then
                return false
            end
        elseif cond == 'strengthlt' then
            if not v.modifier then return false end
            if has_buff(v.value:lower(), v.modifier) then
                return false
            end
        end
    end
    return true
end

function run_action()
    local player = windower.ffxi.get_player()
    local self = windower.ffxi.get_mob_by_index(player.index)

    if next(to_use) ~= nil and info.busy == false then
        local target = windower.ffxi.get_mob_by_target(to_use[1].target)
        local resolved_ability = resolve_ability(to_use[1])
        
        if (os.clock() - info.last_atk_pkt > 3) then
            if test_recast(resolved_ability) and in_range(resolved_ability) and test_conditions(resolved_ability, to_use[1], 'to_use') then
                info.busy = true
                info.busy_timer = os.clock()
                --notice('Using Action: '..to_use[1].name..' formatted as: '..to_use[1].prefix..' "'..to_use[1].name..'" <'..to_use[1].target..'>')
                if to_use[1].prefix == '/item' then
                    info.casting = true
                    last.last_item_time = os.clock()
                    cmd('input '..to_use[1].prefix..' "'..to_use[1].name..'" <'..to_use[1].target..'>')
                elseif array_contains(magic_castable_prefixes, to_use[1].prefix) then
                    info.casting = true
                    last.last_spell = to_use[1].name
                    local command = 'input '..to_use[1].prefix..' "'..to_use[1].name..'" <'..to_use[1].target..'>'
                    coroutine.sleep(.7)
                    cmd(command)
                elseif to_use[1].prefix == '/pet' then
                    if resolved_ability.type and resolved_ability.type == 'Monster' then
                        last.last_monster_time = os.clock()
                        last.last_monster_abil = to_use[1].name
                    end
                    cmd('input '..to_use[1].prefix..' "'..to_use[1].name..'" <'..to_use[1].target..'>')
                elseif to_use[1].prefix == '/weaponskill' then
                    last.last_weaponskill = to_use[1].name
                    cmd('input '..to_use[1].prefix..' "'..to_use[1].name..'" <'..to_use[1].target..'>')
                elseif to_use[1].prefix == '/ra' then
                    cmd('input '..to_use[1].prefix..' <'..to_use[1].target..'>')
                else
                    last.action = to_use[1].name
                    cmd('input '..to_use[1].prefix..' "'..to_use[1].name..'" <'..to_use[1].target..'>')
                end
                if to_use[1] then last.last_prefix_used = to_use[1].prefix end
                windower.ffxi.run(false)
            else
                table.remove(to_use, 1)
            end
        end
    end
end

function empty_one_per_fight()
    one_per_combat = T{}
    to_use = T{}
end

function add_to_to_use(action)
    last.last_action_added_time = os.clock()
    last.last_action = action.name:lower()
    table.append(to_use, action)
end
