-- what are you doing here?!

local Config = {
    ENABLED = true,
    OPTIMIZATION_INTERVAL = 30,
    SHOW_UPDATELOG = true,
    MIN_INTERVAL = 3,
    MAX_DISTANCE = 50,
    PERFORMANCE_MONITORING = true,
    FPS_MONITOR = true,
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
    NETWORK_OPTIMIZATION = true,
    REDUCE_REPLICATION = true,
    THROTTLE_REMOTE_EVENTS = true,
    OPTIMIZE_CHAT = true,
    DISABLE_UNNECESSARY_GUI = true,
    STREAMING_ENABLED = true,
    REDUCE_PLAYER_REPLICATION_DISTANCE = 100,
    THROTTLE_SOUNDS = true,
    REMOVE_GRASS = true,
    DESTROY_PARTICLES = true,
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
    local function CreateUpdateLog()
        if not Config.SHOW_UPDATELOG then return end
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "UpdateLog"
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        local UserInputService = game:GetService("UserInputService")
        local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
        
        local frameWidth = isMobile and 300 or 400
        local frameHeight = isMobile and 350 or 450
        local textSize = isMobile and 10 or 12
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
        frame.Position = UDim2.new(0.5, -frameWidth/2, 0.5, -frameHeight/2)
        frame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
        frame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
        frame.BorderSizePixel = 2
        frame.Parent = screenGui
        local dragHeader = Instance.new("Frame")
        dragHeader.Size = UDim2.new(1, 0, 0, isMobile and 30 or 25)
        dragHeader.Position = UDim2.new(0, 0, 0, 0)
        dragHeader.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        dragHeader.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
        dragHeader.BorderSizePixel = 1
        dragHeader.Parent = frame
        local headerTitle = Instance.new("TextLabel")
        headerTitle.Size = UDim2.new(1, -80, 1, 0)
        headerTitle.Position = UDim2.new(0, 5, 0, 0)
        headerTitle.BackgroundTransparency = 1
        headerTitle.Text = "// UPDATE_LOG v1.0"
        headerTitle.TextColor3 = Color3.new(0, 1, 0)
        headerTitle.TextSize = textSize
        headerTitle.Font = Enum.Font.Code
        headerTitle.TextXAlignment = Enum.TextXAlignment.Left
        headerTitle.Parent = dragHeader
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, isMobile and 35 or 25, 0, isMobile and 30 or 25)
        closeButton.Position = UDim2.new(1, -(isMobile and 35 or 25), 0, 0)
        closeButton.BackgroundColor3 = Color3.new(0.3, 0.1, 0.1)
        closeButton.BorderColor3 = Color3.new(0.6, 0.2, 0.2)
        closeButton.Text = "X"
        closeButton.TextColor3 = Color3.new(1, 0.3, 0.3)
        closeButton.TextSize = textSize
        closeButton.Font = Enum.Font.Code
        closeButton.Parent = dragHeader
        local copyButton = Instance.new("TextButton")
        copyButton.Size = UDim2.new(0, isMobile and 35 or 50, 0, isMobile and 30 or 25)
        copyButton.Position = UDim2.new(1, -(isMobile and 70 or 75), 0, 0)
        copyButton.BackgroundColor3 = Color3.new(0.1, 0.1, 0.3)
        copyButton.BorderColor3 = Color3.new(0.2, 0.2, 0.6)
        copyButton.Text = "Copy"
        copyButton.TextColor3 = Color3.new(0.3, 0.3, 1)
        copyButton.TextSize = textSize
        copyButton.Font = Enum.Font.Code
        copyButton.Parent = dragHeader
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -10, 1, -(isMobile and 40 or 35))
        scrollFrame.Position = UDim2.new(0, 5, 0, isMobile and 35 or 30)
        scrollFrame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = isMobile and 12 or 8
        scrollFrame.ScrollBarImageColor3 = Color3.new(0.2, 0.2, 0.2)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Never
        scrollFrame.Parent = frame
        local uiListLayout = Instance.new("UIListLayout")
        uiListLayout.Padding = UDim.new(0, 5)
        uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        uiListLayout.Parent = scrollFrame
        local contentLabel = Instance.new("TextLabel")
        contentLabel.Size = UDim2.new(1, -10, 0, 0)
        contentLabel.BackgroundTransparency = 1
        contentLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        contentLabel.TextSize = textSize
        contentLabel.Font = Enum.Font.Code
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.TextWrapped = true
        contentLabel.AutomaticSize = Enum.AutomaticSize.Y
        contentLabel.LayoutOrder = 1
        contentLabel.Parent = scrollFrame
        local configText = [[
    -- like the new design ;)
    local OptizConfig = {
        ENABLED = true,
        OPTIMIZATION_INTERVAL = 30,
        SHOW_UPDATELOG = true,
        MIN_INTERVAL = 3,
        MAX_DISTANCE = 50,
        PERFORMANCE_MONITORING = true,
        FPS_MONITOR = true,
        FPS_THRESHOLD = 30,
        GRAY_SKY_ENABLED = true,
        FULL_BRIGHT_ENABLED = true,
        SMOOTH_PLASTIC_ENABLED = true,
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
        NETWORK_OPTIMIZATION = true,
        REDUCE_REPLICATION = true,
        THROTTLE_REMOTE_EVENTS = false,
        OPTIMIZE_CHAT = true,
        DISABLE_UNNECESSARY_GUI = true,
        STREAMING_ENABLED = true,
        REDUCE_PLAYER_REPLICATION_DISTANCE = 100,
        THROTTLE_SOUNDS = true,
        REMOVE_GRASS = true,
        DESTROY_PARTICLES = true,
    }
    ]]
        contentLabel.Text = configText
        local function updateCanvasSize()
            local contentSize = uiListLayout.AbsoluteContentSize
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 10)
        end
        uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
        contentLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateCanvasSize)
        task.spawn(function()
            wait(0.1)
            updateCanvasSize()
        end)
        copyButton.MouseButton1Click:Connect(function()
            setclipboard(configText)
            
            local originalText = copyButton.Text
            local originalBgColor = copyButton.BackgroundColor3
            local originalTextColor = copyButton.TextColor3
            
            copyButton.Text = "Copied!"
            copyButton.BackgroundColor3 = Color3.new(0.1, 0.3, 0.1)
            copyButton.TextColor3 = Color3.new(0.3, 1, 0.3)
            
            wait(1)
            copyButton.Text = originalText
            copyButton.BackgroundColor3 = originalBgColor
            copyButton.TextColor3 = originalTextColor
        end)
        local function handleManualScroll(direction)
            local scrollAmount = isMobile and 40 or 30
            local currentY = scrollFrame.CanvasPosition.Y
            local maxScroll = math.max(0, scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteWindowSize.Y)
            local newY = currentY + (scrollAmount * direction)
            
            if newY > maxScroll then
                newY = 0
            elseif newY < 0 then
                newY = maxScroll
            end
            
            scrollFrame.CanvasPosition = Vector2.new(0, newY)
        end
        scrollFrame.MouseWheelForward:Connect(function()
            handleManualScroll(-1)
        end)
        scrollFrame.MouseWheelBackward:Connect(function()
            handleManualScroll(1)
        end)
        local touchStartPos = nil
        local touchStartScrollPos = nil
        local isTouching = false
        
        if isMobile then
            scrollFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    touchStartPos = input.Position
                    touchStartScrollPos = scrollFrame.CanvasPosition
                    isTouching = true
                end
            end)
            scrollFrame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch and touchStartPos and isTouching then
                    local delta = input.Position - touchStartPos
                    local newY = touchStartScrollPos.Y - delta.Y
                    local maxScroll = math.max(0, scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteWindowSize.Y)
                    
                    scrollFrame.CanvasPosition = Vector2.new(0, math.clamp(newY, -50, maxScroll + 50))
                end
            end)
            scrollFrame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    isTouching = false
                    
                    local currentY = scrollFrame.CanvasPosition.Y
                    local maxScroll = math.max(0, scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteWindowSize.Y)
                    
                    if currentY < 0 then
                        scrollFrame.CanvasPosition = Vector2.new(0, maxScroll)
                    elseif currentY > maxScroll then
                        scrollFrame.CanvasPosition = Vector2.new(0, 0)
                    end
                end
            end)
        end
        local dragging = false
        local dragInput
        local dragStart
        local startPos
        local function updateDrag(input)
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        dragHeader.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                
                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        connection:Disconnect()
                    end
                end)
            end
        end)
        dragHeader.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                updateDrag(input)
            end
        end)
        closeButton.MouseButton1Click:Connect(function()
            screenGui:Destroy()
        end)
        if not isMobile then
            closeButton.MouseEnter:Connect(function()
                closeButton.BackgroundColor3 = Color3.new(0.5, 0.2, 0.2)
                closeButton.TextColor3 = Color3.new(1, 0.5, 0.5)
            end)
            closeButton.MouseLeave:Connect(function()
                closeButton.BackgroundColor3 = Color3.new(0.3, 0.1, 0.1)
                closeButton.TextColor3 = Color3.new(1, 0.3, 0.3)
            end)
            copyButton.MouseEnter:Connect(function()
                copyButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.5)
                copyButton.TextColor3 = Color3.new(0.5, 0.5, 1)
            end)
            copyButton.MouseLeave:Connect(function()
                copyButton.BackgroundColor3 = Color3.new(0.1, 0.1, 0.3)
                copyButton.TextColor3 = Color3.new(0.3, 0.3, 1)
            end)
        end
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "OPTIZ",
            Text = "Replace the old config with the new one!",
            Duration= "9";
        })
        return screenGui
    end
    CreateUpdateLog()
    
    local function RemoveMesh(target)
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
    RemoveMesh()
    local function fpsc()
        if not Config.FPS_MONITOR then return end
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
    local function optimizeNetworkSettings()
        if not Config.NETWORK_OPTIMIZATION then return end
        
        settings().Network.StreamingEnabled = Config.STREAMING_ENABLED
        
        if settings().Physics then
            settings().Physics.PhysicsSendRate = 30
            settings().Physics.PhysicsSendRate = 60
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    pcall(function()
                        humanoid.AutoJumpEnabled = false
                    end)
                end
            end
        end
    end
    local function reduceReplication()
        if not Config.REDUCE_REPLICATION then return end
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if obj.Anchored and not obj:IsDescendantOf(LocalPlayer.Character) then
                    pcall(function()
                        obj:SetNetworkOwner(nil)
                    end)
                end
                
                local distance = 0
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    distance = (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                end
                
                if distance > Config.REDUCE_PLAYER_REPLICATION_DISTANCE then
                    pcall(function()
                        obj:SetNetworkOwnershipAuto()
                    end)
                end
            end
        end
    end
    local function throttleRemoteEvents()
        if not Config.THROTTLE_REMOTE_EVENTS then return end
        
        local remoteThrottle = {}
        local maxCallsPerSecond = 10
        
        local function throttleRemote(remote, ...)
            local currentTime = tick()
            local remoteId = tostring(remote)
            
            if not remoteThrottle[remoteId] then
                remoteThrottle[remoteId] = {}
            end
            
            for i = #remoteThrottle[remoteId], 1, -1 do
                if currentTime - remoteThrottle[remoteId][i] > 1 then
                    table.remove(remoteThrottle[remoteId], i)
                end
            end
            
            if #remoteThrottle[remoteId] < maxCallsPerSecond then
                table.insert(remoteThrottle[remoteId], currentTime)
                return true
            end
            
            return false
        end
        
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local oldFireServer = obj.FireServer
                obj.FireServer = function(self, ...)
                    if throttleRemote(self, ...) then
                        return oldFireServer(self, ...)
                    end
                end
            elseif obj:IsA("RemoteFunction") then
                local oldInvokeServer = obj.InvokeServer
                obj.InvokeServer = function(self, ...)
                    if throttleRemote(self, ...) then
                        return oldInvokeServer(self, ...)
                    end
                end
            end
        end
    end
    local function optimizeChat()
        if not Config.OPTIMIZE_CHAT then return end
        
        local TextChatService = game:GetService("TextChatService")
        local Players = game:GetService("Players")
        
        pcall(function()
            if TextChatService then
                local channel = TextChatService:FindFirstChild("TextChannels"):FindFirstChild("RBXGeneral")
                if channel then
                    channel.MaximumChannelHistory = 50
                end
            end
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                pcall(function()
                    if player:GetAttribute("BubbleChatEnabled") ~= nil then
                        player:SetAttribute("BubbleChatEnabled", false)
                    end
                end)
            end
        end
    end
    local function disableUnnecessaryGUI()
        if not Config.DISABLE_UNNECESSARY_GUI then return end
        
        local CoreGui = game:GetService("CoreGui")
        local GuiService = game:GetService("GuiService")
        
        local elementsToDisable = {
            "PlayerList", 
            "EmotesMenu", 
            "Health",
            "BubbleChat"
        }
        
        for _, element in ipairs(elementsToDisable) do
            pcall(function()
                local guiElement = CoreGui:FindFirstChild(element)
                if guiElement then
                    guiElement.Enabled = false
                end
            end)
        end
        
        GuiService:SetGlobalGuiInset(0, 0, 0, 0)
    end
    local function throttleSounds()
        if not Config.THROTTLE_SOUNDS then return end
        
        for _, sound in ipairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                local distance = 0
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    distance = (sound.Parent and sound.Parent:IsA("BasePart") and 
                               (sound.Parent.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0
                end
                
                if distance > Config.MAX_DISTANCE then
                    sound:Stop()
                    sound.Playing = false
                elseif distance > Config.MAX_DISTANCE / 2 then
                    sound.Volume = sound.Volume * 0.3
                end
            end
        end
    end
    local function optimizeDataModel()
        local HttpService = game:GetService("HttpService")
        local Stats = game:GetService("Stats")
        
        pcall(function()
            HttpService.HttpEnabled = false
        end)
        
        pcall(function()
            if Stats then
                Stats.PerformanceStats.MeshCacheSize = 10
                Stats.PerformanceStats.TextureCacheSize = 10
            end
        end)
    end
    local function removeGrass()
        if not Config.REMOVE_GRASS then return end
        
        if not game:IsLoaded() then
            repeat
                task.wait()
            until game:IsLoaded()
        end
        coroutine.wrap(pcall)(function()
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if not terrain then
                repeat
                    task.wait()
                until workspace:FindFirstChildOfClass("Terrain")
                terrain = workspace:FindFirstChildOfClass("Terrain")
            end
            
            if sethiddenproperty then
                sethiddenproperty(terrain, "Decoration", false)
            else
                -- Fallback method if sethiddenproperty is not available
                pcall(function()
                    terrain.Decoration = false
                end)
                warn("Your exploit does not support sethiddenproperty, using alternative method.")
            end
            
            -- Additional grass/foliage removal methods
            pcall(function()
                -- Remove grass parts that might already be loaded
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Part") and (string.lower(obj.Name):find("grass") or 
                       string.lower(obj.Name):find("foliage") or 
                       string.lower(obj.Name):find("leaf") or
                       string.lower(obj.Name):find("plant")) then
                        obj:Destroy()
                    end
                end
                
                -- Set terrain attributes to minimize grass
                terrain:SetAttribute("GrassEnabled", false)
                terrain:SetAttribute("GrassDistance", 0)
                terrain:SetAttribute("GrassDensity", 0)
            end)
            
            if _G.ConsoleLogs then
                warn("Grass and Decorations Disabled")
            end
        end)
    end
    local function NoParticles()
        if not Config.DESTROY_PARTICLES then return end
        local RunService = game:GetService("RunService")
        local workspace = game:GetService("Workspace")
        local function removeParticleEmitters()
            for _, descendant in ipairs(workspace:GetDescendants()) do
                -- Check if the object is a ParticleEmitter
                if descendant:IsA("ParticleEmitter") then
                    descendant:Destroy()
                end
            end
        end
        
        while true do
            removeParticleEmitters()
            wait(0.1)
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
        if Config.REMOVE_MESH then
            RemoveMesh()
        end
        optimizeNetworkSettings()
        reduceReplication()
        throttleRemoteEvents()
        optimizeChat()
        disableUnnecessaryGUI()
        throttleSounds()
        optimizeDataModel()
        removeGrass()
        NoParticles()
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
