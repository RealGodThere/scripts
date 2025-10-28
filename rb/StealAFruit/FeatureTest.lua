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
	for i = 1, 70 do
		local args = {
			"Charge",
			"String Fly",
			"String",
			{
				RootCFrame = CFrame.new(-1683.433349609375, 219.54563903808594, 22.77704429626465, 0.10835906863212585, 0, -0.9941118359565735, 0, 1, 0, 0.9941118359565735, 0, 0.10835906863212585),
				MouseHit = CFrame.new(-1673.288818359375, 215.7633514404297, 23.431644439697266, 0.10835667699575424, 0.47881585359573364, -0.871202826499939, 3.725290298461914e-09, 0.8763628602027893, 0.48165175318717957, 0.9941121339797974, -0.05219018831849098, 0.09495975077152252)
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
		local entities = workspace:FindFirstChild("Entities")
		if not entities then continue end
		local boss = entities:FindFirstChild("Light Boss")
		if boss and boss:FindFirstChild("Head") then
			if not bossExists then
				bossExists = true
				AttackBossOnce()
				while enabled and boss and boss.Parent == entities do
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hrp and boss:FindFirstChild("Head") then
						hrp.CFrame = boss.Head.CFrame + Vector3.new(0, 3, 0)
					end
					task.wait(0.1)
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
