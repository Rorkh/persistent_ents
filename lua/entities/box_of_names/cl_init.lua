include("shared.lua")

surface.CreateFont("BoxFont", {
	font = "Trebuchet",
	size = 72,
})

-- Client-side draw function for the Entity
function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + self:GetUp() * 40
	local angle = Angle(0, 180, 0)

	angle:RotateAroundAxis(angle:Up(), -90)
	angle:RotateAroundAxis(angle:Forward(), 90)

	local resolution = 1.1

	local name = self:GetPersistentVar("Name")
	local time = self:GetPersistentVar("Time")

	cam.Start3D2D(pos, angle, 0.05 / resolution)
		draw.SimpleText("Box of names", "BoxFont", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if (name) then
			draw.SimpleText(name, "BoxFont", 0, 140, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		if (time) then
			draw.SimpleText(time, "BoxFont", 0, 280, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end
