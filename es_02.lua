-- Exquisite Script # 2

graphics = include "lib/graphics"

scale = {0,2,3,5,7,8,10,12,15}
pattern = { {}, {}, {}, {}, {}, {} }
steps = 8
pos = {1,1,1,1,1,1}
div = {1,1,1,1,1,1}
selector = 1

j = crow.ii.jf

function init()
  j.mode(1)
  clk = {}
  for i=1,6 do
    clk[i] = clock.run(tick,i)
  end
  build()
end

function tick(voice)
  while true do
    clock.sync(1/div[voice])
    count(voice)
  end
end

function count(voice)
  pos[voice] = (pos[voice] % steps) + 1
  j.play_voice(voice,pattern[voice][pos[voice]]/12, 8)
end

function build()
  for i=1,6 do
    for n=1,steps do
      pattern[i][n] = scale[math.random(#scale)]
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
  screen.move(8,20)
  screen.text(steps)
  graphics.baseline()
  for i=1,6 do
    screen.level(i == selector and 15 or 2)
    screen.move(i*8,32)
    screen.text(div[i])
    graphics.visualizer(i,div[i])
  end

  screen.update()
end
