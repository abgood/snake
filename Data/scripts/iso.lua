require "scripts/Utilities/Sample"
require "scripts/Utilities/2D/Sample2D"

function Start()
	demoFilename = "iso"

	SampleStart()

	CreateScene()

	CreateUIContent("ISOMETRIC 2.5D DEMO")
end

function CreateScene()
	scene_ = Scene()

	scene_:CreateComponent("Octree")
	scene_:CreateComponent("DebugRenderer")
	local physicsWorld = scene_:CreateComponent("PhysicsWorld2D")
	physicsWorld.gravity = Vector2.ZERO

	cameraNode = Node()
	local camera = cameraNode:CreateComponent("Camera")
	camera.orthographic = true
	camera.orthoSize = graphics.height * PIXEL_SIZE
	zoom = 2 * Min(graphics.width / 1280, graphics.height / 800)
	camera.zoom = zoom

	renderer:SetViewport(0, Viewport:new(scene_, camera))
	renderer.defaultZone.fogColor = Color(0.2, 0.2, 0.2)

	local tmxFile = cache:GetResource("TmxFile2D", "Urho2D/Tilesets/atrium.tmx")
	local tileMapNode = scene_:CreateChild("TileMap")
	local tileMap = tileMapNode:CreateComponent("TileMap2D")
	tileMap.tmxFile = tmxFile
	local info = tileMap.info

	CreateCharacter(info, true, 0, Vector3(-5, 11, 0), 0.15)

	local tileMapLayer = tileMap:GetLayer(tileMap.numLayers - 1)
	CreateCollisionShapesFromTMXObjects(tileMapNode, tileMapLayer, info)

	PopulateMovingEntities(tileMap:GetLayer(tileMap.numLayers - 2))

	PopulateCoins(tileMap:GetLayer(tileMap.numLayers - 3))

	SubscribeToEvent("EndRendering", HandleSceneRendered)
end

function HandleSceneRendered()
	UnsubscribeFromEvent("EndRendering")
	SaveScene(true)
	scene_.updateEnabled = false
end

Character2D = ScriptObject()

function Character2D:Start()
	self.wounded = false
	self.killed = false
	self.timer = 0
	self.maxCoins = 0
	self.remainingCoins = 0
	self.remainingLifes = 0
end

function Character2D:Update(timeStep)
	local node = self.node
	local animatedSprite = node:GetComponent("AnimatedSprite2D")

	local moveDir = Vector3.ZERO
	local speedX = Clamp(MOVE_SPEED_X / zoom, 0.4, 1)
	local speedY = speedX

	if input:GetKeyDown(KEY_LEFT) or input:GetKeyDown(KEY_A) then
		moveDir = moveDir + Vector3.LEFT * speedX
		animatedSprite.flipX = false
	end

	if input:GetKeyDown(KEY_RIGHT) or input:GetKeyDown(KEY_D) then
		moveDir = moveDir + Vector3.RIGHT * speedX
		animatedSprite.flipX = false
	end

	if not moveDir:Equals(Vector3.ZERO) then
		speedY = speedX * MOVE_SPEED_SCALE
	end

	if input:GetKeyDown(KEY_UP) or input:GetKeyDown(KEY_W) then
		moveDir = moveDir + Vector3.UP * speedY
	end

	if input:GetKeyDown(KEY_DOWN) or input:GetKeyDown(KEY_S) then
		moveDir = moveDir + Vector3.DOWN * speedY
	end

	if not moveDir:Equals(Vector3.ZERO) then
		node:Translate(moveDir * timeStep)
	end

	if input:GetKeyDown(KEY_SPACE) then
		if animatedSprite.animation ~= "attack" then
			animatedSprite:SetAnimation("attack", LM_FORCE_LOOPED)
		end
	elseif not moveDir:Equals(Vector3.ZERO) then
		if animatedSprite.animation ~= "run" then
			animatedSprite:SetAnimation("run")
		end
	elseif animatedSprite.animation ~= "idle" then
		animatedSprite:SetAnimation("idle")
	end
end
