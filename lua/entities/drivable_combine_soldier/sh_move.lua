AddCSLuaFile()

function ENT:HasMoveInput(mv)
	if self:GetGrenadeTimer() >= CurTime() then
		return false
	end

	return mv:GetForwardSpeed() != 0 or mv:GetSideSpeed() != 0
end

function ENT:GetSpeeds()
	if self:GetState() == STATE_COMBAT then
		return self:GetSequenceGroundSpeed(self:LookupActivity(ACT_WALK_AIM)), self:GetSequenceGroundSpeed(self:LookupActivity(ACT_RUN_AIM))
	else
		return self:GetSequenceGroundSpeed(self:LookupActivity(ACT_WALK)), self:GetSequenceGroundSpeed(self:LookupActivity(ACT_RUN))
	end
end

function ENT:GetSpeedData(mv)
	local length = mv:GetVelocity():Length()

	local walk, run = self:GetSpeeds()

	local speed = 0
	local accel = 0

	if self:HasMoveInput(mv) then
		speed = mv:KeyDown(IN_SPEED) and run or walk
		accel = mv:KeyDown(IN_SPEED) and run or (length > walk * self.Margin and run or walk)
	else
		speed = 0
		accel = self:GetRunning() and run or walk
	end

	return speed, accel + 50
end

function ENT:StartMove(ply, mv, cmd)
	ply:SetObserverMode(OBS_MODE_CHASE)

	mv:SetOrigin(self:GetNetworkOrigin())
	mv:SetVelocity(self:GetMoveSpeed())

	return mv:KeyPressed(IN_USE)
end

function ENT:Move(mv)
	local ang = mv:GetMoveAngles()
	local pos = mv:GetOrigin()

	if mv:KeyDown(IN_WALK) then
		local forced = self:GetForcedAngle()

		forced = forced.r != 180 and forced or ang

		self:SetForcedAngle(forced)

		ang = forced
	else
		self:SetForcedAngle(Angle(0, 0, 180))
	end

	self:SetAimAngle(ang)

	if self:GetState() == STATE_COMBAT then
		if mv:KeyDown(IN_ATTACK) then
			self:Attack()
		end

		if mv:KeyPressed(IN_ATTACK2) and self:GetGrenadeTimer() < CurTime() then
			self:SecondaryAttack()
		end
	end

	if mv:KeyPressed(IN_RELOAD) then
		local state = self:GetState()

		if state == STATE_IDLE then
			self:SetState(STATE_COMBAT)
		else
			self:SetState(STATE_IDLE)
		end

		self:SetLastState(CurTime())
	end

	if mv:KeyPressed(IN_DUCK) then
		self:SetThirdPerson(not self:GetThirdPerson())
	end

	mv:SetMoveAngles(ang)

	local vel = mv:GetVelocity()
	local speed, accel = self:GetSpeedData(mv)

	if accel > 0 then
		local dir = Angle(ang)

		dir.p = 0

		local target = Vector(mv:GetForwardSpeed(), -mv:GetSideSpeed(), 0):GetNormalized()

		target:Rotate(dir)
		target:Mul(speed)

		vel:Approach(target, accel * FrameTime())
	end

	mv:SetOrigin(self:TestGroundMove(pos, vel:GetNormalized(), vel:Length() * FrameTime()))
	mv:SetVelocity(vel)
end

function ENT:FinishMove(mv)
	local ang = mv:GetMoveAngles()

	ang.p = 0

	self:UpdateAnimation()

	self:SetNetworkOrigin(mv:GetOrigin())
	self:SetAngles(ang)
	self:SetMoveSpeed(mv:GetVelocity())

	if self:HasMoveInput(mv) then
		local walk = self:GetSpeeds()

		self:SetRunning(mv:GetVelocity():Length() > walk * self.Margin)
	end

	if SERVER then
		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableMotion(true)

			phys:SetPos(mv:GetOrigin())
			phys:Wake()

			phys:EnableMotion(false)
		end
	end
end

function ENT:StopDriving(ply)
	self:SetMoveSpeed(vector_origin)

	self:UpdateAnimation()
end

if CLIENT then
	local firstperson = CreateClientConVar("drivable_firstperson_offset", "30 15 0")
	local thirdperson = CreateClientConVar("drivable_thirdperson_offset", "170 0 10")

	function ENT:GetOffset(alt)
		local convar = alt and firstperson:GetString() or thirdperson:GetString()
		local offset = Vector(convar)

		if offset:IsZero() then
			offset = Vector(convar:GetDefault())
		end

		offset:Clamp(Vector(0, -30, -10), Vector(200, 30, 20))

		return offset
	end

	function ENT:HandleThirdPersonView(ply, view, alt)
		local ang = ply:EyeAngles()
		local pos = self:GetPos() + Vector(0, 0, 64)
		local target = self:GetOffset(alt)

		target.z = -target.z

		target:Rotate(ang)
		target = pos - target

		local tr = util.TraceHull({
			start = pos,
			endpos = target,
			mins = Vector(-2, -2, -2),
			maxs = Vector(2, 2, 2),
			filter = {self}
		})

		view.origin		= tr.HitPos
		view.angles		= ang
	end

	function ENT:CalcView(ply, view)
		if self:GetThirdPerson() then
			self:HandleThirdPersonView(ply, view, false)
		else
			self:HandleThirdPersonView(ply, view, true)

			-- local index = self:LookupAttachment("eyes")
			-- local att = self:GetAttachment(index)

			-- view.znear = 1

			-- view.origin = LocalToWorld(Vector(-5, 0, 0), angle_zero, att.Pos, att.Ang)
			-- view.angles = ang
		end
	end
end