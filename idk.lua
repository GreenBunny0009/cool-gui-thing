--// Preventing Multiple Processes

pcall(function()
	getgenv().Aimbot.Functions:Exit()
end)

--// Environment

getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

--// Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Camera = game:GetService("Workspace").CurrentCamera

--// Variables

local LocalPlayer = Players.LocalPlayer
local Title = "Nova Developer"
local FileNames = {"Aimbot", "Configuration.json", "Drawing.json"}
local Typing, Running, Animation, RequiredDistance, ServiceConnections = false, false, nil, 2000, {}

--// Support Functions

local mousemoverel = mousemoverel or (Input and Input.MouseMove)
local queueonteleport = queue_on_teleport or syn.queue_on_teleport

--// Script Settings

Environment.Settings = {
	SendNotifications = false,
	SaveSettings = false, -- Re-execute upon changing
	ReloadOnTeleport = true,
	Enabled = false,
	TeamCheck = false,
	AliveCheck = true,
	WallCheck = false, -- Laggy
	Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
	ThirdPerson = false, -- Uses mousemoverel instead of CFrame to support locking in third person (could be choppy)
	ThirdPersonSensitivity = 3, -- Boundary: 0.1 - 5
	TriggerKey = "Q",
	Toggle = false,
	LockPart = "Head" -- Body part to lock on
}

Environment.FOVSettings = {
	Enabled = false,
	Visible = false,
	Amount = 90,
	Color = "255, 255, 255",
	LockedColor = "255, 70, 70",
	Transparency = 0.5,
	Sides = 60,
	Thickness = 1,
	Filled = false
}

Environment.FOVCircle = Drawing.new("Circle")
Environment.Locked = nil

--// Core Functions

local function Encode(Table)
	if Table and type(Table) == "table" then
		local EncodedTable = HttpService:JSONEncode(Table)

		return EncodedTable
	end
end

local function Decode(String)
	if String and type(String) == "string" then
		local DecodedTable = HttpService:JSONDecode(String)

		return DecodedTable
	end
end

local function GetColor(Color)
	local R = tonumber(string.match(Color, "([%d]+)[%s]*,[%s]*[%d]+[%s]*,[%s]*[%d]+"))
	local G = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*([%d]+)[%s]*,[%s]*[%d]+"))
	local B = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*[%d]+[%s]*,[%s]*([%d]+)"))

	return Color3.fromRGB(R, G, B)
end

local function SendNotification(TitleArg, DescriptionArg, DurationArg)
	if Environment.Settings.SendNotifications then
		StarterGui:SetCore("SendNotification", {
			Title = TitleArg,
			Text = DescriptionArg,
			Duration = DurationArg
		})
	end
end

--// Functions

local function SaveSettings()
	if Environment.Settings.SaveSettings then
		if isfile(Title.."/"..FileNames[1].."/"..FileNames[2]) then
			writefile(Title.."/"..FileNames[1].."/"..FileNames[2], Encode(Environment.Settings))
		end

		if isfile(Title.."/"..FileNames[1].."/"..FileNames[3]) then
			writefile(Title.."/"..FileNames[1].."/"..FileNames[3], Encode(Environment.FOVSettings))
		end
	end
end

local function GetClosestPlayer()
	if not Environment.Locked then
		if Environment.FOVSettings.Enabled then
			RequiredDistance = Environment.FOVSettings.Amount
		else
			RequiredDistance = 2000
		end

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer then
				if v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
					if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
					if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
					if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

					local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
					local Distance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude

					if Distance < RequiredDistance and OnScreen then
						RequiredDistance = Distance
						Environment.Locked = v
					end
				end
			end
		end
	elseif (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).X, Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).Y)).Magnitude > RequiredDistance then
		Environment.Locked = nil
		Animation:Cancel()
		Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
	end
end

--// Typing Check

ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// Create, Save & Load Settings

if Environment.Settings.SaveSettings then
	if not isfolder(Title) then
		makefolder(Title)
	end

	if not isfolder(Title.."/"..FileNames[1]) then
		makefolder(Title.."/"..FileNames[1])
	end

	if not isfile(Title.."/"..FileNames[1].."/"..FileNames[2]) then
		writefile(Title.."/"..FileNames[1].."/"..FileNames[2], Encode(Environment.Settings))
	else
		Environment.Settings = Decode(readfile(Title.."/"..FileNames[1].."/"..FileNames[2]))
	end

	if not isfile(Title.."/"..FileNames[1].."/"..FileNames[3]) then
		writefile(Title.."/"..FileNames[1].."/"..FileNames[3], Encode(Environment.FOVSettings))
	else
		Environment.Visuals = Decode(readfile(Title.."/"..FileNames[1].."/"..FileNames[3]))
	end

	coroutine.wrap(function()
		while wait(10) and Environment.Settings.SaveSettings do
			SaveSettings()
		end
	end)()
else
	if isfolder(Title) then
		delfolder(Title)
	end
end

local function Load()
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			Environment.FOVCircle.Visible = false
		end

		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Settings.ThirdPerson then
				Environment.Settings.ThirdPersonSensitivity = math.clamp(Environment.Settings.ThirdPersonSensitivity, 0.1, 5)

				local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
				mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
			else
				if Environment.Settings.Sensitivity > 0 then
					Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
					Animation:Play()
				else
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
				end
			end

			Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.LockedColor)
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							Environment.Locked = nil
							Animation:Cancel()
							Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
						end
					else
						Running = true
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							Environment.Locked = nil
							Animation:Cancel()
							Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
					if not Environment.Settings.Toggle then
						Running = false
						Environment.Locked = nil
						Animation:Cancel()
						Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if not Environment.Settings.Toggle then
						Running = false
						Environment.Locked = nil
						Animation:Cancel()
						Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
					end
				end
			end)
		end
	end)
end

--// Functions

Environment.Functions = {}

function Environment.Functions:Exit()
	SaveSettings()

	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	if Environment.FOVCircle.Remove then Environment.FOVCircle:Remove() end

	getgenv().Aimbot.Functions = nil
	getgenv().Aimbot = nil
end

function Environment.Functions:Restart()
	SaveSettings()

	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		SendNotifications = true,
		SaveSettings = true, -- Re-execute upon changing
		ReloadOnTeleport = true,
		Enabled = true,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
		ThirdPerson = false,
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head" -- Body part to lock on
	}

	Environment.FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 90,
		Color = "255, 255, 255",
		LockedColor = "255, 70, 70",
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	}
end

--// Support Check

if not Drawing or not getgenv then
	SendNotification(Title, "Your exploit does not support this script", 3); return
end

--// Reload On Teleport

if Environment.Settings.ReloadOnTeleport then
	if queueonteleport then
		queueonteleport(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V2/main/Resources/Scripts/Main.lua"))
	else
		SendNotification(Title, "Your exploit does not support \"syn.queue_on_teleport()\"")
	end
end

--// Load

Load();





-- ESP settings
_G.ESPenabled = false
_G.Chamsenabled = false
-- Chams


local Chams = {}


function EnableChams()
    for _, character in ipairs(game:GetService("Players"):GetPlayers()) do
        local Cham = Instance.new("BoxHandleAdornment")
        Cham.Name = "Chams"
        Cham.Adornee = character.Character
        Cham.AlwaysOnTop = true
        Cham.ZIndex = 5
        Cham.Size = character.Character:GetExtentsSize()
        Cham.Color3 = Color3.new(1, 1, 1)
        Cham.Transparency = 0.5
        Cham.Visible = true
        Cham.Parent = character.Character
    end
end

-- disable ESP function
function DisableChams()
    for _, character in ipairs(game:GetService("Players"):GetPlayers()) do
        -- find the ESP box and remove it
        local Cham = character.Character:FindFirstChild("Chams")
        if Cham then
            Cham:Destroy()
        end
    end
end

-- color picker function
function ChangeColor(color)
    -- loop through all player characters
    for _, character in ipairs(game:GetService("Players"):GetPlayers()) do
        -- find the ESP box and change its color
        local Cham = character.Character:FindFirstChild("Chams")
        if Cham then
            Cham.Color3 = color
        end
    end
end

-- main script


getgenv().Config = {
	Invite = "Nova.wtf | 0.2b",
	Version = "0.2b",
}

getgenv().luaguardvars = {
	DiscordName = "BasedIsLegit#6889",
}

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Other/main/Lmao.lua"))()

library:init() -- Initalizes Library Do Not Delete This

local Nova = library.NewWindow({
	title = "Nova.wtf | 0.2b",
	size = UDim2.new(0, 525, 0, 650)
})

local tabs = {
    MainTab = Nova:AddTab("Main"),
	Settings = library:CreateSettingsTab(Nova),
    VisualTab = Nova:AddTab("Visuals")
}

-- 1 = Set Section Box To The Left
-- 2 = Set Section Box To The Right

local sections = {
	Section1 = tabs.MainTab:AddSection("Aimbot", 1),
	Section2 = tabs.MainTab:AddSection("Silent aimbot", 2),
    section3 = tabs.VisualTab:AddSection("ESP", 1)
}
-- Main

sections.Section1:AddToggle({
	enabled = true,
	text = "Aimbot",
	flag = "Aimbot",
	tooltip = "Locks your onto your enemies.",
	risky = false, -- turns text to red and sets label to risky
	callback = function(lol)
        if lol == true then
        print("Enabled!")
        Environment.Settings.Enabled = true
        else
        print("Disabled!")
        Environment.Settings.Enabled = false
        end
	end
})

sections.Section1:AddBind({
	text = "Aimbot bind",
	flag = "Aimbot bind",
	nomouse = true,
	noindicator = false,
	tooltip = "Changes the keybind of the Aimbot module.",
	mode = "toggle",
	bind = Enum.KeyCode.Q,
	risky = false,
	keycallback = function(KeybindAimbot)
        print(KeybindAimbot.Name)
        Environment.Settings.TriggerKey = KeybindAimbot.Name
	end
})

sections.Section1:AddList({
	enabled = true,
	text = "Aim part",
	flag = "Aim part",
	multi = false,
	tooltip = "Will set the Aimbot Aim part on your enemy.",
    risky = false,
    dragging = false,
    focused = false,
	value = "Head",
	values = {
		"Head",
		"UpperTorso"
	},
	callback = function(v)
	    Environment.Settings.LockPart = v
	end
})

--  sections.Section1:AddButton({
--	enabled = true,
--	text = "Button1",
--	flag = "Button_1",
--	tooltip = "Tooltip1",
--	risky = false,
--	confirm = false, -- shows confirm button
--	callback = function(v)
--	    print(v)
--	end
--})

sections.Section1:AddSeparator({
	text = "FOV"
})

--sections.Section1:AddSlider({
--	text = "Slider", 
--	flag = 'Slider_1', 
--	suffix = "", 
--	value = 0.000,
--	min = 0.1, 
--	max = 0.999,
--	increment = 0.001,
--	tooltip = "Tooltip1",
--	risky = false,
--	callback = function(v) 
--		print("Slider Value Is Now : ".. v)
--	end
--})

sections.Section1:AddToggle({
	enabled = true,
	text = "FOV",
	flag = "FOV",
	tooltip = "Will toggle the FOV circle.",
	risky = false, -- turns text to red and sets label to risky
	callback = function(lol)
        if lol == true then
        print("Enabled!")
        Environment.FOVSettings.Visible = true
        Environment.FOVSettings.Enabled = true
        else
        print("Disabled!")
        Environment.FOVSettings.Visible = false
        Environment.FOVSettings.Enabled = false
        end
	end
})

sections.Section1:AddBox({
    enabled = true,
    focused = true,
    text = "FOV size",
    input = "",
	flag = "FOV size",
	risky = false,
	callback = function(v)
	    print(v)
        Environment.FOVSettings.Amount = v
	end
})

--sections.Section1:AddText({
--   enabled = true,
--    text = "Text1",
--    flag = "Text_1",
--    risky = false,
--})


-- visuals

sections.section3:AddToggle({
	enabled = true,
	text = "Chams",
	flag = "Chams",
	tooltip = "Let's you see the enemies through walls.",
	risky = false, -- turns text to red and sets label to risky
	callback = function(lol)
if _G.Chamsenabled == true then
    EnableChams()
else
    DisableChams()
end
    if lol == false then
    _G.Chamsenabled = true
else
    _G.Chamsenabled = false
	end
end
})

library:SendNotification("Nova Hub has loaded!", 5, Color3.new(255, 0, 0))

--Window:SetOpen(true) -- Either Close Or Open Window