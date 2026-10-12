--!nonstrict
-- Periodic intent only. The existing scheduler and mechanics adapter own all input.
local AntiAFKManager = {}
AntiAFKManager.__index = AntiAFKManager

function AntiAFKManager.new(controller)
	return setmetatable({ Controller = controller, SentPulses = 0, AttemptedPulses = 0,
		Running = false, Destroyed = false, Capability = { Available = false, Status = "UNASSESSED" } }, AntiAFKManager)
end

function AntiAFKManager:_settings()
	return self.Controller.Config.ANTIAFK_SETTINGS or {}
end

function AntiAFKManager:_mechanics()
	return self.Controller.Farming and self.Controller.Farming.Mechanics
end

function AntiAFKManager:_fault(reason)
	self.Fault = self.Fault or tostring(reason)
	if not self.FaultReported then
		self.FaultReported = true
		if self.Controller.Log then self.Controller:Log("ANTI_AFK][ERROR", self.Fault, true) end
	end
end

function AntiAFKManager:_release()
	local mechanics = self:_mechanics()
	if not mechanics or type(mechanics.ReleaseAntiAFKInput) ~= "function" then return end
	local ok, released, reason = pcall(mechanics.ReleaseAntiAFKInput, mechanics)
	if not ok or released == false then
		self:_fault("Input cleanup failed: " .. tostring(ok and reason or released))
	end
end

function AntiAFKManager:Observe()
	if self.Destroyed then return end
	local running = self.Controller.State == "RUNNING"
	if not running then
		if self.Running or self.Executing then self:Halt("Controller is not running") end
		return
	end
	self.Running = true
	local settings = self:_settings()
	if not settings.ENABLE_ANTI_AFK then self.NextDueAt = nil return end
	if not self.NextDueAt then self.NextDueAt = os.clock() + settings.INTERVAL_SECONDS end
end

function AntiAFKManager:_guard()
	local mechanics = self:_mechanics()
	if not mechanics or type(mechanics.AntiAFKGuard) ~= "function" then
		self:_fault("The anti-AFK interaction guard is unavailable")
		return false, self.Fault
	end
	local ok, allowed, reason = pcall(mechanics.AntiAFKGuard, mechanics, self)
	if not ok then self:_fault("Anti-AFK guard failed: " .. tostring(allowed)) return false, self.Fault end
	return allowed == true, reason or (allowed ~= true and "Input is suppressed" or nil)
end

function AntiAFKManager:Select()
	self:Observe()
	local settings = self:_settings()
	if self.Destroyed or not settings.ENABLE_ANTI_AFK or not self.Running or self.Fault then return false end
	if not self.NextDueAt or os.clock() < self.NextDueAt then return false end
	if settings.METHOD ~= "VIRTUAL_INPUT_SCROLL_LOCK" then self:_fault("Unsupported anti-AFK input method") return false end
	local active = self.Controller.Scheduler and self.Controller.Scheduler.Active
	if self.Executing or active and (not active.Definition or active.Definition.Owner ~= "ANTI_AFK") then
		self.LastSuppression = "Another scheduler operation owns the foreground"
		return false
	end
	local mechanics = self:_mechanics()
	if not mechanics or type(mechanics.AntiAFKCapability) ~= "function" or type(mechanics.AntiAFKPulse) ~= "function"
		or type(mechanics.ReleaseAntiAFKInput) ~= "function" then
		self:_fault("The anti-AFK runtime adapter is unavailable") return false
	end
	local ok, capability = pcall(mechanics.AntiAFKCapability, mechanics, settings.METHOD)
	if not ok or type(capability) ~= "table" or capability.Available ~= true then
		self.Capability = type(capability) == "table" and capability or { Available = false, Status = "UNAVAILABLE" }
		self:_fault("Anti-AFK capability unavailable: " .. tostring(ok and self.Capability.Reason or capability))
		return false
	end
	self.Capability = capability
	local allowed, reason = self:_guard()
	if not allowed then self.LastSuppression = reason return false end
	self.LastSuppression = nil
	return true, { Kind = "ANTI_AFK", Method = settings.METHOD }
end

function AntiAFKManager:Definition(_, generation)
	local controller = self.Controller
	return { Id = "OC_GAMEPLAY", Owner = "ANTI_AFK", Generation = generation, Priority = 60, TimeoutSeconds = 2,
		CanRun = function() return not self.Destroyed and controller.State == "RUNNING" and generation == controller.Generation end,
		Execute = function(token)
			if self.Destroyed or token:CheckCancelled() or controller.State ~= "RUNNING" or generation ~= controller.Generation then
				return { Status = "CANCELLED", InputSent = false }
			end
			local owns = self:Select()
			if not owns then return { Status = "SUPPRESSED", InputSent = false, Reason = self.LastSuppression or self.Fault } end
			self.Executing = true
			-- Record before the risky adapter call. A failure never triggers a rapid retry.
			self.NextDueAt = os.clock() + self:_settings().INTERVAL_SECONDS
			self.AttemptedPulses += 1
			local mechanics = self:_mechanics()
			local ok, sent, reason = pcall(mechanics.AntiAFKPulse, mechanics, self, token)
			self:_release() -- Always finalize the adapter's tracked possible key-down, including call failures.
			self.Executing = false
			local suppressed = ok and sent ~= true and type(reason) == "string" and reason:sub(1, 11) == "SUPPRESSED:"
			local result = { Status = ok and sent == true and "INPUT_SENT_UNVERIFIED" or suppressed and "SUPPRESSED" or "INPUT_FAILED",
				InputSent = ok and sent == true, Method = self:_settings().METHOD, Reason = ok and reason or sent,
				CancelledAfterDispatch = token:CheckCancelled() or controller.State ~= "RUNNING" or generation ~= controller.Generation,
				NativeActivity = "INPUT_HANDLER_INSPECTED_RUNTIME_PENDING", IdlePrevention = "OWNER_LONG_DURATION_PENDING" }
			if result.InputSent then self.SentPulses += 1 self.LastPulseAt = os.clock()
			elseif suppressed then
				self.LastSuppression = reason
				-- Account/Brain planning performs this retry; there is no independent timer.
				if not result.CancelledAfterDispatch then self.NextDueAt = os.clock() + 5 end
			else self:_fault("Anti-AFK input failed: " .. tostring(result.Reason)) end
			self.LastResult = result
			return result
		end,
		IsComplete = function(result) return type(result) == "table" end }
end

function AntiAFKManager:Completed(_, result)
	if type(result) == "table" then self.LastResult = result end
	if type(result) == "table" and result.InputSent and self.LastLoggedPulseAt ~= self.LastPulseAt then
		self.LastLoggedPulseAt = self.LastPulseAt
		if self.Controller.Log then self.Controller:Log("ANTI_AFK", "INPUT_SENT_UNVERIFIED | method=" .. tostring(self:_settings().METHOD)
			.. "; pulses=" .. tostring(self.SentPulses) .. "; native activity handler inspected; runtime effect/idle prevention remain owner-tested") end
	end
	self:Observe()
end

function AntiAFKManager:Resume()
	if self.Destroyed then return false end
	self.Running = self.Controller.State == "RUNNING"
	self.NextDueAt = self.Running and self:_settings().ENABLE_ANTI_AFK
		and os.clock() + self:_settings().INTERVAL_SECONDS or nil
	self.LastSuppression = nil
	return true
end

function AntiAFKManager:Halt(reason)
	self.Running = false
	self.NextDueAt = nil -- Resume starts a fresh interval; no immediate duplicate pulse.
	self.LastSuppression = reason or "Stopped"
	self:_release() -- Synchronous, before scheduler destruction can discard a coroutine.
end

function AntiAFKManager:Destroy()
	if self.Destroyed then return end
	self:Halt("Destroyed")
	self.Destroyed = true
end

function AntiAFKManager:GetStatus()
	return { Enabled = self:_settings().ENABLE_ANTI_AFK == true, Method = self:_settings().METHOD,
		Capability = self.Capability, NextDueAt = self.NextDueAt, LastPulseAt = self.LastPulseAt,
		AttemptedPulses = self.AttemptedPulses, SentPulses = self.SentPulses, Pending = self.Executing == true,
		Suppression = self.LastSuppression, Fault = self.Fault, LastResult = self.LastResult,
		NativeActivity = "INPUT_HANDLER_INSPECTED_RUNTIME_PENDING", IdlePrevention = "OWNER_LONG_DURATION_PENDING" }
end

return AntiAFKManager
