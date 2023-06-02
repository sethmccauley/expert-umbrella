local Actions = {}
Actions.__index = Actions
local Utilities = require('lang/utilities')
local Observer = require('lang/observer')
local MobObject = require('lang/mobobject')

Actions.range_mult = {
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
Actions.bst_animations = T{
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
Actions.ninja_tool_reference = T{
    ['Shihei'] = T{338, 339, 340},
    ['Shikanofuda'] = T{338, 339, 340, 353, 354, 318, 505, 506, 507, 508, 509, 510,},
    ['Chonofuda'] = T{341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 319, 508},
    ['Inoshishinofuda'] = T{320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335, 336, 337},
}
Actions.ninja_tool_ids = T{
    ['Inoshishinofuda'] = 2971,
    ['Shihei'] = 1179,
    ['Chonofuda'] = 2973,
    ['Shikanofuda'] = 2972,
}
Actions.trust_reference = {['AAEV'] = 'ArkEV', ['AATT'] = 'ArkTT', ['AAHM'] = 'ArkHM', ['AAGK'] = 'ArkGK', ['AAMR'] = 'ArkMR'}
Actions.ja_castable_prefixes = T{'/jobability', '/ja', '/pet'}
Actions.ws_castable_prefixes = T{'/weaponskill','/ws'}
Actions.magic_castable_prefixes = T{'/magic','/ma','/ninjutsu','/nin','/song','/sing'}
Actions.action_types = T{'spells','job_abilities','weapon_skills'}
Actions.packets = require('packets')

function Actions:constructActions(action_list, Player)
    local self = setmetatable({}, Actions)

    self.player = Player

    self.last_weaponskill = T{}
    self.last_jobability = T{}
    self.last_spell = T{}
    self.last_action = {}
    self.last_item_time = 0
    self.last_monster_ability = T{}
    self.last_monster_time = 0
    self.last_prefix_used = nil

    self.combat_actions = T{}
    self.noncombat_actions = T{}
    self.precombat_actions = T{}
    self.postcombat_actions = T{}
    self.engage_distance = 16

    self.to_use = T{}

    self.once_per_combat = T{}
    self.once_per_precombat = T{}
    self.once_per_postcombat = T{}
    self.once_per_noncombat = T{}

    self.trust_list = T{}

    if action_list then self:setActionList(action_list) end

    return self
end

function Actions:setActionList(action_list)
    if type(action_list) ~= 'table' then return nil end

    for i,v in pairs(action_list) do
        if i == 'engage_distance' then self:setEngageDistance(v)
        elseif i == 'combat' then self.combat_actions = self:processAbilities(v)
        elseif i == 'precombat' then self.precombat_actions = self:processAbilities(v)
        elseif i == 'postcombat' then self.postcombat_actions = self:processAbilities(v)
        elseif i == 'noncombat' then self.noncombat_actions = self:processAbilities(v)
        elseif i == 'trusts' then self.trust_list = self:processAbilities(v) end
    end
end
function Actions:processAbilities(table)
    if type(table) ~= 'table' then return nil end

    for i,v in pairs(table) do
        table[i]['res'] = self:resolveAbility(v)
    end
    return table
end
function Actions:setEngageDistance(value)
    if value < 1 or value > 24 then return nil end
    self.engage_distance = value
end
function Actions:setLastWeaponSkill(ws)
    if type(ws) ~= 'table' then return nil end
    self.last_weaponskill = ws
end
function Actions:setLastJobAbility(ja)
    if type(ja) ~= 'table' then return nil end
    self.last_jobability = ja
end
function Actions:setLastSpell(spell)
    if type(spell) ~= 'table' then return nil end
    self.last_spell = spell
end
function Actions:setLastItemTime()
    self.last_item_time = os.clock()
end
function Actions:setLastMonsterAbility(monster_ability)
    if type(monster_ability) ~= 'table' then return end
    self.last_item_time = monster_ability
    self:updateLastMonsterTime()
end
function Actions:setLastMonsterTime()
    self.last_monster_time = os.clock()
end
function Actions:setLastPrefixUsed(prefix)
    if type(monster_ability) ~= 'string' then return end
    self.last_prefix_used = prefix
end
function Actions:handleTrusts(observer_object)
    local party = windower.ffxi.get_party()
    local name = ''
    local trust_count = #self.trust_list
    local free_spaces = 6 - party.party1_count

    for i,v in ipairs(self.trust_list) do
        if v.name:find('(UC)') then
            name = v.name:sub(1,-6)
        elseif v.name:find('II') then
            name = v.name:sub(1, -4)
        elseif v.name:find('[S]') then
            name = v.name:sub(1, -5)
        else
            name = v.name
        end

        if Actions.trust_reference[v.name] then
            name = Actions.trust_reference[v.name]
        end
        name = name:gsub("%s+", "")

        if not observer_object:inParty(name) and free_spaces > 0 then
            free_spaces = free_spaces - 1
            self:testActions({[1] = v}, 'trust')
        end
    end
end

function Actions:targetMob(mob_obj)
    if not self.player and not self.player.id and not self.player.index then return end
    if not mob_obj and not mob_obj.id then return end

    local packet = self.packets.new('incoming', 0x058, {
        ["Player"]=self.player.id,
        ["Player Index"]=self.player.index,
        ["Target"]=mob_obj.id})
    Actions.packets.inject(packet)
end

function Actions:attackMob(mob_obj)
    if not mob_obj and not mob_obj.id then return end

    local packet = self.packets.new('outgoing', 0x01A, {
        ["Category"]=2,
        ["Target Index"]=mob_obj.index,
        ["Target"]=mob_obj.id})
    Actions.packets.inject(packet)
end

function Actions:switchTarget(mob_obj)
    if not Actions.packets then return end
    if not mob_obj and not mob_obj.id then return end

    local packet = self.packets.new('outgoing', 0x01A, {
        ["Category"]=15,
        ["Target Index"]=mob_obj.index,
        ["Target"]=mob_obj.id})
    Actions.packets.inject(packet)
end

function Actions:sendCommad(str)
    if not str then return end
    local cmd = str or nil
    if cmd then
        windower.send_command(cmd)
    end
end

function Actions:handleState(StateController, observer_obj)

    observer_obj:validateTargetsTable()
    observer_obj:validateAggroTable()
    self.player:update()

    if StateController.state == 'combat' then
        self:handleCombat(observer_obj)
    elseif StateController.state == 'precombat' then
        -- notice('precombat')
    elseif StateController.state == 'postcombat' then
        -- notice('postcombat')
    elseif StateController.state == 'noncombat' then
        self:handleNonCombat(observer_obj)
    end
    self:runActions(observer_obj)
end

function Actions:handleCombat(observer_obj)
    if observer_obj and observer_obj.mob_to_fight and not observer_obj.mob_to_fight.obj then
        return
    end

    local mob = observer_obj.mob_to_fight.obj
    if mob and mob.updateDetails then mob:updateDetails() else return end

    if self.player.status == 0 then -- PreCombat (Not Yet Engaged)
        -- if self.player.target_index == nil and observer_obj:timeSinceLastTarget() > 5 then
        --     observer_obj:setTargetPkt()
        --     self:targetMob(mob)
        --     notice(Utilities:printTime()..' Target invoked '..mob.name..' '..mob.index..'')
        -- end
        Actions:emptyOncePerTables()


        -- notice('Time since last attack command: '..observer_obj:timeSinceLastAttackPkt().. ' > 4')
        -- notice('Time since last attack round: '..observer_obj:timeSinceLastAttackRound().. ' > '..observer_obj.attack_round_calc)

        if (mob.details.distance:sqrt() < (self.engage_distance or 5)) and observer_obj:timeSinceLastAttackPkt() > 4 and observer_obj:timeSinceLastAttackRound() > observer_obj.attack_round_calc then
            observer_obj:setAtkPkt()
            self:attackMob(mob)
            notice(Utilities:printTime()..' Attack invoked '..mob.name..' '..mob.index..'')

            observer_obj.is_busy = true
            coroutine.schedule(function() observer_obj:forceUnbusy() end, 0.5)
        end
    elseif self.player.status == 1 then -- Combat
        if next(self.combat_actions) ~= nil then
            self:testActions(self.combat_actions, 'combat', mob)
        end
    end
end

function Actions:handleNonCombat(observer_obj)
    if self.player.status == 0 then
        if next(self.noncombat_actions) ~= nil then
            self:testActions(self.noncombat_actions, 'noncombat')
        end
    end
    if next(self.trust_list) ~= nil and (observer_obj:isPartyLead() or observer_obj:isSolo()) and not observer_obj:inAlliance() and not observer_obj:inCity() and observer_obj.role ~= 'slave' then
        self:handleTrusts(observer_obj)
    end
end

function Actions:inRange(full_ability)
    if not self.player or not full_ability then return false end

    self.player:update()

    local self_target = self.player.mob
    local targ_obj = windower.ffxi.get_mob_by_target(full_ability.target)
    local adjustment = 0

    local action = full_ability
    if full_ability.res then
        action = full_ability.res
    else
        return false
    end

    if action.prefix == '/pet' then
        local pet = windower.ffxi.get_mob_by_target('pet')
        if pet then
            targ_obj = pet
            adjustment = -4
        end
    end

    if not targ_obj or next(targ_obj) == nil then return false end

    local distance = Observer:distanceBetween(self_target, targ_obj)
    if action.prefix == '/ra' then
        if distance < (action.range * Actions.range_mult[0] + self_target.model_size) then
            return true
        end
    end

    if action.prefix == '/weaponskill' then
        adjustment = 1
    end
    if distance < (targ_obj.model_size + (action.range - adjustment) * Actions.range_mult[action.range] + self_target.model_size) then
        return true
    end
    return false
end

function Actions:canUse(resolved_ability)
    if not self.player or not resolved_ability then return false end

    if (resolved_ability and resolved_ability.prefix == '/item' or resolved_ability.prefix == '/ra') then return true end

    local learned = windower.ffxi.get_spells()[resolved_ability.id]

    if resolved_ability.name == "Honor March" then return true end

    if Utilities:arrayContains(Actions.magic_castable_prefixes, resolved_ability.prefix) then
        if learned then
            local main_id, sub_id = self.player.details.main_job_id, self.player.details.sub_job_id
            local jp_allocated = self.player.details.job_points[self.player.details.main_job:lower()].jp_spent
            local main_requirement = resolved_ability.levels[main_id]
            local sub_requirement = resolved_ability.levels[sub_id]
            local main_castable, sub_castable = false, false
            if main_requirement ~= nil then
                main_castable = (main_requirement <= self.player.details.main_job_level) or (main_requirement <= jp_allocated)
            end
            if sub_requirement ~= nil then
                sub_castable = (sub_requirement <= self.player.details.sub_job_level)
            end
            return main_castable or sub_castable
        else
            return false
        end
    elseif Utilities:arrayContains(Actions.ja_castable_prefixes, resolved_ability.prefix) then
        local available_ja = T(windower.ffxi.get_abilities().job_abilities)
        return available_ja:contains(resolved_ability.id)
    elseif Utilities:arrayContains(Actions.ws_castable_prefixes, resolved_ability.prefix) then
        local available_ws = T(windower.ffxi.get_abilities().weapon_skills)
        return available_ws:contains(resolved_ability.id)
    end
    return false
end

function Actions:isRecastReady(full_ability)
    if not self.player or not full_ability then return false end

    local needs_recast_id = true
    if full_ability.prefix and Utilities:arrayContains(Actions.ws_castable_prefixes, full_ability.prefix) or full_ability.prefix == '/item' then
        needs_recast_id = false
    end

    local ability = full_ability
    if full_ability.res then
        ability = full_ability.res
    else
        return false
    end

    if needs_recast_id and ability.recast_id == nil then return false end

    self.player:update()

    if self:canUse(ability) then
        local recast = 99
        if Utilities:arrayContains(Actions.magic_castable_prefixes, ability.prefix) and self.player:canCastSpells() then
            recast = windower.ffxi.get_spell_recasts()[ability.recast_id]
            if ability.type and ability.type == 'Ninjutsu' then
                local have_item = false
                local usable_tools = {}
                for i,v in pairs(Actions.ninja_tool_reference) do
                    if Utilities:arrayContains(v, ability.id) then
                        table.append(usable_tools, i)
                    end
                    for k,val in pairs(usable_tools) do
                        if Actions.ninja_tool_ids[val] and Utilities:haveItem(Actions.ninja_tool_ids[val]) then
                            have_item = true
                        end
                    end
                end
                return (recast == 0) and have_item
            end
            return (recast == 0) and (self.player.vitals.mp >= ability.mp_cost)
        elseif Utilities:arrayContains(Actions.ja_castable_prefixes, ability.prefix) and self.player:canJaWs() and ability.prefix ~= '/pet' then
            recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
            return (recast == 0) and (self.player.vitals.tp >= ability.tp_cost)
        elseif Utilities:arrayContains(Actions.ws_castable_prefixes, ability.prefix) and self.player:canJaWs() then
            return (self.player.status == 1) and (self.player.vitals.tp > 999)
        elseif ability.prefix == '/pet' and self.player:canJaWs() then
            if ability.type == 'Monster' then
                local charges_left = 0
                local charges_required = ability.mp_cost
                local recast = windower.ffxi.get_spell_recasts()[ability.recast_id]
                local pet = windower.ffxi.get_mob_by_target('pet')
                charges_left = math.floor(((15 * 3) - recast) / 15)
                if not pet then return false end
                return (charges_left >= charges_required) and (pet.status == 1) and (os.clock() - self.last_monster_time > (Utilities:valueAtKey(Actions.bst_animations, self.last_monster_abil) or 5))
            else
                recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
                return recast == 0
            end
        elseif ability.prefix == '/item' and self.player:canJaWs() then
            if (os.clock() - self.last_item_time > 8) then
                recast = 0
            end
            local resolved_item = Utilities.res.items:with('en',ability['name']:lower()) or Utilities.res.items:with('enl',ability['name']:lower()) or nil
            if resolved_item and not Utilities:haveItem(resolved_item.id) then
                recast = 99
            end
            return recast == 0
        elseif ability.prefix == '/ra' and self.player:canJaWs() then
            recast = 0
            return recast == 0
        end
    end
    return false
end

function Actions:resolveAbility(raw_ability)
    if not raw_ability then return false end

    local action = {}
    local lower_name = raw_ability.name:lower()

    if Utilities:arrayContains(self.magic_castable_prefixes, raw_ability.prefix) then
        action = Utilities.res.spells:with('en',raw_ability['name']) or Utilities.res.spells:with('enl',raw_ability['name']:lower()) or nil
        if next(action) ~= nil then
            return action
        end
    elseif S{'/jobability', '/pet', '/ja'}:contains(raw_ability.prefix) then
        action = Utilities.res.job_abilities:with('en',raw_ability['name']) or Utilities.res.job_abilities:with('enl',raw_ability['name']:lower()) or nil
        if next(action) ~= nil then
            return action
        end
    elseif Utilities:arrayContains(self.ws_castable_prefixes, raw_ability.prefix) then
        action = Utilities.res.weapon_skills:with('en',raw_ability['name']) or nil
        action.range = 4
        if next(action) ~= nil then
            return action
        end
    elseif raw_ability.prefix == '/item' then
        action = {
            ['prefix'] = '/item',
            ['tp_cost'] = 0,
            ['declared_target'] = raw_ability.target,
            ['type'] = "Item",
            ['targets'] = {
                "Self"
            },
            ['range'] = 12,
            ['name'] = raw_ability.name
        }
        if next(action) ~= nil then
            return action
        end
    elseif raw_ability.prefix == '/ra' then
        action = {
            ['prefix'] = '/ra',
            ['tp_cost'] = 0,
            ['declared_target'] = raw_ability.target,
            ['type'] = "Ranged Attack",
            ['targets'] = {
                "Enemy"
            },
            ['range'] = 22,
            ['name'] = raw_ability.name
        }
        if next(action) ~= nil then
            return action
        end
    end
    return false
end

function Actions:testActions(list, ltype, mob)
    local list_type = ltype or 'combat'
    local actions = list or nil
    local mob = mob or nil

    if list_type == 'combat' or list_type == 'precombat' then
        -- mob = windower.ffxi.get_mob_by_index(info.mob_to_fight.index) or nil
    end

    for i,ability in ipairs(actions) do
        local action_res = {}
        local target = windower.ffxi.get_mob_by_target(ability.target) or mob

        action_res = ability.res
        action_res.declared_target = ability.target

        if action_res and next(action_res) ~= nil then  -- Resolve Ability
            -- notice(ability.name..' is recast ready '..tostring(self:isRecastReady(ability)))
            if self:isRecastReady(ability) then  -- Test Recast Time/Charges/Inventory/MP/can act
                -- notice(ability.name..' is in range '..tostring(self:inRange(ability)))
                if self:inRange(ability) then         -- Test target is in range

                    if action_res.type == 'Trust' then
                        if not Utilities:arrayContains(self.to_use, ability.name) then
                            self:addToUse(ability, ltype)
                        end
                    end
                    -- notice(ability.name..' are conditions true '..tostring(self:testConditions(ability, 'combat', mob)))
                    if action_res.type ~= 'Trust' and self:testConditions(ability, 'combat', mob) then
                        -- notice(ability.name)
                        if ability.prefix == '/ra' and not Utilities:arrayContains(self.once_per_combat, ability) then
                            table.append(self.once_per_combat, ability)
                            self:addToUse(ability, ltype)
                        end

                        self:addToUse(ability, ltype)
                    end
                end
            end
        end
    end
end

function Actions:testConditions(ability, --[[optional]]source, --[[optional]]mob_obj)

    if not ability.conditions then return true end

    local conditions = ability.conditions
    local mob_obj = mob_obj or windower.ffxi.get_mob_by_target('t') or nil
    local action = ability
    local src = source or nil

    if not self.player or next(conditions) == nil then return false end

    self.player:update()
    local decision = false
    local func_map = {
        ['tpgt'] = function(value) return self.player.vitals.tp > value end,
        ['tplt'] = function(value) return self.player.vitals.tp < value end,
        ['ready'] = function(value) return self:isRecastReady(action) end,
        ['hpplt'] = function(value) return self.player.vitals.hpp < value end,
        ['hppgt'] = function(value) return self.player.vitals.hpp > value end,
        ['mpplt'] = function(value) return self.player.vitals.mpp < value end,
        ['mppgt'] =  function(value) return self.player.vitals.mpp > value end,
        ['mobhpplt'] = function(value) return mob_obj and mob_obj.details and mob_obj.details.hpp < value end,
        ['mobhppgt'] = function(value) return mob_obj and mob_obj.details and mob_obj.details.hpp > value end,
        ['once'] = function()
                        local flag = false
                        if src and src == 'to_use' then
                            flag = true
                        end
                        if Utilities:arrayContains(self.once_per_combat, action.name) and not flag then
                            return false
                        end
                        return true
                    end,
        ['absent'] = function(value)
                        if value:lower() == 'pet' then return windower.ffxi.get_mob_by_target('pet') == nil end
                        return not self.player:hasBuff(value:lower()) end,
        ['present'] = function(value)
                        if value:lower() == 'pet' then return windower.ffxi.get_mob_by_target('pet') ~= nil end
                        return self.player:hasBuff(value:lower()) end,
        ['pethpplt'] = function(value)
                        local pet = windower.ffxi.get_mob_by_target('pet') or nil
                        return pet ~= nil and pet.hpp < value end,
        ['pethppgt'] = function(value)
                        local pet = windower.ffxi.get_mob_by_target('pet') or nil
                        return pet ~= nil and pet.hpp > value end,
        ['petstatus'] = function(value)
                        local pet = windower.ffxi.get_mob_by_target('pet') or nil
                        return pet ~= nil and pet.status ~= value end,
        ['inqueue'] = function(value) return Utilities:arrayContains(self.to_use, value) end,
        ['notinqueue'] = function(value) return not Utilities:arrayContains(self.to_use, value) end,
        ['strengthlt'] = function(value, modifier) if not modifier then return false end return not self.player:hasBuff(value, modifier) end,
        ['resonatingwith'] = function(value) if mob_obj and mob_obj.resonating_window == nil then return false end
                            local time_left = mob_obj.resonating_window - (os.clock() - mob_obj.resonating_start_time)
                            local window_breeched = os.clock() - mob_obj.resonating_start_time > 3
                            return Utilities:arrayContains(mob_obj.resonating, value) and window_breeched and time_left >= 0.5 end,
        ['notresonatingwith'] = function(value)
                            if mob_obj and mob_obj.resonating_window == nil then return false end
                            -- local time_left = mob_obj.resonating_window - (os.clock() - mob_obj.resonating_start_time)
                            return not Utilities:arrayContains(mob_obj.resonating, value) end,
        ['notresonating'] = function(value)
                                if mob_obj and mob_obj.resonating_window == nil then return true end
                                local time_left = mob_obj.resonating_window - (os.clock() - mob_obj.resonating_start_time)
                                return (time_left <= 0)
                            end,
        ['resonatingstepgt'] = function(value) return mob_obj.resonating_step > value end
    }

    for i,v in pairs(conditions) do
        local cond = v.condition
        local value = v.value or ''
        local modifier = v.modifier or nil

        if not cond then return false end

        if func_map[cond] ~= nil then
            decision = func_map[cond](value, modifier)
        end
        if decision == false then return false end
    end
    return decision
end

function Actions:addToUse(action, list_type) -- Unecessary, as most things.
    if not Utilities:arrayContains(self.to_use, action.name) then
        if Utilities:arrayContains(action, 'once') then
            if list_type == 'combat' and not Utilities:arrayContains(self.once_per_combat, action.name) then
                table.append(self.once_per_combat, action.name)
            elseif list_type == 'noncombat' and not Utilities:arrayContains(self.once_per_noncombat, action) then
                table.append(self.once_per_noncombat, action)
            elseif list_type == 'precombat' and not Utilities:arrayContains(self.once_per_precombat, action) then
                table.append(self.once_per_precombat, action)
            elseif list_type == 'postcombat' and not Utilities:arrayContains(self.once_per_postcombat, action) then
                table.append(self.once_per_postcombat, action)
            end
        end
        table.append(self.to_use, action)
    end
end

function Actions:runActions(observer_obj)
    self.player:update()

    if next(self.to_use) ~= nil and observer_obj.is_busy == false then

        local target = windower.ffxi.get_mob_by_target(self.to_use[1].target)
        if target then
            if observer_obj.mob_to_fight and observer_obj.mob_to_fight.index == target.index then
                target = observer_obj.mob_to_fight.obj
            else
                target = MobObject.constructMob(target)
            end
        end
        local ability = self.to_use[1]
        local resolved_ability = self.to_use[1]['res']

        if observer_obj:timeSinceLastAttackPkt() > 2 then
            if self:inRange(ability) then
                -- notice(ability.name..' | are conditions true '..tostring(self:testConditions(ability, 'to_use', target)))
                if not self:testConditions(ability, 'to_use', target) or not self:isRecastReady(ability) then
                    table.remove(self.to_use, 1)
                    return
                end

                observer_obj:setBusy()
                windower.ffxi.run(false)

                if not ability.prefix or not ability.name or not ability.target then return end

                if ability.prefix == '/item' then
                    observer_obj:setCasting()
                    self:setLastItemTime()
                    self:sendCommand('input '..ability.prefix..' "'..ability.name..'" <'..ability.target..'>')
                elseif Utilities:arrayContains(self.magic_castable_prefixes, ability.prefix) then
                    observer_obj:setCasting()
                    self:setLastSpell(ability)
                    coroutine.sleep(.7)
                    self:sendCommand('input '..ability.prefix..' "'..ability.name..'" <'..ability.target..'>')
                elseif ability.prefix == '/pet' then
                    if resolved_ability.type and resolved_ability.type == 'Monster' then
                        self:setLastMonsterTime()
                        self:setLastMonsterAbility(ability)
                        self:setLastJobAbility(ability)
                    end
                    self:sendCommand('input '..ability.prefix..' "'..ability.name..'" <'..ability.target..'>')
                elseif Utilities:arrayContains(self.ws_castable_prefixes, ability.prefix) then
                    self:setLastWeaponSkill(ability.name)
                    self:sendCommand('input '..ability.prefix..' "'..ability.name..'" <'..ability.target..'>')
                elseif ability.prefix == '/ra' then
                    self:sendCommand('input '..ability.prefix..' <'..ability.target..'>')
                else
                    self.last_action = ability.name
                    self:setLastJobAbility(ability)
                    self:sendCommand('input '..ability.prefix..' "'..ability.name..'" <'..ability.target..'>')
                end

                if ability then
                    self:setLastPrefixUsed(ability.prefix)
                else
                    table.remove(self.to_use, 1)
                end

            end
        end
    end
end

function Actions:sendCommand(str)
    local cmd = str or nil
    if cmd then
        windower.send_command(cmd)
    end
end

function Actions:emptyOncePerTables()
    self:emptyOncePerCombat()
    self:emptyOncePerNonCombat()
    self:emptyOncePerPreCombat()
    self:emptyOncePerPostCombat()
end

function Actions:emptyOncePerCombat()
    self.once_per_combat = T{}
end

function Actions:emptyOncePerPreCombat()
    self.once_per_precombat = T{}
end

function Actions:emptyOncePerPostCombat()
    self.once_per_postcombat = T{}
end

function Actions:emptyOncePerNonCombat()
    self.once_per_noncombat = T{}
end

function Actions:emptyToUse()
    self.to_use = T{}
end

function Actions:handleActionNotification(act, player, observer, statecontroller)
    local actor = windower.ffxi.get_mob_by_id(act.actor_id)
    local role = statecontroller.role or 'master'

    if actor and actor.id == self.player.id then
        local target_count = act.target_count
        local category = act.category
        local param = act.param
        local recast = act.recast
        local targets = act.targets
        local primarytarget = windower.ffxi.get_mob_by_id(targets[1].id)
        local valid_target = act.valid_target
        local paralyzed = targets[1].actions[1].message
        local para_flag = false

        if paralyzed == 29 or paralyzed == 84 then
            para_flag = true
        end

        if category == 1 then -- Attack round
            observer:setAttackRoundCalcTime()
            observer:setLastAttackRoundTime()
        end

        --notice('(Targ.Act.Msg) Category: '..category..'; TAM: '..paralyzed..';')
        if category == 6 or category == 14 then  -- Finished JA
            if Utilities.res.job_abilities[param] then
                local ability = Utilities.res.job_abilities[param]
                if self.to_use and not para_flag then
                    for i,v in pairs(self.to_use) do
                        if v.name:lower() == Utilities.res.job_abilities[param].en:lower() then
                            table.remove(self.to_use, i)
                        end
                    end
                end

                if self.to_use[1] and (self.to_use[1].prefix == '/jobability' or self.to_use[1].prefix == '/weaponskill') then
                    coroutine.schedule(function() observer:forceUnbusy() end, 0.7)
                else
                    coroutine.schedule(function() observer:forceUnbusy() end, 0.7)
                end
            end
        end

        if category == 8 then -- Interrupted Casting
            if param == 28787 then
                notice('Interrupted.')
                coroutine.schedule(function() observer:forceUnbusy() end, 1.7)
            end
        end

        if category == 9 then
            if param == 28787 then
                return
            end
            local item_id = targets[1].actions[1].param or nil
            local item = Utilities.res.items[item_id].en or Utilities.res.items[item_id].enl
            if param == 24931 then -- Initiation
                if self.to_use and not para_flag then
                    for i,v in pairs(self.to_use) do
                        if v.name:lower() == item:lower() then
                            table.remove(self.to_use, i)
                        end
                    end
                end
                coroutine.schedule(function() observer:forceUnbusy() end, recast)
            elseif param == 28787 then -- Interruption
                ccoroutine.schedule(function() observer:forceUnbusy() end, recast)
            end
        end

        if category == 3 then -- Finished Weapon Skill
            if Utilities.res.weapon_skills[param] or Utilities.res.job_abilities[param] then

                local ws = Utilities.res.weapon_skills[param] or nil
                local ability = Utilities.res.job_abilities[param] or nil

                if self.to_use and not para_flag then
                    for i,v in pairs(self.to_use) do
                        local ws_name = ws and ws.en:lower() or nil
                        local abil_name = ability and ability.en:lower() or nil
                        if v.name:lower() == ws_name or v.name:lower() == abil_name then
                            table.remove(self.to_use, i)
                            coroutine.schedule(function() observer:forceUnbusy() end, 1)
                            break
                        end
                    end
                end
            end
        end

        if category == 7 then
            --24931  Started WS
            if param == 28787 then
                notice('Failed TP move. Plz Unbusy.')
            end
        end

        if category == 4 then -- Finished Spell
            if Utilities.res.spells[param] then
                local ability = Utilities.res.spells[param]
                if self.to_use and not para_flag then
                    for i,v in pairs(self.to_use) do
                        if v.name:lower() == Utilities.res.spells[param].en:lower() then
                            table.remove(self.to_use, i)
                            break
                        end
                    end
                    coroutine.schedule(function() observer:forceUnbusy() end, 1.7)
                end
            end
            if param == 0 then
                self.to_use = T{}
                coroutine.schedule(function() observer:forceUnbusy() end, 1.7)
            end
        end
    end

    if actor and actor.id ~= self.id and role == 'master' then
        local category = act.category
        local param = act.param
        local recast = act.recast
        local targets = T(act.targets)
        local party_ids = observer:setPartyClaimIds()

        if category == 1 then -- Melee attack against Player or Party
            for _,v in pairs(party_ids) do
                if targets:with('id', v) then
                    observer:addToAggro(actor.id)
                end
            end
        end
        if category == 11 and not Utilities:arrayContains(party_ids, actor.id) then -- Matamata Cleave/Type Attack
            for _,v in pairs(party_ids) do
                if targets:with('id', v) then
                    observer:addToAggro(actor.id)
                end
            end
        end
    end
end

return Actions