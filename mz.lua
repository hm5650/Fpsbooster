-- what are you doing here?!

local Config = {
    ENABLED = true,
    OPTIMIZATION_INTERVAL = 30,
    MIN_INTERVAL = 3,
    MAX_DISTANCE = 50,
    PERFORMANCE_MONITORING = true,
    FPS_THRESHOLD = 30,
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
    IMPORTANT_TEXTURE_KEYWORDS = {"sign", "ui", "hud", "menu", "button", "fence"},
    QUALITY_LEVEL = 1,
    FPS_CAP = 1000,
    MEMORY_CLEANUP_THRESHOLD = 500,
    REMOVE_MESH = true,
    REMOVE_CLOTHING = true,
    REDUCE_NETWORK_TRAFFIC = true,
}

local function Main(ExternalConfig)
    if ExternalConfig and type(ExternalConfig) == "table" then
        for key, value in pairs(ExternalConfig) do
            if Config[key] ~= nil then
                Config[key] = value
            end
        end
    end

    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    local RunService = game:GetService("RunService")
    local StarterGui = game:GetService("StarterGui")
    local PhysicsService = game:GetService("PhysicsService")
    local workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    local function safeCall(func, name, ...)
        local success, err = pcall(func, ...)
        if not success then
            warn(string.format("Error in %s: %s", name, err))
        end
        return success
    end

    local Running = Config.ENABLED
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


    local function createUpdateLogGUI()
        if not Config.SHOW_UPDATELOG then return end
        
        local Players = game:GetService("Players")
        local CoreGui = game:GetService("CoreGui")
        local TweenService = game:GetService("TweenService")
        
        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end
        
        -- Create main frame
        local ScreenGui = Instance.new("ScreenGui")
        local MainFrame = Instance.new("Frame")
        local Title = Instance.new("TextLabel")
        local ScrollFrame = Instance.new("ScrollingFrame")
        local ConfigList = Instance.new("UIListLayout")
        local CloseButton = Instance.new("TextButton")
        local CopyAllButton = Instance.new("TextButton")
        
        ScreenGui.Name = "AntiLagUpdateLog"
        ScreenGui.Parent = CoreGui
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 400, 0, 500)
        MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
        MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        MainFrame.BorderSizePixel = 0
        MainFrame.ClipsDescendants = true
        MainFrame.Parent = ScreenGui
        
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = MainFrame
        
        local UIStroke = Instance.new("UIStroke")
        UIStroke.Color = Color3.fromRGB(100, 100, 200)
        UIStroke.Thickness = 2
        UIStroke.Parent = MainFrame
        
        Title.Name = "Title"
        Title.Size = UDim2.new(1, 0, 0, 40)
        Title.Position = UDim2.new(0, 0, 0, 0)
        Title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        Title.BorderSizePixel = 0
        Title.Text = "🔄 Anti-Lag Update Log"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 18
        Title.Font = Enum.Font.GothamBold
        Title.Parent = MainFrame
        
        local TitleCorner = Instance.new("UICorner")
        TitleCorner.CornerRadius = UDim.new(0, 8)
        TitleCorner.Parent = Title
        
        ScrollFrame.Name = "ScrollFrame"
        ScrollFrame.Size = UDim2.new(1, -20, 1, -120)
        ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
        ScrollFrame.BackgroundTransparency = 1
        ScrollFrame.BorderSizePixel = 0
        ScrollFrame.ScrollBarThickness = 6
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ScrollFrame.Parent = MainFrame
        
        ConfigList.Name = "ConfigList"
        ConfigList.Padding = UDim.new(0, 5)
        ConfigList.Parent = ScrollFrame
        
        CopyAllButton.Name = "CopyAllButton"
        CopyAllButton.Size = UDim2.new(1, -20, 0, 35)
        CopyAllButton.Position = UDim2.new(0, 10, 1, -80)
        CopyAllButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        CopyAllButton.BorderSizePixel = 0
        CopyAllButton.Text = "📋 Copy All Config Variables"
        CopyAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CopyAllButton.TextSize = 14
        CopyAllButton.Font = Enum.Font.GothamBold
        CopyAllButton.Parent = MainFrame
        
        local CopyCorner = Instance.new("UICorner")
        CopyCorner.CornerRadius = UDim.new(0, 6)
        CopyCorner.Parent = CopyAllButton
        
        CloseButton.Name = "CloseButton"
        CloseButton.Size = UDim2.new(1, -20, 0, 35)
        CloseButton.Position = UDim2.new(0, 10, 1, -35)
        CloseButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
        CloseButton.BorderSizePixel = 0
        CloseButton.Text = "❌ Close"
        CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseButton.TextSize = 14
        CloseButton.Font = Enum.Font.GothamBold
        CloseButton.Parent = MainFrame
        
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 6)
        CloseCorner.Parent = CloseButton
        
        -- Config variables to display
        local configVariables = {
            "REMOVE_CLOTHING = " .. tostring(Config.REMOVE_CLOTHING),
            "REMOVE_MESH = " .. tostring(Config.REMOVE_MESH),
            "REDUCE_NETWORK_TRAFFIC = " .. tostring(Config.REDUCE_NETWORK_TRAFFIC),
            "REMOVE_SOUNDS = " .. tostring(Config.REMOVE_SOUNDS),
            "REMOVE_CHAT_BUBBLES = " .. tostring(Config.REMOVE_CHAT_BUBBLES),
            "REMOVE_EFFECTS = " .. tostring(Config.REMOVE_EFFECTS),
            "REMOVE_ANIMATIONS = " .. tostring(Config.REMOVE_ANIMATIONS),
            "THROTTLE_PARTICLES = " .. tostring(Config.THROTTLE_PARTICLES),
            "THROTTLE_TEXTURES = " .. tostring(Config.THROTTLE_TEXTURES),
            "LOW_POLY_CONVERSION = " .. tostring(Config.LOW_POLY_CONVERSION),
            "OPTIMIZE_PHYSICS = " .. tostring(Config.OPTIMIZE_PHYSICS),
            "DISABLE_CONSTRAINTS = " .. tostring(Config.DISABLE_CONSTRAINTS),
        }
        
        -- Create config items
        for i, configText in ipairs(configVariables) do
            local ConfigItem = Instance.new("Frame")
            local ConfigLabel = Instance.new("TextLabel")
            local CopyButton = Instance.new("TextButton")
            
            ConfigItem.Name = "ConfigItem"
            ConfigItem.Size = UDim2.new(1, 0, 0, 30)
            ConfigItem.BackgroundTransparency = 1
            ConfigItem.Parent = ScrollFrame
            
            ConfigLabel.Name = "ConfigLabel"
            ConfigLabel.Size = UDim2.new(0.7, 0, 1, 0)
            ConfigLabel.Position = UDim2.new(0, 0, 0, 0)
            ConfigLabel.BackgroundTransparency = 1
            ConfigLabel.Text = configText
            ConfigLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
            ConfigLabel.TextSize = 12
            ConfigLabel.TextXAlignment = Enum.TextXAlignment.Left
            ConfigLabel.Font = Enum.Font.Gotham
            ConfigLabel.Parent = ConfigItem
            
            CopyButton.Name = "CopyButton"
            CopyButton.Size = UDim2.new(0.25, 0, 0.7, 0)
            CopyButton.Position = UDim2.new(0.72, 0, 0.15, 0)
            CopyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
            CopyButton.BorderSizePixel = 0
            CopyButton.Text = "Copy"
            CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            CopyButton.TextSize = 11
            CopyButton.Font = Enum.Font.Gotham
            CopyButton.Parent = ConfigItem
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 4)
            ButtonCorner.Parent = CopyButton
            
            -- Copy individual config
            CopyButton.MouseButton1Click:Connect(function()
                setclipboard(configText)
                CopyButton.Text = "✓ Copied!"
                task.wait(1)
                CopyButton.Text = "Copy"
            end)
        end
        
        -- Update canvas size
        local totalHeight = #configVariables * 35
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        
        -- Copy all configs
        CopyAllButton.MouseButton1Click:Connect(function()
            local allConfigs = table.concat(configVariables, ",\n")
            setclipboard(allConfigs)
            CopyAllButton.Text = "✓ All Configs Copied!"
            task.wait(1.5)
            CopyAllButton.Text = "📋 Copy All Config Variables"
        end)
        
        -- Close button
        CloseButton.MouseButton1Click:Connect(function()
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                ScreenGui:Destroy()
            end)
        end)
        
        -- Make draggable
        local dragging = false
        local dragInput, dragStart, startPos
        
        Title.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        Title.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        -- Auto-close after 30 seconds
        task.delay(30, function()
            if ScreenGui and ScreenGui.Parent then
                ScreenGui:Destroy()
            end
        end)
        
        return ScreenGui
    end

    local function RemoveMesh(target)
        if not Config.REMOVE_MESH then return end  -- Early return if disabled
        
        local textureKeywords = {
            "chair", "seat", "stool", "bench", "coffee", "fruit", "paper", "document", 
            "note", "cup", "mug", "photo", "monitor", "screen", "display", "pistol", 
            "rifle", "plate", "computer", "laptop", "desktop", "bedframe", "table", 
            "desk", "plank", "cloud", "furniture", "bottle", "cardboard", "chest", 
            "book", "pillow", "magazine", "poster", "sign", "billboard", "keyboard", 
            "picture", "frame", "painting", "pipe", "wires", "fridge", "glass", "leaf",
            "window", "pane", "shelf", "phone", "tree", "bush", "plant", "foliage", 
            "boxes", "decor", "ornament", "detail", "knob", "handle", "wall", "tree",
            "prop", "object", "tool", "weapon", "food", "drink", "bloxy", "cola",
            "container", "box", "bag", "case", "stand", "rack", "holder", "support",
            "leg", "arm", "back", "top", "base", "cover", "lid", "door", "drawer",
            "handle", "knob", "button", "switch", "lever", "wheel", "chain", "door",
            "rope", "wire", "cable", "tube", "hose", "vent", "fan", "motor", "engine",
            "machine", "equipment", "device", "bottle", "closet", "potplant", "balloons",
        }
        
        local function hasTextureKeyword(name)
            local lowerName = string.lower(name)
            for _, keyword in ipairs(textureKeywords) do
                if string.find(lowerName, keyword:lower()) then
                    return true
                end
            end
            return false
        end
        
        local function isLocalPlayer(instance)
            local players = game:GetService("Players")
            local localPlayer = players.LocalPlayer
            if localPlayer and localPlayer.Character then
                if instance:IsDescendantOf(localPlayer.Character) then
                    return true
                end
            end
            
            for _, player in ipairs(players:GetPlayers()) do
                if player.Character and instance:IsDescendantOf(player.Character) then
                    return true
                end
            end
            
            return false
        end
        
        local function processInstance(instance)
            if isLocalPlayer(instance) then
                return
            end
            
            if instance:IsA("BasePart") then
                if hasTextureKeyword(instance.Name) then
                    local decal = instance:FindFirstChildWhichIsA("Decal")
                    if decal then
                        decal:Destroy()
                    end
                    
                    for _, child in ipairs(instance:GetChildren()) do
                        if child:IsA("Decal") then
                            child:Destroy()
                        end
                    end
                    
                    instance.BrickColor = BrickColor.new("Medium stone grey")
                    instance.Material = Enum.Material.Plastic
                    
                    if instance:IsA("Part") then
                        instance.TopSurface = Enum.SurfaceType.Smooth
                        instance.BottomSurface = Enum.SurfaceType.Smooth
                        instance.LeftSurface = Enum.SurfaceType.Smooth
                        instance.RightSurface = Enum.SurfaceType.Smooth
                        instance.FrontSurface = Enum.SurfaceType.Smooth
                        instance.BackSurface = Enum.SurfaceType.Smooth
                    end
                end
            elseif instance:IsA("Model") then
                for _, child in ipairs(instance:GetChildren()) do
                    processInstance(child)
                end
            end
        end
        
        if target then
            if target:IsA("Model") or target:IsA("BasePart") then
                if not isLocalPlayer(target) then
                    processInstance(target)
                else
                    warn("RemoveMesh: Cannot process local player")
                end
            else
                warn("RemoveMesh: Target must be a Model or BasePart")
            end
        else
            for _, obj in ipairs(workspace:GetChildren()) do
                if (obj:IsA("Model") or obj:IsA("BasePart")) and not isLocalPlayer(obj) then
                    processInstance(obj)
                end
            end
        end
    end
    -- Only call RemoveMesh if it's enabled in config
    if Config.REMOVE_MESH then
        RemoveMesh()
    end
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
                        
                        if isFirstPerson and localRootPart then
                            local cameraDirection = Camera.CFrame.LookVector
                            local toPlayerDirection = (rootPart.Position - localRootPart.Position).Unit
                            local dotProduct = cameraDirection:Dot(toPlayerDirection)
                            
                            isBehind = dotProduct < 0
                            shouldRemoveAnimations = isBehind
                        else
                            shouldRemoveAnimations = isFar
                        end
                    end
                    
                    if humanoid then
                        if shouldRemoveAnimations then
                            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                track:Stop()
                            end
                            
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
                            local originalAnimatorMarker = humanoid:FindFirstChild("OriginalAnimator")
                            if originalAnimatorMarker and originalAnimatorMarker.Value then
                                originalAnimatorMarker.Value.Parent = humanoid
                                originalAnimatorMarker:Destroy()
                            end
                        end
                    end
                    
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
        
        for _, gui in ipairs(coreGui:GetDescendants()) do
            if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
                gui.ImageTransparency = 0.3
            elseif gui:IsA("Frame") then
                gui.BackgroundTransparency = 0.5
            end
        end
        
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
    local function removeOtherPlayerAccessories()
        if not localPlayer then
            warn("LocalPlayer not available yet.")
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local character = player.Character
                if character then
                    for _, descendant in ipairs(character:GetChildren()) do
                        if descendant:IsA("Accessory") then
                            descendant:Destroy()
                        end
                    end
                end
            end
        end
    end
    Players.PlayerAdded:Connect(function(player)
        if player ~= localPlayer then
            player.CharacterAdded:Connect(function()
                task.wait(0.5) 
                removeOtherPlayerAccessories()
            end)
        end
    end)
    removeOtherPlayerAccessories()
    local function removeClothing()
        if not Config.REMOVE_CLOTHING then return end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, item in ipairs(player.Character:GetDescendants()) do
                    if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                        pcall(function() item:Destroy() end)
                    end
                end
            end
        end
    end
    local function reduceNetworkTraffic()
        if not Config.REDUCE_NETWORK_TRAFFIC then return end
        
        -- Reduce network ownership updates
        settings().Network.IncomingReplicationLag = 1000
        
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part:CanSetNetworkOwnership() then
                pcall(function()
                    part:SetNetworkOwnershipAuto()
                end)
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
        RemoveMesh()
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
        local HEAVY_OPTIMIZATION_INTERVAL = 20
        
        while Running do
            local currentTime = tick()
            
            if currentTime - lastHeavyOptimization >= HEAVY_OPTIMIZATION_INTERVAL then
                safeCall(applya, "heavy_optimization")
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
    return {
        Config = Config,
        stopOptimizations = stopOptimizations,
        applyOptimizations = applya
    }
end

return Main
