local globalSettings = {
  enabled = true
}
local camera = workspace.CurrentCamera
local utils = {} do
  function utils.CreateDrawing(type, data)
    local obj = Drawing.new(type)
    for i,v in pairs(data) do obj[i] = v end
    return obj
  end
  function utils.something(character)

  end

  function utils.BoxCorners(character)
    local CameraPosition = camera.CFrame.Position
    local CF, Size = character:GetBoundingBox()

    local function handler(front, back)
      local midpoint = Vector3.new((front.X + back.X) / 2, front.Y, (front.Z + back.Z) / 2)

      local blank = (front - front.Position)

      return blank + midpoint
    end

    local front = {
      CF * CFrame.new(-Size.X / 2, Size.Y / 2, -Size.Z / 2),
      CF * CFrame.new(Size.X / 2, Size.Y / 2, -Size.Z / 2),
      CF * CFrame.new(-Size / 2),
      CF * CFrame.new(Size.X / 2, -Size.Y / 2, -Size.Z / 2)
    }
    local back = {
      CF * CFrame.new(-Size.X / 2, Size.Y / 2, Size.Z / 2),
      CF * CFrame.new(Size / 2),
      CF * CFrame.new(-Size.X / 2, -Size.Y / 2, Size.Z / 2),
      CF * CFrame.new(Size.X / 2, -Size.Y / 2, Size.Z / 2)
    }
    local points = {}
    for i=1,4 do points[i] = handler(front[i], back[i]) end

    local points2d = {}
    for _, point in pairs(points) do
      local pointPos, onScreen = camera:WorldToViewportPoint(point.Position)
      if not onScreen then return false end

      table.insert(points2d, Vector2.new(pointPos.X, pointPos.Y))
    end

    return points2d
  end
end

local box = {}
box.__index = box

box.isEnemy = false
box.isTarget = false
box.isTargetTime = 0

function box.new(pID, isEnemy)
  return setmetatable({
    pID = pID,
    drawing = utils.CreateDrawing("Quad", {
      Visible = true,
      ZIndex = 0,
      Transparency = 1, 
      Color = Color3.fromRGB(255,255,255),
      Thickness = 3,
      Filled = false
    }),
    -- isEnemy = isEnemy
  }, box)
end

function box.Remove(self)
  self.drawing:Remove()
end

function box.Render(self)
  local character = _G.globals.gbl_sol_state.r15_models[self.pID]

  if not character then self.drawing.Visible = false return end
  if not globalSettings.enabled then self.drawing.Visible = false return end
  self.drawing.Visible = true

  local points = utils.BoxCorners(character)
  self.drawing.Visible = not points == false

  if not self.drawing.Visible then return end

  self.drawing.PointA = points[2]
  self.drawing.PointB = points[1]
  self.drawing.PointC = points[3]
  self.drawing.PointD = points[4]

  if self.isTarget and self.isTargetTime+5 < time() then self.isTarget = false end

  self.drawing.Color = self.isTarget and Color3.fromRGB(255,165,0) or (self.isEnemy and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0))
end

function box.target(self)
  self.isTarget = true
  self.isTargetTime = time()
end

return box, globalSettings