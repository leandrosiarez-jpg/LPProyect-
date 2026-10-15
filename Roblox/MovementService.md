# MovementService

**Qué hace:**
- Da al cliente el `NetworkOwner` de su propio personaje (permite la predicción instantánea).
- Descarta inputs con valores fuera de rango (anti-cheat básico).
- Corre una corrección periódica: si detecta que un personaje se salió del plano Z o va a una velocidad horizontal imposible, retoma el control (`SetNetworkOwner(nil)`), corrige posición/velocidad y se lo devuelve al cliente.

**Ubicación:** `ServerScriptService > Services > MovementService` — **Script** (servidor)

**Objeto a crear manualmente en Studio:** `ReplicatedStorage > Remotes > Player > MovementInput` → **RemoteEvent** (el mismo que usa `MovementController`).

**Pendientes de decisión (sin cambios en el código):**
- La reconciliación solo clampea la velocidad en X; no valida Y. Posible techo vertical: `MIN_JUMP_VELOCITY + JUMP_HOLD_FORCE * MAX_JUMP_HOLD_TIME` (≈ 57 studs/s).
- El `OnServerEvent` solo descarta paquetes inválidos y no hace nada más con el input; falta definir si es un placeholder o se simplifica.

```lua
-- Script: ServerScriptService > Services > MovementService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConstants = require(ReplicatedStorage.Constants.MovementConstants)
local movementInputEvent = ReplicatedStorage.Remotes.Player.MovementInput

local function onCharacterAdded(player, character)
	local root = character:WaitForChild("HumanoidRootPart")
	-- el cliente es dueño de la física de su propio personaje (predicción instantánea);
	-- el servidor solo valida/corrige si algo no cuadra
	root:SetNetworkOwner(player)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Anti-cheat básico: descarta inputs con valores fuera de rango
movementInputEvent.OnServerEvent:Connect(function(_, direction, _wantsToJump)
	if typeof(direction) ~= "number" or direction < -1 or direction > 1 then
		return
	end
end)

-- Corrección periódica (reconciliación): revisa drift de Z y velocidad imposible
RunService.Heartbeat:Connect(function()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local position = root.Position
		local velocity = root.AssemblyLinearVelocity

		local zDrifted = math.abs(position.Z - MovementConstants.GAMEPLAY_Z) > 1
		local speedTooHigh = math.abs(velocity.X) > MovementConstants.WALK_SPEED + MovementConstants.MAX_SPEED_TOLERANCE

		if zDrifted or speedTooHigh then
			root:SetNetworkOwner(nil)
			root.CFrame = CFrame.new(position.X, position.Y, MovementConstants.GAMEPLAY_Z) * (root.CFrame - root.CFrame.Position)
			root.AssemblyLinearVelocity = Vector3.new(
				math.clamp(velocity.X, -MovementConstants.WALK_SPEED, MovementConstants.WALK_SPEED),
				velocity.Y,
				0
			)
			root:SetNetworkOwner(player)
		end
	end
end)
```
