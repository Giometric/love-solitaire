cards = require("cards")
utils = require("utils")
BoundingBox = require("BoundingBox")
Debug = require("Debug")

windowW = 640
windowH = 480
cardW = 70
cardH = 95
cardWHalf = cardW / 2
cardHHalf = cardH / 2
sideSpacing = 20
tableauSpacingX = ((windowW - (sideSpacing * 2)) - (7 * cardW)) / 6
tableauSpacingY = 14
stockX = sideSpacing + cardWHalf
stockY = sideSpacing + cardHHalf
tableauY = 210
cardBack = "red4"
talonMaxCount = 3
gameStartTime = -1
gameStartDelay = 0.3
gameTime = 0
gameComplete = false
dealDelayBetweenCards = 0.04
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
grabbedStack = {}
grabOffset = { x = 0, y = 0 }

-- Broad bounding boxes for clickable areas, used to narrow down number of collision checks
stockBox = { x = sideSpacing - 10, y = stockY - cardHHalf - 10, w = cardW + 20, h = cardH + 20 }
talonBox = { x = sideSpacing + cardW + tableauSpacingX - 10, y = stockY - cardHHalf - 10, w = cardW + 120, h = cardH + 20 }
tableauBox = {} -- refreshed in love.update
foundationSlotBoxes = { -- refreshed in love.update
    {}, {}, {}, {}
}

showDebug = false

function isCardSpriteAtDestination(cardSprite)
    return math.abs(cardSprite.oX - cardSprite.x) < 0.1 and
        math.abs(cardSprite.oY - cardSprite.y) < 0.1
end

function drawCardFromStock()
    if #stock > 0 then
        return table.remove(stock)
    else
        return nil
    end
end

function restartGame()
    gameStartTime = love.timer.getTime()
    gametime = 0
    gameComplete = false
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
            moveDelay = 0,
            grabbed = false,
            grabbedInStack = false,
            returning = false,
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

    local moveDelay = 0
    for row = 1, 7 do
        for c = 1, 7 do
            if c >= row then
                local cardIdx = drawCardFromStock()
                tableau[c][row] = cardIdx

                local cardSprite = cardSprites[cardIdx]
                if c == row then
                    cardSprite.up = true
                    cardSprite.face = -1
                else
                    cardSprite.up = false
                    cardSprite.face = -1
                end
                cardSprite.state = 2
                cardSprite.moveDelay = moveDelay
                moveDelay = moveDelay + dealDelayBetweenCards
            end
        end
    end

    talon = {}

    foundation = {
        {}, {}, {}, {}
    }

    Debug.Log("Game started.")
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
    vignetteImg = love.graphics.newImage("img/vignette.png", {})

    restartGame()
end

function love.keypressed(key)
    if key == "r" then
        restartGame()
    elseif key == "tab" then
        showDebug = not showDebug
    elseif key == "c" then
        Debug.ClearLogMessages()
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.wheelmoved(x, y)
    if showDebug then
        if Debug.HandleWheelMoved(x, y) then return end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if showDebug then
        Debug.HandleMousePressed(x, y, button, istouch, presses)
    end

    -- Right-clicking releases the held card without trying to place it
    if button == 2 and grabbedCard then
        releaseGrabbedSprites()
        return
    end

    -- If holding a card (that's not a stack), check if any of the foundation slots were clicked
    if button == 1 and grabbedCard and #grabbedStack == 0 then
        for i = 1, #foundationSlotBoxes do
            local box = foundationSlotBoxes[i]
            if BoundingBox.PointWithinBox(box.x, box.y, box.w, box.h, x, y) then
                if canPlaceCardOnFoundationSlot(grabbedCard, i) then
                    placeCardOnFoundationSlot(grabbedCard, i)
                    releaseGrabbedSprites()
                end
                -- Found a clicked slot, stop here
                return
            end
        end
    end

    if not grabbedCard and BoundingBox.PointWithinBox(stockBox.x, stockBox.y, stockBox.w, stockBox.h, x, y) then
        -- Mouse press was on stock, draw to talon
        local drawnCardIdx = drawCardFromStock()
        if drawnCardIdx then
            local card = cardData[drawnCardIdx]
            local cardSprite = cardSprites[drawnCardIdx]
            Debug.Log("Clicked stock, drew %i of %s.", card.value, suitNames[card.suit])
            table.insert(talon, drawnCardIdx)
            cardSprite.visible = true
            cardSprite.up = true
            cardSprite.face = -1
            cardSprite.state = 1
        end

        -- If the talon is already at the max count, or we're out of stock cards,
        -- put the bottom-most talon card back at the bottom of the stock
        if #talon > talonMaxCount or (not drawnCardIdx and #talon > 0) then
            local talonBottom = table.remove(talon, 1)
            local talonBottomSprite = cardSprites[talonBottom]
            table.insert(stock, 1, talonBottom)

            -- Move talon card back to stock
            talonBottomSprite.state = 0
            talonBottomSprite.visible = true
            talonBottomSprite.up = true
            talonBottomSprite.oX = stockX
            talonBottomSprite.oY = stockY
        end
    elseif not grabbedCard and BoundingBox.PointWithinBox(talonBox.x, talonBox.y, talonBox.w, talonBox.h, x, y) then
        -- Mouse press was on talon
        local talonCount = #talon
        if talonCount > 0 then
            -- Only top-most card can be grabbed, check against that
            local cardIdx = talon[talonCount]
            local topCard = cardData[cardIdx]
            local cardBox = getCardSpriteBoundingBox(cardIdx)
            if BoundingBox.PointWithinBox(cardBox.x, cardBox.y, cardBox.w, cardBox.h, x, y) then
                if button == 1 then
                    Debug.Log("Grabbed talon top card, %i of %s.", topCard.value, suitNames[topCard.suit])
                    grabCardSprite(cardIdx)
                elseif button == 2 then
                    Debug.LogWarning("Attempting to auto-place card %i of %s.", topCard.value, suitNames[topCard.suit])
                    tryAutoPlaceOnFoundation(cardIdx)
                end
            end
        end
    elseif BoundingBox.PointWithinBox(tableauBox.x, tableauBox.y, tableauBox.w, tableauBox.h, x, y) then
        -- Mouse press was on tableau
        local checkX = sideSpacing
        for i = 1, 7 do -- Check which column was clicked, left-to-right
            if BoundingBox.PointWithinBox(checkX, tableauBox.y, cardW, tableauBox.h, x, y) then
                Debug.Log("Clicked tableau, column %i.", i)
                local column = tableau[i]

                if grabbedCard then
                    -- If we're holding a card, only check the top-most card of this column,
                    -- or check if the column is empty if placing a King
                    local grabbedCardData = cardData[grabbedCard]
                    local attemptPlace = false
                    if #column == 0 then
                        attemptPlace = true
                    else
                        local clickedCardIdx = column[#column]
                        local cardBox = getCardSpriteBoundingBox(clickedCardIdx)
                        if BoundingBox.PointWithinBox(cardBox.x, cardBox.y, cardBox.w, cardBox.h, x, y) then
                            attemptPlace = true
                        end
                    end

                    -- Try to place the held card
                    if attemptPlace and canPlaceCardOnTableauColumn(grabbedCard, i) then
                        if placeCardOnTableau(grabbedCard, i) then
                            Debug.Log("Placed card %i of %s onto tableau column %i.", grabbedCardData.value, suitNames[grabbedCardData.suit], i)
                            releaseGrabbedSprites()
                        else
                            Debug.LogWarning("Failed to place card %i of %s onto %i.", grabbedCardData.value, suitNames[grabbedCardData.suit], i)
                        end
                    end
                else
                    -- Not holding a card. If right-clicking, check if the top-most card can be auto-placed
                    -- onto the foundation. Otherwise, check for collisions, starting from the
                    -- last (top-most) card on this column to see if we can pick one up
                    if button == 2 and #column > 0 then
                        local topCardIdx = column[#column]
                        local topCardData = cardData[topCardIdx]
                        Debug.LogWarning("Attempting to auto-place tableau card %i of %s.", topCardData.value, suitNames[topCardData.suit])
                        tryAutoPlaceOnFoundation(topCardIdx)
                    else
                        for rowIdx = #column, 1, -1 do
                            local clickedCardIdx = column[rowIdx]
                            local clickedCardSprite = cardSprites[clickedCardIdx]
                            -- Only allow clicking cards which are face-up
                            if clickedCardSprite.up then
                                local cardBox = getCardSpriteBoundingBox(clickedCardIdx)
                                if BoundingBox.PointWithinBox(cardBox.x, cardBox.y, cardBox.w, cardBox.h, x, y) then
                                    local clickedCardData = cardData[clickedCardIdx]
                                    Debug.Log("Grabbed tableau card, %i of %s.", clickedCardData.value, suitNames[clickedCardData.suit])
                                    -- Pick up all the cards stacked on top of the one we clicked
                                    local stackedCards = {}
                                    for stackIdx = rowIdx + 1, #column do
                                        table.insert(stackedCards, column[stackIdx])
                                    end
                                    grabCardSprite(clickedCardIdx, stackedCards)
                                    -- Found a clicked card, stop here
                                    break
                                end
                            end
                        end
                    end
                end
                -- Found which column was clicked, break from here
                break
            end
            checkX = checkX + cardW + tableauSpacingX
        end
    end
end

function findCardInTableau(cardIdx)
    for columnIdx = 1, 7 do
        local column = tableau[columnIdx]
        for rowIdx, columnCardIdx in pairs(column) do
            if columnCardIdx == cardIdx then
                return columnIdx, rowIdx
            end
        end
    end
    return -1, -1
end

function areCardsOpposingSuits(a, b)
    return
        ((a.suit == 1 or a.suit == 4) and (b.suit == 2 or b.suit == 3)) or
        ((a.suit == 2 or a.suit == 3) and (b.suit == 1 or b.suit == 4))
end

function canPlaceCardOnTableauColumn(placingCardIdx, columnIdx)
    local placingCard = cardData[placingCardIdx]
    local column = tableau[columnIdx]
    if #column == 0 then
        -- Only Kings can be placed in empty columns
        return placingCard.value == 13
    else
        local tableauCardIdx = column[#column]
        local tableauCard = cardData[tableauCardIdx]
        return areCardsOpposingSuits(placingCard, tableauCard) and placingCard.value == tableauCard.value - 1
    end
end

function canPlaceCardOnFoundationSlot(placingCardIdx, slotIdx)
    local placingCard = cardData[placingCardIdx]
    local pile = foundation[slotIdx]

    if #pile == 0 then
        -- Only Ace (any suit) can be placed in empty foundation slots
        return placingCard.value == 1
    else
        local topCardIdx = pile[#pile]
        local topCardSuit = cardData[topCardIdx].suit
        local topCardValue = cardData[topCardIdx].value
        -- Only cards of the same suit and the next value up can be placed
        return placingCard.suit == topCardSuit and placingCard.value == topCardValue + 1
    end
end

function grabCardSprite(cardIdx, stackedCards)
    -- Release previously-grabbed cards
    releaseGrabbedSprites()

    local cardSprite = cardSprites[cardIdx]
    cardSprite.grabbed = true
    cardSprite.grabbedInStack = false
    cardSprite.returning = false
    grabbedCard = cardIdx
    mouseX, mouseY = love.mouse.getPosition()
    grabOffset = { x = cardSprite.x - mouseX, y = cardSprite.y - mouseY }

    if stackedCards then
        for _, stackCardIdx in pairs(stackedCards) do
            local stackCardSprite = cardSprites[stackCardIdx]
            stackCardSprite.grabbed = false
            stackCardSprite.grabbedInStack = true
            stackCardSprite.returning = false
            table.insert(grabbedStack, stackCardIdx)
        end
    end
end

function releaseGrabbedSprites()
    if grabbedCard then
        local cardSprite = cardSprites[grabbedCard]
        cardSprite.grabbed = false
        cardSprite.returning = true
        grabbedCard = nil
    end

    for _, cardIdx in pairs(grabbedStack) do
        local cardSprite = cardSprites[cardIdx]
        cardSprite.grabbedInStack = false
        cardSprite.returning = true
    end
    grabbedStack = {}
end

function placeCardOnTableau(cardIdx, columnIdx)
    local cardSprite = cardSprites[cardIdx]
    if cardSprite.state == 1 then
        -- Card was top-most in talon
        table.remove(talon)
        table.insert(tableau[columnIdx], cardIdx)
        cardSprite.state = 2
        cardSprite.returning = true
        return true
    elseif cardSprite.state == 2 then
        -- Card was in tableau, find which column it came from, remove it from there, and then place
        local foundColumn, foundRow = findCardInTableau(cardIdx)
        if foundColumn == -1 then
            Debug.LogError("Failed to find tableau card anywhere in the tableau!")
        else
            local stack = {}
            local foundColumnCount = #tableau[foundColumn]
            -- Remove cards from the top until we have the entire stack, starting from the card that was clicked
            -- Add them one by one to the top of the clicked column
            for i = foundRow, foundColumnCount do
                local topCardIdx = table.remove(tableau[foundColumn], foundRow)
                local topCardSprite = cardSprites[topCardIdx]
                topCardSprite.returning = true
                table.insert(tableau[columnIdx], topCardIdx)
            end

            -- Flip over the new top card, if any are left in our previous column
            if #tableau[foundColumn] > 0 then
                local newTopCardIdx = tableau[foundColumn][#tableau[foundColumn]]
                local newTopCardSprite = cardSprites[newTopCardIdx]
                newTopCardSprite.up = true
            end
            return true
        end
    end
    return false
end

function placeCardOnFoundationSlot(cardIdx, slotIdx)
    local cardSprite = cardSprites[cardIdx]
    local placedData = cardData[cardIdx]
    if cardSprite.state == 1 then
        -- Card was top-most in talon
        table.remove(talon)
        table.insert(foundation[slotIdx], cardIdx)
        cardSprite.state = 3
        Debug.Log("Placed %i of %s onto foundation slot %i", placedData.value, suitNames[placedData.suit], slotIdx)
        return true
    elseif cardSprite.state == 2 then
        -- Card was in tableau, find which column it came from, remove it from there, and then place
        local foundColumn, foundRow = findCardInTableau(cardIdx)
        if foundColumn == -1 then
            Debug.LogError("Failed to find tableau card anywhere in the tableau!")
        else
            -- TODO: Support adding a stack?
            local placedCardIdx = table.remove(tableau[foundColumn], foundRow)
            local placedCardSprite = cardSprites[placedCardIdx]
            placedCardSprite.state = 3
            table.insert(foundation[slotIdx], placedCardIdx)

            -- Flip over the new top card, if any are left in the tableau column
            if #tableau[foundColumn] > 0 then
                local newTopCardIdx = tableau[foundColumn][#tableau[foundColumn]]
                local newTopCardSprite = cardSprites[newTopCardIdx]
                newTopCardSprite.up = true
            end
            Debug.Log("Placed %i of %s onto foundation slot %i", placedData.value, suitNames[placedData.suit], slotIdx)
            return true
        end
    end
    return false
end

function tryAutoPlaceOnFoundation(cardIdx)
    for i = 1, #foundation do
        if canPlaceCardOnFoundationSlot(cardIdx, i) then
            placeCardOnFoundationSlot(cardIdx, i)
            return true
        end
    end
    return false
end

function love.mousereleased(x, y, button, istouch, presses)
    -- TODO: Logic for dropping a card
end

function love.update(dt)
    -- Recalculate every update in case window was resized
    tableauBox = { x = 0, y = tableauY - cardHHalf - 10, w = windowW, h = windowH - (tableauY - cardHHalf) }

    local foundationX = sideSpacing + ((cardW + tableauSpacingX) * 3)
    local foundationY = stockY - cardHHalf
    for i = 0, 3 do
        foundationSlotBoxes[i + 1] = { x = foundationX, y = foundationY, w = cardW, h = cardH }
        foundationX = foundationX + cardW + tableauSpacingX
    end

    -- Check if we've finished the game by counting up the cards in the foundation
    gameComplete = true
    for _, pile in pairs(foundation) do
        if #pile < 13 then
            gameComplete = false
            break
        end
    end

    if gameComplete then
        -- Do game completed stuff
    else
        gameTime = math.max(0, love.timer.getTime() - (gameStartTime + gameStartDelay))
    end
    updateCardSprites(dt)
end

function drawStockStatic()
    local stockCount = #stock
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
    local startDelayEnd = gameStartTime + gameStartDelay
    local timeSinceStartDelay = currentTime - startDelayEnd
    local startDelayFinished = timeSinceStartDelay >= 0

    -- Hide stock cards once they've reached their destination
    for _, cardIdx in pairs(stock) do
        local cardSprite = cardSprites[cardIdx]
        if cardSprite.visible and isCardSpriteAtDestination(cardSprite) then
            cardSprite.visible = false
        end
    end

    -- Move foundation cards into place, keeping only the top 3 visible
    local foundationX = sideSpacing + cardWHalf + ((cardW + tableauSpacingX) * 3)
    local foundationY = stockY
    for _, pile in pairs(foundation) do
        local pileCount = #pile
        local minDrawPile = math.max(pileCount - 2, 1)
        if pileCount > 0 then
            local pileX = foundationX
            local pileY = foundationY
            for i = pileCount, 1, -1 do
                local cardIdx = pile[i]
                local cardSprite = cardSprites[cardIdx]
                cardSprite.visible = i >= minDrawPile
                if cardSprite.visible then
                    cardSprite.oX = pileX
                    cardSprite.oY = pileY
                end
            end
        end
        foundationX = foundationX + cardW + tableauSpacingX
    end

    -- Update cards in talon
    local talonX = stockX + cardW + 20
    local talonY = stockY
    for i, cardIdx in pairs(talon) do
        local cardSprite = cardSprites[cardIdx]
        if not cardSprite.grabbed and not cardSprite.grabbedInStack then
            cardSprite.oX = talonX
            cardSprite.oY = talonY
            talonX = talonX + 30
            talonY = talonY + 1
            -- If a returning talon card is no longer the top-most, take away its 'returning' status
            -- so that it no longer draws over the top of all other cards
            if cardSprite.returning and (not cardSprite.visible or i ~= #talon or isCardSpriteAtDestination(cardSprite)) then
                cardSprite.returning = false
            end
        end
    end

    -- Update cards in tableau
    local tableauX = sideSpacing + cardWHalf
    for _, pile in pairs(tableau) do
        for row, cardIdx in pairs(pile) do
            local cardSprite = cardSprites[cardIdx]
            if not cardSprite.grabbed and not cardSprite.grabbedInStack then
                cardSprite.oX = tableauX
                cardSprite.oY = tableauY + (row * tableauSpacingY)
                cardSprite.visible = cardSprite.moveDelay <= timeSinceStartDelay
                if cardSprite.returning and (isCardSpriteAtDestination(cardSprite) or not cardSprite.visible) then
                    cardSprite.returning = false
                end
            end
        end
        tableauX = tableauX + cardW + tableauSpacingX
    end

    -- If game start delay is done, update movement for any visible card sprites
    if startDelayFinished then
        for _, sprite in pairs(cardSprites) do
            if sprite.visible then
                if not sprite.grabbed and not sprite.grabbedInStack then
                    if isCardSpriteAtDestination(sprite) then
                        sprite.x = sprite.oX
                        sprite.y = sprite.oY
                    else
                        sprite.x = utils.lerp(sprite.x, sprite.oX, dt * spriteMoveSpeed)
                        sprite.y = utils.lerp(sprite.y, sprite.oY, dt * spriteMoveSpeed)
                    end

                    local destFace = -1
                    if sprite.up then destFace = 1 end
                    if math.abs(destFace - sprite.face) < 0.02 then
                        sprite.face = destFace
                    else
                        sprite.face = utils.lerp(sprite.face, destFace, dt * spriteFlipSpeed)
                    end
                end
            end
        end
    end

    -- Update positions of grabbed cards
    if grabbedCard then
        local mouseX, mouseY = love.mouse.getPosition()
        local grabPosX = mouseX + grabOffset.x
        local grabPosY = mouseY + grabOffset.y
        local grabbedSprite = cardSprites[grabbedCard]
        grabbedSprite.x = grabPosX
        grabbedSprite.y = grabPosY
        
        for i, cardIdx in pairs(grabbedStack) do
            grabPosY = grabPosY + tableauSpacingY
            local stackSprite = cardSprites[cardIdx]
            stackSprite.x = grabPosX
            stackSprite.y = grabPosY
        end
    end
end

function drawCardSprites()
    for _, cardIdx in pairs(stock) do
        local sprite = cardSprites[cardIdx]
        if sprite.visible then
            drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
        end
    end

    -- Stock draws over stock-bound cards but under all others
    drawStockStatic()

    for _, cardIdx in pairs(talon) do
        local sprite = cardSprites[cardIdx]
        if sprite.visible and not sprite.grabbed and not sprite.grabbedInStack and not sprite.returning then
            drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
        end
    end

    for _, pile in pairs(tableau) do
        for i, cardIdx in pairs(pile) do
            local sprite = cardSprites[cardIdx]
            if sprite.visible and not sprite.grabbed and not sprite.grabbedInStack and not sprite.returning then
                drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
            end
        end
    end

    for _, pile in pairs(foundation) do
        for i, cardIdx in pairs(pile) do
            local sprite = cardSprites[cardIdx]
            if sprite.visible then
                drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
            end
        end
    end

    -- Draw cards returning to the talon or tableau above others
    for _, cardIdx in pairs(talon) do
        local sprite = cardSprites[cardIdx]
        if sprite.returning then
            drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
        end
    end

    for _, pile in pairs(tableau) do
        for _, cardIdx in pairs(pile) do
            local sprite = cardSprites[cardIdx]
            if sprite.returning then
                drawCard(cardIdx, sprite.x, sprite.y, sprite.face)
            end
        end
    end

    -- Draw grabbed card last, over everything else, then any cards grabbed as part of the stack
    if grabbedCard then
        local sprite = cardSprites[grabbedCard]
        drawCard(grabbedCard, sprite.x, sprite.y, sprite.face, true)
        
        for i, cardIdx in pairs(grabbedStack) do
            local stackSprite = cardSprites[cardIdx]
            drawCard(cardIdx, stackSprite.x, stackSprite.y, stackSprite.face, true)
        end
    end
end

function drawEmptyCardSpace(x, y)
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.35)
    love.graphics.rectangle("line", x - cardWHalf, y - cardHHalf, cardW, cardH, 4, 4, 8)
end

function drawFoundationStatic()
    -- Similar positioning rules to the tableau, but skip the first 3 columns
    local x = sideSpacing + cardWHalf + ((cardW + tableauSpacingX) * 3)
    local y = stockY
    for _, _ in pairs(foundation) do
        -- Always draw the empty card outline
        drawEmptyCardSpace(x, y)
        x = x + cardW + tableauSpacingX
    end
end

function drawCard(idx, x, y, face, grabbed)
    grabbed = grabbed or false
    local faceAbs = math.abs(face)
    local cardScale = 0.5
    if grabbed then cardScale = 0.52 end
    local scaleX = faceAbs * cardScale
    local fade = utils.lerp(0.3, 1, faceAbs)
    local shadowScaleX = utils.lerp(0.05, cardScale + 0.01, faceAbs)

    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.3)
    local shadowDist = 2
    if grabbed then shadowDist = 6 end
    cards.drawCardShadow(x + shadowDist, y + shadowDist, 0, shadowScaleX, cardScale)

    love.graphics.setColor(fade, fade, fade, 1)
    if face > 0 then
        cards.drawCard(idx, x, y, 0, scaleX, cardScale)
    elseif face < 0 then
        cards.drawCardBack(cardBack, x, y, 0, scaleX, cardScale)
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
    tableauSpacingX = (totalWidth - (7 * cardW)) / 6
    drawVignette()
    drawFoundationStatic()
    drawCardSprites()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Time: %.0f", gameTime), 10, windowH - 20)
    if gameComplete then
        love.graphics.print(string.format("You win!!!"), 10, windowH - 40)
    end

    if showDebug then Debug.DrawDebug() end
end