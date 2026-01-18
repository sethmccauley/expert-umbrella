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
Actions.ja_castable_prefixes = S{'/jobability', '/ja', '/pet'}
Actions.ws_castable_prefixes = S{'/weaponskill','/ws'}
Actions.magic_castable_prefixes = S{'/magic','/ma','/ninjutsu','/nin','/song','/sing'}
Actions.action_types = T{'spells','job_abilities','weapon_skills'}
Actions.stratagems = S{234,235,215,216,217,218,219,220,221,222}
Actions.strat_charge_time = {[1]=240,[2]=120,[3]=80,[4]=60,[5]=48}
Actions.light_arts_buff_ids = T{[211] = 358, [234] = 401}
Actions.dark_arts_buff_ids = T{[212] = 359,[235] = 402}
Actions.packets = require('packets')

-- Condition function map (module-level for performance)
-- Each function receives (ctx, value, modifier) where ctx contains: self, ability, mob_obj, observer_obj, src, pet
Actions.condition_funcs = {
    ['tpgt'] = {
        allowed_targets = S{'Self'},
        coerce_to = 'Self',
        func = function(ctx, value)
            local tp = tonumber(ctx.mob_obj.tp)
            local threshold = tonumber(value)
            return tp and threshold and (tp > threshold)
        end
    },
    ['tplt'] = {
        allowed_targets = S{'Self'},
        coerce_to = 'Self',
        func = function(ctx, value)
            local tp = tonumber(ctx.mob_obj.tp)
            local threshold = tonumber(value)
            return tp and threshold and (tp < threshold)
        end
    },
    ['ready'] = {
        -- No allowed_targets, this references an ability not a target
        func = function(ctx, value)
            return ctx.self:isRecastReady(ctx.ability)
        end
    },
    ['hpplt'] = {
        allowed_targets = S{'Self','Party','Alliance','Enemy'},
        func = function(ctx, value)
            local hpp = ctx.mob_obj and tonumber(ctx.mob_obj.hpp)
            local threshold = tonumber(value)
            return hpp and threshold and (hpp < threshold)
        end
    },
    ['hppgt'] = {
        allowed_targets = S{'Self','Party','Alliance','Enemy'},
        func = function(ctx, value)
            local hpp = ctx.mob_obj and tonumber(ctx.mob_obj.hpp)
            local threshold = tonumber(value)
            return hpp and threshold and (hpp > threshold)
        end
    },
    ['missinghplt'] = {
        allowed_targets = S{'Self','Party','Alliance'},
        func = function(ctx, value)
            local missing_hp = math.floor(ctx.mob_obj.hp * (100 - ctx.mob_obj.hpp) / ctx.mob_obj.hpp)
            local threshold = tonumber(value)
            return missing_hp and threshold and (missing_hp < value)
        end
    },
    ['missinghpgt'] = {
        allowed_targets = S{'Self','Party','Alliance'},
        func = function(ctx, value)
            local missing_hp = math.floor(ctx.mob_obj.hp * (100 - ctx.mob_obj.hpp) / ctx.mob_obj.hpp)
            local threshold = tonumber(value)
            return missing_hp and threshold and (missing_hp > value)
        end
    },
    ['mpplt'] = {
        allowed_targets = S{'Self','Party','Alliance'},
        coerce_to = 'Self',
        func = function(ctx, value)
            local mpp = ctx.mob_obj and tonumber(ctx.mob_obj.mpp)
            local threshold = tonumber(value)
            return mpp and threshold and (mpp < threshold)
        end
    },
    ['mppgt'] = {
        allowed_targets = S{'Self','Party','Alliance'},
        coerce_to = 'Self',
        func = function(ctx, value)
            local mpp = ctx.mob_obj and tonumber(ctx.mob_obj.mpp)
            local threshold = tonumber(value)
            return mpp and threshold and (mpp > threshold)
        end
    },
    ['mobhpplt'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            local hpp = ctx.mob_obj.hpp or (ctx.mob_obj.details and ctx.mob_obj.details.hpp)
            return hpp and hpp < value
        end
    },
    ['mobhppgt'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            local hpp = ctx.mob_obj.hpp or (ctx.mob_obj.details and ctx.mob_obj.details.hpp)
            return hpp and hpp > value
        end
    },
    ['adhoc'] = {
        func = function(ctx) return ctx.ability and ctx.ability.res and ctx.ability.res.ad_hoc == true end
    },
    ['once'] = {
        func = function(ctx)
            local flag = (ctx.src and ctx.src == 'to_use')
            if Utilities:arrayContains(ctx.self.once_per_combat, ctx.ability.name) and not flag then
                return false
            end
            return true
        end
    },
    ['absent'] = {
        allowed_targets = S{'Self','Party','Pet'},
        func = function(ctx, value)
            if type(value) == 'string' and value:lower() == 'pet' then
                return ctx.pet == nil
            end
            return not ctx.self.player:hasBuff(value)
        end
    },
    ['present'] = {
        allowed_targets = S{'Self','Party','Pet'},
        func = function(ctx, value, modifier)
            if type(value) == 'string' and value:lower() == 'pet' then
                if modifier then
                    return ctx.pet and ctx.pet.name:lower() == modifier:lower()
                end
                return ctx.pet ~= nil
            end
            return ctx.self.player:hasBuff(value)
        end
    },
    ['buffdurationremaininglt'] = {
        allowed_targets = S{'Self'},
        func = function(ctx, value, modifier)
            if not modifier or not value then return false end
            local buff_identifier = type(value) == 'string' and value:lower() or ''
            if not ctx.self.player:hasBuff(value) then return true end
            return ctx.self.player:buffTimeLeft(buff_identifier) < modifier
        end
    },
    ['buffdurationremaininggt'] = {
        allowed_targets = S{'Self'},
        func = function(ctx, value, modifier)
            if not modifier or not value then return false end
            local buff_identifier = type(value) == 'string' and value:lower() or ''
            if not ctx.self.player:hasBuff(value) then return false end
            return ctx.self.player:buffTimeLeft(buff_identifier) > modifier
        end
    },
    ['pethpplt'] = {
        func = function(ctx, value)
            return ctx.pet ~= nil and ctx.pet.hpp < value
        end
    },
    ['pethppgt'] = {
        func = function(ctx, value)
            return ctx.pet ~= nil and ctx.pet.hpp > value
        end
    },
    ['petstatus'] = {
        func = function(ctx, value)
            return ctx.pet ~= nil and ctx.pet.status ~= value
        end
    },
    ['inqueue'] = {
        func = function(ctx, value) return Utilities:arrayContains(ctx.self.to_use, value) end
    },
    ['notinqueue'] = {
        func = function(ctx, value) return not Utilities:arrayContains(ctx.self.to_use, value) end
    },
    ['strengthlt'] = {
        allowed_targets = S{'Self','Party'},
        func = function(ctx, value, modifier)
            if not modifier then return false end
            return not ctx.self.player:hasBuff(value, modifier)
        end
    },
    ['resonatingwith'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            if not ctx.mob_obj or ctx.mob_obj.resonating_window <= 0 then return false end
            local time_left = ctx.mob_obj.resonating_window - (os.clock() - ctx.mob_obj.resonating_start_time)
            local window_breeched = os.clock() - ctx.mob_obj.resonating_start_time > 3
            return Utilities:arrayContains(ctx.mob_obj.resonating, value) and window_breeched and time_left >= 0.5
        end
    },
    ['notresonatingwith'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            if not ctx.mob_obj or ctx.mob_obj.resonating_window <= 0 then return false end
            return not Utilities:arrayContains(ctx.mob_obj.resonating, value)
        end
    },
    ['notresonating'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            if not ctx.mob_obj or ctx.mob_obj.resonating_window <= 0 then return true end
            local time_left = ctx.mob_obj.resonating_window - (os.clock() - ctx.mob_obj.resonating_start_time)
            return (time_left <= 0)
        end
    },
    ['resonatingstepgt'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            return ctx.mob_obj and ctx.mob_obj.resonating_step > value
        end
    },
    ['aggrotablegt'] = {
        func = function(ctx, value)
            if not ctx.observer_obj or not ctx.observer_obj.aggro then return false end
            local count = 0
            for _ in pairs(ctx.observer_obj.aggro) do count = count + 1 end
            return count > value
        end
    },
    ['aggrotablelt'] = {
        func = function(ctx, value)
            if not ctx.observer_obj or not ctx.observer_obj.aggro then return false end
            local count = 0
            for _ in pairs(ctx.observer_obj.aggro) do count = count + 1 end
            return count < value
        end
    },
    ['mobisnamed'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            return ctx.mob_obj and ctx.mob_obj.name == value
        end
    },
    ['mobisnotnamed'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            return ctx.mob_obj and ctx.mob_obj.name ~= value
        end
    },
    ['mainjobinparty'] = {
        func = function(ctx, value)
            if not value or not ctx.observer_obj then return false end
            return ctx.observer_obj:partyContains(value, 'main')
        end
    },
    ['mainjobnotinparty'] = {
        func = function(ctx, value)
            if not value or not ctx.observer_obj then return false end
            return not ctx.observer_obj:partyContains(value, 'main')
        end
    },
}

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
    self.last_sent_ability = nil
    self.last_sent_ability_time = 0

    self.combat_actions = T{}
    self.adhoc_actions = T{}
    self.noncombat_actions = T{}
    self.precombat_actions = T{}
    self.postcombat_actions = T{}
    self.engage_distance = 16
    self.should_engage = true
    self.combat_actions_delay = 0
    self.mirror_masters_engage = false

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

    -- Reset action lists before populating
    self.combat_actions = T{}
    self.adhoc_actions = T{}
    self.noncombat_actions = T{}
    self.precombat_actions = T{}
    self.postcombat_actions = T{}
    self.trust_list = T{}
    self.to_use = T{}
    self.once_per_combat = T{}
    self.once_per_precombat = T{}
    self.once_per_postcombat = T{}
    self.once_per_noncombat = T{}

    for i,v in pairs(action_list) do
        if i == 'engage_distance' then self:setEngageDistance(v)
        elseif i == 'should_engage' then self:setShouldEngage(v)
        elseif i == 'combat_actions_delay' then self.combat_actions_delay = tonumber(v)
        elseif i == 'mirror_masters_engage' then self.mirror_masters_engage = v
        elseif i == 'combat' then self.combat_actions = self:processAbilities(v)
        elseif i == 'precombat' then self.precombat_actions = self:processAbilities(v)
        elseif i == 'postcombat' then self.postcombat_actions = self:processAbilities(v)
        elseif i == 'noncombat' then self.noncombat_actions = self:processAbilities(v)
        elseif i == 'trusts' then self.trust_list = self:processAbilities(v)
        elseif i == 'adhoc' then self.adhoc_actions = self:processAbilities(v) end
    end
    Utilities:trimRes()
end
function Actions:processAbilities(table)
    if type(table) ~= 'table' then return nil end

    for i,v in pairs(table) do
        if v.chain then
            for j,action in ipairs(v.chain) do
                v.chain[j]['res'] = self:resolveAbility(action)
                v.chain[j]['queue_type'] = 'enqueue'
            end
            table[i]['is_chain'] = true
        else
            table[i]['res'] = self:resolveAbility(v)
        end
    end
    return table
end
function Actions:setEngageDistance(value)
    if value < 1 or value > 24 then return nil end
    self.engage_distance = value
end
function Actions:setShouldEngage(value)
    if type(value) ~= 'boolean' then return nil end
    self.should_engage = value
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
    self.last_monster_ability = monster_ability
    self:updateLastMonsterTime()
end
function Actions:setLastMonsterTime()
    self.last_monster_time = os.clock()
end
function Actions:setLastPrefixUsed(prefix)
    if type(prefix) ~= 'string' then return end
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
function Actions:disengageMob()
    if not self.player then return end
    local packet = self.packets.new('outgoing', 0x01A, {
        ["Category"]=4,
        ["Target Index"]=self.player.index,
        ["Target"]=self.player.id})
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

function Actions:triggerAdHoc(cmd, observer_obj)
    if not self.adhoc_actions then return end

    local ability = self.adhoc_actions[cmd]
    if not ability then return end

    local abilities_to_process = {}
    if ability.is_chain and ability.chain then
        for _, chain_ability in ipairs(ability.chain) do
            chain_ability.conditions = ability.conditions
            table.insert(abilities_to_process, chain_ability)
        end
    elseif ability.res then
        table.insert(abilities_to_process, ability)
    end

    local target_cache = {}
    for _, proc_ability in ipairs(abilities_to_process) do
        if not proc_ability.res then break end

        if not target_cache[proc_ability.target] then
            target_cache[proc_ability.target] = self:resolveTarget(proc_ability.target, proc_ability.res, observer_obj)
        end

        local resolved_target = target_cache[proc_ability.target]
        if not resolved_target then break end

        if self:isBatchTargets(resolved_target) then
            for _, single_target in ipairs(resolved_target) do
                local ns_target = self:normalizeTarget(single_target)
                local chain_due_to_batch = true
                self:processAdHocAbility(proc_ability, ns_target, observer_obj, chain_due_to_batch)
            end
        else
            local normalized_target = self:normalizeTarget(resolved_target)
            self:processAdHocAbility(proc_ability, normalized_target, observer_obj)
        end
    end
end
function Actions:processAdHocAbility(ability, target_obj, observer_obj, chain_due_to_batch)
    local normalized_target = target_obj
    if not self:inRange(ability, normalized_target) then return false end
    if ability.conditions and not self:testConditions(ability, 'adhoc', normalized_target, observer_obj) then
        return false
    end
    local ability_copy = Utilities:shallowCopy(ability)
    ability_copy.res = Utilities:shallowCopy(ability.res)
    ability_copy.targeting = normalized_target.id
    ability_copy.res.ad_hoc = true
    ability_copy.checks = {recast = false, conditions = false, range = true, duplicate = false}
    -- if chain_due_to_batch then ability_copy.queue_type = 'enqueue' end
    self:addToUse(ability_copy, 'adhoc')
    return true
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
        self:handleCombat(StateController, observer_obj)
    elseif StateController.state == 'precombat' then
        -- notice('precombat')
    elseif StateController.state == 'postcombat' then
        -- notice('postcombat')
    elseif StateController.state == 'idle' or StateController.state == 'travel' then
        self:handleNonCombat(observer_obj)
    end
    self:runActions(StateController, observer_obj)
end
function Actions:handleCombat(StateController, observer_obj)
    if observer_obj and observer_obj.mob_to_fight and not observer_obj.mob_to_fight.obj then
        return
    end

    local mob = observer_obj.mob_to_fight.obj
    if mob and mob.updateDetails then mob:updateDetails() else return end
    mob = observer_obj.mob_to_fight.obj:getFlatCopy()

    if self.player.status == 0 and self.should_engage then -- We are not engaged while in a combat state and we should be engaged.

        if (mob.distance:sqrt() < (self.engage_distance or 5)) and observer_obj:timeSinceLastAttackPkt() > 3 and observer_obj:timeSinceLastAttackRound() > observer_obj.attack_round_calc then
            observer_obj:setAtkPkt()
            self:attackMob(mob)
            notice(Utilities:printTime()..' Attack invoked '..mob.name..' '..mob.index..'')

            observer_obj:setActionDelay('engage')
        end

    elseif self.player.status == 0 and not self.should_engage then

        if mob.distance:sqrt() < (self.engage_distance or 5) then
            local current_target = observer_obj:hasCurrentTarget()
            if current_target == 0 or (current_target ~= 0 and current_target ~= mob.index) then
                self.targetMob(self, mob)
            end
        end

    end

    if self.player.status == 1 or not self.should_engage then -- We are in fact engaged or we shouldn't_engage and while in combat state.

        if next(self.combat_actions) ~= nil then
            self:testActions(self.combat_actions, 'combat', observer_obj)
        end

    end
end
function Actions:handleNonCombat(observer_obj)
    if self.player.status == 0 then
        if next(self.noncombat_actions) ~= nil then
            self:testActions(self.noncombat_actions, 'noncombat', observer_obj)
        end
    end
    if next(self.trust_list) ~= nil and (observer_obj:isPartyLead() or observer_obj:isSolo()) and not observer_obj:inAlliance() and not observer_obj:inCity() and observer_obj.role ~= 'slave' then
        self:handleTrusts(observer_obj)
    end
end

function Actions:inRange(full_ability, target_obj)
    if not self.player or not full_ability then return false end

    if not target_obj then return false end

    self.player:update()

    local self_target = self.player.mob
    local targ_obj = target_obj
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
            adjustment = -4
        end
    end

    if action.prefix == '/pos' then
        return true
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

    -- Position Action handling.
    if (resolved_ability and resolved_ability.prefix == '/pos' and self.player:canJaWs()) then return true end

    local learned = windower.ffxi.get_spells()[resolved_ability.id]

    -- This is a shortcut, hacky mess, this should test if they have the gear required!
    if resolved_ability.name == "Honor March" then return true end
    if resolved_ability.name == "Impact" then return true end

    if Actions.magic_castable_prefixes:contains(resolved_ability.prefix) then
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
    elseif Actions.ja_castable_prefixes:contains(resolved_ability.prefix) then
        if Actions.light_arts_buff_ids[resolved_ability.id] then
            if self.player:hasBuff(Actions.light_arts_buff_ids[resolved_ability.id]) then
                return false
            end
        end
        if Actions.dark_arts_buff_ids[resolved_ability.id] then
            if self.player:hasBuff(Actions.dark_arts_buff_ids[resolved_ability.id]) then
                return false
            end
        end
        local available_ja = T(windower.ffxi.get_abilities().job_abilities)
        return available_ja:contains(resolved_ability.id)
    elseif Actions.ws_castable_prefixes:contains(resolved_ability.prefix) then
        local available_ws = T(windower.ffxi.get_abilities().weapon_skills)
        return available_ws:contains(resolved_ability.id)
    end
    return false
end
function Actions:isRecastReady(full_ability)
    if not self.player or not full_ability then return false end

    local needs_recast_id = true
    if full_ability.prefix and Actions.ws_castable_prefixes:contains(full_ability.prefix) 
            or full_ability.prefix == '/item'
            or full_ability.prefix == '/ra'
            or full_ability.prefix == '/pos' then
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
        if Actions.magic_castable_prefixes:contains(ability.prefix) and self.player:canCastSpells() then
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
        elseif Actions.ja_castable_prefixes:contains(ability.prefix) and self.player:canJaWs() and ability.prefix ~= '/pet' then
            if Actions.stratagems:contains(ability.id) then
                local charges_available = self:getAvailableStratagems()
                return charges_available > 0
            end
            recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
            return (recast == 0) and (self.player.vitals.tp >= ability.tp_cost)
        elseif Actions.ws_castable_prefixes:contains(ability.prefix) and self.player:canJaWs() then
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
            local resolved_item = Utilities:getItemByName(ability['name'])
            if resolved_item and not Utilities:haveItem(resolved_item.id) then
                recast = 99
            end
            return recast == 0
        elseif ability.prefix == '/ra' and self.player:canJaWs() then
            recast = 0
            return recast == 0
        elseif ability.prefix == '/pos' and self.player:canJaWs() then
            recast = 0
            return recast == 0
        end
    end
    return false
end
function Actions:getMaxStratagems()
    if S{self.player.details.main_job, self.player.details.sub_job}:contains('SCH') then
        local lvl = (self.player.details.main_job == 'SCH') and self.player.details.main_job_level or self.player.details.sub_job_level
        return math.floor(((lvl -10) / 20) + 1)
    else
        return 0
    end
end
function Actions:getAvailableStratagems()
	local recastTime = windower.ffxi.get_ability_recasts()[231] or 0
	local maxStrats = self:getMaxStratagems()
	if (maxStrats == 0) then return 0 end
	local stratsUsed = (recastTime/Actions.strat_charge_time[maxStrats]):ceil()
	return maxStrats - stratsUsed
end
function Actions:resolveAbility(raw_ability)
    if not raw_ability then return false end

    local action = {}
    if self.magic_castable_prefixes:contains(raw_ability.prefix) then
        action = Utilities:cacheResource('spells', raw_ability.name)
    elseif S{'/jobability', '/pet', '/ja'}:contains(raw_ability.prefix) then
        action = Utilities:cacheResource('job_abilities', raw_ability.name)
    elseif self.ws_castable_prefixes:contains(raw_ability.prefix) then
        action = Utilities:cacheResource('weapon_skills', raw_ability.name)
        action.range = 4
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
    elseif raw_ability.prefix == '/pos' then
        action = {
            ['prefix'] = '/pos',
            ['tp_cost'] = 0,
            ['declared_target'] = raw_ability.target,
            ['type'] = "Positioning",
            ['targets'] = {
                "Enemy","Ally","Party"
            },
            ['range'] = 50,
            ['name'] = raw_ability.name,
            ['degrees'] = raw_ability.degrees or 0,
            ['distance'] = raw_ability.distance or 2
        }
    end

    if not action then return false end

    if action.target and not action.target_type_string then
        action.target_type_string = self:resolveActionTargetType(raw_ability.target)
    end

    if next(action) ~= nil then
        local action_copy =  Utilities:shallowCopy(action)
        action_copy.ja = nil
        return action_copy
    end
    return false
end

function Actions:resolveActionTargetType(target_string)
    if not target_string then return nil end
    local target_lower = target_string:lower()
    local enemy_strings = S{'t','bt','enemy'}
    local self_strings = S{'self','me'}

    if target_lower:match('^p(%d+)$') or target_lower == 'party' then
        return 'Party'
    end
    if self_strings:contains(target_lower) then
        return 'Self'
    end
    if enemy_strings:contains(target_lower) then
        return 'Enemy'
    end
    if target_lower:match('^a(%d+)$') or target_lower == 'alliance' then
        return 'Alliance'
    end
    if target_lower == 'pet' then
        return 'Pet'
    end
    return 'Specified'
end
-- Self,Pet,NPC,Party,Alliance,Enemy
function Actions:resolveTargetType(target_mob)
    if not target_mob then return nil end

    if target_mob.id == self.player.id then return 'Self' end
    local pet = self.player.mob and self.player.mob.pet_index and windower.ffxi.get_mob_by_index(self.player.mob.pet_index)
    if pet and target_mob.id == pet.id then return 'Pet' end

    local party =  windower.ffxi.get_party()
    if party then
        for i = 0,5 do
            local member = party['p'..i]
            if member and member.mob and member.mob.id == target_mob.id then
                return 'Party'
            end
        end
        for i = 10, 15 do
            local member = party['a'..i]
            if member and member.mob and member.mob.id == target_mob.id then
                return 'Alliance'
            end
        end
        for i = 20, 25 do
            local member = party['a'..i]
            if member and member.mob and member.mob.id == target_mob.id then
                return 'Alliance'
            end
        end
    end

    if target_mob.spawn_type == 16 then
        return 'Enemy'
    end

    return 'NPC'
end
-- Can return a mob object from windower functions OR a table of mob objects
-- Validates, because it can return false if invalid declared target
function Actions:resolveTarget(target_string, ability_res, observer_obj)
    local target_lower = target_string:lower()
    local resolved = nil

    local target_strings = T{'t','bt','pet'}
    local target_groups = T{'party','alliance','enemy'}

    if S{'me','self',self.player.name,'p0'}:contains(target_lower) then
        resolved = self.player.mob
        for i,v in pairs(self.player.vitals) do
            resolved[i] = v
        end
        resolved.target_type_string = 'Self'
        return resolved
    end
    -- A simple target string. Easy.
    if target_strings:contains(target_lower) then
        resolved = windower.ffxi.get_mob_by_target(target_lower)
        local target_type = self:resolveTargetType(resolved)
        local valid = ability_res.targets[target_type] == true
        if not valid then
            return false
        end
        resolved.target_type_string = target_type
        return resolved
    end
    -- Handle alliance slot targets: a10-a15 (alliance 1), a20-a25 (alliance 2)
    local alliance_match = target_lower:match('^a(%d+)$')
    if alliance_match then
        local slot = tonumber(alliance_match)
        resolved = windower.ffxi.get_mob_by_target(slot)
        if resolved then
            resolved.target_type_string = 'Alliance'
            return resolved
        end
        return false
    end
    local party_match = target_lower:match('^p(%d+)$')
    if party_match then
        local slot = tonumber(party_match)
        resolved = windower.ffxi.get_mob_by_target(slot)
        if resolved then
            resolved.target_type_string = 'Party'
            return resolved
        end
        return false
    end
    -- Handle wildcards (can create list of targets)
    local target_batch = T{}
    if target_groups:contains(target_lower) then
        if target_lower == 'party' then
            local party = windower.ffxi.get_party()
            if party then
                for i = 0, 5 do
                    local member = party['p'..i]
                    if member and member.mob then
                        member = Utilities:shallowMerge(member, member.mob)
                        member.target_type_string = 'Party'
                        target_batch:append(member)
                    end
                end
                return target_batch
            end
        end
        if target_lower == 'alliance' then
            local party = windower.ffxi.get_party()
            if party then
                for i = 0, 5 do
                    local member = party['p'..i]
                    if member and member.mob then
                        member = Utilities:shallowMerge(member, member.mob)
                        member.target_type_string = 'Party'
                        target_batch:append(member)
                    end
                end
                for i = 10, 15 do
                    local member = party['a'..i]
                    if member and member.mob then
                        member = Utilities:shallowMerge(member, member.mob)
                        member.target_type_string = 'Alliance'
                        target_batch:append(member)
                    end
                end
                for i = 20, 25 do
                    local member = party['a'..i]
                    if member and member.mob then
                        member = Utilities:shallowMerge(member, member.mob)
                        member.target_type_string = 'Alliance'
                        target_batch:append(member)
                    end
                end
                return target_batch
            end
        end
        if target_lower == 'enemy' then
            -- this should be mob to fight by default
            if observer_obj and observer_obj.mob_to_fight and observer_obj.mob_to_fight.obj then
                resolved = observer_obj.mob_to_fight.obj:getFlatCopy()
                resolved.target_type_string = 'Enemy'
            end
            if resolved then return resolved end
            return false
        end
    end

    resolved = windower.ffxi.get_mob_by_name(target_string)
    if resolved.id and observer_obj.claim_ids:contains(resolved.id) then
        local party = windower.ffxi.get_party()
        if party then
            for i = 0, 5 do
                local member = party['p'..i]
                if member and member.mob and member.mob.id == resolved.id then
                    local append_it = T{'tp','hpp','mp','hp','mpp'}
                    for _,v in pairs(append_it) do
                        if member[v] then resolved[v] = member[v] end
                    end
                end
            end
        end
    end

    resolved.target_type_string = self:resolveTargetType(resolved)
    if resolved then return resolved end

    return false
end
function Actions:isBatchTargets(resolved_target)
    return resolved_target and type(resolved_target) == 'table' and resolved_target[1] ~= nil
end
function Actions:getTargetId(resolved_target)
    if not resolved_target then return nil end
    if resolved_target.mob and resolved_target.mob.id then
        return resolved_target.mob.id
    end
    if resolved_target.id then return resolved_target.id end
    return nil
end
function Actions:normalizeTarget(resolved_target)
    if not resolved_target then return nil end
    if resolved_target.target_type_string then
        if resolved_target.target_type_string == 'Self' then
            for i,v in pairs(windower.ffxi.get_player().vitals) do
                resolved_target[i] = v
            end
        end
        if S{'Party','Alliance'}:contains(resolved_target.target_type_string) then
            if resolved_target.mob then
                for i,v in pairs(resolved_target.mob) do
                    if i ~= 'models' then
                        resolved_target[i] = v
                    end
                end
            end
            return resolved_target
        end
    end
    return resolved_target
end

function Actions:testActions(list, ltype, observer_obj)
    local list_type = ltype or 'combat'
    if not list then return end

    for _,ability in ipairs(list) do

        if ability.is_chain and ability.chain then -- Chain Ability Handling
            local target_cache = {}
            local all_conditions_pass = true

            for _, chain_ability in ipairs(ability.chain) do
                chain_ability.conditions = ability.conditions
                if not target_cache[chain_ability.target] then
                    target_cache[chain_ability.target] = self:resolveTarget(chain_ability.target, chain_ability.res, observer_obj)
                end
                local resolved_target = self:normalizeTarget(target_cache[chain_ability.target])
                if not resolved_target or not self:testConditions(chain_ability, list_type, resolved_target, observer_obj) then
                    all_conditions_pass = false
                    break
                end
            end
            -- Second pass: queue all if conditions passed
            if all_conditions_pass then
                for _, chain_ability in ipairs(ability.chain) do
                    local resolved_target = target_cache[chain_ability.target]
                    local ability_copy = Utilities:shallowCopy(chain_ability)
                    ability_copy.targeting = self:getTargetId(resolved_target)
                    ability_copy.target_type_string = resolved_target.target_type_string
                    ability_copy.checks = {
                        recast = false,      -- isRecastReady
                        conditions = true,  -- testConditions
                        range = true,        -- inRange
                        duplicate = false,    -- Check for duplicate name+target
                    }
                    self:addToUse(ability_copy, 'enqueue')
                end
            end
        elseif not ability.res then
            -- Skip (Cuz there's no friggin Continue)
        elseif not self:isRecastReady(ability) then
            -- Skip
        elseif ability.res.ad_hoc then
            -- Skip
        else
            local resolved_target = self:resolveTarget(ability.target, ability.res, observer_obj)

            if not resolved_target then
                -- Skip (barf)
            else
                local targets = self:isBatchTargets(resolved_target) and resolved_target or {resolved_target}

                if self:isBatchTargets(resolved_target) then
                    for _, single_target in ipairs(resolved_target) do
                        local ns_target = self:normalizeTarget(single_target)

                        if not self:inRange(ability, ns_target) then
                            -- Skip
                        elseif ability.conditions and not self:testConditions(ability, list_type, ns_target, observer_obj) then
                            -- Skip
                        else
                            local ability_copy = Utilities:shallowCopy(ability)
                            ability_copy.targeting = self:getTargetId(ns_target)
                            ability_copy.checks = {
                                recast = false,      -- isRecastReady
                                conditions = false,  -- testConditions
                                range = true,        -- inRange
                                duplicate = true,    -- Check for duplicate name+target
                            }
                            ability_copy.queue_type = 'enqueue'
                            self:addToUse(ability_copy, 'enqueue')
                        end
                    end
                else
                    local ns_target = self:normalizeTarget(resolved_target)

                    if not self:inRange(ability, ns_target) then
                        -- skip
                    elseif ability.res.type == 'Trust' then
                        if not Utilities:arrayContains(self.to_use, ability.name) then
                            self:addToUse(ability, list_type)
                        end
                    elseif not self:testConditions(ability, list_type, ns_target, observer_obj) then
                        -- skip
                    else
                        local ability_copy = Utilities:shallowCopy(ability)
                        ability_copy.targeting = self:getTargetId(ns_target)
                        -- ability_copy.target_type_string = ns_target.target_type_string
                        if ability.prefix == '/ra' and not Utilities:arrayContains(self.once_per_combat, ability) then
                            table.append(self.once_per_combat, ability)
                        end
                        ability_copy.checks = {
                            recast = true,      -- isRecastReady
                            conditions = true,  -- testConditions
                            range = true,        -- inRange
                            duplicate = true,    -- Check for duplicate name+target
                        }
                        self:addToUse(ability_copy, list_type)
                    end
                end
            end
        end
    end
end

function Actions:testConditions(ability, --[[optional]]source, --[[optional]]mob_obj, --[[optional]]observer_obj)

    if not ability.conditions then return true end
    local conditions = ability.conditions
    if not self.player or next(conditions) == nil then return false end

    local is_enemy_target = mob_obj and mob_obj.target_type_string == 'Enemy'

    if is_enemy_target then
        if self.combat_actions_delay > 0 and mob_obj.claimed_at_time and ((os.clock() - mob_obj.claimed_at_time) < self.combat_actions_delay) then return false end
        if ability.prefix == '/pos' then
            if mob_obj.claimed_at_time == 0 or (os.clock() - mob_obj.claimed_at_time < 1.5 )then
                return false
            end
        end
    end

    self.player:update()
    local target_type = mob_obj and mob_obj.target_type_string or nil
    local mob_to_fight = observer_obj and observer_obj.mob_to_fight and observer_obj.mob_to_fight.obj or nil
    local ctx = {
        self = self,
        ability = ability,
        mob_obj = mob_obj,
        observer_obj = observer_obj,
        src = source,
        pet = windower.ffxi.get_mob_by_target('pet')
    }
    local decision = false

    for _,v in pairs(conditions) do
        local cond = v.condition
        local value = v.value or ''
        local modifier = v.modifier or nil
        local condition_target = v.target or nil

        if not cond then return false end

        local cond_entry = Actions.condition_funcs[cond]
        if cond_entry then
            local effective_mob_obj = mob_obj
            local effective_target_type = target_type

            if condition_target then
                local ct_lower = condition_target:lower()
                if ct_lower == 'me' then
                    effective_mob_obj = Utilities:shallowMerge(self.player.mob, self.player.vitals)
                    effective_mob_obj.target_type_string = 'Self'
                    effective_target_type = 'Self'
                elseif ct_lower == 'pet' then
                    local pet = ctx.pet
                    if pet then
                        effective_mob_obj = pet
                        effective_mob_obj.target_type_string = 'Pet'
                        effective_target_type = 'Pet'
                    else
                        -- No pet exists, condition cannot be evaluated
                        return false
                    end
                end
            end

            -- Check target type compatibility, coerce if possible
            if not condition_target and cond_entry.allowed_targets and effective_target_type then
                if not cond_entry.allowed_targets:contains(effective_target_type) then
                    -- Attempt to Coerce
                    if cond_entry.coerce_to == 'Enemy' and mob_to_fight then
                        effective_mob_obj = mob_to_fight
                    elseif cond_entry.coerce_to == 'Self' and ctx.self.player then
                        local self_obj = Utilities:shallowMerge(ctx.self.player.mob, ctx.self.player.vitals)
                        self_obj.target_type_string = 'Self'
                        effective_mob_obj = self_obj
                    else
                        -- Cannot coerce this
                        return false
                    end
                end
            end

            ctx.mob_obj = effective_mob_obj
            decision = cond_entry.func(ctx, value, modifier)
            -- Restore original mob_obj after coerced condition
            ctx.mob_obj = mob_obj
        end
        if decision == false then return false end
    end

    return decision
end

function Actions:addToUse(action, list_type)
    local queue_type = action.queue_type or 'invoked'
    local checks = action.checks or {}

    if checks.duplicate ~= false then
        local is_spell = self.magic_castable_prefixes:contains(action.prefix)
        local is_ws = self.ws_castable_prefixes:contains(action.prefix)

        for _, queued in ipairs(self.to_use) do
            -- if is_spell and queued.name == action.name and queued.targeting == action.targeting then
            --     return
            -- end
            if is_ws and self.ws_castable_prefixes:contains(queued.prefix) and queued.targeting == action.targeting then
                return
            end
            if queued.name == action.name and queued.targeting == action.targeting then
                return
            end
        end
    end

    if list_type == 'adhoc' then
        table.append(self.to_use, action)
        return
    end

    -- if queue_type == 'invoked' then
    --     for _, queued in ipairs(self.to_use) do
    --         local same_name = queued.name == action.name
    --         local same_target = queued.targeting == action.targeting
    --         local is_invoked = (queued.queue_type or 'invoked') == 'invoked'
    --         if same_name and same_target and is_invoked then
    --             return -- already have this ability for this target in the list
    --         end
    --     end
    -- end

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

function Actions:runActions(StateController, observer_obj)

    self.player:update()

    -- Nothing to Process
    if next(self.to_use) == nil then return end

    local ability = self.to_use[1]
    local resolved_ability = self.to_use[1]['res']
    local checks = ability.checks or {recast = true, conditions = true, range = true}

    local can_act = observer_obj:canAct()
    local last_was_ja = self.last_prefix_used and Utilities:arrayContains(self.ja_castable_prefixes, self.last_prefix_used)
    local next_is_ja_or_ws = self.to_use[1] and (self.ja_castable_prefixes:contains(self.to_use[1].prefix)
                            or self.ws_castable_prefixes:contains(self.to_use[1].prefix))
    local can_chain = last_was_ja and next_is_ja_or_ws

    -- Can't act or not chaining.
    if not can_act and not can_chain then return end
    -- Too close to attack packet engagement
    if observer_obj:timeSinceLastAttackPkt() <= 2 then return end

    -- Resolve Target using Targeting
    local resolved_target = nil
    if ability.targeting then
        resolved_target = windower.ffxi.get_mob_by_id(ability.targeting)

        if resolved_target and observer_obj.mob_to_fight
            and observer_obj.mob_to_fight.obj
            and observer_obj.mob_to_fight.obj.index == resolved_target.index then
                resolved_target = observer_obj.mob_to_fight.obj:getFlatCopy()
        else
            -- Enrich with Vitals for Self and party members
            if resolved_target.id == self.player.id then
                for i,v in pairs(windower.ffxi.get_player().vitals) do
                    resolved_target[i] = v
                end
            else
                local party = windower.ffxi.get_party()
                if party then
                    for i = 0, 5 do
                        local member = party['p'..i]
                        if member and member.mob and member.mob.id == resolved_target.id then
                            local append_it = T{'tp','hpp','mp','hp','mpp'}
                            for _,v in pairs(append_it) do
                                if member[v] then resolved_target[v] = member[v] end
                            end
                        end
                    end
                end
            end
        end
        if resolved_target and ability.target_type_string then
            resolved_target.target_type_string = ability.target_type_string
        end
    end

    if not ability.prefix or not ability.name or not ability.target or not ability.targeting then return end

    -- In Range of specified Target
    -- if not self:inRange(ability, resolved_target) then return end

    local should_remove = not resolved_target
        or (checks.range and not self:inRange(ability, resolved_target))
        or (checks.recast and not self:isRecastReady(ability))
        or (checks.conditions and not self:testConditions(ability, 'to_use', resolved_target, observer_obj))
    if should_remove then
        table.remove(self.to_use, 1)
    end

    -- Prevent spamming the last ability
    if self.last_sent_ability == ability.name and (os.clock() - self.last_sent_time) < 1 then return end

    -- Ready to execute
    local requires_stationary = ability.prefix == '/item' or self.magic_castable_prefixes:contains(ability.prefix)
    if requires_stationary then
        observer_obj:setCasting()
        windower.ffxi.run(false)
        coroutine.sleep(0.4)
    end
    -- notice('d')
    -- Execute
    self:executeAbility(ability, resolved_ability, resolved_target, observer_obj, Statecontroller)
    self:setLastPrefixUsed(ability.prefix)
    self.last_sent_ability = ability.name
    self.last_sent_time = os.clock()
end
function Actions:executeAbility(ability, resolved_ability, target, observer_obj, StateController)
    local prefix = ability.prefix
    local command_string = 'input '..prefix..' "'..ability.name..'" '..ability.targeting

    if prefix == '/item' then
        self:setLastItemTime()
        self:sendCommand(command_string)
        observer_obj:setActionDelay('item')
    elseif self.magic_castable_prefixes:contains(prefix) then
        self:setLastSpell(ability)
        self:sendCommand(command_string)
        observer_obj:setActionDelay('spell', 15)
    elseif prefix == '/pet' then
        if resolved_ability.type and resolved_ability.type == 'Monster' then
            self:setLastMonsterTime()
            self:setLastMonsterAbility(ability)
            self:setLastJobAbility(ability)
        end
        self:sendCommand(command_string)
        observer_obj:setActionDelay('ja')
    elseif self.ws_castable_prefixes:contains(prefix) then
        self:setLastWeaponSkill(ability.name)
        self:sendCommand(command_string)
        observer_obj:setActionDelay('ws')
    elseif prefix == '/ra' then
        self:sendCommand('input '..prefix..' '..ability.targeting)
        observer_obj:setActionDelay('ra')
    elseif prefix == '/pos' then
        if target and target.details then
            local me = self.player.mob
            local degrees = ability.degrees
            local dx = target.details.x - me.x
            local dy = target.details.y - me.y
            local distance = resolved_ability.distance or math.sqrt(dx*dx + dy*dy) or 2
            local new_x, new_y = observer_obj:determinePointInSpace(target.details, distance, degrees)
            observer_obj:setCombatPosition(new_x, new_y)
            StateController:setState('combat positioning')
            table.remove(self.to_use, 1)
        end
    else
        -- Default: treat as job ability
        self.last_action = ability.name
        self:setLastJobAbility(ability)
        self:sendCommand(command_string)
        observer_obj:setActionDelay('ja')
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
        local category = act.category
        local param = act.param
        local recast = act.recast
        local targets = act.targets
        local paralyzed = targets[1].actions[1].message
        local para_flag = (paralyzed == 29 or paralyzed == 84)

        if category == 1 then -- Attack round
            observer:setAttackRoundCalcTime()
            observer:setLastAttackRoundTime()
        end

        --notice('(Targ.Act.Msg) Category: '..category..'; TAM: '..paralyzed..';')
        if category == 6 or category == 14 then  -- Finished JA
            if self.to_use and not para_flag then
                for i,v in ipairs(self.to_use) do
                    if v.res and v.res.id == param then
                        table.remove(self.to_use, i)
                        break
                    end
                end
            end
            -- if Utilities.res.job_abilities[param] then
            --     local ability = Utilities.res.job_abilities[param]
            --     if self.to_use and not para_flag then
            --         for i,v in ipairs(self.to_use) do
            --             if v.name:lower() == Utilities.res.job_abilities[param].en:lower() then
            --                 table.remove(self.to_use, i)
            --                 break
            --             end
            --         end
            --     end

                if self.to_use[1] and (self.to_use[1].prefix == '/jobability' or self.to_use[1].prefix == '/weaponskill') then
                    coroutine.schedule(function() observer:forceUnbusy() end, 0.7)
                else
                    coroutine.schedule(function() observer:forceUnbusy() end, 0.7)
                end
            -- end
        end

        if category == 8 then -- Interrupted Casting
            if param == 28787 then
                notice('Interrupted.')
                observer_obj:setActionDelay('spell', 2)
                coroutine.schedule(function() observer:forceUnbusy() end, 2)
            end
        end

        if category == 9 then  -- Item Usage
            if param == 28787 then
                coroutine.schedule(function() observer:forceUnbusy() end, recast)
                return
            end
            local item_id = targets[1].actions[1].param or nil
            -- local item = Utilities.res.items[item_id].en or Utilities.res.items[item_id].enl
            if param == 24931 and self.to_use and not para_flag then -- Initiation
                for i,v in pairs(self.to_use) do
                    if v.res and v.res.id == item_id then
                        table.remove(self.to_use, i)
                        break
                    end
                end
                coroutine.schedule(function() observer:forceUnbusy() end, recast)
            end
        end

        if category == 3 then -- Finished Weapon Skill
            -- if Utilities.res.weapon_skills[param] or Utilities.res.job_abilities[param] then

            --     local ws = Utilities.res.weapon_skills[param] or nil
            --     local ability = Utilities.res.job_abilities[param] or nil

            if self.to_use and not para_flag then
                for i,v in pairs(self.to_use) do
                    if v.res and v.res.id == param then
                        table.remove(self.to_use, i)
                        coroutine.schedule(function() observer:forceUnbusy() end, 1)
                        break
                    end
                    -- local ws_name = ws and ws.en:lower() or nil
                    -- local abil_name = ability and ability.en:lower() or nil
                    -- if v.name:lower() == ws_name or v.name:lower() == abil_name then

                    -- end
                end
            end
            -- end
        end

        if category == 7 then
            --24931  Started WS
            if param == 28787 then
                notice('Failed TP move. Plz Unbusy.')
            end
        end

        if category == 4 then -- Finished Spell
            if param == 0 then
                self.to_use = T{}
                observer:setActionDelay('spell')
                coroutine.schedule(function() observer:forceUnbusy() end, 2)
            end

            -- if Utilities.res.spells[param] then
                -- local ability = Utilities.res.spells[param]
            if self.to_use and not para_flag then
                for i,v in pairs(self.to_use) do
                    if v.res and v.res.id == param then
                        table.remove(self.to_use, i)
                        break
                    end
                end
                observer:setActionDelay('spell')
                coroutine.schedule(function() observer:forceUnbusy() end, 2)
            end
            -- end
        end
    end

    -- Track aggro for both master and slave roles
    if actor and actor.id ~= self.player.id then
        local category = act.category
        local targets = T(act.targets)
        local party_ids = observer:setPartyClaimIds()
        local party_pet_ids = observer:getPartyPetIds()

        if category == 1 then -- Melee attack against Player or Party
            for _,v in pairs(party_ids) do
                if targets:with('id', v) then
                    -- Exclude pet IDs as they don't transfer aggro to party
                    if not party_pet_ids:contains(v) then
                        observer:addToAggro(actor.id)
                    end
                end
            end
        end
        if category == 11 and not Utilities:arrayContains(party_ids, actor.id) then -- Monster TP Attack
            for _,v in pairs(party_ids) do
                if targets:with('id', v) then
                    -- Exclude pet IDs as they don't transfer aggro to party
                    if not party_pet_ids:contains(v) then
                        observer:addToAggro(actor.id)
                    end
                end
            end
        end
    end
end

return Actions