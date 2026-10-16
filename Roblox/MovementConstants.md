# MovementConstants

**Qué hace:** centraliza todos los valores ajustables del movimiento (velocidad, salto, tolerancias) para que cliente y servidor usen siempre los mismos números.

**Ubicación:** `ReplicatedStorage > Constants > MovementConstants` — **ModuleScript**

```lua
local MovementConstants = {}

MovementConstants.GAMEPLAY_Z = 0            -- debe coincidir con GAMEPLAY_Z de CameraController2D
MovementConstants.WALK_SPEED = 24           -- studs/seg, placeholder
MovementConstants.MAX_SPEED_TOLERANCE = 4   -- margen de error permitido al validar en servidor

MovementConstants.MIN_JUMP_VELOCITY = 30    -- impulso inicial al despegar (salto "tap", el mínimo)
MovementConstants.JUMP_HOLD_FORCE = 90      -- aceleración extra mientras se mantiene presionado, studs/seg²
MovementConstants.MAX_JUMP_HOLD_TIME = 0.3  -- segundos máximos que se puede sostener el salto

return MovementConstants
```
