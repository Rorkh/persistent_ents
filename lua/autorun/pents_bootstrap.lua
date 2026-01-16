if SERVER then
    include("persistent_ents/server/sv_utils.lua")

    include("persistent_ents/server/sv_meta.lua")
    include("persistent_ents/server/sv_lib.lua")

    include("persistent_ents/server/sv_general.lua")

    AddCSLuaFile("persistent_ents/client/cl_pents.lua")
    AddCSLuaFile("persistent_ents/shared/sh_meta.lua")
else
    include("persistent_ents/client/cl_pents.lua")
end

include("persistent_ents/shared/sh_meta.lua")