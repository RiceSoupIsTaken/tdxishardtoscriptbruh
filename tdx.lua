-- Configuration
local TARGET_MAP = "Blox Out" 
local SHORT_DELAY = 5    -- Seconds to wait if no match is found
local LONG_DELAY = 30    -- Seconds to wait after a successful teleport attempt
local DIFFICULTY_VOTE = "Easy"
local TELEPORT_GAME_ID = 9503261072 -- The TDX game ID for rejoining the lobby
local RESTART_WAIT_TIME = 60       -- Seconds to wait after the final upgrade before teleporting

-- Initial Check for Lobby State
local APCs = workspace:FindFirstChild("APCs") 

-----------------------------------------------------------
-- Utility Functions (Services/Remotes defined internally)
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

-- Function to generate a unique token for the PlaceTower remote
function generatePlaceToken()
    return os.clock() + (math.random() * 0.001)
end

-----------------------------------------------------------
-- Tower Placement and Upgrade Sequence Data
-----------------------------------------------------------
-- Tower ID is the index in the sequence (1, 2, 3, etc.)

local placementAndUpgradeSequence = {
    -- 1. Place John (Tower ID 1)
    { type = "place", cost = 300, tower = "John", position = vector.create(-367.9532470703125, 123.75299835205078, -100.3285903930664) },

    -- Upgrades for John (Tower ID 1)
    { type = "upgrade", cost = 100, towerId = 1, path = 2 }, 
    { type = "upgrade", cost = 225, towerId = 1, path = 2 },
    { type = "upgrade", cost = 125, towerId = 1, path = 1 },
    { type = "upgrade", cost = 450, towerId = 1, path = 1 },
    { type = "upgrade", cost = 2000, towerId = 1, path = 2 },

    -- 2. Place Golden Mine Layer (Tower ID 2)
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-363.4068908691406, 123.75299835205078, -93.43791961669922) },
    
    -- 3. Place Golden Mine Layer (Tower ID 3)
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-359.9133605957031, 123.75299835205078, -93.25811767578125) },
    
    -- Upgrade for John (Tower ID 1) - Final Path 2 upgrade
    { type = "upgrade", cost = 5350, towerId = 1, path = 2 }, 

    -- 4. Place Golden Mine Layer (Tower ID 4)
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-356.737548828125, 123.75299835205078, -93.49857330322266) },
    
    -- 5. Place Golden Mine Layer (Tower ID 5)
    { type = "place", cost = 600, tower = "Golden Mine Layer", position = vector.create(-353.3089294433594, 123.75299835205078, -93.76673889160156) },

    -- 6. Place Juggernaut (Tower ID 6)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-362.8759460449219, 123.75299835205078, -101.43222045898438) },

    -- Upgrades for Juggernaut (Tower ID 6)
    { type = "upgrade", cost = 850, towerId = 6, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 6, path = 1 },
    { type = "upgrade", cost = 600, towerId = 6, path = 2 },
    { type = "upgrade", cost = 3650, towerId = 6, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 6, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 6, path = 2 }, 
    

    -- 7. Place Juggernaut (Tower ID 7)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-362.9827880859375, 123.75299835205078, -106.51229095458984) },

    -- Upgrades for Juggernaut (Tower ID 7) 
    { type = "upgrade", cost = 600, towerId = 7, path = 2 },
    { type = "upgrade", cost = 850, towerId = 7, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 7, path = 1 },
    { type = "upgrade", cost = 3650, towerId = 7, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 7, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 7, path = 2 },

    -- 8. Place Juggernaut (Tower ID 8)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-358.1361083984375, 123.75299835205078, -101.14927673339844) },

    -- Upgrades for Juggernaut (Tower ID 8)
    { type = "upgrade", cost = 600, towerId = 8, path = 2 },
    { type = "upgrade", cost = 850, towerId = 8, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 8, path = 1 },
    { type = "upgrade", cost = 3650, towerId = 8, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 8, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 8, path = 2 },

    -- 9. Place Juggernaut (Tower ID 9)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(-358.4192199707031, 123.75299835205078, -106.3624267578125) },

    -- Upgrades for Juggernaut (Tower ID 9)
    { type = "upgrade", cost = 850, towerId = 9, path = 1 },
    { type = "upgrade", cost = 1600, towerId = 9, path = 1 },
    { type = "upgrade", cost = 600, towerId = 9, path = 2 },
    { type = "upgrade", cost = 3650, towerId = 9, path = 2 },
    { type = "upgrade", cost = 7500, towerId = 9, path = 2 },
    { type = "upgrade", cost = 14000, towerId = 9, path = 2 },
    
    -- Final Max Upgrades (60k)
    { type = "upgrade", cost = 60000, towerId = 8, path = 2 },
    { type = "upgrade", cost = 60000, towerId = 9, path = 2 },
}

-----------------------------------------------------------
-- MAIN FARMING LOOP
-----------------------------------------------------------

while true do
    local APCs = workspace:FindFirstChild("APCs") 

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
    -- Match Start Sequence & Speed Toggle
    -----------------------------------------------------------
    print("Starting Match Preparation Sequence...")
    task.wait(10)

    if not workspace:FindFirstChild("Enemies") then 
        local voteArgs = { DIFFICULTY_VOTE }
        safeFire("DifficultyVoteCast", voteArgs)
        print("Voted for " .. DIFFICULTY_VOTE .. " difficulty.")

        safeFire("DifficultyVoteReady")
        print("Clicked Ready.")
        
        -- NEW: Speed Control Toggle
        local speedArgs = {
            true,
            true
        }
        safeFire("SoloToggleSpeedControl", speedArgs)
        print("Activated Solo Speed Control (true, true). Waiting for wave 1...")
    end

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

    print("Automated build sequence complete. Waiting " .. RESTART_WAIT_TIME .. "s before teleporting...")
    
    task.wait(RESTART_WAIT_TIME)

    -----------------------------------------------------------
    -- Restart Loop: Teleport to Lobby
    -----------------------------------------------------------
    print("Teleporting back to lobby to restart the farming cycle.")
    local TeleportService = game:GetService("TeleportService")
    pcall(function()
        TeleportService:Teleport(TELEPORT_GAME_ID)
    end)
    
    task.wait(10) -- Give time for the teleport to happen before restarting the main loop
end
