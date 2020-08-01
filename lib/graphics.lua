local graphics = {}

function graphics.init() end

function graphics.mlrs(xa,ya,xb,yb)
  screen.move(xa,ya)
  screen.line_rel(xb,yb)
  screen.stroke()
end

function graphics.baseline()
  screen.level(1)
  graphics.mlrs(6,35,47,0)
end

function graphics.visualizer(i,div)
  local a = div * 4
  local x1 = (i * 8) + 2
  local x2 = ((i * 8) + 1) + 2
  screen.level(15)
  graphics.mlrs(x1,36,0,a)
  graphics.mlrs(x2,36,0,a)
end

return graphics