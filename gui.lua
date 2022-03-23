loadstring(game:HttpGet("https://raw.githubusercontent.com/Serophots/frontlines_gui/main/game_vars.lua"))()
local box, boxSettings = loadstring(game:HttpGet("https://raw.githubusercontent.com/Serophots/frontlines_gui/main/box.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Serophots/my-uilib/main/uilib_main.lua"))()
UI = UI.init("Frontlines", "v1.0.0", "Serophots", "FRL")

--FOV circle
local circle = Drawing.new("Circle") do
  circle.Thickness = 1
  circle.NumSides = 360
  circle.Radius = 60
  circle.Filled = false
  circle.Visible = false
  circle.Color = Color3.fromRGB(255,165,0)
end

local TabAim = UI:AddTab("Aim", "Silent Aim") do
  local SectionSilentAim = TabAim:AddSection("Silent Aim") do
    SectionSilentAim:AddToggle({
      title = "Enable Silent Aim"
    }):AddToggle({
      title = "Show FOV circle"
    })

    SectionSilentAim:AddSlider({
      title = "FOV Radius",
      values = { min=10, max=250, default=circle.Radius },
      round = 1
    })

    SectionSilentAim:AddDropdown({
      title = "targetPart", --doesn't show on GUI, used for UI.values
      placeholder = "Target part",
      options = {"Head", "UpperTorso", "HumanoidRootPart", "LeftUpperLeg", "RightUpperLeg", "LeftUpperArm", "RightUpperArm"},
      default = 1
    })
  end
end
local TabVisuals = UI:AddTab("Visuals", "ESP") do
  local SectionESP = TabVisuals:AddSection("ESP") do
    SectionESP:AddToggle({
      title = "Enable ESP",
      checked = true,
    }):AddToggle({
      title = "Show aimbot target",
      checked = true,
    })
  end
end

--Script

--Vars
local esp = {}
local FriendlyRaycastParams = RaycastParams.new()
FriendlyRaycastParams.IgnoreWater = true; FriendlyRaycastParams.CollisionGroup = "FRIENDLY_PROJECTILE"
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiInset = game:GetService("GuiService"):GetGuiInset()
local UISilentAim = UI.values["Aim"]["Silent Aim"]
local cliID = _G.globals.cli_state.id

--FOV Circle update
RunService.RenderStepped:Connect(function()
  circle.Position = UIS:GetMouseLocation()
  circle.Visible = UI.values["Aim"]["Silent Aim"]["Show FOV circle"]
  circle.Radius = UI.values["Aim"]["Silent Aim"]["FOV Radius"]
end)

--Utility functions for silent aim
--fpv = current soldier
--cli = client
local function isVisible(chest, part)
  local hit = workspace:Raycast(chest.Position, part.Position-chest.Position, FriendlyRaycastParams)
  if hit == nil then return false end
  if hit.Instance == nil then return false end
  return hit.Instance:IsDescendantOf(part.Parent)
end
local function isDead(pID)
  return _G.globals.gbl_sol_healths[pID] == 0
end
local function isAlive(pID)
  return not isDead(pID)
end
local function getEnemyPlayers()
  local enemies = {}
  local cliTeam = _G.globals.cli_teams[cliID]
  for pID, team in pairs(_G.globals.cli_teams) do
    if team ~= 0 and pID ~= cliID then
      if cliTeam ~= team and isAlive(pID) then
        enemies[pID] = _G.globals.gbl_sol_state.r15_models[pID]
      end
    end
  end
  return enemies
end
local function getClosestPlayer(chest)
  local ID
  local closest
  local distanceToMouse = UISilentAim["FOV Radius"]
  for sID, rig in pairs(getEnemyPlayers()) do
    local target = rig:FindFirstChild(UISilentAim["targetPart"])
    if isVisible(chest, target) then
      local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(target.Position)
      pos = Vector2.new(pos.X, pos.Y) - GuiInset
      if onScreen then
        local dist = (pos - UIS:GetMouseLocation()).Magnitude
        if dist <= distanceToMouse then
          closest = target
          distanceToMouse = dist
          esp[sID]:target()
        end
      end
    end
  end
  return closest, distanceToMouse
end

--Silent aim hook
local __index
__index = hookmetamethod(game, "__index", function(Self, key)
  if not checkcaller() and key == "CFrame" and UI.values["Aim"]["Silent Aim"]["Enable Silent Aim"] then
    local chest = _G.globals.fpv_sol_instances.chest
    if Self == chest and chest ~= nil then
      local target, dist = getClosestPlayer(chest)
      if target ~= nil then
        return CFrame.new(chest.Position, target.Position)
      end
    end
  end
  return __index(Self, key)
end)

--ESP util functions
local _t = 600
local function taskID()
  _t = _t + 1
  return _t
end
--ESP Connections

do --ESP
  for pID, name in pairs(_G.globals.cli_names) do
    if pID ~= cliID then
      esp[pID] = box.new(pID)
      esp[pID].isEnemy = _G.globals.cli_teams[cliID] ~= _G.globals.cli_teams[pID]
    end
  end
  local S_ADD_CLIENT = _G.utils.gbus.EVENT_ENUM.S_ADD_CLIENT
  local S_REMOVE_CLIENT = _G.utils.gbus.EVENT_ENUM.S_REMOVE_CLIENT
  local S_SET_CLI_TEAM = _G.utils.gbus.EVENT_ENUM.S_SET_CLI_TEAM
  local DEFAULT_PRIO = _G.utils.gbus.DEFAULT_PRIO
  _G.utils.gbus.add_task(S_ADD_CLIENT, taskID(), DEFAULT_PRIO, function(pID)
    esp[pID] = box.new(pID)
    esp[pID].isEnemy = _G.globals.cli_teams[cliID] ~= _G.globals.cli_teams[pID]
  end)
  _G.utils.gbus.add_task(S_REMOVE_CLIENT, taskID(), DEFAULT_PRIO, function(pID)
    esp[pID]:Remove()
    esp[pID] = nil
  end)
  _G.utils.gbus.add_task(S_SET_CLI_TEAM, taskID(), DEFAULT_PRIO, function(pID, team)
    if team == 0 or esp[pID] == nil then return end
    -- esp[pID]:setIsEnemy(_G.globals.cli_teams[cliID] ~= team)
    esp[pID].isEnemy = _G.globals.cli_teams[cliID] ~= team
  end)
end

RunService.RenderStepped:Connect(function()
  if UI.values["Visuals"]["ESP"]["Enable ESP"] then
    for pID,box in pairs(esp) do
      box:Render()
    end
  end
end)