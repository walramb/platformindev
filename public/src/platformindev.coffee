# video gem

settings={}
settings.drawsprites = true
settings.slowmo = false
settings.altcostume = true
settings.beanmode = false
settings.muted = true
settings.paused = false
settings.volume = 0.2
settings.decemberween = true

sourcebaseurl = "./sprites/"
audiobaseurl="./audio/"

body = $ "body"

V = (x=0,y=0) -> new V2d x,y
PP = (x,y) -> new PIXI.Point x,y
VTOPP = (v) -> PP v.x, v.y

screensize = V 64*10, 64*6

playsound = ( src ) ->
  if settings.muted then return
  snd = new Audio audiobaseurl+src
  snd.volume = settings.volume
  snd.play()

parentstage = new PIXI.Stage 0x66FF99
stage = new PIXI.DisplayObjectContainer
parentstage.addChild stage
hitboxlayer = new PIXI.DisplayObjectContainer
stage.addChild hitboxlayer
renderer = PIXI.autoDetectRenderer screensize.x, screensize.y

pausescreen = new PIXI.Graphics()
pausescreen.beginFill 0x000000
pausescreen.drawRect 0, 0, screensize.x, screensize.y
pausescreen.alpha = 0.5

pausetext = new PIXI.Text "PAUSED", { font: "32px Arial", fill:"white", strokeThickness: 8, stroke:'red'}
pausetext.position = VTOPP screensize.ndiv 2
pausetext.anchor = PP 1/2, 1

pausescreen.addChild pausetext
pausetext = new PIXI.Text "GO GET SOME SNACKS\nPERHAPS A CARBONATED SODA", { font: "16px Arial", fill:"white"}
pausetext.position = VTOPP screensize.ndiv(2).vadd(V(0,64))
pausetext.anchor = PP 1/2, 0

pausescreen.addChild pausetext

tex = PIXI.Texture.fromImage sourcebaseurl+'titleplaceholder.png'
titlescreen = new PIXI.Sprite tex


body.append renderer.view

scale = 1
animate = ->
  cam=cameraoffset().nmul -scale
  stage.position = VTOPP cam
  stage.scale = PP scale, scale
  renderer.render parentstage
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
  render: ->
    anchor = @anchor or V(0,0)
    flip=false
    pos=relativetobox(@gethitbox(),anchor)
    drawsprite @, @src, pos, flip, anchor
    #drawsprite @, @src, @pos, false
GenericSprite::cleanup = ->
  removesprite @

class Hat extends GenericSprite
  constructor: () ->
    @src = "hat.png"
    @pos=V()
    @anchor = V 1/2, 1.5
    console.log "HAT ACQUIRED"
Hat::tick = ->
  @pos = ladybug.pos

GenericSprite::gethitbox = ->
  size=V 32, 32
  anchor = @anchor or V(0,0)
  makebox @pos, size, anchor

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

class Jelly extends GenericSprite
  constructor: ( @pos ) ->
    @lifetime=-1
    @vel = V()
    @src='jelly.png'
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
  render: ->
    flip = tickno%10<5
    anchor = V 1/2, 1
    pos=relativetobox(@gethitbox(),anchor)
    drawsprite @, @src, pos, flip, anchor

Jelly::gethitbox = ->
  return makebox @pos, V(32,16), bottomcenter

degstorads = (degs) -> degs*Math.PI/180

GenericSprite::touchingground = () ->
  touch=false
  collidebox = @gethitbox()
  blockcandidates=bglayer.filter (block) ->
    collidebox.overlaps block
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
GenericSprite::gravitate = () ->
  if not @touchingground()
    @vel.y++

relativetobox = ( box, anchor ) ->
  pos = V box.x, box.y
  size = V box.w, box.h
  pos = pos.vadd size.vmul anchor
  return pos

class Thug extends GenericSprite
  constructor: ( @pos ) ->
    @lifetime=-1
    @vel = V()
    @src='bugthug.png'
    @facingleft = false
  render: ->
    flip = not @facingleft
    box = @gethitbox()
    anchor = V 1/2, 1
    pos = relativetobox box, anchor
    sprit=drawsprite @, @src, pos, flip
    sprit.anchor = VTOPP anchor
bottomcenter = V 1/2, 1
Thug::gethitbox = ->
  return makebox @pos, V(24,64), bottomcenter
GenericSprite::friction = ->
  @vel.x *= 0.9
Thug::tick = () ->
  @pos = @pos.vadd @vel
  @avoidwalls()
  @blockcollisions()
  if @touchingground()
    @pos.y--
    @vel.y=0
    @friction()
  @gravitate()
  @getsprite()
Thug::getsprite = ->
  if @lifetime == 0 and @touchingground() then @src = 'bugthug.png'
  if @lifetime > 0
    @lifetime--
    @src="bugthugoof.png"
Thug::collide = ( otherent ) ->
    if otherent instanceof BoggleParticle
      @vel = @vel.vadd otherent.vel.nmul 1/8
    if otherent.attacktimeout? and otherent.attacktimeout > 0
      @gethitby otherent
Thug::gethitby = ( otherent ) ->
    @vel.y += otherent.vel.y
    dir=if otherent.facingleft then -1 else 1
    @vel.x += dir*1
    @lifetime = 10
GenericSprite::blockcollisions = ->
  box=@gethitbox()
  spriteheight=box.h
  candidates = hitboxfilter box, bglayer
  candidates.forEach (candidate) =>
    if bottomof(@.gethitbox()) >= topof( candidate )
      @pos.y = candidate.y
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0

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

BoggleParticle::render = ->
    drawsprite @, 'huh.png', @pos, false

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
  render: ->

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

entcenter = ( ent ) ->
  hb=ent.gethitbox()
  return V hb.x+hb.w/2, hb.y+hb.h/2

BugLady::blockcollisions = ->
  spriteheight=64
  box=@fallbox()
  candidates = hitboxfilter box, bglayer
  candidates.forEach (candidate) =>
    if bottomof(@.gethitbox()) <= topof( candidate )
      if @vel.y > 20 then @stuntimeout = 20
      @pos.y = candidate.y
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0

BugLady::checkcontrols = ->
  @holdingboggle = isholdingkey 'x'
  @holdingjump = isholdingkey 'w'

BugLady::cancelattack = ->
  @attacktimeout = 0
  @attacking=false

BugLady::outofbounds = ->
  @pos.y > 640

BugLady::kill = ->
  if @ded then $('#deathmsg').html "<b>WHAT DID I JUST TELL YOU</b>"
  if not @ded
    body.prepend "<p id=deathmsg><b>YOU'RE DEAD</b> now don't let me catch you doing that again young lady</p>"
    @ded=true
  @respawn()

BugLady::tick = ->
  unpowered = settings.altcostume
  if unpowered then @cancelattack()
  @checkcontrols()
  if @outofbounds() then @kill()
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  boggling = not walking and @touchingground() and @holdingboggle
  if boggling and Math.random()<0.3 then @boggle()
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
  @avoidwalls()
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
    @gravitate()
    if not @holdingjump and @vel.y < 0 then @vel.y /= 2
  if @touchingground()
    @friction()
  jumpvel = if unpowered then 12 else 16
  @jumpimpulse jumpvel
  @jumping = false #so we don't repeat by accident yo
  @climbing = @touchingwall()

BugLady::jumpimpulse = (jumpvel) ->
  if @touchingground() and @jumping
    @vel.y = -jumpvel

BugLady::gravitate = () ->
  @vel.y += 1
BugLady::friction = () ->
  @vel.x = @vel.x*0.5
  if Math.abs(@vel.x)<0.0001
    @vel.x = 0

BugLady::boggle = () ->
  spritelayer.push new BoggleParticle entcenter @
  hit=ladybug.gethitbox()
  boxes = fglayer.map (obj) -> obj.gethitbox()
  #  new Block obj.pos.x, obj.pos.y, 64, 64
  cand=hitboxfilter hit, boxes
  if cand.length > 0
    achieve "boggle"

BugLady::getsprite = ->
  if settings.beanmode then return "bugbean.png"
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
  if @stuntimeout > 0 then src = 'lovelycrouch.png'
  if @stuntimeout > 4 then src = 'lovelyfall.png'
  if @poweruptimeout > 0 then src = 'viewtiful.png'
  if @poweruptimeout > 16
    src = 'boggle.png'
    @facingleft = @poweruptimeout % 10 < 5
  if @poweruptimeout > 32 then src = 'marl/boggle.png'
  if settings.altcostume then src = "marl/" + src
  if @climbing then src = 'bugclimb1.png'
  return src

BugLady::render = ->
  vel = Math.abs( @vel.x )
  walking = vel > 1
  src=@getsprite()
  flip = @facingleft
  if settings.beanmode and walking then flip = tickno % 8 < 4
  offs = V 0, 4
  anchor = V 1/2, 1
  pos = relativetobox @gethitbox(), anchor
  pos = offs.vadd pos
  sprit=drawsprite @, src, pos, flip, anchor
  if src == 'boggle.png'
    sprit.rotation=degstorads randfloat()*4
  else
    sprit.rotation=0

removesprite = ( ent ) ->
  if not ent._pixisprite then return
  stage.removeChild ent._pixisprite

initsprite = (ent,tex) ->
  sprit = new PIXI.Sprite tex
  ent._pixisprite=sprit
  stage.addChild sprit
  return sprit

drawsprite = (ent, src, pos, flip, anchor=V()) ->
  tex = PIXI.Texture.fromImage sourcebaseurl+src
  if not ent._pixisprite
    initsprite ent,tex
  sprit = ent._pixisprite
  sprit.position = VTOPP pos
  sprit.anchor = VTOPP anchor
  sprit.setTexture tex 
  sprit.scale.x = if flip then -1 else 1
  return sprit


class Block
  constructor: (@x,@y,@w,@h) -> @pos = V @x, @y
Block::overlaps = ( rectb ) ->
  recta=@
  if recta.x > rectb.x+rectb.w or
  recta.y > rectb.y+rectb.h or
  recta.x+recta.w < rectb.x or
  recta.y+recta.h < rectb.y
    return false
  else
    return true
hitboxfilter = ( hitbox, rectarray ) ->
  rectarray.filter (box) ->
    hitbox.overlaps box

makebox = (position, dimensions, anchor) ->
  truepos = position.vsub dimensions.vmul anchor
  return new Block truepos.x, truepos.y, dimensions.x, dimensions.y

bottomcenter = V 1/2, 1
BugLady::gethitbox = ->
  w=16
  h=32
  return makebox @pos, V(w,h), bottomcenter

BugLady::fallbox = ->
  box=@gethitbox()
  box.y+=@vel.y
  box.x+=@vel.x
  return box

leftof = (box) -> box.x
rightof = (box) -> box.x+box.w
bottomof = (box) -> box.y+box.h
topof = (box) -> box.y

Block::left = -> leftof @
Block::right = -> rightof @
Block::bottom = -> bottomof @
Block::top = -> topof @
blocksatpoint = (blocks, p) ->
  blocks.filter (box) -> box.x <= p.x and box.y <= p.y and box.x+box.w >= p.x and box.y+box.h >= p.y

GenericSprite::touchingwall = Sprite::touchingwall = () ->
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, bglayer
  for block in blockcandidates
    notontop = bottomof(collidebox)>topof(block)
    if notontop and collidebox.left() < block.left()
      return true
    if notontop and collidebox.right() > block.right()
      return true
  return false

GenericSprite::avoidwalls = Sprite::avoidwalls = () ->
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, bglayer
  for block in blockcandidates
    notontop = bottomof(collidebox)>topof(block)
    ofs=1
    if notontop and leftof(collidebox) < leftof(block)
      @vel.x=0
      @pos.x-=ofs
    if notontop and rightof(collidebox) > rightof(block)
      @vel.x=0
      @pos.x+=ofs

BugLady::touchingground = () ->
  touch=false
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, bglayer
  for block in blockcandidates
    if bottomof(collidebox) < bottomof(block)
      touch=true
  return touch

class PowerSuit extends GenericSprite
  constructor: (@pos) ->
    super @pos, 'suit.png'
PowerSuit::collide = ( otherent ) ->
  if otherent instanceof BugLady
    @KILLME=true
    otherent.poweruptimeout = 45
    settings.altcostume=false


class ControlObj
  constructor: ->
    @bindings={}
    @holdbindings={}
    @heldkeys=[]
    @bindingnames={}

control = new ControlObj

normalizekey = (key) -> key.toUpperCase().charCodeAt 0

ControlObj::keytapbind = ( key, func ) ->
  @bindings[normalizekey(key)]=func

ControlObj::keytapbindname = ( key, name, func ) ->
  @bindingnames[normalizekey(key)]=name
  console.log @bindingnames
  @keytapbind key, func

ControlObj::keyholdbind = ( key, func ) ->
  @holdbindings[normalizekey(key)]=func

control.keytapbindname '9', 'zoom out', -> scale-=0.1
control.keytapbindname '0', 'zoom in', -> scale+=0.1

launchFullScreen = (elm) ->
  elm.requestFullScreen?()
  elm.mozRequestFullScreen?()
  elm.webkitRequestFullScreen?()
cancelFullScreen = ->
  document.cancelFullScreen?()
  document.mozCancelFullScreen?()
  document.webkitCancelFullScreen?()
toggleFullScreen = (elm) ->
  isfullscreen = document.fullScreen || document.mozFullScreen || document.webkitFullScreen
  if isfullscreen
    cancelFullScreen()
  else
    launchFullScreen elm

control.keytapbindname 'y', 'toggle fullscreen', ->
  toggleFullScreen renderer.view
control.keytapbindname 'p', 'pause', ->
  playsound "pause.wav"
  settings.paused = not settings.paused
  if settings.paused then parentstage.addChild pausescreen
  if not settings.paused then parentstage.removeChild pausescreen
  
control.keytapbindname 't', 'underclock/slowmo', ->
  settings.slowmo = not settings.slowmo

control.keytapbindname 'g', 'toggle grid', ->
  settings.grid = not settings.grid

control.keytapbindname 'b', 'toggle beanmode', -> settings.beanmode = not settings.beanmode

control.keytapbindname 'l', 'WHAM!', ->
  ladybug.jumping=true
  ladybug.kicking=false
  ladybug.punching=false
control.keyholdbind 'l', -> ladybug.attacktimeout=10

punch = ->
  ladybug.punching=true
  ladybug.kicking=false
  ladybug.attacktimeout=10
  playsound "hit.wav"
kick = ->
  ladybug.kicking=true
  ladybug.jumping=true
  ladybug.punching=false
  ladybug.attacktimeout=10
  playsound "hit.wav"

control.keytapbindname 'j', 'POW!', punch
control.keytapbindname 'k', 'BAM!', kick
control.keytapbindname 'm', 'mute', ->
  settings.muted = not settings.muted

up = ->
  if ladybug.touchingground()
    playsound "jump.wav"
  ladybug.jumping=true
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
  tmpladybug = $.extend {}, ladybug
  tmpladybug._pixisprite = undefined
  console.log "saving"
  localStorage["bug"] = JSON.stringify tmpladybug
  console.log localStorage["bug"]
  localStorage["settings"] = JSON.stringify settings

load = ->
  console.log "loading"
  $.extend ladybug, JSON.parse localStorage["bug"]
  ladybug.pos = $.extend V(), ladybug.pos
  ladybug.vel = V ladybug.vel.x, ladybug.vel.y
  $.extend settings, JSON.parse localStorage["settings"]

control.keytapbindname '6', 'save', save
control.keytapbindname '7', 'load', load


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

tickno = 0

Block::gethitbox = () ->
  return @

Block::render = ->
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
    if settings.decemberween then @src='snow.png'

Cloud::spriteinit = () ->
  tex = PIXI.Texture.fromImage sourcebaseurl+@src
  sprit = new PIXI.TilingSprite tex, screensize.x, screensize.y
  @_pixisprite=sprit
  stage.addChildAt sprit, 0
  return sprit

Cloud::render = () ->
  pos = cameraoffset()
  flip = false
  if not @_pixisprite then @spriteinit()
  sprit = @_pixisprite
  offset=V tickno*-0.2, Math.sin(tickno/200)*64
  sprit.position = VTOPP pos
  sprit.tilePosition = VTOPP offset

class Grid extends Sprite
  constructor: () ->
    super()
    @src='square.png'
Grid::render = () ->
  pos = cameraoffset()
  flip = false
  tex = PIXI.Texture.fromImage sourcebaseurl+@src
  if not @_pixisprite
    sprit = new PIXI.TilingSprite tex, screensize.x, screensize.y
    @_pixisprite=sprit
    stage.addChildAt sprit, 1
  sprit = @_pixisprite
  offset=V tickno*-0.2, Math.sin(tickno/200)*64
  sprit.position = new PIXI.Point pos.x, pos.y
  offset = camera.pos.nmul -1
  sprit.tilePosition = new PIXI.Point offset.x, offset.y
  sprit.setTexture tex 
  if not settings.grid and @_pixisprite
    stage.removeChild @_pixisprite
    @_pixisprite=undefined

WORLD={}
WORLD.entities = []
WORLD.entities.push new Cloud()
WORLD.entities.push new Grid()

WORLD.bglayer = bglayer
WORLD.fglayer=fglayer
WORLD.spritelayer=spritelayer

randpos = -> V(640*1.5,64*2).vadd randvec().vmul V 640, 100

placeshrub = (pos) ->
  pos = pos.vsub V 0, 32
  fglayer.push new GenericSprite pos, 'shrub.png'

WORLD_ONE_INIT = ->
  spritelayer=spritelayer.concat [0..10].map ->
    new Target randpos()
  spritelayer=spritelayer.concat [0..10].map ->
    new Jelly randpos()
  spritelayer=spritelayer.concat [0..3].map ->
    new Thug randpos()
  spritelayer.push new PowerSuit V(128,32)
  bglayer.push new Block 128+8, 64+20, 64, 32
  bglayer.push new Block 128+8+64, 64+20+32, 32, 32
  placeshrub V 64*8, 64*5-4
  placeshrub V 64*7-48, 64*5-4
  placeshrub V 64*9, 64*5-4
  if settings.decemberween
    WORLD.entities.push new Hat()

WORLD_ONE_INIT()

camera={}
camera.offset=V()
camera.pos=V()

PIXI.DisplayObjectContainer
cameraoffset = ->
  tmppos = ladybug.pos.nadd(64).vsub screensize.ndiv 2
  tmppos.y = mafs.clamp tmppos.y, -screensize.y, 0
  return tmppos.vsub camera.offset.ndiv scale

render = ->
  camera.pos = cameraoffset()
  renderables = [].concat WORLD.bglayer, spritelayer, [ladybug], fglayer
  renderables.forEach (sprite) -> sprite.render?()
  WORLD.entities.forEach (ent) -> ent.render?()
  drawhitboxes renderables

drawhitboxes = ( ents ) ->
  stage.removeChild hitboxlayer
  hitboxlayer = new PIXI.DisplayObjectContainer
  stage.addChild hitboxlayer
  if not settings.grid then return
  graf = new PIXI.Graphics()
  graf.lineStyle 1, 0x00ff00, 1
  graf.beginFill 0xff0000, 1/8
  ents.forEach (ent) ->
    graf.drawCircle ent.pos.x, ent.pos.y, 4
    box = ent.gethitbox?()
    graf.drawRect box.x, box.y, box.w, box.h
  hitboxlayer.addChild graf

#returns elapsed time in ms.
timecall = (func) ->
  starttime = Date.now()
  func()
  Date.now()-starttime

tickwaitms = 20
skipframes = 0
ticktimes = []

checkcolls = ( ent, otherents ) ->
  bawks = ent.gethitbox()
  otherents.forEach (target) ->
    if target is ent then return
    targethitbox = target.gethitbox()
    if bawks.overlaps targethitbox
      target.collide?(ent)

#remove entities that requested death
WORLD.euthanasia = ->
  doomedsprites = spritelayer.filter (sprite) -> sprite.KILLME?
  doomedsprites.forEach (sprite) ->
    sprite.cleanup?()
    spritelayer = arrsansval spritelayer, sprite

WORLD.tick = () ->
  for key in control.heldkeys
    control.holdbindings[key]?()
  checkcolls ladybug, spritelayer
  spritelayer.forEach (sprite) ->
    checkcolls sprite, arrsansval spritelayer, sprite
  WORLD.euthanasia() 
  spritelayer.forEach (sprite) -> sprite.tick?()
  ladybug.tick()
  WORLD.entities.forEach (ent) -> ent.tick?()
  render()
  tickno++

fpscounter=$ xmltag()
tt=0
mainloop = ->
  updatesettingstable()
  if not settings.paused
    ticktime = timecall WORLD.tick
    tt=ticktime
    fps=Math.round 1000/Math.max(tickwaitms,ticktime)
    idealfps=Math.round 1000/tickwaitms
    fpscounter.html "tick time: #{tt}ms, running at approx #{fps} fps (aiming for #{idealfps} fps)"
  tickwaitms = if settings.slowmo then 1000/4 else 1000/50
  setTimeout mainloop, Math.max tickwaitms-ticktime, 1

xmlwrap = (tagname,body) -> 
  xmltag tagname, undefined, body

maketablerow = ( values ) ->
  tds = values.map (v) -> xmlwrap "td", v
  return xmlwrap "tr", tds

bindingsDOM = $ "<table>"
for k,v of control.bindings
  bindingsDOM.append maketablerow [String.fromCharCode(k),control.bindingnames[k] or "??"]

settingsDOM = $ "<table>"
updatesettingstable = () ->
  settingsDOM.html ""
  for k,v of settings
    settingsDOM.append maketablerow [k,v]

INIT = ->
  body.append "<br/><em>there's no crime to fight around here, use WASD to waste time by purposelessly wiggling around,<br/>X to boggle vacantly and JKL to do some wicked sick totally radical moves</em><br/><p>G and T for some debug dev mode shit, Y for fullscreen, P to pause</p>"
  body.append fpscounter
  body.append "<b>bindings:</b>"
  body.append bindingsDOM
  body.append "<b>settings:</b>"
  body.append settingsDOM
  mainloop()
  requestAnimFrame animate

INIT()

adjustmouseevent = (e) ->
  coffs=$(renderer.view).offset()
  adjusted = V e.pageX-coffs.left, e.pageY-coffs.top
  adjusted = adjusted.ndiv scale
  adjusted = adjusted.vadd camera.pos
  adjusted = adjusted.op Math.round
  return adjusted

creatingblock = false

BLOCKCREATIONTOOL = {}
BLOCKCREATIONTOOL.mousedown = (e) ->
  #ADD BLOCK, LEFT MBUTTON
  #HOLD Z TO SNAP TO GRID
  if e.button != 0 then return
  adjusted = adjustmouseevent e
  adjusted=snapmouseadjust adjusted
  creatingblock=new Block adjusted.x, adjusted.y, 32, 32
  bglayer.push creatingblock
BLOCKCREATIONTOOL.mouseup = (e) ->
  creatingblock = false

snapmouseadjust = (mpos) ->
  snaptogrid = isholdingkey 'z'
  if snaptogrid
    gridsize = 32
    mpos = mpos.ndiv(gridsize).op(Math.floor).nmul(gridsize)
  return mpos

$(renderer.view).mousedown BLOCKCREATIONTOOL.mousedown
$(renderer.view).mouseup BLOCKCREATIONTOOL.mouseup

ORIGCLICKPOS = false
mousemiddledownhandler = (e) ->
  if e.button != 1 then return
  e.preventDefault()
  ORIGCLICKPOS = V e.pageX, e.pageY
mousemiddleuphandler = (e) ->
  if e.button != 1 then return
  ORIGCLICKPOS = false
  camera.offset = V()
mousemovehandler = (e) ->
  mpos = snapmouseadjust adjustmouseevent e
  if creatingblock
    creatingblock.w = mpos.x-creatingblock.x
    creatingblock.h = mpos.y-creatingblock.y
    stage.removeChild creatingblock._pixisprite
    creatingblock._pixisprite = undefined
  if ORIGCLICKPOS
    currclickpos=V e.pageX, e.pageY
    offset=currclickpos.vsub ORIGCLICKPOS
    camera.offset = offset
    console.log offset

$(renderer.view).mousemove mousemovehandler

$(renderer.view).mousedown mousemiddledownhandler
$(renderer.view).mouseup mousemiddleuphandler

mouserightdownhandler = (e) ->
  if e.button != 2 then return
  e.preventDefault()
  adjusted = adjustmouseevent e
  blox=blocksatpoint bglayer, adjusted
  console.log blox
  if blox.length > 0
    ent=blox[0]
    bglayer = arrsansval bglayer, ent
    WORLD.bglayer=bglayer
    stage.removeChild ent._pixisprite

$(renderer.view).mousedown mouserightdownhandler

$(renderer.view).contextmenu -> return false #NOOP

$(renderer.view).bind 'wheel', (e) ->
  e.preventDefault()
  delta=e.originalEvent.deltaY
  up=delta>0
  console.log delta
  if up then scale-=0.1
  if not up then scale+=0.1

