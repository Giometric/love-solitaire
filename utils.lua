local utils = {}

function utils.lerp(a,b,t) return a * (1-t) + b * t end

-- From https://gist.github.com/Uradamus/10323382?permalink_comment_id=2754684#gistcomment-2754684
-- In-place array shuffle
function utils.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = love.math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

return utils