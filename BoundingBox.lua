local BoundingBox = {}
-- From https://love2d.org/wiki/BoundingBox.lua
-- Collision detection function;
-- Returns true if two boxes overlap, false if they don't;
-- x1,y1 are the top-left coords of the first box, while w1,h1 are its width and height;
-- x2,y2,w2 & h2 are the same, but for the second box.
function BoundingBox.CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and
           x2 < x1+w1 and
           y1 < y2+h2 and
           y2 < y1+h1
end

-- Check if the point defined by x,y is within the specified box
-- x1,y1 are the top-left coords of the box, while w1,h1 are its width and height
function BoundingBox.PointWithinBox(x1,y1,w1,h1, x,y)
    return x >= x1 and x <= x1+w1 and
           y >= y1 and y <= y1+h1
end

return BoundingBox