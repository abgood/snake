ExpirationTimer = {
	timer_ = nil,
	expirationTime_ = 0,
}

function ExpirationTimer:new()
	local new_expirationTime = {}
	self.__index = self
	setmetatable(new_expirationTime, self)

	new_expirationTime.timer_ = Time:GetElapsedTime()
	new_expirationTime.timer_:Reset()

	return new_expirationTime
end

function ExpirationTimer:Expired()
	return (not Active())
end

function ExpirationTimer:Active()
	return (self.timer_:GetMSec(false) < self.expirationTime_)
end

function ExpirationTimer:Reset()
	self.timer_:Reset()
end

function ExpirationTimer:SetExpirationTime(expirationTime)
	self.expirationTime_ = expirationTime
	self.timer_:Reset()
end

function ExpirationTimer:GetCurrentTime()
	return self.timer_:GetMSec(false)
end
