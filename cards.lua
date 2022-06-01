local cards = {}

function cards.loadCardGraphics()
    cardsImg = love.graphics.newImage("img/playingCards.png", {mipmaps=true})
    cardsImg:setFilter("linear", "linear", 8)
    local cardsImgWidth = cardsImg:getWidth();
    local cardsImgHeight = cardsImg:getHeight();

    cardQuads = {
        love.graphics.newQuad(560, 570, 140, 190, cardsImgWidth, cardsImgHeight), -- cA
        love.graphics.newQuad(280, 1140, 140, 190, cardsImgWidth, cardsImgHeight), -- c2
        love.graphics.newQuad(700, 190, 140, 190, cardsImgWidth, cardsImgHeight), -- c3
        love.graphics.newQuad(700, 0, 140, 190, cardsImgWidth, cardsImgHeight), -- c4
        love.graphics.newQuad(560, 1710, 140, 190, cardsImgWidth, cardsImgHeight), -- c5
        love.graphics.newQuad(560, 1520, 140, 190, cardsImgWidth, cardsImgHeight), -- c6
        love.graphics.newQuad(560, 1330, 140, 190, cardsImgWidth, cardsImgHeight), -- c7
        love.graphics.newQuad(560, 1140, 140, 190, cardsImgWidth, cardsImgHeight), -- c8
        love.graphics.newQuad(560, 950, 140, 190, cardsImgWidth, cardsImgHeight), -- c9
        love.graphics.newQuad(560, 760, 140, 190, cardsImgWidth, cardsImgHeight), -- c10
        love.graphics.newQuad(560, 380, 140, 190, cardsImgWidth, cardsImgHeight), -- cJ
        love.graphics.newQuad(560, 0, 140, 190, cardsImgWidth, cardsImgHeight), -- cQ
        love.graphics.newQuad(560, 190, 140, 190, cardsImgWidth, cardsImgHeight), -- cK
        love.graphics.newQuad(420, 0, 140, 190, cardsImgWidth, cardsImgHeight), -- dA
        love.graphics.newQuad(420, 1710, 140, 190, cardsImgWidth, cardsImgHeight), -- d2
        love.graphics.newQuad(420, 1520, 140, 190, cardsImgWidth, cardsImgHeight), -- d3
        love.graphics.newQuad(420, 1330, 140, 190, cardsImgWidth, cardsImgHeight), -- d4
        love.graphics.newQuad(420, 1140, 140, 190, cardsImgWidth, cardsImgHeight), -- d5
        love.graphics.newQuad(420, 950, 140, 190, cardsImgWidth, cardsImgHeight), -- d6
        love.graphics.newQuad(420, 760, 140, 190, cardsImgWidth, cardsImgHeight), -- d7
        love.graphics.newQuad(420, 570, 140, 190, cardsImgWidth, cardsImgHeight), -- d8
        love.graphics.newQuad(420, 380, 140, 190, cardsImgWidth, cardsImgHeight), -- d9
        love.graphics.newQuad(420, 190, 140, 190, cardsImgWidth, cardsImgHeight), -- d10
        love.graphics.newQuad(280, 1710, 140, 190, cardsImgWidth, cardsImgHeight), -- dJ
        love.graphics.newQuad(280, 1330, 140, 190, cardsImgWidth, cardsImgHeight), -- dQ
        love.graphics.newQuad(280, 1520, 140, 190, cardsImgWidth, cardsImgHeight), -- dK
        love.graphics.newQuad(140, 1330, 140, 190, cardsImgWidth, cardsImgHeight), -- hA
        love.graphics.newQuad(700, 380, 140, 190, cardsImgWidth, cardsImgHeight), -- h2
        love.graphics.newQuad(280, 950, 140, 190, cardsImgWidth, cardsImgHeight), -- h3
        love.graphics.newQuad(280, 760, 140, 190, cardsImgWidth, cardsImgHeight), -- h4
        love.graphics.newQuad(280, 570, 140, 190, cardsImgWidth, cardsImgHeight), -- h5
        love.graphics.newQuad(280, 380, 140, 190, cardsImgWidth, cardsImgHeight), -- h6
        love.graphics.newQuad(280, 190, 140, 190, cardsImgWidth, cardsImgHeight), -- h7
        love.graphics.newQuad(280, 0, 140, 190, cardsImgWidth, cardsImgHeight), -- h8
        love.graphics.newQuad(140, 1710, 140, 190, cardsImgWidth, cardsImgHeight), -- h9
        love.graphics.newQuad(140, 1520, 140, 190, cardsImgWidth, cardsImgHeight), -- h10
        love.graphics.newQuad(140, 1140, 140, 190, cardsImgWidth, cardsImgHeight), -- hJ
        love.graphics.newQuad(140, 760, 140, 190, cardsImgWidth, cardsImgHeight), -- hQ
        love.graphics.newQuad(140, 950, 140, 190, cardsImgWidth, cardsImgHeight), -- hK
        love.graphics.newQuad(0, 570, 140, 190, cardsImgWidth, cardsImgHeight), -- sA
        love.graphics.newQuad(140, 380, 140, 190, cardsImgWidth, cardsImgHeight), -- s2
        love.graphics.newQuad(140, 190, 140, 190, cardsImgWidth, cardsImgHeight), -- s3
        love.graphics.newQuad(140, 0, 140, 190, cardsImgWidth, cardsImgHeight), -- s4
        love.graphics.newQuad(0, 1710, 140, 190, cardsImgWidth, cardsImgHeight), -- s5
        love.graphics.newQuad(0, 1520, 140, 190, cardsImgWidth, cardsImgHeight), -- s6
        love.graphics.newQuad(0, 1330, 140, 190, cardsImgWidth, cardsImgHeight), -- s7
        love.graphics.newQuad(0, 1140, 140, 190, cardsImgWidth, cardsImgHeight), -- s8
        love.graphics.newQuad(0, 950, 140, 190, cardsImgWidth, cardsImgHeight), -- s9
        love.graphics.newQuad(0, 760, 140, 190, cardsImgWidth, cardsImgHeight), -- s10
        love.graphics.newQuad(0, 380, 140, 190, cardsImgWidth, cardsImgHeight), -- sJ
        love.graphics.newQuad(0, 0, 140, 190, cardsImgWidth, cardsImgHeight), -- sQ
        love.graphics.newQuad(0, 190, 140, 190, cardsImgWidth, cardsImgHeight), -- sK
        love.graphics.newQuad(140, 570, 140, 190, cardsImgWidth, cardsImgHeight) -- joker
    }

    cardBacksImg = love.graphics.newImage("img/playingCardBacks.png", {mipmaps=true})
    cardBacksImg:setFilter("linear", "linear", 8)
    local cardBacksImgWidth = cardBacksImg:getWidth();
    local cardBacksImgHeight = cardBacksImg:getHeight();

    cardBackQuads = {
        blue1 = love.graphics.newQuad(140, 380, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        blue2 = love.graphics.newQuad(280, 570, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        blue3 = love.graphics.newQuad(280, 380, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        blue4 = love.graphics.newQuad(280, 190, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        blue5 = love.graphics.newQuad(280, 0, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        green1 = love.graphics.newQuad(140, 760, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        green2 = love.graphics.newQuad(140, 570, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        green3 = love.graphics.newQuad(280, 760, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        green4 = love.graphics.newQuad(140, 190, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        green5 = love.graphics.newQuad(140, 0, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        red1 = love.graphics.newQuad(0, 760, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        red2 = love.graphics.newQuad(0, 570, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        red3 = love.graphics.newQuad(0, 380, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        red4 = love.graphics.newQuad(0, 190, 140, 190, cardBacksImgWidth, cardBacksImgHeight),
        red5 = love.graphics.newQuad(0, 0, 140, 190, cardBacksImgWidth, cardBacksImgHeight)
    }

    cardShadowImg = love.graphics.newImage("img/cardShadow.png", {mipmaps=true})
    cardShadowImg:setFilter("linear", "linear", 2)
end

function cards.drawCard(idx, x, y, rotation, scaleX, scaleY)
    rotation = rotation or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    local cardQuad = cardQuads[idx]
    qx, qy, qw, qh = cardQuad:getViewport()
    
    love.graphics.draw(cardsImg, cardQuad, x, y, rotation, scaleX, scaleY, qw/2.0, qh/2.0)
end

function cards.drawCardBack(name, x, y, rotation, scaleX, scaleY)
    rotation = rotation or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    local cardBackQuad = cardBackQuads[name]
    qx, qy, qw, qh = cardBackQuad:getViewport()
    
    love.graphics.draw(cardBacksImg, cardBackQuad, x, y, rotation, scaleX, scaleY, qw/2.0, qh/2.0)
end

function cards.drawCardShadow(x, y, rotation, scaleX, scaleY)
    rotation = rotation or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    local w = cardShadowImg:getWidth();
    local h = cardShadowImg:getHeight();
    
    love.graphics.draw(cardShadowImg, x, y, rotation, scaleX, scaleY, w/2.0, h/2.0)
end

return cards