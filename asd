-- Import necessary modules
local peripheral = peripheral or require("peripheral")

-- Function to get the reactor peripheral
local function getReactorPeripheral()
    local reactor = peripheral.find("fissionReactorLogicAdapter")
    if reactor then
        return reactor
    else
        print("Reactor peripheral not found.")
        return nil
    end
end

-- Function to probe the reactor
local function probeReactor(desiredTemperature, monitor)
    local reactor = getReactorPeripheral()

    if not reactor then
        print("Failed to retrieve reactor peripheral.")
        return
    end

    local bestBurnRate = 0
    local bestCoolantLevel = 0
    local lastStableBurnRate = 0
    local scramRequired = false

    -- Initialize the monitor UI
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Starting reactor probing...")

    for burnRate = 0, 400, 5 do
        local success, errorReason = pcall(function()
            reactor.setBurnRate(burnRate)
            os.sleep(1)  -- Wait for a moment to stabilize

            local coolantLevel = reactor.getCoolantFilledPercentage()
            local reactorDamage = reactor.getReactorDamage()

            -- Update the monitor UI
            monitor.clear()
            monitor.setCursorPos(1, 1)
            monitor.write("Reactor Probing UI")
            monitor.setCursorPos(1, 3)
            monitor.write(string.format("Burn Rate: %.2f MB/t", burnRate))
            monitor.setCursorPos(1, 4)
            monitor.write(string.format("Coolant Level: %.2f%%", coolantLevel * 100))

            -- Check if the reactor is damaged
            if reactorDamage > 0 then
                monitor.setBackgroundColor(colors.red)
                monitor.setTextColor(colors.white)
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.write("SCRAMED")
                monitor.setBackgroundColor(colors.black)
                monitor.setTextColor(colors.white)
                scramRequired = true
            end

            -- Check if the coolant level drops below 99%
            if coolantLevel < 0.99 then
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.write("Probing stopped: Coolant level below 99%.")
                bestBurnRate = burnRate
                bestCoolantLevel = coolantLevel
                return false  -- Explicitly returning false to indicate stopping the loop
            end

            -- Check if the coolant level is stable
            if coolantLevel >= 0.99 then
                lastStableBurnRate = burnRate
            end

            -- Check if the desired temperature is reached or exceeded
            if coolantLevel >= 0.99 and coolantLevel < bestCoolantLevel then
                bestBurnRate = burnRate
                bestCoolantLevel = coolantLevel
            end
            return true  -- Continue the loop
        end)

        if not success or not errorReason then
            -- Display an error message on the monitor
            monitor.clear()
            monitor.setCursorPos(1, 1)
            monitor.write("Error during probing: " .. tostring(errorReason))
            os.sleep(2)
            break
        end

        if not success then
            break
        end

        -- If scram is required, stop probing
        if scramRequired then
            break
        end
    end

    -- Display probing results on the monitor
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Probing finished.")
    monitor.setCursorPos(1, 3)
    monitor.write(string.format("Best Burn Rate: %.2f MB/t", bestBurnRate))
    monitor.setCursorPos(1, 4)
    monitor.write(string.format("Coolant Level: %.2f%%", bestCoolantLevel * 100))
    monitor.setCursorPos(1, 5)
    monitor.write(string.format("Last Stable Burn Rate: %.2f MB/t", lastStableBurnRate))
end

-- Function to toggle reactor status (activate or scram)
local function toggleReactor()
    local reactor = getReactorPeripheral()

    if not reactor then
        print("Failed to retrieve reactor peripheral.")
        return
    end

    local success, errorReason = pcall(function()
        local status = reactor.getStatus()
        if status then
            reactor.scram()
        else
            reactor.activate()
        end

        -- Wait for a moment to allow the reactor to stabilize
        os.sleep(2)
    end)

    if not success then
        print("Error during toggling reactor status:", errorReason)
    end
end

-- Function to get user input for the desired temperature
local function getDesiredTemperature()
    while true do
        io.write("Enter the desired temperature (K): ")
        local input = tonumber(io.read())
        if input and input > 0 then
            return input
        else
            print("Invalid input. Please enter a valid positive number.")
        end
    end
end

-- Main function
local function main()
    local monitor = peripheral.find("monitor")

    if not monitor then
        print("Monitor peripheral not found.")
        return
    end

    monitor.setTextScale(1)  -- Adjust the text scale for a better UI

    local reactor = getReactorPeripheral()

    if not reactor then
        return
    end

    -- Get user input for the desired temperature
    local desiredTemperature = getDesiredTemperature()

    local success, errorReason = pcall(function()
        print("Turning on the reactor...")
        reactor.activate()

        os.sleep(2)  -- Allow reactor to start up

        -- Perform probing with the user-specified temperature
        probeReactor(desiredTemperature, monitor)

        -- Toggle reactor status after probing
        print("\nToggling reactor status...")
        toggleReactor()

        -- Wait for a moment to observe the reactor status
        os.sleep(2)

        -- Turn off the reactor after toggling
        print("\nTurning off the reactor...")
        reactor.scram()
    end)

    if not success then
        print("Error during main execution:", errorReason)
    end
end

-- Run the main function
main()
