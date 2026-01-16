local ENTITY = FindMetaTable("Entity")

function ENTITY:GetPersistentVar(key)
    local ent_vars = pents.vars[self:EntIndex()]
    if not ent_vars then return end
    return ent_vars[key]
end