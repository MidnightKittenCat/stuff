local person1 = "Amia"
local person2 = "Midnight"

local function calculateLovePercentage()
    return math.random(0, 100)
end

local function displayLovePercentage(percentage, monitor)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Love Percentage between " .. person1 .. " and " .. person2 .. ":")
    monitor.setCursorPos(1, 2)
    monitor.write(percentage .. "%")

    -- Draw a heart shape
    local heart = {
        "  ***   ***  ",
        " ***** ***** ",
        "*************",
        " *********** ",
        "  *********  ",
        "   *******   ",
        "    *****    ",
        "     ***     ",
        "      *      "
    }

    local heartStartX = 25
    local heartStartY = 2

    for i, line in ipairs(heart) do
        monitor.setCursorPos(heartStartX, heartStartY + i - 1)
        monitor.write(line)
    end
end

local monitor = peripheral.find("monitor")

if monitor then
    while true do
        local lovePercentage = calculateLovePercentage()
        displayLovePercentage(lovePercentage, monitor)
        sleep(5)
    end
else
    print("No monitor found. Please connect a monitor.")
end
