AddCSLuaFile()

ENT.Type 				= "anim"

ENT.Author 				= "TankNut"

ENT.PhysgunDisabled 	= true
ENT.m_tblToolsAllowed 	= {}

ENT.Model 				= Model("models/weapons/w_irifle.mdl")

ENT.HoldType 			= "ar2"

ENT.FireRate 			= 60 / 600
ENT.Spread 				= 3

function ENT:Initialize()
	self:SetModel(self.Model)

	local parent = self:GetParent()

	parent:SetupHoldType(self.HoldType)
	parent:UpdateAnimation()
end

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "LastFire")
end

function ENT:DoFire()
	if CurTime() - self:GetLastFire() < self.FireRate then
		return
	end

	self:SetLastFire(CurTime())

	local ed = EffectData()

	ed:SetEntity(self)
	ed:SetOrigin(self:WorldSpaceCenter())
	ed:SetAttachment(1)
	ed:SetScale(1)

	util.Effect("drivable_muzzleflash_ar2", ed)

	self:EmitSound("Weapon_AR2.Single")

	local spread = math.rad(self.Spread * 0.5)
	local parent = self:GetParent()

	self:FireBullets({
		Attacker = parent.Player,
		Damage = 8,
		TracerName = "AR2Tracer",
		Dir = parent:GetAimAngle():Forward(),
		Spread = Vector(spread, spread, spread),
		Src = parent:GetShootPos(),
		IgnoreEntity = parent,
		Callback = function(attacker, tr, dmg)
			dmg:SetInflictor(parent)

			local effectdata = EffectData()

			effectdata:SetOrigin(tr.HitPos + tr.HitNormal)
			effectdata:SetNormal(tr.HitNormal)

			util.Effect("AR2Impact", effectdata)
		end
	})

	parent:SetLayerCycle(2, 0)
end