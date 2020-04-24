--[[
    PauseState
    Author: Brandon Tate
    brandonntate@gmail.com

    Pauses gameplay until the user presses the unpause button
]]

PauseState = Class{__includes = BaseState}

-- The play state on pause
local playState

function PauseState:init()
end

function PauseState:update(dt)
    -- pause/unpause if p was pressed
    if love.keyboard.wasPressed('p') then
        gStateMachine:change('play', self.playState)
    end
end


function PauseState:render()
    -- render pause text big in the middle of the screen
    love.graphics.setFont(hugeFont)
    love.graphics.printf('Paused', 0, 100, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('(press p to play)', 0, 160, VIRTUAL_WIDTH, 'center')
end

--[[
    Called when this state is transitioned to from another state.
]]
function PauseState:enter(playState)

    self.playState = playState

    -- pause music
    love.audio.pause(sounds['music'])
end

--[[
    Called when this state changes to another state.
]]
function PauseState:exit()
    -- resume music
    love.audio.resume(sounds['music'])
end