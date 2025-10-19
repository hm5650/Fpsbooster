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
local PHYSICS_SLEEP_THRESHOLD = 0.01
local COLLISION_GROUP_NAME = "OptimizedParts"
local MAX_RENDER_DISTANCE = 100
local FOV_ANGLE = 90
local OPTIMIZATION_INTERVAL = 0.5
local CLEANUP_INTERVAL = 0.1

local OptimizedParts = {}
local OriginalProperties = {}
local Running = true

pcall(function()
    PhysicsService:CreateCollisionGroup(COLLISION_GROUP_NAME)
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP_NAME, COLLISION_GROUP_NAME, false)
end)

local function setSmoothPlastic()
    local player = Players.LocalPlayer
    
    local function handleInstance(instance)
        if player and player.Character and instance:IsDescendantOf(player.Character) then
            return
        end

        if instance:IsA("BasePart") then
            instance.Material = Enum.Material.SmoothPlastic
            instance.Reflectance = 0
        elseif instance:IsA("Texture") or instance:IsA("Decal") then 
            instance.Transparency = 1
        end
    end

    for _, instance in ipairs(Workspace:GetDescendants()) do
        handleInstance(instance)
    end
    
    Workspace.DescendantAdded:Connect(handleInstance)
end
setSmoothPlastic()

local function storeOriginalProperties(instance)
    if not OriginalProperties[instance] then
        OriginalProperties[instance] = {
            Material = instance.Material,
            Reflectance = instance.Reflectance,
            Transparency = instance.Transparency,
            CastShadow = instance.CastShadow
        }
    end
end

local function removePlayerAnimations()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                        track:Stop()
                    end
                    
                    local animator = humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        animator:Destroy()
                    end
                end
                
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Material = Enum.Material.SmoothPlastic
                        part.Reflectance = 0
                        part.CastShadow = false
                        
                        storeOriginalProperties(part)
                        pcall(function()
                            PhysicsService:SetPartCollisionGroup(part, COLLISION_GROUP_NAME)
                        end)
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or 
                           part:IsA("Smoke") or part:IsA("Fire") then
                        part.Enabled = false
                    end
                end
            end
        end
    end
end

local function optimizeUnanchoredParts()
    local unanchoredCount = 0
    local maxUnanchored = 50 -- Limit unanchored parts
    
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            unanchoredCount = unanchoredCount + 1
            
            if unanchoredCount > maxUnanchored then
                local distance = (part.Position - Camera.CFrame.Position).Magnitude
                if distance > MAX_RENDER_DISTANCE then
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    
                    if part.AssemblyLinearVelocity.Magnitude > 5 then
                        part.Anchored = true
                        task.delay(2, function()
                            if part and part.Parent then
                                part.Anchored = false
                            end
                        end)
                    end
                end
            end
            
            part.CanCollide = (distance or 0) < MAX_RENDER_DISTANCE
        end
    end
end

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
    sky.StarCount = 0
    sky.Parent = Lighting
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

    -- Remove any object that is a PostEffect
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then
            v:Destroy()
        end
    end
end

local function removeReflectionsAndOptimize()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            storeOriginalProperties(obj)
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("SurfaceAppearance") or child:IsA("Reflection") then
                    child:Destroy()
                end
            end
            
            if obj:CanSetNetworkOwnership() then
                obj:SetNetworkOwnershipAuto()
            end
            
            pcall(function()
                PhysicsService:SetPartCollisionGroup(obj, COLLISION_GROUP_NAME)
            end)
            
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end
    end
end

local function convertToLowPoly()
    local HttpService = game:GetService("HttpService")
    
    local replacementPrimitives = {
        "Ball", "Block", "Cylinder", "Wedge"
    }
    
    local complexMeshKeywords = {
        "mesh", "Mesh", "part", "Part", "model", "Model", 
        "detail", "Detail", "ornament", "Ornament",
        "decal", "Decal", "couch", "design", "Design"
    }
    
    local function shouldSimplify(part)
        if part:IsA("MeshPart") then
            return true
        end
        
        if part:IsA("Part") then
            -- Check if it has complex children or special materials
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("SpecialMesh") or child:IsA("BlockMesh") or 
                   child:IsA("CylinderMesh") or child:IsA("FileMesh") then
                    return true
                end
            end
            
            local partName = part.Name:lower()
            for _, keyword in ipairs(complexMeshKeywords) do
                if partName:find(keyword:lower()) then
                    return true
                end
            end
        end
        
        return false
    end
    
    local function simplifyMeshPart(meshPart)
        if not meshPart or not meshPart.Parent then return end
        
        local originalSize = meshPart.Size
        local originalCFrame = meshPart.CFrame
        local originalColor = meshPart.Color
        local originalMaterial = meshPart.Material
        local originalTransparency = meshPart.Transparency
        
        -- Create replacement part
        local replacement = Instance.new("Part")
        replacement.Name = "LowPoly_" .. meshPart.Name
        replacement.Size = originalSize
        replacement.CFrame = originalCFrame
        replacement.Color = originalColor
        replacement.Material = originalMaterial
        replacement.Transparency = originalTransparency
        replacement.Anchored = meshPart.Anchored
        replacement.CanCollide = meshPart.CanCollide
        replacement.CastShadow = false
        replacement.Material = Enum.Material.SmoothPlastic
        
        if meshPart:IsA("MeshPart") and meshPart.MeshId ~= "" then
            local meshSize = meshPart.Size
            local aspectRatio = meshSize.Y / meshSize.X
            
            if aspectRatio > 2 then
                replacement.Shape = Enum.PartType.Cylinder
            elseif math.abs(meshSize.X - meshSize.Y) < 0.1 and math.abs(meshSize.Y - meshSize.Z) < 0.1 then
                replacement.Shape = Enum.PartType.Ball
            else
                replacement.Shape = Enum.PartType.Block
            end
        else
            replacement.Shape = Enum.PartType.Block
        end
        
        for _, child in ipairs(meshPart:GetChildren()) do
            if child:IsA("Weld") or child:IsA("WeldConstraint") or 
               child:IsA("Attachment") or child:IsA("Motor6D") then
                child:Clone().Parent = replacement
            end
        end
        
        replacement.Parent = meshPart.Parent
        meshPart:Destroy()
        
        return replacement
    end
    
    local function simplifyModel(model)
        if not model:IsA("Model") and not model:IsA("Folder") then
            return
        end
        
        local partsToSimplify = {}
        
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("MeshPart") or descendant:IsA("Part") then
                if shouldSimplify(descendant) then
                    table.insert(partsToSimplify, descendant)
                end
            end
        end
        
        for _, part in ipairs(partsToSimplify) do
            pcall(simplifyMeshPart, part)
        end
    end
    
    local function reduceMeshDetail(mesh)
        if mesh:IsA("SpecialMesh") or mesh:IsA("FileMesh") then
            -- For SpecialMesh, reduce detail by scaling or changing mesh type
            if mesh.MeshType == Enum.MeshType.Head then
                mesh.Scale = mesh.Scale * 1.2  -- Simplify by scaling up
            elseif mesh.MeshType == Enum.MeshType.Sphere then
                mesh.MeshType = Enum.MeshType.Head  -- Use lower detail sphere
            end
        end
    end
    
    local function processWorkspace()
        local modelsProcessed = 0
        local partsSimplified = 0
        
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and #model:GetChildren() > 0 then
                pcall(function()
                    simplifyModel(model)
                    modelsProcessed += 1
                end)
            end
        end
        
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("MeshPart") and shouldSimplify(part) then
                pcall(function()
                    simplifyMeshPart(part)
                    partsSimplified += 1
                end)
            end
            
            if part:IsA("Part") then
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("SpecialMesh") or child:IsA("FileMesh") then
                        pcall(function()
                            reduceMeshDetail(child)
                        end)
                    end
                end
            end
        end
        
        print(string.format("Low-poly conversion complete: %d models processed, %d parts simplified", 
              modelsProcessed, partsSimplified))
    end
    
    pcall(processWorkspace)
end

local function optimizes()
    settings().Physics.AllowSleep = true
    settings().Rendering.QualityLevel = 1
    settings().Rendering.EagerBulkExecution = false
    settings().Rendering.TextureQuality = Enum.TextureQuality.Low
    settings().Physics.PhysicsEnvironmentalThrottle = 2
    setfpscap(20000)
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

-- Enhanced culling with player animation and part optimization
local function applyCulling()
    local cam = Camera
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
            local distance = (cam.CFrame.Position - part.Position).Magnitude
            
            -- Distance-based optimization
            if distance > MAX_RENDER_DISTANCE then
                part.LocalTransparencyModifier = 1
                part.CastShadow = false
                
                -- Force physics sleep for distant unanchored parts
                if not part.Anchored then
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            else
                -- FOV-based culling for closer objects
                local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                local dirToPart = (part.Position - cam.CFrame.Position).Unit
                local camDir = cam.CFrame.LookVector
                local angle = math.deg(math.acos(math.clamp(camDir:Dot(dirToPart), -1, 1)))
                
                if onScreen and angle < FOV_ANGLE then
                    part.LocalTransparencyModifier = 0
                else
                    part.LocalTransparencyModifier = 1
                end
            end
        end
    end
end

local function applyOptimizations()
    removePlayerAnimations()
    optimizeUnanchoredParts()
    applyGraySky()
    applyFullBright()
    simplifyTerrain()
    optimizeLighting()
    removeReflectionsAndOptimize()
    optimizes()
    setSmoothPlastic()
    convertToLowPoly()
    
    StarterGui:SetCore("SendNotification", {
        Title = "AntiLag Started",
        Text = "Noticing any? yay or nay",
        Duration = 3,
    })
end

applyOptimizations()

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if Running then
            task.wait(1)
            removePlayerAnimations()
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        removePlayerAnimations()
    end
end

task.spawn(function()
    while Running and task.wait(OPTIMIZATION_INTERVAL) do
        pcall(function()
            removePlayerAnimations()
            optimizeUnanchoredParts()
            forcePhysicsSleep()
        end)
    end
end)

task.spawn(function()
    while Running and task.wait(CLEANUP_INTERVAL) do
        pcall(function()
            applyGraySky()
            optimizeLighting()
            simplifyTerrain()
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if Running then
        pcall(applyCulling)
    end
end)

local function cleanup()
    Running = false
    
    for part, properties in pairs(OriginalProperties) do
        if part and part.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    part[property] = value
                end)
            end
        end
    end
    
    pcall(function()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(part, "Default")
            end
        end
    end)
end

return {
    cleanup = cleanup,
    applyOptimizations = applyOptimizations
}
