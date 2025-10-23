
-- Configuration
local TARGET_MAP = "Blox Out" 
local SHORT_DELAY = 5    -- Seconds to wait if no match is found
local LONG_DELAY = 30    -- Seconds to wait after a successful teleport attempt

-- Services and Player
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remote Events for Match Start
local DifficultyVoteCast = Remotes:WaitForChild("DifficultyVoteCast")
local DifficultyVoteReady = Remotes:WaitForChild("DifficultyVoteReady")

local APCs = workspace:WaitForChild("APCs")
local APCs2 = workspace:WaitForChild("APCs2")

-----------------------------------------------------------
-- 1. Lobby Automation Loop
-----------------------------------------------------------

function isIngame()
    -- Checks for the presence of the Cash leaderstat, which appears once in-game
    return player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")
end

function findAndJoinMatch()
    
    -- Compile a list of all 16 elevator folders
    local elevatorFolders = {}
    for i = 1, 10 do
        local folder = APCs:FindFirstChild(tostring(i))
        if folder then table.insert(elevatorFolders, folder) end
    end
    for i = 11, 16 do
        local folder = APCs2:FindFirstChild(tostring(i))
        if folder then table.insert(elevatorFolders, folder) end
    end

    print("Starting lobby automation for '" .. TARGET_MAP .. "'.")
    local currentDelay = SHORT_DELAY

    -- Main Loop
    while not isIngame() do
        local matchFoundAndSeated = false
        local matchFoundAndAttempted = false

        for _, elevator in ipairs(elevatorFolders) do
            local mapDisplay = elevator:FindFirstChild("mapdisplay")
            local rampPart = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Ramp")

            if mapDisplay and rampPart then
                local mapNamePath = mapDisplay.screen.displayscreen.map
                local currentMap = mapNamePath and (mapNamePath.ContentText or mapNamePath.Text)
                
                -- 1. Check if the map name matches
                if currentMap and currentMap:lower():find(TARGET_MAP:lower()) then
                    
                    print("Match found: " .. TARGET_MAP .. " on Elevator " .. elevator.Name .. ". Attempting teleport...")
                    matchFoundAndAttempted = true 

                    -- Teleport player to the Ramp position
                    local character = player.Character
                    if character and character.HumanoidRootPart then
                        character.HumanoidRootPart.CFrame = rampPart.CFrame
                        task.wait(0.5)
                        
                        -- **Crucial Check:** See if we were successfully seated
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
                            break -- Exit elevator search
                        end
                    end
                end
            end
        end
        
        -- --- Delay Logic ---
        if matchFoundAndSeated then
            -- We succeeded, wait the long delay for the match to start/teleport us.
            currentDelay = LONG_DELAY
            task.wait(currentDelay)
            print("Finished long delay. Resuming quick check loop.")
            currentDelay = SHORT_DELAY -- Reset delay for the next check
        else
            -- We failed to find a match or failed to get seated, so we use the short delay.
            print("Check failed. Retrying in " .. currentDelay .. "s...")
            task.wait(currentDelay)
        end
    end
end

-- Start the Lobby Automation
findAndJoinMatch()

-----------------------------------------------------------
-- 2. Match Start Sequence
-----------------------------------------------------------

print("Detected in-game status. Starting match preparation...")

-- Wait 10 seconds for the GUI/Server-side loading to complete
task.wait(10)

-- Vote for Easy difficulty
local voteArgs = { "Easy" }
pcall(function()
    DifficultyVoteCast:FireServer(unpack(voteArgs))
end)
print("Voted for Easy difficulty.")
task.wait(1)

-- Click Ready
pcall(function()
    DifficultyVoteReady:FireServer()
end)
print("Clicked Ready. Waiting for game start...")

-- What is the next step once the game starts? (e.g., Tower placement)
