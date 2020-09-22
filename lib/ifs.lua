local ImaginaryFriends = {}
local n_voices = 6

local j = crow.ii.jf

function ImaginaryFriends.mode(m)
	j.mode(m)
	if m ~= 1 then
		error('imaginary friends cannot imagine geode mode (yet?)')
	end
end

function ImaginaryFriends.play_voice(voice, pitch, level)
	if params:get('source') == 1 then
		engine.note(voice, math.pow(2, pitch) * 440, level / 10)
	else
		j.play_voice(voice, pitch, level)
	end
end

function ImaginaryFriends.add_params()
	params:add_group('imaginary friends', 12)

	params:add{
		id='source',
		name='source',
		type='option',
		options={'engine', 'just friends'},
	}

	params:add{
		id = 'ramp',
		name = 'ramp',
		type = 'control',
		controlspec = controlspec.new(0, 1, 'lin', 0, 0.5),
		action = engine.ramp
	}
	params:add{
		id = 'time',
		name = 'time',
		type = 'control',
		controlspec = controlspec.new(0.01, 10, 'exp', 0, 1),
		action = engine.time
	}
	params:add{
		id = 'curve',
		name = 'curve',
		type = 'control',
		controlspec = controlspec.new(-1, 1, 'lin', 0, 0),
		action = engine.curve
	}
	params:add{
		id = 'ratio',
		name = 'ratio',
		type = 'control',
		controlspec = controlspec.new(0.125, 16, 'exp', 0, 2),
		action = engine.ratio
	}
	params:add{
		id = 'index',
		name = 'index',
		type = 'control',
		controlspec = controlspec.new(0, 10, 'lin', 0, 0),
		action = engine.index
	}

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
