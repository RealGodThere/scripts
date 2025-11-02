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
				RootCFrame = CFrame.new(68.33767700195312, 17.85211181640625, 185.8611602783203, -0.9966945648193359, 7.292989323559596e-08, 0.08123976737260818, 6.521718631802287e-08, 1, -9.759111208040849e-08, -0.08123976737260818, -9.197030692575936e-08, -0.9966945648193359),
        		MouseHit = CFrame.new(66.08076477050781, 14.402545928955078, 192.009033203125, -0.9966946840286255, -0.05125772953033447, 0.06302662193775177, -0, 0.7758211493492126, 0.6309528946876526, -0.08123859763145447, 0.6288673877716064, -0.773256778717041)
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
