-- Ludum Dare 46

-- UTILITY

function lerp( a, b, alpha )
	return a + (b-a) * alpha
end

function randInRange( a, b )
	return lerp( a, b, math.random() )
end

function randInt( a, b )
	return math.floor( randInRange( a, b ))
end

function randomElement( tab )
	local n = #tab
	if n == 0 then return nil end

	return tab[ math.random( 1, #tab ) ]
end

function tableString( tab )
	local str = ''
	for key, value in pairs( tab ) do
		str = str .. key .. '=' .. value .. ', '
	end
	return str
end

function tableStringValues( tab )
	local str = ''
	for _, value in pairs( tab ) do
		str = str .. value .. ' '
	end
	return str
end

function stringify( o )
	if type( o ) == 'table' then
		return saveTable( o )
	elseif type( o ) == 'string' then
		return '"' .. o .. '"'
	elseif type( o ) == 'boolean' then
		return boolToString( o )
	elseif type( o ) == 'function' then
		return '<function>'
	else
		return '' .. o
	end
end

function saveTable( tab )
	local str = '{'
	for key, value in pairs( tab ) do
		str = str .. key .. '=' .. stringify( value ) .. ','
	end
	str = str .. '}'

	return str
end

function restoreTable( tab, string )
	-- TODO
end

function tableFind( tab, element )
    for index, value in pairs(tab) do
        if value == element then
            return index
        end
	end
	return nil
end

function tableRemoveValue( tab, element )
	table.remove( tab, tableFind( tab, element ))
end

function tableCopy( t )
	local u = {}
	for k, v in pairs(t) do
		u[k] = v
	end
	return setmetatable(u, getmetatable(t))
end

function tableFilter( tab, fn )
	local result = {}
	for _, value in ipairs( tab ) do
		if fn( value ) then
			table.insert( result, value )
		end
	end
	return result
end

function boolToString( b )
	return b and 'true' or 'false'
end

local physicalButtonsPressed = false
function showControlsGuides( show )
	show_controls_guides( show and not physicalButtonsPressed )
end


local MUTE_SOUND = false

function sfxm( sound, gain )
	if not MUTE_SOUND then
		sfx( sound, gain )
	end
end

function musicm( sound, gain )
	if not MUTE_SOUND or #sound == 0 then
		music( sound, gain )
	end
end

local debugCircles = {}
local debugMessages = {}

function drawDebugCircles()
	for _, circle in ipairs( debugCircles ) do
		circ( circle[1].x, circle[1].y, 32 )
	end

	debugCircles = {}
end

function drawDebug()
	print( '', 0, 0 )

	-- print( tostring( mousex ) .. ',' .. tostring( mousey ) .. '::' .. tostring( placeableRoom ))
	-- print( tostring( world.focusX ) .. ',' .. tostring( world.focusY ))

	-- print( 'actors: ' .. tostring( #world.actors ), 0, 0 )

	for _,message in ipairs( debugMessages ) do
		print( message )
	end

	while #debugMessages > 10 do
		table.remove( debugMessages, 1 )
	end
end

function debugCircle( center, radius, color )
	table.insert( debugCircles, {center, radius, color })
end

function trace( message )
	table.insert( debugMessages, message )
end

function length( x, y )
	return math.sqrt( x * x + y * y )
end

function sign( x )
	return x < 0 and -1 or ( x > 0 and 1 or 0 )
end

function signNoZero( x )
	return x < 0 and -1 or 1
end

function clamp( x, minimum, maximum )
	return math.min( maximum, math.max( x, minimum ))
end

function proportion( x, a, b )
	return ( x - a ) / ( b - a )
end

function pctChance( percent )
	return randInRange( 0, 100 ) <= percent
end

function round( x, divisor )
	divisor = divisor or 1
	return ( x + 0.5 ) // divisor * divisor
end

-- TIME

local ticks = 0
function now()
	return ticks * 1 / 60.0
end

local realTicks = 0
function realNow()
	return realTicks * 1 / 60.0
end

-- Configuration

support_virtual_trackball( true )
text_scale( 1 )
filter_mode( "Nearest" )

screen_size( 220, 0 )

local WHITE = 0xFFE3E0F2
local YELLOW = 0xFFDBC762
local BRIGHT_RED = 0xFFC23324
local LIGHT_GRAY = 0xFFB0B8BF
local BRIGHT_BLUE = 0xFF0466c2


-- GLOBALS

local GLOBAL_DRAG = 0.175
local RESOURCE_MAX_COUNT_DEFAULT = 9

local MIN_ACTIVE_BLOCK_INDEX = 256

local SPRITE_SHEET_PIXELS_X = 512
local PIXELS_PER_TILE = 16
local TILES_X = SPRITE_SHEET_PIXELS_X // PIXELS_PER_TILE

local ACTOR_DRAW_MARGIN = PIXELS_PER_TILE

sprite_size( PIXELS_PER_TILE )

local WORLD_SIZE_TILES = 32
local WORLD_SIZE_PIXELS = WORLD_SIZE_TILES * PIXELS_PER_TILE

function spriteIndex( x, y )
	return y * TILES_X + x
end

function worldToTile( x )
	return math.floor( x / PIXELS_PER_TILE )
end

local DEFAULT_CHROMATIC_ABERRATION = 0.4
local DEFAULT_BARREL = 0.2
local DEFAULT_BLOOM_INTENSITY = 0.1
local DEFAULT_BURN_IN = 0.1

local barrel_ = DEFAULT_BARREL
local bloom_intensity_ = DEFAULT_BLOOM_INTENSITY
local bloom_contrast_ = 10
local bloom_brightness_ = 1
local burn_in_ = DEFAULT_BURN_IN
local chromatic_aberration_ = DEFAULT_CHROMATIC_ABERRATION
local noise_ = 0.025
local rescan_ = 0.75
local saturation_ = 1
local color_multiplied_r = 1
local color_multiplied_g = 1
local color_multiplied_b = 1
local bevel_ = 0.20

local barrel_smoothed = barrel_
local bloom_intensity_smoothed = bloom_intensity_
local bloom_contrast_smoothed = bloom_contrast_
local bloom_brightness_smoothed = bloom_brightness_
local burn_in_smoothed = burn_in_
local chromatic_aberration_smoothed = chromatic_aberration_
local noise_smoothed = noise_
local rescan_smoothed = rescan_
local saturation_smoothed = saturation_
local color_multiplied_r_smoothed = color_multiplied_r
local color_multiplied_g_smoothed = color_multiplied_g
local color_multiplied_b_smoothed = color_multiplied_b
local bevel_smoothed = bevel_

local SCREEN_EFFECT_SMOOTH_FACTOR = 0.035

function updateScreenParams()
	barrel_smoothed = lerp( barrel_smoothed, barrel_, SCREEN_EFFECT_SMOOTH_FACTOR )
	bloom_intensity_smoothed = lerp( bloom_intensity_smoothed, bloom_intensity_, SCREEN_EFFECT_SMOOTH_FACTOR )
	bloom_contrast_smoothed = lerp( bloom_contrast_smoothed, bloom_contrast_, SCREEN_EFFECT_SMOOTH_FACTOR )
	bloom_brightness_smoothed = lerp( bloom_brightness_smoothed, bloom_brightness_, SCREEN_EFFECT_SMOOTH_FACTOR )
	burn_in_smoothed = lerp( burn_in_smoothed, burn_in_, SCREEN_EFFECT_SMOOTH_FACTOR )
	chromatic_aberration_smoothed =
		lerp( chromatic_aberration_smoothed, chromatic_aberration_, SCREEN_EFFECT_SMOOTH_FACTOR )
	noise_smoothed = lerp( noise_smoothed, noise_, SCREEN_EFFECT_SMOOTH_FACTOR )
	rescan_smoothed = lerp( rescan_smoothed, rescan_, SCREEN_EFFECT_SMOOTH_FACTOR )
	saturation_smoothed = lerp( saturation_smoothed, saturation_, SCREEN_EFFECT_SMOOTH_FACTOR )
	color_multiplied_r_smoothed = lerp( color_multiplied_r_smoothed, color_multiplied_r, SCREEN_EFFECT_SMOOTH_FACTOR )
	color_multiplied_g_smoothed = lerp( color_multiplied_g_smoothed, color_multiplied_g, SCREEN_EFFECT_SMOOTH_FACTOR )
	color_multiplied_b_smoothed = lerp( color_multiplied_b_smoothed, color_multiplied_b, SCREEN_EFFECT_SMOOTH_FACTOR )
	bevel_smoothed = lerp( bevel_smoothed, bevel_, SCREEN_EFFECT_SMOOTH_FACTOR )

	barrel( barrel_smoothed )
	bloom( bloom_intensity_smoothed, bloom_contrast_smoothed, bloom_brightness_smoothed )
	burn_in( burn_in_smoothed )
	chromatic_aberration( chromatic_aberration_smoothed )
	noise( noise_smoothed, rescan_smoothed )
	saturation( saturation_smoothed )
	color_multiplied( color_multiplied_r_smoothed, color_multiplied_g_smoothed, color_multiplied_b_smoothed )
	bevel( bevel_smoothed, 1 )
end

updateScreenParams()


-- Vector

--[[
Vector class ported/inspired from
Processing (http://processing.org)
]]--
local vec2 = {}

function vec2:new( x, y )

	if type( x ) == 'table' then
		y = x.y
		x = x.x
	end

	x = x or 0
	y = y or x

	local o = {
	x = x,
	y = y
	}

	self.__index = self
	return setmetatable(o, self)
end

function vec2:__add(v)
  return vec2:new( self.x + v.x, self.y + v.y )
end

function vec2:__sub(v)
	return vec2:new( self.x - v.x, self.y - v.y )
end

function vec2:__mul(v)
	if v == nil then
		trace( 'vec2:__mul called with nil operand.' )
		return
	end

	if type( v ) == 'number' then
		v = { x = v, y = v }
	end

	return vec2:new( self.x * v.x, self.y * v.y )
end

function vec2:__div(v)

	if type( v ) == 'number' then
		v = { x = v, y = v }
	end

	if v.x == nil or v.x == 0 then
		v.x = 1
	end

	if v.y == nil or v.y == 0 then
		v.y = 1
	end

	return vec2:new( self.x / v.x, self.y / v.y )
end

function vec2:length()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec2:lengthSquared()
  return self.x * self.x + self.y * self.y
end

function vec2:dist(v)
  local dx = self.x - v.x
  local dy = self.y - v.y

  return math.sqrt(dx * dx + dy * dy)
end

function vec2:dot(v)
  return self.x * v.x + self.y * v.y
end

function vec2:majorAxis()
	return math.abs( self.x ) > math.abs( self.y ) and 0 or 1
end

function vec2:snappedToMajorAxis()
	if self:majorAxis() == 0 then
		return vec2:new( signNoZero( self.x ), 0 )
	else
		return vec2:new( signNoZero( self.y ), 0 )
	end
end

function vec2:cardinalDirection() -- 0 = north, 1 = east...
	if self:majorAxis() == 0 then
		return self.x >= 0 and 1 or 3
	else
		return self.y >= 0 and 2 or 0
	end
end

function vec2:normal()
  local m = self:length()
  if m ~= 0 then
    return self / m
  else
	return self
  end
end

function vec2:limit(max)
  local m = self.lengthSquared()
  if m >= max * max then
    return self:normal() * max
  end
end

 function vec2:heading()
  local angle = math.atan2(-self.y, self.x)
  return -1 * angle
end

function vec2:rotate(theta)
  local tempx = self.x
  self.x = self.x * math.cos(theta) - self.y * math.sin(theta)
  self.y = tempx * math.sin(theta) + self.y * math.cos(theta)
end

function vec2:angle_between(v1, v2)
  if v1.x == 0 and v1.y then
    return 0
  end

  if v2.x == 0 and v2.y == 0 then
    return 0
  end

  local dot = v1.x * v2.x + v1.y * v2.y
  local v1mag = math.sqrt(v1.x * v1.x + v1.y * v1.y)
  local v2mag = math.sqrt(v2.x * v2.x + v2.y * v2.y)
  local amt = dot / (v1mag * v2mag)

  if amt <= -1 then
    return math.pi
  elseif amt >= 1 then
    return 0
  end

  return math.acos(amt)
end

function vec2:set(x, y)
	if type( x ) == 'table' then
		self.x = x.x
		self.y = x.y
	else
		self.x = x
		self.y = y ~= nil and y or x
	end
end

function vec2:equals(o)
  o = o or {}
  return self.x == o.x and self.y == o.y
end

function vec2:__tostring()
  return '(' .. string.format( "%.2f", self.x ) .. ', ' .. string.format( "%.2f", self.y ) .. ')'
end

function sheet_pixels_to_sprite( x, y )
	return ( y // PIXELS_PER_TILE ) * (SPRITE_SHEET_PIXELS_X//PIXELS_PER_TILE) + ( x // PIXELS_PER_TILE )
end

-- Objects

function rectsOverlap( rectA, rectB )
	return not (
			rectB.right < rectA.left
		or  rectB.left > rectA.right
		or  rectB.bottom < rectA.top
		or  rectB.top > rectA.bottom )
end

function rectOverlapsPoint( rect, pos )
	return rect.left <= pos.x and pos.x <= rect.right and rect.top <= pos.y and pos.y <= rect.bottom
end

function expandContractRect( rect, expansion )
	rect.left = rect.left - expansion
	rect.top = rect.top - expansion
	rect.right = rect.right + expansion
	rect.bottom = rect.bottom + expansion
	return rect
end

function headingToDirectionName( direction )
	if direction == 0 then return 'north'
	elseif direction == 1 then return 'east'
	elseif direction == 2 then return 'south'
	elseif direction == 3 then return 'west'
	else return nil end
end

function sprite_by_grid( x, y )
	return y // TILES_X + x
end

function range( from, to, step )
	local arr = {}
	for i = from, to, step or 1 do
		table.insert( arr, i )
	end
	return arr
end

local initialMap = {}	-- TODO!!! save with world?

function saveInitialMap()
	initialMap = {}
	for y = 0, WORLD_SIZE_TILES - 1 do
		initialMap[ y ] = {}
		for x = 0, WORLD_SIZE_TILES - 1 do
			initialMap[ y ][ x ] = mget( x, y )
		end
	end
end

function restoreInitialMap()
	if initialMap == nil then
		trace( 'no initial map to restore' )
		return
	end

	for y = 0, WORLD_SIZE_TILES - 1 do
		for x = 0, WORLD_SIZE_TILES - 1 do
			mset( x, y, initialMap[ y ][ x ] )
		end
	end
end

local world = {}

function actorCenter( actor )
	return actor.pos - vec2:new( 0, actor.config.dims.y * 0.5 )
end

function actorConveyorForce( actor, force )
	actor.vel = actor.vel + force
end

function actorControlThrust( actor, thrust )
	actor.thrust = thrust
	actor.vel = actor.vel + thrust

	if thrust:lengthSquared() > 0 then
		actor.heading = thrust:normal()
	end
end

ARM_OFFSET = vec2:new( 0, -2 )

function pickupPoint( byActor, useArmLength )
	assert( useArmLength )
	return byActor.pos + ARM_OFFSET + byActor.heading * useArmLength
end

function placementPoint( byActor, useArmLength )
	assert( useArmLength )
	return byActor.pos + ARM_OFFSET + byActor.heading * useArmLength
end

function blockInteractionTile( byActor, useArmLength )
	local point = pickupPoint( byActor, useArmLength )

	local pickupTileX = worldToTile( point.x )
	local pickupTileY = worldToTile( point.y )

	if  pickupTileX < 0 or pickupTileX >= WORLD_SIZE_TILES or
		pickupTileY < 0 or pickupTileY >= WORLD_SIZE_TILES then
			return nil
	end

	return pickupTileX, pickupTileY
end

function blockToPickup( byActor, useArmLength )

	local pickupTileX, pickupTileY = blockInteractionTile( byActor, useArmLength )

	local blockType = blockTypeAt( pickupTileX, pickupTileY )
	if blockType == nil or blockType.stationary then return nil end

	return pickupTileX, pickupTileY
end

function randomGroundBlockIndex()
	return randInt( 256, 256+5 )
end

function blockOnNeighborChanged( x, y, changedX, changedY )
	withBlockTypeAt( x, y, function( blockType, blockTypeIndex )
		withBaseBlockType( blockTypeIndex, function( baseBlockType, baseBlockTypeIndex )
			if baseBlockType ~= nil and baseBlockType.onPlaced ~= nil then
				baseBlockType.onPlaced( x, y, baseBlockType, blockTypeIndex )
			end
		end)
	end)
end

function onBlockChangeNear( x, y )
	blockOnNeighborChanged( x, y, x, y )		-- self, actually
	blockOnNeighborChanged( x, y - 1, x, y )
end

function setBlockTypeSimple( x, y, blockTypeIndex )
	if blockTypeIndex == mget( x, y ) then return end

	blockDeleteSponsored( x, y )
	mset( x, y, blockTypeIndex )
end

function setBlockType( x, y, blockTypeIndex )
	if blockTypeIndex == mget( x, y ) then return end
	setBlockTypeSimple( x, y, blockTypeIndex )
	onBlockChangeNear( x, y )
end

function clearBlock( x, y )
	setBlockType( x, y, randomGroundBlockIndex() )
	clearDataForBlockAt( x, y )
end

function createActorForBlockIndex( blockTypeIndex, x, y )
	return withBaseBlockType( blockTypeIndex, function( baseBlockType, baseBlockTypeIndex )
		if baseBlockType.actorConfigName ~= nil then
			return createActor( baseBlockType.actorConfigName, x, y )
		end
	end)
end

function forEachActorNear( x, y, radius, callback )
	local pos = vec2:new( x, y )
	local rSquared = radius * radius
	for _, actor in ipairs( world.actors ) do
		local distSquared = ( actor.pos - pos ):lengthSquared()
		if distSquared <= rSquared then
			callback( actor, distSquared )
		end
	end
end

function closestActorTo( x, y, radius, filterFn )
	local nearestActor = nil
	local nearestDistSquared = nil
	forEachActorNear( x, y, radius, function( actor, distSquared )
		if not filterFn( actor, distSquared ) then return end

		if nearestDistSquared == nil or distSquared < nearestDistSquared then
			nearestDistSquared = distSquared
			nearestActor = actor
		end
	end)

	return nearestActor
end

function findPickupActorNear( forActor, x, y, radius )
	return closestActorTo( x, y, radius, function( actor, distSquared )
		return actor.holder == nil and actor.config.mayBePickedUp and actor ~= forActor
	end)
end

function makeHeld( item, holder )
	item.wasEverHeld = true
	item.holder = holder
	item.inert = true
	item.nonColliding = true
	item.z = 0
	actorSnapTo( item, item.pos )
	item.lastPlayerPlacedPos = nil
	item.thrust = vec2:new( 0, 0 )
	item.heading = vec2:new( -1, 0 )

	createShadowForActor( item )
end

function makeNotHeld( item, dropPoint )
	item.holder = nil
	actorSnapTo( item, dropPoint )
	item.lastPlayerPlacedPos = vec2:new( item.pos )
	item.ulOffset = nil
	item.z = 0
	item.inert = false
	item.nonColliding = false
	if item.shadow ~= nil then deleteActor( item.shadow ) end
	world.player.heldItem = nil
end


function mayPlaceBlockOnBlock( x, y )
	local blockType, blockTypeIndex = blockTypeAt( x, y )
	if blockType == nil then return false end

	return blockType.mayBePlacedUpon or false
end

function tryPlaceAsBlock( item, direction, position )
	assert( position )
	local blockTypeForItem = actorPlacementBlock( item, direction )
	if blockTypeForItem == nil then return nil end

	-- clear block placement area?
	local placementPos = position or item.pos
	local placementX = worldToTile( placementPos.x )
	local placementY = worldToTile( placementPos.y )
	if not mayPlaceBlockOnBlock( placementX, placementY ) then
		return nil
	end

	setBlockType( placementX, placementY, blockTypeForItem )

	actorCountAdd( item, -1 )

	return placementX, placementY
end

function playerTryPlaceAsBlock( item, direction, position )

	local placementX, placementY = tryPlaceAsBlock( item, direction, position )

	if placementX ~= nil then

		-- succeeded
		if item.deleted then
			world.player.heldItem = nil
		end

		createActor( 'placement_poof', placementX * PIXELS_PER_TILE, placementY * PIXELS_PER_TILE )
		sfxm( 'drop_block' )
	end

	return placementX, placementY
end

DEFAULT_ARM_LENGTH = 4

function tryDropHeldItem( options )

	local item = world.player.heldItem
	if not item then return end

	options = options or {
		preferDropAll = false
	}

	-- If we're only holding one thing, nevermind about dropping "all".
	options.preferDropAll = options.preferDropAll and ( item.count or 1 ) > 1

	local dropPoint = placementPoint( world.player, DEFAULT_ARM_LENGTH )

	local placed = false

	if not options.preferDropAll then
		-- try to place as a block
		local placementX, placementY = playerTryPlaceAsBlock( item, world.player.heading:cardinalDirection(), dropPoint )
		placed = placementX ~= nil
	end

	world.dropped = true

	-- failed?
	if not placed then
		-- try to place as an item

		sfxm( 'drop_item' )

		-- does this item have count?
		if not options.preferDropAll and (( item.count or 1 ) > 1 ) then
			createActor( item.configKey, dropPoint.x, dropPoint.y )
			item.lastPlayerPlacedPos = vec2:new( item.pos.x, item.pos.y )
			actorCountAdd( item, -1 )
		else
			-- no count, or we're dropping them all. don't create a new item, just drop this one.
			makeNotHeld( item, dropPoint )
		end
	end
end

function tryPickupActor( byActor )

	function tryArmLength( armLength )
		-- look for actors near the pick area
		local point = pickupPoint( byActor, armLength )
		local pickupActor = findPickupActorNear( byActor, point.x, point.y, 12 )
		if pickupActor == byActor or pickupActor == nil then return nil end

		if byActor.heldItem == nil or canCombineForHolding( pickupActor, byActor.heldItem ) then
			sfxm( 'lift' )
			world.pickedUp = true

			if byActor.heldItem ~= nil then
				combineResources( byActor.heldItem, pickupActor )
			else
				makeHeld( pickupActor, world.player )
				byActor.heldItem = pickupActor
			end

			return pickupActor
		else
			return nil
		end
	end

	local item = tryArmLength( DEFAULT_ARM_LENGTH )
	if item == nil then
		return tryArmLength( 0 )
	end
	return item
end

function tryPickupBlock( byActor )

	function tryArmLength( armLength )
		local blockX, blockY = blockToPickup( byActor, armLength )
		if blockX ~= nil then
			-- place in inventory
			local creationPos = vec2:new( blockX, blockY ) * PIXELS_PER_TILE

			local blockIndex = mget( blockX, blockY )
			local pickupActor = createActorForBlockIndex( blockIndex, creationPos.x, creationPos.y )

			if pickupActor and ( byActor.heldItem == nil or canCombineForHolding( pickupActor, byActor.heldItem )) then

				createActor( 'pickup_particles', blockX * PIXELS_PER_TILE + 8, blockY * PIXELS_PER_TILE + 16 )
				sfxm( 'lift' )
				world.pickedUp = true

				if byActor.heldItem ~= nil then
					combineResources( byActor.heldItem, pickupActor )
				else
					makeHeld( pickupActor, world.player )
					pickupActor.pos = creationPos + actorULOffset( pickupActor )
					byActor.heldItem = pickupActor
				end

				clearBlock( blockX, blockY )

				return pickupActor
			else
				if pickupActor then
					deleteActor( pickupActor )
				end
				return nil
			end
		end
		return nil
	end

	local item = tryArmLength( DEFAULT_ARM_LENGTH )
	if item == nil then
		return tryArmLength( 0 )
	end
	return item
end

function onButton1()
	-- Pickup, prefering actor.
	if tryPickupActor( world.player ) == nil then
		if tryPickupBlock( world.player ) == nil then

			-- Couldn't pickup. Drop?
			if world.player.heldItem ~= nil then
				tryDropHeldItem()
			end
		end
	end
end

function onButton2()
	-- try to drop.
	if world.player.heldItem ~= nil then
		tryDropHeldItem( { preferDropAll = true } ) -- forcing drop
	else
		-- -- Pickup, prefering block.
		-- if tryPickupBlock( world.player ) == nil then
		-- 	tryPickupActor( world.player )
		-- end
	end
end

function updateInput( actor )

	local thrust = vec2:new()

	-- Update button thrust

	if btn( 0 ) then
		world.moved = true
		thrust.x = thrust.x - 1
		physicalButtonsPressed = true
		showControlsGuides( false )
	end

	if btn( 1 ) then
		world.moved = true
		thrust.x = thrust.x + 1
		physicalButtonsPressed = true
		showControlsGuides( false )
	end

	if btn( 2 ) then
		world.moved = true
		thrust.y = thrust.y - 1
		physicalButtonsPressed = true
		showControlsGuides( false )
	end

	if btn( 3 ) then
		world.moved = true
		thrust.y = thrust.y + 1
		physicalButtonsPressed = true
		showControlsGuides( false )
	end

	thrust = thrust:normal()

	-- Update joystick thrust
	local joyThrust = vec2:new( joy( 0 ), joy( 1 ))

	if joyThrust:lengthSquared() > 0.1 then
		world.moved = true
	end

	thrust = thrust + joyThrust

	if thrust:lengthSquared() > 1.0 then
		thrust = thrust:normal()
	end

	actorControlThrust( actor, thrust * actor.config.maxThrust )

	-- Update other buttons

	if btnp( 4 ) then
		onButton1()
	end
	if btnp( 5 ) then
		onButton2()
	end

	if world.moved and world.pickedUp and world.dropped and not world.completedControls then
		world.completedControls = true
		showControlsGuides( false )
	end
end

function updateViewTransform()
	local viewOffset = vec2:new( screen_wid() / 2, screen_hgt() / 2 )

	viewOffset.y = screen_hgt() / 2

	-- local desiredViewPoint = ( world.player.pos - vec2:new( 0, 10 ) ) - viewOffset + world.player.vel * 32

	-- if viewPoint == nil then viewPoint = desiredViewPoint end
	-- viewPoint = lerp( viewPoint, desiredViewPoint, 0.05 )

	local viewPoint = ( world.player.pos - vec2:new( 0, 10 ) ) - viewOffset

	setWorldView( viewPoint.x, viewPoint.y )
end

function updateShadow( actor )
	if actor.shadowHost == nil then return end
	actor.pos:set( actor.shadowHost.pos )
end

function drawShadow( actor )
	local outerRadius = math.min( actor.shadowHost.config.dims.x, actor.shadowHost.config.dims.y ) * 0.5
	local innerRadius = outerRadius * 0.75
	fillp( ~0x8421 )
	circ( actor.pos.x, actor.pos.y, outerRadius, 0xFF000000, outerRadius - innerRadius )

	fillp( 0xA5A5 )
	circfill( actor.pos.x, actor.pos.y, innerRadius, 0xFF000000 )
	fillp( 0 )
end

function updateHeldItem( holder, item )
	actorSnapTo( item, lerp( item.pos, holder.pos + vec2:new( 0, 1 + math.sin( ticks * 0.06 ) * 1.5 ), 0.08 ))
	item.z = lerp( item.z or 0, 16, 0.08 )
end

function updatePlayer( actor )
	if world.player.heldItem then
		updateHeldItem( world.player, world.player.heldItem )
	end
end

-- Combining rules are complex. They differ between two items that have never been picked up vs when at least
-- one has, and for situations where one item is on the ground and one is held.
-- They must always, of course, be the same type.
--
-- Both on the ground (including immediately after a block or world.player drop):
-- 	If neither has ever been held:
--		They can combine regardless, maxing at 9. The rest is swallowd--destroyed.
-- 	If at least one has been held:
--		They combine, but not maxing at 9: any remaining is kept in the second object.
-- If one is held, with Z key:
--		If they combine under the limit:
--			The ground one is picked up into the held one.
--		Else:
--			The held one drops a single count, possibly combining on the ground.
-- If one is held, with X key:
-- 		All are dropped. They will combine as if on ground (because they will be).


function canCombineBecauseCorrectTypes( a, b )
	assert( a and b )
	return a.configKey == b.configKey
		   and a.config.mayCombine
		   and b.config.mayCombine
end

function canCombineBecauseUnderLimit( a, b )
	return ( a.count or 1 ) + ( b.count or 1 ) <= RESOURCE_MAX_COUNT_DEFAULT
end

function canCombineOnGround( a, b )
	assert( a and b )
	return a.holder == nil and b.holder == nil
		   and canCombineBecauseCorrectTypes( a, b )
end

function canCombineForHolding( a, b )
	return canCombineBecauseCorrectTypes( a, b )
			and canCombineBecauseUnderLimit( a, b )
end

function combineResources( a, b )
	assert( a.configKey == b.configKey )

	local total = ( a.count or 1 ) + ( b.count or 1 )

	a.count = math.min( total, RESOURCE_MAX_COUNT_DEFAULT )

	local remaining = total - a.count
	if remaining == 0 then
		deleteActor( b )
	else
		b.count = remaining
	end
end

function onResourcesCollide( a, b )
	if canCombineOnGround( a, b ) then
		actorSnapTo( a, b.pos )
		combineResources( a, b )
	end
end

function wouldNewItemBeSwallowedNear( position, newActorType, itemsToAdd )
	itemsToAdd = itemsToAdd or 1

	assert( position and newActorType )
	local actorThere = closestActorTo( position.x, position.y, 8, function( actor )
		return actor.holder == nil and actor.configKey == newActorType
	end)

	return actorThere ~= nil and ((( actorThere.count or 1 ) + itemsToAdd > RESOURCE_MAX_COUNT_DEFAULT )
			  and actorThere.pos:equals( position ))
end

ROBOT_TIME_TO_LOSE_FUEL_FROM_ONE_WOOD_SECONDS = 9.5
FUEL_LOSS_PER_TICK = 1
FUEL_LOSS_PER_SECOND = FUEL_LOSS_PER_TICK * 60
ROBOT_FUEL_PER_WOOD = FUEL_LOSS_PER_SECOND * ROBOT_TIME_TO_LOSE_FUEL_FROM_ONE_WOOD_SECONDS
ROBOT_MAX_FUEL = ROBOT_FUEL_PER_WOOD * 9
ROBOT_INITIAL_FUEL = FUEL_LOSS_PER_SECOND * 60 * 1.5
MAX_FUEL_FOR_NEEDINESS = FUEL_LOSS_PER_SECOND * 30
MIN_FUEL_FOR_MAX_NEEDINESS_DISPLAY = FUEL_LOSS_PER_SECOND * 4
MIN_FUEL_FOR_MAX_GUAGE_FLICKER = MIN_FUEL_FOR_MAX_NEEDINESS_DISPLAY + FUEL_LOSS_PER_SECOND * 6

function onRobotOutOfFuel( actor )
	if not world.gameLost then
		world.gameLost = true
		world.gameOverStartTime = realTicks
		color_multiplied_g = 0
		color_multiplied_b = 0
		musicm( '' )
		sfxm( 'fail' )
	end
end

function onRobotCompletedAllRecipes()
	if not world.gameWon then
		world.gameWon = true
		world.gameOverStartTime = realTicks
		world.finalGameTicks = ticks
		sfxm( 'win', 0.75 )
		musicm( '' )
	end
end

function robotTick( actor )
	if world.robotFound and not world.robotDialoguing then
		actor.fuel = actor.fuel ~= nil and actor.fuel or actor.config.fuel
		actor.fuel = actor.fuel - FUEL_LOSS_PER_TICK

		local fuelNeediness = clamp( proportion( actor.fuel, MAX_FUEL_FOR_NEEDINESS, MIN_FUEL_FOR_MAX_NEEDINESS_DISPLAY ), 0, 1 ) ^ 2

		-- trace( actor.fuel .. ' ' .. fuelNeediness)

		chromatic_aberration_ = lerp( DEFAULT_CHROMATIC_ABERRATION, 1.0, fuelNeediness )
		barrel_ = 				lerp( DEFAULT_BARREL, 				0.7, fuelNeediness )
		bloom_intensity_ = 		lerp( DEFAULT_BLOOM_INTENSITY, 		0.2, fuelNeediness )
		burn_in_ =		 		lerp( DEFAULT_BURN_IN,		 		0.5, fuelNeediness )

		local fuelDesperation = clamp( proportion( actor.fuel, MIN_FUEL_FOR_MAX_NEEDINESS_DISPLAY, 0 ), 0, 1 )
		color_multiplied_g = lerp( 1.0, 0.5, fuelDesperation )
		color_multiplied_b = lerp( 1.0, 0.5, fuelDesperation )

		if actor.fuel <= 0 then
			actor.fuel = 0
			onRobotOutOfFuel( actor )
		end
	end
end

function playerFootstepFrames( start )
	local frames = {}
	for i = 1, 7 do
		frames[ i ] = {
			frame = start + i,
			event = ( i == 1 or i == 5 ) and function( actor )
				sfxm( 'footstep' .. randInt( 1, 3 ), 0.25 )
			end
				or nil
		}
	end
	return frames
end

function selfDeletingAnimFrames( start, count, step )
	step = step or 1

	local frames = {}

	for i = 0, count - 1 do
		frames[ i ] = {
			frame = i * step + start,
			event = i + 1 == count and function( actor )
				deleteActor( actor )
			end
				or nil
		}
	end

	return frames
end

ACTOR_CONFIGS = {
	player = {
		dims = vec2:new( 7, 13 ),
		maxThrust = 0.35,
		ulOffset = vec2:new( 8, 15 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle_south = { speed = 0, frames = { 1 }},
			run_south =  { speed = 0.4, frames = playerFootstepFrames( 2 )},
			idle_north = { speed = 0, frames = { 33 }},
			run_north =  { speed = 0.4, frames = playerFootstepFrames( 34 )},
			idle_side = { speed = 0, frames = { 65 }},
			run_side = { speed = 0.4, frames = playerFootstepFrames( 66 ) },
		},
		amendAnimName = function( self, animName )
			if self.heading:majorAxis() == 0 then return animName .. '_side' end

			return animName .. '_' .. ( self.heading.y < 0 and 'north' or 'south' )
		end,
		tick = updatePlayer,
	},
	shadow = {
		dims = vec2:new( 0, 0 ),
		ulOffset = vec2:new( 0, 8 ),
		tileSizeX = 1,
		tileSizeY = 1,
		nonColliding = true,
		inert = false,
		tick = updateShadow,
		draw = drawShadow,
	},
	robot = {
		tick = robotTick,
		dims = vec2:new( 24, 26 ),
		ulOffset = vec2:new( 16, 34 ),
		nonColliding = true,
		fadeForPlayer = true,
		tileSizeX = 2,
		tileSizeY = 2,
		animations = {
			idle = { speed = 0.1, frames = { 10, 12, 14 }},
		},
	},
	tree = {
		inert = true,
		nonColliding = true,
		fadeForPlayer = true,
		dims = vec2:new( 18, 56 ),
		ulOffset = vec2:new( 16, 64 ),
		tileSizeX = 2,
		tileSizeY = 4,
		animations = {
			idle_3 = { speed = 0, frames = { 544 }},
			idle_2 = { speed = 0, frames = { 546 }},
			idle_1 = { speed = 0, frames = { 548 }},
			idle_0 = { speed = 0, frames = { 548 }},
		},
		onCapacityChange = function( actor, x, y, capacity )
			actor.capacity = capacity
		end,
		amendAnimName = function( self, animName )
			local proportionalCapacity = clamp( proportion( self.capacity, 0, BLOCK_CONFIGS.tree_base.defaultCapacity ), 0, 1 )
			local fullness = math.floor( round( lerp( 0, 3, proportionalCapacity )))

			return animName .. '_' .. fullness
		end,
	},
	tree_rubber = {
		inert = true,
		nonColliding = true,
		fadeForPlayer = true,
		dims = vec2:new( 30, 43 ),
		ulOffset = vec2:new( 24, 48 ),
		tileSizeX = 3,
		tileSizeY = 3,
		animations = {
			idle = { speed = 0, frames = { 322 }},
		},
	},
	placement_poof = {
		inert = true,
		nonColliding = true,
		ulOffset = vec2:new( 16, 0 ),
		tileSizeX = 3,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0.25, frames = selfDeletingAnimFrames( 224, 8, 3 ) },
		},
	},
	pickup_particles = {
		inert = true,
		nonColliding = true,
		ulOffset = vec2:new( 8, 16 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0.35, frames = selfDeletingAnimFrames( 128, 15 ) },
		},
	},
	produce_particles = {
		inert = true,
		nonColliding = true,
		ulOffset = vec2:new( 0, 0 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0.35, frames = selfDeletingAnimFrames( 176, 9 ) },
		},
	},
	consume_particles = {
		inert = true,
		nonColliding = true,
		ulOffset = vec2:new( 0, 0 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0.35, frames = selfDeletingAnimFrames( 208, 7 ) },
		},
	},
	conveyor = {
		mayBePickedUp = true,
		mayCombine = true,
		fadeForPlayer = true,
		convertToBlockWhenPossible = true,
		blockPlacementType = { 261, 261+32, 261+32*2, 261+32*3 } ,
		dims = vec2:new( 16, 16 ),
		ulOffset = vec2:new( 8, 16 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 261 }},
			idle_north = { speed = 0, frames = { 261 }},
			idle_east = { speed = 0, frames = { 261+32 }},
			idle_south = { speed = 0, frames = { 261+32*2 }},
			idle_west = { speed = 0, frames = { 261+32*3 }},
		},
		amendAnimName = function( actor, animName )
			if actor.holder and actor.holder.heading then
				return animName .. '_' .. headingToDirectionName( actor.holder.heading:cardinalDirection() )
			end
			return animName
		end
	},
	oven = {
		mayBePickedUp = true,
		mayCombine = true,
		fadeForPlayer = true,
		convertToBlockWhenPossible = true,
		blockPlacementType = { 512, 512, 512, 512 } ,
		dims = vec2:new( 16, 16 ),
		ulOffset = vec2:new( 8, 16 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 512 }},
		},
	},
	combiner = {
		mayBePickedUp = true,
		mayCombine = true,
		fadeForPlayer = true,
		convertToBlockWhenPossible = true,
		blockPlacementType = { 515, 515, 515, 515 } ,
		dims = vec2:new( 16, 16 ),
		ulOffset = vec2:new( 8, 16 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 515 }},
		},
	},
	sensor = {
		mayBePickedUp = true,
		mayCombine = true,
		fadeForPlayer = true,
		convertToBlockWhenPossible = true,
		blockPlacementType = { 517, 517, 517, 517 },
		dims = vec2:new( 16, 16 ),
		ulOffset = vec2:new( 8, 16 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 521 }},
		},
	},
	harvester = {
		mayBePickedUp = true,
		mayCombine = true,
		fadeForPlayer = true,
		convertToBlockWhenPossible = true,
		blockPlacementType = { 519, 519, 519, 519 } ,
		dims = vec2:new( 16, 16 ),
		ulOffset = vec2:new( 8, 16 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 522 }},
		},
	},

	-- RESOURCES
	iron_ore = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 7, 7 ),
		ulOffset = vec2:new( 8, 11 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 192 }},
		},
	},
	iron = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 9, 8 ),
		ulOffset = vec2:new( 9, 11 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 193 }},
		},
	},
	copper = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 9, 8 ),
		ulOffset = vec2:new( 9, 11 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 194 }},
		},
	},
	gold_ore = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 7, 7 ),
		ulOffset = vec2:new( 8, 11 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 195 }},
		},
	},
	gold = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 9, 8 ),
		ulOffset = vec2:new( 9, 11 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 196 }},
		},
	},
	wood = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 11, 6 ),
		ulOffset = vec2:new( 8, 11 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 197 }},
		},
	},
	rubber = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 7,6 ),
		ulOffset = vec2:new( 8, 10 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 198 }},
		},
	},
	stone = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 8,11 ),
		ulOffset = vec2:new( 9, 10 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0, frames = { 199 }},
		},
	},
	chip = {
		mayBePickedUp = true,
		mayCombine = true,
		dims = vec2:new( 10, 8 ),
		ulOffset = vec2:new( 9, 12 ),
		tileSizeX = 1,
		tileSizeY = 1,
		animations = {
			idle = { speed = 0.1, frames = { 200, 201 }},
		},
	},
}

function createShadowForActor( actor )
	actor.shadow = createActor( 'shadow', actor.pos.x, actor.pos.y )
	actor.shadow.shadowHost = actor
end

function actorMemento( actor )
	local memento = tableCopy( actor )
	memento.config = nil
	return memento
end

function deleteActor( actor )
	assert( actor ~= nil )

	if actor.deleted then return end

	if actor.shadow ~= nil then
		actor.shadow.shadowHost = nil
		deleteActor( actor.shadow )
	end

	actor.deleted = true
	-- trace( 'deleted actor ' .. actor.configKey )

	tableRemoveValue( world.actors, actor )
end

function createActor( configKey, x, y )
	local config = ACTOR_CONFIGS[ configKey ]
	assert( config )

	local actor = {
		configKey = configKey,
		config = config,
		birthTicks = ticks,
		birthdate = now(),
		pos = vec2:new( x, y ),
		lastPos = vec2:new( x, y ),
		vel = vec2:new( 0, 0 ),
		thrust = vec2:new( 0, 0 ),
		heading = vec2:new( 0, 1 ),
		animFrame = 0,
		lastFrame = 0,
		occluding = false,
		occlusionOpacity = 1.0
	}

	table.insert( world.actors, actor )

	-- trace( 'actors ' .. #world.actors)

	return actor
end

function effectiveVelocity( actor )
	return actor.pos - actor.lastPos
end

function speed( actor )
	return actor.vel:length()
end

function actorPlacementBlock( actor, placementDirectionCardinal )
	if type( actor.config.blockPlacementType ) == 'number' then
		return actor.config.blockPlacementType
	elseif actor.config.blockPlacementType == nil then
		return nil
	else
		return actor.config.blockPlacementType[ placementDirectionCardinal + 1 ]
	end
end

function onFrameChanged( actor )
	local animation = currentAnimation( actor )
	if animation ~= nil then

		-- call event if it's there.

		local frames = animation.frames
		local frameIndex = math.floor( actor.animFrame ) % #frames
		local frame = frames[ frameIndex + 1 ]

		if type( frame ) == 'table' then
			if frame.event ~= nil then
				frame.event( actor )
			end
		end
	end
end

function actorSetFrame( actor, frame )
	actor.animFrame = frame

	if math.floor( actor.animFrame ) ~= math.floor( actor.lastFrame ) then
		onFrameChanged( actor )
		actor.lastFrame = actor.animFrame
	end
end

function currentAnimation( actor )
	local animations = actor.config.animations

	if animations == nil then return nil end

	local anim = ( math.abs( actor.thrust:length() ) > 0.1 ) and 'run' or 'idle'

	if actor.config.amendAnimName ~= nil then
		anim = actor.config.amendAnimName( actor, anim )
	end

	return animations[ anim ]
end

function actorOccludingBounds( actor )
	return {
		left = actor.pos.x - actor.config.dims.x / 2,
		top =  actor.pos.y - actor.config.dims.y,
		right = actor.pos.x + actor.config.dims.x / 2,
		bottom = actor.pos.y,
	}
end

function actorBounds( actor )
	local foot = actor.pos

	return {
		left = foot.x - actor.config.dims.x / 2,
		top = foot.y - actor.config.dims.y,
		right = foot.x + actor.config.dims.x / 2,
		bottom = foot.y,
	}
end

function actorVisualBounds( actor )
	local ul = actor.pos - actorULOffset( actor )

	local wid = actor.config.tileSizeX * PIXELS_PER_TILE
	local hgt = actor.config.tileSizeY * PIXELS_PER_TILE

	return {
		left = ul.x,
		top = ul.y,
		right = ul.x + wid,
		bottom = ul.y + hgt,
	}
end

function frameSpriteIndex( frame )
	return ( type( frame ) == 'table' and frame.frame ) or frame
end

function actorColor( actor )
	return actor.flickerColor or 0xFFFFFFFF
end

function floatTermsToColor( r, g, b )

	function term( x )
		return math.floor( x * 0xFF )
	end

	return 0xFF000000 | ( term( r ) << 16 ) | ( term( g ) << 8 ) | term( b )
end

function colorToFloatTerms( color )
	local r = ( color & 0x00FF0000 ) >> 16
	local g = ( color & 0x0000FF00 ) >> 8
	local b = ( color & 0x000000FF ) >> 0

	function term( x )
		return x / 0xFF
	end

	return term( r ), term( g ), term( b )
end

function colorLerp( a, b, alpha )
	local ar, ag, ab = colorToFloatTerms( a )
	local br, bg, bb = colorToFloatTerms( b )

	return floatTermsToColor( lerp( ar, br, alpha ), lerp( ag, bg, alpha ), lerp( ab, bb, alpha ) )
end

function actorAdditiveColor( actor )
	return actor.additiveColor or 0x00000000
end

function updateAnimation( actor )

	if actor.animPlaying ~= nil and not actor.animPlaying then return end

	local animation = currentAnimation( actor )
	if animation ~= nil then
		local frameStep = animation.speed
		if animation.velScalar ~= nil then
			frameStep = animation.speed + animation.velScalar * speed( actor )
		end
		actorSetFrame( actor, actor.animFrame + frameStep )
	end

	if animation ~= actor.lastAnimation then
		actor.lastAnimation = animation
		if not animation.keepFrame then
			actor.animFrame = 0
		end
	end
end

function actorOccludesPlayer( actor )
	if world.player.pos.y > actor.pos.y then return false end

	local myBounds = actorOccludingBounds( actor )
	local playerBounds = expandContractRect( actorOccludingBounds( world.player ), 0 )

	return rectsOverlap( myBounds, playerBounds )
end

function bitPatternForAlpha( alpha )
	local iAlpha = math.floor( alpha * 16 )
	local pattern = 0

	local bit = 1
	for i = 0, iAlpha do
		pattern = pattern | bit
		bit = ( bit << 7 ) % 0xFFFF
	end

	return ~pattern
end

function actorOpacityForDither( actor )
	return actor.occlusionOpacity or 1.0
end

function actorULOffset( actor )
	local offset = actor.ulOffset or actor.config.ulOffset
	assert( offset )

	local z = actor.z or 0
	return offset + vec2:new( 0, z )
end

function drawCount( count, x, y )
	printShadowed( '' .. count, math.floor( x ), math.floor( y ), YELLOW, 3 )
end

function drawActorCount( actor )
	if actor.count ~= nil and actor.count > 1 then
		local actorBounds = actorVisualBounds( actor )
		local countPos = vec2:new( actorBounds.right - 4, actorBounds.top )
		drawCount( actor.count, countPos.x, countPos.y )
	end
end

function drawActor( actor )
	if actor.config.draw ~= nil then
		local abortDraw = actor.config.draw( actor )
		if abortDraw then return end
	end

	local animation = currentAnimation( actor )
	if animation == nil then return end

	local frames = animation.frames

	local cur_frame = math.floor( actor.animFrame ) % #frames

	local sprite = frameSpriteIndex( frames[ cur_frame + 1 ] )

	fillp( bitPatternForAlpha( actorOpacityForDither( actor ) ))

	local flipX = actor.heading:majorAxis() == 0 and actor.heading.x > 0

	local ulOffset = actorULOffset( actor )

	spr( sprite,
		math.floor( actor.pos.x - ulOffset.x ),
		math.floor( actor.pos.y - ulOffset.y ),
		actor.config.tileSizeX,
		actor.config.tileSizeY,
		flipX,
		false,
		actorColor( actor ),
		actorAdditiveColor( actor )
	)

	fillp( 0 )

	drawActorCount( actor )
end

-- UPDATE

function actorMayCollideWith( actor, other )
	if actor.config.nonColliding then return false end
	return true
end

function actorOnCollide( actor, other )

	-- add to colliding actors if it's not there already
	if actor.collidingActors ~= nil and actor.collidingActors[ other ] == nil then
		actor.collidingActors[ other ] = true
		if actor.config.onActorCollisionStart ~= nil then
			actor.config.onActorCollisionStart( actor, other )
		end
	end

	-- call the continual callback
	if actor.config.onActorCollide ~= nil then
		actor.config.onActorCollide( actor, other )
	end
end

function actOnNotCollide( actor, other )
	if actor.collidingActors ~= nil and actor.collidingActors[ other ] ~= nil then
		actor.collidingActors[ other ] = nil
		if actor.config.onActorCollisionEnd ~= nil then
			actor.config.onActorCollisionEnd( actor, other )
		end
	end
end

function collideActorPair( actorA, actorB )
	if not( actorMayCollideWith( actorA, actorB ) or actorMayCollideWith( actorB, actorA ) ) then
		return
	end

	local boundsA = actorBounds( actorA )
	local boundsB = actorBounds( actorB )

	if rectsOverlap( boundsA, boundsB ) then
		actorOnCollide( actorA, actorB )
		actorOnCollide( actorB, actorA )
	else
		actOnNotCollide( actorA, actorB )
		actOnNotCollide( actorB, actorA )
	end
end

function eachNearbyActorToPos( pos, radius, callback )
	local tileX = worldToTile( pos.x )
	local tileY = worldToTile( pos.y )

	local radiusSquared = radius * radius

	local radiusInTiles = math.max( 1, radius / PIXELS_PER_TILE )
	for y = tileY - radiusInTiles, tileY + radiusInTiles do
		for x = tileX - radiusInTiles, tileX + radiusInTiles do
			forEachActorOnBlock( x, y, function( tileActor )
				if ( tileActor.pos - pos ):lengthSquared() <= radiusSquared then
					callback( tileActor )
				end
			end)
		end
	end
end

function eachNearbyActorToActor( actor, radius, callback )
	return eachNearbyActorToPos( actor.pos, radius, function( otherActor )
		if otherActor ~= actor then
			callback( otherActor )
		end
	end)
end

function collideActors()

	for i, actor in ipairs( world.actors ) do
		if actor ~= world.player then
			collideActorPair( world.player, actor )
		end
	end
end

function collideActorWithTile( actor, tileX, tileY )
	local bounds = actorBounds( actor )

	local tileSprite = mget( tileX, tileY )

	local tileCollides = fget( tileSprite, 1 ) ~= 0

	if tileCollides then

		local vel = effectiveVelocity( actor )

		local colliding, normalX, normalY, hitAxis, adjustmentDistance = table.unpack( rect_collision_adjustment(
			bounds.left, bounds.top, bounds.right, bounds.bottom,
			tileX * PIXELS_PER_TILE, tileY * PIXELS_PER_TILE, ( tileX + 1 ) * PIXELS_PER_TILE, ( tileY + 1 ) * PIXELS_PER_TILE,
			vel.x, vel.y ))

		if colliding then
			local adjustment = vec2:new( normalX * adjustmentDistance, normalY * adjustmentDistance )
			actor.pos = actor.pos + adjustment
			if( hitAxis == 0 ) then
				actor.vel.x = 0
			else
				actor.vel.y = 0
			end
		end

		return colliding
	end
	return false
end

function collideActorWithTerrain( actor )
	if actor.config.nonColliding then return end

	local bounds = actorBounds( actor )

	local startX = worldToTile( bounds.left )
	local endX = worldToTile( bounds.right )
	local startY = worldToTile( bounds.top )
	local endY = worldToTile( bounds.bottom )

	local vel = effectiveVelocity( actor )

	local stepX = signNoZero( vel.x )
	local stepY = signNoZero( vel.y )

	if stepX < 0 then
		startX, endX = endX, startX
	end

	if stepY < 0 then
		startY, endY = endY, startY
	end

	for y = startY, endY, stepY do
		for x = startX, endX, stepX do
			collided = collideActorWithTile( actor, x, y )
			if collided then return true end
		end
	end

	return false
end


function actorCheckSurroundingTilesForNearbyActors( actor, radius )
	eachNearbyActorToActor( actor, radius, function( otherActor )
		onResourcesCollide( actor, otherActor )
	end)
end

function hasBeenPlayerHeld( actor )
	return actor.wasEverHeld or false
end

function actorHasMovedSincePlayerPlaced( actor )
	return actor.lastPlayerPlacedPos == nil or not actor.pos:equals( actor.lastPlayerPlacedPos )
end

function updateActor( actor )

	if actor.additiveColor ~= nil then
		actor.additiveColor = colorLerp( actor.additiveColor, 0, 0.08 )
	end

	if not actor.inert and ( actor.config.inert == nil or not actor.config.inert ) then

		if actor.config.tick ~= nil then
			actor.config.tick( actor )
		end

		actor.lastPos:set( actor.pos )

		actor.vel = actor.vel - actor.vel * GLOBAL_DRAG
		actor.pos = actor.pos + actor.vel

		if actor.mayCollideWithTerrain then
			for i = 1, 4 do
				local collided = collideActorWithTerrain( actor )
				if not collided then break end
			end
		end

		actorCheckSurroundingTilesForNearbyActors( actor, 10 )

		if actor.config.convertToBlockWhenPossible
			and (( actor.count or 1 ) == 1
			or actorHasMovedSincePlayerPlaced( actor ) )
			then
			tryPlaceAsBlock( actor, effectiveVelocity( actor ):cardinalDirection(), actor.pos )
		end
	end

	updateAnimation( actor )
end

function updateActorsOnBlocks()
	world.blocksToActors = {}

	for _, actor in ipairs( world.actors ) do
		local actorTileX = worldToTile( actor.pos.x )
		local actorTileY = worldToTile( actor.pos.y )

		local tileIndex = worldTilePosToIndex( actorTileX, actorTileY )

		if world.blocksToActors[ tileIndex ] == nil then world.blocksToActors[ tileIndex ] = {} end

		table.insert( world.blocksToActors[ tileIndex ], actor )
	end
end

function updateActors()

	for _, actor in ipairs( world.actors ) do
		if not actor.deleted then
			updateActor( actor )
		end
	end

	-- collideActors()

	-- clamp the player to the world
	world.player.pos.x = clamp( world.player.pos.x, 16, WORLD_SIZE_PIXELS - 16 )
	world.player.pos.y = clamp( world.player.pos.y, 16, WORLD_SIZE_PIXELS - 16 )
end

BLOCK_ANIM_SETS = {
	{ speed = 2, frames = range( 261, 264 ) },
	{ speed = 2, frames = range( 265, 268 ) },
	{ speed = 2, frames = range( 293, 293+3 ) },
	{ speed = 2, frames = range( 297, 297+3 ) },
	{ speed = 2, frames = range( 325, 325+3 ) },
	{ speed = 2, frames = range( 329, 329+3 ) },
	{ speed = 2, frames = range( 357, 357+3 ) },
	{ speed = 2, frames = range( 361, 361+3 ) },

	{ speed = 6, frames = range( 513, 514 ) },
	{ speed = 6, frames = range( 519, 520 ) },
}

function worldTilePosToIndex( x, y )
	return x + y * WORLD_SIZE_TILES
end

function forEachActorOnBlock( x, y, callback )
	local tileIndex = worldTilePosToIndex( x, y )
	local actors = world.blocksToActors[ tileIndex ]
	if actors then
		for _, actor in ipairs( actors ) do
			if not actor.config.inert then
				callback( actor )
			end
		end
	end
end

CONVEYOR_FORCE = 0.106

function conveyorTick( x, y, blockType, blockTypeIndex )
	local direction = blockType.conveyor.direction
	forEachActorOnBlock( x, y, function( actor )
		actorConveyorForce( actor, direction * CONVEYOR_FORCE )
	end)
end

function withBlockTypeAt( x, y, callback )
	local blockType, blockTypeIndex = blockTypeAt( x, y )
	if blockType == nil then return nil end

	return callback( blockType, blockTypeIndex )
end

function blockAbuttingSouthVersion( blockTypeIndex, southIsConveyor )
	local baseType = baseBlockTypeIndex( blockTypeIndex )

	if southIsConveyor then
		return baseType + 4
	else
		return baseType
	end
end

function blockPickupVersion( blockTypeIndex )
	return blockTypeForIndex( blockTypeIndex )
end

function conveyorOnPlaced( x, y, blockType, blockTypeIndex )
	withBlockTypeAt( x, y + 1, function( southernBlockType, southernBlockTypeIndex )
		withBaseBlockType( southernBlockTypeIndex, function( southernBlockTypeBase, southernBaseBlockTypeIndex )
			local desiredIndex = blockAbuttingSouthVersion( blockTypeIndex, southernBlockTypeBase and southernBlockTypeBase.conveyor ~= nil )
			setBlockTypeSimple( x, y, desiredIndex )
		end)
	end)
end

function amendedObject( object, callback )
	local amended = tableCopy( object )
	callback( amended )
	return amended
end

function tileCenterToWorldPos( x, y )
	return ( vec2:new( x, y ) + vec2:new( 0.5, 0.5 )) * PIXELS_PER_TILE
end

function ingredientCount( list, configKey )
	for _, item in ipairs( list ) do
		if item[ 1 ] == configKey then return item[ 2 ] end
	end
	return 0
end

function consumeActor( actor )
	actorCountAdd( actor, -1 )
end

function blockStartRecipe( x, y, blockType, blockTypeIndex, recipe, availableIngredients )
	-- consume ingredients
	for key, count in pairs( recipe.inputs ) do
		for _, actor in ipairs( availableIngredients[ key ] ) do
			if count <= 0 then break end
			consumeActor( actor )
			count = count - 1
		end
	end

	createActor( 'consume_particles', x * PIXELS_PER_TILE, y * PIXELS_PER_TILE )
	sfxm( 'consume', 0.5 )

	-- cook
	local data = dataForBlockAt( x, y )
	data.doneTick = ticks + recipe.duration * 60
	data.recipe = recipe

	setBlockType( x, y, blockType.on_version )
end

function creationPositionFromBlockAt( x, y )
	return tileCenterToWorldPos( x, y ) + vec2:new( 0, 14 )
end

function blockCompleteRecipe( x, y, blockType, blockTypeIndex )

	local data = dataForBlockAt( x, y )
	local recipe = data.recipe
	if recipe == nil then return end

	local creationPosition = creationPositionFromBlockAt( x, y )

	if recipe.output then
		createActor( 'produce_particles', x * PIXELS_PER_TILE, y * PIXELS_PER_TILE )

		for key, count in pairs( recipe.output ) do
			for i = 1, count do
				local actor = createActor( key, creationPosition.x, creationPosition.y )
			end
		end
	end

	if recipe.effect then
		recipe.effect( x, y, blockType, blockTypeIndex )
	end
end

function blockUpdateCooking( x, y, blockType, blockTypeIndex )
	local data = dataForBlockAt( x, y )
	if data == nil then return end

	local doneTick = data.doneTick or ticks
	if ticks >= doneTick then
		blockCompleteRecipe( x, y, blockType, blockTypeIndex )
		setBlockType( x, y, blockType.off_version )
	end
end

function blockCheckRecipes( x, y, blockType, blockTypeIndex )
	local recipes = blockType.recipes
	if recipes == nil or #recipes == 0 then return end

	local availableIngredients = {}

	eachNearbyActorToPos( tileCenterToWorldPos( x, y ), 16, function( actor )
		if actor.holder == nil then
			if availableIngredients[ actor.configKey ] == nil then
				availableIngredients[ actor.configKey ] = {}
			end
			-- insert the actor once for each of its counts
			for i = 1, ( actor.count or 1 ) do
				table.insert( availableIngredients[ actor.configKey ], actor )
			end
		end
	end)

	for i, recipe in ipairs( recipes ) do
		if recipe.enabled == nil or recipe.enabled then
			local satisfied = true
			for key, count in pairs( recipe.inputs ) do
				if availableIngredients[ key ] ~= nil then
					local availableCount = #availableIngredients[ key ]
					if( availableCount or 0 ) < count then
						satisfied = false
						break
					end
				else
					satisfied = false
					break
				end
			end

			if satisfied then

				-- make sure there's a place to put the output
				local creationPosition = creationPositionFromBlockAt( x, y )
				local clearToStartRecipe = true
				if recipe.output ~= nil then
					for key, count in pairs( recipe.output ) do
						if wouldNewItemBeSwallowedNear( creationPosition, key, count ) then
							clearToStartRecipe = false
							break
						end
					end
				end

				if clearToStartRecipe then
					blockStartRecipe( x, y, blockType, blockTypeIndex, recipe, availableIngredients )
				end
			end
		end
	end
end

local DEFAULT_HARVEST_RATE = 5

function onBlockRanOutOfCapacity( x, y, blockType, blockTypeIndex )
	sfxm( 'source_exhausted', 0.2 )

	color_multiplied_r_smoothed = 0.5
	color_multiplied_g_smoothed = 0.75
	color_multiplied_b_smoothed = 0.5
	barrel_smoothed = 0.3

	setBlockType( x, y, 486 )
end

function blockIsHarvestable( x, y, blockType, blockTypeIndex )
	if blockType.harvestSource == nil then return false end

	local capacity = dataForBlockAt( x, y ).capacity

	return capacity == nil or capacity > 0
end

function blockSetCapacity( x, y, capacity )
	dataForBlockAt( x, y ).capacity = capacity

	if dataForBlockAt( x, y ).sponsoredActor ~= nil and dataForBlockAt( x, y ).sponsoredActor.config.onCapacityChange then
		dataForBlockAt( x, y ).sponsoredActor.config.onCapacityChange( dataForBlockAt( x, y ).sponsoredActor, x, y, capacity )
	end
end

function blockDrainCapacity( x, y, blockType, blockTypeIndex )
	if dataForBlockAt( x, y ).capacity == nil then return end	-- nil is infinite capacity

	blockSetCapacity( x, y, dataForBlockAt( x, y ).capacity - 1 )

	if dataForBlockAt( x, y ).capacity == 0 then
		onBlockRanOutOfCapacity( x, y, blockType, blockTypeIndex )
	end
end

function harvesterDoHarvest( harvestSource, x, y, blockType, blockTypeIndex, neighborBlockTypeBase, neighborBaseBlockTypeIndex)

	blockDrainCapacity( x, y - 1, neighborBlockTypeBase, neighborBaseBlockTypeIndex )

	local creationPosition = creationPositionFromBlockAt( x, y )

	createActor( harvestSource, creationPosition.x, creationPosition.y )
	sfxm( 'produce', 0.5 )
	createActor( 'produce_particles', x * PIXELS_PER_TILE, y * PIXELS_PER_TILE )
end

function harvestRateToPctChance( rate )
	return ( 1/ rate ) * 100
end

function harvesterTick( x, y, blockType, blockTypeIndex )
	-- get the block just north.
	local canHarvest = withBlockTypeAt( x, y - 1, function( neighborBlockType, neighborBlockTypeIndex )
		return withBaseBlockType( neighborBlockTypeIndex, function( neighborBlockTypeBase, neighborBaseBlockTypeIndex )

			-- north neighbor is a harvestable block?
			if not blockIsHarvestable( x, y - 1, neighborBlockTypeBase, neighborBaseBlockTypeIndex ) then
				return false
			end

			-- would the produced actor simply be swallowed up by a group?
			local creationPosition = creationPositionFromBlockAt( x, y )
			if wouldNewItemBeSwallowedNear( creationPosition, neighborBlockTypeBase.harvestSource ) then
				return false
			end

			local harvestRate = ( neighborBlockTypeBase.harvestRate or DEFAULT_HARVEST_RATE ) * 60
			-- local harvestChancePerTick = harvestRateToPctChance( harvestRate )
			-- if pctChance( harvestChancePerTick ) then
			if ( ticks + 1 ) % harvestRate == 0 then
				harvesterDoHarvest( neighborBlockTypeBase.harvestSource, x, y, blockType, blockTypeIndex, neighborBlockTypeBase, neighborBaseBlockTypeIndex)
			end
			return true
		end)
	end)

	dataForBlockAt( x, y ).animated = canHarvest or false
end

function conveyorRotatedVersion( fromBlockTypeIndex, turnsClockwise )
	local MIN = 256
	local MAX = 256 + 32*4

	local turned = fromBlockTypeIndex + turnsClockwise * 32

	turned = MIN + ( turned - MIN ) % ( MAX - MIN )

	return turned
end

function onConveyorTriggered( x, y, blockType, blockTypeIndex, turningOn )
	if dataForBlockAt( x, y ).triggeredOn ~= turningOn then
		setBlockTypeSimple( x, y, conveyorRotatedVersion( blockTypeIndex, turningOn and 1 or -1 ))
	end
end

function sensorChanged( x, y, blockType, blockTypeIndex, turningOn )
	-- trigger or untrigger the south block
	withBlockTypeAt( x, y + 1, function( southernBlockType, southernBlockTypeIndex )
		withBaseBlockType( southernBlockTypeIndex, function( southernBlockTypeBase, southernBaseBlockTypeIndex )

			if southernBlockTypeBase.onTriggered ~= nil then
				southernBlockTypeBase.onTriggered( x, y + 1, southernBlockType, southernBlockTypeIndex, turningOn )
			end
			dataForBlockAt( x, y + 1 ).triggeredOn = turningOn
		end)
	end)
end

function sensorTick( x, y, blockType, blockTypeIndex, triggerIfSensed, toTypeIfTriggered )
	local sensedActor = nil
	forEachActorOnBlock( x, y - 1, function( actor )
		if  actor.holder == nil and
			actor ~= world.player and
			actor.shadowHost == nil and
			not actor.config.invisibleToSensors then
			sensedActor = actor
		end
	end)

	if triggerIfSensed == ( sensedActor ~= nil ) then
		sensorChanged( x, y, blockType, blockTypeIndex, triggerIfSensed )
		setBlockTypeSimple( x, y, toTypeIfTriggered )
	end
end

function sensorTickOff( x, y, blockType, blockTypeIndex )
	sensorTick( x, y, blockType, blockTypeIndex, true, blockTypeIndex + 1 )
end

function sensorTickOn( x, y, blockType, blockTypeIndex )
	sensorTick( x, y, blockType, blockTypeIndex, false, blockTypeIndex - 1 )
end

function reportIfNil( label, value )
	trace( label .. ' nil? ' .. ( value == nil and 'true' or 'false' ) )
end

local gauge = {
	flashBrightness = 1,
}

function updateFuelGuage()
	if not world.robotFound then return end

	gauge.flashBrightness = lerp( gauge.flashBrightness, 0.0, 0.1 )

	local gaugeFlashSpeed = ( world.robot.fuel <= MIN_FUEL_FOR_MAX_GUAGE_FLICKER ) and 10 or ( world.robot.fuel <= MAX_FUEL_FOR_NEEDINESS and 60 or 0 )

	if gaugeFlashSpeed > 0 and ( ticks % gaugeFlashSpeed ) == 0 then
		gauge.flashBrightness = 1
		sfxm( 'warning', 0.20 )
	end
end

function robotOnCompletedRecipe()

	local recipes = BLOCK_CONFIGS.robot_base_off.recipes

	assert( world.robot.recipeSequence ~= nil )
	assert( recipes[ world.robot.recipeSequence ] ~= nil )

	color_multiplied_r_smoothed = 1
	color_multiplied_g_smoothed = 1
	color_multiplied_b_smoothed = 0
	barrel_smoothed = 0.5

	if world.robot.recipeSequence > 1 then
		recipes[ world.robot.recipeSequence ].enabled = false
	end

	world.robot.recipeSequence = world.robot.recipeSequence + 1

	if world.robot.recipeSequence > #recipes then
		onRobotCompletedAllRecipes()
	else
		recipes[ world.robot.recipeSequence ].enabled = true
	end
end

function robotOnWood( x, y, blockType, blockTypeIndex )
	-- trace( 'robotOnWood' )
	world.robot.fuel = math.min( ROBOT_MAX_FUEL, world.robot.fuel + ROBOT_FUEL_PER_WOOD )
	gauge.flashBrightness = 1
	world.robot.additiveColor = 0xFFFFFF00

	sfxm( 'eat_wood' )

	if world.robot.recipeSequence == nil or world.robot.recipeSequence == 1 then
		world.robot.recipeSequence = 1
		robotOnCompletedRecipe()
	end
end

function robotOnIron( x, y, blockType, blockTypeIndex )
	-- trace( 'robotOnIron' )
	robotOnCompletedRecipe()
	sfxm( 'finish_robot_recipe' )
end
function robotOnConveyor( x, y, blockType, blockTypeIndex )
	-- trace( 'robotOnConveyor' )
	robotOnCompletedRecipe()
	sfxm( 'finish_robot_recipe' )
end
function robotOnSensor( x, y, blockType, blockTypeIndex )
	-- trace( 'robotOnSensor' )
	robotOnCompletedRecipe()
	sfxm( 'finish_robot_recipe' )
end
function robotOnChip( x, y, blockType, blockTypeIndex )
	-- trace( 'robotOnChip' )
	robotOnCompletedRecipe()
	sfxm( 'finish_robot_recipe' )
end

ROBOT_NAME = '@73N'

ROBOT_RECIPE_DURATION = 0

function robotBaseClass()
	return {
		name = ROBOT_NAME,
		sponsoredActorConfig = 'robot',
		drawRecipes = false,
		on_version = 290,
		recipes = {
			{
				inputs = { wood = 1 },
				effect = robotOnWood,
				duration = ROBOT_RECIPE_DURATION,
			},
			{
				enabled = false,
				inputs = { iron = 4 },
				effect = robotOnIron,
				duration = ROBOT_RECIPE_DURATION,
			},
			{
				enabled = false,
				inputs = { conveyor = 9 },
				effect = robotOnConveyor,
				duration = ROBOT_RECIPE_DURATION,
			},
			{
				enabled = false,
				inputs = { sensor = 3 },
				effect = robotOnSensor,
				duration = ROBOT_RECIPE_DURATION,
			},
			{
				enabled = false,
				inputs = { chip = 1 },
				effect = robotOnChip,
				duration = 0.65,
			},
		},
		onPlaced = function( x, y, blockType, blockTypeIndex )
			if world.robot == nil then
				world.robot = createActor( blockType.sponsoredActorConfig, ( x + 0.5 ) * PIXELS_PER_TILE + 22, ( y + 1 ) * PIXELS_PER_TILE - 1 )
				world.robot.baseBlockPos = vec2:new( x, y )
				world.robot.fuel = ROBOT_INITIAL_FUEL
			end
		end,
		tick = function( x, y, blockType, blockTypeIndex )
			blockCheckRecipes( x, y, blockType, blockTypeIndex )
		end,
	}
end

function dataForBlockAt( x, y )
	local index = worldTilePosToIndex( x, y )
	if world.blockData[ index ] == nil then world.blockData[ index ] = {} end
	return world.blockData[ index ]
end

function clearDataForBlockAt( x, y )
	local index = worldTilePosToIndex( x, y )
	world.blockData[ index ] = {}
end

function blockCreateSponsored( x, y, blockType, blockTypeIndex )
	if dataForBlockAt( x, y ).sponsoredActor ~= nil then return dataForBlockAt( x, y ).sponsoredActor end

	-- trace( 'create sponsored ' ..  blockType.sponsoredActorConfig .. ' ' .. x .. ' ' .. y )
	local sponsoredActor = createActor( blockType.sponsoredActorConfig, ( x + 0.5 ) * PIXELS_PER_TILE, ( y + 1 ) * PIXELS_PER_TILE )
	sponsoredActor.baseBlockPos = vec2:new( x, y )
	dataForBlockAt( x, y ).sponsoredActor = sponsoredActor
	return sponsoredActor
end

function blockDeleteSponsored( x, y )
	local sponsoredActor = dataForBlockAt( x, y ).sponsoredActor
	if sponsoredActor ~= nil then
		deleteActor( sponsoredActor )
	end
end

CONVEYOR_EXPLANATION = { "Moves things." }
SENSOR_EXPLANATION = { 'Detects items.', 'Triggers Conveyors.' }
HARVESTER_EXPLANATION = 'Gathers resources.'
COMBINER_EXPLANATION = { 'Makes items and blocks.' }
OVEN_EXPLANATION = 'Turns ore into metal.'

BLOCK_CONFIGS = {
	ground = {
		mayBePlacedUpon = true,
	},
	conveyor = {
		name = 'Conveyor',
		explanation = CONVEYOR_EXPLANATION,
		actorConfigName = 'conveyor',
		conveyor = { direction = vec2:new( 0, -1 )},
		onPlaced = conveyorOnPlaced,
		tick = conveyorTick,
		onTriggered = onConveyorTriggered,
	},
	harvester = {
		name = 'Harvester',
		explanation = HARVESTER_EXPLANATION,
		actorConfigName = 'harvester',
		tick = harvesterTick,
	},
	combiner_off = {
		name = 'Combiner',
		explanation = COMBINER_EXPLANATION,
		actorConfigName = 'combiner',
		on_version = 516,
		recipes = {
			{
				inputs = { iron = 2, rubber = 1 },
				output = { conveyor = 1 },
				duration = 0.5,
			},
			{
				inputs = { stone = 2, iron = 3 },
				output = { harvester = 1 },
				duration = 0.5,
			},
			{
				inputs = { combiner = 1, gold = 2 },
				output = { sensor = 1 },
				duration = 0.5,
			},
			{
				inputs = { stone = 2, wood = 2 },
				output = { oven = 1 },
				duration = 0.5,
			},
			{
				inputs = { oven = 1, copper = 3 },
				output = { combiner = 1 },
				duration = 0.5,
			},
			{
				inputs = { sensor = 2, copper = 3 },
				output = { chip = 1 },
				duration = 0.5,
			},
		},
		tick = function( x, y, blockType, blockTypeIndex )
			if world.robotFound then
				blockCheckRecipes( x, y, blockType, blockTypeIndex )
			end
		end,
	},
	combiner_on = {
		name = 'Combiner',
		explanation = COMBINER_EXPLANATION,
		actorConfigName = 'combiner',
		off_version = 515,
		tick = function( x, y, blockType, blockTypeIndex )
			blockUpdateCooking( x, y, blockType, blockTypeIndex )
		end,
	},
	sensor_off = {
		name = 'Sensor',
		explanation = SENSOR_EXPLANATION,
		actorConfigName = 'sensor',
		on_version = 518,
		tick = sensorTickOff,
	},
	sensor_on = {
		name = 'Sensor',
		explanation = SENSOR_EXPLANATION,
		actorConfigName = 'sensor',
		off_version = 517,
		tick = sensorTickOn,
	},
	tree_base = {
		name = 'Tree',
		sponsoredActorConfig = 'tree',
		harvestSource = 'wood',
		harvestRate = 11,
		defaultCapacity = 9 * 10,
		onPlaced = function( x, y, blockType, blockTypeIndex )
			blockCreateSponsored( x, y, blockType, blockTypeIndex )
		end,
		initialCapacity = function( x, y, blockType )
			-- special case for first tree
			if x == 18 and y == 4 then
				return blockType.defaultCapacity
			end

			local capCurve = randInRange( 0, 1 ) ^ (1/1.5)
			return math.floor( lerp( blockType.defaultCapacity * 0.15, blockType.defaultCapacity, capCurve ))
		end
	},
	rubber_tree_base = {
		name = 'Rubber Tree',
		sponsoredActorConfig = 'tree_rubber',
		harvestSource = 'rubber',
		harvestRate = 11,
		defaultCapacity = 6 * 10,
		onPlaced = function( x, y, blockType, blockTypeIndex )
			blockCreateSponsored( x, y, blockType, blockTypeIndex )
		end,
	},
	source_iron_ore = { name = 'Iron Ore', harvestSource = 'iron_ore', harvestRate = 9, defaultCapacity = 9 * 14, },
	source_gold_ore = { name = 'Gold Ore', harvestSource = 'gold_ore', harvestRate = 45 },
	source_copper = { name = 'Copper', harvestSource = 'copper', harvestRate = 20 },
	source_stone = { name = 'Stone', harvestSource = 'stone', harvestRate = 10 },
	robot_base_off = robotBaseClass(),
	robot_base_on = {
		drawRecipes = false,
		off_version = 288,
		tick = function( x, y, blockType, blockTypeIndex )
			blockUpdateCooking( x, y, blockType, blockTypeIndex )
		end,
	},
}

BLOCK_TYPES = {
	[261] = BLOCK_CONFIGS.conveyor,
	[261+4] = {
		baseType = 261,
	},
	[261+32] = amendedObject( BLOCK_CONFIGS.conveyor, function( conveyor )
		conveyor.conveyor = { direction = vec2:new( 1, 0 ) }
	end),
	[261+32+4] = {
		baseType = 261+32,
	},
	[261+32*2] = amendedObject( BLOCK_CONFIGS.conveyor, function( conveyor )
		conveyor.conveyor = { direction = vec2:new( 0, 1 ) }
	end),
	[261+32*2+4] = {
		baseType = 261+32*2,
	},
	[261+32*3] = amendedObject( BLOCK_CONFIGS.conveyor, function( conveyor )
		conveyor.conveyor = { direction = vec2:new( -1, 0 ) }
	end),
	[261+32*3+4] = {
		baseType = 261+32*3,
	},

	[512] = {
		name = 'Oven',
		explanation = OVEN_EXPLANATION,
		actorConfigName = 'oven',
		on_version = 513,
		recipes = {
			{
				inputs = { iron_ore = 2 },
				output = { iron = 2 },
				duration = 2,
			},
			{
				inputs = { gold_ore = 2 },
				output = { gold = 1 },
				duration = 3,
			},
		},
		tick = function( x, y, blockType, blockTypeIndex )
			blockCheckRecipes( x, y, blockType, blockTypeIndex )
		end,
	},
	[513] = {
		name = 'Oven',
		explanation = OVEN_EXPLANATION,
		actorConfigName = 'oven',
		off_version = 512,
		tick = function( x, y, blockType, blockTypeIndex )
			blockUpdateCooking( x, y, blockType, blockTypeIndex )
		end,
	},
	[515] = BLOCK_CONFIGS.combiner_off,
	[516] = BLOCK_CONFIGS.combiner_on,
	[517] = BLOCK_CONFIGS.sensor_off,
	[518] = BLOCK_CONFIGS.sensor_on,
	[519] = BLOCK_CONFIGS.harvester,

	-- [288] = BLOCK_CONFIGS.robot_base_off,
	[290] = BLOCK_CONFIGS.robot_base_on,

	[480] = BLOCK_CONFIGS.tree_base,
	[481] = BLOCK_CONFIGS.source_iron_ore,
	[482] = BLOCK_CONFIGS.source_gold_ore,
	[483] = BLOCK_CONFIGS.source_copper,
	[484] = BLOCK_CONFIGS.source_stone,
	[485] = BLOCK_CONFIGS.rubber_tree_base,
}

function setBlockTypeRange( config, start, count )
	for i = start, start + count - 1 do
		BLOCK_TYPES[ i ] = config
	end
end

function blockTypeForIndex( blockTypeIndex )
	return BLOCK_TYPES[ blockTypeIndex ]
end

function baseBlockTypeIndex( blockTypeIndex )
	local blockType = blockTypeForIndex( blockTypeIndex )
	if blockType == nil then return blockTypeIndex end

	if blockType.baseType and blockType.baseType ~= blockTypeIndex then
		return baseBlockTypeIndex( blockType.baseType )
	end
	return blockTypeIndex
end

function withBaseBlockType( blockTypeIndex, callback )
	local baseTypeIndex = baseBlockTypeIndex( blockTypeIndex )
	local baseType = blockTypeForIndex( baseTypeIndex )
	if baseType ~= nil then
		return callback( baseType, baseTypeIndex )
	else
		return nil
	end
end

function blockTypeAt( x, y )
	local blockTypeIndex = mget( x, y )
	return blockTypeForIndex( blockTypeIndex ), blockTypeIndex
end

function forEachBlock( callback )
	for y = 0, WORLD_SIZE_TILES - 1 do
		for x = 0, WORLD_SIZE_TILES - 1 do
			local tileSpriteIndex = mget( x, y )
			if tileSpriteIndex >= MIN_ACTIVE_BLOCK_INDEX then
				local blockType = blockTypeForIndex( tileSpriteIndex )
				if blockType ~= nil then
					callback( x, y, blockType, tileSpriteIndex )
				end
			end
		end
	end
end

function fixupBlocks()
	setBlockTypeRange( BLOCK_CONFIGS.ground, 256, 5 )

	BLOCK_CONFIGS.robot_base_off = robotBaseClass()
	BLOCK_TYPES[ 288 ] = BLOCK_CONFIGS.robot_base_off


	for _, animSet in pairs( BLOCK_ANIM_SETS ) do
		local animSetBase = animSet.frames[ 1 ]

		for _, block in pairs( animSet.frames ) do
			if BLOCK_TYPES[ block ] == nil then
				BLOCK_TYPES[ block ] = {}
			end

			if block ~= animSetBase then
				BLOCK_TYPES[ block ].baseType = animSetBase
			end
			BLOCK_TYPES[ block ].animSet = animSet
		end
	end

	forEachBlock( function( x, y, blockType, blockTypeIndex )
		withBaseBlockType( blockTypeIndex, function( baseBlockType, baseBlockTypeIndex )
			if baseBlockType.onPlaced ~= nil then
				baseBlockType.onPlaced( x, y, blockType, blockTypeIndex )
				if baseBlockType.defaultCapacity ~= nil then
					if baseBlockType.initialCapacity ~= nil then
						blockSetCapacity( x, y, baseBlockType.initialCapacity( x, y, baseBlockType ) )
					else
						blockSetCapacity( x, y, baseBlockType.defaultCapacity )
					end
				end
			end
		end)
	end )
end


function updateBlock( x, y, blockType, blockTypeIndex )
	assert( blockType )

	withBaseBlockType( blockTypeIndex, function( baseBlockType, baseBlockTypeIndex )
		local animSet = blockType.animSet

		local animated = dataForBlockAt( x, y ).animated
		if animated == nil then animated = true end

		if animSet and animated then
			local changeSpeed = animSet.speed or 4
			local frame = math.floor( ticks // changeSpeed )

			local block = animSet.frames[ 1 + frame % #animSet.frames ]

			setBlockTypeSimple( x, y, block )
		end

		if baseBlockType.tick then
			baseBlockType.tick( x, y, baseBlockType, baseBlockTypeIndex )
		end
	end)
end

function updateBlocks()
	forEachBlock( function( x, y, blockType, blockTypeIndex )
		updateBlock( x, y, blockType, blockTypeIndex )
	end )
end

function speechSound()
	sfxm( 'speech' .. math.floor( randInt( 2, 4 )), 0.75 )
end

function onRobotFound()
	if not world.robotFound then
		world.robotDialoguing = true
		sfxm( 'speech3', 0.75 )
		showControlsGuides( true )
	end
end

function updateGameLogic()
	if not world.robotDialoguing then
		if world.player.pos.x >= 19 * PIXELS_PER_TILE and world.player.pos.y >= 13 * PIXELS_PER_TILE and world.player.pos.y <= 17 * PIXELS_PER_TILE then
			onRobotFound()
		end
	end
end

function updateActive()

	updateGameLogic()

	updateInput( world.player )

	updateActors()
	updateActorsOnBlocks()
	updateBlocks()

	ticks = ticks + 1
end

function pressToRestartAvailable()
	return ( realTicks - world.gameOverStartTime ) / 60 > 1.5
end

function pressToRestart()
	if pressToRestartAvailable() then
		if btnp( 4 ) or btnp( 5 ) then
			startGame()
			showControlsGuides( false )
		end
	end
end

function updateGameWon()
	barrel_ = 0.7
	color_multiplied_r = 1
	color_multiplied_g = 1
	color_multiplied_b = 0
	bloom_intensity_ = 0.8
	pressToRestart()
end

function updateGameLost()
	pressToRestart()
end

function updateDialogue()
	if btnp( 4 ) or btnp( 5 ) then
		showControlsGuides( false )

		world.dialogueStep = world.dialogueStep + 1

		if world.dialogueStep > #DIALOGUE then
			world.robotDialoguing = false
			world.robotFound = true
		else
			speechSound()
		end
	end
end

function update()

	if world.robotDialoguing then
		updateDialogue()
	elseif world.gameWon then
		updateGameWon()
	elseif world.gameLost then
		updateGameLost()
	else
		updateFuelGuage()
		updateActive()
	end

	updateScreenParams()

	realTicks = realTicks + 1
end


-- DRAW

-- TODO!!! world?
local viewLeft = 0
local viewTop = 0

function setWorldView( x, y )
	x = clamp( x, 0, WORLD_SIZE_PIXELS - screen_wid() )
	y = clamp( y, 0, WORLD_SIZE_PIXELS - screen_hgt() )

	viewLeft = math.floor( x )
	viewTop = math.floor( y )
	camera( viewLeft, viewTop )
end

function viewBounds()
	return {
		left = viewLeft,
		top = viewTop,
		right = viewLeft + screen_wid(),
		bottom = viewTop + screen_hgt(),
	}
end

function worldBoundsToTerrainBounds( bounds )
	local tileBounds = {
		left = 		worldToTile( bounds.left ),
		top = 		worldToTile( bounds.top ),
		right = 	worldToTile( bounds.right ),
		bottom = 	worldToTile( bounds.bottom ),
	}
	return tileBounds
end

function drawMap()
	local bounds = viewBounds()
	local tiles = worldBoundsToTerrainBounds( bounds )
	local wid = tiles.right - tiles.left + 1
	local hgt = tiles.bottom - tiles.top + 1

	map( tiles.left, tiles.top, tiles.left * PIXELS_PER_TILE, tiles.top * PIXELS_PER_TILE, wid, hgt )
end

function actorCountAdd( actor, amount )
	amount = amount ~= nil and amount or 1

	if actor.count == nil then actor.count = 1 end
	actor.count = actor.count + amount

	if actor.count > RESOURCE_MAX_COUNT_DEFAULT then
		actor.count = RESOURCE_MAX_COUNT_DEFAULT
	end

	if actor.count < 1 then
		deleteActor( actor )
	end

	-- count established.
end

function actorAgeTicks( actor )
	return ticks - actor.birthTicks
end

function actorSnapTo( actor, p )
	assert( actor )
	assert( p )
	actor.pos:set( p )
	actor.lastPos:set( actor.pos )
	actor.vel:set( 0 )
end

function actorDrawBounds()
	local bounds = viewBounds()
	assert( ACTOR_DRAW_MARGIN )
	expandContractRect( bounds, ACTOR_DRAW_MARGIN )
	return bounds
end

function drawActors()
	local bounds = actorDrawBounds()

	-- only draw actors in bounds.
	local drawnActors = {}

	for _, actor in ipairs( world.actors ) do
		if rectsOverlap( bounds, actorVisualBounds( actor ) ) then
			assert( not actor.deleted )

			table.insert( drawnActors, actor )
		end
	end

	table.sort( drawnActors, function( a, b )
		return a.pos.y < b.pos.y
	end )

	-- count occluders
	local numOccludingActors = 0
	for _, actor in ipairs( drawnActors ) do
		actor.occluding = actor.config.fadeForPlayer and actor.holder == nil and actorOccludesPlayer( actor )
		if actor.occluding then
			numOccludingActors = numOccludingActors + 1
		end
	end

	local targetOpacity = numOccludingActors > 0 and ( 0.2 / ( numOccludingActors ^ (1/2) )) or 1.0

	for _, actor in ipairs( drawnActors ) do
		local actorOpacity = actor.occluding and targetOpacity or 1.0
		actor.occlusionOpacity = lerp( actor.occlusionOpacity, actorOpacity, 0.2 )

		drawActor( actor )
	end

end

function populateWithActors()

	-- for i = 1,9 do
	-- 	createActor( 'chip', 10 * PIXELS_PER_TILE, 21 * PIXELS_PER_TILE )
	-- end
	-- for i = 1,5 do
	-- 	createActor( 'chip', 11 * PIXELS_PER_TILE, 21 * PIXELS_PER_TILE )
	-- end
	-- for i = 1,5 do
	-- 	createActor( 'chip', 11 * PIXELS_PER_TILE, 22 * PIXELS_PER_TILE )
	-- end
end

function startGame()

	musicm( 'ld46', 0.2 )

	world = {
		startGameTicks = ticks,
		actors = {},
		blocksToActors = {},
		blockData = {},
		robot = nil,
		player = nil,
	}

	restoreInitialMap()

	fixupBlocks()

	chromatic_aberration_ = DEFAULT_CHROMATIC_ABERRATION
	barrel_ = 				DEFAULT_BARREL
	bloom_intensity_ = 		DEFAULT_BLOOM_INTENSITY
	burn_in_ = DEFAULT_BURN_IN

	color_multiplied_r = 1
	color_multiplied_g = 1
	color_multiplied_b = 1
	color_multiplied_r_smoothed = 0
	color_multiplied_g_smoothed = 0
	color_multiplied_b_smoothed = 0

	barrel_ = DEFAULT_BARREL
	barrel_smoothed = barrel_


	world.player = createActor( 'player', 9 * PIXELS_PER_TILE, 21 * PIXELS_PER_TILE )

	populateWithActors()

	updateViewTransform()
end


function drawHUDFuelGuage()
	if not world.robotFound then return end

	local screen_mid = screen_wid() // 2
	local fuelGuageMaxWid = screen_wid() * 0.65
	local gaugeWid = fuelGuageMaxWid * clamp( proportion( world.robot.fuel, MIN_FUEL_FOR_MAX_NEEDINESS_DISPLAY, ROBOT_MAX_FUEL ), 0, 1 )
	local halfWid = gaugeWid // 2

	local gaugeColor = colorLerp( BRIGHT_RED, WHITE, gauge.flashBrightness )

	rectfill( screen_mid - halfWid, screen_hgt() - 5, screen_mid + halfWid, screen_hgt() - 3, gaugeColor )
end

RECIPE_TEXT_COLOR = 0xFFE3E0F2
RECIPE_TEXT_OFFSET_Y = 4

function drawResourceIcon( resourceKey, x, y )
	local config = ACTOR_CONFIGS[ resourceKey ]
	local sprite = config.animations.idle.frames[1]
	if sprite == nil then return end

	spr( sprite, x, y + 1, 1, 1, false, false, 0xFF000000 )
	spr( sprite, x, y )

	return 8
end

function drawIngredientList( ingredients, x, y )
	local i = 1
	for key, count in pairs( ingredients ) do
		if i > 1 then
			printShadowed( '+', x, y + RECIPE_TEXT_OFFSET_Y, RECIPE_TEXT_COLOR )
			x = x + 8
		end

		x = x + drawResourceIcon( key, x, y ) + 4

		if count > 1 then
			drawCount( count, x, y )
		end
		x = x + 8

		i = i + 1
	end

	return x
end

function drawBlockRecipes( blockType )

	local TOP_Y = 30
	local ROW_STEP = 20
	local PADDING_HORIZ = 8
	local PADDING_BOTTOM = PADDING_HORIZ
	local GUTTER = 16

	local nTotalRows = #tableFilter( blockType.recipes, function( recipe ) return recipe.output ~= nil end )
	local totalTableHeight = nTotalRows * ROW_STEP
	local availableHeight = screen_hgt() - TOP_Y - PADDING_BOTTOM

	local nNeededCols = math.ceil( totalTableHeight / availableHeight )

	local columnWidth = ( screen_wid() - PADDING_HORIZ*2 ) // nNeededCols
	local columnLeft = PADDING_HORIZ
	local y = TOP_Y
	for _, recipe in ipairs( blockType.recipes ) do
		if recipe.output ~= nil then
			local x = drawIngredientList( recipe.output, columnLeft, y )

			x = x + 2

			printShadowed( '<=', x, y + RECIPE_TEXT_OFFSET_Y, RECIPE_TEXT_COLOR )
			x = x + 16

			drawIngredientList( recipe.inputs, x, y )

			y = y + ROW_STEP

			if y + ROW_STEP >= screen_hgt() - PADDING_BOTTOM then
				y = TOP_Y
				columnLeft = columnLeft + columnWidth + GUTTER
			end
		end
	end
end

function printShadowed( text, x, y, color, font, shadowColor )
	print( text, x, y+1, shadowColor or 0xFF161C21, font )
	print( text, x, y, color, font )
end

function printOutlined( text, x, y, color, font, outlineColor )
	outlineColor = outlineColor or WHITE
	print( text, x+1, y  , outlineColor, font )
	print( text, x-1, y  , outlineColor, font )
	print( text, x  , y+1, outlineColor, font )
	print( text, x  , y-1, outlineColor, font )
	print( text, x, y, color, font )
end

function drawHUDBlockInfo()
	local screen_mid = screen_wid() // 2

	local x = worldToTile( world.player.pos.x )
	local y = worldToTile( world.player.pos.y )

	return withBlockTypeAt( x, y, function( blockType, blockTypeIndex )
		return withBaseBlockType( blockTypeIndex, function( blockTypeBase, baseBlockTypeIndex )
			local textX = 6
			local textY = 6
			local name = blockTypeBase.name
			if name ~= nil and name ~= '' then
				printOutlined( name or '', textX, textY, BRIGHT_RED, 2, WHITE )
				textY = textY + 10

				if type( blockTypeBase.explanation ) == 'table' then
					for _, text in ipairs( blockTypeBase.explanation ) do
						printShadowed( text, textX, textY, WHITE )
						textY = textY + 10
					end
				else
					local explanation = blockTypeBase.explanation
					explanation = explanation or ( blockTypeBase.harvestSource ~= nil and 'USE HARVESTER' or '' )
					printShadowed( explanation, textX, textY, WHITE )
					textY = textY + 10
				end

				if blockTypeBase.drawRecipes ~= false and blockTypeBase.recipes ~= nil then
					displayingForBlock = true
					drawBlockRecipes( blockTypeBase )
				end

				if blockTypeBase.draw ~= nil then
					displayingForBlock = true
					blockTypeBase.draw()
				end

				return blockTypeBase
			else
				return nil
			end
		end)
	end)
end

function printRightAligned( text, x, y, color, font, printFn )
	( printFn or print )( text, x - #text * 8, y, color, font )
end

function printCentered( text, x, y, color, font, printFn )
	( printFn or print )( text, x - #text * 4, y, color, font )
end

function drawRobotNeed( needRecipe )
	if world.robotFound then
		printRightAligned( ROBOT_NAME, screen_wid() - 10, 6, WHITE, 1, printShadowed )
		printRightAligned( ' needs', screen_wid() - 10, 14, WHITE, 1, printShadowed )
		drawIngredientList( needRecipe.inputs, screen_wid() - 16 - 10, 22 )
	end
end

function drawHUDQuest()
	local robotRecipes = BLOCK_CONFIGS.robot_base_off.recipes
	assert( robotRecipes ~= nil )

	local sequence = world.robot.recipeSequence or 1
	if sequence > #robotRecipes then return end

	local currentNeed = robotRecipes[ sequence ]
	assert( currentNeed ~= nil )

	drawRobotNeed( currentNeed )
end

function drawInstructions()
	if not world.moved then
		printCentered( 'ARROW KEYS TO MOVE.', screen_wid() // 2, screen_hgt() - (16+20), BRIGHT_RED, 1, printShadowed )
	end

	if not world.pickedUp then
		local msgColor = world.moved and BRIGHT_RED or WHITE
		printCentered( 'Z and X TO PICK UP', screen_wid() // 2, screen_hgt() - (16+10), msgColor, 3, printShadowed )
		printCentered( 'AND PLACE THINGS.', screen_wid() // 2, screen_hgt() - (16), msgColor, 3, printShadowed )
	end
end

function drawHUD()
	camera( 0, 0 )

	drawInstructions()

	drawHUDFuelGuage()

	local drawnBlockType = drawHUDBlockInfo()

	if drawnBlockType == nil
		or (     drawnBlockType == BLOCK_CONFIGS.robot_base_off
			  or drawnBlockType == BLOCK_CONFIGS.robot_base_on ) then

		drawHUDQuest()
	end

end

function drawPlayAgain( x )
	if pressToRestartAvailable() then
		printCentered( 'PLAY AGAIN!', x, screen_hgt() - 26, BRIGHT_RED, 2, printShadowed )
		printCentered( '[X]', x, screen_hgt() - 16, WHITE, 2, printShadowed )
		showControlsGuides( true )
	end
end

function drawGameWon()
	camera( 0, 0 )
	local midX = screen_wid() // 2
	local midY = screen_hgt() // 2
	printCentered( 'YOU WON!', midX, 16, BRIGHT_RED, 2, printShadowed )
	printCentered( 'You Kept ' .. ROBOT_NAME .. ' Alive', midX, 32, WHITE, 1, printShadowed )
	printCentered( 'and helped him get fixed!', midX, 42, WHITE, 1, printShadowed )

	printCentered( 'You won in:', midX, midY + 4, BRIGHT_RED, 2, printShadowed )
	printCentered( '' .. ( world.finalGameTicks - world.startGameTicks ) // 3600 .. ' minutes', midX, midY + 14, WHITE, 1,printShadowed )

	drawPlayAgain( midX )
end

function drawGameLost()
	camera( 0, 0 )
	local midX = screen_wid() / 2
	printCentered( 'GAME OVER', midX, 24, BRIGHT_RED, printShadowed )
	printCentered( 'You failed', midX, 40, WHITE, printShadowed )
	printCentered( 'to Keep ' .. ROBOT_NAME .. ' Alive.', midX, 50, WHITE, printShadowed )

	drawPlayAgain( midX )
end

DIALOGUE = {
	{ "HELLO AGAIN, OLD FRIEND!",
	  "Yes, it's me: " .. ROBOT_NAME .. "!" },
	{ "It's been",
	  "SUCH a LONG time!" },
	{ "As you may have noticed,",
	  "I've seen BETTER DAYS." },
	{ "I'd be much OBLIGED",
	  "if you would HELP me." },
	{ "I need WOOD to stay alive,",
	  "and some other ITEMS",
	  "to help FIX me." },
	{ "Would you FIND or MAKE",
	  "these items",
	  "and BRING them to me?" },
	{ "You may need to create",
	  "almost a FACTORY",
	  "to make it all." },
	{ "And DON'T FORGET:" },
	{ "I'll need WOOD",
	  "from time to time",
	  "to KEEP ALIVE!" },
	{ "I can't THANK YOU enough!" },
}

function drawDialogue()
	camera( 0, 0 )

	world.dialogueStep = world.dialogueStep or 1

	local midX = screen_wid() / 2

	local speech = DIALOGUE[ world.dialogueStep ]

	local y = 24
	for i, text in ipairs( speech ) do
		printCentered( text, midX, y, (world.dialogueStep == 1 and i == 1 ) and BRIGHT_RED or WHITE, (world.dialogueStep == 1 and i == 1 ) and 2 or 4, printShadowed )
		y = y + 12
	end

	printCentered( '[X] or [Z] to continue', midX, screen_hgt() - 20, BRIGHT_RED, 3, printShadowed )
end

TITLE_FADE_DURATION_SECS = 3

function drawTitle()

	if world.robotDialoguing or world.robotFound then return end

	if( world.pickedUp or world.moved ) and world.titleFadeStart == nil then
		world.titleFadeStart = ticks
	end

	local opacity = 1

	if world.titleFadeStart ~= nil then
		local titleShownDuration = ( ticks - world.titleFadeStart ) / 60

		if titleShownDuration > TITLE_FADE_DURATION_SECS then
			return
		end

		opacity = ( 1 - clamp( titleShownDuration / TITLE_FADE_DURATION_SECS, 0, 1 )) ^ (1/2)
	end

	local midX = screen_wid()/2

	-- fillp( bitPatternForAlpha( opacity * 0.1 ))
	-- spr( 19, midX - 2.5*16, 20, 6, 2, false, false, 0xFF000000 )

	fillp( bitPatternForAlpha( opacity ))
	spr( 19, midX - 42, 4, 6, 2 )
	printCentered( 'KEEP. HIM. ALIVE.', midX + 4, 36, WHITE, 2, printShadowed )

	fillp(0)
end

function draw()
	-- cls( 0xff000040 )

	updateViewTransform()

	fillp( 0 )
	drawMap()

	drawActors()

	if world.robotDialoguing then
		drawDialogue()
	elseif world.gameWon then
		drawGameWon()
	elseif world.gameLost then
		drawGameLost()
	else
		drawHUD()
	end

	drawTitle()

	camera( 0, 0 )
	drawDebug()
end

saveInitialMap()

startGame()

function mergeCountDictionaries( a, b )
	for key, count in pairs( b ) do
		if a[ key ] == nil then
			a[ key ] = count
		else
			a[ key ] = a[ key ] + count
		end
	end
end

function multiplyCountDictionary( dict, x )
	for key, count in pairs( dict ) do
		dict[ key ] = dict[ key ] * x
	end
end

function findProviderRecipe( resourceKey )
	_debug_trace( 'seeking provider for ' .. resourceKey )

	local function seekRecipeBook( book )
		for configKey, blockConfig in pairs( book ) do
			if blockConfig.recipes ~= nil then
				for _, recipe in ipairs( blockConfig.recipes ) do
					if recipe.output ~= nil then
						for key, count in pairs( recipe.output ) do
							if key == resourceKey then
								_debug_trace( 'found provider for ' .. resourceKey )
								return recipe, count
							end
						end
					end
				end
			end
		end
	end

	local recipe, count = seekRecipeBook( BLOCK_CONFIGS )
	if recipe == nil then
		return seekRecipeBook( BLOCK_TYPES )
	else
		return recipe, (count or 1)
	end
end

function findProviderSource( resourceKey )
	for key, config in pairs( BLOCK_CONFIGS ) do
		if config.harvestSource == resourceKey then
			return config
		end
	end
end

function totalRecipeCosts( recipe )
	local resourceCounts = {
		duration = recipe.duration or 0
	}
	for key, count in pairs( recipe.inputs ) do
		_debug_trace( key .. ':' .. count )
		assert( count > 0 )
		resourceCounts[ key ] = count
		local recipeForInput, outputCount = findProviderRecipe( key )
		if recipeForInput ~= nil then
			local cookCount = math.ceil( count / ( outputCount or 1))
			local recipeCosts = totalRecipeCosts( recipeForInput )
			multiplyCountDictionary( recipeCosts, cookCount )
			mergeCountDictionaries( resourceCounts, recipeCosts )
		else
			local sourceForInput = findProviderSource( key )
			if sourceForInput ~= nil then
				resourceCounts.duration = resourceCounts.duration + sourceForInput.harvestRate * count
			else
				_debug_trace( 'Found no source for ' .. key )
			end
		end
	end

	return resourceCounts
end

function reportResourceNeeds()
	local robotRecipes = BLOCK_CONFIGS.robot_base_off.recipes
	local resourceCounts = {
		duration = 0
	}

	for i = 1, #robotRecipes do
		local recipe = robotRecipes[ i ]

		local recipeCosts = totalRecipeCosts( recipe )
		mergeCountDictionaries( resourceCounts, recipeCosts )
	end

	_debug_trace( tableString( resourceCounts ))

	local minimumWood = math.ceil( resourceCounts.duration / ROBOT_TIME_TO_LOSE_FUEL_FROM_ONE_WOOD_SECONDS )
	_debug_trace( 'Minimum wood needed: ' .. minimumWood )

	_debug_trace( 'Minutes: ' .. round( resourceCounts.duration / 60 ))
end

-- reportResourceNeeds()

function save()
	local memento = {}

	memento.ticks = ticks
	memento.realTicks = realTicks
	memento.startGameTicks = world.startGameTicks
	memento.robotFound = world.robotFound

	memento.actors = {}

	for i, actor in ipairs( world.actors ) do
		memento.actors[ i ] = actorMemento( actor )

		if actor == world.player then memento.iPlayer = i end
		if actor == world.robot then memento.iRobot = i end
	end

	memento.blockData = {}
	for i, blockData in ipairs( world.blockData ) do
		memento.blockData[ i ] = blockData
	end
	
	return saveTable( memento )
end

function load( mementoString )
	-- trace( 'load' )

	-- local memento = restoreTable( mementoString )

	-- ticks = memento.ticks or ticks
	-- realTicks = memento.realTicks or realTicks
	-- world.startGameTicks = memento.startGameTicks
	-- world.robotFound = memento.robotFound

	-- world.actors = {}

	-- for i, actorMemento in ipairs( memento.actors ) do
	-- 	world.actors[ i ] = restoreActorMemento( actorMemento )
	-- end

	-- world.player = world.actors[ memento.iPlayer ]
	-- world.robot = world.actors[ memento.iRobot ]

	-- world.blockData = {}

	-- for i, blockData in ipairs( memento.blockData ) do
	-- 	world.blockData[ i ] = blockData
	-- end
end