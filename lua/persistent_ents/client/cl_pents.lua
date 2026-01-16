pents = pents or {vars = {}}

net.Receive("PEnts/Sync", function()
    local format = net.ReadString()
    local raw_keys = net.ReadString()

    local index = net.ReadUInt(13)

    local keys = string.Split(raw_keys, ";")
    local values = {}

    for i = 1, #format do
        local char = string.sub(format, i, i)
        local value = nil

        if char == "s" then
            value = net.ReadString()
        elseif char == "i" then
            value = net.ReadInt(32)
        end

        table.insert(values, value)
    end

    for i = 1, #values do
        if not pents.vars[index] then
            pents.vars[index] = {}
        end

        pents.vars[index][keys[i]] = values[i]
    end
end)

concommand.Add("make_persistent_debug_client", function(ply)
    PrintTable(pents)
end)
