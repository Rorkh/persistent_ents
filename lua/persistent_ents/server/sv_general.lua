hook.Add("InitPostEntity", "PEnts/InitPostEntity", function()
    sql.Query("CREATE TABLE IF NOT EXISTS persistent_ents (id integer primary key, class text, model text, x integer, y integer, z integer)")
    sql.Query("CREATE TABLE IF NOT EXISTS persistent_ents_vars (id integer primary key, entity_id integer, type text, key text, value text)")

    pents.spawn_persistent_ents()
end)

hook.Add("ShutDown", "PEnts/ShutDown", function()
    pents.flush_sql_queue()
end)

hook.Add("PlayerInitialSpawn", "PEnts/PlayerInitialSpawnn", function(ply)
    local player_index = ply:EntIndex()

    pents.local_net_pool[player_index] = {}
    pents.player_last_global_pool_index[player_index] = 0

    ply:Sync()
end)

timer.Create("PEnts/Sync", pents.net_sync_delay, 0, function()
    pents.sync()
end)