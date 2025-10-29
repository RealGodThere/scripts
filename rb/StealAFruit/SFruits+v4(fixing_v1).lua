local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local vim=game:GetService("VirtualInputManager")
local player=Players.LocalPlayer
local Bases=Workspace:WaitForChild("Bases")
local processedLabels={}

local function hideExtraTextLabels(obj)
	if obj:IsA("TextLabel") and (obj.Name=="Header" or obj.Name=="Rate" or obj.Name=="Mutation" or obj.Name=="Character") then
		obj.Visible=false
	end
end

local function processCharacterLabel(obj)
	if obj:IsA("BillboardGui") and obj.Name=="CharacterLabel" and not processedLabels[obj] then
		obj.AlwaysOnTop=true
		obj.Size=UDim2.new(8,0,45,0)
		obj.MaxDistance=15000
		for _,sub in pairs(obj:GetDescendants()) do hideExtraTextLabels(sub) end
		processedLabels[obj]=true
		obj.AncestryChanged:Connect(function(_,parent) if not parent then processedLabels[obj]=nil end end)
	end
end

for _,obj in pairs(Bases:GetDescendants()) do
	if obj:IsA("BillboardGui") and obj.Name=="LockedLabel" then
		obj.AlwaysOnTop=true
		obj.Size=UDim2.new(40,0,40,0)
		obj.MaxDistance=15000
	elseif obj:IsA("Part") and obj.Name=="LockBtn2" then
		obj:Destroy()
	else
		hideExtraTextLabels(obj)
	end
	processCharacterLabel(obj)
end

Bases.DescendantAdded:Connect(processCharacterLabel)

local function findAncestorByName(inst,name)
	local p=inst.Parent
	while p do
		if p.Name==name then return p end
		p=p.Parent
	end
	return nil
end

local function isUnderBases(hrp)
	if not hrp then return false end
	local p=hrp.Parent
	while p do
		if p==Bases then return true end
		p=p.Parent
	end
	return false
end

-- toggles controlled by GUI
local stealEnabled=true
local lockEnabled=true
local allianceEnabled=true

local function tryFixPrompt(prompt)
	if not stealEnabled or not prompt or not prompt:IsA("ProximityPrompt") or prompt.Name~="StealOrSell" or prompt.HoldDuration==0 then return end
	local hrp=findAncestorByName(prompt,"HumanoidRootPart")
	if not hrp then return end
	if not hrp.Parent or hrp.Parent.Name~="CharacterModel" then return end
	if not isUnderBases(hrp) then return end
	pcall(function() prompt.HoldDuration=0 end)
end

local function scanExistingPrompts()
	for _,inst in ipairs(Bases:GetDescendants()) do
		if inst:IsA("ProximityPrompt") then tryFixPrompt(inst) end
	end
end
scanExistingPrompts()

Bases.DescendantAdded:Connect(function(inst)
	if inst:IsA("ProximityPrompt") then
		tryFixPrompt(inst)
	else
		task.defer(function()
			for _,d in ipairs(inst:GetDescendants()) do
				if d:IsA("ProximityPrompt") then tryFixPrompt(d) end
			end
		end)
	end
end)

local humanoid,playerPart
local function setupCharacter()
	local c=player.Character or player.CharacterAdded:Wait()
	humanoid=c:WaitForChild("Humanoid",10)
	playerPart=c:FindFirstChild("LeftFoot") or c:FindFirstChild("HumanoidRootPart")
end
setupCharacter()
player.CharacterAdded:Connect(function() task.wait(1) setupCharacter() end)

local function pressButton(btn)
	if not playerPart or not playerPart.Parent then return end
	if not btn or not btn:IsDescendantOf(Workspace) then return end
	pcall(function()
		firetouchinterest(playerPart,btn,0)
		task.wait(0.1)
		firetouchinterest(playerPart,btn,1)
	end)
end

local function checkAllBases()
	for _,base in pairs(Bases:GetChildren()) do
		local spawn=base:FindFirstChild("Spawn")
		if spawn and spawn:FindFirstChildWhichIsA("BillboardGui") and spawn:FindFirstChild("YourBase") then
			local btn=base:FindFirstChild("LockBtn")
			if btn then
				pressButton(btn)
				task.wait(0.2)
			end
		end
	end
end

task.spawn(function()
	while true do
		if lockEnabled and humanoid and humanoid.Health>0 then
			checkAllBases()
		end
		task.wait(1)
	end
end)

local targetID=9326004240
local REMOTE=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Server")
local function sendAlliance()
	REMOTE:FireServer("ConfirmAllyReq",targetID,"Accept")
	REMOTE:FireServer("SendAlliance",targetID)
end
local function breakAlliance()
	REMOTE:FireServer("BreakAlliance",targetID)
end

task.spawn(function()
	while true do
		if allianceEnabled then sendAlliance() end
		task.wait(10)
	end
end)

local serverFunc=ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ServerRemoteFunc")
local AttackServer=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AttackServer")
local autoAuraRunning=false
local swordsToEquip={"Clima Tact","Gravity Blade"}

local function getPlayerEntities()
	local e=Workspace:FindFirstChild("Entities")
	if not e then return nil end
	return e:FindFirstChild(player.Name)
end

local function hasTool(name)
	for _,loc in ipairs({player.Backpack,getPlayerEntities(),player.Character}) do
		if loc then
			for _,v in ipairs(loc:GetChildren()) do
				if v:IsA("Tool") and v.Name==name then return true end
			end
		end
	end
	return false
end

local function equipSword(name)
	if not serverFunc then return end
	if not hasTool(name) then
		pcall(function() serverFunc:InvokeServer("EquipOrUnequipSword",name) end)
	end
end

local function findMyBase()
	for _,b in ipairs(Bases:GetChildren()) do
		local s=b:FindFirstChild("Spawn")
		if s and s:FindFirstChild("YourBase") then return b end
	end
	return nil
end

local function teleportPlayerTo(pos)
	if not player or not player.Character then return false end
	local hrp=player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		pcall(function() if player.Character then player.Character:MoveTo(pos) end end)
		return false
	end
	pcall(function() hrp.CFrame=CFrame.new(pos) end)
	return true
end

local function tryActivatePrompt(prompt)
	if not prompt then return false end
	pcall(function()
		if typeof(fireproximityprompt)=="function" then
			fireproximityprompt(prompt)
		else
			prompt:InputHoldBegin()
			task.wait(0.05)
			prompt:InputHoldEnd()
		end
	end)
	return true
end

local function searchAndEquipFruitByName(name)
	local b = findMyBase()
	if not b then return end
	local f = b:FindFirstChild("Characters")
	if not f then return end
	for _, m in ipairs(f:GetChildren()) do
		local hrp = m:FindFirstChild("HumanoidRootPart", true)
		if hrp then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("TextLabel") and d.Text == name then
					if not hasTool(name) then
						local pos = hrp.Position + Vector3.new(0, 3, 0)
						local c = player.Character
						if c and c:FindFirstChild("HumanoidRootPart") then
							c.HumanoidRootPart.CFrame = CFrame.new(pos)
						else
							teleportPlayerTo(pos)
						end
						task.wait(0.5)
						for _, x in ipairs(hrp:GetDescendants()) do
							if x:IsA("ProximityPrompt") and x.Name == "Equip" then
								tryActivatePrompt(x)
								break
							end
						end
					end
					return
				end
			end
		end
	end
end

local function pressKey(k,h,a)
	vim:SendKeyEvent(true,k,false,game)
	task.wait(h or 0.1)
	vim:SendKeyEvent(false,k,false,game)
	task.wait(a or 0)
end

local function fireAttack(a,m,w,cf)
	local t={a,m,w}
	if cf then table.insert(t,{cf}) end
	AttackServer:FireServer(unpack(t))
end

local function spamAttack(a,m,w,cf,c)
	for _=1,c do
		fireAttack(a,m,w,cf)
		task.wait(0.1)
	end
end

-- =======================
-- ClearVFX system (v2)
-- =======================
local autoClearVFXEnabled = true
local autoClearVFXConnection = nil

local function ClearVFX()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local playerName = player.Name
	local vfxFolder = workspace:WaitForChild("AttackVfx")

	for _, vfx in ipairs(vfxFolder:GetChildren()) do
		if string.find(vfx.Name, playerName) or string.find(vfx.Name, "Buzz") then
			vfx:Destroy()
		end
	end
end

local function enableAutoClearVFX()
	if autoClearVFXConnection then return end
	local vfxFolder = workspace:FindFirstChild("AttackVfx") or Instance.new("Folder", workspace)
	vfxFolder.Name = "AttackVfx"

	autoClearVFXConnection = vfxFolder.ChildAdded:Connect(function()
		local attack = workspace:FindFirstChild("AttackVfx")
		if attack then
			attack:Destroy()
		end
	end)
end

local function disableAutoClearVFX()
	if autoClearVFXConnection then
		autoClearVFXConnection:Disconnect()
		autoClearVFXConnection = nil
	end
	
	if not workspace:FindFirstChild("AttackVfx") then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "AttackVfx"
		newFolder.Parent = workspace
	end
end

if autoClearVFXEnabled then
    enableAutoClearVFX()
end

local autoAuraRunning=false
local autoAuraCancel=false

local function runAutoAura()
	if autoAuraRunning then return end
	autoAuraRunning=true
	local char=player.Character or player.CharacterAdded:Wait()
	local hrp=char:WaitForChild("HumanoidRootPart")
	local original=hrp.CFrame
	local bCF=CFrame.new(-95.7972,-40.5677,748.3856,0.9995211,0,-0.030946,0,1,0,0.030946,0,0.9995211)
	local tCF=CFrame.new(14.6191,-40.5677,763.1363,0.999701,0,-0.0244519,0,1,0,0.0244519,0,0.999701)

	searchAndEquipFruitByName("Barrier")
	task.wait(0.5)
	equipSword("Clima Tact")
	hrp.CFrame=CFrame.new(1,-41,775)
	task.wait(0.2)
	spamAttack("Hold","Barrier Rotation","Barrier",bCF, 1)
	fireAttack("Release","Barrier Rotation","Barrier")
	spamAttack("Hold","Barrier Rotation","Barrier",bCF, 1)
	spamAttack("Hold","Tornado Tempo","Clima Tact",tCF, 1)
	fireAttack("Release","Tornado Tempo","Clima Tact")
	fireAttack("Hold","Tornado Tempo","Clima Tact",tCF, 1)
	task.wait(1)
	searchAndEquipFruitByName("Dough")
	task.wait(0.5)
	equipSword("Night Blade")
	hrp.CFrame=original
	ClearVFX()
	autoAuraRunning=false
end

local function findYourBase()
	for _,b in pairs(Bases:GetChildren()) do
		local s=b:FindFirstChild("Spawn")
		if s and s:FindFirstChild("YourBase") then return b end
	end
end

local function teleportToLockBtn()
	local b=findYourBase()
	if not b then return end
	local l=b:FindFirstChild("LockBtn")
	if not l then return end
	local hrp=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame=l.CFrame+Vector3.new(0,3,0)
end

-- Attack binding left as Keybind 'T'
local function activateAttack()
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local args = {
		"Charge",
		"Dough Buzzcut",
		"Dough",
		{
			RootCFrame = rootPart.CFrame
		}
	}
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AttackServer"):FireServer(unpack(args))
end

-- =======================
-- Teleport / Fruit picker (TP)
-- =======================
local TOGGLE_KEY_TP=Enum.KeyCode.KeypadFour
local SWITCH_KEY_TP=Enum.KeyCode.KeypadFive
local TOUCH_DURATION_TP=0.1
local tp_humanoid,tp_playerPart
local tp_fruitList = {}
local lastValidFruitList = {}
local lastBaseName = nil
local createdZones = {}
local tp_selectedIndex=1
local BaseParams={
	["b1"]={Size=Vector3.new(280,200,140),Offset=Vector3.new(150,-7,-201),Base="2"},
	["b2"]={Size=Vector3.new(280,200,140),Offset=Vector3.new(150,-7,-58),Base="4"},
	["b3"]={Size=Vector3.new(280,200,140),Offset=Vector3.new(150,-7,85),Base="6"},
	["b4"]={Size=Vector3.new(280,200,140),Offset=Vector3.new(-190,10,85),Base="5"},
	["b5"]={Size=Vector3.new(280,200,140),Offset=Vector3.new(-190,10,-58),Base="3"},
	["b6"]={Size=Vector3.new(280,200,140),Offset=Vector3.new(-190,10,-201),Base="1"}
}

local function setupCharacter_TP()
	local c=player.Character or player.CharacterAdded:Wait()
	tp_humanoid=c:WaitForChild("Humanoid",10)
	tp_playerPart=c:WaitForChild("Head",10)
end
setupCharacter_TP()
player.CharacterAdded:Connect(function() task.wait(1) setupCharacter_TP() end)

local function createZones_TP()
	for _,p in pairs(BaseParams) do
		local z=Instance.new("Part")
		z.Anchored=true
		z.CanCollide=false
		z.Transparency=1
		z.Size=p.Size
		z.CFrame=CFrame.new(p.Offset)
		z.Parent=Workspace
		table.insert(createdZones,{Part=z,Base=p.Base})
	end
end
createZones_TP()

local function createDraggableUI_TP()
	local g=Instance.new("ScreenGui")
	g.Name="FruitIndicator"
	g.ResetOnSpawn=false
	g.Parent=player:WaitForChild("PlayerGui")
	local f=Instance.new("Frame")
	f.Size=UDim2.new(0,350,0,50)
	f.Position=UDim2.new(0,780,0,835)
	f.BackgroundTransparency=0.3
	f.BackgroundColor3=Color3.fromRGB(0,0,0)
	f.BorderSizePixel=0
	f.Active=true
	f.Draggable=true
	f.Parent=g
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,0,1,0)
	l.BackgroundTransparency=1
	l.TextColor3=Color3.fromRGB(255,255,255)
	l.TextScaled=true
	l.Font=Enum.Font.SourceSansBold
	l.Text="..."
	l.Parent=f
	return l
end

local tp_indicator = createDraggableUI_TP()

local function updateIndicator_TP(t,c)
	if tp_indicator then
		tp_indicator.Text=t
		tp_indicator.TextColor3=c or Color3.fromRGB(255,255,255)
	end
end

local function parsePrice_TP(t)
	if not t or t=="" then return 0 end
	t = string.upper(t):gsub(",",""):gsub("%s+","")
	local n,s = t:match("(%d+%.?%d*)(%a*)")
	n = tonumber(n) or 0
	if s=="K" then n = n * 1e3
	elseif s=="M" then n = n * 1e6
	elseif s=="B" then n = n * 1e9 end
	return n
end

local function getCurrentBase_TP()
	local c=player.Character or player.CharacterAdded:Wait()
	local hrp=c:WaitForChild("HumanoidRootPart")
	for _,z in pairs(createdZones) do
		local p=z.Part
		local s=p.Size/2
		local pos=p.Position
		local h=hrp.Position
		if math.abs(h.X-pos.X)<=s.X and math.abs(h.Y-pos.Y)<=s.Y and math.abs(h.Z-pos.Z)<=s.Z then
			return Bases:FindFirstChild(z.Base)
		end
	end
end

local function isYourBase_TP(b)
	local s=b:FindFirstChild("Spawn")
	if not s then return false end
	local y=s:FindFirstChild("YourBase")
	return y and y:IsA("BillboardGui")
end

local function collectAllFruits_TP(b)
	local t={}
	local c=b:FindFirstChild("Characters")
	if not c then return t end
	for _,f in pairs(c:GetChildren()) do
		local m=f:FindFirstChild("CharacterModel")
		if m then
			local l=m:FindFirstChild("CharacterLabel")
			if l and l:IsA("BillboardGui") then
				local p=l:FindFirstChild("Price")
				local u=l:FindFirstChild("Unstealable")
				local n=l:FindFirstChild("Character")
				if p and p:IsA("TextLabel") and not(u and u:IsA("TextLabel")) then
					local pr=parsePrice_TP(p.Text)
					local name = n and n:IsA("TextLabel") and n.Text or "Unknown"
					table.insert(t,{model=m,folder=f.Name,priceText=p.Text,priceValue=pr,name=name})
				end
			end
		end
	end
	table.sort(t,function(a,b) return a.priceValue>b.priceValue end)
	return t
end

local function previewTarget_TP()
	local b = getCurrentBase_TP()
	if b then
		if isYourBase_TP(b) then return end
		tp_fruitList = collectAllFruits_TP(b)
		if #tp_fruitList>0 then
			lastValidFruitList = tp_fruitList
			lastBaseName = b.Name
			if tp_selectedIndex > #tp_fruitList then tp_selectedIndex = 1 end
			local t = tp_fruitList[tp_selectedIndex]
			updateIndicator_TP(t.name.." | "..t.priceText.." | "..t.folder.." ("..tp_selectedIndex.."/"..#tp_fruitList..")", Color3.fromRGB(0,255,255))
			return
		end
	end
	if #lastValidFruitList>0 then
		tp_fruitList = lastValidFruitList
		local t = tp_fruitList[tp_selectedIndex]
		updateIndicator_TP("Last saved : "..t.name.." | "..t.priceText, Color3.fromRGB(0,255,200))
	else
		updateIndicator_TP("No saved fruits", Color3.fromRGB(255,255,0))
	end
end

local function teleportAndEquip_TP()
	if #tp_fruitList==0 then return end
	local t = tp_fruitList[tp_selectedIndex]
	if not t or not t.model then return end
	local hrp = t.model:FindFirstChild("HumanoidRootPart")
	local c = player.Character or player.CharacterAdded:Wait()
	local my = c:WaitForChild("HumanoidRootPart")
	if hrp and my then
		updateIndicator_TP("Teleporting to: "..t.name.." | "..t.priceText, Color3.fromRGB(0,255,0))
		-- place slightly above target
		my.CFrame = hrp.CFrame + Vector3.new(0,3,0)
		task.wait(0.1)
		-- try to activate many times (robust)
		for _,x in ipairs(hrp:GetDescendants()) do
			if x:IsA("ProximityPrompt") and x.Name=="StealOrSell" or (x:IsA("ProximityPrompt") and x.Name=="Equip") then
				tryActivatePrompt(x)
				task.wait(0.12)
			end
		end
	end
end

-- preview loop
task.spawn(function()
	while true do
		previewTarget_TP()
		task.wait(1)
	end
end)

-- auto collect (press collect in your base)
local function pressCollect()
	if not playerPart or not playerPart.Parent then return end
	local base = findYourBase()
	if not base then return end
	local collect = base:FindFirstChild("Collect")
	if not collect or not collect:IsA("BasePart") then return end
	pcall(function()
		firetouchinterest(playerPart, collect, 0)
		task.wait(TOUCH_DURATION_TP)
		firetouchinterest(playerPart, collect, 1)
	end)
end

task.spawn(function()
	while true do
		if humanoid and humanoid.Health > 0 then
			pressCollect()
		end
		task.wait(0.2)
	end
end)

task.spawn(function()
	while true do
		if humanoid and humanoid.Health <= 0 then
			while humanoid.Health <= 0 do
				task.wait(1)
			end
			setupCharacter()
		end
		task.wait(0.5)
	end
end)

-- =======================
-- SpamRadiant function
-- =======================
local function SpamRadiant()
    task.spawn(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")

        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.V, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.V, false, game)

        for i = 1, 30 do
            local args = {
                "Charge",
                "Radiant Tempest",
                "LightV2",
                {
                    RootCFrame = CFrame.new(
                        -104.1279067993164, -13.342497825622559, -57.480098724365234,
                        -0.0027732616290450096, 1.1818434231258834e-08, 0.9999961256980896,
                        -8.443401355862079e-08, 1, -1.205263799874956e-08,
                        -0.9999961256980896, -8.446711774467985e-08, -0.0027732616290450096
                    ),
                    MouseHit = CFrame.new(
                        -119.46944427490234, -16.900001525878906, -62.80809783935547,
                        0.0732104703783989, -0.34043553471565247, 0.9374135136604309,
                        0, 0.9399358630180359, 0.34135153889656067,
                        -0.9973165392875671, -0.0249905064702034, 0.06881313771009445
                    )
                }
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
                :WaitForChild("AttackServer"):FireServer(unpack(args))
            task.wait(0.1)
        end
    end)
end

-- =======================
-- GUI for toggles (K,L,Y,R)
-- style preserved from original: black, semi-transparent, draggable
-- =======================
local function createBindableGUI()
	local gui=Instance.new("ScreenGui")
	gui.Name="BindStatusGUI"
	gui.ResetOnSpawn=false
	gui.Parent=player:WaitForChild("PlayerGui")

	local frame=Instance.new("Frame")
	frame.Size=UDim2.new(0,200,0,225)
	frame.Position=UDim2.new(0,1400,0,200)
	frame.BackgroundColor3=Color3.fromRGB(20,20,20)
	frame.BackgroundTransparency=0.3
	frame.BorderSizePixel=0
	frame.Active=true
	frame.Draggable=true
	frame.Parent=gui

	local binds={
		{key="J", name="SpamRadiant", state=function() return false end, toggle=SpamRadiant},
		{key="K",name="FastSteal", state=function() return stealEnabled end, toggle=function()
			stealEnabled = not stealEnabled
			if stealEnabled then scanExistingPrompts() end
		end},
		{key="L",name="BaseLock", state=function() return lockEnabled end, toggle=function()
			lockEnabled = not lockEnabled
		end},
		{key="Y",name="AllyFriend", state=function() return allianceEnabled end, toggle=function()
			allianceEnabled = not allianceEnabled
			if not allianceEnabled then breakAlliance() end
		end},
		{key="P", name="ClearAnim", state=function() return autoClearVFXEnabled end, toggle=function()
			autoClearVFXEnabled = not autoClearVFXEnabled
			if autoClearVFXEnabled then
				enableAutoClearVFX()
			else
				disableAutoClearVFX()
			end
		end},
		{key="R",name="Killaura", state=function() return autoAuraRunning end, toggle=function()
			if autoAuraRunning then
				autoAuraCancel=true
			else
				task.spawn(runAutoAura)
			end
		end}
	}

	local labels={}
	for i,bind in ipairs(binds) do
		local btn=Instance.new("TextButton")
		btn.Size=UDim2.new(1,-10,0,30)
		btn.Position=UDim2.new(0,5,0,(i-1)*35+5)
		btn.BackgroundTransparency=0.1
		btn.BackgroundColor3=Color3.fromRGB(0,0,0)
		btn.TextColor3=Color3.fromRGB(255,0,0)
		btn.TextScaled=true
		btn.Font=Enum.Font.SourceSansBold
		btn.Text=bind.name..": OFF"
		btn.Parent=frame
		labels[bind.key]=btn
		btn.MouseButton1Click:Connect(function()
			bind.toggle()
		end)
        btn.MouseEnter:Connect(function()
			btn.BackgroundTransparency = 0.5
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundTransparency = 0.1
			btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		end)
	end

	local function updateStatus()
		for _,bind in ipairs(binds) do
			local lbl=labels[bind.key]
			local on=bind.state()
			lbl.Text=bind.name..": "..(on and "ON" or "OFF")
			lbl.TextColor3= on and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
		end
	end

	task.spawn(function()
		while true do
			updateStatus()
			task.wait(1)
		end
	end)
end

createBindableGUI()

-- =======================
-- GUI: MaxFruitsAllBases
-- =======================
local function createMaxFruitGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MaxFruitGUI"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 240)
	frame.Position = UDim2.new(0, 1600, 0, 200)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = gui

	local baseOrder = {2, 4, 6, 5, 3, 1}
	local labels = {}

	for idx, baseNum in ipairs(baseOrder) do
		local lbl = Instance.new("TextButton")
		lbl.Size = UDim2.new(1, -10, 0, 30)
		lbl.Position = UDim2.new(0, 5, 0, (idx - 1) * 35 + 5)
		lbl.BackgroundTransparency = 0.1
		lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
		lbl.TextScaled = true
		lbl.Font = Enum.Font.SourceSansBold
		lbl.Text = "Base " .. baseNum .. " MaxFruit: ..."
		lbl.Parent = frame
		labels[baseNum] = lbl

		lbl.MouseButton1Click:Connect(function()
			local baseKey
			for key, val in pairs(BaseParams) do
				if val.Base == tostring(baseNum) then
					baseKey = key
					break
				end
			end
			if not baseKey then return end

			local baseParam = BaseParams[baseKey]
			local base = Bases:FindFirstChild(baseParam.Base)
			if not base then return end
			if isYourBase_TP(base) then
				updateIndicator_TP("Your Base", Color3.fromRGB(255, 80, 80))
				return
			end

			local fruits = collectAllFruits_TP(base)
			if #fruits > 0 then
				lastValidFruitList = fruits
				tp_fruitList = fruits
				tp_selectedIndex = 1
                updateIndicator_TP(fruits[1].name .. " | " .. fruits[1].priceText, Color3.fromRGB(0, 255, 200))
				previewTarget_TP()
			end
		end)

		lbl.MouseEnter:Connect(function()
			lbl.BackgroundTransparency = 0.5
			lbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		end)
		lbl.MouseLeave:Connect(function()
			lbl.BackgroundTransparency = 0.1
			lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		end)
	end

	local function updateMaxFruits()
		for key, param in pairs(BaseParams) do
			local base = Bases:FindFirstChild(param.Base)
			if not base then continue end

			if isYourBase_TP(base) then
				labels[tonumber(param.Base)].Text = "YourBase"
				labels[tonumber(param.Base)].TextColor3 = Color3.fromRGB(255, 50, 50)
			else
				local fruits = collectAllFruits_TP(base)
				if #fruits > 0 then
					local f = fruits[1]
					labels[tonumber(param.Base)].Text = " MaxFruit: " .. f.name .. " | " .. f.priceText
					labels[tonumber(param.Base)].TextColor3 = Color3.fromRGB(255, 255, 0)
				else
					labels[tonumber(param.Base)].Text = " MaxFruit: None"
					labels[tonumber(param.Base)].TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end
		end
	end

	task.spawn(function()
		while true do
			updateMaxFruits()
			task.wait(1)
		end
	end)
end

createMaxFruitGUI()


-- =======================
-- Key binds left as requested: T, M, Keypad4, Keypad5
-- =======================
UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.T then
		activateAttack()
	elseif i.KeyCode == Enum.KeyCode.M then
		teleportToLockBtn()
	elseif i.KeyCode == Enum.KeyCode.KeypadFour then
		teleportAndEquip_TP()
	elseif i.KeyCode == Enum.KeyCode.KeypadFive then
		tp_selectedIndex = tp_selectedIndex + 1
		if tp_selectedIndex > #tp_fruitList then tp_selectedIndex = 1 end
		previewTarget_TP()
	end
end)
