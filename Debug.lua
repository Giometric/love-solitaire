local Debug = {}

-- Config
LineCount = 16

local maxMessages = 255
local lineHeight = 13
local lineSpacing = 2
local padding = 3
local messages = {}
local scroll = 0

local categoryNames = {
    "Log",
    "Warn",
    "Error",
}
local colors = {
    { r = 1, g = 1, b = 1 },
    { r = 1, g = 1, b = 0 },
    { r = 1, g = 0.0625, b = 0.03125 },
}

local function logInternal(category, msg, ...)
    local newMsg = { text = string.format(msg, ...), category = category }
    if (#messages == maxMessages) then
        table.remove(messages, 1)
    end
    table.insert(messages, newMsg)

    -- Scroll to bottom when new messages are added
    scroll = math.max(#messages - LineCount, 0)
end

local function mouseInWindow()
    local mouseX, mouseY = love.mouse.getPosition()
    local _, windowH = love.graphics.getDimensions()
    local totalHeight = (LineCount * lineHeight) + ((LineCount - 1) * lineSpacing) + (padding * 2)
    local windowY = windowH - totalHeight
    if mouseX >= 0 and mouseX <= windowH and
        mouseY >= windowY and mouseY <= windowY+windowH then
            return true
    end
    return false
end

-- Public methods
function Debug.Log(msg, ...)
    logInternal(1, msg, ...)
end

function Debug.LogWarning(msg, ...)
    logInternal(2, msg, ...)
end

function Debug.LogError(msg, ...)
    logInternal(3, msg, ...)
end

function Debug.ClearLogMessages()
    messages = {}
end

function Debug.Scroll(lines)
    lines = lines or 1
    local newScroll = scroll + lines
    scroll = math.max(0, math.min(#messages - LineCount, newScroll))
end

function Debug.HandleWheelMoved(x, y)
    if mouseInWindow() then
        Debug.Scroll(-y)
        return true
    end
    return false
end

function Debug.HandleMousePressed(x, y, button, istouch, presses)
    return mouseInWindow()
end

function Debug.DrawDebug()
    local windowW, windowH = love.graphics.getDimensions()
    local totalHeight = (LineCount * lineHeight) + ((LineCount - 1) * lineSpacing) + (padding * 2)
    local windowY = windowH - totalHeight
    love.graphics.setColor(0, 0, 0, 0.625)
    love.graphics.rectangle("fill", 0, windowY, windowW, totalHeight)

    local msgX = padding
    local msgY = windowY + padding
    for i = 1, math.min(#messages, LineCount) do
        local msg = messages[i + scroll]
        if msg then
            local c = colors[msg.category]
            love.graphics.setColor(c.r, c.g, c.b, 1)
            love.graphics.print(msg.text, msgX, msgY)
            msgY = msgY + lineHeight + lineSpacing
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Debug