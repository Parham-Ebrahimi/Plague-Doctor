local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.core.GameConstants)

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local MODE_THIRD = "ThirdPerson"
local MODE_FIRST = "FirstPerson"

-- Vertical clamp is asymmetric: we allow looking further up than down
-- because pitching hard down clips the camera into the character/floor.
local PITCH_MIN_DEG = -70
local PITCH_MAX_DEG = 80

local RUN_SPEED_THRESHOLD = 14

local currentMode = MODE_THIRD
local yaw = 0
local pitch = 0
-- First-person yaw is stored as an offset relative to the character's facing
-- direction so it can be clamped to a realistic head-turn range without
-- limiting third-person rotation.
local fpYawOffset = 0
local fpYawCenter = 0

local bobPhase = 0
local bobOffsetCurrent = Vector3.zero
local swayTime = 0

local currentCameraCFrame = camera.CFrame

-- Examination camera. While inExamination is true the normal per-frame camera
-- and stamina/walkspeed loop is suspended so a TweenService tween on the
-- scriptable camera can hold instead of being overwritten every frame.
local EXAM_DISTANCE = 5
local EXAM_CHEST_OFFSET = 0.5
-- Studs the camera is shifted along the NPC's RightVector during examination.
-- This pushes the NPC toward the left side of the frame, leaving the right
-- side empty for the examination UI panel.
local EXAM_LATERAL_OFFSET = -3
local EXAM_TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local inExamination = false
local examTween = nil
local preExamCFrame = nil
-- The pose onRenderStep pins the camera to after the enter tween completes.
-- nil while an enter/exit tween is actively driving camera.CFrame (the tween
-- owns it then); set by the enter tween's Completed, cleared on exit.
local examHeldCFrame = nil
-- Per-BasePart LocalTransparencyModifier fade tweens, keyed by part, so a
-- quick re-entry/exit can cancel an in-flight fade cleanly (Fix 4).
local examPartTweens = {}

local character = nil
local humanoid = nil
local humanoidRootPart = nil
local headPart = nil

-- Parts whose LocalTransparencyModifier we changed to hide in first person.
-- Stored so we can restore their original values on mode switch or respawn.
local hiddenParts = {}

-- Stamina state.
local stamina = GameConstants.PLAYER_STAMINA_MAX
local isSprinting = false
local isExhausted = false

-- Cursor / GUI state. guiOpenCount allows multiple panels to be open at once
-- (e.g. treatment + journal) without one closing re-locking the cursor while
-- the other is still visible.
local guiOpenCount = 0
local guiIsOpen = false

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 70

-- External UI scripts fire this to unlock the cursor while a panel is open.
local setGuiOpen = Instance.new("BindableEvent")
setGuiOpen.Name = "SetGuiOpen"
setGuiOpen.Parent = script

-- TreatmentPanelUI fires this to drive the examination camera:
-- Fire(true, npc) on panel open, Fire(false) on panel close.
local setExamining = Instance.new("BindableEvent")
setExamining.Name = "SetExamining"
setExamining.Parent = script

-- ---------------------------------------------------------------------------
-- Stamina bar UI
-- ---------------------------------------------------------------------------

local staminaGui = Instance.new("ScreenGui")
staminaGui.Name = "StaminaInterface"
staminaGui.ResetOnSpawn = false
staminaGui.IgnoreGuiInset = true
staminaGui.DisplayOrder = 3
staminaGui.Parent = localPlayer:WaitForChild("PlayerGui")

local staminaBackground = Instance.new("Frame")
staminaBackground.Name = "StaminaBackground"
staminaBackground.Size = UDim2.fromOffset(300, 14)
staminaBackground.Position = UDim2.new(0.5, -150, 1, -40)
staminaBackground.BackgroundColor3 = Color3.fromRGB(18, 16, 12)
staminaBackground.BackgroundTransparency = 0.2
staminaBackground.BorderSizePixel = 0
staminaBackground.Visible = false
staminaBackground.Parent = staminaGui

local staminaStroke = Instance.new("UIStroke")
staminaStroke.Color = Color3.fromRGB(80, 70, 50)
staminaStroke.Thickness = 1
staminaStroke.Parent = staminaBackground

local staminaFill = Instance.new("Frame")
staminaFill.Name = "StaminaFill"
staminaFill.Size = UDim2.fromScale(1, 1)
staminaFill.BackgroundColor3 = Color3.fromRGB(190, 150, 60)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaBackground

-- ---------------------------------------------------------------------------
-- Mouse / character helpers
-- ---------------------------------------------------------------------------

local function lockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function unlockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function restoreHiddenParts()
	for part, originalValue in hiddenParts do
		if part and part.Parent then
			part.LocalTransparencyModifier = originalValue
		end
	end
	table.clear(hiddenParts)
end

local function hideHeadAndAccessories()
	if not character then
		return
	end

	restoreHiddenParts()

	if headPart then
		hiddenParts[headPart] = headPart.LocalTransparencyModifier
		headPart.LocalTransparencyModifier = 1
	end

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Accessory") then
			local handle = descendant:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				hiddenParts[handle] = handle.LocalTransparencyModifier
				handle.LocalTransparencyModifier = 1
			end
		end
	end
end

local function resetCharacterTransparency()
	if not character then
		return
	end
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") and hiddenParts[descendant] == nil then
			descendant.LocalTransparencyModifier = 0
		end
	end
end

local function bindCharacter(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
	headPart = newCharacter:FindFirstChild("Head")

	raycastParams.FilterDescendantsInstances = { newCharacter }

	bobPhase = 0
	bobOffsetCurrent = Vector3.zero
	table.clear(hiddenParts)

	stamina = GameConstants.PLAYER_STAMINA_MAX
	isSprinting = false
	isExhausted = false

	humanoid.WalkSpeed = GameConstants.PLAYER_WALK_SPEED
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid.AutoRotate = currentMode ~= MODE_FIRST

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Climbing then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)

	-- Roblox's built-in TransparencyController fades character parts when the
	-- camera is close. Because we drive a scriptable camera at first-person
	-- range, it continually writes LocalTransparencyModifier > 0 on our parts.
	-- Reset on the next frame (so every part exists) and again every second.
	local capturedChar = newCharacter
	task.delay(0, resetCharacterTransparency)
	task.spawn(function()
		while capturedChar == character and capturedChar.Parent do
			task.wait(1)
			if capturedChar ~= character then
				break
			end
			resetCharacterTransparency()
		end
	end)

	if currentMode == MODE_FIRST then
		hideHeadAndAccessories()
	end
end

-- ---------------------------------------------------------------------------
-- Stamina logic
-- ---------------------------------------------------------------------------

local function updateStamina(dt)
	if not humanoid then
		return
	end

	local wantsSprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local moving = humanoid.MoveDirection.Magnitude > 0.1

	-- isExhausted latches true at 0 stamina and only unlatches at full.
	-- This prevents the player from tapping shift repeatedly to micro-sprint.
	local canSprint = wantsSprint and moving and not isExhausted and stamina > 0

	if canSprint then
		isSprinting = true
		stamina = math.max(0, stamina - GameConstants.PLAYER_STAMINA_DRAIN_RATE * dt)
		if stamina <= 0 then
			isSprinting = false
			isExhausted = true
		end
	else
		isSprinting = false
		stamina = math.min(GameConstants.PLAYER_STAMINA_MAX, stamina + GameConstants.PLAYER_STAMINA_REGEN_RATE * dt)
		local regenThreshold = GameConstants.PLAYER_STAMINA_MAX * GameConstants.PLAYER_STAMINA_REGEN_THRESHOLD
		if stamina >= regenThreshold then
			isExhausted = false
		end
	end

	local targetSpeed = isSprinting and GameConstants.PLAYER_RUN_SPEED or GameConstants.PLAYER_WALK_SPEED
	if humanoid.WalkSpeed ~= targetSpeed then
		humanoid.WalkSpeed = targetSpeed
	end

	local fraction = stamina / GameConstants.PLAYER_STAMINA_MAX
	staminaFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
	staminaBackground.Visible = fraction < 1
end

-- ---------------------------------------------------------------------------
-- Camera math
-- ---------------------------------------------------------------------------

local function getCameraOffset()
	-- Build a single rotation CFrame from yaw (world Y) and pitch (local X).
	local rotation = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
	return rotation
end

local function applyHeadBob(dt, baseCFrame, amplitudeScale)
	if not humanoid then
		return baseCFrame
	end

	local moving = humanoid.MoveDirection.Magnitude > 0.1
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local isRunning = humanoid.WalkSpeed >= RUN_SPEED_THRESHOLD

	local freq, ampV, ampH
	if isRunning then
		freq = GameConstants.CAMERA_BOB_RUN_FREQ
		ampV = GameConstants.CAMERA_BOB_RUN_AMP_V
		ampH = GameConstants.CAMERA_BOB_RUN_AMP_H
	else
		freq = GameConstants.CAMERA_BOB_WALK_FREQ
		ampV = GameConstants.CAMERA_BOB_WALK_AMP_V
		ampH = GameConstants.CAMERA_BOB_WALK_AMP_H
	end

	ampV = ampV * amplitudeScale
	ampH = ampH * amplitudeScale

	local targetOffset
	if moving and grounded then
		bobPhase = bobPhase + dt * freq
		-- Horizontal bob runs at half frequency so the camera traces a figure-8.
		local vertical = math.sin(bobPhase * 2 * math.pi) * ampV
		local horizontal = math.sin(bobPhase * math.pi) * ampH
		targetOffset = Vector3.new(horizontal, vertical, 0)
	else
		targetOffset = Vector3.zero
	end

	local smoothing = math.clamp(dt * 10, 0, 1)
	bobOffsetCurrent = bobOffsetCurrent:Lerp(targetOffset, smoothing)

	return baseCFrame * CFrame.new(bobOffsetCurrent)
end

local function applySway(dt, baseCFrame)
	swayTime = swayTime + dt

	local amp
	if currentMode == MODE_FIRST then
		amp = GameConstants.CAMERA_SWAY_AMP_FP
	else
		amp = GameConstants.CAMERA_SWAY_AMP_TP
	end

	local freq = GameConstants.CAMERA_SWAY_FREQ
	local roll = math.sin(swayTime * freq) * amp
	local pitchTilt = math.sin(swayTime * freq * 0.7 + 1.3) * amp * 0.5

	return baseCFrame * CFrame.Angles(math.rad(pitchTilt), 0, math.rad(roll))
end

local function updateThirdPerson(dt)
	if not humanoidRootPart then
		return
	end

	local pivot = humanoidRootPart.Position + Vector3.new(0, GameConstants.CAMERA_THIRD_PERSON_HEIGHT, 0)
	local rotation = getCameraOffset()

	local shoulder = GameConstants.CAMERA_THIRD_PERSON_SHOULDER_OFFSET
	local distance = GameConstants.CAMERA_THIRD_PERSON_DIST
	local desiredPos = pivot + (rotation * Vector3.new(shoulder, 0, distance))

	-- Keep the camera from poking through geometry by raycasting from the
	-- pivot toward the desired position and stopping 0.3 studs short of any
	-- hit (prevents z-fighting against the surface).
	local direction = desiredPos - pivot
	local result = Workspace:Raycast(pivot, direction, raycastParams)
	if result then
		local pullBack = 0.3
		local safeDir = direction.Unit * math.max(0, (result.Position - pivot).Magnitude - pullBack)
		desiredPos = pivot + safeDir
	end

	local lookAtTarget = pivot + (rotation * Vector3.new(shoulder, 0, 0))
	local desiredCFrame = CFrame.lookAt(desiredPos, lookAtTarget)

	desiredCFrame = applyHeadBob(dt, desiredCFrame, 0.4)
	desiredCFrame = applySway(dt, desiredCFrame)

	local alpha = 1 - math.exp(-GameConstants.CAMERA_LERP_SPEED * dt)
	currentCameraCFrame = currentCameraCFrame:Lerp(desiredCFrame, alpha)
	camera.CFrame = currentCameraCFrame
end

local function updateFirstPerson(dt)
	if not humanoidRootPart then
		return
	end

	-- Anchor the eye to HRP's CFrame (not just its position) so strafing and
	-- turning move the eye with the body instead of leaving it behind the spine.
	-- +1.6Y lifts it to eye height; -0.4Z pushes it forward out of the forehead
	-- so looking down does not reveal the character's back or feet.
	local origin = humanoidRootPart.Position
	local desiredEye = (humanoidRootPart.CFrame * CFrame.new(0, 1.6, -0.4)).Position

	-- If the HRP is pressed against a wall, the desired eye can end up on the
	-- other side of the surface. Raycast from HRP center toward the eye and
	-- clamp before any hit so the camera never crosses a solid face.
	local toEye = desiredEye - origin
	local eyePosition = desiredEye
	if toEye.Magnitude > 0 then
		local result = Workspace:Raycast(origin, toEye, raycastParams)
		if result then
			local safeDist = math.max(0, (result.Position - origin).Magnitude - 0.05)
			eyePosition = origin + toEye.Unit * safeDist
		end
	end

	-- Yaw in first person is decoupled from HumanoidRootPart rotation. Movement
	-- (WASD + AutoRotate) can turn the character, but should not drag the
	-- camera with it unless the player moves the mouse.
	local yawTotalRad = math.rad(fpYawCenter + fpYawOffset)

	local desiredCFrame = CFrame.new(eyePosition)
		* CFrame.Angles(0, yawTotalRad, 0)
		* CFrame.Angles(math.rad(pitch), 0, 0)

	desiredCFrame = applyHeadBob(dt, desiredCFrame, 1.0)
	desiredCFrame = applySway(dt, desiredCFrame)

	-- First person does NOT lerp; we snap so pressing against a wall in TP and
	-- switching to FP cannot leak a stale lerp target into the eye position.
	camera.CFrame = desiredCFrame
end

local function setMode(mode)
	if mode == currentMode then
		return
	end

	currentMode = mode

	if mode == MODE_FIRST then
		hideHeadAndAccessories()
		if humanoid then
			humanoid.AutoRotate = false
		end
		fpYawCenter = yaw
		fpYawOffset = 0
	else
		restoreHiddenParts()
		if humanoid then
			humanoid.AutoRotate = false
		end
		-- Preserve where the player was looking when leaving first person.
		yaw = fpYawCenter + fpYawOffset
		fpYawOffset = 0
		-- Seed the TP lerp with whatever the camera currently is, so the
		-- transition starts from where FP left the camera instead of a stale
		-- accumulator from before the mode switch.
		currentCameraCFrame = camera.CFrame
	end
end

-- ---------------------------------------------------------------------------
-- Examination camera
-- ---------------------------------------------------------------------------

-- Camera EXAM_DISTANCE studs directly in front of the NPC (along its HRP
-- LookVector), at chest height. The camera does NOT look at the NPC's center;
-- it looks PAST the NPC to a point offset EXAM_LATERAL_OFFSET studs along the
-- NPC's RightVector. Aiming off-axis like this slides the NPC toward the left
-- of the frame (the off-axis look point becomes screen-center), leaving the
-- right side empty for the examination UI panel.
local function computeExamCFrame(npc)
	if not npc then
		return nil
	end
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	if not npcRoot then
		return nil
	end
	local chestPos = npcRoot.Position + Vector3.new(0, EXAM_CHEST_OFFSET, 0)
	local camPos = chestPos + npcRoot.CFrame.LookVector * EXAM_DISTANCE
	local lookAtTarget = chestPos + npcRoot.CFrame.RightVector * EXAM_LATERAL_OFFSET
	return CFrame.lookAt(camPos, lookAtTarget)
end

-- Fade every BasePart of the local character to hidden over the camera-tween
-- duration, reusing the hiddenParts table (skipped by resetCharacterTransparency
-- so the 1 Hz reset loop will not fight the fade). Fix 3: never call
-- restoreHiddenParts here and never re-touch an already-tracked part, so
-- re-examining while still hidden does not flash the character back to visible.
local function hideAllCharacterParts()
	if not character then
		return
	end
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			-- Only record an original the first time so a mid-fade value is
			-- never stored as the "original" on a quick re-entry.
			if hiddenParts[descendant] == nil then
				hiddenParts[descendant] = descendant.LocalTransparencyModifier
			end
			-- Cancel any in-flight fade for this part (e.g. a restore fade
			-- from a previous exit) before driving it to hidden.
			local existing = examPartTweens[descendant]
			if existing then
				existing:Cancel()
				examPartTweens[descendant] = nil
			end
			if descendant.LocalTransparencyModifier ~= 1 then
				local fade = TweenService:Create(
					descendant,
					EXAM_TWEEN_INFO,
					{ LocalTransparencyModifier = 1 }
				)
				examPartTweens[descendant] = fade
				fade:Play()
			end
		end
	end
end

local function enterExamination(npc)
	if inExamination then
		-- Panel cannot reopen until the server round-trip completes, by which
		-- time the 0.6s exit tween has finished; a stale enter is ignored.
		return
	end

	local target = computeExamCFrame(npc)
	if not target then
		warn("[CameraController] examination NPC has no HumanoidRootPart; camera unchanged.")
		return
	end

	inExamination = true
	preExamCFrame = camera.CFrame
	-- Cleared so onRenderStep does not pin a stale pose while the enter tween
	-- is the active owner of camera.CFrame; the tween's Completed sets it.
	examHeldCFrame = nil

	if humanoid then
		humanoid.WalkSpeed = 0
	end
	hideAllCharacterParts()

	-- Create and assign the new camera tween before cancelling the previous
	-- one. Tween:Cancel() also fires Completed; in this order the stale exit
	-- tween's guarded callback sees examTween already pointing at the new
	-- tween and bails (Fix 1, robust under Immediate and Deferred signals).
	local previousTween = examTween
	examTween = TweenService:Create(camera, EXAM_TWEEN_INFO, { CFrame = target })
	local thisTween = examTween
	thisTween.Completed:Connect(function()
		-- Same stale-tween guard as exitExamination: Cancel() also fires
		-- Completed, so only pin the held pose if we are still the active
		-- enter tween (a later enter/exit may have replaced us).
		if examTween ~= thisTween then
			return
		end
		-- Pin to the same target the tween animated to so onRenderStep holds
		-- the camera here instead of the default camera taking over.
		examHeldCFrame = target
	end)
	if previousTween then
		previousTween:Cancel()
	end
	examTween:Play()
end

local function exitExamination()
	if not inExamination then
		return
	end

	-- NOTE: examHeldCFrame is deliberately NOT cleared here. Clearing it before
	-- the exit tween owns camera.CFrame leaves a frame where onRenderStep
	-- writes nothing (inExamination still true, examHeldCFrame nil) and the
	-- camera is unowned -> snap. It is cleared one render frame after the exit
	-- tween's Play() instead (see the deferred clear below).

	-- Fix 4: fade the character back in over the same 0.6s / Quad-Out as the
	-- camera instead of an instant restore. Cancel any in-flight hide fade per
	-- part first. hiddenParts is intentionally left populated until the fade
	-- finishes so resetCharacterTransparency keeps skipping these parts.
	for part, originalValue in hiddenParts do
		if part and part.Parent then
			local existing = examPartTweens[part]
			if existing then
				existing:Cancel()
			end
			local fade = TweenService:Create(
				part,
				EXAM_TWEEN_INFO,
				{ LocalTransparencyModifier = originalValue }
			)
			examPartTweens[part] = fade
			fade:Play()
		end
	end
	-- WalkSpeed is restored by updateStamina once inExamination clears.

	-- Assign the new exit tween before cancelling the previous one, same
	-- ordering rationale as enterExamination.
	local previousTween = examTween
	local restoreCFrame = preExamCFrame or camera.CFrame
	local thisTween = TweenService:Create(camera, EXAM_TWEEN_INFO, { CFrame = restoreCFrame })
	examTween = thisTween
	if previousTween then
		previousTween:Cancel()
	end
	thisTween.Completed:Connect(function()
		-- Fix 1: Tween:Cancel() also fires Completed. Only act if we are still
		-- the active exit tween; a new examination may have replaced us, in
		-- which case this is a stale callback and must not flip state.
		if examTween ~= thisTween then
			return
		end
		-- Seed the third-person lerp accumulator with where the tween landed so
		-- the normal scriptable camera resumes without a snap. CameraType stays
		-- Scriptable throughout; this game has no Custom camera to return to.
		currentCameraCFrame = camera.CFrame
		inExamination = false
		-- Defensive: ensure no stale held pose leaks into the next examination.
		examHeldCFrame = nil

		-- Finalize the restore now the fade is complete: snap to the exact
		-- originals, then clear the tracking tables so the 1 Hz reset loop
		-- resumes ownership of these parts.
		for part, originalValue in hiddenParts do
			if part and part.Parent then
				part.LocalTransparencyModifier = originalValue
			end
		end
		table.clear(hiddenParts)
		table.clear(examPartTweens)

		-- FP normally hides the head/accessories; reinstate after the
		-- full-body restore so the player does not see their own head.
		if currentMode == MODE_FIRST then
			hideHeadAndAccessories()
		end
	end)
	thisTween:Play()

	-- Keep the held pose written by onRenderStep for one more render frame so
	-- camera.CFrame is never unowned during the handoff to the exit tween. The
	-- tween's first interpolated write starts from the held pose anyway, so the
	-- one-frame overlap is visually identical and avoids the unowned-frame snap.
	-- Same stale-tween guard as the Completed handlers: bail if a newer tween
	-- has replaced us before the deferred clear runs.
	task.spawn(function()
		RunService.RenderStepped:Wait()
		if examTween ~= thisTween then
			return
		end
		examHeldCFrame = nil
	end)
end

-- ---------------------------------------------------------------------------
-- Render step (camera + stamina)
-- ---------------------------------------------------------------------------

local function onRenderStep(dt)
	if not humanoidRootPart or not humanoidRootPart.Parent then
		return
	end

	if guiIsOpen then
		-- Re-assert every frame in case anything else (PlayerModule, devtools)
		-- tries to grab the cursor back while a panel is open.
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		if not UserInputService.MouseIconEnabled then
			UserInputService.MouseIconEnabled = true
		end
	elseif UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		local delta = UserInputService:GetMouseDelta()
		local sensitivity = GameConstants.CAMERA_SENSITIVITY
		local dxDeg = delta.X * sensitivity
		local dyDeg = delta.Y * sensitivity
		if currentMode == MODE_FIRST then
			fpYawOffset = math.clamp(
				fpYawOffset - dxDeg,
				GameConstants.CAMERA_FP_YAW_MIN,
				GameConstants.CAMERA_FP_YAW_MAX
			)
		else
			yaw = yaw - dxDeg
		end
		pitch = math.clamp(pitch - dyDeg, PITCH_MIN_DEG, PITCH_MAX_DEG)
	end

	-- During examination the camera is owned by the examination tween (or held
	-- at the target CFrame after it completes). Skip the normal camera and the
	-- stamina/walkspeed loop so neither fights the tween nor undoes WalkSpeed=0.
	-- The GUI cursor block above still runs so the panel stays usable.
	if inExamination then
		-- A tween does not hold a property after it completes; it only
		-- animates to it. While the enter tween is still playing,
		-- examHeldCFrame is nil and the tween itself owns camera.CFrame, so we
		-- skip the write. Once the enter tween completes it pins examHeldCFrame
		-- and we re-assert it every frame, otherwise the default camera would
		-- take over the moment the tween releases the property. updateStamina
		-- and the camera-solve functions still do not run during examination.
		if examHeldCFrame then
			camera.CFrame = examHeldCFrame
		end
		return
	end

	updateStamina(dt)

	if currentMode == MODE_FIRST then
		updateFirstPerson(dt)
	else
		updateThirdPerson(dt)
	end
end

-- ---------------------------------------------------------------------------
-- Input handling
-- ---------------------------------------------------------------------------

local function toggleJournal()
	local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then
		warn("[CameraController] PlayerScripts missing; cannot toggle journal.")
		return
	end

	local clientFolder = playerScripts:WaitForChild("Client", 2)
	if not clientFolder then
		warn("[CameraController] Client folder missing; cannot toggle journal.")
		return
	end

	local uiFolder = clientFolder:WaitForChild("ui", 2)
	if not uiFolder then
		warn("[CameraController] Client/ui folder missing; cannot toggle journal.")
		return
	end

	local journalScript = uiFolder:WaitForChild("JournalUI", 2)
	if not journalScript then
		warn("[CameraController] JournalUI script missing; cannot toggle journal.")
		return
	end

	local toggleEvent = journalScript:FindFirstChild("JournalToggle")
	if not toggleEvent then
		warn("[CameraController] JournalToggle event missing; cannot toggle journal.")
		return
	end

	toggleEvent:Fire()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Y then
		if currentMode == MODE_THIRD then
			setMode(MODE_FIRST)
		else
			setMode(MODE_THIRD)
		end
	elseif input.KeyCode == Enum.KeyCode.J then
		toggleJournal()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		unlockMouse()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.MouseButton3 then
		if not guiIsOpen then
			lockMouse()
		end
	end
end)

setGuiOpen.Event:Connect(function(open)
	if open then
		guiOpenCount = guiOpenCount + 1
	else
		guiOpenCount = math.max(0, guiOpenCount - 1)
	end

	guiIsOpen = guiOpenCount > 0
	if guiIsOpen then
		unlockMouse()
	else
		lockMouse()
	end
end)

setExamining.Event:Connect(function(active, npc)
	if active then
		enterExamination(npc)
	else
		exitExamination()
	end
end)

localPlayer.CharacterAdded:Connect(bindCharacter)
if localPlayer.Character then
	bindCharacter(localPlayer.Character)
end

lockMouse()

RunService:BindToRenderStep("CameraController", Enum.RenderPriority.Camera.Value + 1, onRenderStep)
