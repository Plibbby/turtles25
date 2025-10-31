-- Mining turtle script with coordinate tracking
-- Mines down and forward in a loop until bedrock is reached
-- Uses coal found for refueling and places a chest in a side tunnel

local depth = 0
local x, y, z = 0, 0, 0  -- Turtle coordinates (y is vertical)
local facing = 0  -- 0: North, 1: East, 2: South, 3: West

-- Ask user for mining depth
print("Enter mining depth (or 0 for until bedrock):")
depth = tonumber(read()) or 0

-- Initialize position and fuel
local function init()
    print("Starting mining operation...")
    print("Current fuel level: " .. turtle.getFuelLevel())
    
    -- Try to refuel at start
    refuel()
end

-- Refuel using coal from inventory
local function refuel()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then return true end
    
    for i = 1, 16 do
        turtle.select(i)
        local detail = turtle.getItemDetail()
        if detail and (detail.name == "minecraft:coal" or detail.name == "coal") then
            turtle.refuel(1)
            print("Refueled. Current fuel: " .. turtle.getFuelLevel())
            return true
        end
    end
    return false
end

-- Check if turtle has enough fuel for a round trip
local function checkFuel(required)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then return true end
    return fuelLevel >= required
end

-- Update position based on movement
local function updatePosition(direction)
    if direction == "forward" then
        if facing == 0 then z = z - 1  -- North
        elseif facing == 1 then x = x + 1  -- East
        elseif facing == 2 then z = z + 1  -- South
        elseif facing == 3 then x = x - 1  -- West
        end
    elseif direction == "back" then
        if facing == 0 then z = z + 1
        elseif facing == 1 then x = x - 1
        elseif facing == 2 then z = z - 1
        elseif facing == 3 then x = x + 1
        end
    elseif direction == "up" then
        y = y + 1
    elseif direction == "down" then
        y = y - 1
    end
end

-- Turn turtle and update facing
local function turnLeft()
    turtle.turnLeft()
    facing = (facing - 1) % 4
end

local function turnRight()
    turtle.turnRight()
    facing = (facing + 1) % 4
end

-- Try to move in a direction
local function tryMove(direction)
    local moved = false
    local errorMessage = ""
    
    if direction == "forward" then
        moved, errorMessage = turtle.forward()
    elseif direction == "up" then
        moved, errorMessage = turtle.up()
    elseif direction == "down" then
        moved, errorMessage = turtle.down()
    end
    
    if moved then
        updatePosition(direction)
        return true
    else
        print("Could not move " .. direction .. ": " .. (errorMessage or "unknown error"))
        return false
    end
end

-- Dig in a direction
local function tryDig(direction)
    local dug = false
    local errorMessage = ""
    
    if direction == "forward" then
        while turtle.detect() do
            dug, errorMessage = turtle.dig()
            if not dug then
                print("Could not dig forward: " .. (errorMessage or "unknown error"))
                return false
            end
            sleep(0.5)  -- Wait for block to break
        end
    elseif direction == "up" then
        while turtle.detectUp() do
            dug, errorMessage = turtle.digUp()
            if not dug then
                print("Could not dig up: " .. (errorMessage or "unknown error"))
                return false
            end
            sleep(0.5)
        end
    elseif direction == "down" then
        while turtle.detectDown() do
            dug, errorMessage = turtle.digDown()
            if not dug then
                print("Could not dig down: " .. (errorMessage or "unknown error"))
                return false
            end
            sleep(0.5)
        end
    end
    return true
end

-- Place a chest to the side
local function placeChest()
    print("Placing chest at side tunnel...")
    
    -- Turn right and dig a side tunnel
    turnRight()
    tryDig("forward")
    tryMove("forward")
    
    -- Place chest
    for i = 1, 16 do
        turtle.select(i)
        local detail = turtle.getItemDetail()
        if detail and (detail.name == "minecraft:chest" or detail.name == "chest") then
            turtle.place()
            print("Chest placed successfully")
            break
        end
    end
    
    -- Return to main tunnel
    turnLeft()
    tryMove("back")
end

-- Mine a single block forward and down
local function mineBlock()
    -- Dig forward
    tryDig("forward")
    if not tryMove("forward") then
        return false
    end
    
    -- Dig down
    tryDig("down")
    tryMove("down")
    
    -- Dig up (clear above)
    tryDig("up")
    tryMove("up")
    
    return true
end

-- Return to starting position
local function returnToStart()
    print("Returning to start position...")
    
    -- Move up to surface level
    while y < 0 do
        tryDig("up")
        tryMove("up")
    end
    
    -- Turn around to face starting direction
    turnLeft()
    turnLeft()
    
    -- Move back to start X
    while x > 0 do
        tryDig("forward")
        tryMove("forward")
    end
    
    -- Turn left to align with Z axis
    turnLeft()
    
    -- Move back to start Z
    while z < 0 do
        tryDig("forward")
        tryMove("forward")
    end
    
    print("Returned to start. Position: (" .. x .. ", " .. y .. ", " .. z .. ")")
end

-- Main mining loop
local function mine()
    local blocksMined = 0
    local targetDepth = depth
    
    print("Starting mining operation")
    print("Target depth: " .. (targetDepth > 0 and targetDepth or "bedrock"))
    
    -- Mine down to target depth or bedrock
    while (targetDepth == 0 or math.abs(y) < targetDepth) do
        -- Check fuel before each move
        if not checkFuel(100) then
            print("Low fuel, attempting to refuel...")
            if not refuel() then
                print("Out of fuel. Returning to start.")
                break
            end
        end
        
        -- Try to mine forward and down
        if not mineBlock() then
            -- If we can't move forward, we might have hit bedrock
            print("Cannot move forward. Checking for bedrock...")
            
            -- Check if we're at bedrock by trying to dig down
            if not turtle.detectDown() then
                print("Reached bedrock or lava. Stopping.")
                break
            end
        end
        
        blocksMined = blocksMined + 1
        
        -- Place chest every 20 blocks
        if blocksMined % 20 == 0 then
            placeChest()
        end
        
        -- Check for coal in inventory and refuel
        refuel()
    end
    
    print("Mining complete. Blocks mined: " .. blocksMined)
    returnToStart()
end

-- Run the program
init()
mine()
