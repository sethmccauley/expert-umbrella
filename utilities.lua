local extdata = require('extdata')

local Utilities = {}
Utilities.__index = Utilities

local _res = nil
Utilities.res = setmetatable({}, {
    __index = function(t, key)
        if not _res then _res = require('resources') end
        return _res[key]
    end,
    __newindex = function(t, key, value)
        if _res then _res[key] = value end
    end
})
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
Utilities._slot_map = T{'main','sub','range','ammo','head','body','hands','legs','feet','neck','waist','left_ear', 'right_ear', 'left_ring', 'right_ring','back'}
Utilities._server_content = T{'Azi Dahaka','Naga Raja','Quetzalcoatl','Mireu'}
Utilities._trust_job_list = T{
    [1]={id=896,english="Shantotto",name="Shantotto",models=3000, mjob=4},
    [2]={id=897,english="Naji",name="Naji",models=3001, mjob=1},
    [3]={id=898,english="Kupipi",name="Kupipi",models=3002, mjob=3},
    [4]={id=899,english="Excenmille",name="Excenmille",models=3003, mjob=7},
    [5]={id=900,english="Ayame",name="Ayame",models=3004, mjob=12}, 
    [6]={id=901,english="Nanaa Mihgo",name="NanaaMihgo",models=3005, mjob=6},
    [7]={id=902,english="Curilla",name="Curilla",models=3006, mjob=7},
    [8]={id=903,english="Volker",name="Volker",models=3007, mjob=1},
    [9]={id=904,english="Ajido-Marujido",name="Ajido-Marujido",models=3008, mjob=4},
    [10]={id=905,english="Trion",name="Trion",models=3009, mjob=7},
    [11]={id=906,english="Zeid",name="Zeid",models=3010, mjob=8},
    [12]={id=907,english="Lion",name="Lion",models=3011, mjob=6},
    [13]={id=908,english="Tenzen",name="Tenzen",models=3012, mjob=12},
    [14]={id=909,english="Mihli Aliapoh",name="MihliAliapoh",models=3013, mjob=3},
    [15]={id=910,english="Valaineral",name="Valaineral",models=3014, mjob=7},
    [16]={id=911,english="Joachim",name="Joachim",models=3015, mjob=10},
    [17]={id=912,english="Naja Salaheem",name="NajaSalaheem",models=3016, mjob=2},
    [18]={id=913,english="Prishe",name="Prishe",models=3017, mjob=2},
    [19]={id=914,english="Ulmia",name="Ulmia",models=3018, mjob=10},
    [20]={id=915,english="Shikaree Z",name="ShikareeZ",models=3019, mjob=14},
    [21]={id=916,english="Cherukiki",name="Cherukiki",models=3020, mjob=3},
    [22]={id=917,english="Iron Eater",name="IronEater",models=3021, mjob=1},
    [23]={id=918,english="Gessho",name="Gessho",models=3022, mjob=13},
    [24]={id=919,english="Gadalar",name="Gadalar",models=3023, mjob=4},
    [25]={id=920,english="Rainemard",name="Rainemard",models=3024, mjob=5},
    [26]={id=921,english="Ingrid",name="Ingrid",models=3025, mjob=3},
    [27]={id=922,english="Lehko Habhoka",name="LehkoHabhoka",models=3026, mjob=6},
    [28]={id=923,english="Nashmeira",name="Nashmeira",models=3027, mjob=3},
    [29]={id=924,english="Zazarg",name="Zazarg",models=3028, mjob=2},
    [30]={id=925,english="Ovjang",name="Ovjang",models=3029, mjob=5},
    [31]={id=926,english="Mnejing",name="Mnejing",models=3030, mjob=7},
    [32]={id=927,english="Sakura",name="Sakura",models=3031, mjob=21},
    [33]={id=928,english="Luzaf",name="Luzaf",models=3032, mjob=17},
    [34]={id=929,english="Najelith",name="Najelith",models=3033, mjob=11},
    [35]={id=930,english="Aldo",name="Aldo",models=3034, mjob=6},
    [36]={id=931,english="Moogle",name="Moogle",models=3035, mjob=21},
    [37]={id=932,english="Fablinix",name="Fablinix",models=3036, mjob=5},
    [38]={id=933,english="Maat",name="Maat",models=3037, mjob=2},
    [39]={id=934,english="D. Shantotto",name="D.Shantotto",models=3038, mjob=4},
    [40]={id=935,english="Star Sibyl",name="StarSibyl",models=3039, mjob=21},
    [41]={id=936,english="Karaha-Baruha",name="Karaha-Baruha",models=3040, mjob=3},
    [42]={id=937,english="Cid",name="Cid",models=3041, mjob=1},
    [43]={id=938,english="Gilgamesh",name="Gilgamesh",models=3042, mjob=12},
    [44]={id=939,english="Areuhat",name="Areuhat",models=3043, mjob=1},
    [45]={id=940,english="Semih Lafihna",name="SemihLafihna",models=3044, mjob=11},
    [46]={id=941,english="Elivira",name="Elivira",models=3045, mjob=11},
    [47]={id=942,english="Noillurie",name="Noillurie",models=3046, mjob=12},
    [48]={id=943,english="Lhu Mhakaracca",name="LhuMhakaracca",models=3047, mjob=9},
    [49]={id=944,english="Ferreous Coffin",name="FerreousCoffin",models=3048, mjob=3},
    [50]={id=945,english="Lilisette",name="Lilisette",models=3049, mjob=19},
    [51]={id=946,english="Mumor",name="Mumor",models=3050, mjob=19},
    [52]={id=947,english="Uka Totlihn",name="UkaTotlihn",models=3051, mjob=19},
    [53]={id=948,english="Klara",name="Klara",models=3053, mjob=1},
    [54]={id=949,english="Romaa Mihgo",name="RomaaMihgo",models=3054, mjob=6},
    [55]={id=950,english="Kuyin Hathdenna",name="KuyinHathdenna",models=3055, mjob=21},
    [56]={id=951,english="Rahal",name="Rahal",models=3056, mjob=7},
    [57]={id=952,english="Koru-Moru",name="Koru-Moru",models=3057, mjob=5},
    [58]={id=953,english="Pieuje (UC)",name="Pieuje",models=3058, mjob=3},
    [59]={id=954,english="I. Shield (UC)",name="InvincibleShld",models=3060, mjob=1},
    [60]={id=955,english="Apururu (UC)",name="Apururu",models=3061, mjob=3},
    [61]={id=956,english="Jakoh (UC)",name="JakohWahcondalo",models=3062, mjob=6},
    [62]={id=957,english="Flaviria (UC)",name="Flaviria",models=3059, mjob=14},
    [63]={id=958,english="Babban",name="Babban",models=3067, mjob=2},
    [64]={id=959,english="Abenzio",name="Abenzio",models=3068, mjob=6},
    [65]={id=960,english="Rughadjeen",name="Rughadjeen",models=3069, mjob=7},
    [66]={id=961,english="Kukki-Chebukki",name="Kukki-Chebukki",models=3070, mjob=4},
    [67]={id=962,english="Margret",name="Margret",models=3071, mjob=11},
    [68]={id=963,english="Chacharoon",name="Chacharoon",models=3072, mjob=6},
    [69]={id=964,english="Lhe Lhangavo",name="LheLhangavo",models=3073, mjob=2},
    [70]={id=965,english="Arciela",name="Arciela",models=3074, mjob=5},
    [71]={id=966,english="Mayakov",name="Mayakov",models=3075, mjob=19},
    [72]={id=967,english="Qultada",name="Qultada",models=3076, mjob=17},
    [73]={id=968,english="Adelheid",name="Adelheid",models=3077, mjob=20},
    [74]={id=969,english="Amchuchu",name="Amchuchu",models=3078, mjob=22},
    [75]={id=970,english="Brygid",name="Brygid",models=3079, mjob=21},
    [76]={id=971,english="Mildaurion",name="Mildaurion",models=3080, mjob=7},
    [77]={id=972,english="Halver",name="Halver",models=3087, mjob=7},
    [78]={id=973,english="Rongelouts",name="Rongelouts",models=3088, mjob=1},
    [79]={id=974,english="Leonoyne",name="Leonoyne",models=3089, mjob=4},
    [80]={id=975,english="Maximilian",name="Maximilian",models=3090, mjob=6},
    [81]={id=976,english="Kayeel-Payeel",name="Kayeel-Payeel",models=3091, mjob=4},
    [82]={id=977,english="Robel-Akbel",name="Robel-Akbel",models=3092, mjob=4},
    [83]={id=978,english="Kupofried",name="Kupofried",models=3093, mjob=21},
    [84]={id=979,english="Selh\'teus",name="Selh\'teus",models=3094, mjob=7},
    [85]={id=980,english="Yoran-Oran (UC)",name="Yoran-Oran",models=3095, mjob=3},
    [86]={id=981,english="Sylvie (UC)",name="Sylvie",models=3096, mjob=21},
    [87]={id=982,english="Abquhbah",name="Abquhbah",models=3098, mjob=1},
    [88]={id=983,english="Balamor",name="Balamor",models=3099, mjob=8},
    [89]={id=984,english="August",name="August",models=3100, mjob=7},
    [90]={id=985,english="Rosulatia",name="Rosulatia",models=3101, mjob=4},
    [91]={id=986,english="Teodor",name="Teodor",models=3103, mjob=4},
    [92]={id=987,english="Ullegore",name="Ullegore",models=3105, mjob=4},
    [93]={id=988,english="Makki-Chebukki",name="Makki-Chebukki",models=3106, mjob=11},
    [94]={id=989,english="King of Hearts",name="KingOfHearts",models=3107, mjob=5},
    [95]={id=990,english="Morimar",name="Morimar",models=3108, mjob=9},
    [96]={id=991,english="Darrcuiln",name="Darrcuiln",models=3109, mjob=1},
    [97]={id=992,english="AAHM",name="ArkHM",models=3113, mjob=13},
    [98]={id=993,english="AAEV",name="ArkEV",models=3114, mjob=7},
    [99]={id=994,english="AAMR",name="ArkMR",models=3115, mjob=9},
    [100]={id=995,english="AATT",name="ArkTT",models=3116, mjob=4},
    [101]={id=996,english="AAGK",name="ArkGK",models=3117, mjob=12},
    [102]={id=997,english="Iroha",name="Iroha",models=3111, mjob=12},
    [103]={id=998,english="Ygnas",name="Ygnas",models=3118, mjob=3},
    [104]={id=1004,english="Excenmille [S]",name="Excenmille",models=3052, mjob=7},
    [105]={id=1005,english="Ayame (UC)",name="Ayame",models=3063, mjob=12},
    [106]={id=1006,english="Maat (UC)",name="Maat",models=3064, mjob=2}, --expected models
    [107]={id=1007,english="Aldo (UC)",name="Aldo",models=3065, mjob=6}, --expected models
    [108]={id=1008,english="Naja (UC)",name="NajaSalaheem",models=3066, mjob=2},
    [109]={id=1009,english="Lion II",name="Lion",models=3081, mjob=6},
    [110]={id=1010,english="Zeid II",name="Zeid",models=3086, mjob=8},
    [111]={id=1011,english="Prishe II",name="Prishe",models=3082, mjob=2},
    [112]={id=1012,english="Nashmeira II",name="Nashmeira",models=3083, mjob=3},
    [113]={id=1013,english="Lilisette II",name="Lilisette",models=3084, mjob=19},
    [114]={id=1014,english="Tenzen II",name="Tenzen",models=3097, mjob=12},
    [115]={id=1015,english="Mumor II",name="Mumor",models=3104, mjob=19},
    [116]={id=1016,english="Ingrid II",name="Ingrid",models=3102, mjob=3},
    [117]={id=1017,english="Arciela II",name="Arciela",models=3085, mjob=5},
    [118]={id=1018,english="Iroha II",name="Iroha",models=3112, mjob=12},
    [119]={id=1019,english="Shantotto II",name="Shantotto",models=3110, mjob=4},
    [120]={id=1003,english="Cornelia",name="Cornelia",models=3119, mjob=3},
    [121]={id=999,english="Monberaux",name="Monberaux",models=3120, mjob=7},
    [122]={id=1003,english="Matsui-P",name="Matsui-P",models=3121, mjob=13},
}
Utilities._job_ids = T{
    [1]  = {english = 'Warrior',       short = 'WAR'},
    [2]  = {english = 'Monk',          short = 'MNK'},
    [3]  = {english = 'White Mage',    short = 'WHM'},
    [4]  = {english = 'Black Mage',    short = 'BLM'},
    [5]  = {english = 'Red Mage',      short = 'RDM'},
    [6]  = {english = 'Thief',         short = 'THF'},
    [7]  = {english = 'Paladin',       short = 'PLD'},
    [8]  = {english = 'Dark Knight',   short = 'DRK'},
    [9]  = {english = 'Beastmaster',   short = 'BST'},
    [10] = {english = 'Bard',          short = 'BRD'},
    [11] = {english = 'Ranger',        short = 'RNG'},
    [12] = {english = 'Samurai',       short = 'SAM'},
    [13] = {english = 'Ninja',         short = 'NIN'},
    [14] = {english = 'Dragoon',       short = 'DRG'},
    [15] = {english = 'Summoner',      short = 'SMN'},
    [16] = {english = 'Blue Mage',     short = 'BLU'},
    [17] = {english = 'Corsair',       short = 'COR'},
    [18] = {english = 'Puppetmaster',  short = 'PUP'},
    [19] = {english = 'Dancer',        short = 'DNC'},
    [20] = {english = 'Scholar',       short = 'SCH'},
    [21] = {english = 'Geomancer',     short = 'GEO'},
    [22] = {english = 'Rune Fencer',   short = 'RUN'},
    [23] = {english = 'Monipulator',   short = 'MON'},
}
Utilities._global_delays = T{
    ['spell'] = 3.2,
    ['ja'] = 1.0,
    ['ws'] = 2,
    ['item'] = 2.5,
    ['ra'] = 2,
    ['engage'] = 2,
}
Utilities._statuses = {
    [0] = 'Idle',
    [1] = 'Engaged',
    [2] = 'Dead',
    [3] = 'Engaged dead',
    [4] = 'Event',
    [5] = 'Chocobo',
    [33] = 'Resting',
    [38] = 'Fishing',
    [39] = 'Hooked',
    [43] = 'Synth',
    [44] = 'Sit',
    [47] = 'Mount',
    [48] = 'Mounted',
    [85] = 'Healing',
}
Utilities._bags = {
    [0] = 'inventory',
    [1] = 'safe',
    [2] = 'storage',
    [3] = 'temporary',
    [4] = 'locker',
    [5] = 'satchel',
    [6] = 'sack',
    [7] = 'case',
    [8] = 'wardrobe',
    [9] = 'safe 2',
    [10] = 'wardrobe 2',
    [11] = 'wardrobe 3',
    [12] = 'wardrobe 4',
    [13] = 'wardrobe 5',
    [14] = 'wardrobe 6',
    [15] = 'wardrobe 7',
    [16] = 'wardrobe 8',
    [17] = 'recycle',
}
Utilities._cache = {
    ['spells'] = {},
    ['job_abilities'] = {},
    ['weapon_skills'] = {},
    ['items'] = {},
    ['buffs'] = {},
}
Utilities._cache_by_name = {
    ['spells'] = {},
    ['job_abilities'] = {},
    ['weapon_skills'] = {},
    ['items'] = {},
    ['buffs'] = {},
}
Utilities._debuff_by_name = {
    doom = 15, petrification = 7, curse = 9, bane = 30, sleep = 2, lullaby = 193,
    paralysis = 4, silence = 6, slow = 13, elegy = 194, hp_down = 144, blind = 5,
    acc_down = 146, att_down = 147, def_down = 149, magic_eva_down = 404, magic_def_down = 167,
    evasion_down = 148, inhibit_tp = 168, tp_down = 189, plague = 31, flash = 156, mp_down = 145,
    poison = 3, dia = 134, bio = 135, burn = 128, frost = 129, choke = 130,
    rasp = 131, shock = 132, drown = 133, helix = 186, magic_acc_down = 174, magic_att_down = 175,
    str_down = 136, dex_down = 137, vit_down = 138, agi_down = 139, int_down = 140, mnd_down = 141,
    chr_down = 142, bind = 11, weight = 12, addle = 21, nocturne = 223, requiem = 192, disease = 8,
}
Utilities._tracked_debuffs = S{
    'doom', 'petrification', 'curse', 'bane', 'sleep', 'lullaby',
    'paralysis', 'silence', 'slow', 'elegy', 'hp down', 'blind',
    'accuracy down', 'attack down', 'defense down', 'magic evasion down', 'magic defense down',
    'evasion down', 'inhibit tp', 'poison', 'flash', 'mp down',
    'dia', 'bio', 'burn', 'frost', 'choke', 'rasp', 'shock', 'drown',
    'helix', 'magic accuracy down', 'magic attack down', 'plague', 'disease',
    'str down', 'dex down', 'vit down', 'agi down', 'int down', 'mnd down', 'chr down',
    'bind', 'weight', 'addle', 'nocturne', 'requiem',
}

function Utilities:constructUtilities() 
    local self = setmetatable({}, Utilities)

    self.status_by_name = {}
    self.status_by_id = {}

    self:buildStatusLookup()

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
function Utilities:shallowCopy(t)
    if type(t) ~= 'table' then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return setmetatable(copy, getmetatable(t))
end
function Utilities:shallowMerge(base, override)
    local merged = {}
    for k, v in pairs(base or {}) do
        merged[k] = v
    end
    for k, v in pairs(override or {}) do
        merged[k] = v
    end
    return merged
end
function Utilities:deepMerge(base, override)
    local result = {}
    for k, v in pairs(base or {}) do
        if type(v) == 'table' then
            result[k] = self:shallowCopy(v)
        else
            result[k] = v
        end
    end
    for k, v in pairs(override or {}) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            -- Both are arrays (combat/noncombat lists) - concatenate
            if #v > 0 and #result[k] > 0 then
                for _, item in ipairs(v) do
                    table.insert(result[k], self:shallowCopy(item))
                end
            else
                -- Both are dictionaries - recurse
                result[k] = self:deepMerge(result[k], v)
            end
        else
            result[k] = v
        end
    end
    return result
end

function Utilities:buildStatusLookup()
    self.status_by_name = {}
    self.status_by_id = {}

    for id, buff in pairs(self.res.buffs) do
        local name = buff.en:lower()
        if self._tracked_debuffs:contains(name) then
            self.status_by_name[name] = id
            self.status_by_id[id] = name
        end
        buff.ja = nil
        buff.jal = nil
    end
end

function Utilities:valueAtKey(t, key)
    for i,v in pairs(t) do
        if i == key or i == tostring(key):lower() then return v end
        if type(v) == 'table' then
            if self:valueAtKey(v, key) then return v[key] end
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

-- Runtime lookup - cache only, O(1), never touches self.res
function Utilities:getResource(res_type, name)
    if not name then return nil end
    local name_lower = name:lower()

    if self._cache_by_name[res_type] then
        return self._cache_by_name[res_type][name_lower]
    end

    return nil
end
-- Only call during startup
function Utilities:cacheResource(res_type, name)
    if not name then return nil end
    local name_lower = name:lower()

    -- Already cached
    if self._cache_by_name[res_type] and self._cache_by_name[res_type][name_lower] then
        return self._cache_by_name[res_type][name_lower]
    end
    -- Expensive lookup
    local res_table = self.res[res_type]
    if not res_table then return nil end

    local result = res_table:with('en', name) or res_table:with('enl', name_lower)
    -- Cache by both id and name
    if result and result.id then
        self._cache[res_type][result.id] = result
        self._cache_by_name[res_type] = self._cache_by_name[res_type] or {}
        self._cache_by_name[res_type][name_lower] = result
    end

    return result
end
function Utilities:getResourceById(res_type, id)
    -- Check cache first
    if self._cache[res_type][id] then
        return self._cache[res_type][id]
    end
    notice('ouch')
    -- Cache miss - direct ID access is O(1)
    local result = self.res[res_type][id]
    if result then
        self._cache[res_type][id] = result
    end

    return result
end
function Utilities:getItemByName(name)
    local name_lower = name:lower()

    -- Check name cache
    if self._cache_by_name.items[name_lower] then
        return self._cache_by_name.items[name_lower]
    end

    -- Expensive
    local result = self.res.items:with('en', name_lower) or self.res.items:with('enl', name_lower)

    -- Cache by both ID and name
    if result then
        self._cache.items[result.id] = result
        self._cache_by_name.items[name_lower] = result
    end

    return result
end
function Utilities:trimRes()
    self.res.spells = nil
    self.res.job_abilities = nil
    self.res.items = nil
    self.res.key_items = nil
    collectgarbage("collect")
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
function Utilities:haveKI(item)
    local key_items = windower.ffxi.get_key_items()
    local ki_id = 0
    for _,v in pairs(Utilities.res.key_items) do
        if v.en:lower() == item:lower() then
            ki_id = v.id
        end
    end
    if ki_id == 0 then
        return false
    end
    for _,v in pairs(key_items) do
        if v == ki_id then
            return true
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
        report.ability = Utilities.res.monster_abilities[packet.Param]
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

function Utilities:isBlank(value)
    return not not tostring(value):find("^%s*$")
end

function Utilities:isEquipped(item)
    local items = windower.ffxi.get_items()
    local item_id, item = Utilities.res.items:find(function(v) if v.name == item then return true end end)
    if item_id == nil then return false end
    local equipment = T{}
    for id,name in pairs(Utilities._slot_map) do
        equipment[name] = {
            ['slot'] = items.equipment[name],
            ['bag_id'] = items.equipment[name..'_bag']
            }
        if equipment[name].slot == 0 then equipment[name].slot = 'empty' end
    end
    for i,v in pairs(equipment) do
        if v.slot ~= 'empty' then
            if items[Utilities:fixBag(Utilities._bags[v.bag_id])][v.slot].id == item_id then
                return true
            end
        end
    end
    return false
end

function Utilities:fixBag(bag)
    local new = bag:gsub(' ','')
    return new:lower()
end

function Utilities:isUsable(item)
    local item_id, item = Utilities.res.items:find(function(v) if v.name == item then return true end end)
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
function Utilities:hasCharges(item)
	local item_id, item = Utilities.res.items:find(function(v) if v.name == item then return true end end)
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

function Utilities:partyIsPresent()
    local party_table = windower.ffxi.get_party()
    local world = windower.ffxi.get_info()
    if party_table == nil then return false end
    local all_present = true
    local party_members = {
        ['p0'] = true,
    }
    local zone_id = world.zone

    for party_key,member in pairs(party_table) do
        if type(member) == 'table' then
            local isPresent = true
            if member.zone ~= zone_id then
                isPresent = false
            end

            if isPresent and member.mob and distance_to(member.mob.x, member.mob.y) < 8 then
                isPresent = true
            else
                isPresent = false
            end

            if isPresent then
                party_members[party_key] = true
            else
                party_members[party_key] = false
            end
        end
    end

    for p_key,mem in pairs(party_members) do
        if mem == false then
            all_present = false
        end
    end
    if all_present == true then
        -- notice('All here.')
        return true
    end
    return false
end

function Utilities:stringExplode(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    str:gsub(pattern, function(c)
        table.insert(result, c)
    end)
    return result
end

function Utilities:sendIPC(msg, name)
    local from = name
    if not from then return end
    if #msg > 0 then windower.send_ipc_message(from..' '..msg) end
end
function Utilities:receiveIPC(from, cmd, args, Observer, StateController, Navigation, Actions)

    if StateController.on_switch == 0 and (cmd ~= 'acknowledge' and cmd ~= 'register') then return end

    local func_map = {
        ['pos'] = function(args)
                    if #args < 1 then return false end
                    local packed = args[1]:parse_hex()
                    local zone_id, x, y, z = packed:unpack('Hfff', 1)
                    local my_zone = windower.ffxi.get_info().zone
                    if zone_id ~= my_zone then return false end
                    if StateController.assist and Observer:inParty(StateController.assist) and Observer:memberInZone(StateController.assist) and StateController.follow_master == true then
                        StateController.assist_last_pos = T{['x'] = x, ['y'] = y, ['z'] = z, ['tolerance'] = .33}
                        Navigation:pushNode(StateController.assist_last_pos)
                    end
                end,
        ['register'] = function()
                        self:sendIPC('acknowledge', Observer.player.name)
                    end,
        ['mtf'] = function(args)
                    if not args[1] then return end
                    notice('Was told by '..from..' about a mtf '..args[1])
                    local index = tonumber(args[1])
                    local mob = windower.ffxi.get_mob_by_index(index)
                    if mob then
                        Observer:setMobToFight({['name'] = mob.name, ['index'] = index, ['mob'] = mob})
                        Actions:emptyOncePerTables()
                        Navigation:setShortCourse({})
                    end
                end,
        ['engage'] = function(value) end,
        ['follow'] = function(args)
                        local new_val
                        if not args or #args == 0 then
                            new_val = not StateController.follow_master
                        else
                            new_val = (args[1] == 'true')
                        end
                        StateController:setFollowMaster(new_val)
                    end,
        ['disengage'] = function()
                            if next(Observer.mob_to_fight) ~= nil then
                                Observer:setMobToFight(T{})
                                Observer:setAggroEmpty()
                                Actions:disengageMob()
                            end
                            Navigation:setShortCourse(T{})
                        end,
    }

    Observer:addLocalEntity(from)

    if func_map[cmd] then
        func_map[cmd](args)
    end
end

return Utilities
