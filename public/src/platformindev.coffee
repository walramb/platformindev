# video gem
#dependencies:
#jQuery
#Underscore.js
#pixi.js

#THISFILE = "src/platformindev.coffee"
THISFILE = "js/platformindev.js"

settings=
  gridsize: 16
  fps: 30
  drawsprites : true
  slowmo : false
  altcostume : true
  muted : true
  paused : false
  volume : 0.2
  variablejump : false
  moonjump : false
  NOSUBSCREENS : true
  NOCOLLS : false
  HD : false
  scale: 1
  recordingdemo: false
  forcemove: false #when at max speed, prevent deceleration
  aircontrol: true #can move left/right in midair?
  devmode: no
  hudscale: 2

settings.devmode = window.location.hash is "#dev"

#global var to be moved elsewhere
TILESELECT = 0
tickno = 0

#constants
MLEFT = 0
MRIGHT = 2

#
mafs.roundn = ( num, base ) -> Math.round(num/base)*base
linterpolate = (a,b,frac) -> a+(b-a)*frac

#helper function, easy to globally replace later??
TEXBYNAME = (imgsrc) -> PIXI.Texture.fromImage sourcebaseurl+imgsrc

assert = (expr, msg) ->
  if not expr
    console.log Error
    throw msg or "assert failed!"
WARN = (msg) ->
  console.log msg
  return
DEPRECATE = ->
  throw "deprecated"

voidcaller = (func) -> do func; return
noop = ->

b2n = (bool) -> if bool then 1 else 0 #poorly named bool to num function

#return args as array
arr = (args...) -> args
call = (func) -> do func


#need this for some CSS
browserprefix = '-webkit-'

is_firefox = navigator.userAgent.toLowerCase().indexOf('firefox') > -1
if is_firefox then browserprefix = '-moz-'

stats=
  collisionchecks: 0

V = (x=0,y=0) -> new V2d x,y
screensize_default = V 960, 540 # halved 1080p
screensize = screensize_default.nadd 0 # halved 1080p
#screensize = new V2d 320, 240 # GCW Zero


sourcebaseurl = "./sprites/"
audiobaseurl="./audio/"


preload = (str) -> PIXI.loader.add(sourcebaseurl+str).load()
XXXX = (tilesrc, tileW, tileH, cols, rows) ->
  preload tilesrc
  pxSheetW=tileW*cols
  pxSheetH=tileH*rows
  _tileset = TEXBYNAME tilesrc
  _tileset.baseTexture.width = pxSheetW
  _tileset.baseTexture.height = pxSheetH
  tsw = 20 #tileset width in tiles
  tilesize = 16
  rowcount = 8
  numtiles = rows*cols
  return _maketiles _tileset, tileW, tileH, cols, rows


gettileoffs = (n,tsw, tilesize) ->
  V n%tsw, Math.floor(n/tsw)

# slice an image into square textures
maketiles = (tileset, tsize, cols, numtiles) ->
  rows=numtiles/cols
  _maketiles tileset, tsize, tsize, cols, rows

#tileW is the width of an individual tile
#setW is the width of the entire sheet, measured in tiles
_maketiles = (tileset, tileW, tileH, cols, rows ) ->
  numtiles=cols*rows
  range=[0...numtiles]
  texs= for i in range
    tex = new PIXI.Texture tileset
    {x,y}=gettileoffs i, cols
    rec = new PIXI.Rectangle x*tileW, y*tileH, tileW, tileH
    tex.frame = rec
    tex

fontsrc = "font-hand-white-12x16.png"
fonttexs = XXXX fontsrc, 12, 16, 16, 6

blocktextures = do ->
  tilesrc = "metroid like.png"
  preload tilesrc
  tileset = TEXBYNAME tilesrc
  tileset.baseTexture.width = 320
  tileset.baseTexture.height = 256
  console.log tileset
  tsw = 20 #tileset width in tiles
  tilesize = 16
  rowcount = 8
  numtiles = rowcount*tsw
  return maketiles tileset, tilesize, tsw, numtiles

bts = TEXBYNAME "bugrunhd.png"
bts.baseTexture.width = 310
bts.baseTexture.height = 47
bugtextures = maketiles bts, 21, 4, 4

Line2d = mafs.Line2d
HitboxRayIntersect = mafs.HitboxRayIntersect
pointlisttoedges = mafs.pointlisttoedges

body = $ "body"

PP = (x,y) -> new PIXI.Point x,y
VTOPP = (v) -> PP v.x, v.y

CURSOR = V 0,0
SCREENCURS = V 0,0

audiocache = []
audiocachelength = 10
for n in [0...audiocachelength]
  audiocache[n] = new Audio()

curraudiotrack=0


playsound = ( src, volume ) ->
  curraudiotrack++
  curraudiotrack=curraudiotrack%audiocachelength
  if settings.muted then return
  snd = audiocache[curraudiotrack]
  snd.src = audiobaseurl+src
  snd.volume = volume or settings.volume
  snd.play()

parentstage = new PIXI.Stage 0x66FF99

dotfilt = new PIXI.filters.DotScreenFilter()
dotfilt.scale = 6
#parentstage.filters = [dotfilt]


stage = new PIXI.Container
parentstage.addChild stage

hitboxlayer = new PIXI.Container
stage.addChild hitboxlayer
resetstage = ->
  parentstage.removeChild stage
  stage = new PIXI.Container
  parentstage.addChild stage
  hitboxlayer = new PIXI.Container
  stage.addChild hitboxlayer


HUDLAYER = new PIXI.Container
parentstage.addChild HUDLAYER

#renderer = PIXI.autoDetectRenderer screensize.x, screensize.y
renderer = new PIXI.CanvasRenderer screensize.x, screensize.y

pausescreen = new PIXI.Graphics()
pausescreen.beginFill 0x000000
pausescreen.drawRect 0, 0, screensize.x, screensize.y
pausescreen.alpha = 0.5

pausetext = new PIXI.Text "PAUSED",
  { font: "32px Arial", fill:"white", strokeThickness: 8, stroke:'red'}
pausetext.position = VTOPP screensize.ndiv 2
pausetext.anchor = PP 1/2, 1
pausescreen.addChild pausetext

pausetext = new PIXI.Text "GO GET SOME SNACKS\nPERHAPS A CARBONATED SODA",
  { font: "16px Arial", fill:"white"}
pausetext.position = VTOPP screensize.ndiv(2).vadd(V(0,64))
pausetext.anchor = PP 1/2, 0
pausescreen.addChild pausetext

ascii = String.fromCharCode.apply @, [32..126] #from Space to Tilde
fontmap=ascii


string_to_pixi = (text = "I AM ERROR" ) ->
  textcontainer = new PIXI.Graphics()

  for char,i in text
    offs=V 0,0
    wspacing=16
    glyph = fonttexs[ fontmap.indexOf(char) ]
    spr = new PIXI.Sprite glyph
    spr.tint = 0xFF0000
    spr.anchor = PP 1/2, 1/2
    spr.position = VTOPP offs.vadd V i*wspacing, 0
    spr.scale = PP 2, 2
    textcontainer.addChild spr
  return textcontainer


body.append renderer.view
$(renderer.view).attr tabindex: 0


scale = 1

tmpstage = new PIXI.Container()
tmpinnerstage = new PIXI.Container()
tmpstage.addChild tmpinnerstage


animate = ->
  camera.tick()
  render()
  cam=cameraoffset().nmul -scale
  stage.position = VTOPP cam
  stage.scale = PP scale, scale
  renderer.render parentstage
  requestAnimationFrame animate


achieve = (title) ->
  WARN "there's nothing to achieve"

class Renderable
  constructor: () ->
    @pos=V()
Renderable::hassprite = -> typeof @._pixisprite isnt "undefined"
Renderable::removesprite = -> removesprite @


class GenericSprite extends Renderable
  constructor: ( @pos=V(), @src ) ->
    @vel=V()
  render: ->
    anchor = @anchor or V(0,0)
    flip=not @facingleft
    box= @gethitbox()
    pos=relativetobox box, anchor
    drawsprite @, @src, pos, flip, anchor
GenericSprite::cleanup = ->
  removesprite @

class TextEnt extends GenericSprite
  constructor: (@text) ->
    super()
    @age=0
    @targetpos = @pos
  initsprite: () ->
    textcontainer = string_to_pixi @text
    @_pixisprite = textcontainer
    stage.addChild @_pixisprite
  render: () ->
    if not @hassprite() then @initsprite()
    if @_pixisprite?
      sprit=@_pixisprite
      sprit.position = VTOPP @pos
      return
  tick: () ->
    @age++
    @pos.y = linterpolate @pos.y, @targetpos.y, 1/2
    if (@age % 60) is 0
      @targetpos.y -= 64
    if @age > 200
      @KILLME = true

CUE_DIALOGUE = (location) ->
  CUE_DIALOGUE = -> #one time only
  lines = [ "oh hai marl", "this is dialogue", "anyway how's your sex life" ]
  offs = 0
  for line in lines
    te=new TextEnt line
    WORLD.entAdd te
    te.targetpos = location.nadd 0
    te.targetpos.y += offs
    offs += 32


#LOAD PROPERTIES FROM AN OBJECT
#for example to initialize from .json level data
GenericSprite::load = (obj) ->
  if obj.pos?
    _.extend @pos, obj.pos

class PlaceholderSprite extends GenericSprite
  constructor: (@pos) ->
    super @pos
    @label='a thing'
    @anchor = V 0,0
PlaceholderSprite::render = ->
  if @_pixisprite?
    sprit=@_pixisprite
    sprit.position = VTOPP @pos
    return
  txt = new PIXI.Text @label,
    { font: "12px Arial", fill:"black" }
  txt.anchor = VTOPP @anchor
  sprit = new PIXI.Graphics()
  sprit.beginFill 0xFF00FF
  sprit.pivot = VTOPP V 0, 32
  box=@gethitbox()
  sprit.position = VTOPP @pos
  sprit.drawRect 0, 0, box.w, box.h
  sprit.alpha = 0.9
  sprit.addChild txt
  stage.addChild sprit
  @_pixisprite=sprit


_DEFAULTHITBOXSIZE = V 32, 32
GenericSprite::gethitbox = ->
  size=@size or _DEFAULTHITBOXSIZE
  anchor = @anchor or V 1/2, 1/2
  #@hitboxcache ?= makebox @pos, size, anchor
  #fuck it
  @hitboxcache = makebox @pos, size, anchor
  @hitboxcache
GenericSprite::updatehitbox = ->
  size=@size or _DEFAULTHITBOXSIZE
  anchor = @anchor or V 1/2, 1/2
  if @hitboxcache?
    [ x, y, w, h ] = fixbox @pos, size, anchor
    @hitboxcache.x = x
    @hitboxcache.y = y
    @hitboxcache.w = w
    @hitboxcache.h = h
  return @hitboxcache

fixbox = (position, dimensions, anchor) ->
  truepos = position.vsub dimensions.vmul anchor
  return [ truepos.x, truepos.y, dimensions.x, dimensions.y ]

entitycount = ( classtype ) ->
  ents = WORLD.spritelayer.filter (sprite) -> sprite instanceof classtype
  return ents.length

GenericSprite::gravitate = () ->
  if not @touchingground()
    @vel.y++


class Pickup extends GenericSprite
  constructor: ( @pos=V() ) ->
    @vel=V()
    @src="energy1.png"
Pickup::collide = ( otherent ) ->
  if otherent instanceof BugLady
    @pickedup otherent
Pickup::pickedup = ( otherent ) ->
  playsound 'boip.wav'
  @KILLME=true

class Energy extends Pickup
  constructor: ( @pos=V() ) ->
    @vel=V()
    @src="energy1.png"
Energy::getsprite = ->
  framelist = [1..6].map (n) -> "energy#{n}.png"
  @src = selectframe framelist, 4
Energy::tick = () ->
  super()
  @getsprite()
Energy::pickedup = (otherent) ->
  super()
  otherent.energy += 1

class Gold extends Pickup
  constructor: ( @pos=V() ) ->
    @vel=V()
    @src="crown.png"
Gold::getsprite = ->
Gold::pickedup = (otherent) ->
  super()
  otherent.score += 1

relativetobox = ( box, anchor ) ->
  pos = V box.x, box.y
  size = V box.w, box.h
  pos = pos.vadd size.vmul anchor
  return pos


class Thug extends GenericSprite
  constructor: ( @pos=V() ) ->
    @lifetime=-1
    @vel = V()
    @src='bugthug.png'
    @facingleft = true
    @health=3
bottomcenter = V 1/2, 1
Thug::size = V 24, 64+16
Thug::anchor = bottomcenter
Thug::tick = () ->
  @physmove()
  @getsprite()

Thug::getsprite = ->
  if @lifetime <= 0
    @src = 'bugthug.png'
  if @health <= 0
    @src='thugded.png'
  if @lifetime > 0
    @lifetime--
    @src="bugthugoof.png"

Thug::collide = ( otherent ) ->
  if otherent instanceof BoggleParticle
    @vel = @vel.vadd otherent.vel.nmul 1/8
  if otherent.timers?.attack? and otherent.timers?.attack > 0 and @lifetime <= 0
    @vel = @vel.vadd otherent.vel.nmul 1/2
    @gethitby otherent
  return if @health <= 0
  if otherent instanceof Hero and otherent.timers?.invincible == 0
    playsound 'excardon.wav'
    otherent.flinch()
Thug::gethitby = ( otherent ) ->
  @vel.y += otherent.vel.y
  dir=_facing otherent
  @vel.x += dir*1
  @lifetime = 10
  @health-=1

class Lila extends Thug
class Robo extends Thug

Lila::scampersubroutine = Robo::scampersubroutine = ->
  if not @scampering and Math.random()<1/10
    @scampering=true
  if @scampering and Math.random()<1/10
    @scampering=false
  if @scampering and Math.abs(@vel.x)<3
    @vel.x += if @facingleft then -@scamperspeed else @scamperspeed
  if not @scampering and Math.random()<1/20
    @facingleft = not @facingleft


Lila::tick = () ->
  if @kisstimeout > 0
    @kisstimeout--
  super()
  if @kisstimeout > 50
    return
  @scamperspeed = 2
  @scampersubroutine()

Robo::visioncheck = () ->
  CENTER = V 1/2, 1/2
  dim = 64*4
  visionarea = makebox @.pos, V(dim,dim), CENTER
  #@angry = visionarea.containspoint ladybug.pos
  @angerlevel ?= 0
  if visionarea.containspoint ladybug.pos
    @angerlevel++
  else if @angerlevel > 0
    @angerlevel--
  @angry = @angerlevel > 40

Robo::tick = () ->
  super()
  isdead = @health <= 0
  @state=if @scampering and @angry then "attacking" else "idle"
  if isdead
    @scampering=false
    return
  @visioncheck()
  @scamperspeed = 1
  @scamperspeed = 6 if @angry
  #charge towards ladybug
  if @angry then @facingleft = ladybug.pos.x < @pos.x
  @scampersubroutine()

class Turret extends Thug
Turret::visioncheck = () ->
  CENTER = V 1/2, 1/2
  dim = 64*4
  visionarea = makebox @.pos, V(dim,dim), CENTER
  @angry = visionarea.containspoint ladybug.pos
Turret::tick = () ->
  @visioncheck()
  if @angry and tickno % 10 is 0
    firebullet @

selectframe = ( framelist, framewait ) ->
  totalframes = framelist.length
  framechoice = Math.floor(tickno/framewait)%totalframes
  framelist[framechoice]

Lila::getsprite = ->
  idlecycle = [ 'lilaidle1.png', 'lilaidle2.png' ]
  scampercycle = ("lilascamper#{n}.png" for n in [1..4])
  framewait = 4
  framelist=idlecycle
  if not @scampering then framewait = 20
  if @scampering then framelist=scampercycle
  if @kisstimeout > 90 then framelist = [ "lilakiss.png" ]
  @src = selectframe framelist, framewait

_cycle = (name, range) ->
  range.map (n) -> "#{name}#{n}.png"

Robo::getsprite = ->
  idlecycle = [ 'robocalm1.png' ]
  scampercycle = _cycle "robocalm", [1..2]
  if @angerlevel > 10
    idlecycle = _cycle "roboroll", [1..2]
    scampercycle = _cycle "roboroll", [1..2]
  if @angry
    idlecycle = _cycle "roborage", [1..2]
    scampercycle = _cycle "roborage", [2..4]
  framelist=idlecycle
  if @scampering then framelist=scampercycle
  if @lifetime > 0
    @lifetime--
    framelist=["robohurt.png"]
  if @health <= 0
    framelist=["robobody.png"]
  #@pos.y++ #AUGH
  if @health <= 0 and @lifetime == 0 and @touchingground()
    framelist=["roboded.png"]
  #@pos.y--
  framewait = 4
  @src = selectframe framelist, framewait


Robo::collide = (otherent) ->
  if otherent instanceof Hero and @state is "attacking"
    otherent.takedamage()
Lila::collide = ( otherent ) ->
  if otherent instanceof Hero
    CUE_DIALOGUE(@pos)
  if otherent instanceof BoggleParticle
    #parentstage.addChild bogglescreen
    if not (@kisstimeout > 0)
      ladybug.heal()
      WORLD.entAdd new Smoochie @pos
    @kisstimeout = 1


class BoggleParticle extends GenericSprite
  constructor: ( @pos=V() ) ->
    @vel = mafs.randvec().norm()
    @src = 'huh.png'
    @life = 50
    @anchor = V 0,0
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd mafs.randvec().norm().ndiv 8
    if @life<=10 then @_pixisprite.alpha=@life/10

BoggleParticle::render = ->
  drawsprite @, 'emily.png', @pos, false

class Smoochie extends GenericSprite
  constructor: ( @pos ) ->
    @anchor=V 1/2, 1
    @vel = mafs.randvec().norm()
    @src = 'kissparticle1.png'
    @life = 50
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    guipos = cameraoffset().nadd 32
    dif = guipos.vsub @pos
    if @life<10
      @vel=@vel.vadd dif.ndiv 64 #hacky
    @pos = @pos.vadd @vel
    @vel = @vel.vadd mafs.randvec().norm().ndiv 8
    @vel = @vel.vadd V 0, -1/8
  render: () ->
    super()
    @src=@getsprite()
    @_pixisprite.rotation = mafs.degstorads Math.cos(@life/100)*10

Smoochie::getsprite = ->
  framewait = 16
  framelist = [3,2,1].map (n) -> "kissparticle#{n}.png"
  framechoice = Math.floor this.life/framewait
  return framelist[framechoice]

class PchooParticle extends GenericSprite
  constructor: ( @pos=V() ) ->
    @vel = ladybug.vel.nmul(-1).norm()
    @life = 20
    @src = 'energy4.png'
    @anchor = V 1/2, 1/2
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd mafs.randvec().norm().ndiv 64
  render: ->
    drawsprite @, @src, @pos, false, @anchor
    @_pixisprite.alpha = 0.25 + @life/40 #fading
    @_pixisprite.rotation = -Math.atan2 @vel.x, @vel.y

class Bullet extends GenericSprite
  constructor: ( @pos=V() ) ->
    @owner = undefined
    @vel = V(8,0)
    @life = 10
    @src = 'particlepunch.png'
    @anchor = V 1/2, 1/2
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd mafs.randvec().norm().ndiv 64
  render: ->
    flip=@vel.x<0
    drawsprite @, @src, @pos, flip, @anchor
    @_pixisprite.alpha = 0.8

class Shieldbubble extends GenericSprite
  constructor: ( @pos=V() ) ->
    @owner = ladybug
    @src = 'bubble.png'
    @anchor = V 1/2, 1
    @vel = V()
  tick: () ->
    @pos = @owner.pos
    if @_pixisprite then @_pixisprite.alpha = 1/2

Bullet::collide = ( otherent ) ->
  if otherent.health? and otherent isnt @owner
    otherent.gethitby?( @owner )
    @KILLME=true

isholdingkey = (key) ->
  key = key.toUpperCase().charCodeAt 0
  return key in control.heldkeys

isholdingbound = (name) ->
  keys=control.heldkeys.map (key) -> control.bindingnames[key]
  return name in keys

class Hero extends GenericSprite
  constructor: () ->
    super()
    @jumping = false
    @attacking = false
    @timers=
      attack: 0
      stun: 0
      mildstun: 0
      invincible: 0
    @health=3
    @energy=0
    @score=0
    @facingleft=false
    @anchor = V 1/2, 1

class BugLady extends Hero
  constructor: () ->
    super()
    @controls={}
    @controls.tapstatus={}
    @state = "normal"
    @state_frame = 0
  state_call: ->
    @state_functions[@state]?.call this
    @state_frame++
  state_set: (statename) ->
    @state_frame = 0
    @state = statename
  state_functions:
    recover: ->
      if @state_frame > 4 then @state_set "normal"
    punch: ->
      @vel = V 0, 8
      @state_punch()
      if @state_frame > 4 then @state_set "recover"
    kick: ->
      if @state_frame is 0 then @vel = V @dirfaced()*4, -1
      if @state_frame > 4 then @state_set "recover"
    roundhouse: ->
      if @state_frame is 0 then @vel = V @dirfaced()*4, -8
      if @state_frame > 4 then @state_set "recover"

BugLady::heal = -> @health=3
BugLady::respawn = ->
  @pos = V()
  @vel = V()
  @heal()
BugLady::flinch = () ->
  knockbackDir = @facingleft or -1
  @vel.x *= 1/2
  @vel.x += knockbackDir * 8
  #@vel = @vel.vmul V -1, 1
  @timers.invincible = 20
  @timers.flinching = 20
Hero::gethitby = ( otherent ) ->
  @takedamage()
BugLady::takedamage = ->
  if @timers.invincible > 0 then return
  if @timers.stun <= 0 then @flinch()
  @health-=1
  if @health <= 0 then @kill()

entcenter = ( ent ) ->
  hb=ent.gethitbox()
  return V hb.x+hb.w/2, hb.y+hb.h/2

GenericSprite::blockcollisions = ->
  box=@gethitbox()
  candidates = hitboxfilter box, WORLD.bglayer
  candidates.forEach (candidate) =>
    if @.gethitbox().bottom() >= candidate.top()
      @pos.y = candidate.y
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0


BugLady::blockcollisions = ->
  box=@fallbox()
  #nonstatic platforms/jellies
  platforms = hitboxfilter box, WORLD.BOXCACHE
  if platforms.length > 0
    WARN "stuck in wall"
    @pos.y-=2
  candidates = hitboxfilter box, WORLD.bglayer
  candidates.forEach (candidate) =>
    if @.gethitbox().bottom() <= candidate.top()
      @pos.y = candidate.y
      @vel.y = 0
      #do a little pause when you smack into the ground
      if (not @timers.fightstance) and not @timers.mildstun
        @timers.mildstun=4
    #following lines handle ceiling collisions
    jumpthroughable = candidate instanceof OnewayBlock
    cond = box.strictoverlaps(candidate)
    if @vel.y < 0 and not jumpthroughable and box.top()>candidate.top()
      @vel.y = 0

closestpoint = (p, pointarr) ->
  closest = pointarr[0]
  for point in pointarr
    if closest.dist(p) > point.dist(p)
      closest = point
  return closest



Hero::checkcontrols = -> #noop
BugLady::checkcontrols = ->
  if this isnt ladybug then return
  @holdingboggle = isholdingbound 'boggle'
  @holdingjump = isholdingbound 'jump'
  if not @holdingjump then @controls.tapstatus.jump = true
  @controls.crouch = isholdingbound 'down'


BugLady::cancelattack = ->
  @timers.attack = 0
  @attacking=false

Hero::outofbounds = ->
  @pos.y > 6400

BugLady::kill = ->
  @respawn()


BugLady::timeoutcheck = -> #rename to timerhandler or something?
  for k,v of @timers
    if v>0 then @timers[k]--
  if @timers.powerup > 0
    @vel = V2d.zero()
  if @timers.stun > 0
    achieve "fall"
    @vel = V2d.zero()
  if @timers.invincible is 0 and @shield
    @shield.KILLME = true
    @shield=null

BugLady::state_punch = ->
  if @attacking and @punching
    if entitycount(Bullet) < 3 and @energy > 0
      @energy-=0.1
      firebullet @

BugLady::attackchecks = ->
NOOPE = ->
  @attacking=@timers.attack > 0
  heading = _facing @
  dashing = Math.abs(@vel.x)>11
  if @attacking and dashing
    @vel.x *= 1/2
    @timers.uppercut = 10
  forward = isholdingbound('left') or isholdingbound('right')
  up = isholdingbound 'up'
  down = isholdingbound 'down'
  if @attacking and up
    @vel.x *= 1/2
    @timers.uppercut = 10
  if @attacking and @kicking and down
    @timers.slide = 10
    @vel = V heading*10, 0
  if @attacking and @kicking and forward
    @vel = V heading*10, 0
  if @attacking and @kicking and up and !@timers.roundhouse
    @timers.roundhouse = 20
  if @state is "punching"
    @state_punch()
  if @attacking and not @timers.hitboxery
    @timers.hitboxery=10
    nent = new Damagebox(@)
    WORLD.entAdd nent

class Damagebox extends Renderable
  constructor: (@owner) ->
    @pos = @owner.pos
    @life = 15
    @anchor = V 0.5, 2
    @size = V 64, 16
  tick: ->
    if @life-- <= 0
      @KILLME=true
  gethitbox: GenericSprite::gethitbox

firebullet = (ent) ->
  heading = _facing ent
  bullet = new Bullet()
  bullet.owner = ent
  bullet.vel = V heading*32, 0
  bullet.life = 2
  CENTER=V 1/2, 1/2
  bullet.pos = relativetobox ent.gethitbox(), CENTER
  WORLD.entAdd bullet
  return bullet

get_sprites_of_class = (classtype) ->
  ents = WORLD.spritelayer.filter (sprite) -> sprite instanceof classtype


BugLady::tick = ->
  TICKLOG @state
  @state_call()
  @timeoutcheck()
  @movetick()
BugLady::state_functions.normal = ->
  #slow energy recharge
  @energy+=0.001
  if @getsprite() is "bugdash.png" #no, bad. fix this
    WORLD.entAdd new PchooParticle entcenter @
  unpowered = settings.altcostume
  if unpowered then @cancelattack()
  @checkcontrols()
  if @outofbounds() then @kill()
  vel = Math.abs( @vel.x )
  walking = vel > 0.2


BugLady::limitvelocity = ->
  vellimit = 800
  @vel.x = mafs.clamp @vel.x, -vellimit, vellimit
BugLady::gravitate = ->
  if not @touchingground() and not @touchingwall()
    @vel.y += 1
    if @timers.fightstance then @vel.y += 1
    if settings.variablejump
      if not @holdingjump and @vel.y < 0 then @vel.y /= 2

BugLady::canhurdle = ->
  return if not isholdingbound 'cling'
  return if settings.altcostume
  #automagically do a hop skip and a jump over waist high obstacles
  box=@fallbox()
  box.x += if @.facingleft then -2 else 2
  candidates = hitboxfilter box, WORLD.bglayer
  b_hitsomething = candidates.length > 0
  box.y -= 4
  candidates = hitboxfilter box, WORLD.bglayer
  b_cansqueezein = candidates.length > 0
  return b_hitsomething and b_cansqueezein

BugLady::hurdlecheck = ->
  if @canhurdle()
    @vel.y-=2

GenericSprite::physmove = ->
  @blockcollisions()
  @avoidwalls()
  if @vel.y > 0 and @touchingground()
    @vel.y = 0
  @pos = @pos.vadd @vel
  @gravitate()
  if @touchingground()
    @friction()

BugLady::physmove = ->
  @hurdlecheck()
  @limitvelocity()
  @blockcollisions()
  @avoidwalls()
  if @vel.y > 0 and @touchingground()
    @vel.y = 0
  if @timers.mildstun<=2 #cooldown to avoid getting stuck on blocks
    @pos = @pos.vadd @vel
  if !@timers.hover then @gravitate()
  pressingwalk = isholdingbound('left') or isholdingbound('right')
  if @touchingground()
    @friction()
    if not pressingwalk then @friction() #double the friction double the fun

BugLady::smashblock = ->
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
  for block in blockcandidates
    if block.src isnt "genblackrocks.png" then continue
    WORLD.bglayer = _.without WORLD.bglayer, block
    block.removesprite()

BugLady::movetick = ->
  unpowered = settings.altcostume
  @physmove()
  @attackchecks()
  jumpvel = if unpowered then 11 else 13
  @jumpimpulse jumpvel
  if @vel.y>1 and @controls.crouch and @timers.charge
    ladybug.timers.charge=0
    @state = 'headfirst'
    @vel.y += 0.1
  if @touchingground() and @state == 'headfirst'
    @smashblock()
    @state = ''
    @timers.stun=20
  if @state == 'headfirst'
    @vel.y+=2
    @vel.x*=0.9
  @jumping = false #so we don't repeat by accident yo
  #@climbing = @touchingwall()
  @climbing = @canhurdle()

BugLady::jumpimpulse = (jumpvel) ->
  unpowered = settings.altcostume
  if @touchingground()
    @spentdoublejump = false
    @timers.jumpgraceperiod = 4
    if settings.moonjump then @timers.jumpgraceperiod = 100
  jumplegal = @touchingground() or @timers.jumpgraceperiod > 0
  jumplegal = jumplegal and this.controls.tapstatus.jump
  doublejumplegal = not unpowered and settings.airjump and @energy > 0
  doublejumplegal = doublejumplegal and this.controls.tapstatus.jump
  if @spentdoublejump then doublejumplegal = false
  if @jumping and doublejumplegal and not jumplegal
    @spentdoublejump = true
    @energy--
  if @jumping and (jumplegal or doublejumplegal)
    @controls.tapstatus.jump = false
    @vel.y = -jumpvel
  if @spentdoublejump and @vel.y < 0
    WORLD.entAdd new PchooParticle entcenter @

GenericSprite::OLD_friction = () ->
  @vel.x = @vel.x*0.9
GenericSprite::friction = () ->
  x = @vel.x
  sign = Math.sign x
  x -= sign / 2
  if Math.abs(x) < 1/2 then x = 0
  @vel.x = x

BugLady::boggle = () ->
  WORLD.entAdd new BoggleParticle entcenter @
  @energy++

BugLady::getsprite = ->
  src="lovelyshorter"
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  running = vel > 5
  if walking then src = selectframe [ 'lovelyrun1', 'lovelyrun2' ], 6
  if running then src = selectframe [ 'lovelyrun1', 'lovelyrun2' ], 2
  if not @touchingground()
    src = if @vel.y < 0 then 'lovelyjump' else 'lovelycrouch'
  if @timers.fightstance > 0 then src = "bugstance"
  if not walking
    if @controls.crouch
      src = 'lovelycrouch'
    if isholdingbound 'up'
      src = 'bugstance'
    if @touchingground() and @holdingboggle
      src = 'boggle'
  if @attacking
    src = 'viewtiful'
    if @timers.attack < 2 and @punching then src = 'lovelyrun2'
    if @state is "kick"
      src = 'bugkick'
      if @timers.slide then src = 'lovelyfall'
      if @timers.roundhouse then src = 'lb_roundhouse'
      if @timers.roundhouse>=15 then src = 'bugkick'
  if @timers.stun > 0 then src = 'lovelycrouch'
  if @timers.mildstun > 2 then src = 'lovelycrouch'
  if @timers.stun > 4 then src = 'bugbonk'
  if @timers.powerup > 0 then src = 'viewtiful'
  if @timers.powerup > 16
    src = 'boggle'
    @facingleft = @timers.powerup % 10 < 5
  if vel > 11 then src = "bugdash"
  if @timers.powerup > 32 then src = 'marl/boggle'
  if @lastfacing isnt @facingleft
    @timers.turn=4
    @lastfacing = @facingleft
  if @timers.turn>0
    src = 'lovelycrouch'
  if settings.altcostume then src = "marl/" + src
  if @climbing
    src = 'bugledge'
    if settings.altcostume then src = 'marl/boggle'
  if @state == 'headfirst' then src = 'bugdrop'
  if @timers.flinching > 10 and @touchingground() then src= "bugflinch"
  if @timers.flinching > 15 then src= "bugdmg"
  if @timers.flinching > 0 and not @touchingground() then src= "bugdmg2"
  if @state is "punch" then src= "buguppercut"
  if @state is "kick" then src= "bugkick"
  if @state is "roundhouse" then src= "lb_roundhouse"
  if @state is "recover" then src = "bugbean"
  return src+".png"


BugLady::flickershield = ->
  if @timers.invincible < 32 and @shield
    @shield._pixisprite.alpha = 0.5 * b2n(tickno % 8 isnt 0)
  if @timers.invincible < 10 and @shield
    @shield._pixisprite.alpha = 0.5 * (tickno % 2)

BugLady::render = ->
  vel = Math.abs( @vel.x )
  walking = vel > 1
  src=@getsprite()
  flip = @facingleft
  pos = relativetobox @gethitbox(), @anchor
  sprit=drawsprite @, src, pos, flip, @anchor
  if src == 'boggle.png'
    sprit.rotation=mafs.degstorads mafs.randfloat()*4
  else
    sprit.rotation=0
  if @timers.stun #blinking
    sprit.alpha = tickno % 2
  else
    sprit.alpha = 1
  @flickershield()

stageremovesprite = ( stage, ent ) ->
  if not ent._pixisprite? then return
  stage.removeChild ent._pixisprite
  ent._pixisprite=undefined
removesprite = ( ent ) ->
  stageremovesprite stage, ent

initsprite = (ent,tex) ->
  sprit = new PIXI.Sprite tex
  ent._pixisprite=sprit
  stage.addChild sprit
  return sprit

drawsprite = (ent, src, pos, flip, anchor=V()) ->
  tex = TEXBYNAME src
  if not ent._pixisprite
    initsprite ent,tex
  sprit = ent._pixisprite
  sprit.position = VTOPP pos
  sprit.anchor = VTOPP anchor
  sprit.texture = tex
  sprit.scale.x = if flip then -1 else 1
  return sprit



class Rect
  constructor: (@x,@y,@w,@h) ->
  # axis-aligned rectangles

_Rectmethods =
  containspoint: (p) ->
    @x <= p.x and @y <= p.y and @x+@w >= p.x and @y+@h >= p.y



class Block extends Renderable
  constructor: (@x,@y,@w,@h) ->
    @pos = V @x, @y
    @timers = {}
    @tile = 0

_.extend Rect::, _Rectmethods
_.extend Block::, _Rectmethods

Block::intersection = (rectb) ->
  # returns a new rect of area shared by both rects, like bool AND
  recta=@
  l=Math.max recta.left(), rectb.left()
  t=Math.max recta.top(), rectb.top()
  r=Math.min recta.right(), rectb.right()
  b=Math.min recta.bottom(), rectb.bottom()
  w=r-l
  h=b-t
  return new Block l,t,w,h


Block::strictoverlaps = ( rectb ) ->
  recta=@
  if recta.left() >= rectb.right() or
  recta.top() >= rectb.bottom() or
  recta.right() <= rectb.left() or
  recta.bottom() <= rectb.top()
    return false
  else
    return true

#rename Block::touching ?
Block::overlaps = ( rectb ) ->
  recta=@
  if recta.left() > rectb.right() or
  recta.top() > rectb.bottom() or
  recta.right() < rectb.left() or
  recta.bottom() < rectb.top()
    return false
  else
    return true

Block::tostone = () -> DEPRECATE()

Block::fixnegative = () ->
  if @w<0
    @x+=@w
    @w*=-1
  if @h<0
    @y+=@h
    @h*=-1
  @pos = V @x, @y
  @removesprite()

hitboxfilter_OLD = ( hitbox, rectarray ) ->
  rectarray.filter (box) ->
    hitbox.overlaps box

hitboxfilter = ( hitbox, rectarray ) ->
  stats.collisionchecks+= rectarray.length
  res = hitboxfilter_OLD hitbox, rectarray
  #stats.collisionchecks+= res.length
  return res

makebox = (position, dimensions, anchor) ->
  truepos = position.vsub dimensions.vmul anchor
  return new Block truepos.x, truepos.y, dimensions.x, dimensions.y

bottomcenter = V 1/2, 1
BugLady::anchor = bottomcenter
BugLady::size = V 16, 32+16

GenericSprite::fallbox = ->
  box=@gethitbox()
  box.w+=Math.abs @vel.x
  box.h+=Math.abs @vel.y
  if @vel.x < 0
    box.x += @vel.x
  if @vel.y < 0
    box.y += @vel.y
  #shrink it a bit so jumping works again, this is not ideal
  box.h-=2
  return box

Block::left = -> @x
Block::right = -> @x+@w
Block::bottom = -> @y+@h
Block::top = -> @y

Block::issamebox = (b) ->
  return @x is b.x and @y is b.y and @w is b.w and @h is b.h

blocksatpoint = (blocks, p) ->
  blocks.filter (box) -> box.containspoint p

boxtouchingwall = (collidebox) ->
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
  for block in blockcandidates
    notontop = collidebox.bottom()>block.top()
    if notontop and collidebox.left() < block.left()
      return true
    if notontop and collidebox.right() > block.right()
      return true
  return false

GenericSprite::touchingwall = () ->
  collidebox = @gethitbox()
  return boxtouchingwall collidebox

GenericSprite::avoidwalls = () ->
  actualbox = @gethitbox()
  collidebox = @fallbox()
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
  for block in blockcandidates
    jumpthroughable = block instanceof OnewayBlock
    if jumpthroughable then continue
    notontop = actualbox.bottom() >block.top()
    if boxtouchingwall collidebox
      @hitwall?()
      @vel.x = 0

BugLady::hitwall = () ->
  if Math.abs(@vel.x) > 11 then @timers.invincible = 10

GenericSprite::touchingground = () ->
  touch=false
  collidebox = @gethitbox()
  #otherboxes = _.union WORLD.BOXCACHE, WORLD.bglayer
  fromgrid=WORLD.collgrid.get collidebox, @
  otherboxes = [].concat fromgrid, WORLD.bglayer
  otherboxes = otherboxes.filter (b) -> not b.issamebox collidebox
  blockcandidates=hitboxfilter collidebox, otherboxes
  for block in blockcandidates
    if collidebox.bottom() <= block.bottom()
      touch=true
  return touch


class PowerSuit extends GenericSprite
  constructor: (@pos) ->
    super @pos, 'suit.png'
PowerSuit::anchor = V 1/2, 1
PowerSuit::collide = ( otherent ) ->
  if otherent instanceof BugLady
    @KILLME=true
    otherent.timers.powerup = 45
    settings.altcostume=false
    achieve "suit"


class ControlObj
  constructor: ->
    @bindings={}
    @holdbindings={}
    @heldkeys=[]
    @bindingnames={}
    @removedkeys=[]


ControlObj::trimheldkeys = ->
  @heldkeys = _.difference @heldkeys,  @removedkeys
  @removedkeys = []

control = new ControlObj
@control = control

normalizekey = (key) -> key.toUpperCase().charCodeAt 0

ControlObj::keytapbindraw = ( key, func ) ->
  @bindings[key]=func
ControlObj::keytapbind = ( key, func ) ->
  @bindings[normalizekey(key)]=func
ControlObj::keytapbind = ( key, func ) ->
  @bindings[normalizekey(key)]=func

ControlObj::keytapbindname = ( key, name, func ) ->
  @bindingnames[normalizekey(key)]=name
  @keytapbind key, func

ControlObj::keyBindRawNamed = ( key, name, func ) ->
  @bindingnames[key]=name
  @keytapbindraw key, func
ControlObj::keyBindCharNamed = (key, name, fnc ) ->
  @keyBindRawNamed keyCharToCode[key], name, fnc

ControlObj::keyholdbind = ( key, func ) ->
  @holdbindings[normalizekey(key)]=func
ControlObj::keyholdbindname = ( key, name, func ) ->
  @bindingnames[normalizekey(key)]=name
  @holdbindings[normalizekey(key)]=func

ControlObj::keyHoldBindRawNamed = ( key, name, func ) ->
  @bindingnames[key]=name
  @holdbindings[key]=func

if settings.devmode
  control.keytapbindname '9', 'zoom out', -> camera.zoomout()
  control.keytapbindname '0', 'zoom in', -> camera.zoomin()


_doc=document
launchFullScreen = (elm) ->
  elm.requestFullScreen?()
  elm.mozRequestFullScreen?()
  elm.webkitRequestFullScreen?()
cancelFullScreen = (elm) ->
  _doc.cancelFullScreen?()
  _doc.mozCancelFullScreen?()
  _doc.webkitCancelFullScreen?()
isfullscreen = ->
  _doc.fullscreenElement || _doc.mozFullscreenElement || _doc.webkitFullscreenElement
_toggleFullScreen = (elm) ->
  if isfullscreen()
    cancelFullScreen elm
  else
    launchFullScreen elm

toggleFullScreen = (elm) ->
  _toggleFullScreen(elm)
  [x,y]=[0,0]
  if isfullscreen()
    [x,y] = [screen.width,screen.height]
  else
    [x,y] = [screensize_default.x, screensize_default.y]
  renderer.resize x, y
  screensize = V x, y


control.keytapbindname 'y', 'toggle fullscreen', ->
  toggleFullScreen renderer.view

pausefunc = ->
  playsound "pause.wav"
  settings.paused = not settings.paused
  if settings.paused
    playsound "gimmebreak.ogg", 1
  else
    playsound "gameon.ogg", 1
  if settings.paused then parentstage.addChild pausescreen
  if not settings.paused then parentstage.removeChild pausescreen

control.keytapbindname 'p', 'pause', pausefunc
control.keyBindCharNamed 'Pause/Break', 'pause', pausefunc
control.keyBindCharNamed 'Enter', 'pause', ->
  key = keyCharToCode["Alt"]
  if key in control.heldkeys
    toggleFullScreen renderer.view
  else
    pausefunc()

control.keyBindCharNamed 'Esc', 'pause', pausefunc


if settings.devmode
  control.keytapbindname 't', 'underclock/slowmo', ->
    settings.slowmo = not settings.slowmo

  control.keytapbindname 'g', 'toggle grid', ->
    settings.grid = not settings.grid

control.keytapbindname 'l', 'WHAM!', ->
  #ladybug.jumping=true
control.keyholdbind 'l', -> ladybug.timers.attack=10

BugLady::dirfaced = -> if @facingleft then -1 else 1
_facing = (ent) -> if ent.facingleft then -1 else 1
punch = -> ladybug.state_set "punch"
kick = ->
  if isholdingbound 'up'
    ladybug.state_set "roundhouse"
  else
    ladybug.state_set "kick"

control.keytapbindname 'e', 'charge suit', ->
  return if settings.altcostume
  #if ladybug.shield then return
  return if ladybug.energy < 1
  ladybug.energy--
  ladybug.timers.charge = 10
  #ladybug.timers.powerup = 2

control.keyholdbindname 'i', 'guard', ->
  if ladybug.timers.charge
    ladybug.timers.charge=0
    ladybug.timers.invincible=60
    sb = new Shieldbubble()
    sb.pos = ladybug.pos
    WORLD.entAdd sb
    ladybug.shield = sb
  ladybug.timers.fightstance=4
control.keytapbindname 'j', 'POW!', punch
control.keytapbindname 'k', 'BAM!', kick
control.keytapbindname 'm', 'mute', ->
  settings.muted = not settings.muted

up = ->
  if ladybug.timers.charge
    ladybug.timers.charge=0
    ladybug.jumping = true
    ladybug.vel.y -= 20
jump = ->
  if ladybug.touchingground()
    playsound "jump.wav"
  ladybug.jumping=true
down = -> #noop

bugspeed = -> 1
#dont allow "regular" acceleration beyond this value
MAXBUGSPEED = 10

_particle = () ->
  pcho = new PchooParticle entcenter ladybug
  pcho.vel = mafs.randvec().nmul 2
  WORLD.entAdd pcho

bugthrust = (vel) ->
  ladybug.vel.x=vel
  ladybug.vel.y=0
  ladybug.timers.hover=8
  [0..10].forEach _particle

_sidestep = (dir) ->
  if ladybug.touchingground()
    ladybug.vel.x = dir*8
    ladybug.vel.y-=4

#direction: LEFT -1 or RIGHT +1
_dash = (dir) ->
  return if not ladybug.timers.charge
  ladybug.timers.charge=0
  bugthrust dir*20

_move = (dir) ->
  if isholdingbound 'cling' #doubles as a sprint for now
    MAXBUGSPEED = 12
  else
    MAXBUGSPEED = 8
  if ladybug.timers.fightstance > 0
    _sidestep dir
    return
  _dash dir
  if not settings.aircontrol and not ladybug.touchingground() then return
  if ladybug.touchingground() or ladybug.vel.x*dir>8
    ladybug.facingleft = dir is -1
  vx = ladybug.vel.x+bugspeed()*dir
  if !settings.forcemove and Math.abs(vx) < MAXBUGSPEED
    ladybug.vel.x=vx
  if settings.forcemove and Math.abs(ladybug.vel.x) < MAXBUGSPEED
    ladybug.vel.x+=bugspeed()*dir

left = -> _move -1
right = -> _move 1

availableactions = [ up, down, left, right ]

AKA = (func) => (args...) => func args...
_bind = (args...) -> control.keyholdbindname args...

_bind 'w', 'up', up
_bind 's', 'down', down
_bind 'a', 'left', left
_bind 'd', 'right', right
_bind 'x', 'boggle', -> #noop

ControlObj::keyHoldBindCharNamed = ( key, name, func ) ->
  @keyHoldBindRawNamed keyCharToCode[key], name, func

control.keyHoldBindCharNamed 'Up', 'up', up
control.keyHoldBindCharNamed 'Down', 'down', down
control.keyHoldBindCharNamed 'Left', 'left', left
control.keyHoldBindCharNamed 'Right', 'right', right

control.keyHoldBindCharNamed 'Space', 'jump', jump
control.keyHoldBindCharNamed 'Shift', 'cling', -> #noop


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

record_s = ->
  jame.demofile = [] #clear the demo, doi
  settings.recordingdemo = true
  settings.playingdemo = false
  alert "recording demo"
  restartlevel()

record_l = ->
  settings.recordingdemo = false
  settings.playingdemo = true
  alert "replaying demo"
  console.log jame.demofile
  restartlevel()

control.keytapbindname '6', 'record', record_s
control.keytapbindname '7', 'replay', record_l


settings.layer = 1
changelayer = (num) ->
  settings.layer = num

if settings.devmode
  control.keytapbindname '1', 'layer1', -> changelayer 1
  control.keytapbindname '2', 'layer2', -> changelayer 2

#wee woo here is where we store level list
level_files = ["1.json", "2.json"]
CURRENT_LEVEL = 0

_loadcurrlevel = ->
  loadlevelfile "levels/"+level_files[CURRENT_LEVEL]

nextlevel = ->
  return if settings.grid or ladybug.timers.fightstance
  CURRENT_LEVEL++
  if CURRENT_LEVEL >= level_files.length
    CURRENT_LEVEL = 0
    alert 'u win'
    achieve "win"
  restartlevel()

restartlevel = ->
  WORLD.clear()
  _loadcurrlevel()
  WORLDINIT()
  ladybug.respawn()

if settings.devmode
  control.keytapbindname 'r', 'restart level', restartlevel
  control.keytapbindname 'n', 'change level', nextlevel

@CONTROL = control

#eventelement = $ document
eventelement = $ renderer.view

eventelement.attr onclick: "this.focus()"
body.attr onload: -> eventelement.focus()

reservedkeys = [] #blank
reserveKeyNamed = (key) -> reservedkeys.push keyCharToCode[key]

reserveKeyNamed(key) for key in [ "Space", "Up", "Down", "Backspace" ]

eventelement.bind 'keydown', (e) ->
  key = e.which
  control.bindings[key]?()
  if not (key in control.heldkeys)
    control.heldkeys.push key
  if key in reservedkeys
    return false

eventelement.bind 'keyup', (e) ->
  key = e.which
  #remove at the end of next frame instead
  control.removedkeys.push key
  #control.heldkeys = _.without control.heldkeys, key
  if key in reservedkeys
    return false

tmpcanvasjq = $ "<canvas>"
tmpcanvas = tmpcanvasjq[0]

Block::gethitbox = () -> @
Block::initsprite = () ->
  #src = @src or "genbrick.png"
  #tex = PIXI.Texture.fromImage sourcebaseurl+src
  tex = blocktextures[@tile]
  sprit = new PIXI.extras.TilingSprite tex, @w, @h
  @_pixisprite=sprit
  stage.addChild sprit

Block::render = ->
  if not @hassprite() then @initsprite()
  sprit = @_pixisprite
  sprit.tilePosition = PP -@x, -@y
  sprit.position = PP @x, @y

class Water extends Block
  constructor: (@x,@y,@w,@h) ->
    super @x, @y, @w, @h
    @src = "snow.png"
Water::render = ->
  super()
  @_pixisprite.tilePosition.y = -tickno/2
  @_pixisprite.tilePosition.x = 16 * Math.cos tickno/100
  @_pixisprite.alpha=0.5

class OnewayBlock extends Block
  constructor: (@x,@y,@w,@h) ->
    super @x, @y, @w, @h
    @src = "groundstone.png"

ladybug = new BugLady

class Cloud extends Renderable
  constructor: () ->
    super()
    @src='bigcloud.png'

Cloud::spriteinit = () ->
  tex = TEXBYNAME @src
  sprit = new PIXI.extras.TilingSprite tex, screensize.x, screensize.y
  @_pixisprite=sprit
  parentstage.addChildAt sprit, 0
  return sprit

class Grid extends Renderable
  constructor: () ->
    super()
    @src='square.png'

adjustedscreensize = ->
  return x: screensize.x*10, y: screensize.y*10

Grid::PIXINIT = Cloud::PIXINIT = ->
  if not @_pixisprite
    tex = TEXBYNAME @src
    {x,y}=adjustedscreensize()
    sprit = new PIXI.extras.TilingSprite tex, x,y
    @_pixisprite=sprit
    parentstage.addChildAt sprit, 0
Cloud::cleanup = ->
  if @_pixisprite
    parentstage.removeChild @_pixisprite
    @_pixisprite=undefined

Grid::PIXREMOVE = ->
  if not settings.grid and @_pixisprite
    parentstage.removeChild @_pixisprite
    @_pixisprite=undefined

Cloud::render = () ->
  pos = cameraoffset()
  flip = false
  @PIXINIT()
  sprit = @_pixisprite
  offset=V tickno*-0.2, 0 #Math.sin(tickno/200)*64
  #sprit.position = VTOPP pos
  sprit.tilePosition = VTOPP offset
  if settings.grid then @cleanup()

Grid::render = () ->
  pos = cameraoffset()
  flip = false
  @PIXINIT()
  sprit = @_pixisprite
  #sprit.position = VTOPP pos
  offset = pos.nmul -1
  sprit.tilePosition = new PIXI.Point offset.x, offset.y
  @PIXREMOVE()


class World
  constructor: () ->
    @entities=[]
    @bglayer=[]
    @fglayer=[]
    @spritelayer=[]

World::entAdd = (ent) ->
  @spritelayer.push ent
World::spritesRemove = (doomed) ->
  @spritelayer = _.difference @spritelayer, doomed


WORLD=new World

randpos = -> V(640*1.5,64*2).vadd mafs.randvec().vmul V 640, 480

class Shrub extends GenericSprite
  constructor: (@pos) ->
    super @pos, 'shrub.png'
    @anchor=V 1/2,1

placeshrub = (pos) ->
  WORLD.fglayer.push new Shrub pos

class DoubleJumper extends PlaceholderSprite
  constructor: (@pos) ->
    super @pos
    @label = "airjump"
  anchor: V 1/2, 1
  collide: ( otherent ) ->
    if otherent instanceof BugLady
      @KILLME=true
      otherent.timers.powerup = 45
      settings.airjump=true

class BugMeter extends GenericSprite
  constructor: () ->
    super()
    @src='bughealth.png'
    @value=3
    @abspos = V 0, 0
    @spritesize = V 32, 32
    @layer = HUDLAYER

BugMeter::spriteinit = () ->
  tex = TEXBYNAME @src
  sprit = new PIXI.extras.TilingSprite tex, @spritesize.x*@value, @spritesize.y
  @_pixisprite=sprit
  @layer.addChild sprit
  return sprit
BugMeter::cleanup = () ->
  stageremovesprite @layer, @

BugMeter::render = () ->
  pos = @abspos
  flip = false
  if not @_pixisprite then @spriteinit()
  sprit = @_pixisprite
  sprit.zIndex = 100
  sprit.width = @spritesize.x*@value
  sprit.scale = PP settings.hudscale, settings.hudscale
  sprit.position = VTOPP pos
BugMeter::tick = () ->
  @update ladybug.health
BugMeter::update = (value) ->
  stageremovesprite HUDLAYER, @
  @value = value

class EnergyMeter extends BugMeter
  constructor: () ->
    super()
    @src='energy1.png'
    @abspos = V 0, 16
EnergyMeter::tick = () -> @update ladybug.energy
class MoneyMeter extends BugMeter
  constructor: () ->
    super()
    @src='crown.png'
    @spritesize = V 16,16
    @abspos = V 8, 64-16
  tick: () ->
    @update ladybug.score

Block::toJSON = ->
  [ @x, @y, @w, @h, @tile ]

loadblocks = (blockdata) ->
  blockdata.forEach (blockdatum) ->
    [x,y,w,h,src]=blockdatum
    WORLD.addblock bl= new Block x, y, w, h
    if typeof src is "number" then bl.tile = src
    bl.src = src

loadspawners = (entdata) ->
  entdata.forEach (entdatum) ->
    WORLD.entAdd spawner=new Spawner entdatum.pos
    spawner.entdata = entdatum

class Goal extends PlaceholderSprite
  constructor: (@pos) ->
    super @pos
    @label="GOAL"
Goal::collide = ( otherent ) ->
  if otherent instanceof Hero
    nextlevel()

class Platform extends PlaceholderSprite
  constructor: (@pos) ->
    super @pos
    @size = V 64,32
    @label="platform"
    @anchor = V 0, 1
    @t=0
  tick: () ->
    if !@origpos
      @origpos = @pos.nadd 0
    @t++
    @pos.y = @origpos.y + Math.sin( @t/100 ) * 64
#Platform::collide = ( otherent ) ->
#  if otherent instanceof Hero
#    otherent.vel.y = 0


class HurtWire extends GenericSprite
HurtWire::size = V 8, 32
HurtWire::anchor = V 1/2, 0
HurtWire::getsprite = ->
  framewait = 1
  framelist = [ "wire.png" ]
  if @state=="sparking"
    framelist = [1..4].map (n) -> "wirespark#{n}.png"
  return selectframe framelist, framewait
HurtWire::tick = ->
  @age = @age or 0
  @age = (@age+1)%100
  if @age < 30
    @state="sparking"
  else
    @state="inert"
HurtWire::collide = ( otherent ) ->
  if @state=="sparking" and otherent instanceof Hero
    otherent.takedamage()
HurtWire::render = ->
  @src=@getsprite()
  super()


spawnables = powersuit: PowerSuit, doublejumper: DoubleJumper,
gold: Gold, energy:Energy, lila: Lila, platform: Platform,
robot: Robo, robo: Robo, turret: Turret, #enemies
"HurtWire": HurtWire, "Energy": Energy, "Gold": Gold, "Thug": Thug,
"Shrub": Shrub, goal: Goal

class Spawner extends PlaceholderSprite
  constructor: (@pos) ->
    super @pos
    @label="Entity spawner"
    @entdata=class: GenericSprite, pos: @pos
Spawner::render = ->
  #want these to be invisible except in grid view
  if not settings.grid
    removesprite @
  else
    super()
Spawner::tick = ->
  #update the data so if this is moved it'll get saved
  @entdata.pos = @pos
  #console.log @entdata.pos
  @label = @entdata.class
Spawner::spawn = ->
  #ent=jame.spawn @classname
  #ent.load @entdata
  loadents [@entdata]
Spawner::toJSON = ->
  @entdata


jame={}
jame.spawn = (classname) ->
  if not spawnables[classname]
    return
  ent=new spawnables[classname]?()
  WORLD.entAdd ent
  return ent

loadent = (entdatum) ->
  if not spawnables[entdatum.class]
    WARN "tried to spawn nonexistant entity class #{classname}"
    return
  #oh god why
  spawner = new Spawner()
  spawner.pos.x = entdatum.pos.x
  spawner.pos.y = entdatum.pos.y
  console.log entdatum
  spawner.entdata = entdatum
  WORLD.entAdd spawner
  ent=jame.spawn entdatum.class
  ent.load entdatum

WORLD.addblock = (block) ->
  if block.layer is 2
    WORLD.entAdd block
  else
    WORLD.bglayer.push block

loadents = (entdata) ->
  entdata.forEach (entdatum) -> loadent entdatum


WORLDINIT = () ->
  WORLD.entities.push new Cloud()
  WORLD.entities.push new Grid()
  bugmeter= new BugMeter
  WORLD.entities.push bugmeter
  energymeter= new EnergyMeter
  WORLD.entities.push energymeter
  WORLD.entities.push new MoneyMeter
  @bugmeter = bugmeter
  WORLD.entAdd ladybug

randtri = ->
  new Poly [ randpos(), randpos(), randpos() ]

WORLD.getallents = ->
  return [].concat WORLD.entities, WORLD.spritelayer, WORLD.bglayer, WORLD.fglayer

WORLD.clear = ->
  tickno = 0
  ALLENTS = WORLD.getallents()
  renderables = ALLENTS.filter (ent) -> ent instanceof Renderable
  renderables.forEach (ent) -> ent.cleanup?()
  WORLD.entities=[]
  WORLD.spritelayer=[]
  WORLD.bglayer=[]
  WORLD.fglayer=[]
  resetstage()


loadlevel = (data) ->
  loadblocks data.blockdata
  loadents data.ents


loadlevelfile = (levelfilename) ->
  WORLD.doneloading=false
  $.ajax levelfilename, success: (data,status,xhr) ->
    #jsondata=JSON.parse data
    jsondata = data
    loadlevel jsondata
    WORLD.doneloading=true
    settings.paused = false

_loadcurrlevel()
WORLDINIT()

camera={}
jame.camera=camera
camera.offset=V()
camera.pos=V()
camera.trackingent = ladybug
camera.zoomout = ->
  scale-=0.1
  scale = mafs.clamp scale, 0.1, 1
camera.zoomin = ->
  scale+=0.1
  scale = mafs.clamp scale, 0.1, 1


cameraoffset = ->
  #for debugging, hitboxes are easier to read if the camera is kept still
  #if settings.grid or ladybug.timers.fightstance then return camera.pos
  tmppos = camera.trackingent.pos.nadd 0
  offs = camera.trackingent.vel.vmul V 5, 0
  tmppos = tmppos.vadd offs
  tmppos.y = mafs.roundn tmppos.y, 256
  tmppos = tmppos.vsub camera.offset.ndiv scale
  tmppos = tmppos.vsub screensize.ndiv 2*scale
  #return tmppos
  return camera.pos.vadd tmppos.vsub(camera.pos).ndiv 10

camera.tick = ->
  camera.pos = cameraoffset()

###
stage.updateLayersOrder = ->
  stage.children.sort (a,b) ->
    a.zIndex ?= 0
    b.zIndex ?= 0
    return b.zIndex-a.zIndex
###

render = ->
  camera.tick()
  renderables = [].concat WORLD.bglayer, WORLD.spritelayer, [ladybug], WORLD.fglayer, WORLD.entities
  renderables.forEach (ent) -> ent.render?()
  highlighted = renderables.filter (ent) -> ent.HIGHLIGHT?
  highlighted = highlighted.concat getCursorBlocks()
  if settings.grid then highlighted = renderables
  drawhitboxes highlighted
  #stage.updateLayersOrder()

drawhitboxes = ( ents ) ->
  stage.removeChild hitboxlayer
  hitboxlayer = new PIXI.Container
  stage.addChild hitboxlayer
  graf = new PIXI.Graphics()
  graf.lineStyle 1, 0x00ff00, 1
  graf.beginFill 0xff0000, 1/8
  ents.forEach (ent) ->
    graf.lineStyle 1, 0x00ff00, 1
    graf.drawCircle ent.pos.x, ent.pos.y, 4
    box = ent.gethitbox?()
    if not box then return
    graf.drawRect box.x, box.y, box.w, box.h
    velbox = ent.fallbox?()
    if not velbox then return
    graf.lineStyle 1, 0x0000ff, 1
    graf.drawRect velbox.x, velbox.y, velbox.w, velbox.h
  hitboxlayer.addChild graf

#returns elapsed time in ms.
timecall = (func) ->
  starttime = Date.now()
  func()
  Date.now()-starttime

tickwaitms = 20
skipframes = 0
ticktimes = []

WORLD.gethitbox = (sprite) -> sprite.gethitbox()

checkcolls = ( ent, otherents ) ->
  if settings.NOCOLLS then return false
  #bawks = ent.gethitbox()
  bawks = WORLD.gethitbox ent
  otherents.forEach (target) ->
    if target is ent then return
    #targethitbox = target.gethitbox()
    targethitbox = WORLD.gethitbox target
    if bawks.overlaps targethitbox
      target.collide?(ent)

#remove entities that requested death
WORLD.euthanasia = ->
  doomedsprites = WORLD.spritelayer.filter (sprite) -> sprite.KILLME?
  doomedsprites.forEach (sprite) -> sprite.cleanup?()
  WORLD.spritesRemove doomedsprites

reset_tick_stats = () ->
  stats.collisionchecks=0

COLLGRIDSIZE=64
WORLD.collgrid =
  contents: []
  clear: -> @contents=[]
  getraw: (rect,ignore=[]) ->
    i=Math.floor(rect.x/COLLGRIDSIZE)
    ar = @contents?[i] or []
    ar = ar.filter (objrect) -> objrect.obj not in ignore
    return ar
  get: (rect,ignore=[]) ->
    if not Array.isArray(ignore) then ignore=[ignore]
    i=Math.floor(rect.x/COLLGRIDSIZE)
    ar = @contents?[i] or []
    ar = ar.filter (objrect) -> objrect.obj not in ignore
    return _.pluck ar, 'rect'
  set: (rect, obj) ->
    i=Math.floor(rect.x/COLLGRIDSIZE)
    @contents[i]=@contents[i] or []
    @contents[i].push {obj,rect}

WORLD.updateboxes = () ->
  WORLD.collgrid.clear()
  WORLD.BOXCACHE = []

#heres the info box thing that follows the cursor

css=transition: "background .2s", boxShadow: "4px 4px 8px rgba(0,0,0,.5)",
top: "200px", left: "400px", position: "absolute", width: 32, height: 32,
background: "url('sprites/metroid like.png')"

WORLD.xx = [
  {
    elm: do ->
      return if not settings.devmode
      e=$ "<div>"
      e.css css
      e.appendTo body
      e
    tick: ->
      return if not settings.devmode
      pos=gettileoffs TILESELECT, 20, 16
      pos=pos.nmul -16
      @elm.css backgroundPosition: pos.x+" "+pos.y
      @elm.css left: 16+SCREENCURS.x+'px', top: 16+SCREENCURS.y+'px'
  }
]



jame.demofile=[]
recordinputs = () ->
  if not settings.recordingdemo then return false
  ech = []
  ech = ech.concat control.heldkeys
  jame.demofile.push ech


#replace sequential duplicates in an array with a given value
#i.e. _repdupes([1,1,1,7,3,3,1,1], "x") == [1,0,0,7,3,0,1,0]
# _repdupes("oooh shiiiit","~").join("") == "o~~h shi~~~t"
_repdupes = (arr,rep) ->
  (for x in arr
    if x is prev then rep else prev=x )

_demotick = () ->
  recordinputs()
  if settings.playingdemo
    tmpks= jame.demofile[tickno..tickno+64].map (x) -> x.toString()
    tmpks = _repdupes tmpks, "~~"
    tmpks = tmpks.map (s) -> if s is "" then "  " else s
    TICKLOG xmlwrap 'pre', tmpks.join ","
    if tickno >= jame.demofile.length
      settings.playingdemo = false
      alert "replay over"
    else
      control.heldkeys = jame.demofile[tickno]

WORLD.tick = () ->
  _demotick()
  reset_tick_stats()
  for key in control.heldkeys
    control.holdbindings[key]?()
  WORLD.updateboxes()
  checkcolls ladybug, WORLD.spritelayer
  WORLD.spritelayer.forEach (sprite) ->
    checkcolls sprite, _.without WORLD.spritelayer, sprite
  WORLD.euthanasia()
  ACTIVEENTS = [].concat WORLD.spritelayer, WORLD.entities, WORLD.xx
  #ACTIVEENTS.forEach (ent) -> ent.updatehitbox?()
  ACTIVEENTS.forEach (ent) -> ent.tick?()
  #render()
  tickno++


fpscounter=$ xmltag()
fpscounter.attr class: "ticklog"
tt=0

updateinfobox = ->
  text= control.heldkeys.map (key) -> "<span>#{keyCodeToChar[key]}</span>"
  $(infobox).html text.join " "

# for displaying info that is updated every frame
TICKLOG = (datum) ->
  return if not settings.devmode
  fpscounter.append $ xmlwrap 'div', datum

_ml = ->
  getCursorBlocks().forEach (bl) ->
    tmp = [bl.x,bl.y,bl.w,bl.h].map (n) -> n/settings.gridsize
    TICKLOG tmp.join ", "

hz = (ms) -> Math.round 1000/ms

#all this framerate nonsense seems overly fancy and hacked together,
#see if you can just cut it all out
mainloop = ->
  #TODO: updating the settings table should
  #only be done when values actually change
  if tickno % 300 is 0
    updatesettingstable()
  updateinfobox()
  if not WORLD.doneloading then settings.paused = true
  fpscounter.html ""
  if not settings.paused
    ticktime = timecall WORLD.tick
    tt=ticktime
    fps=hz Math.max(tickwaitms,ticktime)
    idealfps=hz tickwaitms
    TICKLOG "~#{fps}/#{idealfps} fps ; per tick: #{tt}ms"
    TICKLOG "#{stats.collisionchecks} collisionchecks"
    _ml()
  fpsgoal = if settings.slowmo then 4 else settings.fps
  tickwaitms = hz fpsgoal
  dms = tickwaitms-ticktime
  TICKLOG dms
  control.trimheldkeys()
  setTimeout mainloop, Math.max dms, 1
  #requestAnimationFrame animate

xmlwrap = (tagname,body) ->
  xmltag tagname, undefined, body

maketablerow = ( values ) ->
  tds = values.map (v) -> xmlwrap "td", v
  return xmlwrap "tr", tds
jame.maketable = (arrofarr) ->
  domelm = $ '<table>'
  for k,v of arrofarr
    domelm.append maketablerow v
  return domelm

selectall = (classname) ->
  jame.WORLD.spritelayer.filter (obj) -> obj.constructor.name == classname

jame.listents = () ->
  ents=_.pairs _.countBy jame.WORLD.spritelayer, (obj) -> obj.constructor.name
  body.append jame.maketable ents

infobox = $ "<div>"
infobox.css float: "right", border: "1px solid black"

body.append infobox


bindingsDOM = $ "<table>"
bindingsDOMcontainer = $ "<details>"
bindingsDOMcontainer.append bindingsDOM

for k,v of control.bindingnames
  bindingsDOM.append maketablerow [keyCodeToChar[k],v or "??"]

#tmp, fix this shit
_CHARbindingnames = {}
for k,v of control.bindingnames
  _CHARbindingnames[keyCodeToChar[k]]=v

settingsDOM = $ "<table>"
settingsDOMcontainer = $ "<details>"
settingsDOMcontainer.append settingsDOM
updatesettingstable = () ->
  settingsDOM.html ""
  for k,v of settings
    if ( v is true or v is false )
      tempv = xmltag "button",
        onclick: "jame.settings.#{k}=!jame.settings.#{k}", v
    else if ( typeof v is "number"  )
      tempv = xmltag "input",
        type: "number", oninput: "jame.settings.#{k}=parseFloat(this.value)", value: v
    else tempv = v
    settingsDOM.append maketablerow [k,tempv]

INIT = ->
  if settings.devmode
    body.append fpscounter
  bindingsDOMcontainer.append "<summary>bindings:</summary>"
  #DEPENDS ON  keyboarddisplay.js
  body.append $ "<br/>"
  body.append keyboardlayout.visualize _CHARbindingnames
  body.append bindingsDOMcontainer
  settingsDOMcontainer.append "<summary>settings:</summary>"
  body.append settingsDOMcontainer
  mainloop()
  requestAnimationFrame animate

INIT()


# LEVEL EDITING SECTION
#

adjustmouseevent = (e) ->
  coffs=$(renderer.view).offset()
  adjusted = V e.pageX-coffs.left, e.pageY-coffs.top
  adjusted = adjusted.ndiv scale
  adjusted = adjusted.vadd camera.pos
  adjusted = adjusted.op Math.round
  return adjusted

class Tool
  constructor: ->

NOOPTOOL = name: 'noop', mousedown: (->), mouseup: (->), mousemove: (->)

BLOCKCREATIONTOOL = _.extend {}, NOOPTOOL,
  name: 'create block'
  creatingblock: false
  mousedown: (e) ->
    #ADD BLOCK, LEFT MBUTTON
    #HOLD Z TO SNAP TO GRID
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    BLOCKCREATIONTOOL.creatingblock=new Block adjusted.x, adjusted.y, 16, 16
    BLOCKCREATIONTOOL.creatingblock.layer = settings.layer
    BLOCKCREATIONTOOL.creatingblock.tile = TILESELECT
    WORLD.addblock BLOCKCREATIONTOOL.creatingblock
  mouseup: (e) ->
    BLOCKCREATIONTOOL.creatingblock.fixnegative()
    BLOCKCREATIONTOOL.creatingblock = false
  mousemove: (e) ->
    mpos = snapmouseadjust adjustmouseevent e
    creatingblock = BLOCKCREATIONTOOL.creatingblock
    if creatingblock
      creatingblock.w = mpos.x-creatingblock.x
      creatingblock.h = mpos.y-creatingblock.y
      if creatingblock.w is 0 then creatingblock.w = 16
      if creatingblock.h is 0 then creatingblock.h = 16
      creatingblock.removesprite()

__snap = (mpos,func) ->
  mpos.ndiv(settings.gridsize).op(func).nmul(settings.gridsize)

snapmouseadjust_always = (mpos) ->
  __snap mpos, Math.round
snapmouseadjust_down = (mpos) ->
  __snap mpos, Math.floor

snapmouseadjust = (mpos) ->
  snaptogrid = isholdingkey 'z'
  if not snaptogrid
    return snapmouseadjust_always mpos
  return mpos

#short undescriptive name wow such syntax sugar
smame = (e) -> snapmouseadjust adjustmouseevent e

class MoveTool extends Tool
MoveTool::name = 'move entities'
MoveTool::constructor = ->
  @selected = []

MoveTool::mouseup = (e) ->
  #p = adjustmouseevent e
  #@selected.forEach (ent) ->
  #  ent.pos = p
  @selected = []
  setcursor 'auto'
MoveTool::mousemove = (e) ->
  @selected = @selected or [] #jesus christ how horrifying
  isSelecting = @selected.length > 0
  p = adjustmouseevent e
  entsundercursor = getentsunderpoint p
  if isSelecting
    setcursor browserprefix+"grabbing"
  else
    setcursor 'auto'
  if entsundercursor.length > 0
    setcursor browserprefix+"grab"
  p = snapmouseadjust p
  @selected.forEach (ent) ->
    ent.pos = p
    ent.vel = V()
class MoveBlockTool extends Tool
  name: 'move blocks'
  constructor: ->
    @selected = []
    @relpos = V 0,0
    @relative_positions = []
  mouseup: (e) ->
    @isholding = false
    setcursor 'auto'
  mousehold: (e) ->
    @selected = @selected or [] #jesus christ how horrifying
    isSelecting = @selected.length > 0
    @selected.forEach (ent, i) =>
      p = adjustmouseevent e
      p = p.vsub @relative_positions[i]
      p = snapmouseadjust p
      ent.pos = p
      ent.x = p.x
      ent.y = p.y
      ent.render()
  mousemove: (e) ->
    if @isholding then @mousehold e
MoveBlockTool::mousedown = (e) ->
  @isholding = true
  p = adjustmouseevent e
  blocksundercursor = blocksatpoint WORLD.bglayer, p
  if blocksundercursor.length is 0
    @selected.forEach (e) -> e.HIGHLIGHT = undefined
    @selected=[]
  else
    @selected=@selected.concat blocksundercursor
  @selected.forEach (e) -> e.HIGHLIGHT = true
  @relpos = p.vsub @selected[0].pos
  @relative_positions = @selected.map (e) -> p.vsub e.pos

getentsunderpoint = (p) ->
  WORLD.spritelayer.filter (ent) ->
    box = ent.gethitbox?()
    return box and box.containspoint p

MoveTool::mousedown = (e) ->
  p = adjustmouseevent e
  entsundercursor = getentsunderpoint p
  @selected=entsundercursor

setcursor = (cursorname) ->
  $(renderer.view).css 'cursor', cursorname

MOVETOOL=new MoveTool()
MOVETOOL.selected = []
MOVEBLOCKTOOL=new MoveBlockTool()

tool = MOVETOOL
prevtool = MOVETOOL

$(renderer.view).mousedown (e) ->
  return if not settings.devmode
  if e.button is MLEFT then tool.mousedown? e
  if e.button is MRIGHT then prevtool.mousedown? e
$(renderer.view).mouseup (e) ->
  return if not settings.devmode
  if e.button is MLEFT then tool.mouseup? e
  if e.button is MRIGHT then prevtool.mouseup? e
$(renderer.view).mousemove (e) ->
  return if not settings.devmode
  tool.mousemove? e
  prevtool.mousemove? e

randposrel = (p=V()) -> p.vadd mafs.randvec().vmul V 32,32
TRIANGLETOOL=_.extend {}, NOOPTOOL,
  name: "add triangle"
  mousedown: (e) ->
    p = adjustmouseevent e
    triangle=new Poly [ randposrel(p), randposrel(p), randposrel(p) ]
    WORLD.entAdd triangle
  mouseup: (e) ->
  mousemove: (e) ->

SPAWNTOOL= name: 'Spawn entity'
SPAWNTOOL.classname = 'burd'
SPAWNTOOL.mousedown = (e) ->
  p = adjustmouseevent e
  ent=jame.spawn SPAWNTOOL.classname
  ent.pos = p

SPAWNTOOL.mouseup = (e) ->
SPAWNTOOL.mousemove = (e) ->

SPAWNERTOOL=_.extend {}, NOOPTOOL,
  name: 'Spawn entity'
  classname: 'burd'
  mousedown: (e) ->
    p = adjustmouseevent e
    WORLD.entAdd ent=new Spawner p
    ent.pos = p
    ent.entdata.class = SPAWNTOOL.classname
    ent.spawn()

TELEPORTTOOL=_.extend {}, NOOPTOOL,
  name: "teleport"
  mousedown: (e) ->
    p = adjustmouseevent e
    ladybug.pos = p
    ladybug.vel = V 0,0


# take a list of Block objects
# return a bounding block
boxesbounding = (boxlist) ->
  ls=boxlist.map (b) -> b.left()
  rs=boxlist.map (b) -> b.right()
  ts=boxlist.map (b) -> b.top()
  bs=boxlist.map (b) -> b.bottom()
  l=ls.reduce (n,m) -> Math.min n,m
  r=rs.reduce (n,m) -> Math.max n,m
  t=ts.reduce (n,m) -> Math.min n,m
  b=bs.reduce (n,m) -> Math.max n,m
  return new Block l,t,r-l,b-t

# ughhhh
blockcarve = ( aa, bb ) ->
  b = boxesbounding [ aa, bb ]
  a = aa.intersection(bb)
  x1= b.left()
  x2= a.left()
  x3= a.right()
  x4= b.right()
  y1= b.top()
  y2= a.top()
  y3= a.bottom()
  y4= b.bottom()
  blokx=[ [ x1, y1, x2-x1, y2-y1 ]
  [ x2, y1, x3-x2, y2-y1 ]
  [ x3, y1, x4-x3, y2-y1 ]
  [ x1, y2, x2-x1, y3-y2 ]
  [ x2, y2, x3-x2, y3-y2 ]
  [ x3, y2, x4-x3, y3-y2 ]
  [ x1, y3, x2-x1, y4-y3 ]
  [ x2, y3, x3-x2, y4-y3 ]
  [ x3, y3, x4-x3, y4-y3 ]
  ]
  blokx=blokx.map (blok) ->
    newthing=new Block blok[0], blok[1], blok[2], blok[3]
    newthing.fixnegative()
    return newthing
  blokx=blokx.filter (blok) ->
    blok.strictoverlaps(aa) or blok.strictoverlaps(bb)
  #_.extend WORLD.bglayer, blokx
  for blok in blokx
    WORLD.addblock blok
  return blokx

unfuck = (p) ->
  blocks = blocksatpoint WORLD.bglayer, p
  if blocks.length == 2
    a=blocks[0]
    b=blocks[1]
    blockcarve a,b
    WORLD.bglayer = _.without WORLD.bglayer, a
    WORLD.bglayer = _.without WORLD.bglayer, b
    stage.removeChild a._pixisprite
    stage.removeChild b._pixisprite

UNIONTOOL=_.extend {}, NOOPTOOL,
  name: "unfuck block overlaps"
  mousedown: (e) ->
    p = adjustmouseevent e
    unfuck(p)

carveoutblock = (b) ->
  #copy because reasons
  block = new Block b.x, b.y, b.w, b.h
  tocarve=block.allstrictoverlaps()
  for bloke in tocarve
    newcarved=blockcarve bloke,block
    newcarved.forEach (blech) -> blech.tile = bloke.tile
  todelete=block.allstrictoverlaps()
  for bloke in todelete
    WORLD.bglayer = _.without WORLD.bglayer, bloke
    if bloke._pixisprite?
      stage.removeChild bloke._pixisprite


CARVER=_.extend {}, NOOPTOOL,
  name: "block carver"
  carve: (p) ->
    CARVER.creatingblock=new Block p.x, p.y, 32, 32
    WORLD.addblock CARVER.creatingblock
  mousedown: (e) ->
    #ADD BLOCK, LEFT MBUTTON
    #HOLD Z TO SNAP TO GRID
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    @carve adjusted
  mouseup: (e) ->
    CARVER.creatingblock.fixnegative()
    carveoutblock CARVER.creatingblock
    CARVER.creatingblock = false
  mousemove: (e) ->
    mpos = snapmouseadjust adjustmouseevent e
    creatingblock = CARVER.creatingblock
    if creatingblock
      creatingblock.w = mpos.x-creatingblock.x
      creatingblock.h = mpos.y-creatingblock.y
      creatingblock.src="lila.png"
      creatingblock.removesprite()

WATERTOOL=_.extend {}, NOOPTOOL,
  name: "turn block into water"
  mousedown: (e) ->
    if e.button != 0 then return
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    blocksundercursor = blocksatpoint WORLD.bglayer, adjusted
    for bl in blocksundercursor
      WORLD.spritelayer.unshift new Water bl.x, bl.y, bl.w, bl.h
      bglayer_remove_block bl

BASETOOL = _.extend {}, NOOPTOOL,
  held: false
  mousedown: (e) ->
    @held=true
    #if e.button is 0 then
    @leftclick adjustmouseevent e
  mouseup: (e) ->
    @held=false
  mousemove: (e) ->
    if @held then @lefthold adjustmouseevent e
  leftclick: (p) -> @action p
  lefthold: (p) -> @action p

BLOCKPAINT=_.extend {}, BASETOOL,
  name: "draw blocks"
  action: (p) ->
    gs=32
    tmp=settings.gridsize
    settings.gridsize = gs #hacky, code smell alert
    snapped=snapmouseadjust_down p
    blocksundercursor = blocksatpoint WORLD.bglayer, p
    if blocksundercursor.length == 0
      newblock=new Block snapped.x, snapped.y, gs, gs
      WORLD.addblock newblock
    settings.gridsize = tmp

alltools = [ MOVETOOL, TRIANGLETOOL, SPAWNERTOOL, TELEPORTTOOL ]
blocktools = [ BLOCKCREATIONTOOL, MOVEBLOCKTOOL, UNIONTOOL,
  CARVER, WATERTOOL, BLOCKPAINT ]

alltools.push _.extend {}, NOOPTOOL,
  name: "delete block"
  mousedown: (e) ->
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    selected=blocksatpoint WORLD.bglayer, adjusted
    tool_clickdelete adjusted

alltools.push _.extend {}, NOOPTOOL,
  name: "select entity"
  mousedown: (e) ->
    if e.button != 0 then return
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    selected=getentsunderpoint adjusted
    console.log selected[0]

mktool = (obj) -> alltools.push _.extend {}, BASETOOL, obj

mktool
  name: "painter"
  action: (p) ->
    for bl in getCursorBlocks()
      bl.tile=TILESELECT
      bl.removesprite()

mktool
  name: "picker"
  action: (p) ->
    selected=blocksatpoint WORLD.bglayer, p
    TILESELECT=selected[0].tile

alltools.push _.extend {}, NOOPTOOL,
  name: "turn block into oneway"
  mousedown: (e) ->
    if e.button != 0 then return
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    blocksundercursor = blocksatpoint WORLD.bglayer, adjusted
    for bl in blocksundercursor
      WORLD.bglayer.unshift new OnewayBlock bl.x, bl.y, bl.w, bl.h
      bglayer_remove_block bl

alltools.push _.extend {}, NOOPTOOL,
  name: "turn block into background"
  mousedown: (e) ->
    if e.button != 0 then return
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    blocksundercursor = blocksatpoint WORLD.bglayer, adjusted
    for bl in blocksundercursor
      WORLD.entities.unshift bl
      bglayer_remove_block bl

if settings.devmode
  toolbar = $ xmltag 'details', class: 'toolbar'
  toolbar.append $ xmltag 'summary', undefined, 'tools'
  toolbar.insertAfter $(renderer.view)
  makebutton = (t) ->
    but=$ xmltag 'button', undefined, t.name
    but.click ->
      prevtool = tool
      tool = t
      $(".toolbar button").css backgroundColor: 'lightgray'
      but.css backgroundColor: 'pink'
    toolbar.append but
  blocktools.forEach makebutton
  alltools.forEach makebutton


allactions={}
@allactions = allactions

bindaction = ( key, actionname ) ->
  control.keytapbindname key, actionname, allactions[actionname]
@bindaction = bindaction

readablebindings = ->
  ks=_.keys control.bindingnames
  vs=_.values control.bindingnames
  ks=ks.map (k) -> keyCodeToChar[Number(k)]
  return _.zip ks,vs


allactions['export keybindings'] = ->
  data=JSON.stringify readablebindings()
  window.open().document.write data
allactions['import keybindings'] = ->
  rawdata=prompt 'paste data here'
  newbinds=[]
  newholdbinds=[]
  if rawdata?
    data=JSON.parse rawdata
    for k,v of data
      k = keyCharToCode[v[0]]
      v = v[1]
      console.log k,v
      func=control.bindings[k]
      if func?
        newbinds.push k: k, name: v, f:func
      func=control.holdbindings[k]
      if func?
        newholdbinds.push k: k, name: v, f:func

    console.log newbinds
    console.log newholdbinds
    control.bindings={}
    control.holdbindings={}
    control.bindingnames={}
    newbinds.forEach (binding) ->
      control.bindings[binding.k]=binding.f
    newholdbinds.forEach (binding) ->
      control.holdbindings[binding.k]=binding.f

allactions['export level'] = ->
  ents=WORLD.getallents()
  spawners = ents.filter (ent) -> ent instanceof Spawner
  data=ents: spawners, blockdata: WORLD.bglayer
  window.open().document.write JSON.stringify data

allactions['import level'] = ->
  rawdata=prompt 'paste data here'
  if rawdata?
    data=JSON.parse rawdata
    WORLD.clear()
    loadlevel data
    WORLDINIT()
    ladybug.respawn()

allactions['load .json test level'] = ->
  levelfilename = "levels/2.json"
  $.ajax levelfilename, success: (data,status,xhr) ->
    jsondata=JSON.parse data
    WORLD.clear()
    loadlevel jsondata
    WORLDINIT()
    ladybug.respawn()

actioncategories={silly:{}}
actioncategories.silly["toggle moonjump"] = ->
  settings.moonjump = not settings.moonjump
actioncategories["level editing"]=
  "align all blocks to grid": ->
    gridsize = settings.gridsize
    for block in WORLD.bglayer
      block.x = mafs.roundn block.x, gridsize
      block.y = mafs.roundn block.y, gridsize
      block.w = mafs.roundn block.w, gridsize
      block.h = mafs.roundn block.h, gridsize
      block.removesprite()

mafs.roundn = ( num, base ) -> Math.round(num/base)*base

highlightoverlaps = ->
  blox=WORLD.bglayer
  #alloverlaps = blox.map (b) -> blox.filter (b2) -> b2.overlaps b
  alloverlaps = blox.map (b) -> b.alloverlaps()
  alloverlaps = alloverlaps.filter (i) -> i.length > 1
  flatlaps = _.flatten alloverlaps
  blox.forEach (b) -> b.HIGHLIGHT = undefined
  flatlaps.forEach (b) -> b.HIGHLIGHT = true

allactions['highlight overlapping blocks'] = highlightoverlaps

objnames = (objs) ->
  objs.map (obj) -> obj.constructor.name
allactions['generate entity list'] = ->
  entlist = $ "<div>"
  body.append entlist
  entlist.html objnames(WORLD.spritelayer).join()

if settings.devmode
  toolbar.append $ xmltag 'em', undefined, 'actions: '
  for k,v of allactions
    but=$ xmltag 'button', undefined, k
    but.click v
    toolbar.append but
  for ck,cv of actioncategories
    tb = $ xmltag 'details', class: 'toolbar'
    toolbar.append tb
    tb.append $ xmltag 'summary', undefined, "#{ck} actions: "
    for k,v of cv
      but=$ xmltag 'button', undefined, k
      but.click v
      tb.append but

ORIGCLICKPOS = false

# a "TOOL" in this context is analogous to tools in e.g. photoshop
# actions that can be bound to mouse buttons

# camera movement tool
# middle button by default

cameratool =
down: (e) ->
  ORIGCLICKPOS = V e.pageX, e.pageY
up: (e) ->
  ORIGCLICKPOS = false
  camera.offset = V()
move: (e) ->
  mpos = snapmouseadjust adjustmouseevent e
  if ORIGCLICKPOS
    currclickpos=V e.pageX, e.pageY
    offset=currclickpos.vsub ORIGCLICKPOS
    camera.offset = offset.nmul 2

#e.preventDefault()
$(renderer.view).mousedown (e) ->
  if e.button is 1 then cameratool.down e
$(renderer.view).mouseup (e) ->
  if e.button is 1 then cameratool.up e
$(renderer.view).mousemove (e) ->
  cameratool.move e



$(body).mousemove (e) ->
  p = smame e
  SCREENCURS = V e.pageX, e.pageY
  CURSOR = p


edithistory =
  data: []
  add: (entry) ->
    @data.push entry
    console.log @data
  undo: ->
    if @data.length is 0 then return
    lastevent = @data.pop()
    [type,ent]=lastevent
    if type is "remove"
      console.log ent
      WORLD.addblock ent

control.keyBindCharNamed 'Backspace',
  'undo', -> edithistory.undo()

bglayer_remove_block = (ent) ->
  edithistory.add [ "remove", ent ]
  WORLD.bglayer = _.without WORLD.bglayer, ent
  #stage.removeChild ent._pixisprite
  removesprite ent

tool_clickdelete = (p) ->
  blox=blocksatpoint WORLD.bglayer, p
  if blox.length > 0
    ent=blox[0]
    bglayer_remove_block ent

mouserightdownhandler = (e) ->
  if e.button != 2 then return
  e.preventDefault()
  adjusted = adjustmouseevent e
  #tool_clickdelete adjusted

$(renderer.view).mousedown mouserightdownhandler

$(renderer.view).contextmenu -> return false #NOOP


getCursorBlocks = () ->
  blocksatpoint WORLD.bglayer, CURSOR

#move this to control obj later
_wheelin = (offs) ->
  size = if isholdingkey('z') then 20 else 1
  TILESELECT += offs * size
  for bl in getCursorBlocks()
    bl.tile=TILESELECT
    bl.removesprite()

wheel =
  up: (e) -> _wheelin(-1)
  down: (e) -> _wheelin(1)

$(renderer.view).bind 'wheel', (e) ->
  return if not settings.devmode
  e.preventDefault()
  delta=e.originalEvent.deltaY
  up=delta<0
  if up then wheel.up e
  if not up then wheel.down e

_lastmodified = (date) ->
  body.append xmlwrap "footer",
    "last modified " + xmltag "time", title: date, datetime: date, jQuery.timeago(new Date(date))

_versionfoot = (data,status,xhr) ->
  body.append xmlwrap "footer",
    "version #{data}"

$.ajax THISFILE, type: "HEAD", success: (data,status,xhr) ->
  _lastmodified xhr.getResponseHeader "Last-Modified"
$.ajax "./version.json", success: _versionfoot

root = exports ? this

spawnselection = $ xmltag 'select'
for classname of spawnables
  spawnselection.append $ xmltag 'option', value: classname, classname
if settings.devmode
  toolbar.append $ xmltag 'em', undefined, "entity class:"
  toolbar.append spawnselection
spawnselection.change (e) ->
  SPAWNTOOL.classname = $(@).val()

jame.WORLD = WORLD

jame.control = control
jame.stats = stats
jame.settings = settings

root.jame = jame
root.stage = stage


Block::allstrictoverlaps = ->
  blox=WORLD.bglayer
  return blox.filter (otherblock) => @strictoverlaps otherblock
Block::alloverlaps = ->
  blox=WORLD.bglayer
  return blox.filter (otherblock) => @overlaps otherblock
Block::equals = (b) ->
  return @x=b.x and @y=b.y and @w=b.w and @h=b.h

jame.cleanobj = (obj) ->
  arr= ( [key,val] for own key,val of obj)
  return _.object arr
