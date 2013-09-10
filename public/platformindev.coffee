#vidyon gem

slowmo = false

canvas = $ "<canvas>"
body = $ "body"

sourcebaseurl = "./sprites/"

chievs={}

xmlatts = (atts) ->
  (" #{key}=\"#{val}\"" for own key,val of atts).join() 
xmltag = (type="div", atts={}, body="") ->
  "<#{type}#{xmlatts atts}>#{body}</#{type}>"

#ARRAY HELPER FUNCS
arrclone = (arr) -> arr.slice 0
arrsansval = (arr,val) ->
 #DEVNOTE: unsure whether i should always return a clone,
 # or just the original if there's nothing removed
 newarr=arrclone arr
 if not val in arr then return newarr
 i=newarr.indexOf val
 newarr.splice i, 1
 return newarr

#mafs
add = (a,b) -> a+b
sum = (arr) -> arr.reduce add, 0
avg = (arr) -> sum(arr)/arr.length

class V2d
  constructor: ( @x=0, @y=0 ) ->

V = (x,y) -> new V2d x,y
V2d::clone = -> V @x, @y

ZEROVEC=V()
vadd = (v,u) -> V add(v.x,u.x), add(v.y,u.y)
vsub = (v,u) -> V v.x-u.x, v.y-u.y
vmul = (v,u) -> V v.x*u.x, v.y*u.y
vnmul = (v,n) -> V v.x*n, v.y*n
vnadd = (v,n) -> V v.x+n, v.y+n
vdist = (v,u) -> vsub(v,u).mag()

V2d::vadd = (v) -> vadd @,v
V2d::vsub = (v) -> vsub @,v
V2d::vnmul = (n) -> vnmul @,n
V2d::vnadd = (n) -> vnadd @,n
V2d::vmul = (u) -> vmul @,u
V2d::op = (op) -> V op(@x), op(@y)

V2d::mag = -> Math.sqrt Math.pow(@x,2)+Math.pow(@y,2)
V2d::ndiv = (n) -> V @x/n, @y/n
V2d::norm = -> @ndiv @mag()

#random float between -1 and 1
randfloat = () -> -1+Math.random()*2

randvec = () ->
  #return #nvec.norm()
  V randfloat(), randfloat()

randint = (max) -> Math.floor Math.random()*max
randelem = (arr) -> arr[randint(arr.length)]


class Sprite
  constructor: () ->
    @vel=V()
    @pos=V()
  tick: () ->

makechievbox = ( src, text ) ->
  #jesus christ how horrifying
  chievbox = $ "<div><span style='display: inline-block; margin-left: 16px'><b>ACHIEVEMENT UNLOCKED</b><br/>#{text}</span></div>"
  chievbox.css 'border-radius', '50px'
  chievbox.css 'padding', '8px 32px 8px 8px'
  chievbox.css 'background-color', '#333'
  chievbox.css 'color', 'white'
  chievbox.css 'font-family', 'sans-serif'
  chievbox.css 'display', 'inline-block'
  chievbox.css 'position', 'absolute'
  chievbox.css 'top', '-100px'
  chievbox.css 'left', '32px'
  chievbox.prepend pic=$ xmltag 'img', src: sourcebaseurl+src
  pic.css 'background-color', '#444'
  pic.css 'float', 'left'
  pic.css 'border', '2px solid white'
  pic.css 'border-radius', '64px'
  body.append chievbox
  chievbox.animate( top: '32px' ).delay 4000
  chievbox.animate( { top: '-100px'}, { queue: true } ).delay 2000


class GenericSprite
  constructor: ( @pos=V(), @src ) ->
  render: (ctx) ->
    img=cachedimg(@src)
    ctx.drawImage img, @pos.x, @pos.y
GenericSprite::gethitbox = () ->
  new Block @pos.x, @pos.y, 32, 32

class Target extends GenericSprite
  constructor: ( @pos ) ->
    @src = 'target.png'
    @lifetime=-1
    @vel = V()
  collide: ( otherent ) ->
    if otherent instanceof BoggleParticle
      @vel = @vel.vadd otherent.vel.vnmul 1/8
    if otherent.attacktimeout? and otherent.attacktimeout > 0 and topof(otherent.gethitbox()) < topof(@.gethitbox())
      @gethitby otherent
  gethitby: ( otherent ) ->
      if @src isnt 'shatteredtarget.png'
        @src = 'shatteredtarget.png'
        @vel = otherent.vel.vnmul 1/2
        @lifetime = 10
  render: (ctx) ->
    img=cachedimg(@src)
    ctx.drawImage img, @pos.x, @pos.y


GenericSprite::gethitbox = ->
  img = cachedimg @src
  new Block @pos.x, @pos.y, img.naturalWidth, img.naturalHeight

class BoggleParticle extends GenericSprite
  constructor: ( @pos=V() ) ->
    @pos = @pos.vnadd -8
    @pos.y += 16
    @vel = randvec().norm()
    @src = 'huh.png'
    @life = 50
  tick: () ->
    @life-=1
    if @life<=0 then @KILLME=true
    @pos = vadd @pos, @vel
    @vel = vadd @vel, randvec().norm().ndiv 8
    checkcolls @, spritelayer

Target::tick = ->
  @vel = @vel or V 0,0
  @vel = @vel.vnmul 7/10
  @pos = vadd @pos, @vel
  if @lifetime is 0 then @KILLME=true
  if @lifetime > 0 then @lifetime--

isholdingkey = (key) ->
  key = key.toUpperCase().charCodeAt 0
  key in control.heldkeys

class BugLady extends Sprite
  constructor: () ->
    super
    @jumping = false
    @attacking = false
    @attacktimeout = 0
    @stuntimeout = 0

BugLady::tick = ->
  @holdingboggle = isholdingkey 'x'
  if @pos.y > 640 #fall in bottomless pit
    if not ded
      body.prepend "<p><b>YOU'RE DEAD</b> now don't let me catch you doing that again young lady</p>"
      ded=true
    @pos = V()
    @vel = V()

  if @attacktimeout > 0 and @touchingground()
    @attacktimeout=0
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  boggling = not walking and @touchingground() and @holdingboggle
  if boggling and Math.random()<0.3
    spritelayer.push new BoggleParticle ladybug.pos.vnadd 32
  if @stuntimeout > 0
    if not chievs.fall?
      chievs.fall=true
      makechievbox "lovelyfall.png", randelem falltitles
    @vel.x = 0
    @vel.y = 0
    @stuntimeout -= 1
  #LIMIT VELOCITY
  vellimit = if @touchingground() then 4 else 5
  if @vel.x > vellimit
    @vel.x = vellimit
  if @vel.x < -vellimit
    @vel.x = -vellimit
  spriteheight=64
  box=fallbox @
  candidates = hitboxfilter box, bglayer
  if candidates.length > 0 and @vel.y >= 0
    if @vel.y > 20 then @stuntimeout = 20
    @pos.y = candidates[0].y-spriteheight
    @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0
  else
  @attacking=@attacktimeout > 0
  heading = if @facingleft then -1 else 1
  if @attacking
    @vel.y *= 0.7
    @attacktimeout-=1
    @vel.x += heading*0.3
  @pos = vadd @pos, @vel
  if not @touchingground()
    @vel.y += 1 #GRAVITY
  if @touchingground()
    @vel.x = @vel.x*0.5 #GROUND FRICTION
    if Math.abs(@vel.x)<0.0001
      @vel.x = 0
  if @touchingground() and @jumping
    @vel.y = -13
  @jumping = false #so we don't repeat by accident yo
  lbw=32
  width = 640+lbw
  @avoidwalls()
  #@pos.x = ( (@pos.x + (width+lbw)) % (width) )-lbw #WRAPAROUND

bogimg = xmltag 'img', src: sourcebaseurl+'boggle.png'


falltitles = [ "Fractured spine", "Faceplant", "Dats gotta hoit", "OW FUCK", "pomf =3", "Broken legs", "Have a nice trip", "Ow my organs", "Shattered pelvis", "Bugsplat" ]
boggletitles = [ "Buggy the boggle champ", "Bushboggler 2013", "Boggle that bush", "Collosal waste of time", "Boggle 2: Electric boggleoo", "Buggy bushboggle", "excuse me wtf are you doing", "Bush it, bush it real good", "Fondly regard flora", "&lt;chievo title unavailable due to trademark infringement&gt;", "Returning a bug to its natural habitat", "Bush it to the limit", "Live Free or Boggle Hard", "Identifying bushes, accurate results with simple tools", "Bugtester", "A proper lady (bug)", "Stupid achievement title", "The daily boggle", bogimg+bogimg+bogimg ]


boggle = () ->
  if chievs.boggle? then return
  hit=ladybug.gethitbox()
  boxes = fglayer.map (obj) -> obj.gethitbox()
  #  new Block obj.pos.x, obj.pos.y, 64, 64
  cand=hitboxfilter hit, boxes
  if cand.length > 0
    chievs.boggle=true
    makechievbox 'boggle.png', randelem boggletitles


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
   if not walking and @touchingground() and @holdingboggle
     boggle()
     src = 'boggle.png'
   if @attacking then src = 'viewtiful.png'
   if @stuntimeout > 0
     src = 'lovelycrouch.png'
   if @stuntimeout > 4
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

BugLady::gethitbox = ->
  trueh = 64
  offsety=-4
  h = 50
  w = 20 + Math.abs @vel.x
  return new Block @pos.x+(64/2-w/2), @pos.y+(trueh-h), w, h

fallbox = (bug) ->
  box=bug.gethitbox()
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
  collidebox = ladybug.gethitbox()
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
  collidebox = ladybug.gethitbox()
  blockcandidates=bglayer.filter (block) ->
    rectsoverlap collidebox, block
  for block in blockcandidates
    if collidebox.y+collidebox.h < block.y+block.h
      touch=true
  return touch

class ControlObj
  constructor: ->
    @bindings={}
    @holdbindings={}
    @heldkeys=[]

control = new ControlObj

control.bindings = {}
control.holdbindings = {}
control.heldkeys = []

normalizekey = (key) -> key.toUpperCase().charCodeAt 0

ControlObj::keytapbind = ( key, func ) ->
  control.bindings[normalizekey(key)]=func
ControlObj::keyholdbind = ( key, func ) ->
  control.holdbindings[normalizekey(key)]=func

control.keytapbind 't', ->
  slowmo = not slowmo

somanygrafics = true
drawsprites = true

control.keytapbind 'g', -> somanygrafics = not somanygrafics
control.keytapbind 'b', -> drawsprites = not drawsprites

control.keytapbind 'j', -> ladybug.jumping=true
control.keyholdbind 'j', -> ladybug.attacktimeout=10

up = -> ladybug.jumping=true
down = ->
left = ->
  ladybug.facingleft = true
  amt = if ladybug.touchingground() then 3 else 1
  ladybug.vel.x-=amt
right = ->
  ladybug.facingleft = false
  amt = if ladybug.touchingground() then 3 else 1
  ladybug.vel.x+=amt

availableactions = [ up, down, left, right ]

control.keyholdbind 'w', up
control.keyholdbind 's', down
control.keyholdbind 'a', left
control.keyholdbind 'd', right

@CONTROL = control

$(document).bind 'keydown', (e) ->
  key = e.which
  control.bindings[key]?()
  if not (key in control.heldkeys)
    control.heldkeys.push key
$(document).bind 'keyup', (e) ->
  key = e.which
  control.heldkeys = arrsansval control.heldkeys, key

tmpcanvasjq = $ "<canvas>"
tmpcanvas = tmpcanvasjq[0]

ladybug.pos = V 64, 100

ctx = canvas[0].getContext '2d'

canvas.attr 'height', 64*6
canvas.attr 'width', 640
canvas.css 'border', '1px solid black'

tickno = 0

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

tilebackgroundobj = ( ctx, offset, imgobj ) ->
  offset = offset.op Math.round
  cw = canvas[0].width
  ch = canvas[0].height
  img = imgobj
  if img.width == 0 or img.height == 0 then return
  horiznum = Math.floor cw/img.width
  vertnum = Math.floor ch/img.height
  [-1...horiznum+1].forEach (n) ->
    [-1..vertnum+1].forEach (m) ->
      finalx = n*img.width+(offset.x%img.width)
      finaly = m*img.height+(offset.y%img.height)
      ctx.drawImage img, finalx, finaly

tilebackground = ( ctx, offset, src ) ->
  tilebackgroundobj ctx, offset, cachedimg src

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
bglayer.push new Block 64*12, 64*4, 64*12, 200

fglayer = []
spritelayer=[]

spritelayer=spritelayer.concat [0..10].map ->
  new Target V(640*1.5,64*2).vadd randvec().vmul V 640, 100

placeshrub = (pos) ->
  pos = vsub pos, V 0, 32
  fglayer.push new GenericSprite pos, 'shrub.png'

placeshrub V 64*8, 64*5-4
placeshrub V 64*7-48, 64*5-4

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
  collidebox = ladybug.gethitbox()
  drawoutline ctx, collidebox, 'blue'
  collidebox = fallbox ladybug
  drawoutline ctx, collidebox, 'orange'
  findhitboxesof = [].concat spritelayer, fglayer
  hits=findhitboxesof.map (sprite) -> sprite.gethitbox()
  hitboxes = [].concat bglayer, hits
  hitboxes.forEach (block) ->
    color=if rectsoverlap(collidebox, block) then 'red' else 'green'
    drawoutline ctx, block, color

render = ->
  ctx.fillStyle="skyblue"
  ctx.save()
  ctx.fillRect 0, 0, 640, 640
  if somanygrafics
    tilebackground ctx, V( tickno*-0.2, Math.sin(tickno/200)*64), "cloud.png"
  cw = 640
  offs = -(ladybug.pos.x-cw/2)
  ctx.translate offs, 0
  if drawsprites
    tilebackground brickctx, V(), "groundtile.png"
  tmpctx.clearRect 0, 0, 640, 640
  bglayer.forEach (sprite) ->
    sprite.render? ctx
  bglayer.forEach (sprite) ->
    sprite.render? tmpctx
  tmpctx.globalCompositeOperation = "source-in"
  tmpctx.drawImage brickcanvas, 0, 0
  tmpctx.globalCompositeOperation = "source-over"
  ctx.drawImage tmpcanvas , 0, 0
  if not somanygrafics
    drawcolls ctx
  renderables = [].concat spritelayer, [ladybug], fglayer
  if drawsprites
    renderables.forEach (sprite) ->
      sprite.render? ctx
  else
    renderables.forEach (sprite) ->
      hb=sprite.gethitbox()
      offs=0.5
      hb.x=offs+Math.round hb.x
      hb.y=offs+Math.round hb.y
      hb.w=Math.round(hb.w)-offs*2
      hb.h=+Math.round(hb.h)-offs*2
      drawoutline ctx, hb, 'black'
  ctx.restore()


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


checkcolls = ( ent, otherents ) ->
  bawks = ent.gethitbox()
  otherents.forEach (target) ->
    if target is ent then return
    targethitbox = target.gethitbox()
    if rectsoverlap bawks, targethitbox
      target.collide?(ent)

looptick = ->
  for key in control.heldkeys
    control.holdbindings[key]?()
  checkcolls ladybug, spritelayer
  
  #remove entities that requested death
  doomedsprites = spritelayer.filter (sprite) -> sprite.KILLME?
  doomedsprites.forEach (sprite) ->
    spritelayer = arrsansval spritelayer, sprite
  
  spritelayer.forEach (sprite) -> sprite.tick?()
  ladybug.tick()
  if skipframes is 0 or tickno%(skipframes+1) is 0
    render()
  tickno++

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
  tickwaitms = if slowmo then 1000/4 else 1000/60
  setTimeout mainloop, Math.max tickwaitms-ticktime, 1

#uses imagesLoaded.js by desandro

preloadcontainer.imagesLoaded 'done', ->
  body.append "<br/><em>there's no crime to fight around here, use WASD to waste time by purposelessly wiggling around,<br/>X to boggle vacantly and J to do some wicked sick totally radical moves</em><br/><p>G and T for some debug dev mode shit</p>"
  mainloop()

body.append canvas
canvas.mousedown (e) ->
  coffs=$(canvas).offset()
  adjusted = V e.pageX-coffs.left, e.pageY-coffs.top
  bglayer.push new Block Math.round(-320+adjusted.x+ladybug.pos.x), adjusted.y, 32, 32

