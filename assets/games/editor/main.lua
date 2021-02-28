-- Lua

screen_size( 480 )
barrel( 0.2 )
noise( 0.02, 1 )
bevel( 0.5 )
bloom( 3, 5, 0 )

-- TODO
local bloom_intensity = 0
local bloom_contrast = 0
local bloom_brightness = 0

local history = {}
local topHistoryToPrint = 1
local command = ''
local insertPos = command:len() + 1
local font = 1
local glyph_wid = 8
local top = 4
local left = 4

local recalledHistoryIndex = nil
local pendingCommand = nil
local pendingInsertPos = nil

function maxTextWidth()
	return ( screen_wid() - left*2 ) // glyph_wid
end

function clamp( x, min, max )
	return math.min( math.max( x, min ), max )
end

function clearConsole()
	topHistoryToPrint = #history + 1
end

function table.slice(tbl, first, last)
	local sliced = {}

	if first < 0 then
		first = #tbl + 1 + first
	end

	if last < 0 then
  		last = #tbl + 1 + last
	end

	for i = first or 1, last or #tbl do
    	sliced[#sliced+1] = tbl[i]
	end

	return sliced
end

function console( message, executable )

	-- split the line at a reasonable number of characters
	while #message > 0 do
		local submessage = message:sub( 1, maxTextWidth() )
		table.insert( history, { message = submessage, executable = executable ~= nil or false } )

		message = message:sub( maxTextWidth() + 1, -1 )
	end
end

function string_insert( s, pos, insert )
	return string.sub( s, 1, pos - 1 ) .. insert .. string.sub( s, pos )
end

function string_remove( s, pos )
	if pos == nil then pos = s:len() end

	return string.sub( s, 1, pos - 1 ) .. string.sub( s, pos + 1, -1 )
end

function nullKey( key ) end

function charKey( key )
	command = string_insert( command, insertPos, string.char( key ))
	insertPos = insertPos + 1
end

function tabKey( key )
	charKey( 32 )
	-- TODO completion handling
end

function directionalKey( key )
	if key == 17 then
		insertPos = math.max( insertPos - 1, 1 )
	elseif key == 18 then
		insertPos = math.min( insertPos + 1, command:len() + 1 )
	elseif key == 19 then
		if recalledHistoryIndex == nil then
			startIndex = #history
			pendingCommand = command
			pendingInsertPos = insertPos
		else
			startIndex = recalledHistoryIndex - 1
		end

		for i = startIndex, 1, -1 do
			if history[ i ].executable then
				recalledHistoryIndex = i
				break
			end
		end

		if recalledHistoryIndex == nil or recalledHistoryIndex < 1 or recalledHistoryIndex > #history then
			recalledHistoryIndex = nil
		else
			command = history[ recalledHistoryIndex ].message
			insertPos = command:len() + 1
		end
	elseif key == 20 then

		if recalledHistoryIndex ~= nil then
			for i = recalledHistoryIndex + 1, #history + 1 do
				if i > #history or history[ i ].executable then
					recalledHistoryIndex = i
					break
				end
			end

			if recalledHistoryIndex > #history then
				command = pendingCommand
				insertPos = pendingInsertPos
				recalledHistoryIndex = nil
			else
				command = history[ recalledHistoryIndex ].message
				insertPos = command:len() + 1
			end
		end	
	end
end

function maxHistoryLen()
	return ( screen_hgt() - top ) // text_line_hgt() - 1
end

function enterKey( key )
	if command:len() > 0 then

		-- Move to the history.
		console( command, true )

		insertPos = 1

		pendingCommand = nil
		pendingInsertPos = nil
		recalledHistoryIndex = nil

		-- Execute the command.
		if command == 'cls' then
			clearConsole()
		else
			execute( command )
		end
		command = ''		
	end
end

local commandKeys = {
	[0] = nullKey,
	[1] = nullKey,
	[2] = function( key ) 	-- Home
		insertPos = 1
		end,		
	[3] = function( key ) 	-- End
		insertPos = command:len() + 1
		end,		
	[4] = nullKey,
	[5] = nullKey,
	[6] = nullKey,
	[7] = nullKey,
	[8] = function( key ) 	-- Backspace
		command = string_remove( command, insertPos - 1 ) 
		insertPos = math.max( 1, insertPos - 1 )
		end,	
	[9] = tabKey,
	[10] = nullKey,
	[11] = nullKey,
	[12] = nullKey,
	[13] = enterKey,
	[14] = nullKey,
	[15] = nullKey,
	[16] = nullKey,
	[17] = directionalKey,
	[18] = directionalKey,
	[19] = directionalKey,
	[20] = directionalKey,
	[21] = nullKey,
	[22] = nullKey,
	[23] = nullKey,
	[24] = nullKey,
	[25] = nullKey,
	[26] = nullKey,
	[27] = nullKey,
	[28] = nullKey,
	[29] = nullKey,
	[30] = nullKey,
	[31] = nullKey,
	
	[127] = function( key ) 	-- Delete
		command = string_remove( command, insertPos ) 
		end,		
}

function onKey( key )
	local command = commandKeys[ key ] or charKey
	command( key )
end

function updateKeys()
	for keyCode = 0, 256 do
		if keydown( keyCode ) then
			onKey( keyCode )
		end
	end
end

function update()
	updateKeys()
end

function flash()
	local period = 0.65
	return ( time() % period >= period / 2 )
end

function draw()
	function printCommandText( text )
		print( text, nil, nil, 0xffffffff, font, nil, true )
	end

	cls( 0xff606080 )
	
	-- print the command history
	print( '', left, top, nil, font, nil, true )
	local start = math.max( topHistoryToPrint, #history - maxHistoryLen() + 1 )	
	for i = start, #history do
		local line = history[ i ]
		print( line.message, left, nil, line.executable and 0xffcccccc or 0xffeeeeeee, font )
	end

	-- print the current command
	print( '', left, nil, nil, font, nil, true )
	printCommandText( ">" )
	printCommandText( command:sub( 1, insertPos - 1 ))

	if flash() then
		print( string.char( 128 ), nil, nil, 0xffaa0000, font, nil, true )
	else
		printCommandText( command:sub( insertPos, insertPos ))
	end
	printCommandText( command:sub( insertPos + 1, -1 ))
	print()
end
