LOCAL_STEP_SIZE = 16
LOCAL_STEP_HEIGHT = 18
MOVE_HEIGHT_EPSILON = 0.0625

STATE_IDLE 		= 0
STATE_COMBAT 	= 1

AddCSLuaFile()

ENT.Type 					= "anim"

ENT.RenderGroup 			= RENDERGROUP_OPAQUE

ENT.AutomaticFrameAdvance 	= true

ENT.PrintName 				= "Combine Soldier"
ENT.Author 					= "TankNut"

ENT.Category 				= "Drivable"

ENT.Spawnable 				= true

ENT.PhysgunDisabled 		= true
ENT.m_tblToolsAllowed 		= {}

ENT.HullMin 				= Vector(-16, -16, 0)
ENT.HullMax 				= Vector(16, 16, 73)

ENT.Model 					= Model("models/Combine_Soldier.mdl")
ENT.GunClass 				= "drivable_gun_ar2"

ENT.Margin = 1.1

include("sh_animation.lua")
include("sh_move.lua")
include("sh_step.lua")

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetupPhysics(self.HullMin, self.HullMax)

	if SERVER then
		self:SetUseType(SIMPLE_USE)

		self:AddLayeredSequence(0, 0)
		self:AddLayeredSequence(0, 1)
		self:AddLayeredSequence(0, 2)

		self:SetLayerLooping(0, true)
		self:SetLayerLooping(1, true)

		local gun = ents.Create(self.GunClass)

		gun:SetPos(self:WorldSpaceCenter())

		gun:SetParent(self)
		gun:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES))

		gun:Spawn()
		gun:Activate()

		self:DeleteOnRemove(gun)
		self:SetGun(gun)
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Gun")

	self:NetworkVar("Vector", 0, "MoveSpeed")

	self:NetworkVar("Angle", 0, "ForcedAngle")
	self:NetworkVar("Angle", 1, "AimAngle")

	self:NetworkVar("Bool", 0, "Running")
	self:NetworkVar("Bool", 1, "ThirdPerson")

	self:NetworkVar("Float", 0, "LastState")
	self:NetworkVar("Float", 2, "GrenadeTimer")
	self:NetworkVar("Float", 3, "GrenadeStart")

	self:NetworkVar("Int", 0, "State")

	self:NetworkVar("String", 0, "HoldType")

	self:SetForcedAngle(Angle(0, 0, 180))
	self:SetThirdPerson(true)
	self:SetHoldType("ar2")
end

function ENT:SetupPhysics(mins, maxs)
	if IsValid(self.PhysCollide) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox(mins, maxs)
	self:SetCollisionBounds(mins, maxs)

	if CLIENT then
		self:SetRenderBounds(mins, maxs)
	else
		self:PhysicsInitBox(mins, maxs)
		self:SetMoveType(MOVETYPE_STEP)
		self:SetSolid(SOLID_BBOX)

		self:GetPhysicsObject():EnableMotion(false)
	end

	self:EnableCustomCollisions(true)
end

function ENT:Think()
	self:NextThink(CurTime())

	return true
end

function ENT:GetShootPos()
	return self:LocalToWorld(Vector(0, 0, 64))
end

function ENT:Attack()
	self:GetGun():DoFire()
end

function ENT:SecondaryAttack()
	self:SetGrenadeTimer(CurTime() + self:SequenceDuration(self:LookupActivity(ACT_GESTURE_RANGE_ATTACK2)))
	self:SetGrenadeStart(CurTime())
	self:SetCycle(0)
end

function ENT:TestCollision(start, delta, isbox, extends)
	if not IsValid(self.PhysCollide) then
		return
	end

	local max = extends
	local min = -extends

	max.z = max.z - min.z
	min.z = 0

	local hit, norm, frac = self.PhysCollide:TraceBox(self:GetPos(), angle_zero, start, start + delta, min, max)

	if not hit then
		return
	end

	return {
		HitPos = hit,
		Normal = norm,
		Fraction = frac
	}
end

if CLIENT then
	function ENT:Draw(studio)
		-- local scale = Vector(1, 1, 1)

		-- if LocalPlayer():GetViewEntity() == self and not self:GetThirdPerson() then
		-- 	scale = vector_origin
		-- end

		-- self:ManipulateBoneScale(self:LookupBone("ValveBiped.Bip01_Head1"), scale)

		self:SetupBones()
		self:DrawModel()
	end
else
	function ENT:Use(ply)
		drive.PlayerStartDriving(ply, self, "drive_entity")
	end

	local damage = GetConVar("sk_npc_dmg_fraggrenade")
	local radius = GetConVar("sk_fraggrenade_radius")

	function ENT:ThrowGrenade()
		local gravity = -physenv.GetGravity().z

		local vel = util.TraceLine({
			start = self:GetShootPos(),
			endpos = self:GetShootPos() + self:GetAimAngle():Forward() * 1024,
			filter = {self, self:GetGun()}
		}).HitPos - self:GetShootPos()

		local time = vel:Length() / 650

		vel = vel * (1 / time)
		vel.z = vel.z + gravity * time * 0.5

		local spin = VectorRand(-1000, 1000)

		local ent = ents.Create("npc_grenade_frag")

		ent:SetSaveValue("m_flDamage", damage:GetFloat())
		ent:SetSaveValue("m_DmgRadius", radius:GetFloat())

		ent:SetSaveValue("m_combineSpawned", true)

		ent:SetSaveValue("m_hThrower", self.Player or self)

		local index = self:LookupAttachment("lefthand")
		local att = self:GetAttachment(index)

		ent:SetPos(att.Pos)
		ent:SetAngles(att.Ang)

		ent:SetOwner(self)

		ent:Spawn()
		ent:Activate()

		ent:Fire("SetTimer", 3.5)

		local phys = ent:GetPhysicsObject()

		phys:SetVelocity(vel)
		phys:AddAngleVelocity(spin)
	end

	function ENT:HandleAnimEvent(event)
		if event == 7 then
			self:ThrowGrenade()
		end
	end
end

drive.Register("drive_entity", {
	StartMove = function(self, mv, cmd)
		if self.Entity:StartMove(self.Player, mv, cmd) then
			self.Aborted = true
			self:Stop()
		end
	end,
	Move = function(self, mv)
		self.Entity:Move(mv)
	end,
	FinishMove = function(self, mv)
		self.Entity:FinishMove(mv)

		if self.StopDriving then
			self.Entity:StopDriving(self.Player)
		end
	end,
	CalcView = function(self, view)
		self.Entity:CalcView(self.Player, view)
	end
}, "drive_base")

if CLIENT then
	hook.Add("PreDrawHUD", "drivable", function()
		local ent = LocalPlayer():GetDrivingEntity()
		local mode = util.NetworkIDToString(LocalPlayer():GetDrivingMode())

		if not IsValid(ent) or mode != "drive_entity" then
			return
		end

		local state = ent:GetState()

		if state == STATE_COMBAT then
			local tr = util.TraceLine({
				start = ent:GetShootPos(),
				endpos = ent:GetShootPos() + ent:GetAimAngle():Forward() * 32768,
				filter = {ent, ent:GetGun()}
			})

			local screen = tr.HitPos:ToScreen()

			cam.Start2D()
				surface.SetDrawColor(255, 0, 0)
				surface.DrawLine(screen.x - 5, screen.y, screen.x + 5, screen.y)
				surface.DrawLine(screen.x, screen.y - 5, screen.x, screen.y + 5)
			cam.End2D()
		end
	end)
end