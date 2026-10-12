do
-- This is an offline opt-in fixture only. Public examples/defaults keep the
-- exception OFF; no owner live test is represented by these synthetic records.
local before = tests
local Allowance, Policy, Manager = requireOC("OwnerHatchTestAllowance"), requireOC("PetPolicy"), requireOC("PetManager")
local token = { CheckCancelled = function() return false end }
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {} for key, entry in pairs(value) do result[key] = copy(entry) end
	return result
end
local function options()
	return {
		PET_SETTINGS = { ENABLE_PET_INTELLIGENCE = true, AUTO_HATCH = true, AUTO_EQUIP = false, EQUIP_OWNED_TEAM_ONCE = false,
			OBJECTIVE_CURRENCY = "Coins", AUTO_DELETE_PETS = false, AUTO_CRAFT_SHINY = false, AUTO_FUSE_PETS = false },
		HATCH_SETTINGS = { HATCH_ONE_EGG_ONCE = true, EGG_SELECTION_MODE = "MANUAL", SELECTED_EGGS = { "Test Egg" },
			ALLOWED_CURRENCIES = { "Coins" }, MAXIMUM_SESSION_HATCHES = 1, MAXIMUM_BATCH_HATCHES = 1,
			MAXIMUM_EGG_COST = 10, MAXIMUM_SESSION_COST = 10, PRESERVE_PROGRESSION_RESERVE = true, ENABLE_BACKGROUND_PICKUPS = false },
		OWNER_ONE_HATCH_TEST_SETTINGS = { OWNER_ONE_HATCH_TEST_ALLOWANCE = true, MAXIMUM_COIN_ALLOWANCE = 10, MAXIMUM_EGG_COST = 10 },
		WORLD_SETTINGS = { ENABLE_WORLD_PROGRESSION = false, AUTO_DISCOVER_ISLANDS = false, AUTO_UNLOCK_WORLDS = false,
			AUTO_TRAVEL_FOR_PROGRESSION = false, AUTO_FARM_UNLOCK_REQUIREMENTS = false },
		FARMING_SETTINGS = { AUTO_RESOURCE_FARM = false, AUTO_FARM_FALLBACK = false },
		ISLAND_SETTINGS = { AUTO_TRAVEL_BEST_ISLAND = false, AUTO_EXPLORE_UNLOCKED_ISLANDS = false },
		PICKUP_SETTINGS = { BULK_COLLECT_PICKUPS = false, STATIONARY_ISOLATED_TEST = false },
		BUBBLE_SETTINGS = { AUTO_BLOW_BUBBLES = false, AUTO_SELL_BUBBLES = false, AUTO_BUY_GUM = false, AUTO_BUY_FLAVORS = false, ENABLE_SIMULTANEOUS_BLOWING = false },
		UPGRADE_SETTINGS = { ENABLE_SMART_UPGRADES = false, ENABLE_CAPACITY_UPGRADES = false, ENABLE_FLAVOR_UPGRADES = false, AUTO_EQUIP_OWNED_UPGRADES = false },
		EGG_TRAVEL_SETTINGS = { MODE = "NORMAL", ENABLE_SELECTED_EGG_TRAVEL = false, ENABLE_DIRECT_POSITIONING = false, ENABLE_NATIVE_ISLAND_TRAVEL = false },
		PLAYTIME_SETTINGS = { AUTO_CLAIM_PLAYTIME = false }, MYSTERY_BOX_SETTINGS = { AUTO_OPEN_MYSTERY_BOXES = false, ENABLE_AUTOMATIC_CONTINUATION = false },
		ANTIAFK_SETTINGS = { ENABLE_ANTI_AFK = false }, RESOURCE_SETTINGS = { COIN_RESERVE = 50 },
		FALL_EVENT_SETTINGS = { ENABLE_FALL_EVENT = false, AUTO_REBIRTH = false, AUTO_BUY_REBIRTH_UPGRADES = false,
			AUTO_USE_FALL_ELIXIRS = false, AUTO_BUY_AUTUMN_SHOP_ITEMS = false },
	}
end
local function snapshot(balance)
	return { Ready = true, Balances = { Coins = balance or 500, Gems = 50 }, ProgressionGraph = { Worlds = {
		{ Name = "The Overworld", Unlocked = true }, { Name = "Future World", Unlocked = false, Cost = { Type = "Currency", Currency = "Coins", Amount = 1000000000 } } } } }
end
local function syntheticShared(callback)
	local previous = shared shared = {}
	local ok, result = pcall(callback)
	shared = previous
	assert(ok,result)
end
local function controller()
	local c = { Config = config(options()), State = "RUNNING", Reader = { Player = { UserId = 123 } } }
	c.HatchTestAllowance = Allowance.new(c)
	return c
end

local function hatchFixture()
	local s=stationaryFixture(options())
	s.Profile.Coins=500
	s.Profile.Pets={{Id="strong",Name="Strong",Amount=2},{Id="weak",Name="Weak"}}
	s.Profile.Teams,s.Profile.TeamEquipped={{Pets={"strong","strong"}}},1
	s.Profile.EggsOpened,s.Profile.AutoDelete={["Test Egg"]=0},{}
	local d=s.Dependencies
	d.Pets={Strong={Rarity="Rare"},Weak={Rarity="Common"},New={Rarity="Epic"}}
	d.HatchPresentation={IsHatching=function() return false end}
	d.ProximityPrompt={Visible=0} d.Time={now=function() return os.clock() end}
	d.WorldUtil={GetPlayerWorld=function() return "The Overworld" end}
	d.StatsUtil.GetEggCost=function(_,_,facts) facts.CostProbe=true return {Type="Currency",Currency="Coins",Amount=10} end
	d.StatsUtil.HasDigitalStorage=function(_,facts) facts.DigitalProbe=true return false end
	d.StatsUtil.GetMaxPetStorage=function(_,facts) facts.MaxStorageProbe=true return 100 end
	d.StatsUtil.GetUsedPetStorage=function(_,facts) facts.UsedStorageProbe=true return 3 end
	d.StatsUtil.GetMaxEggHatches=function(_,facts) facts.HatchesProbe=true return 1 end
	d.StatsUtil.IsInventoryFull=function(_,facts) facts.FullProbe=true return false end
	local auto={IsA=function(_,kind) return kind=="BindableFunction" end,Invoke=function() if s.OnAuto then s.OnAuto() end return nil end}
	s.Controller.Reader.Player={UserId=123,Name="SyntheticOwner",GetAttribute=function() return nil end,
		FindFirstChild=function() return {FindFirstChild=function() return {FindFirstChild=function() return auto end} end} end}
	s.Controller.Reader.GetSnapshot=function() return snapshot(s.Profile.Coins) end
	s.Controller.Farming,s.Controller.Knowledge=s.Coordinator,s.Coordinator.Knowledge
	s.EggPart={Position=s.Root.Position+Vector3.new(2,0,0),IsA=function(_,kind) return kind=="BasePart" end}
	s.Egg={Name="Test Egg",Parent=true,IsDescendantOf=function() return true end,
		FindFirstChild=function(_,name) return name=="Root" and s.EggPart or {} end,GetAttribute=function() return true end}
	s.Controller.Knowledge.EggModels=function() return {s.Egg} end
	s.Controller.HatchTestAllowance=Allowance.new(s.Controller)
	s.Manager=Manager.new(s.Controller) s.Controller.Pets=s.Manager
	s.Commands={}
	d.Remote={FireServer=function(_,command,name,count)
		assert(shared.__OC_OWNER_ONE_HATCH_TEST_LEDGER.Accounts["123"].Consumed,
			"The same-VM allowance must already be consumed before native invocation")
		table.insert(s.Commands,{Command=command,Name=name,Count=count})
		if s.RemoteFailure then error("Synthetic delivery unknown") end
	end}
	function s.Manager:Fresh()
		local snap=snapshot(s.Profile.Coins) local facts=copy(s.Profile) local ranks={Strong=5,Weak=2,New=9}
		local ctx={AccountId=123,Currency="Coins",AccountFacts=facts,Inventory=Policy.Inventory(facts),Pets=d.Pets,MaxEquipped=2,
			MaxHatches=1,StorageUsed=3,StorageCapacity=100,DigitalStorage=false,InventoryFull=false,AutoDeleteKnown=true,AutoDeleteActive=false}
		ctx.ScoreTeam=function(ids,pets)
			local by={} for _,pet in ipairs(pets or facts.Pets) do by[pet.Id]=pet end
			local total=1 for _,id in ipairs(ids) do if not by[id] then return nil end total+=ranks[by[id].Name]-1 end return total
		end
		ctx.PetStats=function(pet) return {Coins=ranks[pet.Name]} end ctx.PetScore=function(pet) return ranks[pet.Name] end
		ctx.ScoreNewPet=function(name,ids)
			local pets=copy(facts.Pets) table.insert(pets,{Id="synthetic",Name=name}) local best=ctx.ScoreTeam(ids)
			for slot=1,#ids do local after=table.clone(ids) after[slot]="synthetic" best=math.max(best,ctx.ScoreTeam(after,pets)) end return best
		end
		ctx.Eggs={{Name="Test Egg",Model=s.Egg,World="The Overworld",Island="The Void",Cost={Type="Currency",Currency="Coins",Amount=10},
			Loaded=true,Accessible=true,AccessStatus="ACCESSIBLE",InRange=true,Opened=true,Unlocked=true,Range=16,Duration=2,
			Pool={{Chance=1,Item={Type="Pet",Name="New"}}}}}
		ctx.EggAvailability=ctx.Eggs return snap,ctx
	end
	function s:Decision() local snap,ctx=self.Manager:Fresh() return self.Controller.Brain:PlanPets(self.Controller.Brain:AnalyzePets(snap,ctx),ctx,self.Manager:State()) end
	function s:Dispatch() local decision=self:Decision() if decision.Kind=="WAIT" then return false,decision.Reason end return self.Coordinator.Mechanics:PetAction(self.Manager,decision,token) end
	return s
end

test("Owner allowance defaults OFF and normal future-world reserve remain unchanged", function()
	assert(not Defaults.OWNER_ONE_HATCH_TEST_SETTINGS.OWNER_ONE_HATCH_TEST_ALLOWANCE and Defaults.OWNER_ONE_HATCH_TEST_SETTINGS.MAXIMUM_COIN_ALLOWANCE == 0)
	local normal = config({ RESOURCE_SETTINGS = { COIN_RESERVE = 50 } })
	assert(Policy.Reserve(normal,snapshot(),"Coins") == 1000000050)
	local funds = Allowance.EffectiveFunds(normal,snapshot(),"Coins","Test Egg",500,123)
	assert(not funds.Enabled and not funds.Eligible)
end)

test("Owner one-hatch exception draws only a small capped amount of actually held world Coins", function()
	syntheticShared(function()
		local c = controller() local snap = snapshot()
		local f = Allowance.EffectiveFunds(c.Config,snap,"Coins","Test Egg",500,123)
		assert(f.Eligible and f.WorldReserve == 1000000000 and f.NormalReserve == 1000000050)
		assert(f.HeldWorldReserve == 450 and f.AdditionalSpendable == 10 and f.Spendable == 10 and f.EffectiveReserve == 490)
		assert(Policy.Reserve(c.Config,snap,"Coins") == 1000000050)
		local report = Policy.FundEgg(c.Config,snap,{ Name="Test Egg",Cost={Type="Currency",Currency="Coins",Amount=10} },123)
		assert(report.Affordable and report.NormalReserve == 1000000050 and report.Reserve == 490)
		assert(c.HatchTestAllowance:Eligibility("Test Egg",10,snap,500,123))
	end)
end)

test("Owner allowance never consumes configured operating reserve or exceeds actual native funds", function()
	syntheticShared(function()
		local c = controller()
		for _, balance in ipairs({ 0, 49, 50, 59 }) do
			assert(not c.HatchTestAllowance:Eligibility("Test Egg",10,snapshot(balance),balance,123))
		end
		assert(c.HatchTestAllowance:Eligibility("Test Egg",10,snapshot(60),60,123))
		assert(not c.HatchTestAllowance:Eligibility("Test Egg",11,snapshot(),500,123))
		assert(not c.HatchTestAllowance:Eligibility("Other Egg",10,snapshot(),500,123))
		assert(not c.HatchTestAllowance:Eligibility("Test Egg",0,snapshot(),500,123))
		assert(not c.HatchTestAllowance:GetStatus().Consumed)
	end)
end)

test("Owner exception rejects automatic selection unrelated actions currencies and missing world/account facts", function()
	syntheticShared(function()
		for _, mutate in ipairs({ function(c) c.Config.HATCH_SETTINGS.EGG_SELECTION_MODE="AUTO" end,
			function(c) c.Config.PET_SETTINGS.AUTO_EQUIP=true end, function(c) c.Config.EGG_TRAVEL_SETTINGS.MODE="TRAVEL_ONLY" end,
			function(c) c.Config.EGG_TRAVEL_SETTINGS.ENABLE_DIRECT_POSITIONING=true end, function(c) c.Config.PLAYTIME_SETTINGS.AUTO_CLAIM_PLAYTIME=true end,
			function(c) c.Config.PICKUP_SETTINGS.BULK_COLLECT_PICKUPS=true end, function(c) c.Config.HATCH_SETTINGS.MAXIMUM_SESSION_HATCHES=2 end }) do
			local c=controller() mutate(c)
			assert(not Allowance.EffectiveFunds(c.Config,snapshot(),"Coins","Test Egg",500,123).Eligible)
		end
		local c=controller() assert(not Allowance.EffectiveFunds(c.Config,snapshot(),"Gems","Test Egg",500,123).Eligible)
		assert(not Allowance.EffectiveFunds(c.Config,snapshot(),"Coins","Test Egg",500,nil).Eligible)
		local unknown=snapshot() unknown.ProgressionGraph.Worlds[2].Cost=nil
		assert(not Allowance.EffectiveFunds(c.Config,unknown,"Coins","Test Egg",500,123).Eligible)
		unknown=snapshot() unknown.ProgressionGraph.Worlds[2].Cost.Currency=nil
		assert(not Allowance.EffectiveFunds(c.Config,unknown,"Coins","Test Egg",500,123).Eligible)
		assert(not c.HatchTestAllowance:Consume("Test Egg",10,unknown,500,123) and not c.HatchTestAllowance:GetStatus().Consumed)
		unknown=snapshot() unknown.ProgressionGraph.Worlds[2].Cost.Amount=1e308 c.Config.RESOURCE_SETTINGS.COIN_RESERVE=1e308
		assert(not Allowance.EffectiveFunds(c.Config,unknown,"Coins","Test Egg",500,123).Eligible)
	end)
end)

test("Owner allowance consumes before uncertain invocation and survives same-VM reload or changed egg/caps", function()
	syntheticShared(function()
		local c=controller() local ok,_,record=c.HatchTestAllowance:Consume("Test Egg",10,snapshot(),500,123)
		assert(ok and record.Consumed and record.State=="REQUESTED_UNRESOLVED" and record.WorldReserveBorrowed==10)
		c.HatchTestAllowance:Uncertain("Synthetic native invocation exception; delivery unknown")
		local loaded=controller() loaded.Config.HATCH_SETTINGS.SELECTED_EGGS={"Other Egg"}
		loaded.Config.OWNER_ONE_HATCH_TEST_SETTINGS.MAXIMUM_COIN_ALLOWANCE=1000
		loaded.Config.OWNER_ONE_HATCH_TEST_SETTINGS.MAXIMUM_EGG_COST=1000
		assert(not loaded.HatchTestAllowance:Eligibility("Other Egg",10,snapshot(),500,123))
		assert(not loaded.HatchTestAllowance:Consume("Other Egg",10,snapshot(),500,123))
		local r=Policy.FundEgg(loaded.Config,snapshot(),{Name="Other Egg",Cost={Type="Currency",Currency="Coins",Amount=10}},123)
		assert(not r.Affordable and r.Reserve==r.NormalReserve and r.Reserve==1000000050 and r.FundingStatus:find("OWNER_TEST_ALLOWANCE_BLOCKED"))
		assert(loaded.HatchTestAllowance:GetStatus().Consumed and loaded.HatchTestAllowance:GetStatus().Persistence:find("restart/rejoin"))
	end)
end)

test("Owner missing corrupt or replaced shared ledger fails closed without consumption", function()
	syntheticShared(function()
		local c=controller() shared.__OC_OWNER_ONE_HATCH_TEST_LEDGER={Version=9,Accounts={}}
		assert(not c.HatchTestAllowance:Eligibility("Test Egg",10,snapshot(),500,123))
		local other=Allowance.new(c) assert(other.Fault)
		shared.__OC_OWNER_ONE_HATCH_TEST_LEDGER={Version=1,Accounts={}}
		assert(not c.HatchTestAllowance:Consume("Test Egg",10,snapshot(),500,123))
		shared=nil assert(not Allowance.EffectiveFunds(c.Config,snapshot(),"Coins","Test Egg",500,123).Eligible)
	end)
end)

test("Owner Stop before dispatch consumes no ledger entry and cannot silently resume that authorization", function()
	syntheticShared(function()
		local c=controller() c.HatchTestAllowance:Halt(true)
		assert(not c.HatchTestAllowance:Consume("Test Egg",10,snapshot(),500,123))
		assert(not c.HatchTestAllowance:GetStatus().Consumed)
	end)
end)

test("Owner result records exact requested price separately from counter inventory and net debit", function()
	syntheticShared(function()
		local c=controller() assert(c.HatchTestAllowance:Consume("Test Egg",10,snapshot(),500,123))
		c.HatchTestAllowance:Observe({Status="INVENTORY_GAIN_OBSERVED",CounterBefore=0,CounterAfter=1,CounterDelta=1,
			RequestedQuantity=1,Quantity=1,Changes={{Id="received",Name="New",Variant="Shiny",Quantity=1}},
			Balances={Coins={Before=500,After=495,Delta=-5}}})
		local r=c.HatchTestAllowance:GetStatus().Record
		assert(r.RequestedPrice==10 and r.Result.ObservedNetDebit==5 and r.Result.Changes[1].Variant=="Shiny")
		assert(r.Consumed and r.State=="RECEIVED_CONFIRMED" and r.Result.Attribution:find("UNKNOWN"))
		assert(not c.HatchTestAllowance:Eligibility("Test Egg",10,snapshot(),500,123))
	end)
end)

test("Owner native one-hatch integration consumes before dispatch and isolates mutating native final helpers", function()
	syntheticShared(function()
		simulated(function()
			local s=hatchFixture() local beforeProfile=copy(s.Profile)
			assert(s:Dispatch() and #s.Commands==1 and s.Commands[1].Count==1)
			assert(Policy.Equal(s.Profile,beforeProfile) and not s.Profile.CostProbe and not s.Profile.FullProbe)
			assert(s.Manager.Hatch.Pending.OwnerAllowance.RequestedPrice==10 and s.Manager.Hatch.RequestCost==10)
			assert(s.Manager.Hatch.Pending.OwnerAllowance.BeforeEvidence.EggCounter==0
				and s.Manager.Hatch.Pending.OwnerAllowance.BeforeEvidence.Inventory.strong.Amount==2)
			s.Profile.Pets[3]={Id="received",Name="New"} s.Profile.EggsOpened["Test Egg"]=1 s.Profile.Coins=490 s.Manager:Observe()
			local result=s.Manager.Hatch.LastResult
			assert(result.Status=="INVENTORY_GAIN_OBSERVED" and result.OwnerAllowance.Result.ObservedNetDebit==10)
			assert(result.OwnerAllowance.RequestedPrice==10 and result.OwnerAllowance.WorldReserveBorrowed==10)
			assert(s.Manager.Hatch:ResultText():find("exact requested price=10") and s.Manager.Hatch:Ended())
			assert(not s:Dispatch() and #s.Commands==1 and s.Manager.EquipCommands==0) s:Close()
		end)
	end)
end)

test("Owner final native guard failures never consume the one-hatch ledger", function()
	syntheticShared(function()
		simulated(function()
			local s=hatchFixture() s.OnAuto=function() s.Profile.Coins=50 end
			assert(not s:Dispatch() and #s.Commands==0 and not s.Controller.HatchTestAllowance:GetStatus().Consumed)
			assert(s.Manager.Hatch.RequestCost==0) s:Close()
		end)
	end)
end)

test("Owner uncertain actual invocation remains consumed across a same-VM fresh manager", function()
	syntheticShared(function()
		simulated(function(clock)
			local s=hatchFixture() s.RemoteFailure=true
			assert(s:Dispatch() and #s.Commands==1 and s.Manager.Fault)
			s.Controller.HatchTestAllowance=Allowance.new(s.Controller)
			assert(not s.Controller.HatchTestAllowance:Consume("Test Egg",10,snapshot(),500,123))
			clock.Time=16 s.Manager:Observe()
			assert(s.Manager.Hatch.LastResult.Status=="UNCONFIRMED" and not s:Dispatch() and #s.Commands==1)
			s:Close()
		end)
	end)
end)

print("[OC TEST] " .. tostring(tests-before) .. " explicit owner one-hatch allowance tests passed; same-VM persistence only, live approval/verification pending.")
end
