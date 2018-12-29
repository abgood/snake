character2DNode = nil
MOVE_SPEED_SCALE = 1
MOVE_SPEED_X = 2.5
zoom = 2

function CreateCharacter(info, createObject, friction, position, scale)
	character2DNode = scene_:CreateChild("Imp")
	character2DNode.position = position
	character2DNode:SetScale(scale)
	local animatedSprite = character2DNode:CreateComponent("AnimatedSprite2D")
	local animationSet = cache:GetResource("AnimationSet2D", "Urho2D/imp/imp.scml")
	animatedSprite.animationSet = animationSet
	animatedSprite.animation = "idle"
	animatedSprite:SetLayer(3)

	local body = character2DNode:CreateComponent("RigidBody2D")
	body.bodyType = BT_DYNAMIC
	body.allowSleep = false

	local shape = character2DNode:CreateComponent("CollisionCircle2D")
	shape.radius = 1.1
	shape.friction = friction
	shape.restitution = 0.1
	if createObject then
		character2DNode:CreateScriptObject("Character2D")
	end

	MOVE_SPEED_SCALE = info.tileHeight / info.tileHeight
end

function CreateCollisionShapesFromTMXObjects(tileMapNode, tileMapLayer, info)
	local body = tileMapNode:CreateComponent("RigidBody2D")
	body.bodyType = BT_STATIC

	for i = 0, tileMapLayer:GetNumObjects() - 1 do
		local tileMapObject = tileMapLayer:GetObject(i)
		local objectType = tileMapObject.objectType

		local shape

		if objectType == OT_RECTANGLE then
			shape = tileMapNode:CreateComponent("CollisionBox2D")
			local size = tileMapObject.size
			shape.size = size
			if info.orientation == O_ORTHOGONAL then
				shape.center = tileMapObject.position + size / 2
			else
				shape.center = tileMapObject.position + Vector2(info.width / 2, 0)
				shape.angle = 45
			end
		elseif objectType == OT_ELLIPSE then
			shape = tileMapNode:CreateComponent("CollisionCircle2D")
			local size = tileMapObject.size
			shape.radius = size.x / 2
			if info.orientation == O_ORTHOGONAL then
				shape.center = tileMapObject.position + size / 2
			else
				shape.center = tileMapObject.position + Vector2(info.tileWidth / 2, 0)
			end
		elseif objectType == OT_POLYGON then
			shape = tileMapNode:CreateComponent("CollisionPolygon2D")

		elseif objectType == OT_POLYLINE then
			shape = tileMapNode:CreateComponent("CollisionChain2D")

		else break
		end

		if objectType == OT_POLYGON or objectType == OT_POLYLINE then
			local numVertices = tileMapObject.numPoints
			shape.vertexCount = numVertices
			for i = 0, numVertices - 1 do
				shape:SetVertex(i, tileMapObject:GetPoint(i))
			end
		end

		shape.friction = 0.8
		if tileMapObject:HasProperty("Friction") then
			shape.friction = ToFloat(tileMapObject:GetProperty("Friction"))
		end

	end
end

function CreateEnemy()
	local node = scene_:CreateChild("Enemy")
	local staticSprite = node:CreateComponent("StaticSprite2D")
	staticSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/Aster.png")
	local body = node:CreateComponent("RigidBody2D")
	body.bodyType = BT_STATIC
	local shape = node:CreateComponent("CollisionCircle2D")
	shape.radius = 0.25
	return node
end

function CreateOrc()
	local node = scene_:CreateChild("Orc")
	node.scale = character2DNode.scale

	local animatedSprite = node:CreateComponent("AnimatedSprite2D")
	local animationSet = cache:GetResource("AnimationSet2D", "Urho2D/Orc/orc.scml")

	animatedSprite.animationSet = animationSet
	animatedSprite.animation = "run"
	animatedSprite:SetLayer(2)

	local body = node:CreateComponent("RigidBody2D")
	local shape = node:CreateComponent("CollisionCircle2D")
	shape.radius = 1.3
	shape.trigger = true
	return node
end

function CreateMovingPlatform()
	local node = scene_:CreateChild("MovingPlatform")
	node.scale = Vector3(3, 1, 0)
	local staticSprite = node:CreateComponent("StaticSprite2D")
	staticSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/Box.png")
	local body = node:CreateComponent("RigidBody2D")
	body.bodyType = BT_STATIC
	local shape = node:CreateComponent("CollisionBox2D")
	shape.size = Vector2(0.32, 0.32)
	shape.friction = 0.8
	return node
end

function CreatePathFromPoints(object, offset)
	local path = {}
	for i = 0, object.numPoints - 1 do
		table.insert(path, object:GetPoint(i) + offset)
	end
	return path
end

function PopulateMovingEntities(movingEntitiesLayer)
	local enemyNode = CreateEnemy()
	local orcNode = CreateOrc()
	local platformNode = CreateMovingPlatform()

	for i = 0, movingEntitiesLayer:GetNumObjects() - 1 do
		local movingObject = movingEntitiesLayer:GetObject(i)
		if movingObject.objectType == OT_POLYLINE then
			local movingClone = nil
			local offset = Vector2.ZERO
			if movingObject.type == "Enemy" then
				movingClone = enemyNode:Clone()
				offset = Vector2(0, -0.32)
			elseif movingObject.type == "Orc" then
				movingClone = orcNode:Clone()
			elseif movingObject.type == "MovingPlatform" then
				movingClone = platformNode:Clone()
			else break
			end

			movingClone.position2D = movingObject:GetPoint(0) + offset
			local mover = movingClone:CreateScriptObject("scripts/Utilities/2D/Mover.lua", "Mover")
			mover.path = CreatePathFromPoints(movingObject, offset)
			print(string.format("lj movingObject: %d, %d, %d, %d", i, #mover.path, offset.x, offset.y))

			if movingObject:HasProperty("Speed") then
				mover.speed = movingObject:GetProperty("Speed")
			end
		end
	end

	enemyNode:Remove()
	orcNode:Remove()
	platformNode:Remove()
end

function CreateCoin()
	local node = scene_:CreateChild("Coin")

	node:SetScale(0.5)
	local animatedSprite = node:CreateComponent("AnimatedSprite2D")
	local animationSet = cache:GetResource("AnimationSet2D", "Urho2D/GoldIcon.scml")
	animatedSprite.animationSet = animationSet
	animatedSprite.animation = "idle"
	animatedSprite:SetLayer(2)
	local body = node:CreateComponent("RigidBody2D")
	body.bodyType = BT_STATIC
	local shape = node:CreateComponent("CollisionCircle2D")
	shape.radius = 0.32
	shape.trigger = true

	return node
end

function PopulateCoins(coinsLayer)
	local coinNode = CreateCoin()

	for i = 0, coinsLayer:GetNumObjects() - 1 do
		local coinObject = coinsLayer:GetObject(i)
		local coinClone = coinNode:Clone()
		coinClone.position2D = coinObject.position + coinObject.size / 2 + Vector2(0, 0.16)
	end

	local character = character2DNode:GetScriptObject()
	character.remainingCoins = coinsLayer.numObjects
	character.maxCoins = coinsLayer.numObjects

	coinNode:Remove()
end

function SaveScene(initial)
	local filename = demoFilename
	if not initial then
		filename = demoFilename .. "InGame"
	end

	scene_:SaveXML(fileSystem:GetProgramDir() .. "Data/Scenes/" .. filename .. ".xml")
end

function CreateUIContent(demoTitle)
	ui.root.defaultStyle = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
end
