require("items")

local versionstamp = 0
local hFull = 0
local xscale = 1
local xgap = 10
local ygap = 15

---@type love.Cursor
local cursorHand = nil
local dragging = nil

-- local posx = 0
local posy = 0
-- local velx = 0
local vely = 0

---@type love.Font
local fontMono = nil

local function displayPos(idx, item)
    if dragging ~= nil and dragging.i == idx then
        local mx, my = love.mouse.getPosition()
        return mx/xscale - dragging.xoffset, my+posy - dragging.yoffset
    end
    local posi = #item.pos
    while posi > 0 and item.pos[posi].v > versionstamp do
        posi = posi - 1
    end
    if posi > 0 then
        local r = item.pos[posi]
        return r.x, r.y
    end
    return 0, 0
end

local function displayVersion(idx, item)
    if dragging ~= nil and dragging.i == idx then
        return versionstamp + 1
    end
    local posi = #item.pos
    while posi > 0 and item.pos[posi].v > versionstamp do
        posi = posi - 1
    end
    if posi > 0 then
        local r = item.pos[posi]
        return r.v
    end
    return 0
end

local function reset()
    local width = love.graphics.getWidth()
    local x = 0
    local y = 0
    local lasth = 0
    local lastbot = 0
    versionstamp = versionstamp + 1
    for _, value in ipairs(Items) do
        if value.obj == nil then
            -- local si, _ = string.find(value.name, "\t")
            -- local name = string.sub(value.name, 1, si-1)
            -- name = string.gsub(name, "Outstanding", "Ø")
            -- name = string.gsub(name, "Individual", "Indv")
            -- name = string.gsub(name, "Limited", "Ltd")
            -- name = string.gsub(name, "Achievement", "Å")
            local name = value.name
            value.obj = love.graphics.newText(fontMono)
            value.obj:add(name)
        end
        while #value.pos > 0 and value.pos[#value.pos].v >= versionstamp do
            table.remove(value.pos)
        end
        local w, h = value.obj:getDimensions()
        if x + w > width / xscale then
            x = 0
            y = y + lasth + ygap
        end
        table.insert(value.pos, {
            v = versionstamp,
            x = x,
            y = y,
        })
        x = x + w + xgap
        lasth = h
        lastbot = y + h
    end
    hFull = lastbot + 480
end

function love.load()
    cursorHand = love.mouse.getSystemCursor("hand")
    fontMono = love.graphics.newFont("LiberationMono-Regular.ttf", 16, "light", 3)
    reset()
end

function love.keypressed(key, scancode, isrepeat)
    if not isrepeat then
        if (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) and key == "r" then
            reset()
        end
        if (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) and key == "s" then
            local fname = os.date("save-%m%d%H%M%S.lua")
            ---@cast fname string
            local f, err = io.open(fname, "w")
            if err ~= nil or f == nil then
                return
            end
            f:write("Items = {\n")
            for _, item in ipairs(Items) do
                f:write("    ")
                writeItem(f, item)
                f:write(",\n")
            end
            f:write("}\n")
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and dragging == nil then
        local z = {}
        for index, value in ipairs(Items) do
            table.insert(z, { index = index, v = displayVersion(index, value) })
        end
        table.sort(z, function(a, b)
            return a.v > b.v
        end)
        for _, o in ipairs(z) do
            local value = Items[o.index]
            if value.obj == nil then
                return
            end
            local vx, vy = displayPos(o.index, value)
            local xoffset, yoffset = x/xscale - vx, y+posy - vy
            if xoffset >= 0 and yoffset >= 0 then
                local vw, vh = value.obj:getDimensions()
                if xoffset < vw and yoffset < vh then
                    love.mouse.setCursor(cursorHand)
                    dragging = { i = o.index, xoffset = xoffset, yoffset = yoffset }
                    return
                end
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        if dragging ~= nil then
            local value = Items[dragging.i]
            local xnew, ynew = displayPos(dragging.i, value)
            versionstamp = versionstamp + 1
            while #value.pos > 0 and value.pos[#value.pos].v >= versionstamp do
                table.remove(value.pos)
            end
            table.insert(value.pos, { v = versionstamp, x = xnew, y = ynew })
            love.mouse.setCursor()
            dragging = nil
        end
    end
end

function love.wheelmoved( dx, dy )
    -- velx = velx + dx * 20
    local kick = 0
    if dy * vely < 0 then
        vely = 0
    else
        kick = dy / math.abs(vely + 1)
    end
    vely = vely + kick * 1000 + dy * 50
end

function love.update( dt )
    -- posx = posx + velx * dt
    posy = posy - vely * dt
    if posy < 0 then
        posy = 0
        vely = 0
        return
    end
    local maxposy = hFull - love.graphics.getHeight()
    if maxposy > 0 and posy > maxposy then
        posy = maxposy
        vely = 0
        return
    end

    -- Gradually reduce the velocity to create smooth scrolling effect.
    -- velx = velx - velx * math.min( dt * 10, 1 )
    vely = vely - vely * dt * 5
end

-- function HSV(h, s, v)
--     if s <= 0 then return v,v,v end
--     h = h*6
--     local c = v*s
--     local x = (1-math.abs((h%2)-1))*c
--     local m,r,g,b = (v-c), 0, 0, 0
--     if h < 1 then
--         r, g, b = c, x, 0
--     elseif h < 2 then
--         r, g, b = x, c, 0
--     elseif h < 3 then
--         r, g, b = 0, c, x
--     elseif h < 4 then
--         r, g, b = 0, x, c
--     elseif h < 5 then
--         r, g, b = x, 0, c
--     else
--         r, g, b = c, 0, x
--     end
--     return r+m, g+m, b+m
-- end

local turboGradient = {
    -- 0x23 / 0xff, 0x17 / 0xff, 0x1b / 0xff,
    0x4a / 0xff, 0x58 / 0xff, 0xdd / 0xff,
    0x2f / 0xff, 0x9d / 0xff, 0xf5 / 0xff,
    0x27 / 0xff, 0xd7 / 0xff, 0xc4 / 0xff,
    0x4d / 0xff, 0xf8 / 0xff, 0x84 / 0xff,
    0x95 / 0xff, 0xfb / 0xff, 0x51 / 0xff,
    0xde / 0xff, 0xdd / 0xff, 0x32 / 0xff,
    0xff / 0xff, 0xa4 / 0xff, 0x23 / 0xff,
    0xf6 / 0xff, 0x5f / 0xff, 0x18 / 0xff,
    0xba / 0xff, 0x22 / 0xff, 0x08 / 0xff,
    0x90 / 0xff, 0x0c / 0xff, 0x00 / 0xff,
}
local function colorTurbo(x)
    if x <= 0 then
        return turboGradient[1], turboGradient[2], turboGradient[3]
    end
    if x >= 1 then
        return turboGradient[#turboGradient-2], turboGradient[#turboGradient-1], turboGradient[#turboGradient]
    end
    local step, alpha = math.modf(x * (#turboGradient / 3 - 1))
    return turboGradient[3*step+1] + alpha * (turboGradient[3*step+4] - turboGradient[3*step+1]),
        turboGradient[3*step+2] + alpha * (turboGradient[3*step+5] - turboGradient[3*step+2]),
        turboGradient[3*step+3] + alpha * (turboGradient[3*step+6] - turboGradient[3*step+3])
end

function love.draw()
    local z = {}
    for index, value in ipairs(Items) do
        table.insert(z, { index = index, v = displayVersion(index, value) })
    end
    table.sort(z, function(a, b)
        return a.v < b.v
    end)
    for _, o in ipairs(z) do
        local value = Items[o.index]
        if value.obj == nil then
            return
        end
        local x, y = displayPos(o.index, value)
        local w, h = value.obj:getDimensions()

        local r, g, b = colorTurbo(y / hFull)
        if (0.2126*r + 0.7152*g + 0.0722*b) > 0.55 then
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", x * xscale, y - posy, w * xscale, h)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(r*.87, g*.87, b*.87)
            love.graphics.rectangle("fill", x * xscale, y - posy, w * xscale, h)
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.draw(value.obj, x * xscale, y - posy, 0, xscale, 1.0)
    end
end

