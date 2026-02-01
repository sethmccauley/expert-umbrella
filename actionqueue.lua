local ActionQueue = {}
ActionQueue.__index = ActionQueue

function ActionQueue:constructActionQueue()
    local self = setmetatable({}, ActionQueue)

    -- The queue stores action entries, sorted by priority then added_at
    self.entries = {}
    self.entry_count = 0

    -- Track last sent ability to prevent spam
    self.last_sent_ability = nil
    self.last_sent_time = 0
    self.last_prefix_used = nil

    return self
end

--------------------------------------------------------------------------------
-- Action Entry Structure
--------------------------------------------------------------------------------

--[[
    Each action in the queue has:
        name: string - ability/spell/item name
        prefix: string - command prefix (/ma, /ja, /ws, etc.)
        targeting: number - resolved target ID (always an ID, never a wildcard)
        res: table - resolved ability resource data
        priority: number - user-defined priority (lower = executes first)
        added_at: number - os.clock() timestamp when queued
        source: string - where this came from ('combat', 'noncombat', 'adhoc', etc.)
        is_chain: boolean - whether this action is part of a chain
        chain_id: number - if is_chain, identifies which chain this belongs to
        checks: table - what validation to perform before execution
            - recast: boolean - check if ability is ready
            - conditions: boolean - re-test conditions before use
            - range: boolean - verify target is in range
        (target validity is always checked - not optional)
]]

--------------------------------------------------------------------------------
-- Sorting Helpers
--------------------------------------------------------------------------------

-- Compare two actions for sort order
-- Returns true if a should come before b
function ActionQueue:compareActions(a, b)
    if a.priority ~= b.priority then
        return a.priority < b.priority
    end
    return a.added_at < b.added_at
end

-- Binary search to find insertion index for a new action
-- Returns the index where the action should be inserted to maintain sort order
function ActionQueue:findInsertIndex(action)
    if self.entry_count == 0 then return 1 end

    local low, high = 1, self.entry_count
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if self:compareActions(action, self.entries[mid]) then
            high = mid - 1
        else
            low = mid + 1
        end
    end
    return low
end

-- Insert action at the correct sorted position (O(log n) search + O(n) insert)
function ActionQueue:insertSorted(action)
    local index = self:findInsertIndex(action)
    table.insert(self.entries, index, action)
    self.entry_count = self.entry_count + 1
end

--------------------------------------------------------------------------------
-- Adding Actions
--------------------------------------------------------------------------------

-- Add a single action to the queue
-- action must have: name, targeting (resolved ID)
-- action may have: priority, checks, source
function ActionQueue:add(action, source)
    if not action or not action.name then return false end

    -- Duplicate check: same name + same target ID (skip if checks.duplicate == false)
    local should_check_duplicate = not action.checks or action.checks.duplicate ~= false
    if should_check_duplicate and self:isDuplicate(action) then
        return false
    end

    -- Ensure required fields
    action.added_at = os.clock()
    action.source = source or action.source or 'unknown'
    action.priority = action.priority or 10
    action.is_chain = false
    action.checks = action.checks or {
        recast = true,
        conditions = true,
        range = true,
    }

    self:insertSorted(action)
    return true
end

-- Add a chain of actions as an atomic group
-- All actions share the same chain_id and stay together in execution order
function ActionQueue:addChain(actions, source)
    if not actions or #actions == 0 then return false end

    -- Check if first action is duplicate
    if self:isDuplicate(actions[1]) then
        return false
    end

    local chain_id = os.clock()
    local chain_priority = actions[1].priority or 10
    local base_time = os.clock()

    for i, action in ipairs(actions) do
        action.added_at = base_time + (i * 0.0001) -- slight offset to preserve order
        action.source = source or action.source or 'unknown'
        action.priority = chain_priority
        action.is_chain = true
        action.chain_id = chain_id
        action.chain_index = i
        action.checks = action.checks or {
            recast = false,
            conditions = true,
            range = true,
        }
        self:insertSorted(action)
    end

    return true
end

--------------------------------------------------------------------------------
-- Retrieving Actions
--------------------------------------------------------------------------------

-- Get the next action to process (does not remove it)
function ActionQueue:peek()
    if self.entry_count == 0 then return nil end
    return self.entries[1]
end

-- Remove and return the front action
function ActionQueue:pop()
    if self.entry_count == 0 then return nil end
    self.entry_count = self.entry_count - 1
    return table.remove(self.entries, 1)
end

-- Remove action at specific index
function ActionQueue:removeAt(index)
    if index < 1 or index > self.entry_count then return nil end
    self.entry_count = self.entry_count - 1
    return table.remove(self.entries, index)
end

-- Remove an action by reference (finds and removes it)
function ActionQueue:removeAction(action)
    for i = 1, self.entry_count do
        if self.entries[i] == action then
            self.entry_count = self.entry_count - 1
            return table.remove(self.entries, i)
        end
    end
    return nil
end

-- Remove all actions belonging to a chain
function ActionQueue:removeChain(chain_id)
    if not chain_id then return 0 end
    local removed = 0
    local i = 1
    while i <= self.entry_count do
        if self.entries[i].chain_id == chain_id then
            table.remove(self.entries, i)
            self.entry_count = self.entry_count - 1
            removed = removed + 1
        else
            i = i + 1
        end
    end
    return removed
end

-- Remove first action matching a resource ID (used by action notification handler)
function ActionQueue:removeByResId(res_id)
    if not res_id then return nil end
    for i = 1, self.entry_count do
        local entry = self.entries[i]
        if entry.res and entry.res.id == res_id then
            self.entry_count = self.entry_count - 1
            return table.remove(self.entries, i)
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Queue Queries
--------------------------------------------------------------------------------

function ActionQueue:isEmpty()
    return self.entry_count == 0
end

function ActionQueue:count()
    return self.entry_count
end

-- Check if an action with the same name and target ID already exists
function ActionQueue:isDuplicate(action)
    if not action or not action.name then return false end

    for i = 1, self.entry_count do
        local entry = self.entries[i]
        if entry.name == action.name and entry.targeting == action.targeting then
            return true
        end
    end
    return false
end

-- Check if queue contains an action by name (any target)
function ActionQueue:contains(name)
    if not name then return false end

    local name_lower = name:lower()
    for i = 1, self.entry_count do
        local entry = self.entries[i]
        if entry.name and entry.name:lower() == name_lower then
            return true
        end
    end
    return false
end

-- Get all actions for a specific target ID
function ActionQueue:getByTarget(target_id)
    local matches = {}
    local match_count = 0
    for i = 1, self.entry_count do
        if self.entries[i].targeting == target_id then
            match_count = match_count + 1
            matches[match_count] = self.entries[i]
        end
    end
    return matches
end

-- Get all actions in a chain (already sorted by chain_index due to insert order)
function ActionQueue:getChain(chain_id)
    if not chain_id then return {} end
    local chain = {}
    local chain_count = 0
    for i = 1, self.entry_count do
        if self.entries[i].chain_id == chain_id then
            chain_count = chain_count + 1
            chain[chain_count] = self.entries[i]
        end
    end
    return chain
end

--------------------------------------------------------------------------------
-- Queue Maintenance
--------------------------------------------------------------------------------

-- Clear all entries
function ActionQueue:clear()
    self.entries = {}
    self.entry_count = 0
    self.last_sent_ability = nil
    self.last_sent_time = 0
end

-- Remove entries older than max_age seconds
function ActionQueue:pruneStale(max_age)
    local now = os.clock()
    local i = 1
    while i <= self.entry_count do
        if now - self.entries[i].added_at > max_age then
            table.remove(self.entries, i)
            self.entry_count = self.entry_count - 1
        else
            i = i + 1
        end
    end
end

-- Remove all entries from a specific source
function ActionQueue:clearSource(source)
    local i = 1
    while i <= self.entry_count do
        if self.entries[i].source == source then
            table.remove(self.entries, i)
            self.entry_count = self.entry_count - 1
        else
            i = i + 1
        end
    end
end

--------------------------------------------------------------------------------
-- Spam Prevention
--------------------------------------------------------------------------------

-- Check if enough time has passed since last send
function ActionQueue:canSend(ability_name, min_interval)
    min_interval = min_interval or 1
    if self.last_sent_ability == ability_name then
        if (os.clock() - self.last_sent_time) < min_interval then
            return false
        end
    end
    return true
end

-- Record that an ability was sent
function ActionQueue:markSent(ability_name)
    self.last_sent_ability = ability_name
    self.last_sent_time = os.clock()
end

-- Record the last prefix used (for JA chaining logic)
function ActionQueue:setLastPrefixUsed(prefix)
    self.last_prefix_used = prefix
end

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------

function ActionQueue:getDebugInfo()
    local info = {
        count = self.entry_count,
        entries = {}
    }

    for i = 1, self.entry_count do
        local entry = self.entries[i]
        info.entries[i] = {
            name = entry.name,
            prefix = entry.prefix,
            targeting = entry.targeting,
            priority = entry.priority,
            age = os.clock() - entry.added_at,
            source = entry.source,
            is_chain = entry.is_chain,
            chain_id = entry.chain_id,
        }
    end

    return info
end

return ActionQueue
