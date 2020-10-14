--[[
SDK References: 

FX_MuzzleEffectAttached
--]]

EFFECT.WMMats = {}

for i = 1, 4 do
	EFFECT.WMMats[i] = Material("effects/muzzleflash" .. i)
end

function EFFECT:Init(data)
	self.Ent = data:GetEntity()
	self.Attachment = data:GetAttachment()
	self.Scale = data:GetScale()

	self.Emitter = ParticleEmitter(Vector())
	self.Emitter:SetNoDraw(true)

	local forward = Vector(1, 0, 0)
	local scale = math.Rand(self.Scale - 0.25, self.Scale + 0.25)

	for i = 1, 9 do
		local offset = forward * (i * 2 * scale)
		local p = self.Emitter:Add(table.Random(self.WMMats), offset)

		p:SetDieTime(0.025)

		p:SetStartAlpha(255)
		p:SetEndAlpha(128)

		local size = (math.Rand(6, 9) * (12 - i) / 9) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)

		p:SetRoll(math.random(0, 360))
	end

	if IsValid(self.Ent) then
		local light = DynamicLight(self.Ent:EntIndex(), true)

		light.pos = self.Ent:GetAttachment(self.Attachment).Pos

		light.r = 255
		light.g = 192
		light.b = 64
		light.brightness = 5

		local size = math.random(64, 128)

		light.size = size
		light.decay = size * 20
		light.dietime = CurTime() + 0.1
	end
end

function EFFECT:GetStartPos(ent)
	local att = self.Ent:GetAttachment(self.Attachment)

	return att.Pos, att.Ang
end

function EFFECT:Think()
	if not IsValid(self.Ent) or self.Emitter:GetNumActiveParticles() == 0 then
		self.Emitter:Finish()

		return false
	end

	return true
end

function EFFECT:Render()
	local pos, ang = self:GetStartPos(self.Ent)

	if IsValid(self.Emitter) then
		cam.Start3D(WorldToLocal(EyePos(), EyeAngles(), pos, ang))
			self.Emitter:Draw()
		cam.End3D()
	end
end