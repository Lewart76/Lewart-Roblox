-- Roblox Aimbot Script with Target Lock
-- This script provides an aimbot that locks onto a target until they're no longer valid

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Configuration
local Config = {
  Enabled = false,
  Key = Enum.KeyCode.Q,
  TeamCheck = true,
  TargetPart = "Head", -- The part to aim at (Head, HumanoidRootPart, etc.)
  FOV = 250, -- Field of view for initial target acquisition
  Sensitivity = 0.5, -- Lower = smoother, Higher = faster
  ShowFOV = true, -- Visual indicator of FOV
  FOVColor = Color3.fromRGB(255, 255, 255),
  LockOnTarget = nil -- Currently locked target
}

-- FOV Circle Drawing
local FOVCircle
if Config.ShowFOV and Drawing then
  FOVCircle = Drawing.new("Circle")
  FOVCircle.Visible = Config.Enabled
  FOVCircle.Radius = Config.FOV
  FOVCircle.Color = Config.FOVColor
  FOVCircle.Thickness = 1
  FOVCircle.Filled = false
  FOVCircle.Transparency = 1
end

-- Toggle function
local function toggleAimbot()
  Config.Enabled = not Config.Enabled
  if FOVCircle then
    FOVCircle.Visible = Config.Enabled
  end
  
  -- Reset locked target when disabling
  if not Config.Enabled then
    Config.LockOnTarget = nil
  end
  
  -- Notification
  local message = Config.Enabled and "Aimbot: ON" or "Aimbot: OFF"
  game.StarterGui:SetCore("SendNotification", {
    Title = "Aimbot",
    Text = message,
    Duration = 2
  })
end

-- Check if player is on the same team
local function isTeamMate(player)
  if not Config.TeamCheck then return false end
  
  return player.Team == LocalPlayer.Team and player.Team ~= nil
end

-- Check if player is valid target
local function isValidTarget(player)
  if player == LocalPlayer then return false end
  if not player.Character then return false end
  if not player.Character:FindFirstChild("Humanoid") then return false end
  if player.Character.Humanoid.Health <= 0 then return false end
  if isTeamMate(player) then return false end
  
  return true
end

-- Get closest player within FOV for initial target acquisition
local function getClosestPlayerInFOV()
  local closestPlayer = nil
  local shortestDistance = Config.FOV
  
  for _, player in pairs(Players:GetPlayers()) do
    if isValidTarget(player) then
      local targetPart = player.Character:FindFirstChild(Config.TargetPart)
      
      if targetPart then
        local screenPoint = Camera:WorldToScreenPoint(targetPart.Position)
        local vectorDistance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
        
        if vectorDistance < shortestDistance then
          closestPlayer = player
          shortestDistance = vectorDistance
        end
      end
    end
  end
  
  return closestPlayer
end

-- Update FOV circle position
if FOVCircle then
  RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
  end)
end

-- Check if current locked target is still valid
local function isLockedTargetValid()
  local target = Config.LockOnTarget
  
  if not target then return false end
  if not target.Parent then return false end -- Player left the game
  if not isValidTarget(target) then return false end
  if not target.Character:FindFirstChild(Config.TargetPart) then return false end
  
  return true
end

-- Main aimbot loop
RunService.RenderStepped:Connect(function()
  if Config.Enabled then
    -- Check if we have a locked target and if it's still valid
    if Config.LockOnTarget and isLockedTargetValid() then
      local targetPart = Config.LockOnTarget.Character[Config.TargetPart]
      local targetPosition = Camera:WorldToScreenPoint(targetPart.Position)
      
      -- Only aim if target is on screen
      if targetPosition.Z > 0 then
        local mousePosition = Vector2.new(Mouse.X, Mouse.Y)
        local aimPosition = Vector2.new(targetPosition.X, targetPosition.Y)
        
        -- Calculate the movement needed
        local movement = (aimPosition - mousePosition) * Config.Sensitivity
        
        -- Move the mouse
        mousemoverel(movement.X, movement.Y)
      end
    else
      -- No valid locked target, acquire a new one
      local newTarget = getClosestPlayerInFOV()
      if newTarget then
        Config.LockOnTarget = newTarget
        
        -- Notification for new target
        game.StarterGui:SetCore("SendNotification", {
          Title = "Target Locked",
          Text = "Locked onto " .. newTarget.Name,
          Duration = 1.5
        })
      end
    end
  end
end)

-- Input handling for toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
  if not gameProcessed and input.KeyCode == Config.Key then
    toggleAimbot()
    
    -- Reset locked target when toggling
    Config.LockOnTarget = nil
  end
end)

-- Player removal handling
Players.PlayerRemoving:Connect(function(player)
  if Config.LockOnTarget == player then
    Config.LockOnTarget = nil
    
    if Config.Enabled then
      game.StarterGui:SetCore("SendNotification", {
        Title = "Target Lost",
        Text = "Target left the game",
        Duration = 1.5
      })
    end
  end
end)

-- Initial notification
game.StarterGui:SetCore("SendNotification", {
  Title = "Aimbot Loaded",
  Text = "Press Q to toggle. Will lock onto targets.",
  Duration = 3
})
