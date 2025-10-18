local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local PhysicsService = game:GetService("PhysicsService")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local GRAY_SKY_ID = "rbxassetid://114666145996289"

local function setSmoothPlastic()
    local workspace = game:GetService("Workspace")
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.SmoothPlastic
        end
    end
end

setSmoothPlastic()

local PHYSICS_SLEEP_THRESHOLD = 0.01
local PHYSICS_MAX_STEERING_FORCE = 10
local COLLISION_GROUP_NAME = "OptimizedParts"

pcall(function()
    PhysicsService:CreateCollisionGroup(COLLISION_GROUP_NAME)
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP_NAME, COLLISION_GROUP_NAME, false)
end)

local function applyGraySky()
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            obj:Destroy()
        end
    end
    local sky = Instance.new("Sky")
    sky.SkyboxBk = GRAY_SKY_ID
    sky.SkyboxDn = GRAY_SKY_ID
    sky.SkyboxFt = GRAY_SKY_ID
    sky.SkyboxLf = GRAY_SKY_ID
    sky.SkyboxRt = GRAY_SKY_ID
    sky.SkyboxUp = GRAY_SKY_ID
    sky.SunAngularSize = 0
    sky.MoonAngularSize = 0
    sky.StarCount = 0  -- Remove stars
    sky.Parent = Lighting

    StarterGui:SetCore("SendNotification", {
        Title = "AntiLag Started";
        Text = "I hope you don't mind the game looks bad :]";
        Duration = 3;
    })
end

local function applyFullBright()
    Lighting.Brightness = 2
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.ExposureCompensation = 0
end

local function simplifyTerrain()
    if Terrain then
        Terrain.Decoration = false
        Terrain:SetAttribute("GrassDistance", 0)
        Terrain:SetAttribute("WaterWaveSize", 0)
        Terrain:SetAttribute("WaterWaveSpeed", 0)
        Terrain:SetAttribute("WaterTransparency", 1)
        Terrain:SetAttribute("WaterReflectance", 0)
    end
end

local function optimizeLighting()
    Lighting.FogEnd = 1000000
    Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(200, 200, 200)
    Lighting.ShadowSoftness = 0
    Lighting.GlobalShadows = false
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or 
           v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") or 
           v:IsA("Clouds") then
            v.Enabled = false
            v:Destroy()
        end
    end
end

local function removeReflectionsAndOptimize()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("SurfaceAppearance") then
                    child:Destroy()
                end
            end
            
            if obj:CanSetNetworkOwnership() then
                obj:SetNetworkOwnershipAuto()
            end
            
            pcall(function()
                PhysicsService:SetPartCollisionGroup(obj, COLLISION_GROUP_NAME)
            end)
            
            if obj:GetPropertyChangedSignal("AssemblyLinearVelocity") then
                obj.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                obj.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
            
        elseif obj:IsA("Reflection") then
            obj:Destroy()
        end
    end
end

local function optimizePhysics()
    settings().Rendering.QualityLevel = 1
    settings().Physics.PhysicsEnvironmentalThrottle = 2
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CastShadow = false
            
            if part:IsGrounded() then
                part.Anchored = false
                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

local function forcePhysicsSleep()
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            local velocity = part.AssemblyLinearVelocity.Magnitude
            local angularVelocity = part.AssemblyAngularVelocity.Magnitude
            
            if velocity < 0.1 and angularVelocity < 0.1 then
                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

local function applyCulling()
    local maxDistance = 400 -- Anything further than this gets hidden
    local fovAngle = 100 -- Field of view cone in degrees
    local cam = Camera

    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) and part.Transparency < 1 and part.CanCollide then
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            local dirToPart = (part.Position - cam.CFrame.Position).Unit
            local camDir = cam.CFrame.LookVector
            local angle = math.deg(math.acos(math.clamp(camDir:Dot(dirToPart), -1, 1)))
            local dist = (cam.CFrame.Position - part.Position).Magnitude

            if onScreen and angle < fovAngle and dist < maxDistance then
                part.LocalTransparencyModifier = 0
            else
                part.LocalTransparencyModifier = 1
            end
        end
    end
end

local function applya()
    applyGraySky()
    applyFullBright()
    simplifyTerrain()
    optimizeLighting()
    removeReflectionsAndOptimize()
    optimizePhysics()
    setSmoothPlastic()
end

applya()

task.spawn(function()
    while task.wait(10) do
        pcall(applya)
    end
end)

task.spawn(function()
    while task.wait(5) do
        pcall(forcePhysicsSleep)
    end
end)

RunService.RenderStepped:Connect(function()
    pcall(applyCulling)
end)
