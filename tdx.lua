-- Configuration
local TARGET_MAP = "Blox Out" 
local SHORT_DELAY = 5
local LONG_DELAY = 30
local DIFFICULTY_VOTE = "Easy"
local TELEPORT_GAME_ID = 9503261072
local MATCH_DURATION_WAIT = 570 -- 9 minutes 30 seconds (570 seconds)

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
-- MAIN FARMING LOOP
-----------------------------------------------------------

while true do
    local APCs = workspace:FindFirstChild("APCs") 
    local timerStartTime = 0 -- Reset timer

    if APCs then
        -- --- State: LOBBY (APCs are visible) ---
        print("--- NEW CYCLE STARTED ---")
        print("Detected Lobby State. Starting Map Selection Automation...")

        local function findAndJoinMatch()
            local player = game:GetService("Players").LocalPlayer
            local elevatorFolders = getElevatorFolders()
            print("Starting lobby automation for '" .. TARGET_MAP .. "'.")
            local currentDelay = SHORT_DELAY

            while workspace:FindFirstChild("APCs") do
                local matchFoundAndSeated = false
                
                for _, elevator in ipairs(elevatorFolders) do
                    local mapDisplay = elevator:FindFirstChild("mapdisplay")
                    local rampPart = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Ramp")

                    if mapDisplay and rampPart then
                        local mapNamePath = mapDisplay.screen.displayscreen.map
                        local currentMap = mapNamePath and (mapNamePath.ContentText or mapNamePath.Text)
                        
                        if currentMap and currentMap:lower():find(TARGET_MAP:lower()) then
                            print("Match found: " .. TARGET_MAP .. ". Attempting teleport...")
                            local player = game:GetService("Players").LocalPlayer
                            local character = player.Character or player.CharacterAdded:Wait()
                            if character and character.HumanoidRootPart then
                                -- Simple teleport to the ramp to sit automatically
                                character.HumanoidRootPart.CFrame = rampPart.CFrame
                                task.wait(0.5)
                                
                                local seatFolder = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Seats")
                                if seatFolder then
                                    local humanoid = character.Humanoid
                                    for _, seat in ipairs(seatFolder:GetChildren()) do
                                        if seat:IsA("Seat") and seat.Occupant == humanoid then
                                            matchFoundAndSeated = true
                                            break 
                                        end
                                    end
                                end
                                
                                if matchFoundAndSeated then
                                    print("CONFIRMED: Successfully seated. Waiting " .. LONG_DELAY .. "s for match to start...")
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- --- Delay Logic ---
                if matchFoundAndSeated then
                    currentDelay = LONG_DELAY
                    task.wait(currentDelay)
                    if workspace:FindFirstChild("APCs") then
                        print("Finished long delay. Resuming quick check loop.")
                        currentDelay = SHORT_DELAY
                    end
                else
                    print("Check failed. Retrying in " .. currentDelay .. "s...")
                    task.wait(currentDelay)
                end
            end
        end

        findAndJoinMatch()
        
    else
        -- --- State: IN-MATCH / PRE-GAME (APCs are NOT visible) ---
        print("Detected In-Match/Pre-Game State. Skipping Lobby Automation.")
    end

    -----------------------------------------------------------
    -- Match Start Sequence & Timer Initialization
    -----------------------------------------------------------
    print("Starting Match Preparation Sequence...")
    task.wait(10)

    if not workspace:FindFirstChild("Enemies") then 
        local voteArgs = { DIFFICULTY_VOTE }
        safeFire("DifficultyVoteCast", voteArgs)
        print("Voted for " .. DIFFICULTY_VOTE .. " difficulty.")

        safeFire("DifficultyVoteReady")
        print("Clicked Ready.")
        
        -- Speed Control Toggle
        local speedArgs = {
            true,
            true
        }
        safeFire("SoloToggleSpeedControl", speedArgs)
        print("Activated Solo Speed Control (true, true).")
        
        -- START TIMER RIGHT AFTER SPEED TOGGLE
        timerStartTime = os.clock()
        print(string.format("Match timer started at %.2f seconds.", timerStartTime))
    end
    
    task.wait(5)

    -----------------------------------------------------------
    -- In-Game Farming Loop
    -----------------------------------------------------------
    print("Executing automated placement and upgrade sequence...")

    for i, action in ipairs(placementAndUpgradeSequence) do
        if action.type == "place" then
            print(string.format("Waiting for %.0f cash to place %s...", action.cost, action.tower))
            waitForCash(action.cost)
            
            local placeArgs = {
                generatePlaceToken(), 
                action.tower, 
                action.position, 
                0
            }
            
            local success, result = safeInvoke("PlaceTower", placeArgs)
            if success then
                print(string.format("Successfully placed Tower #%d: %s", i, action.tower))
            else
                print(string.format("ERROR placing Tower #%d: %s. Error: %s", i, action.tower, tostring(result)))
            end

        elseif action.type == "upgrade" then
            print(string.format("Attempting to upgrade Tower %d (Path %d) for %.0f cash...", action.towerId, action.path, action.cost))
            waitForCash(action.cost) 
            
            local upgradeArgs = {
                action.towerId, 
                action.path, 
                1 
            }
            
            safeFire("TowerUpgradeRequest", upgradeArgs)
            print(string.format("Requested upgrade for Tower %d (Path %d)", action.towerId, action.path))
        end
    end
    
    -----------------------------------------------------------
    -- Match Duration Wait & Restart Loop
    -----------------------------------------------------------
    print(string.format("Automated build complete. Calculating remaining time for %d seconds total.", MATCH_DURATION_WAIT))

    -- Check if the timer was started (i.e., we successfully readied up)
    if timerStartTime > 0 then
        local elapsedTime = os.clock() - timerStartTime
        local remainingTime = MATCH_DURATION_WAIT - elapsedTime
        
        if remainingTime > 0 then
            print(string.format("Waiting %.2f seconds until teleport.", remainingTime))
            task.wait(remainingTime)
        else
            print("Warning: Match duration exceeded target time. Teleporting immediately.")
        end
    else
        -- Fallback if the timer wasn't started (e.g., joined mid-match)
        print("Timer not started. Waiting 60 seconds as a fallback.")
        task.wait(60) 
    end

    local TeleportService = game:GetService("TeleportService")
    print("Teleporting back to lobby to restart the farming cycle.")
    pcall(function()
        TeleportService:Teleport(TELEPORT_GAME_ID)
    end)
    
    task.wait(10)
end
