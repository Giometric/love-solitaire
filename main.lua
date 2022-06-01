cards = require("cards")
utils = require("utils")
BoundingBox = require("BoundingBox")

windowW = 640
windowH = 480
cardW = 70
cardH = 95
cardWHalf = cardW / 2
cardHHalf = cardH / 2
sideSpacing = 20
cardSpacing = ((windowW - (sideSpacing * 2)) - (7 * cardW)) / 6
stockX = sideSpacing + cardWHalf
stockY = sideSpacing + cardHHalf
tableauY = 210
cardBack = "red4"
talonMaxCount = 3
gameStartTime = -1
gameStartDelay = 0.5
debugMsg = ""
suitNames = {
    "Clubs",
    "Diamonds",
    "Hearts",
    "Spades"
}

spriteFlipSpeed = 7
talonSpriteFlipSpeed = 8
spriteMoveSpeed = 6
talonSpriteMoveSpeed = 6.5
grabbedCard = nil
grabOffset = { x = 0, y = 0 }

-- Broad bounding boxes for clickable areas
stockBox = { x = sideSpacing - 10, y = stockY - cardHHalf - 10, w = cardW + 20, h = cardH + 20 }
talonBox = { x = sideSpacing + cardW + cardSpacing - 10, y = stockY - cardHHalf - 10, w = cardW + 120, h = cardH + 20 }
tableauBox = {} -- refreshed in love.update

function drawCardFromStock()
    if table.getn(stock) > 0 then
        return table.remove(stock)
    else
        return nil
    end
end

function restartGame()
    gameStartTime = love.timer.getTime()
    -- Set up card data
    -- Suits are: 1 = clubs, 2 = diamonds, 3 = hearts, 4 = spades
    cardData = {}
    local cardIdx = 1
    for s = 1, 4 do
        for v = 1, 13 do
            cardData[cardIdx] = { idx=cardIdx, suit=s, value=v }
            cardIdx = cardIdx + 1
        end
    end

    -- Set up card sprite states
    cardSprites = {}
    for i = 1, 52 do
        cardSprites[i] = {
            state = 0, -- 0 = stock, 1 = talon, 2 = tableau, 3 = foundation
            grabbed = false,
            moveTime = -1,
            visible = false, up = false, oX = stockX, oY = stockY,
            x = stockX, y = stockY, sX = 1, sY = 1, face = -1, -- draw params
        }
    end

    -- Set up and shuffle cards arrays for Solitaire
    -- Terms and rules from https://bicyclecards.com/how-to-play/solitaire/
    stock = {}
    for i = 1, 52 do
        stock[i] = i
    end
    utils.shuffle(stock)

    -- Deal cards into the tableau
    tableau = {
        {}, {}, {}, {}, {}, {}, {}
    }
    
    local moveTime = gameStartTime + gameStartDelay
    for row = 1, 7 do
        for c = 1, 7 do
            if c >= row then
                local cardIdx = drawCardFromStock()
                tableau[c][row] = cardIdx

                if c == row then
                    cardSprites[cardIdx].up = true
                    cardSprites[cardIdx].face = -1
                else
                    cardSprites[cardIdx].up = false
                    cardSprites[cardIdx].face = -1
                end
                cardSprites[cardIdx].state = 2
                cardSprites[cardIdx].moveTime = moveTime
                moveTime = moveTime + 0.04
            end
        end
    end

    talon = {}

    foundation = {
        {}, {}, {}, {}
    }

    debugMsg = "Game started."
end

function getCardSpriteBoundingBox(idx)
    local cardSprite = cardSprites[idx]
    return {
        x = cardSprite.x - cardWHalf,
        y = cardSprite.y - cardHHalf,
        w = cardW,
        h = cardH
    }
end

function love.load()
    love.window.setTitle("LÖVE Solitaire")
    love.graphics.setBackgroundColor(0.15, 0.4, 0.19)
    love.window.setMode(windowW, windowH, {resizable=true, vsync=true, highdpi=true})
    cards.loadCardGraphics()
    vignetteImg = love.graphics.newImage("img/vignette.png")

    restartGame()
end

function love.keypressed(key)
    if key == "r" then
        restartGame()
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Right-clicking releases the held card without trying to place it
    if button == 2 and grabbedCard then
        cardSprites[grabbedCard.idx].grabbed = false
        grabbedCard = nil
        return
    end

    local currentTime = love.timer.getTime()
    debugMsg = string.format("Mouse click, x: %.0f, y: %.0f.", x, y)
    if not grabbedCard and BoundingBox.PointWithinBox(stockBox.x, stockBox.y, stockBox.w, stockBox.h, x, y) then
        -- Mouse press was on stock, draw to talon
        local cardIdx = drawCardFromStock()
        if cardIdx then
            local card = cardData[cardIdx]
            debugMsg = string.format("Clicked stock, drew %i of %s.", card.value, suitNames[card.suit])
            table.insert(talon, cardIdx)
            cardSprites[cardIdx].visible = true
            cardSprites[cardIdx].moveTime = currentTime
            cardSprites[cardIdx].up = true
            cardSprites[cardIdx].face = -1
            if table.getn(talon) > talonMaxCount then
                local talonBottom = table.remove(talon, 1)
                table.insert(stock, 1, talonBottom)

                -- Move talon card back to stock
                cardSprites[talonBottom].state = 0
                cardSprites[talonBottom].moveTime = currentTime
                cardSprites[talonBottom].visible = true
                cardSprites[talonBottom].up = true
                cardSprites[talonBottom].oX = stockX
                cardSprites[talonBottom].oY = stockY
            end
        end
    elseif not grabbedCard and BoundingBox.PointWithinBox(talonBox.x, talonBox.y, talonBox.w, talonBox.h, x, y) then
        -- Mouse press was on talon
        local talonCount = table.getn(talon)
        if talonCount > 0 and grabbedCard == nil then
            -- Only top-most card can be grabbed, check against that
            local cardIdx = talon[talonCount]
            local topCard = cardData[cardIdx]
            local cardBox = getCardSpriteBoundingBox(cardIdx)
            if BoundingBox.PointWithinBox(cardBox.x, cardBox.y, cardBox.w, cardBox.h, x, y) then
                debugMsg = string.format("Grabbed talon top card, %i of %s.", topCard.value, suitNames[topCard.suit])
                local cardSprite = cardSprites[cardIdx]
                cardSprite.grabbed = true
                grabbedCard = topCard
                grabOffset = { x = cardSprite.x - x, y = cardSprite.y - y }
            end
            -- TODO: Logic for finding eligible spot for card
        end
    elseif BoundingBox.PointWithinBox(tableauBox.x, tableauBox.y, tableauBox.w, tableauBox.h, x, y) then
        -- Mouse press was on tableau
        local checkX = sideSpacing;
        local column = -1
        for i = 1, 7 do
            if BoundingBox.PointWithinBox(checkX, tableauBox.y, cardW, tableauBox.h, x, y) then
                column = i
                debugMsg = string.format("Clicked tableau, column %i.", column)
                -- TODO: Check individual cards, starting from top-most
                break
            end
            checkX = checkX + cardW + cardSpacing
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    -- TODO: Logic for dropping a card
end

function love.update(dt)
    -- Recalculate every update in case window was resized
    tableauBox = { x = 0, y = tableauY - cardHHalf - 10, w = windowW, h = windowH - (tableauY - cardHHalf)}
    updateCardSprites(dt)
end

function drawStockStatic()
    local stockCount = table.getn(stock)
    if stockCount > 3 then stockCount = 3 end

    if stockCount > 0 then
        local x = stockX
        local y = stockY
        for i = 1, stockCount do
            love.graphics.setColor(0, 0, 0, 0.3)
            cards.drawCardShadow(x + 2, y + 2, 0, 0.51, 0.51)
            love.graphics.setColor(1, 1, 1, 1)
            cards.drawCardBack(cardBack, x, y, 0, 0.5, 0.5)
            x = x + 1
            y = y + 3
        end
    else
        drawEmptyCardSpace(stockX, stockY)
    end
end

function updateCardSprites(dt)
    local currentTime = love.timer.getTime()

    -- Hide stock cards once they've reached their destination
    for i, cardIdx in pairs(stock) do
        if cardSprites[cardIdx].visible and
           cardSprites[cardIdx].x == cardSprites[cardIdx].oX and
           cardSprites[cardIdx].y == cardSprites[cardIdx].oY then
            cardSprites[cardIdx].visible = false
        end
    end

    -- Update cards in talon
    local talonX = stockX + cardW + 20
    local talonY = stockY
    for i, cardIdx in pairs(talon) do
        cardSprites[cardIdx].oX = talonX
        cardSprites[cardIdx].oY = talonY
        talonX = talonX + 30
        talonY = talonY + 1
    end

    -- Update cards in tableau
    local tableauX = sideSpacing + cardWHalf
    for c, pile in pairs(tableau) do
        for row, cardIdx in pairs(pile) do
            cardSprites[cardIdx].oX = tableauX
            cardSprites[cardIdx].oY = tableauY + (row * 12)
            cardSprites[cardIdx].visible = currentTime >= cardSprites[cardIdx].moveTime
        end
        tableauX = tableauX + cardW + cardSpacing
    end

    -- Update movement for any visible card sprites that aren't grabbed
    for idx, sprite in pairs(cardSprites) do
        -- Sprites going to the tableau should become visible once they're moving
        if sprite.state == 2 and sprite.moveTime <= currentTime then sprite.visible = true end
        if sprite.visible then
            if sprite.grabbed then
                sprite.x = love.mouse.getX() + grabOffset.x
                sprite.y = love.mouse.getY() + grabOffset.y
            else
                if sprite.moveTime >= 0 and currentTime >= sprite.moveTime then
                    if math.abs(sprite.oX - sprite.x) < 0.2 then
                        sprite.x = sprite.oX
                    else
                        sprite.x = utils.lerp(sprite.x, sprite.oX, dt * spriteMoveSpeed)
                    end
                    if math.abs(sprite.oY - sprite.y) < 0.2 then
                        sprite.y = sprite.oY
                    else
                        sprite.y = utils.lerp(sprite.y, sprite.oY, dt * spriteMoveSpeed)
                    end
                    local destFace = -1
                    if sprite.up then destFace = 1 end
                    if math.abs(destFace - sprite.face) < 0.01 then
                        sprite.face = destFace
                    else
                        sprite.face = utils.lerp(sprite.face, destFace, dt * spriteFlipSpeed)
                    end
                end
            end
        end
    end
end

function drawCardSprites()
    for i, cardIdx in pairs(stock) do
        local sprite = cardSprites[cardIdx]
        if sprite.visible then
            drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
        end
    end

    -- Stock draws over stock-bound cards but under all others
    drawStockStatic()

    for i, cardIdx in pairs(talon) do
        local sprite = cardSprites[cardIdx]
        if sprite.visible and not sprite.grabbed then
            drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
        end
    end

    for col, pile in pairs(tableau) do
        for i, cardIdx in pairs(pile) do
            local sprite = cardSprites[cardIdx]
            if sprite.visible and not sprite.grabbed then
                drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
            end
        end
    end

    -- Draw grabbed card last, over everything else
    if grabbedCard then
        local cardIdx = grabbedCard.idx
        local sprite = cardSprites[cardIdx]
        drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
    end
end

function drawEmptyCardSpace(x, y)
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.35)
    love.graphics.rectangle("line", x - cardWHalf, y - cardHHalf, cardW, cardH, 4, 4, 8)
end

function drawFoundation()
    -- Similar drawing rules to the tableau, but skip the first 3 columns
    local x = sideSpacing + cardWHalf + ((cardW + cardSpacing) * 3)
    local y = stockY
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineWidth(2)
    for col, pile in pairs(foundation) do
        local pileCount = table.getn(pile)
        if pileCount > 0 then
            local topCardIdx = pile[table.getn(pile)]
            drawCard(topCardIdx, x, y, 1)
        else
            drawEmptyCardSpace(x, y)
        end
        x = x + cardW + cardSpacing
    end
end

function drawCard(idx, x, y, face)
    -- { idx=cardIdx, suit=s, value=v }
    local card = cardData[idx]
    local faceAbs = math.abs(face)
    local scaleX = faceAbs * 0.5
    local fade = utils.lerp(0.3, 1, faceAbs)
    local shadowScaleX = utils.lerp(0.05, 0.51, faceAbs)

    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.3)
    cards.drawCardShadow(x + 2, y + 2, 0, shadowScaleX, 0.51)

    love.graphics.setColor(fade, fade, fade, 1)
    if face > 0 then
        cards.drawCard(idx, x, y, 0, scaleX, 0.5)
    elseif face < 0 then
        cards.drawCardBack(cardBack, x, y, 0, scaleX, 0.5)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function drawVignette()
    local vW, vH = vignetteImg:getDimensions()
    local vScaleX = windowW / vW
    local vScaleY = windowH / vH
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.draw(vignetteImg, 0, 0, 0, vScaleX, vScaleY)
    love.graphics.setColor(1, 1, 1, 1)
end

function love.draw()
    windowW, windowH = love.graphics.getDimensions()
    local totalWidth = windowW - (sideSpacing * 2)
    cardSpacing = (totalWidth - (7 * cardW)) / 6
    drawVignette()
    drawFoundation()
    drawCardSprites()

    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.print(debugMsg, 10, windowH - 40)

    love.graphics.setColor(1, 1, 1, 1)
    local gameTime = math.max(0, love.timer.getTime() - (gameStartTime + gameStartDelay))
    love.graphics.print(string.format("Time: %.0f", gameTime), 10, windowH - 20)
end