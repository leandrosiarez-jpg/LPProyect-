# MovementController

**Qué hace:**
- Lee input de teclado (A/D o flechas para movimiento, Space para saltar) y desactiva el control nativo de Roblox (WASD del Humanoid) para que no compita.
- Mueve al personaje horizontalmente seteando `AssemblyLinearVelocity.X` directamente según la dirección presionada.
- Salto con altura variable: un impulso mínimo al despegar (`MIN_JUMP_VELOCITY`); mientras se mantiene `Space` presionado y el personaje sigue subiendo, se suma `JUMP_HOLD_FORCE` por segundo, hasta `MAX_JUMP_HOLD_TIME`. Si se suelta antes, no hay corte: el arco sigue por gravedad.
- Bloquea el eje Z cada frame (corrige la posición si algo la desvía del plano de juego).
- Envía el input (dirección y si sostiene salto) al servidor en cada frame, para que valide.

**Ubicación:** `StarterPlayer > StarterPlayerScripts > MovementController` — **LocalScript**

**Objeto a crear manualmente en Studio:** `ReplicatedStorage > Remotes > Player > MovementInput` → **RemoteEvent**

**Correcciones aplicadas:**
1. La conexión a `Heartbeat` se guarda en `movementConnection` y se desconecta en cada respawn (evita fuga de conexiones).
2. `humanoid.PlatformStand = true` apaga el controlador físico interno del Humanoid, que competía contra la velocidad manual.
3. `WaitForChild` en lugar de `FindFirstChild` para `PlayerScripts` y `PlayerModule` (evita condición de carrera al spawnear).

```lua
-- LocalScript: StarterPlayer > StarterPlayerScripts > MovementController

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConstants = require(ReplicatedStorage.Constants.MovementConstants)
local movementInputEvent = ReplicatedStorage.Remotes.Player.MovementInput

local player = Players.LocalPlayer

local direction = 0 -- -1 izquierda, 0 quieto, 1 derecha
local jumpKeyHeld = false
local jumpStartRequested = false -- se consume una vez por cada apretada
local movementConnection -- conexión de Heartbeat del personaje actual

local function updateDirectionFromKeys()
	local leftDown = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
	local rightDown = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)

	if leftDown and not rightDown then
		direction = -1
	elseif rightDown and not leftDown then
		direction = 1
	else
		direction = 0
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space then
		jumpKeyHeld = true
		jumpStartRequested = true
	end
	updateDirectionFromKeys()
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space then
		jumpKeyHeld = false
	end
	updateDirectionFromKeys()
end)

-- Apaga el control nativo de Roblox (WASD del Humanoid) para que no compita con este sistema
local function disableDefaultControls(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.PlatformStand = true -- apaga el controlador físico interno del Humanoid
	end

	local playerScripts = player:WaitForChild("PlayerScripts")
	local playerModule = playerScripts:WaitForChild("PlayerModule")
	require(playerModule):GetControls():Disable()
end

local function onCharacterAdded(character)
	disableDefaultControls(character)

	if movementConnection then
		movementConnection:Disconnect()
		movementConnection = nil
	end

	local root = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	local isJumping = false
	local jumpHoldTime = 0

	movementConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if root.Parent == nil then return end

		local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local velocity = root.AssemblyLinearVelocity
		local newVelocityY = velocity.Y

		-- inicio del salto: impulso mínimo, solo si está en el piso
		if jumpStartRequested and isGrounded then
			newVelocityY = MovementConstants.MIN_JUMP_VELOCITY
			isJumping = true
			jumpHoldTime = 0
		end
		jumpStartRequested = false

		-- altura extra mientras se sostiene el botón (hasta el tiempo máximo, y solo mientras sube)
		if isJumping and jumpKeyHeld and jumpHoldTime < MovementConstants.MAX_JUMP_HOLD_TIME and newVelocityY > 0 then
			newVelocityY += MovementConstants.JUMP_HOLD_FORCE * deltaTime
			jumpHoldTime += deltaTime
		end

		-- si soltó el botón, simplemente no se suma más impulso; el arco sigue por gravedad (sin corte)

		if isGrounded and newVelocityY <= 0 then
			isJumping = false -- aterrizó, listo para el próximo salto
		end

		local newVelocityX = direction * MovementConstants.WALK_SPEED
		root.AssemblyLinearVelocity = Vector3.new(newVelocityX, newVelocityY, 0)

		-- bloqueo duro del eje Z (predicción local, feedback inmediato)
		local position = root.Position
		if math.abs(position.Z - MovementConstants.GAMEPLAY_Z) > 0.01 then
			root.CFrame = CFrame.new(position.X, position.Y, MovementConstants.GAMEPLAY_Z) * (root.CFrame - root.CFrame.Position)
		end

		movementInputEvent:FireServer(direction, jumpKeyHeld)
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
```
