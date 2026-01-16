AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local last_use = 0

-- Server-side initialization function for the Entity
function ENT:Initialize()
    self:SetModel( "models/props_junk/cardboard_box001a.mdl" ) -- Sets the model for the Entity.
    self:PhysicsInit( SOLID_VPHYSICS ) -- Initializes physics for the Entity, making it solid and interactable.
    self:SetMoveType( MOVETYPE_VPHYSICS ) -- Sets how the Entity moves, using physics.
    self:SetSolid( SOLID_VPHYSICS ) -- Makes the Entity solid, allowing for collisions.
    local phys = self:GetPhysicsObject() -- Retrieves the physics object of the Entity.
    if phys:IsValid() then -- Checks if the physics object is valid.
        phys:Wake() -- Activates the physics object, making the Entity subject to physics (gravity, collisions, etc.).
    end
end

function ENT:Use(activator)
    if last_use + 1 > os.time() then return end

	self:SetPersistentString("Name", activator:Nick())
	self:SetPersistentInt("Time", os.time())

    last_use = os.time()
end
