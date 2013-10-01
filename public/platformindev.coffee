# video gem

settings={}
settings.somanygrafics = true
settings.drawsprites = true
settings.slowmo = false
settings.altcostume = true
sourcebaseurl = "./sprites/"

canvas = $ "<canvas>"
body = $ "body"

V = (x=0,y=0) -> new V2d x,y

screensize = V 640, 64*6

parentstage = new PIXI.Stage 0x66FF99
stage = new PIXI.DisplayObjectContainer
parentstage.addChild stage
renderer = PIXI.autoDetectRenderer screensize.x, screensize.y

body.append renderer.view

scale = 1
animate = ->
  cam=cameraoffset().nmul -scale
  stage.position.x = cam.x
  stage.position.y = cam.y
  stage.scale.x = scale
  stage.scale.y = scale
  renderer.render parentstage
  requestAnimFrame animate
requestAnimFrame animate

chievs={}

achieve = (title) ->
  if chievs[title].gotten? then return
  chievs[title].gotten = true
  console.log chievs
  makechievbox chievs[title].pic, randelem chievs[title].text

bogimg = xmltag 'img', src: sourcebaseurl+'boggle.png'

murdertitles = [ "This isn't brave, it's murder", "Jellycide" ]
fieldgoaltitles = [ "3 points field goal", "Into the dunklesphere", "Blasting off again", "pow zoom straight to the moon" ]
falltitles = [ "Fractured spine", "Faceplant", "Dats gotta hoit", "OW FUCK", "pomf =3", "Broken legs", "Have a nice trip", "Ow my organs", "Shattered pelvis", "Bugsplat" ]
boggletitles = [ "Buggy the boggle champ", "Bushboggler 2013", "Boggle that bush", "Collosal waste of time", "Boggle 2: Electric boggleoo", "Buggy bushboggle", "excuse me wtf are you doing", "Bush it, bush it real good", "Fondly regard flora", "&lt;chievo title unavailable due to trademark infringement&gt;", "Returning a bug to its natural habitat", "Bush it to the limit", "Live Free or Boggle Hard", "Identifying bushes, accurate results with simple tools", "Bugtester", "A proper lady (bug)", "Stupid achievement title", "The daily boggle", bogimg+bogimg+bogimg ]
targettitles = [ "there's no achievement for this", "\"Pow, motherfucker, pow\" -socrates", "Expect more. Pay less.", "You're supposed to use arrows you dingus" ]

chievs.fall = pic: "lovelyfall.png", text: falltitles
chievs.kick = pic: "jelly.png", text: fieldgoaltitles
chievs.boggle = pic: "boggle.png", text: boggletitles
chievs.murder = pic: "lovelyshorter.png", text: murdertitles
chievs.target = pic: "target.png", text: targettitles

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


#random float between -1 and 1
randfloat = () -> -1+Math.random()*2

randvec = () -> V randfloat(), randfloat()

randint = (max) -> Math.floor Math.random()*max
randelem = (arr) -> arr[randint(arr.length)]

class Sprite
  constructor: () ->
    @vel=V()
    @pos=V()
  tick: () ->

makechievbox = ( src, text ) ->
  body.append chievbox = $ "<div class=chievbox><span style='display: inline-block; margin-left: 16px'><b>ACHIEVEMENT UNLOCKED</b><br/>#{text}</span></div>"
  chievbox.prepend pic=$ xmltag 'img', src: sourcebaseurl+src
  chievbox.animate( top: '32px' ).delay 4000
  chievbox.animate( { top: '-100px'}, { queue: true } ).delay 2000

class GenericSprite
  constructor: ( @pos=V(), @src ) ->
  render: (ctx) ->
    drawsprite @, @src, @pos, false
    #img=cachedimg(@src)
    #ctx.drawImage img, @pos.x, @pos.y

GenericSprite::gethitbox = ->
  img = cachedimg @src
  new Block @pos.x, @pos.y, img.naturalWidth, img.naturalHeight

class Target extends GenericSprite
  constructor: ( @pos ) ->
    @src = 'target.png'
    @lifetime=-1
    @vel = V()
  collide: ( otherent ) ->
    if otherent instanceof BoggleParticle
      @vel = @vel.vadd otherent.vel.nmul 1/8
    if otherent.attacktimeout? and otherent.attacktimeout > 0 and topof(otherent.gethitbox()) < topof(@.gethitbox())
      @gethitby otherent
  gethitby: ( otherent ) ->
      if @src isnt 'shatteredtarget.png'
        @src = 'shatteredtarget.png'
        @vel = otherent.vel.nmul 1/2
        @lifetime = 10

Target::render = (ctx) ->
  drawsprite @, @src, @pos, false
GenericSprite::cleanup = ->
  removesprite @

canvascircle = ( context, pos, r ) ->
  context.beginPath()
  context.arc pos.x, pos.y, r, 0, 2*Math.PI, false

degstorads = (deg) -> (deg*Math.PI)/180

class Jelly extends GenericSprite
  constructor: ( @pos ) ->
    @lifetime=-1
    @vel = V()
    @src='jelly.png'
    if Math.random()*10<1
      @royal=true
  collide: ( otherent ) ->
    if otherent instanceof Jelly
      @vel.x = (@vel.x+otherent.vel.x)/2
      @pos.x+=randfloat()*2
    if otherent instanceof BoggleParticle
      @vel = @vel.vadd otherent.vel.nmul 1/8
    if otherent instanceof BugLady and otherent.vel.y > 0
      otherent.vel.y *= -0.9
    if otherent.attacktimeout? and otherent.attacktimeout > 0 and topof(otherent.gethitbox()) < topof(@.gethitbox())
      @gethitby otherent
  gethitby: ( otherent ) ->
    @vel.y += otherent.vel.y
    dir=if otherent.facingleft then -1 else 1
    @vel.x += dir*4
    @lifetime = 10
  render: (ctx) ->
    flip = tickno%10<5
    drawsprite @, @src, @pos, flip
  #  img=cachedimg @src
  #  if tickno%10<5 then img=cacheflippedimg @src
  #  ctx.drawImage img, @pos.x, @pos.y
  #  if @royal?
  #    ctx.drawImage cachedimg("crown.png"), @pos.x+8, @pos.y

Jelly::gethitbox = ->
  new Block @pos.x, @pos.y+16, 32, 16

Jelly::touchingground = () ->
  touch=false
  collidebox = @gethitbox()
  blockcandidates=bglayer.filter (block) ->
    rectsoverlap collidebox, block
  for block in blockcandidates
    if collidebox.y+collidebox.h < block.y+block.h
      touch=true
  return touch

entitycount = ( classtype ) ->
  ents = spritelayer.filter (sprite) -> sprite instanceof classtype
  return ents.length

Jelly::tick = () ->
  @avoidwalls()
  if @pos.y < 0
    achieve "kick"
  if @pos.y < 0 or @pos.y > 640
    @KILLME=true
    if entitycount(Jelly) is 1 then achieve "murder"
  if @touchingground()
    @vel.y=0
    @pos.y--
    @jiggle()
  @gravitate()
  @pos=@pos.vadd @vel
Jelly::jiggle = () ->
  @vel.x*=9/10
  if Math.random()*100<50
    @vel.y = -Math.random()*4
    @vel.x += randfloat()*1
Jelly::gravitate = () ->
  if not @touchingground()
    @vel.y++

class BoggleParticle extends GenericSprite
  constructor: ( @pos=V() ) ->
    @pos = @pos.nadd -8
    @pos.y += 16
    @vel = randvec().norm()
    @src = 'huh.png'
    @life = 50
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd randvec().norm().ndiv 8

hueshift = (src,n) ->
  origimg=loadimg src
  pic = Pixastic.process origimg, "hsl", hue: n, saturation: 0, lightness: 0
  return pic

hueshiftmemo = memoize hueshift

rainbowhuh = (n) -> hueshiftmemo 'huh.png', n

BoggleParticle::render = (ctx) ->
    pic=rainbowhuh @life*10
    drawsprite @, 'huh.png', @pos, false
    ctx.drawImage pic, @pos.x, @pos.y

class PchooParticle extends GenericSprite
  constructor: ( @pos=V() ) ->
    @pos = @pos.nadd -8
    @pos.y += 16
    @vel = randvec().norm().ndiv 8
    @life = 20
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd randvec().norm().ndiv 64
  render: (ctx) ->
    ctx.rect @pos.x, @pos.y, 4, 4
    ctx.fillStyle = "cyan"
    ctx.fill()

Target::tick = ->
  @vel = @vel or V 0,0
  @vel = @vel.nmul 7/10
  @pos = @pos.vadd @vel
  if @lifetime is 0 then @KILLME=true
  if @lifetime > 0 then @lifetime--
  if @lifetime is 0 and entitycount(Target) is 1 then achieve "target"

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

BugLady::respawn = ->
  @pos = V()
  @vel = V()

ded=false

entcenter = ( ent ) ->
  hb=ent.gethitbox()
  return V hb.x+hb.w/2, hb.y+hb.h/2

BugLady::blockcollisions = ->
  spriteheight=64
  box=@fallbox()
  candidates = hitboxfilter box, bglayer
  if candidates.length > 0 # and @vel.y >= 0
    if bottomof(@.gethitbox()) <= topof( candidates[0] )
      if @vel.y > 20 then @stuntimeout = 20
      @pos.y = candidates[0].y-spriteheight
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0

BugLady::tick = ->
  unpowered = settings.altcostume
  if unpowered
    @attacktimeout = 0
    @attacking=false
  @holdingboggle = isholdingkey 'x'
  @holdingjump = isholdingkey 'w'
  if @pos.y > 640 #fall in bottomless pit
    if ded then $('#deathmsg').html "<b>WHAT DID I JUST TELL YOU</b>"
    if not ded
      body.prepend "<p id=deathmsg><b>YOU'RE DEAD</b> now don't let me catch you doing that again young lady</p>"
      ded=true
    @respawn()
  #if @attacktimeout > 0 and @touchingground() then @attacktimeout=0
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  boggling = not walking and @touchingground() and @holdingboggle
  if boggling and Math.random()<0.3
    @boggle()
  if @poweruptimeout > 0
    @poweruptimeout--
    @vel = V2d.zero()
  if @stuntimeout > 0
    @stuntimeout--
    achieve "fall"
    @vel = V2d.zero()
  #LIMIT VELOCITY
  vellimit = if @touchingground() then 4 else 5
  @vel.x = mafs.clamp @vel.x, -vellimit, vellimit
  #BLOCK COLLISIONS
  @blockcollisions()
  @attacking=@attacktimeout > 0
  heading = if @facingleft then -1 else 1
  if @attacking
    @vel.y *= 0.7
    @attacktimeout-=1
    @vel.x += heading*0.3
    spritelayer.push new PchooParticle entcenter @
  if @attacking and @punching and @touchingground()
    @vel.x = @vel.x*0.1
  @pos = @pos.vadd @vel
  if not @touchingground()
    @vel.y += 1 #GRAVITY
    if not @holdingjump and @vel.y < 0 then @vel.y /= 2
  if @touchingground()
    @vel.x = @vel.x*0.5 #GROUND FRICTION
    if Math.abs(@vel.x)<0.0001
      @vel.x = 0
  jumpvel = 15
  if unpowered then jumpvel = 12
  if @touchingground() and @jumping
    @vel.y = -jumpvel
  @jumping = false #so we don't repeat by accident yo
  @climbing = @touchingwall()
  @avoidwalls()


BugLady::boggle = () ->
  spritelayer.push new BoggleParticle entcenter @
  hit=ladybug.gethitbox()
  boxes = fglayer.map (obj) -> obj.gethitbox()
  #  new Block obj.pos.x, obj.pos.y, 64, 64
  cand=hitboxfilter hit, boxes
  if cand.length > 0
    achieve "boggle"


BugLady::getsprite = ->
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
    src = 'boggle.png'
  if @attacking then src = 'viewtiful.png'
  if @attacking and @punching then src = 'bugpunch.png'
  if @attacking and @attacktimeout < 2 and @punching then src = 'lovelyrun2.png'
  if @attacking and @kicking then src = 'bugkick.png'
  if @stuntimeout > 0
    src = 'lovelycrouch.png'
  if @stuntimeout > 4
    src = 'lovelyfall.png'
  if @poweruptimeout > 0
    src = 'viewtiful.png'
  if @poweruptimeout > 16
    src = 'boggle.png'
    @facingleft = @poweruptimeout % 10 < 5
  if @poweruptimeout > 32
    src = 'marl/boggle.png'
  if settings.altcostume
    src = "marl/" + src
  if @climbing then src = 'bugclimb1.png'
  return src

BugLady::render = (ctx) ->
  src=@getsprite()
  flip = @facingleft
  offs = V 0, 4
  pos = offs.vadd @pos
  drawsprite @, src, pos, flip

removesprite = ( ent ) ->
  if not ent._pixisprite then return
  stage.removeChild ent._pixisprite

drawsprite = (ent, src, pos, flip) ->
  tex = PIXI.Texture.fromImage sourcebaseurl+src
  if not ent._pixisprite
    sprit = new PIXI.Sprite tex
    ent._pixisprite=sprit
    stage.addChild sprit
  sprit = ent._pixisprite
  img = if flip then cacheflippedimg(src) else cachedimg(src)
  ctx.drawImage img, pos.x, pos.y
  sprit.position.x = pos.x
  if flip then sprit.position.x = pos.x + tex.width
  sprit.position.y = pos.y
  sprit.anchor.x = 0
  sprit.setTexture tex 
  sprit.scale.x = if flip then -1 else 1

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
  h = 40
  w = 20 + Math.abs @vel.x
  return new Block @pos.x+(64/2-w/2), @pos.y+(trueh-h), w, h

BugLady::fallbox = ->
  box=@gethitbox()
  box.y+=@vel.y
  box.x+=@vel.x
  return box

leftof = (box) -> box.x
rightof = (box) -> box.x+box.w
bottomof = (box) -> box.y+box.h
topof = (box) -> box.y

GenericSprite::touchingwall = Sprite::touchingwall = () ->
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, bglayer
  for block in blockcandidates
    notontop = bottomof(collidebox)>topof(block)+8 #some wiggle room hack
    if notontop and leftof(collidebox) < leftof(block)
      return true
    if notontop and rightof(collidebox) > rightof(block)
      return true
  return false

GenericSprite::avoidwalls = Sprite::avoidwalls = () ->
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, bglayer
  for block in blockcandidates
    notontop = bottomof(collidebox)>topof(block)+8 #some wiggle room hack
    ofs=4
    if notontop and leftof(collidebox) < leftof(block)
      @vel.x=0
      @pos.x-=ofs
    if notontop and rightof(collidebox) > rightof(block)
      @vel.x=0
      @pos.x+=ofs

BugLady::touchingground = () ->
  touch=false
  collidebox = @gethitbox()
  blockcandidates=bglayer.filter (block) ->
    rectsoverlap collidebox, block
  for block in blockcandidates
    if bottomof(collidebox) < bottomof(block)
      touch=true
  return touch

class ControlObj
  constructor: ->
    @bindings={}
    @holdbindings={}
    @heldkeys=[]

control = new ControlObj

normalizekey = (key) -> key.toUpperCase().charCodeAt 0

ControlObj::keytapbind = ( key, func ) ->
  control.bindings[normalizekey(key)]=func
ControlObj::keyholdbind = ( key, func ) ->
  control.holdbindings[normalizekey(key)]=func

control.keytapbind '9', -> scale-=0.1
control.keytapbind '0', -> scale+=0.1

control.keytapbind 't', ->
  settings.slowmo = not settings.slowmo

control.keytapbind 'g', -> settings.somanygrafics = not settings.somanygrafics
control.keytapbind 'b', -> settings.drawsprites = not settings.drawsprites

control.keytapbind 'l', ->
  ladybug.jumping=true
  ladybug.kicking=false
  ladybug.punching=false
control.keyholdbind 'l', -> ladybug.attacktimeout=10
#control.keytapbind 'p', -> settings.altcostume = not settings.altcostume

control.keytapbind 'j', ->
  ladybug.punching=true
  ladybug.kicking=false
  ladybug.attacktimeout=10
control.keytapbind 'k', ->
  ladybug.kicking=true
  ladybug.jumping=true
  ladybug.punching=false
  ladybug.attacktimeout=10

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


save = ->
  console.log ladybug
  console.log "saving"
  localStorage["bug"] = JSON.stringify ladybug
  console.log localStorage["bug"]
  localStorage["settings"] = JSON.stringify settings

load = ->
  console.log "loading"
  $.extend ladybug, JSON.parse localStorage["bug"]
  ladybug.pos = $.extend V(), ladybug.pos
  ladybug.vel = V ladybug.vel.x, ladybug.vel.y
  $.extend settings, JSON.parse localStorage["settings"]

control.keytapbind '6', save
control.keytapbind '7', load


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


ctx = canvas[0].getContext '2d'

canvas.attr 'height', screensize.y
canvas.attr 'width', screensize.x
canvas.css 'border', '1px solid black'

tickno = 0

loadimg = (src) ->
  img = new Image
  img.src = sourcebaseurl+src
  return img

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

sources = [ 'cloud.png', 'jelly.png', 'huh.png', 'suit.png', 'censor.png' ]
sources.push 'groundtile.png'
bugsprites=[ 'lovelyshorter.png', 'lovelycrouch.png', 'lovelyrun1.png', 'lovelyrun2.png', 'lovelyjump.png', 'lovelyfall.png', 'viewtiful.png', 'boggle.png', 'bugpunch.png', 'bugkick.png', 'bugclimb1.png', 'bugclimb2.png' ]
marlsprites=bugsprites.map (str) -> "marl/"+str
sources = sources.concat marlsprites, bugsprites

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


Block::render = (ctx) ->
  ctx.beginPath()
  ctx.fillStyle = 'brown'
  ctx.fillRect @x, @y, @w, @h
  
  ent = @
  src = "groundtile.png"
  pos = @pos
  tex = PIXI.Texture.fromImage sourcebaseurl+src
  if not ent._pixisprite
    sprit = new PIXI.TilingSprite tex, @w, @h
    ent._pixisprite=sprit
    stage.addChild sprit
  sprit = ent._pixisprite
  sprit.tilePosition.x = -@x
  sprit.tilePosition.y = -@y
  sprit.position.x = @x
  sprit.position.y = @y

tmpcanvas.width = canvas[0].width
tmpcanvas.height = canvas[0].height
tmpctx = tmpcanvas.getContext '2d'


ladybug = new BugLady
ladybug.facingleft = false
ladybug.jumping=false
ladybug.pos = V 64, 128+64


bglayer = []
bglayer.push new Block -64, 64*5-4, 64*12, 100
bglayer.push new Block 64*4, 64*2, 32, 32
bglayer.push new Block 64*5, 64*4, 32, 32
bglayer.push new Block 64*6, 64*3, 32, 32
bglayer.push new Block 32, 64*4, 64*2, 64*2
bglayer.push new Block 64*12, 64*4, 64*12, 200

fglayer = []
spritelayer=[]

class Sky
  constructor: () ->
Sky::render = () ->
class Cloud extends Sprite
  constructor: () ->
    super()
    @src='cloud.png'
Cloud::render = () ->
  ent = @
  src = @src
  pos = cameraoffset()
  flip = false
  tex = PIXI.Texture.fromImage sourcebaseurl+src
  if not ent._pixisprite
    sprit = new PIXI.TilingSprite tex, screensize.x, screensize.y
    ent._pixisprite=sprit
    stage.addChildAt sprit, 0
  sprit = ent._pixisprite
  img = if flip then cacheflippedimg(src) else cachedimg(src)
  sprit.position.x = pos.x
  sprit.position.y = pos.y
  sprit.setTexture tex 

WORLD={}
WORLD.entities = []
WORLD.entities.push new Cloud()

WORLD.bglayer = bglayer
WORLD.fglayer=fglayer
WORLD.spritelayer=spritelayer

spritelayer=spritelayer.concat [0..10].map ->
  new Target V(640*1.5,64*2).vadd randvec().vmul V 640, 100
spritelayer=spritelayer.concat [0..10].map ->
  new Jelly V(640*1.5,64*2).vadd randvec().vmul V 640, 100

class PowerSuit extends GenericSprite
  constructor: (@pos) ->
    super @pos, 'suit.png'
PowerSuit::collide = ( otherent ) ->
  if otherent instanceof BugLady and @pos.dist(otherent.pos)<32
    @KILLME=true
    otherent.poweruptimeout = 45
    settings.altcostume=false

spritelayer.push new PowerSuit V(128,32)
bglayer.push new Block 128+8, 64+20, 64, 32
bglayer.push new Block 128+8+64, 64+20+32, 32, 32

placeshrub = (pos) ->
  pos = pos.vsub V 0, 32
  fglayer.push new GenericSprite pos, 'shrub.png'

placeshrub V 64*8, 64*5-4
placeshrub V 64*7-48, 64*5-4
placeshrub V 64*9, 64*5-4

Layer = () ->
  newlayer = $ "<canvas>"
  return newlayer[0]

brickcanvas = Layer()
brickcanvas.width = canvas[0].width
brickcanvas.height = canvas[0].height
brickctx = brickcanvas.getContext '2d'

drawoutline = (ctx, block, color) ->
  ctx.beginPath()
  ctx.rect block.x-1/2, block.y-1/2, block.w, block.h
  ctx.lineWidth=1
  ctx.strokeStyle = color
  ctx.stroke()

drawcolls = (ctx) ->
  collidebox = ladybug.gethitbox()
  drawoutline ctx, collidebox, 'blue'
  collidebox = ladybug.fallbox()
  drawoutline ctx, collidebox, 'orange'
  findhitboxesof = [].concat fglayer, spritelayer
  hits=findhitboxesof.map (sprite) -> sprite.gethitbox()
  hitboxes = [].concat bglayer, hits
  hitboxes.forEach (block) ->
    color=if rectsoverlap(collidebox, block) then 'red' else 'green'
    drawoutline ctx, block, color

skylayer = {}
skylayer.render = (ctx) ->
  origtile=cachedimg 'cloud.png'
  tile=origtile
  if ladybug.holdingboggle
    tile = hueshiftmemo 'cloud.png', Math.round(tickno/10)*10
  
  if settings.somanygrafics
    offset=V tickno*-0.2, Math.sin(tickno/200)*64
    tilebackgroundobj ctx, offset, tile

bricklayer = {}
bricklayer.render = (ctx) ->
  if settings.drawsprites
    tilebackground brickctx, V(-camera.pos.x%64,-camera.pos.y%64), "groundtile.png"
  tmpctx.clearRect 0, 0, 640, 640
  bglayer.forEach (sprite) ->
    sprite.render? ctx
  tmpctx.save()
  tmpctx.translate -camera.pos.x, -camera.pos.y
  bglayer.forEach (sprite) ->
    sprite.render? tmpctx
  tmpctx.restore()
  #tmpctx.translate camera.pos.x, camera.pos.y
  tmpctx.globalCompositeOperation = "source-in"
  tmpctx.drawImage brickcanvas, 0, 0
  tmpctx.globalCompositeOperation = "source-over"
  ctx.save()
  ctx.translate camera.pos.x, camera.pos.y
  ctx.drawImage tmpcanvas , 0, 0
  ctx.restore()
  #camera.pos.x, camera.pos.y
  tmpctx.restore()
  
spritedrawhitbox = (ctx, sprite) ->
  hb=sprite.gethitbox()
  offs=0.5
  vec=V hb.x, hb.y
  vec = vec.op(Math.round).nadd offs
  [hb.x,hb.y]=vec.toarr()
  hb.w=Math.round(hb.w)-offs*2
  hb.h=+Math.round(hb.h)-offs*2
  drawoutline ctx, hb, 'black'

camera={}
camera.pos=V()

PIXI.DisplayObjectContainer
cameraoffset = ->
  tmppos = ladybug.pos.nadd(64).vsub screensize.ndiv 2
  tmppos.y = mafs.clamp camera.pos.y, -screensize.y, 0
  return tmppos

render = ->
  ctx.fillStyle="skyblue"
  ctx.fillRect 0, 0, 640, 640
  ctx.save()
  skylayer.render ctx
  camera.pos = cameraoffset()
  offs = -camera.pos.x
  ctx.translate offs, -camera.pos.y
  bricklayer.render ctx
  if not settings.somanygrafics then drawcolls ctx
  renderables = [].concat spritelayer, [ladybug], fglayer
  if settings.drawsprites
    renderables.forEach (sprite) -> sprite.render? ctx
  else
    renderables.forEach (sprite) -> spritedrawhitbox ctx, sprite
  WORLD.entities.forEach (ent) -> ent.render?()
  ctx.restore()

#returns elapsed time in ms.
timecall = (func) ->
  starttime = Date.now()
  func()
  Date.now()-starttime

logtimecall = (func) ->
  console.log "#{timecall func} ms."


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
  spritelayer.forEach (sprite) ->
    checkcolls sprite, arrsansval spritelayer, sprite
  
  #remove entities that requested death
  doomedsprites = spritelayer.filter (sprite) -> sprite.KILLME?
  doomedsprites.forEach (sprite) ->
    sprite.cleanup?()
    spritelayer = arrsansval spritelayer, sprite
  
  spritelayer.forEach (sprite) -> sprite.tick?()
  ladybug.tick()
  WORLD.entities.forEach (ent) -> ent.tick?()
  if skipframes is 0 or tickno%(skipframes+1) is 0
    render()
  tickno++

fpscounter=$ xmltag()
tt=0
mainloop = ->
  ticktime = timecall looptick
  ticktimes.push ticktime
  if ticktimes.length > 16
    tt=Math.round mafs.avg ticktimes
    ticktimes=[]
    skipframes = Math.floor tt/tickwaitms
  fps=Math.round 1000/Math.max(tickwaitms,ticktime)
  idealfps=Math.round 1000/tickwaitms
  fpscounter.html "avg tick time: #{tt}ms, skipping #{skipframes} frames, running at approx #{fps} fps (aiming for #{idealfps} fps)"
  #fpscounter.html "tick time: #{ticktime}ms, skipping #{skipframes} frames"
  tickwaitms = if settings.slowmo then 1000/4 else 1000/50
  setTimeout mainloop, Math.max tickwaitms-ticktime, 1

#uses imagesLoaded.js by desandro

preloadcontainer.imagesLoaded 'done', ->
  body.append "<br/><em>there's no crime to fight around here, use WASD to waste time by purposelessly wiggling around,<br/>X to boggle vacantly and JKL to do some wicked sick totally radical moves</em><br/><p>G and T for some debug dev mode shit</p>"
  body.append fpscounter
  mainloop()

body.append canvas
canvas.mousedown (e) ->
  coffs=$(canvas).offset()
  adjusted = V e.pageX-coffs.left, e.pageY-coffs.top
  adjusted = adjusted.vadd camera.pos
  adjusted = adjusted.op Math.round
  bglayer.push new Block adjusted.x, adjusted.y, 32, 32


