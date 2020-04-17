--[[
    Some trigonometry utilities for calcualating angles and distances
]] --

function calculateAngle(dx, dy)
    return math.atan(dy / dx)
end

function calculateVerticalSideLength(angle, adjacentSideLength)
    return  math.abs(math.tan(angle) * adjacentSideLength)
end

function calculateHorizontalSideLength(angle, oppositeSideLength)
    return math.abs(oppositeSideLength / math.tan(angle))
end
