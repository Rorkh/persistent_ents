util.AddNetworkString("PEnts/Sync")

pents = pents or {
    verbose = true,

    persistent = {},
    persistent_var_keys = {},

    vars = {},

    sql_pool = {},
    local_net_pool = {},

    player_last_global_pool_index = {},
    global_net_pool = {},

    net_sync_delay = 0.2
}

function pents.spawn_persistent_ents()
    local _ents = sql.Query("SELECT * FROM persistent_ents")

    if not _ents then return end
    
    local persistent_ids = {}
    local persistent_reversed = {}

    for _, remote_ent in ipairs(_ents) do
        local ent = ents.Create(remote_ent["class"])
        ent:SetModel(remote_ent["model"])
        ent:SetPos(Vector(remote_ent["x"], remote_ent["y"], remote_ent["z"]))
        ent:Spawn()

        local persistent_id = remote_ent["id"]
        table.insert(persistent_ids, persistent_id)
        
        persistent_reversed[persistent_id] = ent:EntIndex()
        pents.persistent[ent:EntIndex()] = persistent_id
    end

    if pents.verbose then
        print("PEnts: Spawned " .. #_ents .. " ents")
    end

    local persistent_vars = sql.Query(
        string.format("SELECT * FROM persistent_ents_vars WHERE entity_id IN (%s)", table.concat(persistent_ids, ", "))
    )
    if not persistent_vars then return end

    for _, v in ipairs(persistent_vars) do
        local ent_index = persistent_reversed[v["entity_id"]]
        
        if not pents.persistent_var_keys[v["entity_id"]] then
            pents.persistent_var_keys[v["entity_id"]] = {}
        end

        table.insert(pents.persistent_var_keys[v["entity_id"]], v.key)
        
        if not pents.vars[ent_index] then
            pents.vars[ent_index] = {}
        end

        pents.vars[ent_index][v.key] = {
            ['value'] = v.value,
            ['type'] = v["type"]
        }

        pents.insert_net_history(ent_index, v.type, v.key, v.value)

        if pents.verbose then
            print("PEnts: Assigned variable " .. v.key .. " with value " .. v.value .. " for " .. ent_index)
        end
    end
end

local function replace_var_queue_value(key, value)
    for k, v in ipairs(pents.sql_pool) do
        if v["key"] == key then
            pents.sql_pool[k].value = value
        end
    end
end

function pents.find_local_pool_duplicate(ent_index, _type, key, value)
    for k, v in ipairs(pents.global_net_pool) do
        if v['type'] == _type and v['ent_index'] == ent_index and v['key'] == key then
            if v['value'] == value then return end
            return k
        end
    end
end

function pents.insert_net_history(ent_index, _type, key, value)
    table.insert(pents.global_net_pool, {
        ['ent_index'] = ent_index,
        ['type'] = _type,
        ['key'] = key,
        ['value'] = value,
    })
end

function pents.insert_local_pool_message(player_index, ent_index, _type, key, value)
    if not pents.local_net_pool[player_index][ent_index] then
        pents.local_net_pool[player_index][ent_index] = {}
    end

    pents.local_net_pool[player_index][ent_index][key] = {
        ['value'] = value,
        ['type'] = _type
    }
end

function pents.insert_var(ent, _type, key, value)
    local persistent_id = ent:GetPersistentIndex()
    if not persistent_id then return end

    local ent_index = ent:EntIndex()

    if not pents.vars[ent_index] then
        pents.vars[ent_index] = {}
    end

    pents.vars[ent_index][key] = {
        ['value'] = value,
        ['type'] = _type
    }

    -- local duplicate = pents.find_local_pool_duplicate(ent_index, _type, key, value)

    -- if duplicate then
    --    pents.insert_local_pool_message()
    --    return
    --end


    pents.insert_net_history(ent_index, _type, key, value)

    for k, v in ipairs(pents.sql_pool) do
        if v['type'] == _type and v['id'] == persistent_id and v['key'] == key then
            if v['value'] == value then return end
            replace_var_queue_value(v['key'], value)
            return
        end
    end

    table.insert(pents.sql_pool, {
        ["id"] = persistent_id,
        ["type"] = _type,
        ["key"] = key,
        ["value"] = value
    })
end

function pents.flush_sql_queue()
    local sql_insert_values = {}

    for _, v in ipairs(pents.sql_pool) do
        local exists = false

        if pents.persistent_var_keys[v.id] then
            for _, key in ipairs(pents.persistent_var_keys[v.id]) do
                if key == v.key then
                    exists = true
                    break
                end
            end
        end

        if exists then
            sql.Query(
                string.format('UPDATE persistent_ents_vars SET value = "%s" WHERE entity_id = "%s" AND key = "%s"', v.value, v.id, v.key)
            )
            continue 
        end
        table.insert(sql_insert_values, string.format('(%s, "%s", "%s", "%s")', v.id, v["type"], v.key, v.value))
    end

    if next(sql_insert_values) then
        sql.Query(
            string.format("INSERT INTO persistent_ents_vars (entity_id, type, key, value) VALUES %s", table.concat(sql_insert_values, ", "))
        )
    end

    pents.sql_pool = {}
end

local function transform_from_global_to_local_pool_format(pool)
    local local_pool = {}

    for _, elem in ipairs(pool) do
        if not local_pool[elem.ent_index] then
            local_pool[elem.ent_index] = {}
        end

        if not local_pool[elem.ent_index][elem.key] then
            local_pool[elem.ent_index][elem.key] = {['type'] = elem['type'], ['value'] = elem.value}
        end
    end

    return local_pool
end

local function slice(arr, startIndex, endIndex)
    local slice = {}

    for i = startIndex, endIndex do
        table.insert(slice, arr[i])    
    end

    return slice
end

function pents.sync_player_with_history(player)
    local player_index = player:EntIndex()
    local player_last_global_pool_index = pents.player_last_global_pool_index[player_index]

    if player_last_global_pool_index == #pents.global_net_pool then return end

    local actual_history_slice = transform_from_global_to_local_pool_format(
        slice(pents.global_net_pool, player_last_global_pool_index + 1, #pents.global_net_pool),
        player_index
    )

    pents.player_last_global_pool_index[player_index] = #pents.global_net_pool
    pents.local_net_pool[player_index] = actual_history_slice
end

function pents.sync_player(ply)
    local player_index = ply:EntIndex()

    local format = ""
    local keys = {}

    for ent_index, vars in pairs(pents.local_net_pool[player_index]) do
        net.Start("PEnts/Sync")
        
        for k, v in pairs(vars) do
            format = format .. v['type']
            table.insert(keys, k)
        end

        net.WriteString(format)
        net.WriteString(table.concat(keys, ';'))

        net.WriteInt(ent_index, 13)

        for k, v in pairs(vars) do
            if v['type'] == 's' then
                net.WriteString(v['value'])
            elseif v['type'] == 'i' then
                net.WriteInt(v['value'], 32)
            end
        end

        net.Send(ply)
    end

    pents.local_net_pool[player_index] = {}
end

function pents.sync()
    for _, ply in ipairs(player.GetAll()) do
        pents.sync_player_with_history(ply)
        pents.sync_player(ply)
    end
end