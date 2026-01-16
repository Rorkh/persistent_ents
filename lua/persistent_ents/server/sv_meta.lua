local ENTITY = FindMetaTable("Entity")

function ENTITY:MakePersistent()
    local pos = self:GetPos()

    local class = self:GetClass()
    local model = self:GetModel()

    sql.Query(
        string.format("INSERT INTO persistent_ents (class, model, x, y, z) VALUES (\"%s\", \"%s\", %f, %f, %f)", class, model, pos.x, pos.y, pos.z)
    )
    pents.persistent[self:EntIndex()] = sql.QueryValue("SELECT last_insert_rowid()")
end

function ENTITY:GetPersistentIndex()
    local ent_index = self:EntIndex()
    return pents.persistent[ent_index]
end

function ENTITY:SetPersistentString(key, value)
    pents.insert_var(self, "s", key, value)
end

function ENTITY:SetPersistentInt(key, value)
    pents.insert_var(self, "i", key, value)
end

local PLAYER = FindMetaTable("Player")

function PLAYER:Sync(force)
    pents.sync_player_with_history(self)
    if force then
        pents.sync_player(self)
    end
end