local ImaginaryFriends = {}
local n_voices = 6

function ImaginaryFriends.mode(m)
	if m ~= 1 then
		error('imaginary friends cannot imagine geode mode (yet?)')
	end
end

function ImaginaryFriends.play_voice(voice, pitch, level)
	engine.note(voice, math.pow(2, pitch) * 440, level)
end

function ImaginaryFriends.add_params()
	params:add_group('imaginary friends', 6) -- TODO

	-- TODO: add base freq arg to engine
	for v = 1, 6 do 
		params:add{
			id = 'pan_' .. v,
			name = 'pan ' .. v,
			type = 'control',
			controlspec = controlspec.new(-1, 1, 'lin', 0, (v - 1) / 2.5 - 1, ''),
			action = function(value)
				engine.pan(v, value)
			end
		}
	end

	params:bang()
end

return ImaginaryFriends