--!nonstrict
-- Keep this credential only in your local runtime input. Never commit it.
local GitHubToken = "" -- A fine-grained token: OCscript only, Contents: read.

local Config = {
	GENERAL_SETTINGS = {
		OC_ENABLED = true, --// Permit initialization and OC controls.
		AUTO_START = true, --// Immediately analyze the received account.
	},
	ACCOUNT_SETTINGS = {
		SNAPSHOT_REFRESH_SECONDS = 5, --// Refresh after manual account changes.
		SELECTED_CURRENCIES = { "Coins", "Gems", "Tickets", "Pearls", "Leaves26", "RebirthShards26" }, --// Missing balances remain unavailable.
	},
	STATUS_UI_SETTINGS = {
		ENABLE_STATUS_UI = true, --// Show statistics, account details, goals, and controls.
	},
	DIAGNOSTIC_SETTINGS = {
		ENABLE_CONSOLE_LOGGING = true, --// Print [OC] diagnostics for the test.
		LOG_ACCOUNT_DETAILS = true, --// Print the received account sections.
	},
}

-- Canonical raw path: https://raw.githubusercontent.com/ryanrooflead-source/OCscript/main/dist/OC.lua
-- The repository is private; use GitHub's authenticated raw-media API instead.
local Request = request or http_request or (http and http.request)
assert(type(Request) == "function", "[OC] No header-capable HTTP request API. Download dist/OC.lua while signed into GitHub and use your runtime's local bundle input instead.")
assert(type(loadstring) == "function", "[OC] Your client runtime must support compiling Luau source")
assert(GitHubToken ~= "", "[OC] Enter your read-only GitHub token locally; do not send it in chat")
local ok, Response = pcall(Request, {
	Url = "https://api.github.com/repos/ryanrooflead-source/OCscript/contents/dist/OC.lua?ref=main",
	Method = "GET",
	Headers = { Authorization = "Bearer " .. GitHubToken, Accept = "application/vnd.github.raw+json" },
})
GitHubToken = nil
assert(ok and type(Response) == "table", "[OC] GitHub download failed; check your runtime's HTTP request support")
assert(Response.StatusCode == 200, "[OC] GitHub returned HTTP " .. tostring(Response.StatusCode) .. "; check token access to OCscript")
local Initialize, CompileError = loadstring(Response.Body)
assert(Initialize, "[OC] Bundle compilation failed: " .. tostring(CompileError))
local OC = Initialize()(Config)
-- OC:GetStatus(), OC:PrintAccount(), OC:Pause(), OC:Resume(), OC:Stop(), OC:Start(), OC:Destroy()
return OC
