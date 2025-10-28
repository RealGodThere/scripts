--// LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AttackServer")

local enabled = true
local bossExists = false
local attacking = false
local raidStarted = false

local function AttackBossOnce()
	if attacking then return end
	attacking = true
	for i = 1, 40 do
		local args = {
			"Charge",
			"String Fly",
			"String",
			{
				RootCFrame = CFrame.new(71.12207794189453, 17.851551055908203, 182.30206298828125, -0.9995360970497131, 1.08759641292977e-08, 0.030456289649009705, 8.202976964355457e-09, 1, -8.78896599942891e-08, -0.030456289649009705, -8.759905512079058e-08, -0.9995360970497131),
	        	MouseHit = CFrame.new(69.21131134033203, 14.402069091796875, 187.5513153076172, -0.9995361566543579, -0.021176502108573914, 0.021888792514801025, 9.313225746154785e-10, 0.7187039256095886, 0.6953163146972656, -0.030455924570560455, 0.694993793964386, -0.7183704972267151)
			}
		}
		remote:FireServer(unpack(args))
		task.wait(0.05)
	end
	attacking = false
end

local function TryStartRaid()
	if raidStarted then return end
	local backpack = player:FindFirstChild("Backpack")
	local entities = workspace:FindFirstChild("Entities")
	local bases = workspace:FindFirstChild("Bases")
	if not backpack or not entities or not bases then return end
	local hasTool = backpack:FindFirstChild("String")
	if not hasTool then
		local playerEntity = entities:FindFirstChild(player.Name)
		if playerEntity then
			hasTool = playerEntity:FindFirstChild("String")
		end
	end
	local lockBtn = bases:FindFirstChild("1") and bases["1"]:FindFirstChild("LockBtn")
	if hasTool and lockBtn then
		raidStarted = true
		local args = { "CreateParty" }
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Raid"):FireServer(unpack(args))
		task.wait(0.5)
		local args2 = { "Start" }
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Raid"):FireServer(unpack(args2))
	end
end

task.spawn(function()
	while task.wait(0.3) do
		if not enabled then continue end
		if not raidStarted then
			TryStartRaid()
		end
		local raid = workspace:FindFirstChild("Raid")
		if not raid then continue end
		local bossCam = raid:FindFirstChild("BossSpawnCam1")
		if bossCam then
			if not bossExists then
				bossExists = true
				AttackBossOnce()
				local entities = workspace:FindFirstChild("Entities")
				if entities then
					local boss = entities:FindFirstChild("Light Boss")
					while enabled and boss and boss.Parent == entities do
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp and boss:FindFirstChild("Head") then
							hrp.CFrame = boss.Head.CFrame + Vector3.new(0, 3, 0)
						end
						task.wait(0.1)
					end
				end
				bossExists = false
			end
		else
			bossExists = false
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.T then
		enabled = not enabled
	end
end)
