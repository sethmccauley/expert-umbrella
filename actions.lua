local Actions = {}
Actions.__index = Actions
local Utilities = require('lang/utilities')
local Observer = require('lang/observer')
local MobObject = require('lang/mobobject')
local ActionQueue = require('lang/actionqueue')

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
        coerce_to = 'Self',
        func = function(ctx, value)
            if type(value) == 'string' and value:lower() == 'pet' then
                return ctx.pet == nil
            end
            -- For party members, check their buffs via EntityStore
            if ctx.target_type == 'Party' and ctx.entities and ctx.effective_target_id then
                local party_member = ctx.entities:getPlayer(ctx.effective_target_id)
                if party_member and party_member.hasBuff then
                    return not party_member:hasBuff(value)
                end
            end
            -- Default: check self
            return not ctx.self.player:hasBuff(value)
        end
    },
    ['present'] = {
        allowed_targets = S{'Self','Party','Pet'},
        coerce_to = 'Self',
        func = function(ctx, value, modifier)
            if type(value) == 'string' and value:lower() == 'pet' then
                if modifier then
                    return ctx.pet and ctx.pet.name:lower() == modifier:lower()
                end
                return ctx.pet ~= nil
            end
            -- For party members, check their buffs via EntityStore
            if ctx.target_type == 'Party' and ctx.entities and ctx.effective_target_id then
                local party_member = ctx.entities:getPlayer(ctx.effective_target_id)
                if party_member and party_member.hasBuff then
                    return party_member:hasBuff(value)
                end
            end
            -- Default: check self
            return ctx.self.player:hasBuff(value)
        end
    },
    ['buffdurationremaininglt'] = {
        allowed_targets = S{'Self'},
        coerce_to = 'Self',
        func = function(ctx, value, modifier)
            if not modifier or not value then return false end
            local buff_identifier = type(value) == 'string' and value:lower() or ''
            if not ctx.self.player:hasBuff(value) then return true end
            return ctx.self.player:buffTimeLeft(buff_identifier) < modifier
        end
    },
    ['buffdurationremaininggt'] = {
        allowed_targets = S{'Self'},
        coerce_to = 'Self',
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
        func = function(ctx, value) return ctx.self.to_use:contains(value) end
    },
    ['notinqueue'] = {
        func = function(ctx, value) return not ctx.self.to_use:contains(value) end
    },
    ['strengthlt'] = {
        allowed_targets = S{'Self','Party'},
        coerce_to = 'Self',
        func = function(ctx, value, modifier)
            if not modifier then return false end
            return not ctx.self.player:hasBuff(value, modifier)
        end
    },
    ['resonatingwith'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            if not ctx.mob_obj or not ctx.mob_obj.resonating_window or ctx.mob_obj.resonating_window <= 0 then return false end
            local time_left = ctx.mob_obj.resonating_window - (os.clock() - ctx.mob_obj.resonating_start_time)
            local window_breeched = os.clock() - ctx.mob_obj.resonating_start_time > 3
            return Utilities:arrayContains(ctx.mob_obj.resonating, value) and window_breeched and time_left >= 0.5
        end
    },
    ['notresonatingwith'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            if not ctx.mob_obj or not ctx.mob_obj.resonating_window or ctx.mob_obj.resonating_window <= 0 then return false end
            return not Utilities:arrayContains(ctx.mob_obj.resonating, value)
        end
    },
    ['notresonating'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            if not ctx.mob_obj or not ctx.mob_obj.resonating_window or ctx.mob_obj.resonating_window <= 0 then return true end
            local time_left = ctx.mob_obj.resonating_window - (os.clock() - ctx.mob_obj.resonating_start_time)
            return (time_left <= 0)
        end
    },
    ['resonatingstepgt'] = {
        allowed_targets = S{'Enemy'},
        coerce_to = 'Enemy',
        func = function(ctx, value)
            return ctx.mob_obj and ctx.mob_obj.resonating_step and ctx.mob_obj.resonating_step > value
        end
    },
    ['aggrotablegt'] = {
        func = function(ctx, value)
            if not ctx.observer_obj or not ctx.observer_obj.entities then return false end
            local count = ctx.observer_obj.entities:countAggro()
            return count > value
        end
    },
    ['aggrotablelt'] = {
        func = function(ctx, value)
            if not ctx.observer_obj or not ctx.observer_obj.entities then return false end
            local count = ctx.observer_obj.entities:countAggro()
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
            if not value or not ctx.entities then return false end
            return ctx.entities:partyContainsJob(value, 'main')
        end
    },
    ['mainjobnotinparty'] = {
        func = function(ctx, value)
            if not value or not ctx.entities then return false end
            return not ctx.entities:partyContainsJob(value, 'main')
        end
    },
    ['subjobinparty'] = {
        func = function(ctx, value)
            if not value or not ctx.entities then return false end
            return ctx.entities:partyContainsJob(value, 'sub')
        end
    },
    ['subjobnotinparty'] = {
        func = function(ctx, value)
            if not value or not ctx.entities then return false end
            return not ctx.entities:partyContainsJob(value, 'sub')
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

    self.to_use = ActionQueue:constructActionQueue()

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
    self.to_use:clear()
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

-- Handle adhoc commands from chat packet 0x017
-- whitelist: table of allowed sender names (e.g., {assist_name, player_name})
-- modes 3 = tell, 4 = party
function Actions:handleChatPacket(data, whitelist, observer_obj)
    if not Actions.packets then return end

    local p = Actions.packets.parse('incoming', data)
    local mode = p['Mode']
    local sender = p['Sender Name']
    local message = p['Message']

    -- Only accept party chat (4) or tells (3)
    if mode ~= 3 and mode ~= 4 then return end

    -- Check if sender is in whitelist
    local sender_lower = sender:lower()
    local allowed = false
    for _, name in ipairs(whitelist) do
        if name and name:lower() == sender_lower then
            allowed = true
            break
        end
    end
    if not allowed then return end

    -- Look for *command pattern
    local adhoc_cmd = message:match('^%*(%w+)')
    if not adhoc_cmd then return end

    self:triggerAdHoc(adhoc_cmd, observer_obj)
end
function Actions:handleOutChatPacket(data, observer_obj)
    if not Actions.packets then return end

    local p = Actions.packets.parse('outgoing', data)
    local message = p and p['Message']
    if not message then return end

    local adhoc_cmd = message:match('^%*(%w+)')
    if not adhoc_cmd then return end

    self:triggerAdHoc(adhoc_cmd, observer_obj)
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

    for _, proc_ability in ipairs(abilities_to_process) do
        if not proc_ability.res then break end

        local resolved = self:resolveTargetId(proc_ability.target, observer_obj)
        if not resolved then break end

        if self:isBatchTarget(resolved) then
            for _, target_info in ipairs(resolved) do
                self:processAdHocAbility(proc_ability, target_info, observer_obj)
            end
        else
            self:processAdHocAbility(proc_ability, resolved, observer_obj)
        end
    end
end
-- target_info is {id = number, target_type = string} from resolveTargetId
function Actions:processAdHocAbility(ability, target_info, observer_obj)
    local target_id = target_info.id
    local target_type = target_info.target_type

    if not self:inRangeById(ability, target_id, observer_obj) then return false end

    if ability.conditions and not self:testConditions(ability, 'adhoc', target_id, observer_obj) then
        return false
    end

    local ability_copy = Utilities:shallowCopy(ability)
    ability_copy.res = Utilities:shallowCopy(ability.res)
    ability_copy.targeting = target_id
    ability_copy.target_type_string = target_type
    ability_copy.res.ad_hoc = true
    ability_copy.checks = {recast = false, conditions = false, range = true, duplicate = false}
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
    local mtf = observer_obj and observer_obj.entities and observer_obj.entities.mtf
    if not mtf then
        return
    end

    mtf:updateDetails()
    local mob = mtf:getFlatCopy()

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
-- ID-based range check using EntityStore for O(1) lookup
function Actions:inRangeById(full_ability, target_id, observer_obj)
    if not self.player or not full_ability or not target_id then return false end

    -- Self-target is always in range
    if target_id == self.player.id then
        return true
    end

    local entities = observer_obj and observer_obj.entities
    if not entities then return false end

    -- O(1) lookup from EntityStore
    local target_obj = entities:get(target_id)

    -- Fall back to windower if not in store
    if not target_obj then
        target_obj = windower.ffxi.get_mob_by_id(target_id)
    end

    if not target_obj then return false end

    -- Get the mob data (MobObject/PlayerObject use different field names)
    local targ_mob = target_obj.details or target_obj.mob or target_obj

    return self:inRange(full_ability, targ_mob)
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
--------------------------------------------------------------------------------
-- Target Resolution (returns ID + type, not full objects)
-- EntityStore provides entity data when needed via observer_obj.entities
--------------------------------------------------------------------------------
-- Resolve a target string to ID(s) and target type
-- Returns: {id = number, target_type = string} or array of those for batch targets
-- Returns nil if invalid target
function Actions:resolveTargetId(target_string, observer_obj)
    if not target_string then return nil end
    local target_lower = target_string:lower()
    local entities = observer_obj and observer_obj.entities

    -- Self targets
    if S{'me','self',self.player.name:lower(),'p0'}:contains(target_lower) then
        return {id = self.player.id, target_type = 'Self'}
    end

    -- Enemy targets (t, bt, enemy) - use MTF from EntityStore
    if S{'t','bt','enemy'}:contains(target_lower) then
        if entities and entities.mtf then
            return {id = entities.mtf.id, target_type = 'Enemy'}
        end
        return nil
    end

    -- Pet target
    if target_lower == 'pet' then
        local pet = entities and entities:getMyPet()
        if pet then
            return {id = pet.id, target_type = 'Pet'}
        end
        local pet_mob = windower.ffxi.get_mob_by_target('pet')
        if pet_mob then
            return {id = pet_mob.id, target_type = 'Pet'}
        end
        return nil
    end

    -- Party slot (p0-p5)
    local party_match = target_lower:match('^p(%d+)$')
    if party_match then
        local slot = tonumber(party_match)
        local party = windower.ffxi.get_party()
        if party then
            local member = party['p'..slot]
            if member and member.mob then
                return {id = member.mob.id, target_type = 'Party'}
            end
        end
        return nil
    end

    -- Alliance slot (a10-a15, a20-a25)
    local alliance_match = target_lower:match('^a(%d+)$')
    if alliance_match then
        local slot = tonumber(alliance_match)
        local party = windower.ffxi.get_party()
        if party then
            local member = party['a'..slot]
            if member and member.mob then
                return {id = member.mob.id, target_type = 'Alliance'}
            end
        end
        return nil
    end

    -- Batch targets: 'party' - returns array of {id, target_type}
    if target_lower == 'party' then
        local batch = {}
        local party = windower.ffxi.get_party()
        if party then
            for i = 0, 5 do
                local member = party['p'..i]
                if member and member.mob then
                    batch[#batch + 1] = {id = member.mob.id, target_type = 'Party'}
                end
            end
        end
        return #batch > 0 and batch or nil
    end

    -- Batch targets: 'alliance' - returns array of {id, target_type}
    if target_lower == 'alliance' then
        local batch = {}
        local party = windower.ffxi.get_party()
        if party then
            for i = 0, 5 do
                local member = party['p'..i]
                if member and member.mob then
                    batch[#batch + 1] = {id = member.mob.id, target_type = 'Party'}
                end
            end
            for i = 10, 15 do
                local member = party['a'..i]
                if member and member.mob then
                    batch[#batch + 1] = {id = member.mob.id, target_type = 'Alliance'}
                end
            end
            for i = 20, 25 do
                local member = party['a'..i]
                if member and member.mob then
                    batch[#batch + 1] = {id = member.mob.id, target_type = 'Alliance'}
                end
            end
        end
        return #batch > 0 and batch or nil
    end

    -- Named target (try by name)
    local mob = windower.ffxi.get_mob_by_name(target_string)
    if mob and mob.id then
        -- Determine type
        local target_type = 'NPC'
        if mob.id == self.player.id then
            target_type = 'Self'
        elseif entities and entities:isInIndex('party', mob.id) then
            target_type = 'Party'
        elseif entities and entities:isInIndex('alliance', mob.id) then
            target_type = 'Alliance'
        elseif mob.spawn_type == 16 then
            target_type = 'Enemy'
        end
        return {id = mob.id, target_type = target_type}
    end

    return nil
end

-- Check if resolved target is a batch (array of targets)
function Actions:isBatchTarget(resolved)
    return resolved and type(resolved) == 'table' and resolved[1] ~= nil and resolved[1].id ~= nil
end

function Actions:testActions(list, ltype, observer_obj)
    local list_type = ltype or 'combat'
    if not list then return end

    for _, ability in ipairs(list) do

        if ability.is_chain and ability.chain then
            -- Chain Ability Handling
            local all_conditions_pass = true
            local chain_targets = {} -- Store resolved {id, target_type} per chain ability

            -- First pass: validate all chain abilities
            for i, chain_ability in ipairs(ability.chain) do
                chain_ability.conditions = ability.conditions
                local resolved = self:resolveTargetId(chain_ability.target, observer_obj)
                if not resolved then
                    all_conditions_pass = false
                    break
                end
                chain_targets[i] = resolved
                if not self:testConditions(chain_ability, list_type, resolved.id, observer_obj) then
                    all_conditions_pass = false
                    break
                end
            end

            -- Second pass: build chain actions array and queue
            if all_conditions_pass then
                local chain_actions = {}
                for i, chain_ability in ipairs(ability.chain) do
                    local resolved = chain_targets[i]
                    local ability_copy = Utilities:shallowCopy(chain_ability)
                    ability_copy.targeting = resolved.id
                    ability_copy.target_type_string = resolved.target_type
                    ability_copy.checks = {
                        recast = false,
                        conditions = true,
                        range = true,
                    }
                    chain_actions[#chain_actions + 1] = ability_copy
                end
                self:addChainToUse(chain_actions, list_type)
            end

        elseif not ability.res then
            -- Skip (no resource data)
        elseif not self:isRecastReady(ability) then
            -- Skip (not ready)
        elseif ability.res.ad_hoc then
            -- Skip (ad-hoc abilities handled separately)
        else
            local resolved = self:resolveTargetId(ability.target, observer_obj)
            if not resolved then
                -- Skip (invalid target)
            elseif self:isBatchTarget(resolved) then
                -- Batch targets (party/alliance wildcard)
                for _, target_info in ipairs(resolved) do
                    if not self:inRangeById(ability, target_info.id, observer_obj) then
                        -- Skip (out of range)
                    elseif ability.conditions and not self:testConditions(ability, list_type, target_info.id, observer_obj) then
                        -- Skip (conditions failed)
                    else
                        local ability_copy = Utilities:shallowCopy(ability)
                        ability_copy.targeting = target_info.id
                        ability_copy.target_type_string = target_info.target_type
                        ability_copy.checks = {
                            recast = false,
                            conditions = false,
                            range = true,
                            duplicate = true,
                        }
                        ability_copy.queue_type = 'enqueue'
                        self:addToUse(ability_copy, 'enqueue')
                    end
                end
            else
                -- Single target
                local target_id = resolved.id
                local target_type = resolved.target_type

                if not self:inRangeById(ability, target_id, observer_obj) then
                    -- Skip (out of range)
                elseif ability.res.type == 'Trust' then
                    if not self.to_use:contains(ability.name) then
                        self:addToUse(ability, list_type)
                    end
                elseif not self:testConditions(ability, list_type, target_id, observer_obj) then
                    -- Skip (conditions failed)
                else
                    local ability_copy = Utilities:shallowCopy(ability)
                    ability_copy.targeting = target_id
                    ability_copy.target_type_string = target_type
                    if ability.prefix == '/ra' and not Utilities:arrayContains(self.once_per_combat, ability) then
                        table.insert(self.once_per_combat, ability)
                    end
                    ability_copy.checks = {
                        recast = true,
                        conditions = true,
                        range = true,
                        duplicate = true,
                    }
                    self:addToUse(ability_copy, list_type)
                end
            end
        end
    end
end

function Actions:testConditions(ability, source, target_id, observer_obj)
    if not ability.conditions then return true end
    local conditions = ability.conditions
    if not self.player or next(conditions) == nil then return false end

    local entities = observer_obj and observer_obj.entities
    if not entities then return false end

    -- Get the action's target from EntityStore or windower
    local action_target = nil
    local action_target_type = ability.target_type_string or nil

    if target_id then
        -- Check if it's the MTF
        if entities.mtf and entities.mtf.id == target_id then
            action_target = entities.mtf:getFlatCopy()
            action_target_type = 'Enemy'
        else
            -- Try entity store first (preserves MobObject fields like resonating)
            local store_mob = entities:getMob(target_id)
            if store_mob then
                action_target = store_mob:getFlatCopy()
                action_target_type = 'Enemy'
            else
                -- Check if it's a party/alliance member in the player store
                local store_player = entities:getPlayer(target_id)
                if store_player then
                    action_target = store_player.mob or windower.ffxi.get_mob_by_id(target_id)
                    if store_player.self then
                        action_target = Utilities:shallowMerge(action_target, self.player.vitals)
                        action_target_type = 'Self'
                    else
                        action_target_type = 'Party'
                    end
                else
                    -- Fall back to windower for targets not in the store
                    action_target = windower.ffxi.get_mob_by_id(target_id)
                end
            end
        end
    end

    -- Combat delay checks for enemy targets
    if action_target_type == 'Enemy' and action_target and self.combat_actions_delay > 0 then
        local claimed_time = action_target.claimed_at_time or (entities.mtf and entities.mtf.claimed_at_time)
        if not claimed_time then
            return false
        end
        if (os.clock() - claimed_time) < self.combat_actions_delay then
            return false
        end
        if ability.prefix == '/pos' and (os.clock() - claimed_time) < 1.5 then
            return false
        end
    end

    self.player:update()

    local ctx = {
        self = self,
        ability = ability,
        target_id = target_id,
        observer_obj = observer_obj,
        entities = entities,
        src = source,
        pet = windower.ffxi.get_mob_by_target('pet'),
        -- mob_obj will be set per-condition based on condition's target
        mob_obj = action_target,
    }

    local condition_operator = 'and'
    if ability.condition_operator then condition_operator = ability.condition_operator:lower() end

    for _, v in pairs(conditions) do
        local cond = v.condition
        local value = v.value or ''
        local modifier = v.modifier or nil
        local condition_target = v.target or nil

        if not cond then return false end

        local cond_entry = Actions.condition_funcs[cond]
        if not cond_entry then return false end

        -- Determine which entity this condition evaluates against
        local effective_target = action_target
        local effective_target_type = action_target_type

        if condition_target then
            local ct_lower = condition_target:lower()
            if ct_lower == 'me' or ct_lower == 'self' then
                effective_target = Utilities:shallowMerge(self.player.mob, self.player.vitals)
                effective_target.target_type_string = 'Self'
                effective_target_type = 'Self'
            elseif ct_lower == 'pet' then
                if not ctx.pet then return false end
                effective_target = ctx.pet
                effective_target.target_type_string = 'Pet'
                effective_target_type = 'Pet'
            elseif ct_lower == 'enemy' or ct_lower == 't' then
                if entities.mtf then
                    effective_target = entities.mtf:getFlatCopy()
                    effective_target.target_type_string = 'Enemy'
                    effective_target_type = 'Enemy'
                end
            end
        elseif cond_entry.allowed_targets and effective_target_type then
            -- Coerce if needed
            if not cond_entry.allowed_targets:contains(effective_target_type) then
                if cond_entry.coerce_to == 'Enemy' and entities.mtf then
                    effective_target = entities.mtf:getFlatCopy()
                    effective_target_type = 'Enemy'
                elseif cond_entry.coerce_to == 'Self' then
                    effective_target = Utilities:shallowMerge(self.player.mob, self.player.vitals)
                    effective_target.target_type_string = 'Self'
                    effective_target_type = 'Self'
                else
                    return false
                end
            end
        end

        ctx.mob_obj = effective_target
        ctx.target_type = effective_target_type
        ctx.effective_target_id = effective_target and effective_target.id or target_id
        local decision = cond_entry.func(ctx, value, modifier)
        if condition_operator == 'or' and decision == true then return true end
        if condition_operator ~= 'or' and decision == false then return false end
    end

    if condition_operator == 'or' then return false end
    return true
end

function Actions:addToUse(action, list_type)
    -- Track once-per conditions before adding
    if Utilities:arrayContains(action, 'once') then
        if list_type == 'combat' and not Utilities:arrayContains(self.once_per_combat, action.name) then
            table.insert(self.once_per_combat, action.name)
        elseif list_type == 'noncombat' and not Utilities:arrayContains(self.once_per_noncombat, action) then
            table.insert(self.once_per_noncombat, action)
        elseif list_type == 'precombat' and not Utilities:arrayContains(self.once_per_precombat, action) then
            table.insert(self.once_per_precombat, action)
        elseif list_type == 'postcombat' and not Utilities:arrayContains(self.once_per_postcombat, action) then
            table.insert(self.once_per_postcombat, action)
        end
    end

    -- ActionQueue handles duplicate detection internally
    self.to_use:add(action, list_type)
end

function Actions:addChainToUse(actions, list_type)
    if not actions or #actions == 0 then return end
    self.to_use:addChain(actions, list_type)
end
function Actions:runActions(StateController, observer_obj)
    self.player:update()

    -- Nothing to Process
    if self.to_use:isEmpty() then return end

    local ability = self.to_use:peek()
    if not ability then return end

    local resolved_ability = ability.res
    local checks = ability.checks or {recast = true, conditions = true, range = true}

    local can_act = observer_obj:canAct()
    local last_was_ja = self.to_use.last_prefix_used and Utilities:arrayContains(self.ja_castable_prefixes, self.to_use.last_prefix_used)
    local next_is_ja_or_ws = ability and (self.ja_castable_prefixes:contains(ability.prefix) or self.ws_castable_prefixes:contains(ability.prefix))
    local can_chain = last_was_ja and next_is_ja_or_ws

    -- Can't act or not chaining.
    if not can_act and not can_chain then return end
    -- Too close to attack packet engagement
    if observer_obj:timeSinceLastAttackPkt() <= 2 then return end

    -- Resolve Target using EntityStore (target validity is always checked)
    local resolved_target = nil
    local remove_action = function()
        if ability.is_chain and ability.chain_id then
            self.to_use:removeChain(ability.chain_id)
        else
            self.to_use:pop()
        end
    end

    if ability.targeting then
        local target_type = ability.target_type_string

        if target_type == 'Enemy' then
            local store_mob = entities and entities:getMob(ability.targeting)
            if store_mob then
                if not store_mob:isValidTarget(self.player.mob) then
                    remove_action()
                    return
                end
                resolved_target = store_mob:getFlatCopy()
            else
                -- Not in entity store, fall back to windower
                resolved_target = windower.ffxi.get_mob_by_id(ability.targeting)
                if not resolved_target or resolved_target.hpp == 0
                    or not resolved_target.valid_target
                    or resolved_target.status == 2 or resolved_target.status == 3 then
                    remove_action()
                    return
                end
            end

        elseif target_type == 'Self' then
            self.player:update()
            resolved_target = Utilities:shallowMerge(self.player.mob, self.player.vitals)

        elseif target_type == 'Party' or target_type == 'Alliance' then
            local store_player = entities and entities:getPlayer(ability.targeting)
            if store_player then
                store_player:update()
                resolved_target = Utilities:shallowMerge(store_player.mob, {})
                -- Enrich with party vitals (tp, mp, hp, mpp not available from mob data)
                local party = windower.ffxi.get_party()
                if party then
                    for i = 0, 5 do
                        local member = party['p'..i]
                        if member and member.mob and member.mob.id == ability.targeting then
                            local append_it = T{'tp','hpp','mp','hp','mpp'}
                            for _,v in pairs(append_it) do
                                if member[v] then resolved_target[v] = member[v] end
                            end
                        end
                    end
                end
            else
                resolved_target = windower.ffxi.get_mob_by_id(ability.targeting)
                if not resolved_target then
                    remove_action()
                    return
                end
            end

        elseif target_type == 'Pet' then
            local store_pet = entities and entities:getMob(ability.targeting)
            if store_pet then
                store_pet:updateDetails()
                resolved_target = store_pet:getFlatCopy()
            else
                resolved_target = windower.ffxi.get_mob_by_id(ability.targeting)
                if not resolved_target then
                    remove_action()
                    return
                end
            end

        else
            -- Unknown target type, fall back to windower
            resolved_target = windower.ffxi.get_mob_by_id(ability.targeting)
            if not resolved_target then
                remove_action()
                return
            end
        end

        if ability.target_type_string then
            resolved_target.target_type_string = ability.target_type_string
        end
    end

    if not ability.prefix or not ability.name or not ability.target or not ability.targeting then return end

    -- Check configured validations
    local should_remove = (checks.range and not self:inRange(ability, resolved_target))
        or (checks.recast and not self:isRecastReady(ability))
        or (checks.conditions and not self:testConditions(ability, 'to_use', ability.targeting, observer_obj))

    if should_remove then
        if ability.is_chain and ability.chain_id then
            self.to_use:removeChain(ability.chain_id)
        else
            self.to_use:pop()
        end
        return
    end

    -- Prevent Spamming an Ability still waiting on recast but is enqueued
    if not self:isRecastReady(ability) then return end

    -- Prevent spamming the last ability
    if not self.to_use:canSend(ability.name) then return end

    -- Ready to execute
    local requires_stationary = ability.prefix == '/item' or self.magic_castable_prefixes:contains(ability.prefix)
    if requires_stationary then
        observer_obj:setCasting()
        windower.ffxi.run(false)
        coroutine.sleep(0.4)
    end

    -- Execute
    self:executeAbility(ability, resolved_ability, resolved_target, observer_obj, StateController)
    self.to_use:setLastPrefixUsed(ability.prefix)
    self.to_use:markSent(ability.name)
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
        if target and target.x and target.y then
            local me = self.player.mob
            local degrees = ability.degrees
            local dx = target.x - me.x
            local dy = target.y - me.y
            local distance = resolved_ability.distance or math.sqrt(dx*dx + dy*dy) or 2
            local new_x, new_y = observer_obj:determinePointInSpace(target, distance, degrees)
            observer_obj:setCombatPosition(new_x, new_y)
            StateController:setState('combat positioning')
            self.to_use:pop()
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
    self.to_use:clear()
end

function Actions:handleActionNotification(action, player, observer, statecontroller)

    local act = self.packets.parse('incoming', action)
    local actor = windower.ffxi.get_mob_by_id(act['Actor'])
    local role = statecontroller.role or 'master'

    local category = act['Category']

    local target_count = act['Target Count'] or nil
    local targets = T{}
    if target_count then
        for t = 1, target_count do
            local target = {
                id = act['Target '..t..' ID'],
                actions = {},
            }
            local action_count = act['Target '..t..' Action Count']
            for a = 1, action_count do
                local pfx = 'Target '..t..' Action '..a..' '
                target.actions[a] = {
                    reaction = act[pfx..'Reaction'],
                    animation = act[pfx..'Animation'],
                    effect = act[pfx..'Effect'],
                    stagger = act[pfx..'Stagger'],
                    knockback = act[pfx..'Knockback'],
                    param = act[pfx..'Param'],
                    message = act[pfx..'Message'],
                    unknown = act[pfx..'_unknown'],
                    has_add_effect = act[pfx..'Has Add Effect'],
                    has_spike_effect = act[pfx..'Has Spike Effect'],
                }
            end
            targets[t] = target
        end
    end

    if actor and actor.id == self.player.id then
        local param = act['Param']
        local recast = act['Recast']

        local paralyzed = targets[1].actions[1].message
        local para_flag = (paralyzed == 29 or paralyzed == 84)

        if category == 1 then -- Attack round
            observer:setAttackRoundCalcTime()
            observer:setLastAttackRoundTime()
        end

        --notice('(Targ.Act.Msg) Category: '..category..'; TAM: '..paralyzed..';')
        if category == 6 or category == 14 then  -- Finished JA
            if not para_flag then
                self.to_use:removeByResId(param)
            end
            local next_action = self.to_use:peek()
            if next_action and (next_action.prefix == '/jobability' or next_action.prefix == '/weaponskill') then
                coroutine.schedule(function() observer:forceUnbusy() end, 0.7)
            else
                coroutine.schedule(function() observer:forceUnbusy() end, 0.7)
            end
        end

        if category == 8 then -- Interrupted Casting
            if param == 28787 then
                notice('Interrupted.')
                observer:setActionDelay('spell', 3)
                coroutine.schedule(function() observer:forceUnbusy() end, 2)
            end
        end

        if category == 9 then  -- Item Usage
            if param == 28787 then
                coroutine.schedule(function() observer:forceUnbusy() end, recast)
                return
            end
            local item_id = targets[1].actions[1].param or nil
            if param == 24931 and not para_flag then -- Initiation
                self.to_use:removeByResId(item_id)
                coroutine.schedule(function() observer:forceUnbusy() end, recast)
            end
        end

        if category == 3 then -- Finished Weapon Skill
            if not para_flag then
                self.to_use:removeByResId(param)
                coroutine.schedule(function() observer:forceUnbusy() end, 1)
            end
        end

        if category == 7 then
            --24931  Started WS
            if param == 28787 then
                notice('Failed TP move. Plz Unbusy.')
            end
        end

        if category == 4 then -- Finished Spell
            if param == 0 then
                self.to_use:clear()
                observer:setActionDelay('spell')
                coroutine.schedule(function() observer:forceUnbusy() end, 2)
            end

            if not para_flag then
                self.to_use:removeByResId(param)
                observer:setActionDelay('spell')
                coroutine.schedule(function() observer:forceUnbusy() end, 2)
            end
        end
    end

    -- Track aggro for both master and slave roles
    if actor and actor.id ~= self.player.id and targets then
        local party_ids = observer.entities:updateClaimIds()
        local party_pet_ids = observer.entities:getPetIds()

        if category == 1 then -- Melee attack against Player or Party
            for _,v in pairs(party_ids) do
                if targets:with('id', v) then
                    -- Exclude pet IDs as they don't transfer aggro to party
                    if not party_pet_ids[v] then
                        observer:addToAggro(actor.id)
                    end
                end
            end
        end
        if category == 11 and not Utilities:arrayContains(party_ids, actor.id) then -- Monster TP Attack
            for _,v in pairs(party_ids) do
                if targets:with('id', v) then
                    -- Exclude pet IDs as they don't transfer aggro to party
                    if not party_pet_ids[v] then
                        observer:addToAggro(actor.id)
                    end
                end
            end
        end
    end
end

return Actions