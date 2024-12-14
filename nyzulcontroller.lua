local NyzulController = {}
NyzulController.__index = NyzulController

local Utilities = require('lang/utilities')
local packets = require('packets')
local dialog = require('dialog')

NyzulController._roles = L{
    'coordinator',
    'scout'
}
NyzulController._allowedStates = S{
    'zoneing',
    'outside_nyzul',
    'idle',
    'travel',
    'paused',
    'floor_complete',
    'floor_complete_+',
    'register_code',
    'use_start_rune',
    'received_start',
    'use_floor_rune',
    'received_rune',
    'use_lamp',
    'received_lamp_menu',
    'awaiting_coordinator',
    'awaiting_smiting',
    'awaiting_lamp_result',
    'awaiting_incoming_srune',
    'awaiting_incoming_rune',
    'awaiting_incoming_lamp'
}
NyzulController._nyzulZone = 77
NyzulController._fences = { -- Position 1 is NW corner, Position 2 is SE corner
    [1] = {['submap_index']='start',['x1']=-40,['y1']=0,['x2']=0,['y2']=-40},
    [2] = {['submap_index']='4d_0',['x1']=362,['y1']=-422,['x2']=578,['y2']=-658},
    [3] = {['submap_index']='4d_1',['x1']=380,['y1']=120,['x2']=638,['y2']=-240}, -- 
    [4] = {['submap_index']='4d_2',['x1']=400,['y1']=518,['x2']=600,['y2']=140}, --
    [5] = {['submap_index']='4d_3',['x1']=-100,['y1']=-242,['x2']=118,['y2']=-520}, --
    [6] = {['submap_index']='4d_4',['x1']=-120,['y1']=200,['x2']=120,['y2']=-80}, -- 
    [7] = {['submap_index']='4d_5',['x1']=-578,['y1']=-162,['x2']=-242,['y2']=-600}, --
}
NyzulController._startingRune = T{[822] = {['name']="Rune of Transfer",['index']=822,['x']=-20,['y']=-11}}
NyzulController._lampIndicies = T{0x2D4,0x2D5,0x2D6,0x2D7,0x2D8} -- 724-728
NyzulController._runeOfTransferIndicies = T{0x2D2, 0x2D3} -- Model 1509, At start 1507 - 722, 723
NyzulController._optDoorIndicies = T{
    ['start'] = {},
    ['4d_0'] = {0x2EA, 0x2EB, 0x2EC, 0x2ED, 0x2EE, 0x2EF, 0x2F0, 0x2F1, 0x2F2},
    ['4d_1'] = {0x2F3, 0x2F4, 0x2F5, 0x2F6, 0x2F7, 0x2F8, 0x2F9, 0x2FA, 0x2FB},
    ['4d_2'] = {0x2FC, 0x2FD, 0x2FE, 0x2FF, 0x300, 0x301, 0x302, 0x303, 0x304, 0x305},
    ['4d_3'] = {0x306, 0x307, 0x308, 0x309, 0x30A, 0x30B, 0x30C, 0x30D, 0x30E, 0x30F},
    ['4d_4'] = {0x310, 0x311, 0x312, 0x313, 0x314, 0x315, 0x316, 0x317, 0x318, 0x319, 0x31A, 0x31B},
    ['4d_5'] = {0x31C, 0x31D, 0x31E, 0x31F, 0x320, 0x321, 0x322, 0x323, 0x324, 0x325, 0x326, 0x327, 0x328, 0x329, 0x32A, 0x32B}
} -- Unknown: 0x32C,0x32D,0x32E,

NyzulController._navTables = {
    ['4d_0']= { -- QA'd
        [1]={['y']=-440,['x']=440,['c']=1,},[2]={['y']=-440,['x']=460,['c']=1,},[3]={['y']=-440,['x']=480,['c']=1,},[4]={['y']=-460,['x']=460,['c']=1,},[5]={['y']=-480,['x']=460,['c']=1,},[6]={['y']=-500,['x']=380,['c']=1,},[7]={['y']=-500,['x']=400,['c']=1,},[8]={['y']=-500,['x']=420,['c']=1,},[9]={['y']=-500,['x']=440,['c']=1,},[10]={['y']=-500,['x']=460,['c']=1,},
        [11]={['y']=-500,['x']=480,['c']=1,},[12]={['y']=-500,['x']=500,['c']=1,},[13]={['y']=-520,['x']=380,['c']=1,},[14]={['y']=-520,['x']=420,['c']=1,},[15]={['y']=-520,['x']=460,['c']=0,},[16]={['y']=-520,['x']=480,['c']=0,},[17]={['y']=-520,['x']=500,['c']=1,},[18]={['y']=-520,['x']=560,['c']=1,},[19]={['y']=-540,['x']=380,['c']=1,},[20]={['y']=-540,['x']=400,['c']=1,},
        [21]={['y']=-540,['x']=420,['c']=1,},[22]={['y']=-540,['x']=460,['c']=0,},[23]={['y']=-540,['x']=480,['c']=0,},[24]={['y']=-540,['x']=500,['c']=1,},[25]={['y']=-540,['x']=520,['c']=1,},[26]={['y']=-540,['x']=540,['c']=1,},[27]={['y']=-540,['x']=560,['c']=1,},[28]={['y']=-560,['x']=380,['c']=1,},[29]={['y']=-560,['x']=420,['c']=1,},[30]={['y']=-560,['x']=500,['c']=1,},
        [31]={['y']=-560,['x']=560,['c']=1,},[32]={['y']=-580,['x']=380,['c']=1,},[33]={['y']=-580,['x']=400,['c']=1,},[34]={['y']=-580,['x']=420,['c']=1,},[35]={['y']=-580,['x']=440,['c']=1,},[36]={['y']=-580,['x']=460,['c']=1,},[37]={['y']=-580,['x']=480,['c']=1,},[38]={['y']=-600,['x']=460,['c']=1,},[39]={['y']=-620,['x']=460,['c']=1,},[40]={['y']=-640,['x']=440,['c']=1,},
        [41]={['y']=-640,['x']=460,['c']=1,},[42]={['y']=-640,['x']=480,['c']=1,},
    },
    ['4d_1']= { -- QA'd
        [1]={['y']=100,['x']=460,['c']=1},[2]={['y']=100,['x']=480,['c']=1},[3]={['y']=100,['x']=500,['c']=1},[4]={['y']=80,['x']=460,['c']=1},[5]={['y']=80,['x']=500,['c']=1},[6]={['y']=60,['x']=460,['c']=1},[7]={['y']=60,['x']=480,['c']=1},[8]={['y']=60,['x']=500,['c']=1},[9]={['y']=60,['x']=520,['c']=1},[10]={['y']=60,['x']=540,['c']=1},[11]={['y']=60,['x']=560,['c']=1},[12]={['y']=60,['x']=580,['c']=1},
        [13]={['y']=40,['x']=400,['c']=1},[14]={['y']=40,['x']=460,['c']=1},[15]={['y']=40,['x']=500,['c']=1},[16]={['y']=40,['x']=540,['c']=1},[17]={['y']=40,['x']=580,['c']=0},[18]={['y']=20,['x']=400,['c']=1},[19]={['y']=20,['x']=420,['c']=1},[20]={['y']=20,['x']=440,['c']=1},[21]={['y']=20,['x']=460,['c']=1},[22]={['y']=20,['x']=500,['c']=1},[23]={['y']=20,['x']=540,['c']=1},
        [24]={['y']=20,['x']=560,['c']=1},[25]={['y']=20,['x']=580,['c']=1},[26]={['y']=20,['x']=600,['c']=1},[27]={['y']=20,['x']=620,['c']=1},[28]={['y']=0,['x']=400,['c']=1},[29]={['y']=0,['x']=460,['c']=1},[30]={['y']=0,['x']=500,['c']=0},[31]={['y']=0,['x']=540,['c']=1},[32]={['y']=0,['x']=620,['c']=1},[33]={['y']=-20,['x']=460,['c']=1},[34]={['y']=-20,['x']=480,['c']=1},
        [35]={['y']=-20,['x']=500,['c']=1},[36]={['y']=-20,['x']=520,['c']=1},[37]={['y']=-20,['x']=540,['c']=1},[38]={['y']=-20,['x']=560,['c']=1},[39]={['y']=-20,['x']=580,['c']=1},[40]={['y']=-20,['x']=600,['c']=0},[41]={['y']=-20,['x']=620,['c']=1},[42]={['y']=-40,['x']=500,['c']=1},[43]={['y']=-40,['x']=620,['c']=1},[44]={['y']=-60,['x']=500,['c']=1},[45]={['y']=-60,['x']=620,['c']=1},
        [46]={['y']=-80,['x']=500,['c']=1},[47]={['y']=-80,['x']=620,['c']=1},[48]={['y']=-100,['x']=460,['c']=1},[49]={['y']=-100,['x']=480,['c']=1},[50]={['y']=-100,['x']=500,['c']=1},[51]={['y']=-100,['x']=520,['c']=1},[52]={['y']=-100,['x']=540,['c']=1},[53]={['y']=-100,['x']=560,['c']=1},[54]={['y']=-100,['x']=580,['c']=1},[55]={['y']=-100,['x']=600,['c']=0},[56]={['y']=-100,['x']=620,['c']=1},
        [57]={['y']=-120,['x']=400,['c']=1},[58]={['y']=-120,['x']=460,['c']=1},[59]={['y']=-120,['x']=500,['c']=1},[60]={['y']=-120,['x']=540,['c']=1},[61]={['y']=-120,['x']=620,['c']=1},[62]={['y']=-140,['x']=400,['c']=1},[63]={['y']=-140,['x']=420,['c']=1},[64]={['y']=-140,['x']=440,['c']=1},[65]={['y']=-140,['x']=460,['c']=1},[66]={['y']=-140,['x']=500,['c']=1},[67]={['y']=-140,['x']=540,['c']=1},
        [68]={['y']=-140,['x']=560,['c']=1},[69]={['y']=-140,['x']=580,['c']=1},[70]={['y']=-140,['x']=600,['c']=1},[71]={['y']=-140,['x']=620,['c']=1},[72]={['y']=-160,['x']=400,['c']=1},[73]={['y']=-160,['x']=460,['c']=1},[74]={['y']=-160,['x']=500,['c']=1},[75]={['y']=-160,['x']=540,['c']=1},[76]={['y']=-160,['x']=580,['c']=0},[77]={['y']=-180,['x']=460,['c']=1},[78]={['y']=-180,['x']=480,['c']=1},
        [79]={['y']=-180,['x']=500,['c']=1},[80]={['y']=-180,['x']=520,['c']=1},[81]={['y']=-180,['x']=540,['c']=1},[82]={['y']=-180,['x']=560,['c']=1},[83]={['y']=-180,['x']=580,['c']=1},[84]={['y']=-200,['x']=460,['c']=1},[85]={['y']=-200,['x']=500,['c']=0},[86]={['y']=-220,['x']=460,['c']=1},[87]={['y']=-220,['x']=480,['c']=1},[88]={['y']=-220,['x']=500,['c']=1}
    },
    ['4d_2']= { -- QA'd
        [1]={['y']=500,['x']=420,['c']=1},[2]={['y']=500,['x']=440,['c']=1},[3]={['y']=500,['x']=460,['c']=1},[4]={['y']=500,['x']=480,['c']=1},[5]={['y']=500,['x']=500,['c']=1},[6]={['y']=480,['x']=420,['c']=1},[7]={['y']=480,['x']=500,['c']=1},[8]={['y']=460,['x']=420,['c']=1},[9]={['y']=460,['x']=440,['c']=1},[10]={['y']=460,['x']=460,['c']=1},
        [11]={['y']=460,['x']=480,['c']=1},[12]={['y']=460,['x']=500,['c']=1},[13]={['y']=440,['x']=420,['c']=1},[14]={['y']=440,['x']=500,['c']=1},[15]={['y']=420,['x']=420,['c']=1},[16]={['y']=420,['x']=440,['c']=1},[17]={['y']=420,['x']=460,['c']=1},[18]={['y']=420,['x']=480,['c']=1},[19]={['y']=420,['x']=500,['c']=1},[20]={['y']=420,['x']=520,['c']=1},
        [21]={['y']=420,['x']=540,['c']=1},[22]={['y']=420,['x']=560,['c']=1},[23]={['y']=420,['x']=580,['c']=1},[24]={['y']=400,['x']=580,['c']=1},[25]={['y']=380,['x']=500,['c']=1},[26]={['y']=380,['x']=520,['c']=1},[27]={['y']=380,['x']=540,['c']=1},[28]={['y']=380,['x']=560,['c']=1},[29]={['y']=380,['x']=580,['c']=1},[30]={['y']=360,['x']=580,['c']=1},
        [31]={['y']=340,['x']=420,['c']=1},[32]={['y']=340,['x']=440,['c']=1},[33]={['y']=340,['x']=460,['c']=1},[34]={['y']=340,['x']=480,['c']=1},[35]={['y']=340,['x']=500,['c']=1},[36]={['y']=340,['x']=520,['c']=1},[37]={['y']=340,['x']=540,['c']=1},[38]={['y']=340,['x']=560,['c']=1},[39]={['y']=340,['x']=580,['c']=1},[40]={['y']=320,['x']=420,['c']=1},
        [41]={['y']=320,['x']=500,['c']=1},[42]={['y']=300,['x']=420,['c']=1},[43]={['y']=300,['x']=440,['c']=0},[44]={['y']=300,['x']=460,['c']=1},[45]={['y']=300,['x']=480,['c']=1},[46]={['y']=300,['x']=500,['c']=1},[47]={['y']=280,['x']=420,['c']=1},[48]={['y']=280,['x']=500,['c']=1},[49]={['y']=260,['x']=420,['c']=1},[50]={['y']=260,['x']=440,['c']=1},
        [51]={['y']=260,['x']=460,['c']=1},[52]={['y']=260,['x']=480,['c']=1},[53]={['y']=260,['x']=500,['c']=1},
    },
    ['4d_3']= { -- QA'd
        [1]={['y']=-280,['x']=-60,['c']=1},[2]={['y']=-280,['x']=-40,['c']=1},[3]={['y']=-280,['x']=-20,['c']=1},[4]={['y']=-280,['x']=0,['c']=1},[5]={['y']=-280,['x']=20,['c']=1},[6]={['y']=-300,['x']=-60,['c']=1},[7]={['y']=-300,['x']=-20,['c']=0},[8]={['y']=-300,['x']=20,['c']=1},[9]={['y']=-320,['x']=-60,['c']=1},[10]={['y']=-320,['x']=-40,['c']=0},
        [11]={['y']=-320,['x']=-20,['c']=1},[12]={['y']=-320,['x']=0,['c']=1},[13]={['y']=-320,['x']=20,['c']=1},[14]={['y']=-320,['x']=40,['c']=1},[15]={['y']=-320,['x']=60,['c']=1},[16]={['y']=-340,['x']=-60,['c']=0},[17]={['y']=-340,['x']=60,['c']=1},[18]={['y']=-360,['x']=-60,['c']=1},[19]={['y']=-360,['x']=20,['c']=1},[20]={['y']=-360,['x']=40,['c']=1},
        [21]={['y']=-360,['x']=60,['c']=1},[22]={['y']=-360,['x']=80,['c']=1},[23]={['y']=-360,['x']=-100,['c']=1},[24]={['y']=-380,['x']=-60,['c']=1},[25]={['y']=-380,['x']=-40,['c']=1},[26]={['y']=-380,['x']=20,['c']=1},[27]={['y']=-380,['x']=100,['c']=1},[28]={['y']=-400,['x']=-60,['c']=1},[29]={['y']=-400,['x']=-40,['c']=1},[30]={['y']=-400,['x']=-20,['c']=1},
        [31]={['y']=-400,['x']=0,['c']=0},[32]={['y']=-400,['x']=20,['c']=1},[33]={['y']=-400,['x']=100,['c']=1},[34]={['y']=-420,['x']=-60,['c']=1},[35]={['y']=-420,['x']=-40,['c']=1},[36]={['y']=-420,['x']=20,['c']=1},[37]={['y']=-420,['x']=100,['c']=1},[38]={['y']=-440,['x']=-60,['c']=1},[39]={['y']=-440,['x']=20,['c']=1},[40]={['y']=-440,['x']=40,['c']=1},
        [41]={['y']=-440,['x']=60,['c']=1},[42]={['y']=-440,['x']=80,['c']=1},[43]={['y']=-440,['x']=100,['c']=1},[44]={['y']=-460,['x']=-60,['c']=0},[45]={['y']=-460,['x']=60,['c']=1},[46]={['y']=-480,['x']=-60,['c']=1},[47]={['y']=-480,['x']=-40,['c']=1},[48]={['y']=-480,['x']=-20,['c']=1},[49]={['y']=-480,['x']=0,['c']=1},[50]={['y']=-480,['x']=20,['c']=1},
        [51]={['y']=-480,['x']=40,['c']=1},[52]={['y']=-480,['x']=60,['c']=1},[53]={['y']=-500,['x']=-60,['c']=1},[54]={['y']=-480,['x']=-20,['c']=0},[55]={['y']=-500,['x']=20,['c']=1},[56]={['y']=-520,['x']=-60,['c']=1},[57]={['y']=-520,['x']=-40,['c']=1},[58]={['y']=-520,['x']=-20,['c']=1},[59]={['y']=-520,['x']=0,['c']=1},[60]={['y']=-520,['x']=20,['c']=1}
    },
    ['4d_4']= { -- QA'd
        [1]={['y']=180,['x']=-60,['c']=1},[2]={['y']=180,['x']=-40,['c']=1},[3]={['y']=180,['x']=-20,['c']=1},[4]={['y']=180,['x']=0,['c']=1},[5]={['y']=180,['x']=20,['c']=1},[6]={['y']=160,['x']=-60,['c']=1},[7]={['y']=160,['x']=-20,['c']=1},[8]={['y']=160,['x']=20,['c']=1},[9]={['y']=140,['x']=-60,['c']=1},[10]={['y']=140,['x']=-20,['c']=1},
        [11]={['y']=140,['x']=20,['c']=1},[12]={['y']=120,['x']=-60,['c']=1},[13]={['y']=120,['x']=20,['c']=1},[14]={['y']=100,['x']=-100,['c']=1},[15]={['y']=100,['x']=-80,['c']=1},[16]={['y']=100,['x']=-60,['c']=1},[17]={['y']=100,['x']=-20,['c']=1},[18]={['y']=100,['x']=0,['c']=1},[19]={['y']=100,['x']=20,['c']=1},[20]={['y']=100,['x']=40,['c']=1},
        [21]={['y']=100,['x']=60,['c']=1},[22]={['y']=100,['x']=80,['c']=1},[23]={['y']=100,['x']=100,['c']=1},[24]={['y']=80,['x']=-100,['c']=1},[25]={['y']=80,['x']=-60,['c']=1},[26]={['y']=80,['x']=60,['c']=1},[27]={['y']=80,['x']=100,['c']=1},[28]={['y']=60,['x']=-100,['c']=1},[29]={['y']=60,['x']=-80,['c']=1},[30]={['y']=60,['x']=-60,['c']=1},
        [31]={['y']=60,['x']=60,['c']=1},[32]={['y']=60,['x']=80,['c']=1},[33]={['y']=60,['x']=100,['c']=1},[34]={['y']=40,['x']=-100,['c']=1},[35]={['y']=40,['x']=-60,['c']=1},[36]={['y']=40,['x']=60,['c']=1},[37]={['y']=40,['x']=100,['c']=1},[38]={['y']=20,['x']=-100,['c']=1},[39]={['y']=20,['x']=-80,['c']=1},[40]={['y']=20,['x']=-60,['c']=1},
        [41]={['y']=20,['x']=-20,['c']=1},[42]={['y']=20,['x']=0,['c']=1},[43]={['y']=20,['x']=20,['c']=1},[44]={['y']=20,['x']=40,['c']=1},[45]={['y']=20,['x']=60,['c']=1},[46]={['y']=20,['x']=80,['c']=1},[47]={['y']=20,['x']=100,['c']=1},[48]={['y']=0,['x']=-60,['c']=1},[49]={['y']=0,['x']=20,['c']=1},[50]={['y']=-20,['x']=-60,['c']=1},
        [51]={['y']=-20,['x']=-20,['c']=1},[52]={['y']=-20,['x']=20,['c']=1},[53]={['y']=-40,['x']=-60,['c']=1},[54]={['y']=-40,['x']=-20,['c']=0},[55]={['y']=-40,['x']=20,['c']=1},[56]={['y']=-60,['x']=-60,['c']=1},[57]={['y']=-60,['x']=-40,['c']=1},[58]={['y']=-60,['x']=-20,['c']=1},[59]={['y']=-60,['x']=0,['c']=1},[60]={['y']=-60,['x']=20,['c']=1}
    },
    ['4d_5']= { -- QA'd
        [1]={['y']=-180,['x']=-540,['c']=1},[2]={['y']=-180,['x']=-520,['c']=1},[3]={['y']=-180,['x']=-500,['c']=1},[4]={['y']=-180,['x']=-480,['c']=1},[5]={['y']=-180,['x']=-460,['c']=1},[6]={['y']=-180,['x']=-440,['c']=1},[7]={['y']=-180,['x']=-420,['c']=1},[8]={['y']=-200,['x']=-540,['c']=0},[9]={['y']=-200,['x']=-460,['c']=1},[10]={['y']=-220,['x']=-540,['c']=1},
        [11]={['y']=-220,['x']=-460,['c']=1},[12]={['y']=-220,['x']=-440,['c']=1},[13]={['y']=-220,['x']=-420,['c']=1},[14]={['y']=-220,['x']=-400,['c']=1},[15]={['y']=-220,['x']=-380,['c']=1},[16]={['y']=-240,['x']=-540,['c']=1},[17]={['y']=-240,['x']=-520,['c']=1},[18]={['y']=-240,['x']=-380,['c']=1},[19]={['y']=-260,['x']=-540,['c']=1},[20]={['y']=-260,['x']=-520,['c']=1},
        [21]={['y']=-260,['x']=-500,['c']=1},[22]={['y']=-260,['x']=-480,['c']=0},[23]={['y']=-260,['x']=-460,['c']=1},[24]={['y']=-260,['x']=-440,['c']=1},[25]={['y']=-260,['x']=-420,['c']=1},[26]={['y']=-260,['x']=-400,['c']=1},[27]={['y']=-260,['x']=-380,['c']=1},[28]={['y']=-260,['x']=-360,['c']=1},[29]={['y']=-260,['x']=-340,['c']=1},[30]={['y']=-280,['x']=-540,['c']=1},
        [31]={['y']=-280,['x']=-520,['c']=1},[32]={['y']=-280,['x']=-460,['c']=1},[33]={['y']=-280,['x']=-380,['c']=1},[34]={['y']=-280,['x']=-340,['c']=1},[35]={['y']=-300,['x']=-540,['c']=1},[36]={['y']=-300,['x']=-460,['c']=1},[37]={['y']=-300,['x']=-380,['c']=1},[38]={['y']=-300,['x']=-360,['c']=1},[39]={['y']=-300,['x']=-340,['c']=1},[40]={['y']=-320,['x']=-540,['c']=0},
        [41]={['y']=-320,['x']=-460,['c']=1},[42]={['y']=-320,['x']=-380,['c']=0},[43]={['y']=-340,['x']=-540,['c']=1},[44]={['y']=-340,['x']=-520,['c']=1},[45]={['y']=-340,['x']=-500,['c']=1},[46]={['y']=-340,['x']=-480,['c']=1},[47]={['y']=-340,['x']=-460,['c']=1},[48]={['y']=-340,['x']=-380,['c']=1},[49]={['y']=-340,['x']=-300,['c']=1},[50]={['y']=-340,['x']=-280,['c']=1},
        [51]={['y']=-340,['x']=-260,['c']=1},[52]={['y']=-360,['x']=-540,['c']=1},[53]={['y']=-360,['x']=-460,['c']=1},[54]={['y']=-360,['x']=-400,['c']=1},[55]={['y']=-380,['x']=-400,['c']=1},[56]={['y']=-360,['x']=-360,['c']=1},[57]={['y']=-360,['x']=-300,['c']=1},[58]={['y']=-360,['x']=-260,['c']=1},[59]={['y']=-380,['x']=-540,['c']=1},[60]={['y']=-380,['x']=-520,['c']=1},
        [61]={['y']=-380,['x']=-500,['c']=1},[62]={['y']=-380,['x']=-460,['c']=1},[63]={['y']=-380,['x']=-440,['c']=0},[64]={['y']=-380,['x']=-420,['c']=1},[65]={['y']=-380,['x']=-400,['c']=1},[66]={['y']=-380,['x']=-380,['c']=1},[67]={['y']=-380,['x']=-360,['c']=1},[68]={['y']=-380,['x']=-340,['c']=1},[69]={['y']=-380,['x']=-320,['c']=0},[70]={['y']=-380,['x']=-300,['c']=1},
        [71]={['y']=-380,['x']=-260,['c']=1},[72]={['y']=-400,['x']=-540,['c']=1},[73]={['y']=-400,['x']=-460,['c']=1},[74]={['y']=-400,['x']=-400,['c']=1},[75]={['y']=-400,['x']=-380,['c']=1},[76]={['y']=-400,['x']=-360,['c']=1},[77]={['y']=-400,['x']=-300,['c']=1},[78]={['y']=-400,['x']=-260,['c']=1},[79]={['y']=-420,['x']=-540,['c']=1},[80]={['y']=-420,['x']=-520,['c']=1},
        [81]={['y']=-420,['x']=-500,['c']=1},[82]={['y']=-420,['x']=-480,['c']=1},[83]={['y']=-420,['x']=-460,['c']=1},[84]={['y']=-420,['x']=-380,['c']=1},[85]={['y']=-420,['x']=-300,['c']=1},[86]={['y']=-420,['x']=-280,['c']=1},[87]={['y']=-420,['x']=-360,['c']=1},[88]={['y']=-440,['x']=-540,['c']=0},[89]={['y']=-440,['x']=-460,['c']=1},[90]={['y']=-440,['x']=-380,['c']=0},
        [91]={['y']=-460,['x']=-540,['c']=1},[92]={['y']=-460,['x']=-460,['c']=1},[93]={['y']=-460,['x']=-380,['c']=1},[94]={['y']=-460,['x']=-360,['c']=1},[95]={['y']=-460,['x']=-340,['c']=1},[96]={['y']=-480,['x']=-540,['c']=1},[97]={['y']=-480,['x']=-520,['c']=1},[98]={['y']=-480,['x']=-460,['c']=1},[99]={['y']=-480,['x']=-380,['c']=1},[100]={['y']=-480,['x']=-340,['c']=1},
        [101]={['y']=-500,['x']=-540,['c']=1},[102]={['y']=-500,['x']=-520,['c']=1},[103]={['y']=-500,['x']=-500,['c']=1},[104]={['y']=-500,['x']=-480,['c']=0},[105]={['y']=-500,['x']=-460,['c']=1},[106]={['y']=-500,['x']=-440,['c']=1},[107]={['y']=-500,['x']=-420,['c']=1},[108]={['y']=-500,['x']=-400,['c']=1},[109]={['y']=-500,['x']=-380,['c']=1},[110]={['y']=-500,['x']=-360,['c']=1},
        [111]={['y']=-500,['x']=-340,['c']=1},[112]={['y']=-520,['x']=-540,['c']=1},[113]={['y']=-520,['x']=-520,['c']=1},[114]={['y']=-520,['x']=-380,['c']=1},[115]={['y']=-540,['x']=-540,['c']=1},[116]={['y']=-540,['x']=-460,['c']=1},[117]={['y']=-540,['x']=-440,['c']=1},[118]={['y']=-540,['x']=-420,['c']=1},[119]={['y']=-540,['x']=-400,['c']=1},[120]={['y']=-540,['x']=-380,['c']=1},
        [121]={['y']=-560,['x']=-540,['c']=0},[122]={['y']=-560,['x']=-460,['c']=1},[123]={['y']=-580,['x']=-540,['c']=1},[124]={['y']=-580,['x']=-520,['c']=1},[125]={['y']=-580,['x']=-500,['c']=1},[126]={['y']=-580,['x']=-480,['c']=1},[127]={['y']=-580,['x']=-460,['c']=1},[128]={['y']=-580,['x']=-440,['c']=1},[129]={['y']=-580,['x']=-420,['c']=1}
    },
}

NyzulController._specifiedEnemies = T{'Heraldic Imp','Psycheflayer','Poroggo Gent','Ebony Pudding','Racing Chariot','Qiqirn Treasure Hunter','Qiqirn Archaeologist'}
NyzulController._enemyLeader = T{
    'Long-Gunned Chariot','Long-Horned Chariot','Battledressed Chariot','Shielded Chariot',
    'Anise Custard','Caraway Custard','Cumin Custard','Ginger Custard','Nutmeg Custard','Vanilla Custard',
    'Mokka','Mokke','Mokku',
    'Eriri Samariri','Oriri Samariri','Uriri Samariri',
    'Vile Ineef','Vile Wahdaha','Vile Yabeewa',
    'Gem Heister Roorooroon','Quick Draw Sasaroon','Stealth Bomber Gagaroon',
    'Cerberus','Hydra','Khimaira'
}
NyzulController._timeLimit = 1800
NyzulController._INF = 1/0

function NyzulController:constructController(player, observer, navigation)
    local self = setmetatable({}, NyzulController)

    self.player = player
    self.navigation = navigation
    self.observer = observer

    self.on_switch = 0
    self.state = 'idle'
    self.last_state = {
        ['value'] = 'idle',
        ['time'] = 0
    }
    self.state_flags = {}

    self.role = 'coordinator'
    self.party_size = 1
    self.party_list = {}
    self.start_at_floor = 20 -- 1 is floor 1, option index 20 is floor 96
    self.use_party_chat = true

    self.smite_command = 'bb fight %s'
    self.aggro_terminated_string = ''

    self.current_submap = 0
    self.time_remaining = 0
    self.exit_threshold = 180
    self.should_exit = false

    self.time_repo = {
        ['nyzul_start'] = 0,
        ['goal_set'] = 0,
        ['rune_of_transfer'] = 0,
        ['state_work_start'] = 0
    }

    self.current_floor = 1
    self.current_floor_goal = ''
    self.current_floor_goal_status = ''
    self.current_floor_lamp_goal = ''
    self.current_floor_start_index = nil

    self.current_floor_spec_enemies = {}
    self.current_floor_enemy_leader = {}

    self.rune_info = {
        [722] = {},
        [723] = {},
    }
    self.current_floor_rune = {}
    self.current_floor_lamp_info = {
        [724] = {},
        [725] = {},
        [726] = {},
        [727] = {},
        [728] = {},
    }
    self.current_floor_lamp_order = {}
    self.current_floor_lamp_order_requested = 0
    self.current_floor_lamp_activation_time = 0

    self.current_floor_navigation_history = {}
    self.current_floor_nav_table = {}
    self.current_floor_cached_paths = nil

    self.awaitedPacket = T{
        ['active'] = false,
        ['index'] = 0,
        ['received'] = false,
        ['return'] = false}
    self.receivedPacket = T{}

    self.floor_summary_report = {}
    self.found_doors = {}
    self.found_doors_indexes = {}

    return self
end

------------------------
-- Property Management
------------------------
function NyzulController:setOnSwitch(value)
    if not T{0,1}:contains(value) then return end
    self.on_switch = value
end 
function NyzulController:setState(new_state)
    if self.state == new_state then return true end
    if not NyzulController._allowedStates:contains(new_state) then return false end

    self.last_state['value'] = self.state
    self.state = new_state
    self.last_state['time'] = os.clock()
end
function NyzulController:setRole(role)
    if not NyzulController._roles:contains(role) then return false end
    self.role = role
end
function NyzulController:resetCurrentFloorLampInfo()
    self.current_floor_lamp_info = {}
    for _,v in pairs(NyzulController._lampIndicies) do
        self.current_floor_lamp_info[v] = {}
    end
    self.current_floor_lamp_order_requested = 0
    self.current_floor_lamp_activation_time = 0
end
function NyzulController:setFloorRune()
    local floor_rune = Observer:pickNearest(Observer:getMArray("Transfer",true))
    if floor_rune then
        self.current_floor_rune = floor_rune
    end
end
function NyzulController:resetCurrentFloorRuneInfo()
    self.rune_info = {}
    for _,v in pairs(NyzulController._runeOfTransferIndicies) do
        self.rune_info[v] = {}
    end
    self.current_floor_rune = {}
end
function NyzulController:resetFloorNavigationHistory()
    self.current_floor_navigation_history = {}
    self.current_floor_nav_table = {}
end
function NyzulController:resetFloorDependents()
    self.current_floor_goal = ''
    self.current_floor_goal_status = ''
    self.current_floor_lamp_goal = ''
    self.current_submap = 0
    self.current_floor_start_index = nil
    self.current_floor_enemy_leader = {}
    self.current_floor_spec_enemies = {}
    self:resetFloorTimings()
    self:resetCurrentFloorLampInfo()
    self:resetCurrentFloorRuneInfo()
    self:resetFloorNavigationHistory()
end
function NyzulController:resetAwaitedPacket()
    self.awaitedPacket = T{['active'] = false, ['index'] = 0, ['received'] = false, ['return'] = false}
end
function NyzulController:resetReceivedPacket()
    self.receivedPacket = T{}
end
function NyzulController:requestedWorkAt(value)
    if value > 0 then
        self.time_repo.state_work_start = value
    end
end
function NyzulController:checkFences()
    self.player:update()
    local current_location = {['x'] = self.player.mob.x, ['y'] = self.player.mob.y}
    local found_fence = false
    for i,v in ipairs(NyzulController._fences) do
        if current_location.x >= v.x1 and current_location.x <= v.x2
            and current_location.y >= v.y2 and current_location.y <= v.y1 and not found_fence then
            -- Current location is within this fence
            self.current_submap = v['submap_index']
            found_fence = true
        end
    end
    if not found_fence then
        self.current_submap = 'NA'
    end
end
function NyzulController:updateParty()
    local party = windower.ffxi.get_party()
    if self.party_count ~= party.party1_count then
        self.party_count = party.party1_count
    end
    for i=0,5 do
        if party['p'..i] and party['p'..i]['mob'] then
            local party_index = party['p'..i]['mob']['index']
            self.party_list[party_index] = party['p'..i]['mob']
        end
    end
end
function NyzulController:setCurrentFloorStartIndex(value)
    if value > 0 then
        self.current_floor_start_index = value
    end
end
function NyzulController:resetFloorTimings()
    self.time_repo['goal_set'] = 0
    self.time_repo['rune_of_transfer'] = 0
    self.time_repo['state_work_start'] = 0
end
function NyzulController:setTimeStart()
    self.time_repo['nyzul_start'] = os.clock()
end
function NyzulController:cycleRole()
    local index = 0
    for i,v in pairs(NyzulController._roles) do
        if v == self.role then
            index = i
        end
    end
    index = (index % NyzulController._roles:length()) + 1
    notice("Weee, you're a "..NyzulController._roles[index].."!")
    self:setRole(NyzulController._roles[index])
end

------------------------
-- Main Method
------------------------
function NyzulController:fuckNyzul(Player, Observer, Navigation)

    local haveAggro = next(Observer.aggro)
    local haveTargets = next(Observer.targets)
    local currentState = self.state
    local currentStateFlags = self.state_flags
    local cfg = self.current_floor_goal
    self.player:update()

    -- Housekeeping, adjust our time remaining.
    if self.time_repo['nyzul_start'] > 0 then
        self.time_remaining = math.floor(NyzulController._timeLimit - (os.clock() - self.time_repo['nyzul_start']))
        if self.time_remaining < 0 then
            self.time_remaining = 0
        end
        if self.time_remaining < self.exit_threshold then
            self.should_exit = true
        else
            self.should_exit = false
        end
    end

    -- State Transitions (No Work should be done, just assessment)
    -- First determine if state needs to change
    local state_transitions = {
        ['idle'] = 'checkGoalTargets',  --> Sets State to: idle, travel, awaiting_smiting, use_lamp
        -- ['awaiting_smiting'] = '', -- > Does nothing really, just ensures nothing else is being done.
    }
    if currentState and state_transitions[currentState] and (os.clock() - self.last_state['time'] > 1) then
        self[state_transitions[currentState]](self)
        -- No matter the state and work being done, we need to keep an eye on aggro, as it can really bung up some shit.
        if self.state ~= 'awaiting_smiting' and haveTargets ~= nil or haveAggro ~= nil then
            self:setState('awaiting_smiting')
            return
        end
    end

    -- State Executions
    -- Now do some damn work. But make sure you do it once.
    local state_executions = {
        ['use_start_rune'] = 'checkStartingRune', -- Moves to 'awaiting_start' (caught in delegate)
        ['received_start'] = 'callStartPortRoutine',
        ['use_floor_rune'] = 'checkTheRuneThing', -- Floor objective is complete, check for proximity to Rune
        ['floor_complete_+'] = 'useTheRuneThing', -- We're close enough to use the rune, use it.
        ['received_rune'] = 'callPortUpRoutine', -- We poked the rune, awaiting the incoming.
        ['use_lamp'] = 'checkTheLamp',
        ['received_lamp'] = 'callLampRoutine',
        ['have_targets'] = 'callSmiteRoutine',
        ['travel'] = 'checkNodeNavigation',
        ['awaiting_smiting'] = 'callSmiteRoutine',
    }
    if currentState and state_executions[currentState] and (os.clock() - self.time_repo.state_work_start > 2) then
        self:requestedWorkAt(os.clock())
        self[state_executions[currentState]](self)
    end

end

------------------------
-- Observer get rekt (sowwy)
------------------------
function NyzulController:checkGoalTargets()
    local cfg = self.current_floor_goal
    if cfg == 'Enemy Leader' then
        -- Be Scanning for the Enemy Leader
        self:scanForLeader()
    elseif cfg == 'Spec. Enemies' then
        -- Scan for the enemy types ?
        self:scanForEnemyTypes()
    end

    -- Starting Floor Approach the Rune and Get the Port up:
    if self.current_submap == 'start' and self.role == 'coordinator' then
        if Observer:distanceBetween(self.player.mob, NyzulController._startingRune[822]) > 3.8 then
            local start_rune = {[1]={["y"]=-12,["x"]=-20,['z']=0},}
            self.navigation:setShortCourse(start_rune)
            self.navigation:setNeedClosestNode(true)
            self.navigation:update()
            self:setState('travel')
        else
            -- We've arrived, engage the rune~
            self:setState('use_start_rune')
        end
    end

    -- If something is discernable here this can trigger our travel state.
    -- After 3 seconds of having a floor objective, if nothing is scannable/discernable by what's nearby, we need to select a random walk and get travelling.
    -- I'm using 3 seconds here as a catch all for packet loss/communication and enemy spawning and door ascernment.

end
function NyzulController:scanForLeader()
    local scan_results = Observer:getMArray(NyzulController._enemyLeader)

    local leader = nil
    for i,v in pairs(scan_results) do
        leader = v
    end
    if leader then
        self.current_floor_enemy_leader[leader.index] = {['mob'] = leader}
    end
end
function NyzulController:scanForEnemyTypes()
    local scan_results = Observer:getMArray(NyzulController._specifiedEnemies)

    if next(scan_results) ~= nil then
        for i,v in pairs(scan_results) do
            if v.valid_target and v.hpp > 0 then
                self.current_floor_spec_enemies[v.index] = {['mob']=v}
            end
        end
    end
end
function NyzulController:withinFence(mob, submap_index)
    if mob and mob.x and mob.y then
        if mob.x >= NyzulController._fences[submap_index].x1 and mob.x <= NyzulController._fences[submap_index].x2
            and mob.y >= NyzulController._fences[submap_index].y2 and mob.y <= NyzulController._fences[submap_index].y1 then
                return true
            end
    end
    return false
end
function NyzulController:checkNodeNavigation()
    -- Have we Reached our Target? If so we need to swap back to Idle to determine goal targets again
    -- If we've reached our target, this needs to go into the navigation history.
    -- I mean we really don't have anything necessary to do here... it's handled in the navigation delegate
    if self.navigation.reachedEnd then
        -- table.insert(self.current_floor_navigation_history, {})
    end
end

------------------------
-- Rune Interactions
------------------------

function NyzulController:checkTheRuneThing()
    local floors_rune = self.current_floor_rune
    local target = nil
    if next(floors_rune) ~= nil then
        target = floors_rune
    else
        target = Observer:pickNearest(Observer:getMArray("Transfer",true))
    end

    if Observer:distanceBetween(self.player.mob, target) > 6 then
        return
    end
    -- Here is where we'd tell the coordinator to return to the rune via pathfinding.

    -- If not the coordinator but you ARE near the lamp, let's save time by ensuring you're not hijacking the rune and port up anyway.
    if self.role ~= 'coordinator' then
        self:updateParty()
        local halt = false
        for i,v in pairs(self.party_list) do
            -- We can just see if they're near enough to the rune (within the same room, just let the coordinator handle it)
            if Observer:distanceBetween(target, v) < 20 then
                halt = true
            end
        end
        if halt then
            return
        end
    end

    self:setState('floor_complete_+')
end
function NyzulController:useTheRuneThing()
    local floors_rune = self.current_floor_rune
    local target = nil
    if next(floors_rune) ~= nil then
        target = floors_rune
    else
        target = Observer:pickNearest(Observer:getMArray("Transfer",true))
    end
    -- Poke that shit
    self:useRuneofTransfer(target)
end
function NyzulController:useRuneofTransfer(target)
    self.awaitedPacket.active = true
    self.awaitedPacket['return'] = true

    local targ = target or Observer:pickNearest(Observer:getMArray("Transfer",true))
    -- Do distance check here and fail if out of range.
    if Observer:distanceBetween(self.player.mob, targ) > 7 then
        return
    end

    if targ and targ.index and targ.id then
        self.awaitedPacket.index = targ.index
		local packet = packets.new('outgoing', 0x01A, {
			["Target"]=targ.id,
			["Target Index"]=targ.index,
			["Category"]=0,
			["Param"]=0,
			["_unknown1"]=0
        })

        self:setState('awaiting_incoming_rune')
		packets.inject(packet)
        notice('Poked Rune of Transfer')
    else
        notice('No Rune of Transfer Found.')
    end
end
function NyzulController:callPortUpRoutine()
    -- Determine if you're the coordinator or are the only one near the lamp (in register code cases)
    local floors_rune = nil
    local targ = floors_rune or Observer:pickNearest(Observer:getMArray("Transfer",true))
    -- Do distance check here and fail if out of range.
    if Observer:distanceBetween(self.player.mob, targ) > 6 then
        return
    end

    -- If not the coordinator but you ARE near the lamp, let's save time by ensuring you're not hijacking the rune and port up anyway.
    if self.role ~= 'coordinator' then
        self:updateParty()
        local halt = false
        for i,v in pairs(self.party) do
            -- We can just see if they're near enough to the rune (within the same room, just let the coordinator handle it)
            if Observer:distanceBetween(targ, v) < 20 then
                halt = true
            end
        end
        if halt then
            return
        end
    end

    local option_index = 2
    if self.should_exit == true then
        option_index = 1
    end

    -- Otherwise, g'head, g'on.
    notice('Injecting Port Up')
    self:injectPortUp(option_index)
    self:setState('idle')
end
function NyzulController:injectPortUp(option_index)
    local base_port_up = packets.new('outgoing', 0x05B)
    base_port_up['Target'] = self.receivedPacket['NPC']
    base_port_up['Option Index'] = 0
    base_port_up['_unknown1'] = 0
    base_port_up['Target Index'] = self.receivedPacket['NPC Index']
    base_port_up['Automated Message'] = true
    base_port_up['_unknown2'] = 0
    base_port_up['Zone'] = NyzulController._nyzulZone
    base_port_up['Menu ID'] = self.receivedPacket['Menu ID']
    packets.inject(base_port_up)

    local port_up_followup = packets.new('outgoing', 0x05B)
    port_up_followup['Target'] = self.receivedPacket['NPC']
    port_up_followup['Option Index'] = option_index
    port_up_followup['_unknown1'] = 0
    port_up_followup['Target Index'] = self.receivedPacket['NPC Index']
    port_up_followup['Automated Message'] = false
    port_up_followup['_unknown2'] = 0
    port_up_followup['Zone'] = NyzulController._nyzulZone
    port_up_followup['Menu ID'] = self.receivedPacket['Menu ID']
    packets.inject(port_up_followup)

    self:resetAwaitedPacket()
    self:resetReceivedPacket()
end

function NyzulController:checkStartingRune()
    local floors_rune = nil
    local target = floors_rune or Observer:pickNearest(Observer:getMArray("Transfer",true))

    if Observer:distanceBetween(self.player.mob, targ) > 6 then
        return
    end

    self:useStartingRune(target) -- Sends the Poke
end
function NyzulController:useStartingRune(target)
    self.awaitedPacket.active = true
    self.awaitedPacket['return'] = true

    if target and target.index and target.id then
        self.awaitedPacket.index = target.index
		local packet = packets.new('outgoing', 0x01A, {
			["Target"]=target.id,
			["Target Index"]=target.index,
			["Category"]=0,
			["Param"]=0,
			["_unknown1"]=0
        })

        self:setState('awaiting_incoming_srune')
		packets.inject(packet)
        notice('Poked Starting Rune of Transfer')
    else
        notice('No Starting Rune of Transfer Found.')
    end
end
function NyzulController:callStartPortRoutine()
    local floors_rune = nil
    local targ = floors_rune or Observer:pickNearest(Observer:getMArray("Transfer",true))
    -- Do distance check here and fail if out of range.
    if Observer:distanceBetween(self.player.mob, targ) > 6 then
        return
    end

    notice('Injecting Start Port Up')
    self:injectStartPortUp()
    self:setState('awaiting_coordinator')
end
function NyzulController:injectStartPortUp()
    local base_port_up = packets.new('outgoing', 0x05B)
    base_port_up['Target'] = self.receivedPacket['NPC']
    base_port_up['Option Index'] = self.start_at_floor or 1
    base_port_up['_unknown1'] = 0
    base_port_up['Target Index'] = self.receivedPacket['NPC Index']
    base_port_up['Automated Message'] = false
    base_port_up['_unknown2'] = 0
    base_port_up['Zone'] = NyzulController._nyzulZone
    base_port_up['Menu ID'] = self.receivedPacket['Menu ID']
    packets.inject(base_port_up)

    self:resetAwaitedPacket()
    self:resetReceivedPacket()
end

function NyzulController:checkTheLamp()
    local target = nil
    target = Observer:pickNearest(Observer:getMarray("Lamp", true))

    -- Now check that our current floor lamp database has:
        -- This is not yet activated
        -- And we are beyond 10 seconds

    if Observer:distanceBetween(self.player.mob, target) > 6 then
        return
    end

    self:useTheLamp(target) -- Sends the Poke
end
function NyzulController:useTheLamp(target)
    self.awaitedPacket.active = true
    self.awaitedPacket['return'] = true

    if target and target.index and target.id then
        self.awaitedPacket.index = target.index
        local packet = packets.new('outgoing', 0x01A, {
			["Target"]=target.id,
			["Target Index"]=target.index,
			["Category"]=0,
			["Param"]=0,
			["_unknown1"]=0
        })
        self:setState('awaiting_incoming_lamp')
        packets.inject(packet)
        notice('Poked the Lamp')
    else
        notice('Malformed target information for Lamp passed.')
    end
end
function NyzulController:callLampRoutine()
    local target = nil

    local targ = Observer:pickNearest(Observer:getMArray("Lamp",true))
    -- Do distance check here and fail if out of range.
    if Observer:distanceBetween(self.player.mob, targ) > 6 then
        return
    end

    notice('Injecting Lamp Activation')
    self:injectLampActivation()
end
function NyzulController:injectLampActivation()
    local base_lamp_activation = packets.new('outgoing', 0x05B)
    base_lamp_activation['Target'] = self.receivedPacket['NPC']
    base_lamp_activation['Option Index'] = self.start_at_floor or 1
    base_lamp_activation['_unknown1'] = 0
    base_lamp_activation['Target Index'] = self.receivedPacket['NPC Index']
    base_lamp_activation['Automated Message'] = false
    base_lamp_activation['_unknown2'] = 0
    base_lamp_activation['Zone'] = NyzulController._nyzulZone
    base_lamp_activation['Menu ID'] = self.receivedPacket['Menu ID']
    packets.inject(base_lamp_activation)

    -- If the current floor is lamp - order, now we say that this has been activated in party chat.
    -- If this is lamp - simultaneous, we say that this has been activated
    -- If this is lamp - code, we state what index this is in in party chat.

    self:resetAwaitedPacket()
    self:resetReceivedPacket()
end

function NyzulController:determineNewLampOrder()
    local new_order = {}
    local off_lamp_indexes = {}

    for i,v in pairs(self.current_floor_lamp_order) do
        if self.current_floor_lamp_info[v] and self.current_floor_lamp_info[v].activated then
            if self.current_floor_lamp_info[v].activated == 0 then
                table.insert(off_lamp_indexes, i)
            end
        end
    end

    local temp = table.remove(off_lamp_indexes)
    table.insert(off_lamp_indexes, 1, temp)

    local off_index = 1
    for i,v in ipairs(self.current_floor_lamp_order) do
        local position = self.current_floor_lamp_info[self.current_floor_lamp_order[i]].activated
        if position and position == 1 then
            new_order[i] = self.current_floor_lamp_order[i]
        else
            local off_lamp = self.current_floor_lamp_order[off_lamp_indexes[off_index]]
            new_order[i] = off_lamp
            off_index = off_index + 1
        end
    end

    local stringified = table.concat(new_order, ' | ')
    self:addToPartyChat('lamp_order', 'new '..stringified)

    return true
end

------------------------
-- Injection Methods
------------------------
function NyzulController:requestAllLamps()
    for _,v in pairs(NyzulController._lampIndicies) do
        self:updateNpc(v)
    end
end
function NyzulController:requestAllRunes()
    for _,v in pairs(NyzulController._runeOfTransferIndicies) do
        self:updateNpc(v)
    end
end
function NyzulController:requestMapsDoors()
    if not NyzulController._optDoorIndicies[self.current_submap] then return end
    for _,v in pairs(NyzulController.__optDoorIndices[self.current_submap]) do
        self:updateNpc(v)
    end
end
function NyzulController:updateNpc(index)
    if (index and index > 0 and index < 2304) then
        local update_request = packets.new('outgoing', 0x016)
        update_request['Target Index'] = index
        packets.inject(update_request)
    end
end
function NyzulController:callSmiteRoutine(optional)
    local command_string = string.format(self.smite_command, optional or '')
    windower.send_command(command_string)
end

------------------------
-- Party Coordination
------------------------
function NyzulController:addToPartyChat(type, string)
    local build_string = '/p <'..type..'> '..string
    windower.chat.input(build_string)
end
function NyzulController:countPartyMembers()
    local party = windower.ffxi.get_party()
    self.party_count = party.party1_count
end

------------------------
-- Event Hooks
------------------------
function NyzulController:packetDelegate(id, data, modified, injected, blocked)
    if windower.ffxi.get_info().zone ~= NyzulController._nyzulZone then return end
    if id == 0x00E then
        local packet = packets.parse('incoming',data)
        self:updateE(packet)
    end
    if id == 0x02A then
        local packet = packets.parse('incoming', data)
        self:update2A(packet)
    end
    if id == 0x027 then
        local packet = packets.parse('incoming', data)
        self:update27(packet)
    end
    if id == 0x036 then
        local packet = packets.parse('incoming', data)
        self:update36(packet)
    end
end

function NyzulController:incomingChatDelegate(message, sender, mode, gm)
    if mode == 4 then
        local type, action, index = message:match("<(%a+)> (%a+) (%d+)")
        index = tonumber(index)
        if type == 'lamp' then
            if action == 'simulatenous' then
                self.current_floor_goal = 'Lamps - Simultaneous'
            end
            if action == 'code' then
                self.current_floor_goal = 'Lamps - Code'
            end
            if action == 'activating' then
                self.current_floor_goal = 'Lamps - Order'
                table.insert(self.current_floor_lamp_order, index)
            end
            if action == 'on' then
                self.current_floor_lamp_info[index]['activated'] = 1
            end
            if action == 'off' then
                self.current_floor_lamp_info[index]['activated'] = 0
            end
        end
        if type == 'lamp_order' then
            if action == 'new' then
                local requested_order = Utilities:stringExplode(index, '|')
                if next(requested_order) ~= nil then
                    self.current_floor_lamp_order_requested = os.clock()
                    self.current_floor_lamp_order = requested_order
                end
            end
        end
    end
end

------------------------
-- Packet Hooks
------------------------
function NyzulController:updateE(packet)
    local name = packet['Name']
    local index = packet['Index']
    if string.sub(name, 1, 1) == "_" then
        local door_mob = windower.ffxi.get_mob_by_index(index) or {}
        if not door_mob.x then
            return
        end
        self.found_doors[index] = {
            ['name'] = name,
            ['x'] = door_mob.x,
            ['y'] = door_mob.y,
            ['z'] = door_mob.z,
            ['status'] = door_mob['Status'],
            ['index'] = index,
            ['hex'] = string.format("%x",index),
            ['map'] = self.current_submap,
            ['map_index'] = self:locateNode(door_mob, self.current_submap)
        }
    end
    if NyzulController._runeOfTransferIndicies:contains(packet["Index"]) then
        local mob = windower.ffxi.get_mob_by_index(packet["Index"])
        local fence_index = 1
        for i,v in pairs(NyzulController._fences) do
            if v['submap_index'] == self.current_submap then
                fence_index = i
            end
        end
        local within_fence = self:withinFence(mob, fence_index)
        if mob and within_fence then
            self.rune_info[index]['mob'] = mob
            if packet["_unknown4"] > 0 then
                self.rune_info[index]["activated"] = bit.band(bit.rshift(packet["_unknown4"], 16), 0x01) > 0
            end
            self.rune_info[index]['current'] = true
        end
    elseif NyzulController._lampIndicies:contains(packet["Index"]) then
        local mob = windower.ffxi.get_mob_by_index(packet["Index"])
        local fence_index = 1
        for i,v in pairs(NyzulController._fences) do
            if v['submap_index'] == self.current_submap then
                fence_index = i
            end
        end
        local within_fence = self:withinFence(mob, fence_index)
        if mob and within_fence then
            self.current_floor_lamp_info[index]['mob'] = mob
            if packet["_unknown4"] > 0 then
                self.current_floor_lamp_info[index]["activated"] = bit.band(bit.rshift(packet["_unknown4"], 16), 0x01) > 0
            end
        end
    end
end
function NyzulController:update2A(packet)
    local messageId = bit.band(packet["Message ID"], 0x3FFF)
    if messageId then
        self:resetFloorDependents()

        -- I need to know what floor I'm on, so I can check if I've pushed the floor history
        -- if next(self.floor_summary_report[previous floor nav]) == nil then
        --      populate it with the floor history, then reset the floor navigation
        -- end

        notice('2A '..messageId) 
        -- 7493 x 2 (Welcome to floor?) ???
        -- 7491 (Obtained Tokens.) ???
        if messageId == 7301 then
            self.current_floor_goal = "When Dis?"
            print('a '..string.format("%s", message))
        elseif messageId == 7311 then
            -- self["TimeStr"] = string.format("%s", packet["Param 1"])
            -- self["RunStartTime"] = os.clock()
            print('b '..string.format("%s", packet["Param 1"]))
        elseif messageId == 7492 then
            -- self["FloorStr"] = string.format("%s", packet["Param 1"])
            -- self.current_floor_goal = string.format("%s", packet["Param 1"])
            -- print('c '..string.format("%s", message))
        elseif messageId == 7493 then
            -- This is the floor string not above?
            -- print('c '..string.format("%s", packet["Param 1"]))
            self.current_floor = string.format("%s", packet["Param 1"])
        elseif messageId == 7312 then
            self.current_floor_goal = "At Start"
        end
    end
end
function NyzulController:update36(packet)
    local messageId = bit.band(packet["Message ID"], 0x3FFF)
    if messageId then

        -- We've gotten a message stating the floor's objective, reset our information structures.
        self:checkFences()
        self:requestAllRunes()
        self:setFloorRune()
        if self.time_repo['nyzul_start'] == 0 then
            self.time_repo['nyzul_start'] = os.clock()
        end

        if self.role == 'scout' then
            self:setState('idle')
        end

        local f = dialog.open_dat_by_zone_id(NyzulController._nyzulZone, "english")
        local zoneDat = f:read("*a")
        f:close()
        local message = dialog.decode_string(dialog.get_entry(zoneDat, messageId))
        notice('36 '..messageId)
        -- 7370 x 2 (enemy leader) ???
        -- 7371 (Spec Enemies)
        -- 7374 (all enemies)
        -- 7373 (spec enemy)
        -- 7372 (Activate All Lamps) 
        -- 7360 (Certification Code)
        -- 7362 (Activated at same Time)
        -- 7382 (Weaponskill Restriction has Been Removed)
        -- 7383 (Weaponskill Resriction in place) ???
        if message:contains('all enemies') then
            self.current_floor_goal = 'All Enemies'
        end
        if message:contains('specified enemy') then
            self.current_floor_goal = 'Spec. Enemy'
        end
        if message:contains('specified enemies') then
            self.current_floor_goal = 'Spec. Enemies'
        end
        if message:contains('enemy leader') then
            self.current_floor_goal = 'Enemy Leader'
        end

        if message:contains("lamp") or message:contains("lamps") then
            if not self.current_floor_goal:lower():contains('lamps') then
                self.current_floor_goal = 'Lamps'
            end
            if message:contains("certification") then
                if self.current_floor_goal ~= 'Lamps - Code' then
                    self:addToPartyChat('lamp', 'code position_index_here')
                end
                self.current_floor_goal = 'Lamps - Code'
            end
            if message:contains("order") then
                self.current_floor_goal = 'Lamps - Order'
            end
            if message:contains("same time") then
                if self.current_floor_goal ~= 'Lamps - Simultaneous' then
                    self:addToPartyChat('lamp', 'simultaneous')
                end
                self.current_floor_goal = 'Lamps - Simultaneous'
            end
            self:requestAllLamps()
        end

        self.current_floor_goal_status = ''
        self.time_repo['goal_set'] = os.clock()
    end
end
function NyzulController:update27(packet)
    local messageId = bit.band(packet["Message ID"], 0x3FFF)
    notice('27 '..messageId)
    if messageId then
        if messageId == 7356 then -- (not this one)
            self.current_floor_goal_status = "Hng"
            self:requestAllRunes() --update the state to see if it's activated
        elseif messageId == 7357 then -- Objective Complete. Rune Activated
            self:requestAllRunes()
            self.current_floor_goal_status = "Complete" --?
            if self.role == 'coordinator' then
                self:setState('use_floor_rune')
            else
                self:setState('awaiting_coordinator')
            end
        elseif messageId == 7317 then -- Time remaining: x Minutes (earth time) not 7316
            local now = os.clock()
            local seconds_remain = packet["Param 1"] * 60
            local potential_start = NyzulController._timeLimit - seconds_remain
            self.time_repo['nyzul_start'] = now - potential_start
        elseif messageId == 7316 then
            self.current_floor_goal_status = 'Wat'
        end
    end
end

------------------------
-- Utility for sanity
------------------------
function NyzulController:report()
    notice('On Switch: '..self.on_switch)
    notice('AP: '..T(self.awaitedPacket):tovstring())
    notice('RP: '..T(self.receivedPacket):tovstring())
    notice('TR: '..T(self.time_repo):tovstring())
    notice('SE: '..T(self.current_floor_spec_enemies):tovstring())
end

------------------------
-- Pathfinding
------------------------
function NyzulController:explore()
    -- Working with current submap get valid neighborNodes and choose one that:
    -- hasn't 'been visited yet'?
    -- is weighted more towards the center of the map? (no? work outward in? does it matter?)

    local destination =  nil
    local player = self.player
    player:update()

    if not NyzulController._navTables[self.current_submap] then return notice('So... this aint a map.') end

    local determined_closest_node_index = self:locateNode(player.mob ,self.current_submap)
    local determined_closest_node_values = NyzulController._navTables[self.current_submap][determined_closest_node_index]
    local valid_neighbors = self:neighborNodes(determined_closest_node_values, self.current_submap)

    destination = self:pickRandomWalk(valid_neighbors, self.current_floor_navigation_history)
    if destination == nil then return false end

    return destination
end
function NyzulController:validNode(node, neighbor)
    if not node['c'] or not neighbor['c'] or node['c'] == 0 or neighbor['c'] == 0 then
        return false
    end
    if Observer:distanceBetween(node, neighbor) < 27 then
        return true
    end
    return false
end
function NyzulController:heuristicCostEstimate(node_a, node_b)
    return Observer:distanceBetween(node_a, node_b)
end
function NyzulController:lowestFScore(set, f_score)
	local lowest, bestNode = NyzulController._INF, nil
	for _, node in ipairs(set) do
		local score = f_score [ node ]
		if score < lowest then
			lowest, bestNode = score, node
		end
	end
	return bestNode
end
function NyzulController:neighborNodes(targetNode, map)
    local neighbors = {}
    for i,node in ipairs(map) do
        if targetNode ~= node and self:validNode(targetNode, node) then
            table.insert(neighbors, node)
        end
    end
    return neighbors
end
function NyzulController:notIn(map, targetNode)
	for _, node in ipairs(map) do
		if node == targetNode then return false end
	end
	return true
end
function NyzulController:removeNode(map, targetNode)
	for i, node in ipairs(map) do
		if node == targetNode then
			map[i] = map[#map]
			map[#map] = nil
			break
		end
	end
end
function NyzulController:unwindPath(flatPath, map, currentNode)
	if map[currentNode] then
		table.insert(flatPath, 1, map[currentNode])
		return self:unwindPath(flatPath, map, map[currentNode])
	else
		return flatPath
	end
end
function NyzulController:pickRandomWalk(valid_neighbors, visited)

    local unvisited_neighbors = {}
    for i,v in pairs(valid_neighbors) do
        -- If we've visited this
        if not visited:contains(v) then
            table.insert(unvisited_neighbors, v)
        end
    end

    if #unvisited_neighbors > 0 then
        return unvisited_neighbors[math.random(#unvisited_neighbors)]
    end

    -- If we're not at the first node of our navigation history, get new neighbors of the previous node, and pick a random one.
    if #visited > 1 then
        local previous_node = visited[#visited - 1]
        local previous_neighbors = self:neighborNodes(previous_node, self.current_submap)
        table.remove(visited, #visited)

        return self:pickRandomWalk(previous_neighbors, visited)
    else
        return false
    end
end
function NyzulController:addToFloorHistory()
end
function NyzulController:locateNode(target, map)
    if not target or not map then return nil end
    if not NyzulController._navTables[map] then return nil end

    for i,v in ipairs(NyzulController._navTables[map]) do
        if not target.x or not v.x then
            notice('oops '..tostring(target.x)..' '..tostring(v.x))
        end
        if Observer:distanceBetween(target, v) < 10 then
            return i
        end
    end
    return nil
end
function NyzulController:aStar(start, goal, map)
    local closedset = {}
	local openset = {start}
	local came_from = {}
	local g_score, f_score = {}, {}

	g_score[start] = 0
	f_score[start] = g_score[start] + self:heuristicCostEstimate(start, goal)

	while #openset > 0 do
		local current = self:lowestFScore(openset, f_score)
		if current == goal then
			local path = self:unwindPath({}, came_from, goal)
			table.insert(path, goal)
			return path
		end

		self:removeNode(openset, current)
		table.insert(closedset, current)

		local neighbors = self:neighborNodes(current, map)
		for _,neighbor in ipairs(neighbors) do
			if self:notIn(closedset, neighbor) then

				local tentative_g_score = g_score[current] + Observer:distanceBetween(current, neighbor)
				if self:notIn(openset, neighbor) or tentative_g_score < g_score[neighbor] then
					came_from[neighbor] = current
					g_score[neighbor] = tentative_g_score
					f_score[neighbor] = g_score[neighbor] + self:heuristicCostEstimate(neighbor, goal)
					if self:notIn(openset, neighbor) then
						table.insert(openset, neighbor)
					end
				end
			end
		end
	end
	return nil -- no valid path
end
function NyzulController:findPath(start, goal, nodes, ignoreCache)
	if not self.current_floor_cached_paths then  self.current_floor_cached_paths = {} end
	if not self.current_floor_cached_paths[start] then
        self.current_floor_cached_paths[start] = {}
	elseif  self.current_floor_cached_paths[start][goal] and not ignoreCache then
		return  self.current_floor_cached_paths[start][goal]
	end

    local resPath = NyzulController:aStar(start, goal, nodes)
    if not  self.current_floor_cached_paths[start][goal] and not ignoreCache then
        self.current_floor_cached_paths[start][goal] = resPath
    end

	return resPath
end
function NyzulController:reversePath()
end

return NyzulController