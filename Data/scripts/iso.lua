require "scripts/Utilities/Sample"
require "scripts/Utilities/2D/Sample2D"

function Start()
	demoFilename = "iso"

	SampleStart()

	CreateScene()

	CreateUIContent("ISOMETRIC 2.5D DEMO")

	SubscribeToEvents()
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

function HandleCollisionBegin(eventType, eventData)
	local hitNode = eventData["NodeA"]:GetPtr("Node")
	if hitNode.name == "Imp" then
		hitNode = eventData["NodeB"]:GetPtr("Node")
	end
	local nodeName = hitNode.name
    local character = character2DNode:GetScriptObject()

	if nodeName == "Coin" then
		hitNode:Remove()
		character.remainingCoins = character.remainingCoins - 1
		if character.remainingCoins == 0 then
			ui.root:GetChild("Instructions", true).text = "!!! You have all the coins !!!"
		end
		ui.root:GetChild("CoinsText", true).text = character.remainingCoins
        PlaySound("Powerup.wav")
	end

	if nodeName == "Orc" then
		local animatedSprite = character2DNode:GetComponent("AnimatedSprite2D")
		local deltaX = character2DNode.position.x - hitNode.position.x

		if animatedSprite.animation == "attack" and (deltaX < 0 == animatedSprite.flipX) then
			hitNode:GetScriptObject().emitTime = 1
			if not hitNode:GetChild("Emitter", true) then
				hitNode:GetComponent("RigidBody2D"):Remove()
				SpawnEffect(hitNode)
				PlaySound("BigExplosion.wav")
			end
		else
			if not character2DNode:GetChild("Emitter", true) then
				character.wounded = true;
				if nodeName == "Orc" then
					hitNode:GetScriptObject().fightTimer = 1
				end
				SpawnEffect(character2DNode)
				PlaySound("BigExplosion.wav")
			end
		end
	end
end

function HandleSceneRendered()
	UnsubscribeFromEvent("EndRendering")
	SaveScene(true)
	scene_.updateEnabled = false
end

function SubscribeToEvents()
	SubscribeToEvent("Update", "HandleUpdate")

	SubscribeToEvent("PostUpdate", "HandlePostUpdate")

	SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate")

	SubscribeToEvent("PhysicsBeginContact2D", HandleCollisionBegin)

	UnsubscribeFromEvent("SceneUpdate")
end

function HandleUpdate(eventType, eventData)
	Zoom(cameraNode:GetComponent("Camera"))

	if input:GetKeyPress(KEY_Z) then drawDebug = not drawDebug end

	if input:GetKeyPress(KEY_F5) then
		SaveScene()
	end
	if input:GetKeyPress(KEY_F7) then
		ReloadScene(false)
	end
end

function HandlePostUpdate(eventType, eventData)
	if not character2DNode or not cameraNode then return end

	cameraNode.position = Vector3(character2DNode.position.x, character2DNode.position.y, -10)
end

function HandlePostRenderUpdate(eventType, eventData)
	if drawDebug then
		scene_:GetComponent("PhysicsWorld2D"):DrawDebugGeometry(true)
	end
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
		animatedSprite.flipX = true
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
