-- Exquisite Script # 5
-- 
-- Controls:
-- ---------
-- K1 - Shift
-- K2 - Randomize Pitches
-- K3 - Randomize Clockdivs
-- K1 + K2 - Randomize Octaves
-- K1 + K3 - Play/Stop
--
-- E1 - Adjust Globals
-- K1 + E1 - Select Global
-- E2 - Select Column
-- K1 + E2 - Select Row
-- E3 - Adjust Selected
--
-- State Saving:
-- -------------
-- K1 + Midi Note will store
-- current edit buffer at that
-- note. Press the note to
-- recall. 128 states available.
--
-- Row Legend:
-- -----------
-- / - Voice Clockdiv
-- Oct - Voice Octave select
-- % - Voice Trigger Probability

local mu = require 'musicutil'
local j = crow.ii.jf
local ifs = include 'lib/ifs'

local scale = {0,2,3,5,7,8,10,12,15}
local noteLength = {1, 2, 4, 8, 16} -- referenced but not really used yet
local octaves = {-3, -2, -1, 0, 1, 2, 3}
local mchans = {1, 1, 1, 1, 1, 1}

local states = {}
local currstate = {}

local activenotes = {}

local clk = {}

local shift = false
local selector = 1
local rowselector = 1
local globalselector = 1
local k2down = false
local k3down = false
local stateMessage = false

local playing = false
local gate = {false, false, false, false, false, false}

local offon = {"Off", "On"}
local midi_out_active = true
local jf_out_active = true
local ifs_out_active = true

local m_out = midi.connect()
local m_in = midi.connect()

engine.name = 'ImaginaryFriends'

function init()
    currstate = initstate()
    build_params()
    m_in.event = handle_input
    draw_clock = metro.init(intclk, 0.002, -1)
    draw_clock:start()
    play()  
   
end  

function initstate()
  currstate = newstate()
  build()
  return currstate

end

function newstate()
  return {    
    steps = 8,
    pattern = { {}, {}, {}, {}, {}, {} },
    pos = {1,1,1,1,1,1},
    div = {1,1,1,1,1,1}, 
    v_octave = {4, 4, 4, 4, 4, 4},
    probs = {100,100,100,100,100,100},
    root = 60,
    slop = 0
  }

end

function build()
    for i=1,6 do
      for n=1,currstate.steps do
        currstate.pattern[i][n] = scale[math.random(#scale)]
      end
    end
  
end
  

function build_params()
  ifs.add_params()
 
  params:add_group("output options", 3)

  params:add{type = "option",
             id = "midi_output",
             name = "MIDI output",
             options = offon,
             default = 2
            }

  params:add{type = "option",
             id = "jf_output",
             name = "Just Friends output",
             options = offon,
             default = 2
            }

  params:add{type = "option",
             id = "ifs_output",
             name = "Imaginary Friends output",
             options = offon,
             default = 2
            }

  params:add_group("midi options", 8)

  params:add{type = "number",
             id = "midi_in_device",
             name = "MIDI in device",
             min = 1,
             max = 4,
             default = 1,
             action = function(value)
                        midi:cleanup()
                        m_in = midi.connect(value)
                        m_in.event = handle_input
                      end
            }

  params:add{type = "number",
             id = "midi_out_device",
             name = "MIDI out device",
             min = 1,
             max = 4,
             default = 1,
             action = function(value)
                        allnotesoff()
                        m_out = midi.connect(value)
                      end
            }

  for i = 1, 6 do
    params:add{type = "number",
               id = "mchan_v"..i,
               name = "MIDI out channel V"..i,
               min = 1,
               max = 16,
               default = 1,
               action = function(value)
                         allchannotesoff(mchans[i])
                         mchans[i] = value
                        end
              }
  end

end

function intclk()
  redraw()

end

function play()
  for i = 1,6 do
    clk[i] = clock.run(tick, i)
  end
  playing = true

end

function stop()
  for i = 1,6 do
    clock.cancel(clk[i])
  end
  playing = false
  allnotesoff()

end
 
function tick(voice)
  while true do
    clock.sync(1/currstate.div[voice])
    count(voice)
  end

end

function count(voice)
  currstate.pos[voice] = (currstate.pos[voice] % currstate.steps) + 1
  local note = currstate.pattern[voice][currstate.pos[voice]] + currstate.root + octaves[currstate.v_octave[voice]]*12
 
  if math.random(100) <= currstate.probs[voice] then
    clock.run(playnote, note, voice)
  end

end

function playnote(note, voice)
  if currstate.slop > 0 then
    clock.sleep(math.random(currstate.slop)/100)
  end

  gate[voice] = true

  if params:get("jf_output") ==  2 then
    j.play_voice(voice,note/12, 8)
  end

  if params:get("ifs_output") == 2 then
    ifs.play_voice(voice,(note - 60)/12, 8)
  end
 
  if params:get("midi_output") ==  2 then 
    m_out:note_on(note, 127, mchans[voice])
    table.insert(activenotes, note)
    clock.sync(1/noteLength[4])
    m_out:note_off(note, 0, mchans[voice])
    table.remove(activenotes)
  end

  gate[voice] = false

end

function allnotesoff()
  for i = 1, #mchans do
    for j = 1, #activenotes do
        m_out:note_off(activenotes[j], 0, mchans[i])      
    end
  end
  activenotes = {}

end

function allchannotesoff(chan)
    for i = 1, #activenotes do
        m_out:note_off(activenotes[i], 0, chan)      
    end

end

function handle_input (data)
    local d = midi.to_msg(data)
    if d.type == 'note_on' then
      if shift then
        local temp = t_deepcopy(currstate)
        states[d.note] = temp
        clock.run(state_message, d.note)
      else
        if states[d.note] ~= nil then
          currstate = t_deepcopy(states[d.note])
        end
      end
    end  
   
end

function key(n,d)
  if n == 1 then
    if d == 1 then
      shift = true
    else
      shift = false
    end
  elseif n == 2 and d == 1 then
    k2down = true
    if shift then
      for i = 1,6 do
        currstate.v_octave[i] = math.random(3, 5)
      end
    else
      build()
    end
  elseif n == 2 and d == 0 then
    k2down = false
  elseif n == 3 and d == 1 then
    k3down = true
    if shift then
      if playing then
        stop()
      else
        play()
      end
    else
      for i=1,6 do
        currstate.div[i] = math.random(1,4)
      end
    end
  elseif n == 3 and d == 0 then
    k3down = false
  end
  redraw()

end

function enc(n,d)
  if n == 1 then
    if shift then
      globalselector = util.clamp(globalselector + d, 1, 3)
    elseif globalselector == 1 then
      currstate.steps = util.clamp(currstate.steps + d,1,8)
    elseif globalselector == 2 then
      currstate.slop = util.clamp(currstate.slop + d, 0, 50)
    elseif globalselector == 3 then
      currstate.root = util.clamp(currstate.root + d, 0, 127)
    end
  elseif n == 2 then
    if shift then
      rowselector = util.clamp(rowselector + d, 1, 3)
    else
      selector = util.clamp(selector+d,1,6)
    end
  elseif n == 3 then
    if rowselector == 1 then
      currstate.div[selector] = util.clamp(currstate.div[selector]+d,1,4)
    elseif rowselector == 2 then
      currstate.v_octave[selector] = util.clamp(currstate.v_octave[selector] + d,1,7)
    elseif rowselector == 3 then
      currstate.probs[selector] = util.clamp(currstate.probs[selector] + d, 0, 100)
    end
  end
  redraw()

end

function t_deepcopy(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then
    return seen[obj]
  end

  -- New table; mark it as seen and copy recursively.
  local s = seen or {}
  local res = {}
  s[obj] = res
  for k, v in pairs(obj) do
    res[t_deepcopy(k, s)] = t_deepcopy(v, s)
  end
  return setmetatable(res, getmetatable(obj))

end

function state_message (data)
  stateMessage = true
  stateMessageNote = data
  clock.sleep(2)
  stateMessage = false

end

function redraw()
  local str = ""
  local headrow = 5
  local rows = {20, 31, 42}
 
  screen.clear()
  screen.aa(0)
 
  screen.move(1, headrow)  
  screen.level(globalselector == 1 and 15 or 2)
  screen.text("steps: "..currstate.steps)

  str = "t-slop: "..currstate.slop
  screen.move(64 - math.floor(screen.text_extents(str)/2), headrow)
  screen.level(globalselector == 2 and 15 or 2)
  screen.text(str)

  str = "root: "..mu.note_num_to_name(currstate.root, true)
  screen.move(128 - math.floor(screen.text_extents(str)), headrow)
  screen.level(globalselector == 3 and 15 or 2)
  screen.text(str)

  screen.level(4)
  screen.move(0, 9)
  screen.line_width(1)
  screen.line(128,9)
  screen.stroke()

  screen.move(1,rows[1])
  screen.level(rowselector ==  1 and 15 or 2)
  screen.text("/")
 
  for i=1,6 do
    if rowselector == 1 then
      screen.level(i == selector and 15 or 2)
    else
      screen.level(2)
    end
    screen.move(i*19,rows[1])
    screen.text(currstate.div[i])
  end
 
  screen.move(1,rows[2])
  screen.level(rowselector ==  2 and 15 or 2)
  screen.text("Oct")
 
  for i = 1,6 do
    if rowselector == 2 then
      screen.level(i == selector and 15 or 2)
    else
      screen.level(2)
    end
    screen.move(i*19,rows[2])
    screen.text(octaves[currstate.v_octave[i]])
  end
 
  screen.move(1,rows[3])
  screen.level(rowselector ==  3 and 15 or 2)
  screen.text("%")

  for i = 1,6 do
    if rowselector == 3 then
      screen.level(i == selector and 15 or 2)
    else
      screen.level(2)
    end
    screen.move(i*19,rows[3])
    screen.text(currstate.probs[i])
  end
 
  screen.level(15)
  xval1 = 20
  xval2 = 31
  screen.aa(1)
  screen.line_width(2)
  for i = 1, 6 do
    if gate[i] then
      screen.move(xval1, rows[3]+6)
      screen.line(xval2, rows[3]+6)
      screen.stroke()
    end
    xval1 = xval1 + 19
    xval2 = xval2 + 19
  end
 
  screen.aa(0)
 
  screen.level(4)
  screen.move(0, 54)
  screen.line_width(1)
  screen.line(128,54)
  screen.stroke()

  if stateMessage then
    screen.level(15)
    str = "State saved to note "..mu.note_num_to_name(stateMessageNote, true).."!"
    screen.move(64 - screen.text_extents(str)/2, 62)
    screen.text(str)
  else    
    screen.level(k2down and 15 or 2)
    screen.move(1, 62)
    if shift then
      screen.text("K2: Rnd Octs")
    else
      screen.text("K2: Rnd Pitch")
    end
   
    screen.level(k3down and 15 or 2)
    if shift then
      if playing then
        str = "K3: Stop"
      else
        str = "K3: Play"
      end
    else
      str = "K3: Rnd Divs"
    end
    screen.move(128 - screen.text_extents(str), 62)
    screen.text(str)
  end
 
  screen.update()

end