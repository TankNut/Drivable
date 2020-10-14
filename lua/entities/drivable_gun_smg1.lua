AddCSLuaFile()

DEFINE_BASECLASS("drivable_gun_ar2")

ENT.Base 				= "drivable_gun_ar2"
ENT.Author 				= "TankNut"

ENT.Model 				= Model("models/weapons/w_smg1.mdl")

ENT.HoldType 			= "smg1"

ENT.FireRate 			= 60 / 800
ENT.Spread 				= 5

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

	util.Effect("drivable_muzzleflash_smg", ed)

	self:EmitSound("Weapon_SMG1.NPC_Single")

	local spread = self:GetSpread()
	local parent = self:GetParent()

	self:FireBullets({
		Attacker = parent.Player,
		Damage = 4,
		TracerName = "Tracer",
		Dir = parent:GetAimAngle():Forward(),
		Spread = Vector(spread, spread, spread),
		Src = parent:GetShootPos(),
		IgnoreEntity = parent
	})

	parent:SetLayerCycle(2, 0)
end