--!nonstrict
-- Cooperative cancellation retains the foreground lease until Execute returns.
local TaskScheduler = {}
TaskScheduler.__index = TaskScheduler

function TaskScheduler.new(settings)
	local self = setmetatable({}, TaskScheduler)
	self.Settings = settings
	self.Changed = Instance.new("BindableEvent")
	self.Completed = Instance.new("BindableEvent")
	self.Queue = {}
	self.Active = nil
	self.Enabled = false
	self.Destroyed = false
	self.Sequence = 0
	return self
end

function TaskScheduler:GetStatus()
	return {
		ActiveTask = self.Active and self.Active.Definition.Id or nil,
		CancellationPending = self.Active ~= nil and self.Active.Token.Cancelled,
		PendingCount = #self.Queue,
		Enabled = self.Enabled,
	}
end

function TaskScheduler:_pump()
	if self.Destroyed or not self.Enabled or self.Active or #self.Queue == 0 then return end
	table.sort(self.Queue, function(a, b)
		if a.Priority == b.Priority then return a.Sequence < b.Sequence end
		return a.Priority > b.Priority
	end)
	local definition = table.remove(self.Queue, 1)
	local token = { Cancelled = false, Reason = nil }
	function token:CheckCancelled()
		return self.Cancelled
	end
	local active = { Definition = definition, Token = token }
	self.Active = active
	self.Changed:Fire(self:GetStatus())
	active.TimeoutThread = task.delay(definition.TimeoutSeconds or self.Settings.TASK_TIMEOUT_SECONDS, function()
		if self.Active == active then self:CancelActive("Task timed out") end
	end)
	-- Defer so the timeout/thread handles are installed before a synchronous task finishes.
	active.Thread = task.defer(function()
		local skipped = false
		local ok, result = xpcall(function()
			if token.Cancelled then return nil end
			if definition.CanRun and not definition.CanRun() then skipped = true return nil end
			local output = definition.Execute(token)
			if token.Cancelled then return nil end
			if definition.IsComplete and not definition.IsComplete(output) then
				error("Task returned without satisfying its completion check")
			end
			return output
		end, debug.traceback)
		if active.TimeoutThread then pcall(task.cancel, active.TimeoutThread) end
		if self.Active == active then self.Active = nil end
		if self.Destroyed then return end
		local status = token.Cancelled and "CANCELLED" or (skipped and "SKIPPED" or (ok and "COMPLETED" or "FAILED"))
		self.Completed:Fire(definition.Id, status, result, token.Reason, definition)
		self.Changed:Fire(self:GetStatus())
		self:_pump()
	end)
end

function TaskScheduler:Submit(definition)
	if self.Destroyed or not self.Settings.ENABLE_TASK_SCHEDULER then return false, "Scheduler unavailable" end
	assert(type(definition.Id) == "string" and type(definition.Execute) == "function", "Invalid task")
	assert(type(definition.Priority) == "number", "Task priority must be numeric")
	for index, pending in ipairs(self.Queue) do
		if pending.Id == definition.Id then table.remove(self.Queue, index) break end
	end
	if #self.Queue >= self.Settings.MAXIMUM_PENDING_TASKS then return false, "Queue is full" end
	self.Sequence += 1
	definition.Sequence = self.Sequence
	table.insert(self.Queue, definition)
	self.Changed:Fire(self:GetStatus())
	self:_pump()
	return true
end

function TaskScheduler:CancelActive(reason)
	if not self.Active then return end
	self.Active.Token.Cancelled = true
	self.Active.Token.Reason = reason or "Cancelled"
	self.Changed:Fire(self:GetStatus())
end

function TaskScheduler:Pause()
	self.Enabled = false
	table.clear(self.Queue)
	self:CancelActive("Paused")
	self.Changed:Fire(self:GetStatus())
end

function TaskScheduler:Resume()
	if self.Destroyed or not self.Settings.ENABLE_TASK_SCHEDULER then return end
	self.Enabled = true
	self.Changed:Fire(self:GetStatus())
	self:_pump()
end

function TaskScheduler:Stop()
	self.Enabled = false
	table.clear(self.Queue)
	self:CancelActive("Stopped")
	self.Changed:Fire(self:GetStatus())
end

function TaskScheduler:Destroy()
	if self.Destroyed then return end
	self:Stop()
	self.Destroyed = true
	if self.Active then
		if self.Active.TimeoutThread then pcall(task.cancel, self.Active.TimeoutThread) end
		if self.Active.Thread then pcall(task.cancel, self.Active.Thread) end
		self.Active = nil
	end
	self.Changed:Destroy()
	self.Completed:Destroy()
end

return TaskScheduler
