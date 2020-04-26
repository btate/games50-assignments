--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

local BRONZE_SCORE = 2
local SILVER_SCORE = 4
local GOLD_SCORE = 6

function ScoreState:init()
    self.bronzeImage = love.graphics.newImage('bronze.png')
    self.silverImage = love.graphics.newImage('silver.png')
    self.goldImage = love.graphics.newImage('gold.png')
end

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')

    trophyX = (VIRTUAL_WIDTH / 2) - (self.goldImage:getWidth() / 2)
    trophyY = 120

    if self.score >= GOLD_SCORE then
        love.graphics.draw(self.goldImage, trophyX, trophyY)
    elseif self.score >= SILVER_SCORE then
        love.graphics.draw(self.silverImage, trophyX, trophyY)
    elseif self.score >= BRONZE_SCORE then
        love.graphics.draw(self.bronzeImage, trophyX, trophyY)
    end

    love.graphics.printf('Press Enter to Play Again!', 0, 160, VIRTUAL_WIDTH, 'center')
end