--[[
SDK References: 

CTempEnts::MuzzleFlash_Combine_NPC
--]]

EFFECT.WMMats = {}

EFFECT.StriderMuzzle = Material("effects/strider_muzzle")

for i = 1, 2 do
	EFFECT.WMMats[i] = Material("effects/combinemuzzle" .. i)
end

function EFFECT:Init(data)
	self.Ent = data:GetEntity()
	self.Attachment = data:GetAttachment()
	self.Scale = data:GetScale()

	self.Emitter = ParticleEmitter(Vector())
	self.Emitter:SetNoDraw(true)

	local forward = Vector(1, 0, 0)
	local scale = math.Rand(1, 1.5) * self.Scale
	local burst = math.Rand(50, 150)

	local length = 6

	local function createParticle(offset, dir)
		local p = self.Emitter:Add(table.Random(self.WMMats), offset)

		p:SetDieTime(0.1)

		p:SetVelocity(dir * burst)

		p:SetColor(255, 255, 255)

		p:SetStartAlpha(255)
		p:SetEndAlpha(0)

		p:SetRoll(math.random(0, 360))

		return p
	end

	-- Front flash
	for i = 1, length - 1 do
		local p = createParticle(forward * (i * 2 * scale), forward)
		local size = (math.Rand(6, 8) * (length * 1.25 - i) / length) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	-- Diagonal flashes
	local left = Vector(0, -1, -1)

	for i = 1, length - 1 do
		local p = createParticle(left * (i * scale), left * 0.25)
		local size = (math.Rand(2, 4) * (length - i) / (length * 0.5)) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	local right = Vector(0, 1, -1)

	for i = 1, length - 1 do
		local p = createParticle(right * (i * scale), right * 0.25)
		local size = (math.Rand(2, 4) * (length - i) / (length * 0.5)) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	local up = Vector(0, 0, 1)

	for i = 1, length - 1 do
		local p = createParticle(up * (i * scale), up * 0.25)
		local size = (math.Rand(2, 4) * (length - i) / (length * 0.5)) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	local p = self.Emitter:Add(self.StriderMuzzle, Vector())

	p:SetDieTime(math.Rand(0.3, 0.4))

	p:SetColor(255, 255, 255)

	p:SetStartAlpha(255)
	p:SetEndAlpha(0)

	p:SetStartSize(math.Rand(12, 16) * scale)
	p:SetEndSize(0)

	p:SetRoll(math.random(0, 360))

	if IsValid(self.Ent) then
		local light = DynamicLight(self.Ent:EntIndex(), true)

		light.pos = self.Ent:GetAttachment(self.Attachment).Pos

		light.r = 64
		light.g = 128
		light.b = 255
		light.brightness = 5

		local size = math.random(32, 128)

		light.size = size
		light.decay = size * 20
		light.dietime = CurTime() + 0.05
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