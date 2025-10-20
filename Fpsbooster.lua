local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local PhysicsService = game:GetService("PhysicsService")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration Table
local Config = {
    -- Optimization Settings
    ENABLED = true,
    OPTIMIZATION_INTERVAL = 5,
    MIN_INTERVAL = 1,
    MAX_DISTANCE = 50,
    PERFORMANCE_MONITORING = true,
    FPS_THRESHOLD = 30,
    MESH_REMOVAL_ENABLED = true,
    MESH_REMOVAL_INTERVAL = 15,
    MESH_REMOVAL_COUNT = 30,
    GRAY_SKY_ENABLED = true,
    GRAY_SKY_ID = "rbxassetid://114666145996289",
    FULL_BRIGHT_ENABLED = true,
    SMOOTH_PLASTIC_ENABLED = true,
    COLLISION_GROUP_NAME = "OptimizedParts",
    OPTIMIZE_PHYSICS = true,
    DISABLE_CONSTRAINTS = true,
    THROTTLE_PARTICLES = true,
    THROTTLE_TEXTURES = true,
    REMOVE_ANIMATIONS = true,
    LOW_POLY_CONVERSION = true,
    SELECTIVE_TEXTURE_REMOVAL = true,
    PRESERVE_IMPORTANT_TEXTURES = true,
    IMPORTANT_TEXTURE_KEYWORDS = {"sign", "ui", "hud", "menu", "button"},
    QUALITY_LEVEL = 1,
    FPS_CAP = 1000,
    MEMORY_CLEANUP_THRESHOLD = 500,
    
    -- Mesh Removal Keywords
    MESH_REMOVAL_KEYWORDS = {
        "chair", "Chair", "seat", "Seat", "stool", "Stool", "bench", "Bench", 
        "coffee", "fruit", "paper", "Paper", "document", "Document", "note", "Note", 
        "cup", "mug", "photo", "monitor", "Monitor", "screen", "Screen", "display", "Display", 
        "pistol", "rifle", "plate", "computer", "Computer", "laptop", "Laptop",  "Barrel", "barrel",
        "desktop", "Desktop", "bedframe", "table", "Table", "desk", "Desk",  "Plank", "plank", "Cloud",
        "furniture", "Furniture", "bottle", "cardboard", "Chest", "book", "Book", "Pillow", "pillow",
        "books", "Books", "notebook", "Notebook", "magazine", "Magazine", "poster", "Poster", "cloud",
        "sign", "Sign", "billboard", "Billboard", "keyboard", "Keyboard", "picture", "Picture", 
        "frame", "Frame", "painting", "Painting", "pipe", "wires", "fridge", "glass", "Glass", 
        "window", "Window", "pane", "Pane", "shelf", "phone", "tree", "Tree", "bush", "Bush", 
        "plant", "Plant", "foliage", "Foliage", "Boxes", "decor", "Decor", "ornament", "Ornament", 
        "detail", "Detail", "knob", "Handle", "mesh", "Mesh", "model", "Model", "part", "Part"
    },
    
    -- Complex Mesh Types
    COMPLEX_MESH_TYPES = {
        "FileMesh", "SpecialMesh", "MeshPart"
    }
}

local function safeCall(func, name, ...)
    local success, err = pcall(func, ...)
    if not success then
        warn(string.format("Error in %s: %s", name, err))
    end
    return success
end

-- stuff
local Running = Config.ENABLED
local lastRunTime = 0
local lastMeshRemovalTime = 0

-- New function to remove closest meshes based on keywords
local function removeClosestMeshes()
    if not Config.MESH_REMOVAL_ENABLED then return 0 end
    
    local meshesRemoved = 0
    local processedInstances = {}
    local candidateMeshes = {}
    
    local localPlayerPos
    if LocalPlayer and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            localPlayerPos = rootPart.Position
        end
    end
    
    if not localPlayerPos then
        return 0
    end
    
    -- Collect all candidate meshes
    for _, instance in ipairs(workspace:GetDescendants()) do
        if not processedInstances[instance] and not shouldSkip(instance) then
            processedInstances[instance] = true
            
            local isMesh = false
            local meshInstance = nil
            
            if instance:IsA("MeshPart") then
                isMesh = true
                meshInstance = instance
            elseif (instance:IsA("SpecialMesh") or instance:IsA("FileMesh")) and instance.Parent and instance.Parent:IsA("BasePart") then
                isMesh = true
                meshInstance = instance
            end
            
            if isMesh and meshInstance then
                local shouldRemove = false
                local instanceName = meshInstance.Name:lower()
                local parentName = meshInstance.Parent and meshInstance.Parent.Name:lower() or ""
                
                -- Check if mesh matches any keywords
                for _, keyword in ipairs(Config.MESH_REMOVAL_KEYWORDS) do
                    if instanceName:find(keyword:lower(), 1, true) or parentName:find(keyword:lower(), 1, true) then
                        shouldRemove = true
                        break
                    end
                end
                
                if shouldRemove then
                    local meshPos
                    if meshInstance:IsA("MeshPart") then
                        meshPos = meshInstance.Position
                    else
                        meshPos = meshInstance.Parent.Position
                    end
                    
                    local distance = (localPlayerPos - meshPos).Magnitude
                    
                    table.insert(candidateMeshes, {
                        instance = meshInstance,
                        distance = distance
                    })
                end
            end
        end
    end
    
    table.sort(candidateMeshes, function(a, b)
        return a.distance < b.distance
    end)
    
    for i = 1, math.min(Config.MESH_REMOVAL_COUNT, #candidateMeshes) do
        local meshData = candidateMeshes[i]
        local meshInstance = meshData.instance
        
        local success, err = pcall(function()
            if meshInstance:IsA("MeshPart") then
                local newPart = Instance.new("Part")
                newPart.Name = "Simplified_" .. meshInstance.Name
                newPart.Size = meshInstance.Size
                newPart.CFrame = meshInstance.CFrame
                newPart.Color = Color3.new(0.5, 0.5, 0.5)
                newPart.Material = Enum.Material.SmoothPlastic
                newPart.Transparency = meshInstance.Transparency
                newPart.Anchored = meshInstance.Anchored
                newPart.CanCollide = meshInstance.CanCollide
                newPart.CastShadow = false
                newPart.Reflectance = 0
                
                for _, child in ipairs(meshInstance:GetChildren()) do
                    if child:IsA("Weld") or child:IsA("WeldConstraint") or 
                       child:IsA("Attachment") or child:IsA("Motor6D") then
                        child:Clone().Parent = newPart
                    end
                end

                pcall(function()
                    PhysicsService:SetPartCollisionGroup(newPart, Config.COLLISION_GROUP_NAME)
                end)

                newPart.Parent = meshInstance.Parent
                meshInstance:Destroy()
            else
                meshInstance.Parent.Color = Color3.new(0.5, 0.5, 0.5)
                meshInstance.Parent.Material = Enum.Material.SmoothPlastic
                meshInstance:Destroy()
            end
            
            meshesRemoved += 1
        end)

        if not success then
            warn(string.format("Failed to remove mesh %s: %s", meshInstance:GetFullName(), err))
        end
    end
    
    if meshesRemoved > 0 then
        print(string.format("Timed mesh removal: %d closest meshes removed", meshesRemoved))
    end
    
    return meshesRemoved
end

local function setSmoothPlastic()
    if not Config.SMOOTH_PLASTIC_ENABLED then return end
    
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

local function fpsc()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hm5650/Fps-counter/refs/heads/main/Fpsc", true))()
end
fpsc()

local function shouldSkip(instance)
    if instance:IsDescendantOf(LocalPlayer.Character) then
        return true
    end
    
    local parent = instance.Parent
    while parent do
        if parent:IsA("Model") and Players:GetPlayerFromCharacter(parent) then
            return true
        end
        parent = parent.Parent
    end
    
    return false
end

local function optimizeUI()
    local function optimizeGuiElement(gui)
        if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
            gui.ImageTransparency = 0.5
        elseif gui:IsA("Frame") or gui:IsA("TextLabel") then
            gui.BackgroundTransparency = 0.5
        end
    end
    
    for _, gui in ipairs(StarterGui:GetDescendants()) do
        safeCall(function() optimizeGuiElement(gui) end, "ui_optimization")
    end
end

local function removeMeshesFromObjects()
    if not Config.MESH_REMOVAL_ENABLED then return end
    
    local meshesRemoved = 0
    local partsSimplified = 0
    local processedInstances = {}

    local function isValidInstance(instance)
        return instance and instance.Parent and not processedInstances[instance]
    end

    for _, instance in ipairs(workspace:GetDescendants()) do
        if not isValidInstance(instance) or shouldSkip(instance) then
            continue
        end

        processedInstances[instance] = true

        if instance:IsA("MeshPart") then
            local shouldRemove = false
            local instanceName = instance.Name:lower()
            local parentName = instance.Parent and instance.Parent.Name:lower() or ""

            for _, keyword in ipairs(Config.MESH_REMOVAL_KEYWORDS) do
                if instanceName:find(keyword:lower(), 1, true) or parentName:find(keyword:lower(), 1, true) then
                    shouldRemove = true
                    break
                end
            end

            if shouldRemove then
                local success, err = pcall(function()
                    local newPart = Instance.new("Part")
                    newPart.Name = "Simplified_" .. instance.Name
                    newPart.Size = instance.Size
                    newPart.CFrame = instance.CFrame
                    newPart.Color = Color3.new(0.5, 0.5, 0.5)
                    newPart.Material = Enum.Material.SmoothPlastic
                    newPart.Transparency = instance.Transparency
                    newPart.Anchored = instance.Anchored
                    newPart.CanCollide = instance.CanCollide
                    newPart.CastShadow = false
                    newPart.Reflectance = 0
                    
                    for _, child in ipairs(instance:GetChildren()) do
                        if child:IsA("Weld") or child:IsA("WeldConstraint") or 
                           child:IsA("Attachment") or child:IsA("Motor6D") then
                            child:Clone().Parent = newPart
                        end
                    end

                    pcall(function()
                        PhysicsService:SetPartCollisionGroup(newPart, Config.COLLISION_GROUP_NAME)
                    end)

                    newPart.Parent = instance.Parent
                    instance:Destroy()
                    partsSimplified += 1
                end)

                if not success then
                    warn(string.format("Failed to process MeshPart %s: %s", instance:GetFullName(), err))
                end
            end
        end
        
        if (instance:IsA("SpecialMesh") or instance:IsA("FileMesh")) and instance.Parent and instance.Parent:IsA("BasePart") then
            local shouldRemove = false
            local instanceName = instance.Name:lower()
            local parentName = instance.Parent and instance.Parent.Name:lower() or ""
            local partName = instance.Parent.Name:lower()

            for _, keyword in ipairs(Config.MESH_REMOVAL_KEYWORDS) do
                if instanceName:find(keyword:lower(), 1, true) or parentName:find(keyword:lower(), 1, true) or partName:find(keyword:lower(), 1, true) then
                    shouldRemove = true
                    break
                end
            end

            if shouldRemove then
                local success, err = pcall(function()
                    instance.Parent.Color = Color3.new(0.5, 0.5, 0.5)
                    instance.Parent.Material = Enum.Material.SmoothPlastic
                    instance:Destroy()
                    meshesRemoved += 1
                end)

                if not success then
                    warn(string.format("Failed to process mesh %s: %s", instance:GetFullName(), err))
                end
            end
        end
        
        if instance:IsA("SurfaceAppearance") or instance:IsA("Decal") or instance:IsA("Texture") then
            local shouldRemoveTexture = false
            local parentName = instance.Parent and instance.Parent.Name:lower() or ""
            local instanceName = instance.Name:lower()

            for _, keyword in ipairs(Config.MESH_REMOVAL_KEYWORDS) do
                if instanceName:find(keyword:lower(), 1, true) or parentName:find(keyword:lower(), 1, true) then
                    shouldRemoveTexture = true
                    break
                end
            end

            if shouldRemoveTexture then
                local success, err = pcall(function()
                    if instance:IsA("Decal") or instance:IsA("Texture") then
                        instance.Transparency = 1
                    else
                        instance:Destroy()
                    end
                end)

                if not success then
                    warn(string.format("Failed to process texture %s: %s", instance:GetFullName(), err))
                end
            end
        end
    end

    if meshesRemoved > 0 or partsSimplified > 0 then
        print(string.format("Mesh removal: %d meshes removed, %d parts simplified", meshesRemoved, partsSimplified))
    else
        print("No meshes or parts were processed for removal.")
    end
end

pcall(function()
    PhysicsService:CreateCollisionGroup(Config.COLLISION_GROUP_NAME)
    PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, Config.COLLISION_GROUP_NAME, false)
end)

local function removePlayerAnimations()
    if not Config.REMOVE_ANIMATIONS then return end
    
    local localPlayer = LocalPlayer
    local localCharacter = localPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    local localHumanoid = localCharacter and localCharacter:FindFirstChildOfClass("Humanoid")
    
    -- Check if local player is in first person
    local isFirstPerson = false
    if localHumanoid then
        isFirstPerson = localHumanoid.CameraOffset == Vector3.new(0, 0, 0) and Camera.CameraSubject == localHumanoid
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                
                local shouldRemoveAnimations = false
                local isBehind = false
                
                if localRootPart and rootPart then
                    local distance = (localRootPart.Position - rootPart.Position).Magnitude
                    local isFar = distance > Config.MAX_DISTANCE
                    
                    -- Calculate if player is behind local player (only in first person)
                    if isFirstPerson and localRootPart then
                        local cameraDirection = Camera.CFrame.LookVector
                        local toPlayerDirection = (rootPart.Position - localRootPart.Position).Unit
                        local dotProduct = cameraDirection:Dot(toPlayerDirection)
                        
                        -- If dot product is negative, player is behind camera view
                        isBehind = dotProduct < 0
                        shouldRemoveAnimations = isBehind
                    else
                        -- In third person or no first person check, use distance-based removal
                        shouldRemoveAnimations = isFar
                    end
                end
                
                -- Animation management
                if humanoid then
                    if shouldRemoveAnimations then
                        -- Stop all playing animations
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            track:Stop()
                        end
                        
                        -- Store original animator for potential restoration
                        if not humanoid:FindFirstChild("OriginalAnimator") then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                local originalMarker = Instance.new("ObjectValue")
                                originalMarker.Name = "OriginalAnimator"
                                originalMarker.Value = animator
                                originalMarker.Parent = humanoid
                                animator.Parent = nil
                            end
                        end
                    else
                        -- Restore animations if they were previously removed
                        local originalAnimatorMarker = humanoid:FindFirstChild("OriginalAnimator")
                        if originalAnimatorMarker and originalAnimatorMarker.Value then
                            originalAnimatorMarker.Value.Parent = humanoid
                            originalAnimatorMarker:Destroy()
                        end
                    end
                end
                
                -- Visual optimization based on position
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if shouldRemoveAnimations or (localRootPart and rootPart and (localRootPart.Position - rootPart.Position).Magnitude > Config.MAX_DISTANCE) then
                            part.Material = Enum.Material.SmoothPlastic
                            part.Reflectance = 0
                            part.CastShadow = false
                            
                            pcall(function()
                                PhysicsService:SetPartCollisionGroup(part, Config.COLLISION_GROUP_NAME)
                            end)
                        end
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or 
                           part:IsA("Smoke") or part:IsA("Fire") then
                        part.Enabled = not shouldRemoveAnimations and 
                                     (localRootPart and rootPart and (localRootPart.Position - rootPart.Position).Magnitude <= Config.MAX_DISTANCE)
                    end
                end
            end
        end
    end
end

local function applyGraySky()
    if not Config.GRAY_SKY_ENABLED then return end
    
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            obj:Destroy()
        end
    end
    local sky = Instance.new("Sky")
    sky.SkyboxBk = Config.GRAY_SKY_ID
    sky.SkyboxDn = Config.GRAY_SKY_ID
    sky.SkyboxFt = Config.GRAY_SKY_ID
    sky.SkyboxLf = Config.GRAY_SKY_ID
    sky.SkyboxRt = Config.GRAY_SKY_ID
    sky.SkyboxUp = Config.GRAY_SKY_ID
    sky.SunAngularSize = 0
    sky.MoonAngularSize = 0
    sky.StarCount = 0
    sky.Parent = Lighting
end

local function applyFullBright()
    if not Config.FULL_BRIGHT_ENABLED then return end
    
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
        if v:IsA("PostEffect") then
            v:Destroy()
        end
    end
end

local function optimizeLightingAdvanced()
    local Lighting = game:GetService("Lighting")
    
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.ExposureCompensation = 0
    
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or 
           effect:IsA("ColorCorrectionEffect") or 
           effect:IsA("SunRaysEffect") or
           effect:IsA("BloomEffect") or
           effect:IsA("DepthOfFieldEffect") then
            effect:Destroy()
        end
    end
end

local function convertToLowPoly()
    if not Config.LOW_POLY_CONVERSION then return end
    
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
        end
        
        print(string.format("Low-poly conversion complete: %d models processed, %d parts simplified", 
              modelsProcessed, partsSimplified))
    end
    
    pcall(processWorkspace)
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
                PhysicsService:SetPartCollisionGroup(obj, Config.COLLISION_GROUP_NAME)
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

local function disableConstraints()
    if not Config.DISABLE_CONSTRAINTS then return end
    
    for _, c in ipairs(workspace:GetDescendants()) do
        if (c:IsA("AlignPosition") or c:IsA("AlignOrientation") or c:IsA("Motor") or c:IsA("HingeConstraint") or c:IsA("RodConstraint")) and not shouldSkip(c) then
            pcall(function()
                c.Enabled = false
            end)
        end
    end
end

local function throttleTextures()
    if not Config.THROTTLE_TEXTURES then return end
    
    for _, t in ipairs(workspace:GetDescendants()) do
        if (t:IsA("Decal") or t:IsA("Texture") or t:IsA("ImageLabel") or t:IsA("ImageButton")) and not shouldSkip(t) then
            pcall(function()
                t.Transparency = 1
            end)
        elseif t:IsA("SurfaceAppearance") and not shouldSkip(t) then
            pcall(function() t:Destroy() end)
        end
    end
end

local function optimizePhysics()
    if not Config.OPTIMIZE_PHYSICS then return end
    
    settings().Rendering.QualityLevel = Config.QUALITY_LEVEL
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

local function throttleParticles()
    if not Config.THROTTLE_PARTICLES then return end
    
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ParticleEmitter") and not shouldSkip(p) then
            pcall(function()
                p.Enabled = false
            end)
        end
    end
end

local function Core()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings().Physics.AllowSleep = true
    settings().Rendering.QualityLevel = Config.QUALITY_LEVEL
    settings().Rendering.EagerBulkExecution = true
    settings().Rendering.EnableFRM = true
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
    settings().Rendering.TextureQuality = Enum.TextureQuality.Low
    
    if setfpscap then
        setfpscap(Config.FPS_CAP)
    end
end

local function removeAllTextures()
    local texturesRemoved = 0
    
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            object.Material = Enum.Material.SmoothPlastic
            
            for _, decal in pairs(object:GetChildren()) do
                if decal:IsA("Decal") then
                    decal:Destroy()
                    texturesRemoved += 1
                end
            end
        end
    end
end

local function initializeCollisionGroups()
    local success = pcall(function()
        PhysicsService:CreateCollisionGroup(Config.COLLISION_GROUP_NAME)
        PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, Config.COLLISION_GROUP_NAME, false)
        PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, "Default", false)
    end)
    if not success then
        warn("Failed to initialize collision groups")
    end
end

local function binmem()
    local memory = collectgarbage("count")
    if memory > Config.MEMORY_CLEANUP_THRESHOLD then
        collectgarbage("collect")
    end
end

local function selectiveTextureRemoval()
    if not Config.SELECTIVE_TEXTURE_REMOVAL then return end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Decal") or obj:IsA("Texture")) and not shouldSkip(obj) then
            local shouldPreserve = false
            
            if Config.PRESERVE_IMPORTANT_TEXTURES then
                local objName = obj.Name:lower()
                local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                
                for _, keyword in ipairs(Config.IMPORTANT_TEXTURE_KEYWORDS) do
                    if objName:find(keyword:lower()) or parentName:find(keyword:lower()) then
                        shouldPreserve = true
                        break
                    end
                end
            end
            
            if not shouldPreserve then
                pcall(function()
                    obj.Transparency = 1
                end)
            end
        end
    end
end

local function monitorPerformance()
    if not Config.PERFORMANCE_MONITORING then return end
    
    local currentFPS = 1 / RunService.RenderStepped:Wait()
    
    if currentFPS < Config.FPS_THRESHOLD then
        Config.QUALITY_LEVEL = 1
        Config.MAX_DISTANCE = math.max(Config.MAX_DISTANCE - 10, 20)
        applya()
    end
end

local function optimizeUIAdvanced()
    local coreGui = game:GetService("CoreGui")
    
    -- Optimize CoreGui
    for _, gui in ipairs(coreGui:GetDescendants()) do
        if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
            gui.ImageTransparency = 0.3
        elseif gui:IsA("Frame") then
            gui.BackgroundTransparency = 0.5
        end
    end
    
    -- Optimize player GUIs
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
                if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
                    pcall(function() gui.ImageTransparency = 0.5 end)
                end
            end
        end
    end
end

local function applya()
    if not Config.ENABLED then return end
    
    applyGraySky()
    applyFullBright()
    simplifyTerrain()
    optimizeLighting()
    optimizeLightingAdvanced()
    removeReflectionsAndOptimize()
    optimizePhysics()
    setSmoothPlastic()
    removePlayerAnimations()
    convertToLowPoly()
    removeMeshesFromObjects()
    Core()
    optimizeUIAdvanced()
    disableConstraints()
    throttleParticles()
    throttleTextures()
    optimizeUI()
    removeAllTextures()
    initializeCollisionGroups()
    binmem()
    selectiveTextureRemoval()
    monitorPerformance()
end

applya()

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if Running then
            task.wait(1)
            safeCall(removePlayerAnimations, "new_player_animations")
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        safeCall(removePlayerAnimations, "initial_player_animations")
    end
end

local function mainOptimizationLoop()
    local lastHeavyOptimization = 0
    local HEAVY_OPTIMIZATION_INTERVAL = 20 -- seconds
    
    while Running do
        local currentTime = tick()
        
        -- Check if it's time for timed mesh removal (every 20 seconds)
        if currentTime - lastMeshRemovalTime >= Config.MESH_REMOVAL_INTERVAL then
            safeCall(removeClosestMeshes, "timed_mesh_removal")
            lastMeshRemovalTime = currentTime
        end
        
        if currentTime - lastHeavyOptimization >= HEAVY_OPTIMIZATION_INTERVAL then
            safeCall(applya, "heavy_optimization")
            safeCall(removeMeshesFromObjects, "mesh_removal")
            lastHeavyOptimization = currentTime
        end
        
        safeCall(removePlayerAnimations, "player_animations")
        
        task.wait(Config.OPTIMIZATION_INTERVAL)
    end
end

task.spawn(mainOptimizationLoop)

local function stopOptimizations()
    Running = false
    print("Optimizations stopped")
end

-- Export configuration for external access
return {
    Config = Config,
    stopOptimizations = stopOptimizations,
    applyOptimizations = applya
}
