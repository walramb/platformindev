#vidyon gem

slowmo = false


canvas = $ "<canvas>"
body = $ "body"


xmlatts = (atts) ->
  (" #{key}=\"#{val}\"" for own key,val of atts).join() 
xmltag = (type="div", atts={}, body="") ->
  "<#{type}#{xmlatts atts}>#{body}</#{type}>"

#mafs
add = (a,b) -> a+b
sum = (arr) -> arr.reduce add, 0
avg = (arr) -> sum(arr)/arr.length

class V2d
  constructor: ( @x=0, @y=0 ) ->
#vadd = (v,w) -> x: add(v.x,w.x), y: add(v.y,w.y)
vadd = (v,u) ->
  new V2d add(v.x,u.x), add(v.y,u.y)
vnmul = (v,n) ->
  new V2d v.x*n, v.y*n
vnadd = (v,n) ->
  new V2d v.x+n, v.y+n
V2d::mag = -> Math.sqrt Math.pow(@x,2)+Math.pow(@y,2)
V2d::ndiv = (n) -> new V2d @x/n, @y/n
V2d::norm = -> @ndiv @mag()
class Sprite
  constructor: () ->
    @vel=new V2d()
    @pos=new V2d()
  tick: () ->

class GenericSprite
  constructor: ( @pos=new V2d(0,0), @src ) ->
  render: (ctx) ->
    img=cachedimg(@src)
    ctx.drawImage img, @pos.x, @pos.y-img.naturalHeight

#random float between -1 and 1
randfloat = () -> -1+Math.random()*2

randvec = () ->
  nvec=new V2d randfloat(), randfloat()
  return nvec.norm()

class BoggleParticle extends GenericSprite
  constructor: ( @pos=new V2d(0,0) ) ->
    @pos = vnadd @pos, -8
    @pos.y += 16
    @vel = randvec()
    @src = 'huh.png'
    @life = 50
  tick: () ->
    @life-=1
    if @life<=0 then @KILLME=true
    @pos = vadd @pos, @vel
    @vel = vadd @vel, randvec().ndiv 8

isholdingkey = (key) ->
  key = key.toUpperCase().charCodeAt 0
  key in heldkeys

class BugLady extends Sprite
  constructor: () ->
    super
    @jumping = false
    @attacking = false
    @attacktimeout = 0
    @stuntimeout = 0

BugLady::tick = ->
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  boggling = not walking and @touchingground() and isholdingkey 'x'
  if boggling and Math.random()<0.3
    spritelayer.push new BoggleParticle vnadd ladybug.pos, 32
  if @stuntimeout > 0
    @vel.x = 0
    @stuntimeout -= 1
  @jumping = isholdingkey 'w'
  if @vel.x > 4
    @vel.x = 4
  if @vel.x < -4
    @vel.x = -4
  spriteheight=64
  box=fallbox @
  candidates = hitboxfilter box, bglayer
  if candidates.length > 0 and @vel.y >= 0
    #if topof(fallbox) > bottomof( candidates[0] )
    if @vel.y > 20 then @stuntimeout = 10
    @pos.y = candidates[0].y-spriteheight
    @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    #if topof(fallbox) > bottomof( candidates[0] )
    @pos.y = candidates[0].y+candidates[0].h
    @vel.y = 0
  else
  @attacking=@attacktimeout > 0
  heading = if @facingleft then -1 else 1
  if @attacking
    @vel.y *= 0.7
    @attacktimeout-=1
    @vel.x += heading*0.3
  if @attacking and @touchingground()
    @jumping=true
  @pos = vadd @pos, @vel
  #if candidates.length > 0
  #  @pos.y += 1
  #  @pos.y = candidates[0].y-spriteheight
  #  @vel.y = 0
  if not @touchingground()
    #@vel.x *= 0.99 #AIR DRAG
    @vel.y += 1 #GRAVITY
  if @touchingground()
    #@vel.y = 0
    #@pos.y -= 1
    #if not @touchingground()
    #  @pos.y += 1
    @vel.x = @vel.x*0.5 #GROUND FRICTION
    if Math.abs(@vel.x)<0.0001
      @vel.x = 0
  #super
  if @touchingground() and @jumping
    @vel.y = -13
  lbw=32
  width = 640+lbw
  @avoidwalls()
  @pos.x = ( (@pos.x + (width+lbw)) % (width) )-lbw #WRAPAROUND

randint = (max) -> Math.floor Math.random()*max
randelem = (arr) -> arr[randint(arr.length)]

boggletitle = () ->
  randelem [ "Buggy the boggle champ", "Bushboggler 2013", "Boggle that bush", "Collosal waste of time", "Boggle 2: Electric boggleoo", "Buggy bushboggle", "excuse me wtf are you doing", "Bush it, bush it real good", "Fondly regard flora", "&lt;chievo title unavailable due to trademark infringement&gt;", "Returning a bug to its natural habitat" ]

chievo=false
boggle = () ->
  if chievo then return
  hit= bugbox ladybug
  boxes = fglayer.map (obj) ->
    new Block obj.pos.x, obj.pos.y, 64, 64
  cand=hitboxfilter hit, boxes
  if cand.length > 0
    chievo=true
    #jesus christ how horrifying
    chievbox = $ "<div><span style='display: inline-block; margin-left: 16px'><b>ACHIEVEMENT UNLOCKED</b><br/>#{boggletitle()}</span></div>"
    chievbox.css 'border-radius', '50px'
    chievbox.css 'padding', '8px 32px'
    chievbox.css 'padding-left', '8px'
    chievbox.css 'background-color', '#333'
    chievbox.css 'color', 'white'
    chievbox.css 'font-family', 'sans-serif'
    chievbox.css 'display', 'inline-block'
    chievbox.css 'position', 'absolute'
    chievbox.css 'top', '-100px'
    chievbox.css 'left', '32px'
    chievbox.prepend pic=$ cachedimg 'boggle.png'
    pic.css 'background-color', '#444'
    pic.css 'float', 'left'
    pic.css 'border', '2px solid white'
    pic.css 'border-radius', '64px'
    pic.css 'background-image', 'url(sprites/shrub.png)'
    pic.css 'background-repeat', 'no-repeat'
    pic.css 'background-position', '0px 32px'
    body.append chievbox
    chievbox.animate( top: '32px' ).delay 4000
    chievbox.animate( { top: '-100px'}, { queue: true } ).delay 2000


BugLady::render = (ctx) ->
   offsety=3
   src="lovelyshorter.png"
   vel = Math.abs( @vel.x )
   walking = vel > 0.2
   if walking
     src = if (tickno%12>6) then 'lovelyrun1.png' else 'lovelyrun2.png'
   if not @touchingground()
     src = if @vel.y < 0 then 'lovelyjump.png' else 'lovelycrouch.png'
   if not walking and isholdingkey 's'
     src = 'lovelycrouch.png'
   if not walking and @touchingground() and isholdingkey 'x'
     boggle()
     src = 'boggle.png'
   if @attacking then src = 'viewtiful.png'
   if @stuntimeout > 0
     src = 'lovelyfall.png'
     offsety=6
   img = if @facingleft then cacheflippedimg(src) else cachedimg(src)
   ctx.drawImage img, @pos.x, @pos.y+offsety

hitboxfilter = ( hitbox, rectarray ) ->
  rectarray.filter (box) ->
    rectsoverlap hitbox, box

rectsoverlap = ( recta, rectb ) ->
  if recta.x > rectb.x+rectb.w or
  recta.y > rectb.y+rectb.h or
  recta.x+recta.w < rectb.x or
  recta.y+recta.h < rectb.y
    return false
  else
    return true

bugbox = (bug) ->
  trueh = 64
  offsety=-4
  h = 50
  w = 20 + Math.abs bug.vel.x
  return new Block bug.pos.x+(64/2-w/2), bug.pos.y+(trueh-h), w, h
fallbox = (bug) ->
  box=bugbox bug
  box.y+=bug.vel.y
  return box

ladybug = new BugLady
ladybug.facingleft = false
ladybug.jumping=false

leftof = (box) -> box.x
rightof = (box) -> box.x+box.w
bottomof = (box) -> box.y+box.h
topof = (box) -> box.y

BugLady::avoidwalls = () ->
  collidebox = bugbox ladybug
  blockcandidates=hitboxfilter collidebox, bglayer
  for block in blockcandidates
    #if leftof(collidebox) < rightof(block)
    #  @pos.x++
    notontop = bottomof(collidebox)>topof(block)+8 #some wiggle room hack
    if notontop and leftof(collidebox) < leftof(block)
      @vel.x=0
      @pos.x-=4
    if notontop and rightof(collidebox) > rightof(block)
      @vel.x=0
      @pos.x+=4

BugLady::touchingground = () ->
  touch=false
  collidebox = bugbox ladybug
  blockcandidates=bglayer.filter (block) ->
    rectsoverlap collidebox, block
  for block in blockcandidates
    if collidebox.y+collidebox.h < block.y+block.h
      touch=true
  return touch
  #return collidebox.y+collidebox.h >= 64*8

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

keytapbind 't', ->
  slowmo = not slowmo

somanygrafics = true
keytapbind 'g', ->
  somanygrafics = not somanygrafics

keyholdbind 'j', ->
  ladybug.attacktimeout=3

keyholdbind 'w', ->
  ladybug.jumping=true
keyholdbind 's', ->
keyholdbind 'a', ->
  ladybug.facingleft = true
  amt = if ladybug.touchingground() then 4 else 1
  ladybug.vel.x-=amt
keyholdbind 'd', ->
  ladybug.facingleft = false
  amt = if ladybug.touchingground() then 4 else 1
  ladybug.vel.x+=amt

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

sources = [ 'lovelyshorter.png', 'lovelycrouch.png', 'lovelyrun1.png', 'lovelyrun2.png', 'lovelyjump.png', 'cloud.png', 'lovelyfall.png', 'viewtiful.png', 'boggle.png' ]
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
bglayer.push new Block -64, 64*5-4, 64*12, 100
bglayer.push new Block 64*4, 64*2, 32, 32
bglayer.push new Block 64*5, 64*4, 32, 32
bglayer.push new Block 64*6, 64*3, 32, 32
bglayer.push new Block 32, 64*4, 64*2, 64*2

fglayer = []
spritelayer=[]

placeshrub = (pos) ->
  fglayer.push new GenericSprite pos, 'shrub.png'

placeshrub new V2d( 64*8, 64*5-4 )
placeshrub new V2d( 64*7-48, 64*5-4 )

Layer = () ->
  newlayer = $ "<canvas>"
  return newlayer[0]

brickcanvas = Layer()
brickcanvas.width = canvas[0].width
brickcanvas.height = canvas[0].height
brickctx = brickcanvas.getContext '2d'

drawoutline = (ctx, block, color) ->
  ctx.beginPath()
  ctx.rect block.x, block.y, block.w, block.h
  ctx.lineWidth=1
  ctx.strokeStyle = color
  ctx.stroke()

drawcolls = (ctx) ->
  collidebox = bugbox ladybug
  drawoutline ctx, collidebox, 'blue'
  collidebox = fallbox ladybug
  drawoutline ctx, collidebox, 'orange'
  bglayer.forEach (block) ->
    color=if rectsoverlap(collidebox, block) then 'red' else 'green'
    drawoutline ctx, block, color

render = ->
  ctx.fillRect 0, 0, 640, 640
  if somanygrafics
    tilebackground ctx, x: tickno*-0.2, y: Math.sin(tickno/200)*64, "cloud.png"
  tilebackground brickctx, (x: 0, y: 0), "groundtile.png"
  tmpctx.clearRect 0, 0, 640, 640
  bglayer.forEach (sprite) ->
    sprite.render? tmpctx
  tmpctx.globalCompositeOperation = "source-in"
  tmpctx.drawImage brickcanvas, 0, 0
  tmpctx.globalCompositeOperation = "source-over"
  ctx.drawImage tmpcanvas , 0, 0
  if not somanygrafics
    drawcolls ctx
  spritelayer.forEach (sprite) ->
    sprite.render? ctx
  #ledibag start
  ladybug.render ctx
  fglayer.forEach (sprite) ->
    sprite.render? ctx
  console.log spritelayer.length

#returns elapsed time in ms.
timecall = (func) ->
  starttime = Date.now()
  func()
  Date.now()-starttime

logtimecall = (func) ->
  console.log "#{timecall func} ms."

body.append fpscounter=$ xmltag()

tickwaitms = 20
skipframes = 0
ticktimes = []

looptick = ->
  doomedsprites = spritelayer.filter (sprite) -> sprite.KILLME?
  doomedsprites.forEach (sprite) ->
    spritelayer = arrsansval spritelayer, sprite
  for key in heldkeys
    holdbindings[key]?()
  spritelayer.forEach (sprite) ->
    sprite.tick()?
  ladybug.tick()
  tickno++
  if tickno%(skipframes+1) is 0
    render()
    #skipframes = Math.floor rendertime/tickwaitms
    #fpscounter.html "#{rendertime}ms to render, skipping #{skipframes} frames"


tt=0
mainloop = ->
  ticktime = timecall looptick
  ticktimes.push ticktime
  if ticktimes.length > 16
    tt=Math.round avg ticktimes
    ticktimes=[]
    skipframes = Math.floor tt/tickwaitms
  fps=Math.round 1000/Math.max(tickwaitms,ticktime)
  idealfps=Math.round 1000/tickwaitms
  fpscounter.html "avg tick time: #{tt}ms, skipping #{skipframes} frames, running at approx #{fps} fps (aiming for #{idealfps} fps)"
  #fpscounter.html "tick time: #{ticktime}ms, skipping #{skipframes} frames"
  tickwaitms = if slowmo then 100 else 20
  setTimeout mainloop, Math.max tickwaitms-ticktime, 1

#uses imagesLoaded.js by desandro

preloadcontainer.imagesLoaded 'done', ->
  body.append canvas
  ctx.fillStyle="#008080"
  ctx.fillRect 0, 0, 640, 64
  body.append "<br/><em>there's no crime to fight around here, use WASD to waste time by purposelessly wiggling around,<br/>X to boggle vacantly and J to do some wicked sick totally radical moves</em><br/>"
  body.append xmltag 'a', target: '_blank', href: 'http://www.youtube.com/watch?v=NbVZPu_JM6I', "recommended soundtrack"
  body.append c=$ xmltag()
  c.css 'color', 'silver'
  c.append "<p>psst CAN YOU FIND THE SAUCY SUPER SECRET SAPPHIC SLOPPY SMOOCHING SCENE??</p>"
  c.append answer = $ "<em>(answer: no you can't, because it doesn't exist)</em>"
  answer.css 'transform', 'rotate(180deg)'
  answer.css 'display': 'inline-block'
  mainloop()

