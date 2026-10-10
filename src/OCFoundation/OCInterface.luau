--!nonstrict
local AccountPresentation = require(script.Parent.AccountPresentation)
local OCInterface = {}
OCInterface.__index = OCInterface

local function make(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do instance[key] = value end
	instance.Parent = parent
	return instance
end

local function count(map)
	if type(map) ~= "table" then return "unavailable" end
	local total = 0 for _ in pairs(map) do total += 1 end
	return tostring(total)
end

function OCInterface.new(controller, playerGui)
	local settings = controller.Config.STATUS_UI_SETTINGS
	local self = setmetatable({ Controller = controller, Connections = {}, Destroyed = false }, OCInterface)
	if not settings.ENABLE_STATUS_UI then return self end
	self.Gui = make("ScreenGui", { Name = "OCFoundationPanel", ResetOnSpawn = false,
		DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
	self.Panel = make("Frame", { Name = "Panel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(settings.PANEL_WIDTH_PIXELS, settings.PANEL_HEIGHT_PIXELS),
		BackgroundColor3 = Color3.fromRGB(20, 24, 35), BorderSizePixel = 0 }, self.Gui)
	make("UICorner", { CornerRadius = UDim.new(0, 14) }, self.Panel)
	make("UIStroke", { Color = Color3.fromRGB(65, 77, 97), Thickness = 1 }, self.Panel)
	make("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, self.Panel)
	make("TextLabel", { Name = "Title", Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
		Text = "BUBBLE OC  /  PHASE 2", TextSize = 18, Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(241, 246, 255), TextXAlignment = Enum.TextXAlignment.Left }, self.Panel)
	make("TextLabel", { Name = "Scope", Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1, Text = "Intelligent farming, selling and upgrades", TextSize = 12,
		Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(162, 178, 203), TextXAlignment = Enum.TextXAlignment.Left }, self.Panel)
	local controls = make("Frame", { Name = "Controls", Position = UDim2.fromOffset(0, 61), Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1 }, self.Panel)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, controls)
	self.Buttons = {}
	for index, action in ipairs({ "Start", "Pause", "Resume", "Stop" }) do
		local button = make("TextButton", { Name = action, LayoutOrder = index, Size = UDim2.new(0.25, -5.25, 1, 0),
			BackgroundColor3 = Color3.fromRGB(50, 60, 79), BorderSizePixel = 0, Text = string.upper(action),
			TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(240, 246, 255) }, controls)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
		self.Buttons[action] = button
		table.insert(self.Connections, button.Activated:Connect(function()
			local ok, reason = controller[action](controller)
			if not ok and reason then controller.Error = reason controller:_notify() end
		end))
	end
	local content = make("ScrollingFrame", { Name = "Status", Position = UDim2.fromOffset(0, 112),
		Size = UDim2.new(1, 0, 1, -112), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3 }, self.Panel)
	make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	self.Labels = {}
	for index, name in ipairs({ "State", "Objective", "Reason", "Prerequisites", "Farming", "Rates", "Islands", "Balances", "Progression", "Pets", "Inventory", "Worlds", "Upgrades", "Mastery", "Diagnostics" }) do
		self.Labels[name] = make("TextLabel", { Name = name, LayoutOrder = index, Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "", TextWrapped = true,
			TextSize = name == "Objective" and 17 or 13, Font = name == "Objective" and Enum.Font.GothamBold or Enum.Font.Gotham,
			TextColor3 = name == "Objective" and Color3.fromRGB(137, 220, 213) or Color3.fromRGB(216, 226, 242),
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, content)
	end
	local function resize()
		local camera = workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		self.Panel.Size = UDim2.fromOffset(math.min(settings.PANEL_WIDTH_PIXELS, math.max(200, viewport.X - 32)),
			math.min(settings.PANEL_HEIGHT_PIXELS, math.max(240, viewport.Y - 64)))
	end
	local cameraConnection
	local function hookCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		if workspace.CurrentCamera then cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
		resize()
	end
	table.insert(self.Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera))
	self.DisconnectCamera = function() if cameraConnection then cameraConnection:Disconnect() end end
	hookCamera()
	table.insert(self.Connections, controller.Changed.Event:Connect(function(status) self:Render(status) end))
	self:Render(controller:GetStatus())
	return self
end

function OCInterface:Render(status)
	if self.Destroyed or not self.Gui then return end
	local settings = self.Controller.Config.STATUS_UI_SETTINGS
	local snapshot = status.Snapshot or {}
	local plan = status.Plan
	local objective = plan and plan.Objective
	self.Labels.State.Text = status.State .. "  ·  " .. (snapshot.Status or "NOT_STARTED")
	self.Labels.Objective.Text = objective and objective.Title or (status.State == "STOPPED" and "Press START to analyze your account" or "Analyzing account")
	self.Labels.Reason.Text = objective and objective.Reason or "Waiting for real account data and configured controls."
	self.Labels.Prerequisites.Visible = settings.SHOW_PREREQUISITES and objective ~= nil and #objective.Prerequisites > 0
	self.Labels.Prerequisites.Text = objective and "Prerequisites: " .. table.concat(objective.Prerequisites, " · ") or ""
	local sections = AccountPresentation.Sections(snapshot, self.Controller.Config, settings.MAXIMUM_DISPLAY_ENTRIES)
	self.Labels.Balances.Visible = settings.SHOW_ACCOUNT_BALANCES
	self.Labels.Balances.Text = sections.Balances
	for _, name in ipairs({ "Pets", "Inventory", "Worlds", "Upgrades", "Mastery" }) do
		self.Labels[name].Visible = settings["SHOW_" .. string.upper(name)]
		self.Labels[name].Text = string.upper(name) .. "\n" .. sections[name]
	end
	self.Labels.Progression.Visible = settings.SHOW_PROGRESSION
	self.Labels.Progression.Text = "Progression: " .. (plan and plan.Progression or "UNDETERMINED")
		.. "\nWorlds: " .. count(snapshot.UnlockedWorlds) .. "   Areas: " .. count(snapshot.UnlockedIslands)
		.. (plan and "\n" .. plan.ProgressionEvidence or "")
	local farming = status.Farming or {}
	local decision = farming.Decision or {}
	self.Labels.Farming.Visible = settings.SHOW_FARMING
	self.Labels.Farming.Text = "FARMING: " .. tostring(farming.Activity or decision.Mode or decision.Kind or "Waiting")
		.. "\nArea: " .. tostring(farming.Area or "unavailable") .. " | target: " .. tostring(decision.Currency or "unavailable")
		.. "\n" .. tostring(decision.Reason or "Observing accessible game mechanics")
		.. string.format("\nPickups: %d eligible / %d visible; %d unidentified | radius: %s", farming.EligiblePickups or 0, farming.VisiblePickups or 0,
			farming.UnknownPickups or 0, tostring(farming.Radius or "unavailable"))
		.. "\n" .. tostring(farming.CollectionMethod or "") .. "\n" .. tostring(farming.LastConfirmation or "")
		.. "\nObserved new models: " .. tostring(farming.ObservedSpawns or 0) .. "; respawn observations: " .. tostring(farming.RespawnObservations or 0)
		.. (farming.Scan and string.format("\nNative registry: %s; active IDs=%d, positions=%d; Chunker folders=%d", farming.Scan.RegistryAvailable and "available" or "unavailable", farming.Scan.RegistryActiveIds, farming.Scan.PositionsResolved, farming.Scan.ChunkerFolders) or "")
		.. (farming.CollectionBlocker and "\nCollection unavailable: " .. farming.CollectionBlocker or "")
	local rates = {}
	for mode, entry in pairs(farming.Rates or {}) do
		local values = {}
		for currency, value in pairs(entry.PerMinute) do table.insert(values, string.format("%.2f %s/min", value, currency)) end
		table.sort(values)
		table.insert(rates, mode .. " (" .. string.format("%.1fs", entry.Seconds) .. "): " .. (entry.Ready and (#values > 0 and table.concat(values, ", ") or "0 observed income") or "sampling"))
	end
	table.sort(rates)
	self.Labels.Rates.Visible = settings.SHOW_FARMING_RATES
	self.Labels.Rates.Text = "OBSERVED RATES (external rewards may affect attribution)\n" .. (#rates > 0 and table.concat(rates, "\n") or "No earning samples yet")
	local islands = {}
	for index, candidate in ipairs(decision.IslandCandidates or {}) do
		if index > settings.MAXIMUM_DISPLAY_ENTRIES then break end
		table.insert(islands, string.format("%s: %s %s/min | %s", candidate.Name,
			candidate.PerMinute and string.format("%.2f", candidate.PerMinute) or "unknown", candidate.Currency, candidate.Evidence))
	end
	self.Labels.Islands.Visible = settings.SHOW_ISLAND_CANDIDATES and #islands > 0
	self.Labels.Islands.Text = "ELIGIBLE ISLANDS\n" .. table.concat(islands, "\n")
	local diagnostics = {}
	if status.Error then table.insert(diagnostics, status.Error) end
	if farming.Error then table.insert(diagnostics, farming.Error) end
	if snapshot.UnavailableFields and #snapshot.UnavailableFields > 0 then
		table.insert(diagnostics, "Unavailable fields: " .. table.concat(snapshot.UnavailableFields, ", "))
	end
	for _, message in ipairs(snapshot.Diagnostics or {}) do table.insert(diagnostics, message) end
	self.Labels.Diagnostics.Visible = settings.SHOW_DIAGNOSTICS and #diagnostics > 0
	self.Labels.Diagnostics.Text = table.concat(diagnostics, "\n")
	local enabled = { Start = status.State == "STOPPED", Pause = status.State == "RUNNING",
		Resume = status.State == "PAUSED", Stop = status.State ~= "STOPPED" }
	for name, button in pairs(self.Buttons) do
		button.Interactable = enabled[name]
		button.AutoButtonColor = enabled[name]
		button.TextTransparency = enabled[name] and 0 or 0.55
		button.BackgroundColor3 = name == "Start" and enabled[name] and Color3.fromRGB(32, 121, 111) or Color3.fromRGB(50, 60, 79)
	end
end

function OCInterface:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	if self.DisconnectCamera then self.DisconnectCamera() end
	if self.Gui then self.Gui:Destroy() end
end

return OCInterface
