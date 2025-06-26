require("items")

local versionstamp = 0
local hFull = 0
local xscale = 0.8

---@type love.Cursor
local cursorHand = nil
local dragging = nil

-- local posx = 0
local posy = 0
-- local velx = 0
local vely = 0

--local fontMono = love.graphics.newFont("LiberationMono-Regular.ttf")

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

function love.load()
    cursorHand = love.mouse.getSystemCursor("hand")
end

function love.keypressed(key, scancode, isrepeat)
    if not isrepeat then
        if (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) and key == "r" then
            local width = love.graphics.getWidth()
            local x = 0
            local y = 0
            local lasth = 0
            local lastbot = 0
            versionstamp = versionstamp + 1
            for _, value in ipairs(Items) do
                if value.obj == nil then
                    local si, _ = string.find(value.name, "\t")
                    local name = string.sub(value.name, 1, si-1)
                    name = string.gsub(name, "Outstanding", "Ø")
                    name = string.gsub(name, "Individual", "Indv")
                    name = string.gsub(name, "Limited", "Ltd")
                    name = string.gsub(name, "Achievement", "Å")
                    value.obj = love.graphics.newText(love.graphics.getFont())
                    value.obj:add(name)
                end
                while #value.pos > 0 and value.pos[#value.pos].v >= versionstamp do
                    table.remove(value.pos)
                end
                local w, h = value.obj:getDimensions()
                if x + w > width / xscale then
                    x = 0
                    y = y + 2*lasth + 4
                end
                table.insert(value.pos, {
                    v = versionstamp,
                    x = x,
                    y = y,
                })
                x = x + w + 5
                lasth = h
                lastbot = y + h
            end
            hFull = lastbot + 480
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
    if posy > maxposy then
        posy = maxposy
        vely = 0
        return
    end

    -- Gradually reduce the velocity to create smooth scrolling effect.
    -- velx = velx - velx * math.min( dt * 10, 1 )
    vely = vely - vely * dt * 5
end

function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h = h*6
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r+m, g+m, b+m
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

        love.graphics.setColor(HSV(y / hFull, 0.7, 0.35))
        love.graphics.rectangle("fill", x * xscale, y - posy, w * xscale, h)
        love.graphics.setColor(HSV(y / hFull, 0.2, 1.0))
        love.graphics.draw(value.obj, x * xscale, y - posy, 0, xscale, 1.0)
    end
end

