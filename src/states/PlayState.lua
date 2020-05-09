--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

-- power up spawn time
local POWER_UP_SPAWN_TIME_MIN = 10
local POWER_UP_SPAWN_TIME_MAX = 20

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    self.recoverPoints = 5000
    self.paddleGrowthPoints = params.paddleGrowthPoints and params.paddleGrowthPoints or PADDLE_GROWTH_TIER

    self.powerUps = {}
    self.caughtPowerUps = params.caughtPowerUps and params.caughtPowerUps or {}

    self.additionalBalls = {}

    self:resetPowerUpSpawnTimer()

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)

    -- update power ups and detect collisions
    for k, powerUp in pairs(self.powerUps) do
        powerUp:update(dt)

        if powerUp:collides(self.paddle) then
            gSounds['paddle-hit']:play()
            self:applyPowerUp(powerUp)
            table.remove(self.powerUps, k)
        end

        if powerUp.y >= VIRTUAL_HEIGHT then
            table.remove(self.powerUps, k)
        end
    end

    -- update timer for power up spawning
    self.powerUpSpawnTimer = self.powerUpSpawnTimer + dt

    -- spawn a new power up
    if self.powerUpSpawnTimer > self.timeUntilPowerUpSpawn then
       self:spawnPowerUp()
       self:resetPowerUpSpawnTimer()
    end

    self:checkBallCollisions(self.ball)

    for k, ball in pairs(self.additionalBalls) do
        ball:update(dt)
        self:checkBallCollisions(ball)

        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.additionalBalls, k)
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT then

        -- If we have more balls from a power up then make one of those balls the new main ball
        if table.getn(self.additionalBalls) > 0 then
            self.ball = table.remove(self.additionalBalls, 1)
        else
            self.health = self.health - 1
            gSounds['hurt']:play()
    
            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            else
                self.paddle:changeSize(math.max(1, self.paddle.size - 1))
    
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints,
                    paddleGrowthPoints = self.paddleGrowthPoints,
                    caughtPowerUps = self.caughtPowerUps
                })
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render power ups
    for k, powerUp in pairs(self.powerUps) do
        powerUp:render()
    end

    self.paddle:render()
    self.ball:render()

    for k, ball in pairs(self.additionalBalls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end

function PlayState:checkBallCollisions(ball)

    if ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        ball.y = self.paddle.y - 8
        ball.dy = -ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))

        -- else if we hit the paddle on its right side while moving right...
        elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
        end

        gSounds['paddle-hit']:play()
    end


    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and ball:collides(brick) then

            if brick.locked and not self:hasKey() then
                -- sound on hit
                gSounds['brick-hit-locked']:stop()
                gSounds['brick-hit-locked']:play()
            else

                local multiplier = brick.locked and 2 or 1

                -- add to score
                self.score = self.score + ((brick.tier * 200 + brick.color * 25)) * multiplier

                -- trigger the brick's hit function, which removes it from play
                brick:hit()
            end

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            if self.score > self.paddleGrowthPoints then

                -- increase paddle size, max of 4
                self.paddle:changeSize(math.min(4, self.paddle.size + 1))

                -- increase paddle growth points
                self.paddleGrowthPoints = self.paddleGrowthPoints + PADDLE_GROWTH_TIER

                -- play paddle growth sound
                gSounds['paddle-growth']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints,
                    paddleGrowthPoints = self.paddleGrowthPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if ball.x + 2 < brick.x and ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(ball.dy) < 150 then
                ball.dy = ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end

        -- Lua's version of the 'continue' statement
        ::continue::
    end

end

function PlayState:spawnPowerUp()

    local powerUpX = math.random(0, VIRTUAL_WIDTH)

    -- Figure out whether to spawn key or multi ball
    if self:hasLockedBrick() and not self:hasKey() and RandomBoolean() then
        table.insert(self.powerUps, PowerUp(POWER_UP_SKIN_KEY, powerUpX))
    else
        table.insert(self.powerUps, PowerUp(POWER_UP_SKIN_MULTI_BALL, powerUpX))
    end
end

function PlayState:applyPowerUp(powerUp)

    if powerUp.skin == POWER_UP_SKIN_MULTI_BALL then
        -- Generate two random balls

        local ball1 = Ball(math.random(7))
        ball1.dx = math.random(-200, 200)
        ball1.dy = math.random(-50, -60)
        ball1.x = self.ball.x
        ball1.y = self.ball.y

        table.insert(self.additionalBalls, ball1)

        local ball2 = Ball(math.random(7))
        ball2.dx = math.random(-200, 200)
        ball2.dy = math.random(-50, -60)
        ball2.x = self.ball.x
        ball2.y = self.ball.y

        table.insert(self.additionalBalls, ball2)
    end

    table.insert(self.caughtPowerUps, powerUp)
end


function PlayState:resetPowerUpSpawnTimer()
    self.powerUpSpawnTimer = 0
    self.timeUntilPowerUpSpawn = math.random(POWER_UP_SPAWN_TIME_MIN, POWER_UP_SPAWN_TIME_MAX)
end

function PlayState:hasLockedBrick()
    for k, brick in pairs(self.bricks) do
        if brick.locked then
            return true
        end
    end

    return false
end

function PlayState:hasKey()
    for k, caughtPowerUp in pairs(self.caughtPowerUps) do
        if caughtPowerUp.skin == POWER_UP_SKIN_KEY then
            return true
        end
    end

    return false
end