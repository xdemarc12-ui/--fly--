-- FLY v3.4 | Respawn Fix + Space Ascend
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CONFIG = {
    keybind = Enum.KeyCode.X,
    maxSpeed = 25,
    verticalSpeed = 25,
    acceleration = 0.3,
    deceleration = 0.8,
}

local volando = false
local speed = 0
local ctrl = {f=0,b=0,l=0,r=0}
local lastctrl = {f=0,b=0,l=0,r=0}
local conns = {}

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function limpiarConexiones()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
end

local function limpiarTodoElFly()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "FlyLV" or obj.Name == "FlyAO" 
           or obj.Name == "FlyAtt" or obj.Name == "FlyBV" 
           or obj.Name == "FlyBG" then
            pcall(function() obj:Destroy() end)
        end
    end
end

local function desactivar()
    volando = false
    speed = 0
    ctrl = {f=0,b=0,l=0,r=0}
    lastctrl = {f=0,b=0,l=0,r=0}
    limpiarConexiones()
    limpiarTodoElFly()
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    print("[Fly v3.4] OFF")
end

local function activar()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = getRoot(char)
    if not hum or not root then return end

    limpiarConexiones()
    limpiarTodoElFly()

    volando = true
    speed = 0
    ctrl = {f=0,b=0,l=0,r=0}
    lastctrl = {f=0,b=0,l=0,r=0}

    hum.PlatformStand = true

    local att = Instance.new("Attachment")
    att.Name = "FlyAtt"
    att.Parent = root

    local lv = Instance.new("LinearVelocity")
    lv.Name = "FlyLV"
    lv.Attachment0 = att
    lv.MaxForce = 1e5
    lv.VectorVelocity = Vector3.new(0,0,0)
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.Parent = root

    local ao = Instance.new("AlignOrientation")
    ao.Name = "FlyAO"
    ao.Attachment0 = att
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.MaxTorque = 1e5
    ao.Responsiveness = 200
    ao.Parent = root

    local ic = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.W then ctrl.f=1 end
        if input.KeyCode == Enum.KeyCode.S then ctrl.b=1 end
        if input.KeyCode == Enum.KeyCode.A then ctrl.l=1 end
        if input.KeyCode == Enum.KeyCode.D then ctrl.r=1 end
    end)
    table.insert(conns, ic)

    local ie = UIS.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then ctrl.f=0 end
        if input.KeyCode == Enum.KeyCode.S then ctrl.b=0 end
        if input.KeyCode == Enum.KeyCode.A then ctrl.l=0 end
        if input.KeyCode == Enum.KeyCode.D then ctrl.r=0 end
    end)
    table.insert(conns, ie)

    local loop = RunService.RenderStepped:Connect(function()
        if not volando then return end
        local c = LP.Character
        if not c then desactivar(); return end
        local h = c:FindFirstChildOfClass("Humanoid")
        local r = getRoot(c)
        if not h or not r or h.Health <= 0 then desactivar(); return end

        local lvR = r:FindFirstChild("FlyLV")
        local aoR = r:FindFirstChild("FlyAO")
        if not lvR or not aoR then desactivar(); return end

        h.PlatformStand = true

        local moviendo = (ctrl.l+ctrl.r ~= 0) or (ctrl.f+ctrl.b ~= 0)
        if moviendo then
            speed = math.min(speed + CONFIG.acceleration, CONFIG.maxSpeed)
            lastctrl = {f=ctrl.f, b=ctrl.b, l=ctrl.l, r=ctrl.r}
        else
            speed = math.max(speed - CONFIG.deceleration, 0)
        end

        local look = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector
        local f = moviendo and ctrl.f or lastctrl.f
        local b = moviendo and ctrl.b or lastctrl.b
        local l = moviendo and ctrl.l or lastctrl.l
        local r2 = moviendo and ctrl.r or lastctrl.r

        local dir = (look * (f - b)) + (right * (r2 - l))
        dir = Vector3.new(dir.X, 0, dir.Z)

        -- Espacio para subir
        local verticalSpeed = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            verticalSpeed = CONFIG.verticalSpeed
        end

        if dir.Magnitude > 0 then
            lvR.VectorVelocity = Vector3.new(
                dir.Unit.X * speed,
                verticalSpeed,
                dir.Unit.Z * speed
            )
        else
            lvR.VectorVelocity = Vector3.new(0, verticalSpeed, 0)
        end

        aoR.CFrame = CFrame.new(r.Position, r.Position + look)
    end)
    table.insert(conns, loop)

    print("[Fly v3.4] ON | X toggle | Space subir")
end

-- Toggle
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.keybind then
        if volando then desactivar() else activar() end
    end
end)

-- Respawn fix
LP.CharacterAdded:Connect(function(char)
    limpiarTodoElFly()
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    hum.PlatformStand = false
    task.wait(0.3)
    if volando then activar() end
end)

-- Si ya hay personaje al cargar
if LP.Character then
    task.spawn(function()
        local hum = LP.Character:WaitForChild("Humanoid", 10)
        if hum and volando then activar() end
    end)
end

print("[Fly v3.4] Cargado | X toggle | Respawn fix")
