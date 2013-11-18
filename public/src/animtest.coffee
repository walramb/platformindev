canvas = $ "<canvas>"
body = $ "body"
body.append $ "<b>gotta go fast</b><br>"
ladybug = imgsrc: 'lovely.png'

ladybug.pos = x: -64, y: 0

ctx = canvas[0].getContext '2d'

canvas.attr 'height', 64
canvas.attr 'width', 640
canvas.css 'border', '1px solid black'

tickno = 0

loadimg = (src) ->
  img = new Image
  img.src = basehref+src
  return img

basehref = './sprites/'
sources = [ 'lovelyshorter.png', 'lovelycrouch.png', 'lovelyrun1.png', 'lovelyrun2.png', 'lovelyjump.png' ]

preload = ->
  sources.forEach (src) -> loadimg src

render = ->
  ctx.fillStyle="#008080"
  ctx.fillRect 0, 0, 640, 64
  img = new Image()
  src = if (tickno%12>6) then 'lovelyrun1.png' else 'lovelyrun2.png'
  posing = tickno%1000<200
  if posing
    src = if (tickno%32>16) then 'lovelycrouch.png' else 'lovelyshorter.png'
  lastframe = 1000
  if tickno%lastframe<50 #or (tickno%lastframe>175 and tickno%lastframe<200)
    src = 'lovelyshorter.png'
  if tickno%500>350
    src = 'lovelyshorter.png'
    posing = true
    jumping = true
  if tickno%lastframe>lastframe-150 and jumping
    posing = true
    src = 'lovelycrouch.png'
  if tickno%lastframe>lastframe-100 and jumping
    posing = false
    src = 'lovelyjump.png'
  if tickno%lastframe>lastframe-50 and jumping
    posing=true
    src = 'lovelyfall.png'
  if tickno%lastframe>lastframe-20
    src = 'lovelycrouch.png'
  img.src = basehref+src
  ctx.drawImage img, ladybug.pos.x, ladybug.pos.y
  if not posing then ladybug.pos.x++
  if ladybug.pos.x>640
    ladybug.pos.x = -64

looptick = ->
  tickno++
  render()

tickwaitms = 10
mainloop = ->
  looptick()
  setTimeout mainloop, tickwaitms

body.ready ->
  preload()
  body.append canvas
  mainloop()

