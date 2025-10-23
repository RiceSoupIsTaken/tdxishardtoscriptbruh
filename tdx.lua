-- Configuration
local TARGET_MAP = "Blox Out" 
local SHORT_DELAY = 5    -- Seconds to wait if no match is found
local LONG_DELAY = 30    -- Seconds to wait after a successful teleport attempt
local DIFFICULTY_VOTE = "Easy"

-- Services and Player
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remote Events for Match Start
local DifficultyVoteCast = Remotes:WaitForChild("DifficultyVoteCast")
local DifficultyVoteReady = Remotes:WaitForChild("DifficultyVoteReady")

local APCs = workspace:FindFirstChild("APCs") -- Check for Lobby State here

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------

function getElevatorFolders()
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

function safeFire(remote, args)
    pcall(function()
        if args then
            remote:FireServer(unpack(args))
        else
            remote:FireServer()
        end
    end)
    task.wait(1)
end

-----------------------------------------------------------
-- Main Logic: Check Game State (Lobby or Match)
-----------------------------------------------------------

if APCs then
    -- --- State: LOBBY (APCs are visible) ---
    print("Detected Lobby State. Starting Map Selection Automation...")

    local function findAndJoinMatch()
        local elevatorFolders = getElevatorFolders()
        print("Starting lobby automation for '" .. TARGET_MAP .. "'.")
        local currentDelay = SHORT_DELAY

        -- Main Loop (Exits only when the Lobby environment disappears)
        while workspace:FindFirstChild("APCs") do
            local matchFoundAndSeated = false
            
            for _, elevator in ipairs(elevatorFolders) do
                local mapDisplay = elevator:FindFirstChild("mapdisplay")
                local rampPart = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Ramp")

                if mapDisplay and rampPart then
                    local mapNamePath = mapDisplay.screen.displayscreen.map
                    local currentMap = mapNamePath and (mapNamePath.ContentText or mapNamePath.Text)
                    
                    if currentMap and currentMap:lower():find(TARGET_MAP:lower()) then
                        print("Match found: " .. TARGET_MAP .. " on Elevator " .. elevator.Name .. ". Attempting teleport...")

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
                                break -- Exit elevator search
                            end
                        end
                    end
                end
            end
            
            -- --- Delay Logic ---
            if matchFoundAndSeated then
                currentDelay = LONG_DELAY
                task.wait(currentDelay)
                -- If APCs are still visible after the LONG_DELAY, reset the delay and continue searching.
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
    
    -- Execution falls through to the 'Match Start' sequence below once the APCs disappear
    
else
    -- --- State: IN-MATCH / PRE-GAME (APCs are NOT visible) ---
    print("Detected In-Match/Pre-Game State. Skipping Lobby Automation.")
    -- Script will proceed directly to the 'Match Start' sequence below
end

-----------------------------------------------------------
-- Match Start Sequence (Runs whether it came from the LOBBY or IN-MATCH state)
-----------------------------------------------------------

print("Starting Match Preparation Sequence...")

-- Wait 10 seconds for the GUI/Server-side loading to complete
task.wait(10)

-- Check if we are ready to vote (i.e., the game hasn't fully started yet)
if not workspace:FindFirstChild("Enemies") then 
    
    -- Vote for Difficulty
    local voteArgs = { DIFFICULTY_VOTE }
    safeFire(DifficultyVoteCast, voteArgs)
    print("Voted for " .. DIFFICULTY_VOTE .. " difficulty.")

    -- Click Ready
    safeFire(DifficultyVoteReady)
    print("Clicked Ready. Waiting for game start...")
end

-- --- Next Step: In-Game Tower Placement Loop ---
