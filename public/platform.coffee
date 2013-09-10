canvas = $ "<canvas>"
body = $ "body"

xmlatts = (atts) ->
  (" #{key}=\"#{val}\"" for own key,val of atts).join() 
xmltag = (type="div", atts={}, body="") ->
  "<#{type}#{xmlatts atts}>#{body}</#{type}>"

#mafs
class V2d
  constructor: ( @x=0, @y=0 ) ->
add = (a,b) -> a+b
#vadd = (v,w) -> x: add(v.x,w.x), y: add(v.y,w.y)
vadd = (v,u) ->
  new V2d add(v.x,u.x), add(v.y,u.y)
vnmul = (v,n) ->
  new V2d v.x*n, v.y*n

class Sprite
  constructor: () ->
    @vel=new V2d()
    @pos=new V2d()
  tick: () ->
    @pos = vadd @pos, @vel

isholdingkey = (key) ->
  key = key.toUpperCase().charCodeAt 0
  key in heldkeys

class BugLady extends Sprite
  constructor: () ->
    super
    @jumping = false
  tick: ->
    @jumping = isholdingkey 'w'
    super
    if @touchingground()
      @pos.y = 64*4
      @vel.y = 0
      @vel.x = @vel.x/2
      if Math.abs(@vel.x)<0.0001
        @vel.x = 0
    if not @touchingground()
      @vel.y += 1
    if @touchingground() and @jumping
      @vel.y = -10
    lbw=64
    width = 640+lbw
    @pos.x = ( (@pos.x + (width+lbw)) % (width) )-lbw #WRAPAROUND

BugLady::render = (ctx) ->
   src="lovelyshorter.png"
   vel = Math.abs( @vel.x )
   walking = vel > 0.2
   if walking
     src = if (tickno%12>6) then 'lovelyrun1.png' else 'lovelyrun2.png'
   if not @touchingground()
     src = 'lovelyjump.png'
   if not walking and isholdingkey 's'
     src = 'lovelycrouch.png'
   img = if @facingleft then cacheflippedimg(src) else cachedimg(src)
   ctx.drawImage img, @pos.x, @pos.y

ladybug = new BugLady
ladybug.facingleft = false
ladybug.jumping=false
BugLady::touchingground = () ->
  @pos.y >= 64*4
bindings = {}
holdbindings = {}
heldkeys = []

keytapbind = ( key, func ) ->
  k=key.toUpperCase().charCodeAt 0
  bindings[k]=func
keyholdbind = ( key, func ) ->
  k=key.toUpperCase().charCodeAt 0
  holdbindings[k]=func

arrclone = (arr) -> arr.slice 0

keyholdbind 'w', ->
  ladybug.jumping=true
keyholdbind 's', ->
keyholdbind 'a', ->
  ladybug.facingleft = true
  ladybug.vel.x=-4
keyholdbind 'd', ->
  ladybug.facingleft = false
  ladybug.vel.x=4

arrsansval = (arr,val) ->
 #DEVNOTE: unsure whether i should always return a clone,
 # or just the original if there's nothing removed
 if not val in arr then return arr
 newarr=arrclone arr
 i=newarr.indexOf val
 if i is -1 then return newarr
 newarr.splice i, 1
 return newarr

$(document).bind 'keydown', (e) ->
  key = e.which
  bindings[key]?()
  if not (key in heldkeys)
    heldkeys.push key
$(document).bind 'keyup', (e) ->
  key = e.which
  heldkeys = arrsansval heldkeys, key

tmpcanvasjq = $ "<canvas>"
tmpcanvas = tmpcanvasjq[0]

ladybug.pos = x: 64, y: 100

ctx = canvas[0].getContext '2d'

canvas.attr 'height', 64*6
canvas.attr 'width', 640
canvas.css 'border', '1px solid black'

tickno = 0

sourcebaseurl = "./sprites/"
loadimg = (src) ->
  img = new Image
  img.src = sourcebaseurl+src
  return img

memoize = (func) ->
  newfunc = (args...) ->
    if not (args of newfunc._memos)
      newfunc._memos[args]=func.apply @, args
    newfunc._memos[args]
  newfunc._memos={}
  return newfunc

cachedimg = memoize loadimg

flipimg = (src) ->
  img = cachedimg src
  newcanvas = $("<canvas>")[0]
  newcanvas.width = img.naturalWidth
  newcanvas.height = img.naturalHeight
  newctx = newcanvas.getContext '2d'
  newctx.scale -1, 1
  newctx.translate -img.naturalWidth, 0
  newctx.drawImage img, 0, 0
  return newcanvas

cacheflippedimg = memoize flipimg

sources = [ 'lovelyshorter.png', 'lovelycrouch.png', 'lovelyrun1.png', 'lovelyrun2.png', 'lovelyjump.png', 'cloud.png', 'lovelyfall.png' ]
sources.push 'groundtile.png'
#PRELOAD

preloadcontainer = $ "<div>"
preloadcontainer.hide()
body.append preloadcontainer


preload = ->
  for src in sources
    console.log "PRELOADING #{src}"
    img = cachedimg src
    preloadcontainer.append img


preload()

tilebackground = ( ctx, offset, src ) ->
  cw = canvas[0].width
  ch = canvas[0].height
  img = cachedimg src
  if img.width == 0 or img.height == 0 then return
  horiznum = Math.floor cw/img.width
  vertnum = Math.floor ch/img.height
  [-1...horiznum+1].forEach (n) ->
    [-1..vertnum+1].forEach (m) ->
      finalx = n*img.width+(offset.x%img.width)
      finaly = m*img.height+(offset.y%img.height)
      ctx.drawImage img, finalx, finaly

class Block
  constructor: (@x,@y,@w,@h) ->
  render: (ctx) ->
    ctx.beginPath()
    ctx.fillStyle = 'brown'
    ctx.fillRect @x, @y, @w, @h

tmpcanvas.width = canvas[0].width
tmpcanvas.height = canvas[0].height
tmpctx = tmpcanvas.getContext '2d'

bglayer = []
bglayer.push new Block 0, 64*5-4, 640, 100
bglayer.push new Block 64*4, 64*2, 32, 32

Layer = () ->
  newlayer = $ "<canvas>"
  return newlayer[0]

brickcanvas = Layer()
brickcanvas.width = canvas[0].width
brickcanvas.height = canvas[0].height
brickctx = brickcanvas.getContext '2d'

render = ->
  tilebackground ctx, x: tickno*-0.2, y: Math.sin(tickno/200)*64, "cloud.png"
  tilebackground brickctx, (x: 0, y: 0), "groundtile.png"
  tmpctx.clearRect 0, 0, 640, 640
  bglayer.forEach (sprite) ->
    sprite.render? tmpctx
  tmpctx.globalCompositeOperation = "source-in"
  tmpctx.drawImage brickcanvas, 0, 0
  tmpctx.globalCompositeOperation = "source-over"
  ctx.drawImage tmpcanvas , 0, 0
  
  #ledibag start
  ladybug.render ctx

looptick = ->
  for key in heldkeys
    holdbindings[key]?()
  ladybug.tick()
  tickno++
  render()

tickwaitms = 10
mainloop = ->
  looptick()
  setTimeout mainloop, tickwaitms

#uses imagesLoaded.js by desandro

preloadcontainer.imagesLoaded 'done', ->
  body.append canvas
  ctx.fillStyle="#008080"
  ctx.fillRect 0, 0, 640, 64
  body.append "<br/><em>there's no crime to fight around here, use WASD to waste time by purposelessly wiggling around</em><br/>"
  body.append xmltag 'a', target: '_blank', href: 'http://www.youtube.com/watch?v=NbVZPu_JM6I', "recommended soundtrack"
  body.append c=$ xmltag()
  c.css 'color', 'silver'
  c.append "<p>psst CAN YOU FIND THE SAUCY SUPER SECRET SAPPHIC SLOPPY SMOOCHING SCENE??</p>"
  c.append answer = $ "<em>(answer: no you can't, because it doesn't exist)</em>"
  answer.css 'transform', 'rotate(180deg)'
  answer.css 'display': 'inline-block'
  mainloop()

