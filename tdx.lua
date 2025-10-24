-- Configuration
local TARGET_MAP = "Blox Out" 
local SHORT_DELAY = 5
local LONG_DELAY = 30
local COOLDOWN_DELAY = 30 -- Cooldown if another player joins your APC
local DIFFICULTY_VOTE = "Easy"
local TELEPORT_GAME_ID = 9503261072
local MATCH_DURATION_WAIT = 570 -- 9 minutes 30 seconds

local APCs = workspace:FindFirstChild("APCs") 

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------

function getCash()
    local player = game:GetService("Players").LocalPlayer
    local cashValue = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")
    return cashValue and cashValue.Value or 0
end

function waitForCash(minAmount)
    local cash = getCash()
    while cash < minAmount do
        task.wait(1)
        cash = getCash()
    end
end

function getElevatorFolders()
    local APCs = workspace:WaitForChild("APCs")
    local APCs2 = workspace:WaitForChild("APCs2")
    local elevatorFolders = {}
    
    for i = 1, 10 do
        local folder = APCs:FindFirstChild(tostring(i))
        if folder then table.insert(elevatorFolders, folder) end
    end
    for i = 11, 16 do
        local folder = APCs2:FindFirstChild(tostring(i))
        if folder then table.insert(elevatorFolders, folder) end
    end
    return elevatorFolders
end

function safeFire(remoteName, args)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local remote = Remotes:WaitForChild(remoteName)
    
    pcall(function()
        if args then
            remote:FireServer(unpack(args))
        else
            remote:FireServer()
        end
    end)
    task.wait(0.5)
end

function safeInvoke(remoteName, args)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local remote = Remotes:WaitForChild(remoteName)
    
    local success, result = pcall(function()
        return remote:InvokeServer(unpack(args))
    end)
    task.wait(0.5)
    return success, result
end

function generatePlaceToken()
    return os.clock() + (math.random() * 0.001)
end

-----------------------------------------------------------
-- Tower Placement and Upgrade Sequence Data
-----------------------------------------------------------

local placementAndUpgradeSequence = {
    { type = "place", cost = 300, tower = "John", position = vector.create(-367.9532470703125, 123.75299835205078, -100.3285903930664) },
    { type = "upgrade", cost = 100, towerId = 1, path = 2 }, 
    { type = "upgrade", cost = 225, towerId = 1, path = 2 },
    { type = "upgrade", cost = 125, towerId = 1, path = 1 },
    { type = "upgrade", cost = 450, towerId = 1, path = 1 },
    { type = "upgrade", cost = 2000, towerId = 1, path = 2 },
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-363.4068908691406, 123.75299835205078, -93.43791961669922) },
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-359.9133605957031, 123.75299835205078, -93.25811767578125) },
    { type = "upgrade", cost = 5350, towerId = 1, path = 2 }, 
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-356.737548828125, 123.75299835205078, -93.49857330322266) },
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-353.3089294433594, 123.75299835205078, -93.76673889160156) },
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-362.8759460449219, 123.75299835205078, -101.43222045898438) },
    { type = "upgrade", cost = 850, towerId = 6, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 6, path = 1 },
    { type = "upgrade", cost = 600, towerId = 6, path = 2 },
    { type = "upgrade", cost = 3650, towerId = 6, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 6, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 6, path = 2 }, 
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-362.9827880859375, 123.75299835205078, -106.51229095458984) },
    { type = "upgrade", cost = 600, towerId = 7, path = 2 },
    { type = "upgrade", cost = 850, towerId = 7, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 7, path = 1 },
    { type = "upgrade", cost = 3650, towerId = 7, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 7, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 7, path = 2 },
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-358.1361083984375, 123.75299835205078, -101.14927673339844) },
    { type = "upgrade", cost = 600, towerId = 8, path = 2 },
    { type = "upgrade", cost = 850, towerId = 8, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 8, path = 1 },
    { type = "upgrade", cost = 3650, towerId = 8, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 8, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 8, path = 2 },
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-358.4192199707031, 123.75299835205078, -106.3624267578125) },
    { type = "upgrade", cost = 850, towerId = 9, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 9, path = 1 },
    { type = "upgrade", cost = 600, towerId = 9, path = 2 },
    { type = "upgrade", cost = 3650, towerId = 9, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 9, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 9, path = 2 },
    { type = "upgrade", cost = 60000, towerId = 8, path = 2 },
    { type = "upgrade", cost = 60000, towerId = 9, path = 2 },
}

-----------------------------------------------------------
-- APC MONITOR FUNCTION
-----------------------------------------------------------

local function monitorAPC(elevator)
    local seatFolder = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Seats")
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local initialSeat = nil
    
    -- Find the seat the player is in
    for _, seat in ipairs(seatFolder:GetChildren()) do
        if seat:IsA("Seat") and seat.Occupant and seat.Occupant.Parent == character then
            initialSeat = seat
            break
        end
    end
    
    if not initialSeat then 
        return false -- Player failed to seat or match started, continue main loop
    end

    -- Continuous monitoring loop (runs until APCs vanish)
    while workspace:FindFirstChild("APCs") do
        local occupantCount = 0
        local isPlayerSeated = false
        
        for _, seat in ipairs(seatFolder:GetChildren()) do
            if seat:IsA("Seat") and seat.Occupant then
                occupantCount = occupantCount + 1
                if seat.Occupant.Parent == character then
                    isPlayerSeated = true
                end
            end
        end
        
        if occupantCount > 1 and isPlayerSeated then
            -- INTRUDER DETECTED!
            
            -- Force stand up/eject
            pcall(function()
                initialSeat.Disabled = true
                if character and character.HumanoidRootPart then
                    character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
                end
                initialSeat.Disabled = false
            end)
            
            task.wait(COOLDOWN_DELAY)
            return true -- Intended to return to findAndJoinMatch and start a new search
        end
        
        task.wait(1)
    end
    
    return false -- Match started successfully
end

-----------------------------------------------------------
-- MAIN FARMING LOOP
-----------------------------------------------------------

while true do
    local APCs = workspace:FindFirstChild("APCs") 
    local timerStartTime = 0
    local shouldRestart = false

    if APCs then
        local function findAndJoinMatch()
            local player = game:GetService("Players").LocalPlayer
            local elevatorFolders = getElevatorFolders()
            local currentDelay = SHORT_DELAY

            while workspace:FindFirstChild("APCs") and not shouldRestart do
                local matchFoundAndSeated = false
                
                for _, elevator in ipairs(elevatorFolders) do
                    local mapDisplay = elevator:FindFirstChild("mapdisplay")
                    local rampPart = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Ramp")
                    local seatFolder = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Seats")

                    if mapDisplay and rampPart and seatFolder then
                        local mapNamePath = mapDisplay.screen.displayscreen.map
                        local currentMap = mapNamePath and (mapNamePath.ContentText or mapNamePath.Text)
                        
                        -- Pre-check if APC is empty
                        local occupantCount = 0
                        for _, seat in ipairs(seatFolder:GetChildren()) do
                            if seat:IsA("Seat") and seat.Occupant then
                                occupantCount = occupantCount + 1
                            end
                        end

                        if currentMap and currentMap:lower():find(TARGET_MAP:lower()) and occupantCount == 0 then
                            
                            local player = game:GetService("Players").LocalPlayer
                            local character = player.Character or player.CharacterAdded:Wait()
                            
                            if character and character.HumanoidRootPart then
                                -- Simple teleport to the ramp to sit automatically
                                character.HumanoidRootPart.CFrame = rampPart.CFrame
                                task.wait(0.5)
                                
                                local humanoid = character.Humanoid
                                for _, seat in ipairs(seatFolder:GetChildren()) do
                                    if seat:IsA("Seat") and seat.Occupant == humanoid then
                                        matchFoundAndSeated = true
                                        break 
                                    end
                                end
                                
                                if matchFoundAndSeated then
                                    -- Start monitoring this specific APC
                                    shouldRestart = monitorAPC(elevator)
                                    if shouldRestart then
                                        return -- Restart the whole findAndJoinMatch loop
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                
                if matchFoundAndSeated then
                    currentDelay = LONG_DELAY
                    task.wait(currentDelay)
                    if workspace:FindFirstChild("APCs") then
                        currentDelay = SHORT_DELAY
                    end
                else
                    task.wait(currentDelay)
                end
            end
        end

        findAndJoinMatch()
        
    end

    -----------------------------------------------------------
    -- Match Start Sequence & Timer Initialization
    -----------------------------------------------------------
    task.wait(10)

    if not workspace:FindFirstChild("Enemies") then 
        local voteArgs = { DIFFICULTY_VOTE }
        safeFire("DifficultyVoteCast", voteArgs)

        safeFire("DifficultyVoteReady")
        
        local speedArgs = {
            true,
            true
        }
        safeFire("SoloToggleSpeedControl", speedArgs)
        
        timerStartTime = os.clock()
    end
    
    task.wait(5)

    -----------------------------------------------------------
    -- In-Game Farming Loop
    -----------------------------------------------------------

    for i, action in ipairs(placementAndUpgradeSequence) do
        if action.type == "place" then
            waitForCash(action.cost)
            
            local placeArgs = {
                generatePlaceToken(), 
                action.tower, 
                action.position, 
                0
            }
            
            local success, result = safeInvoke("PlaceTower", placeArgs)

        elseif action.type == "upgrade" then
            waitForCash(action.cost) 
            
            local upgradeArgs = {
                action.towerId, 
                action.path, 
                1 
            }
            
            safeFire("TowerUpgradeRequest", upgradeArgs)
        end
    end
    
    -----------------------------------------------------------
    -- Match Duration Wait & Restart Loop
    -----------------------------------------------------------
    
    if timerStartTime > 0 then
        local elapsedTime = os.clock() - timerStartTime
        local remainingTime = MATCH_DURATION_WAIT - elapsedTime
        
        if remainingTime > 0 then
            task.wait(remainingTime)
        else
            task.wait(0) 
        end
    else
        task.wait(60) 
    end

    local TeleportService = game:GetService("TeleportService")
    -- Use a robust pcall loop for teleporting to handle potential timeouts/failures
    local maxRetries = 3
    for attempt = 1, maxRetries do
        local success = pcall(function()
            TeleportService:Teleport(TELEPORT_GAME_ID)
        end)
        if success then
            break
        end
        task.wait(5)
    end
    
    task.wait(10)
end
