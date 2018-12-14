-- This first example, maintaining tradition, prints a "Hello World" message.
-- Furthermore it shows:
--     - Using the Sample utility functions as a base for the application
--     - Adding a Text element to the graphical user interface
--     - Subscribing to and handling of update events

require "scripts/Utilities/Sample"


local headDirection = nil
local gridTileSize = 16
local gridSize = 32
local numObjects = 3
local snakeBody_ = {}
local gameState_ = 0

local MD_LEFT = 0
local MD_RIGHT = 1
local MD_UP = 2
local MD_DOWN = 3

local gridBorderColor = Color(0.31, 0.31, 0.31);
local gridColor = Color(0.15, 0.15, 0.15);


function Start()
    -- Execute the common startup for samples
    SampleStart()

	CreateScene()

	CreateGrid()

    -- Create "Hello World" Text
    -- CreateText()

    -- Setup the viewport for displaying the scene
    SetupViewport()

    -- Set the mouse mode to use in the sample
    SampleInitMouseMode(MM_FREE)

    -- Finally, hook-up this HelloWorld instance to handle update events
    SubscribeToEvents()
end

function CreateScene()
	scene_ = Scene()

	scene_:CreateComponent("Octree")

	cameraNode = scene_:CreateChild("Camera")
	cameraNode.position = Vector3(0.0, 0.0, -10.0)

	local camera = cameraNode:CreateComponent("Camera")
	camera.orthographic = true
	camera.orthoSize = graphics.height * PIXEL_SIZE

	gameNode_ = scene_:CreateChild("GameNode")

    local sprite = cache:GetResource("Sprite2D", "Urho2D/SnakeHead.png")
    if sprite == nil then
        return
    end
	sprite.hotSpot = Vector2(0.0, 0.0)

	snakeHead_ = gameNode_:CreateChild("SnakeHead")
	snakeHead_.position = Vector3(-2.0 * gridTileSize * PIXEL_SIZE, 1.0 * gridTileSize * PIXEL_SIZE, 0.0)
	snakeHead_:SetScale(0.8)

	local snakeHeadStaticSprite = snakeHead_:CreateComponent("StaticSprite2D")
	snakeHeadStaticSprite.blendMode = BLEND_ALPHA
	snakeHeadStaticSprite.sprite = sprite

	headDirection = MD_LEFT
	
	for i = 1, numObjects do
		AddSegment()

		MoveSnake()
	end

	fruitsprite = cache:GetResource()
end

function AddSegment()
	if next(snakeBody_) == nil then
    	local sprite = cache:GetResource("Sprite2D", "Urho2D/SnakeBody.png")
    	if sprite == nil then
    	    return
    	end
		sprite.hotSpot = Vector2(0.0, 0.0)

		spriteNode = gameNode_:CreateChild("SnakeBody")
		spriteNode.position = snakeHead_.position
		spriteNode:SetScale(0.8)

		local staticSprite = spriteNode:CreateComponent("StaticSprite2D")
		staticSprite.blendMode = BLEND_ALPHA
		staticSprite.sprite = sprite

		table.insert(snakeBody_, spriteNode)
		return
	end

	local last = snakeBody_[#snakeBody_]
	local sprite = cache:GetResource("Sprite2D", "Urho2D/SnakeBody.png")
    if sprite == nil then
        return
    end
	sprite.hotSpot = Vector2(0.0, 0.0)

	spriteNode = gameNode_:CreateChild("SnakeBody")
	spriteNode.position = last.position
	spriteNode:SetScale(0.8)

	local staticSprite = spriteNode:CreateComponent("StaticSprite2D")
	staticSprite.blendMode = BLEND_ALPHA
	staticSprite.sprite = sprite

	table.insert(snakeBody_, spriteNode)
end

function MoveSnake()
	local headPos = snakeHead_:GetPosition2D()
	local Size = gridTileSize * PIXEL_SIZE
	local halfSizeX = (headPos.x / 2) * Size;
	local halfSizeY = (headPos.y / 2) * Size;
	print(string.format("lj pos: %d, %d, %d, %d", headPos.x, headPos.y, headDirection, #snakeBody_))

	if headDirection == MD_LEFT then
		if headPos.x == -halfSizeX then
			snakeHead_:SetPosition2D(Vector2(halfSizeX - Size, headPos.y))
		else
			snakeHead_:SetPosition2D(Vector2(headPos.x - Size, headPos.y))
		end
	elseif headDirection == MD_RIGHT then
		if headPos.x == halfSizeX - size then
			snakeHead_.position = Vector2(-halfSizeX, headPos.y)
		else
			snakeHead_.position = Vector2(headPos.x + Size, headPos.y)
		end
	elseif headDirection == MD_UP then
		if headPos.y == halfSizeY - Size then
			snakeHead_.position = Vector2(headPos.x, -halfSizeY)
		else
			snakeHead_.position = Vector2(headPos.x, headPos.y + Size)
		end
	elseif headDirection == MD_DOWN then
		if headPos.y == -halfSizeY then
			snakeHead_.position = Vector2(headPos.x, halfSizeY - Size)
		else
			snakeHead_.position = Vector2(headPos.x, headPos.y - Size)
		end
	end

	for i = 1, #snakeBody_ do
		local bodySegment = snakeBody_[i]
		local temp = bodySegment:GetPosition2D()
		bodySegment:SetPosition2D(headPos)
		headPos = temp
	end
end

function CreateGrid()
	gridNode_ = scene_:CreateChild("Grid")
	grid_ = gridNode_:CreateComponent("CustomGeometry")
	grid_:SetNumGeometries(1)
	grid_:SetMaterial(cache:GetResource("Material", "Materials/VColUnlit.xml"))

	local Size = gridTileSize * PIXEL_SIZE
	local halfSizeX = (gridSize / 2) * Size;
	local halfSizeY = (gridSize / 2) * Size;

	grid_:BeginGeometry(0, LINE_LIST)

	for i = 0, gridSize do
		grid_:DefineVertex(Vector3(-halfSizeX + i * Size, halfSizeY, 0.0))
		grid_:DefineColor(((i == 0 or i == gridSize) and gridBorderColor) or gridColor)
		grid_:DefineVertex(Vector3(-halfSizeX + i * Size, -halfSizeY, 0.0))
		grid_:DefineColor(((i == 0 or i == gridSize) and gridBorderColor) or gridColor)
	end

	for i = 0, gridSize do
		grid_:DefineVertex(Vector3(-halfSizeX, halfSizeY - i * Size, 0.0))
		grid_:DefineColor(((i == 0 or i == gridSize) and gridBorderColor) or gridColor)
		grid_:DefineVertex(Vector3(halfSizeX, halfSizeY - i * Size, 0.0))
		grid_:DefineColor(((i == 0 or i == gridSize) and gridBorderColor) or gridColor)
	end

	grid_:Commit()

end

function CreateText()
    -- Construct new Text object
    local helloText = Text:new()

    -- Set String to display
    helloText.text = "Hello World from Urho3D!"

    -- Set font and text color
    helloText:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 30)
    helloText.color = Color(0.0, 1.0, 0.0)

    -- Align Text center-screen
    helloText.horizontalAlignment = HA_CENTER
    helloText.verticalAlignment = VA_CENTER

    -- Add Text instance to the UI root element
    ui.root:AddChild(helloText)
end

function SubscribeToEvents()
    -- Subscribe HandleUpdate() function for processing update events
    SubscribeToEvent("Update", "HandleUpdate")
end

local switch = {
	[0] = function()
		if input:GetKeyPress(KEY_SPACE) then
			StartGame()
		end
	end,
	[1] = function()
		local timeStep = eventData["TimeStep"]:GetFloat()
		print("1")
	end,
	[2] = function()
		print("2")
	end,
	[3] = function()
		return
	end
}

function StartGame()
	print ("lj start")
	gameState_ = 1
end

function HandleUpdate(eventType, eventData)
    -- Do nothing for now, could be extended to eg. animate the display
	local f = switch[gameState_]
	if f then
		f()
	else
		print("switch error")
	end
end

function SetupViewport()
    -- Set up a viewport to the Renderer subsystem so that the 3D scene can be seen. We need to define the scene and the camera
    -- at minimum. Additionally we could configure the viewport screen size and the rendering path (eg. forward / deferred) to
    -- use, but now we just use full screen and default render path configured in the engine command line options
    local viewport = Viewport:new(scene_, cameraNode:GetComponent("Camera"))
    renderer:SetViewport(0, viewport)
end

-- Create XML patch instructions for screen joystick layout specific to this sample app
function GetScreenJoystickPatchString()
    return
        "<patch>" ..
        "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Hat0']]\">" ..
        "        <attribute name=\"Is Visible\" value=\"false\" />" ..
        "    </add>" ..
        "</patch>"
end
