-- Exquisite Script # 4

musicutil = require 'musicutil'

graphics = include "lib/graphics"

root = 0
mod_multiplier = 8

scale = {0,4,7,11,14,18,21}
pattern = { {}, {}, {}, {}, {}, {} }
steps = 8
pos = {1,1,1,1,1,1}
div = {1,1,1,1,1,1}
selector = 1

engine.name = 'ImaginaryFriends'
j = include 'lib/ifs'

function init()
  j.add_params()
  j.mode(1)
  build()
  clk = {}
  for i=1,6 do
    clk[i] = clock.run(tick,i)
  end
  clock.run(modulate)
end

function modulate()
  while true do
    clock.sync(mod_multiplier)
    root = (root + 5) % 12
    redraw()
  end
end

function tick(voice)
  while true do
    clock.sync(1/div[voice])
    count(voice)
  end
end

function count(voice)
  pos[voice] = (pos[voice] % steps) + 1
  j.play_voice(voice,(root+pattern[voice][pos[voice]])/12, 8)
end

function wrap_note(note)
  local octave = math.floor(note / #scale) - 2
  local note = (note - 1) % #scale + 1
  return scale[note] + octave * 12
end

function build()
  for i=1,6 do
    for n=1,steps do
      pattern[i][n] = wrap_note(math.random(#scale * 3))
    end
  end
end

function key(n,d)
  if n == 2 and d == 1 then
    build()
  elseif n == 3 and d == 1 then
    for i=1,6 do
      div[i] = math.random(1,4)
    end
  end
  redraw()
end

function enc(n,d)
  if n == 1 then
    steps = util.clamp(steps+d,1,8)
  elseif n == 2 then
    selector = util.clamp(selector+d,1,6)
  elseif n == 3 then
    div[selector] = util.clamp(div[selector]+d,1,4)
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.level(15)
  draw_field(8, 20, 'steps:', steps)
  draw_field(45, 20, 'root:', musicutil.note_num_to_name(root))
  graphics.baseline()
  for i=1,6 do
    screen.level(i == selector and 15 or 2)
    screen.move(i*8,32)
    screen.text(div[i])
    graphics.visualizer(i,div[i])
  end

  screen.update()
end

function draw_field(x, y, label, value)
  screen.level(2)
  screen.move(x, y)
  screen.text(label)
  local label_w = screen.text_extents(label)
  screen.move(x + label_w + 4, y)
  screen.level(15)
  screen.text(value)
end
