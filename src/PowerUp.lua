--[[
    GD50
    Breakout Remake

    -- PowerUp Class --

    Author: Brandon Tate
    brandonntate@gmail.com

    Represents a power up that a player can catch with the paddle
]]

PowerUp = Class{}

function PowerUp:init(skin, x)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16

    self.x = x
    self.y = -self.height

    -- these variables are for keeping track of our velocity on both the
    -- X and Y axis, since the ball can move in two dimensions
    self.dy = math.random(20, 60)
    self.dx = 0

    -- this will be the type of power up, and we will index
    -- our table of Quads relating to the global block texture using this
    self.skin = skin
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function PowerUp:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    -- if the above aren't true, they're overlapping
    return true
end

function PowerUp:update(dt)
    self.y = self.y + self.dy * dt
end

function PowerUp:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['power-ups'][self.skin],
        self.x, self.y)
end