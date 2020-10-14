AddCSLuaFile()

ENT.ActivityTranslate = {
	["ar2"] = {
		[ACT_IDLE] = "idle1",
		[ACT_COMBAT_IDLE] = "combatidle1",
		[ACT_WALK] = "walk_all",
		[ACT_WALK_AIM] = "walk_aiming_all",
		[ACT_RUN] = "runall",
		[ACT_RUN_AIM] = "runaimall1",
		[ACT_GESTURE_RANGE_ATTACK1] = "gesture_shoot_ar2",
		[ACT_GESTURE_RANGE_ATTACK2] = "grenthrow"
	},
	["smg1"] = {
		[ACT_IDLE] = "idle1",
		[ACT_COMBAT_IDLE] = "combatidle1_smg1",
		[ACT_WALK] = "walk_all",
		[ACT_WALK_AIM] = "walk_aiming_all",
		[ACT_RUN] = "runall",
		[ACT_RUN_AIM] = "runaimall1",
		[ACT_GESTURE_RANGE_ATTACK1] = "gesture_shoot_smg1",
		[ACT_GESTURE_RANGE_ATTACK2] = "grenthrow"
	}
}

function ENT:SetupHoldType(holdtype)
	self:SetHoldType(holdtype)

	self:SetLayerSequence(0, self:LookupActivity(ACT_IDLE), 0)
	self:SetLayerSequence(1, self:LookupActivity(ACT_COMBAT_IDLE), 1)
	self:SetLayerSequence(2, self:LookupActivity(ACT_GESTURE_RANGE_ATTACK1), 2)

	self:ResetSequence(self:LookupActivity(ACT_WALK))
end

function ENT:LookupActivity(act)
	return self:LookupCachedSequence(self:TranslateActivity(act))
end

function ENT:LookupCachedSequence(name)
	if not self.CachedSequences then
		self.CachedSequences = {}
	end

	if not self.CachedSequences[name] then
		self.CachedSequences[name] = self:LookupSequence(name)
	end

	return self.CachedSequences[name]
end

function ENT:TranslateActivity(act)
	return self.ActivityTranslate[self:GetHoldType()][act]
end

function ENT:GetLayerWeights()
	local state = self:GetState()
	local fraction = math.min((CurTime() - self:GetLastState()) / 0.25, 1)
	local weights = {}

	if state == STATE_IDLE then
		weights[0] = fraction
		weights[1] = 1 - fraction
	elseif state == STATE_COMBAT then
		weights[0] = 1 - fraction
		weights[1] = fraction
	end

	return weights
end

local function clampRemap(val, inMin, inMax, outMin, outMax)
	return math.Clamp(math.Remap(val, inMin, inMax, outMin, outMax), math.min(outMin, outMax), math.max(outMin, outMax))
end

function ENT:UpdateAnimation(mv)
	local ang, vel, length

	if mv then
		ang = mv:GetMoveAngles()
		vel = mv:GetVelocity()
		length = vel:Length()

		self:SetPoseParameter("aim_pitch", ang.p)
	end

	local weights = self:GetLayerWeights()

	if self:GetGrenadeTimer() >= CurTime() then
		self:SetSequence(self:LookupActivity(ACT_GESTURE_RANGE_ATTACK2))
		self:SetPlaybackRate(1)

		self:SetLayerWeight(0, 0)

		local timeIn = CurTime() - self:GetGrenadeStart()
		local timeOut = self:GetGrenadeTimer() - CurTime()

		self:SetLayerWeight(1, clampRemap(timeIn, 0, 0.2, 1, 0) + clampRemap(timeOut, 0.2, 0, 0, 1))
	elseif mv and length > 0 then
		local diff = vel:Angle().y - ang.y

		if diff > 180 then diff = diff - 360 end
		if diff < -180 then diff = diff + 360 end

		local sequence, rate
		local state = self:GetState()

		local walk, run = self:GetSpeeds()

		if length > walk * self.Margin then
			sequence = state == STATE_COMBAT and ACT_RUN_AIM or ACT_RUN
			rate = length / run
		else
			sequence = state == STATE_COMBAT and ACT_WALK_AIM or ACT_WALK
			rate = length / walk
		end

		local walkRate = length / walk

		self:SetPlaybackRate(rate)
		self:SetPoseParameter("move_yaw", diff)
		self:SetSequence(self:LookupActivity(sequence))

		local weight = math.max(1 - walkRate, 0)

		self:SetLayerWeight(0, weights[0] * weight)
		self:SetLayerWeight(1, weights[1] * weight)

		self:SetLayerPlaybackRate(0, 0)
		self:SetLayerPlaybackRate(1, 0)
	else
		self:SetPlaybackRate(0)

		self:SetLayerWeight(0, weights[0])
		self:SetLayerWeight(1, weights[1])

		self:SetLayerPlaybackRate(0, 1)
		self:SetLayerPlaybackRate(1, 1)
	end
end