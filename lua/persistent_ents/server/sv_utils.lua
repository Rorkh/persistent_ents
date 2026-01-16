concommand.Add("make_persistent", function(ply)
    ply:GetEyeTrace().Entity:MakePersistent()
end)

concommand.Add("make_persistent_debug", function(ply)
    PrintTable(pents)
end)

concommand.Add("make_persistent_test_flush_sql", function(ply)
    pents.flush_sql_queue()
end)

concommand.Add("make_persistent_test_flush_net", function(ply)
    pents.flush_net_queue()
end)

concommand.Add("make_persistent_sync", function()
    pents.sync()
end)