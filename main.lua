-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local relayout = require( "relayout" )
local _W, _H, _CX, _CY = relayout._W, relayout._H, relayout._CX, relayout._CY

-- variables
local pipes = {}
local canAddPipe = 0
local hasStarted = false
local score = 0
local grpMain = display.newGroup()
local grpWorld = display.newGroup()
local grpUI = display.newGroup()

-- ==============================================================================
-- setup layers
-- ==============================================================================
grpMain:insert( grpWorld )
grpMain:insert( grpUI )


-- ==============================================================================
-- Add Pipes
-- ==============================================================================
local function addPipe() 
    local distanceBetween = math.random( 120, 200 )
    local yPosition = math.random( 150, _H - 150 )

    local pTop = display.newImageRect(grpWorld, "assets/images/pipe.png", 50, 600 )
    pTop.x = _W + 50
    pTop.y = yPosition - (distanceBetween / 2) - 300
    pTop.rotation = 180  -- this pipe comes from the top, so rotate it to be upside down
    pTop.xScale = -1   -- flip the pipe horizontally so the shadow is on the right side
    pTop.type = "pipe"
    pipes[#pipes+1] = pTop

    local pBottom = display.newImageRect(grpWorld, "assets/images/pipe.png", 50, 600 )
    pBottom.x = _W + 50
    pBottom.y = yPosition + (distanceBetween / 2) + 300 
    pBottom.type = "pipe"
    pipes[#pipes+1] = pBottom

    local pSensor = display.newRect(grpWorld, _W + 80, _CY, 5, _H )
    pSensor.fill = { 0, 0, 0 } -- set the color to red
    pSensor.type = "sensor"
    pSensor.alpha = 0
    pipes[#pipes+1] = pSensor
end

-- ==============================================================================
-- set background
-- ==============================================================================
local backgrounds = {}
local background1 = display.newImageRect(grpWorld, "assets/images/background.png", _W, _H )
background1.x = _CX
background1.y = _CY
backgrounds[#backgrounds+1] = background1

local background2 = display.newImageRect(grpWorld, "assets/images/background.png", _W, _H )
background2.x = _CX + _W
background2.y = _CY
backgrounds[#backgrounds+1] = background2

local background3 = display.newImageRect(grpWorld, "assets/images/background.png", _W, _H )
background3.x = _CX + (_W * 2)
background3.y = _CY
backgrounds[#backgrounds+1] = background3

-- ==============================================================================
-- Bird
-- ==============================================================================
local bird = display.newImageRect(grpWorld, "assets/images/flappy.png", 25, 20 )
bird.x = _CX
bird.y = _CY
bird.velocity = 0
bird.gravity = 0.6
bird.crashed = false

-- ==============================================================================
-- Score Label
-- ==============================================================================
local lblScore = display.newText("Score: 0", 50, 45, "arial", 18)
lblScore:setFillColor( 0, 0, 0 )
grpUI:insert(lblScore)

-- ==============================================================================
-- Collision Detection
-- ==============================================================================
local function checkCollission( object1, object2 )
    local left   = (object1.contentBounds.xMin <= object2.contentBounds.xMin) and (object1.contentBounds.xMax >= object2.contentBounds.xMin)
    local right  = (object1.contentBounds.xMin >= object2.contentBounds.xMin) and (object1.contentBounds.xMin <= object2.contentBounds.xMax)
    local top    = (object1.contentBounds.yMin <= object2.contentBounds.yMin) and (object1.contentBounds.yMax >= object2.contentBounds.yMin)
    local bottom = (object1.contentBounds.yMin >= object2.contentBounds.yMin) and (object1.contentBounds.yMin <= object2.contentBounds.yMax)

    return (left or right) and (top or bottom)
end

-- ==============================================================================
-- Cleanup pipes
-- ==============================================================================
local function removePipe(pipes, index)
    local pipeToRemove = table.remove( pipes, index )

    if pipeToRemove ~= nil then 
        pipeToRemove:removeSelf()
        pipeToRemove = nil
    end
end

-- ==============================================================================
-- end game
-- ==============================================================================
local function endGame()
    bird.crashed = true
    transition.to( bird, {time=500, y=_H - 30} )  
end

-- ==============================================================================
-- Update 
-- ==============================================================================
local function update()
    if hasStarted and not bird.crashed then
        -- move the background to the left by 2 pixes in every frame
        for i = #backgrounds, 1, -1 do 
            local object = backgrounds[i]
            object:translate( -2 , 0 )

            -- once it off of the screen to the right, we move it to the end of the line
            if object.x < -(_W / 2) then
                object.x = object.x + (_W * 3)
            end
        end


        -- every pass through the game loop, we move the pipes to the left by 2 pixels
        for i = #pipes, 1, -1 do 
            local object = pipes[i]
            object:translate( -2 , 0 )

            -- once it off of the screen to the right, we remove it 
            -- from the table, and make sure to clean up the memory
            if object.x < -100 then
                removePipe(pipes, i)
            end

            if checkCollission(object, bird) then 
                if object.type == "sensor" then
                    score = score + 1
                    lblScore.text = "Score: " .. score

                    removePipe(pipes, i)
                else
                    endGame()
                end
            end  
        end

        -- make the bird fall by decreasing the velocity by the gravity
        -- then reducing the y position by the new velocity
        bird.velocity = bird.velocity - bird.gravity
        bird.y = bird.y - bird.velocity

        -- check if the bird has gone off the top or bottom of the screen
        if bird.y < 0 or bird.y > _H then
            endGame()  
        end


        -- this loop is giving us the gap between the pipes
        -- only adds one pipe after 100 iterations of the game loop
        if canAddPipe > 100 then
            addPipe()
            canAddPipe = 0
        end
        canAddPipe = canAddPipe + 1
    end
end

-- ======================================================================================
-- make the bird flap
-- ======================================================================================
local function touch( event )
    if event.phase == "began" then
        if not hasStarted then
            hasStarted = true
        end
        bird.velocity = 10
    end
end


-- ==============================================================================
-- Start
-- ==============================================================================


Runtime:addEventListener("enterFrame", update)
Runtime:addEventListener("touch", touch)