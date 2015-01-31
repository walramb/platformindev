# video gem
#dependencies:
#jQuery
#Underscore.js
#pixi.js

THISFILE = "src/platformindev.coffee"

settings=
  fps: 30
  drawsprites : true
  slowmo : false
  altcostume : true
  beanmode : false
  muted : true
  paused : false
  volume : 0.2
  decemberween : false
  hat : false

settings.scale=1
#screensize = new V2d 64*16*settings.scale, 64*9*settings.scale
screensize = new V2d 960, 540 # halved 1080p
#screensize = new V2d 320, 240 # GCW Zero


sourcebaseurl = "./sprites/"
audiobaseurl="./audio/"

mafs.randfloat = -> -1+Math.random()*2
mafs.randvec = -> V mafs.randfloat(), mafs.randfloat()
mafs.randint = (max) -> Math.floor Math.random()*max
mafs.randelem = (arr) -> arr[mafs.randint(arr.length)]
mafs.degstorads = (degs) -> degs*Math.PI/180


class Line2d
  constructor: (@p1,@p2) ->

Line2d::lineintersect = ( lineb ) ->
  linea = @
  p = linea.p1
  r = linea.p2.vsub p
  q = lineb.p1
  s = lineb.p2.vsub q
  t = q.vsub(p).cross2d(s) / r.cross2d s
  u = q.vsub(p).cross2d(r) / r.cross2d s
  if t <= 1 and t >= 0 and u <= 1 and u >= 0
    return p.vadd r.nmul t
  return null

#based on an implementation by metamal on stackoverflow
HitboxRayIntersect = ( rect, line ) ->
  minx = line.p1.x
  maxx = line.p2.x
  if line.p1.x > line.p2.x
    minx=line.p2.x
    maxx=line.p1.x
  maxx = Math.min maxx, rect.bottomright.x
  minx = Math.max minx, rect.topleft.x
  if minx > maxx
    return false
  miny = line.p1.y
  maxy = line.p2.y
  dx = line.p2.x-line.p1.x
  #tiny wiggle room to account for floating point errors
  if Math.abs(dx) > 0.0000001
    a=(line.p2.y-line.p1.y)/dx
    b=line.p1.y-a*line.p1.x
  miny=a*minx+b
  maxy=a*maxx+b
  if miny > maxy
    tmp=maxy
    maxy = miny
    miny = tmp
  maxy=Math.min maxy, rect.bottomright.y
  miny=Math.max miny, rect.topleft.y
  if miny>maxy
    return false
  return true

pointlisttoedges = ( parr ) ->
  edges=[]
  prev = parr[parr.length-1]
  for curr,i in parr
    edges.push new Line2d prev,curr
    prev=curr
  return edges

body = $ "body"

V = (x=0,y=0) -> new V2d x,y
PP = (x,y) -> new PIXI.Point x,y
VTOPP = (v) -> PP v.x, v.y

playsound = ( src ) ->
  if settings.muted then return
  snd = new Audio audiobaseurl+src
  snd.volume = settings.volume
  snd.play()

parentstage = new PIXI.Stage 0x66FF99

stage = new PIXI.DisplayObjectContainer
parentstage.addChild stage

resetstage = ->
  parentstage.removeChild stage
  stage = new PIXI.DisplayObjectContainer
  parentstage.addChild stage


HUDLAYER = new PIXI.DisplayObjectContainer
parentstage.addChild HUDLAYER

hitboxlayer = new PIXI.DisplayObjectContainer
stage.addChild hitboxlayer
renderer = PIXI.autoDetectRenderer screensize.x, screensize.y

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

bogglescreen = new PIXI.Graphics()
bogglescreen.beginFill 0xFF00FF
bogglescreen.drawRect 0, 0, screensize.x, screensize.y
bogglescreen.alpha = 0.5
tex = PIXI.Texture.fromImage sourcebaseurl+'smooch.png'
bogsprite = new PIXI.Sprite tex
bogsprite.anchor = PP 1/2, 1/2
bogsprite.position = VTOPP screensize.ndiv 2
bogsprite.scale = PP 2, 2
text = new PIXI.Text """
  wow a secret
  warning, the following sprite is EXTREMELY CANON and EXTREMELY SEXY,
  childrens avert your eyes
  """,
  { font: "16px Arial", fill:"white"}
text.position = VTOPP screensize.ndiv(2).vadd(V(0,-128))
text.anchor = PP 1/2, 0
bogglescreen.addChild text
bogglescreen.addChild bogsprite


tex = PIXI.Texture.fromImage sourcebaseurl+'titleplaceholder.png'
titlescreen = new PIXI.Sprite tex

body.append renderer.view


B_MASKING = false

class Subscreen
  constructor: ->
    #@size= #V 300, 200
    @size = screensize.ndiv 4
    @screenpos = V 640*Math.random(), 640*Math.random()
    @subscreen= new PIXI.RenderTexture @size.x, @size.y
    @subsprite= new PIXI.Sprite @subscreen
    parentstage.addChild @subsprite
    if B_MASKING
      @mask = new PIXI.Graphics()
      parentstage.addChild @mask
Subscreen::subscreenadjust = ->
  maxpos=screensize.vsub @size
  hero=getotherhero()
  p1=ladybug.pos
  p2=hero.pos
  tmpdirection = p2.vsub(p1).norm()
  tmpv = tmpdirection.nadd 1
  tmpv = tmpv.ndiv 2
  newpos = maxpos.vmul tmpv
  @screenpos = newpos
  @subsprite.position = VTOPP @screenpos
  subscreencentercam = hero.pos.nmul -scale
  subscreencentercam = subscreencentercam.vadd @size.ndiv 2
  #hacky but remove the screen from the stage before rendering
  #so it doesnt render on top of itself as a black screen
  parentstage.removeChild @subsprite
  #tmpinnerstage.position = VTOPP subscreencentercam
  #tmpinnerstage.addChild stage
  oldpos=stage.position
  stage.position = VTOPP subscreencentercam
  @subscreen.render parentstage
  stage.position=oldpos
  parentstage.addChild @subsprite
  #parentstage.addChild @mask
  if B_MASKING
    @maskupdate()
    @subsprite.mask = @mask
Subscreen::maskupdate = ->
  @mask.clear()
  @mask.beginFill( 0x000000, 0.9 )
  @mask.moveTo @screenpos.x, @screenpos.y+32
  @mask.lineTo @screenpos.x+@size.x, @screenpos.y
  @mask.lineTo @screenpos.x+@size.x, @screenpos.y+@size.y-32
  @mask.lineTo @screenpos.x, @screenpos.y+@size.y
  @mask.endFill()

SCREENS = list: []
SCREENS.add = ->
   SCREENS.list.push new Subscreen()
SCREENS.adjust = ->
  @list.forEach (screen) ->
    screen.subscreenadjust()


# adding subscreens   duh
SCREENS.add()

scale = 1

tmpstage = new PIXI.DisplayObjectContainer()
tmpinnerstage = new PIXI.DisplayObjectContainer()
tmpstage.addChild tmpinnerstage


animate = ->
  cam=cameraoffset().nmul -scale
  stage.position = VTOPP cam
  stage.scale = PP scale, scale
  renderer.render parentstage
  SCREENS.adjust()

chievs={}

achieve = (title) ->
  if chievs[title].gotten? then return
  chievs[title].gotten = true
  makechievbox chievs[title].pic, mafs.randelem chievs[title].text

bogimg = xmltag 'img', src: sourcebaseurl+'boggle.png'

chievs.fall = pic: "lovelyfall.png", text: [
  "Fractured spine", "Faceplant", "Dats gotta hoit", "OW FUCK",
  "pomf =3", "Broken legs", "Have a nice trip", "Ow my organs", "Shattered pelvis", "Bugsplat" ]
chievs.kick = pic: "jelly.png", text: [
  "3 points field goal", "Into the dunklesphere",
  "Blasting off again", "pow zoom straight to the moon" ]
chievs.boggle = pic: "boggle.png", text: [
  "Buggy the boggle champ", "Bushboggler 2013", "Boggle that bush",
  "Collosal waste of time", "Boggle 2: Electric boggleoo", "Buggy bushboggle",
  "excuse me wtf are you doing", "Bush it, bush it real good", "Fondly regard flora",
  "&lt;chievo title unavailable due to trademark infringement&gt;", "Returning a bug to its natural habitat",
  "Bush it to the limit", "Live Free or Boggle Hard", "Identifying bushes, accurate results with simple tools",
  "Bugtester", "A proper lady (bug)", "Stupid achievement title", "The daily boggle", bogimg+bogimg+bogimg ]
chievs.murder = pic: "lovelyshorter.png", text: [ "This isn't brave, it's murder", "Jellycide" ]
chievs.target = pic: "target.png", text: [
  "there's no achievement for this", "\"Pow, motherfucker, pow\" -socrates",
  "Expect more. Pay less.", "You're supposed to use arrows you dingus" ]
chievs.start = pic: "crown.png", text: [
  "wow u started playin the game, congrats", "walking to the right",
  "chievo modern gaming edition", "baby's first achievement" ]


makechievbox = ( src, text ) ->
  style="style='display: inline-block; margin-left: 16px'"
  body.append chievbox = $(
    "<div class=chievbox><span #{style}><b>ACHIEVEMENT UNLOCKED</b><br/>#{text}</span></div>")
  chievbox.prepend pic=$ xmltag 'img', src: sourcebaseurl+src
  chievbox.animate( top: '32px' ).delay 4000
  chievbox.animate( { top: '-100px'}, { queue: true } ).delay 2000


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

#LOAD PROPERTIES FROM AN OBJECT
#for example to initialize from .json level data
GenericSprite::load = (obj) ->
  if obj.pos?
    _.extend @pos, obj.pos

class Hat extends GenericSprite
  constructor: () ->
    super()
    @src = "hat.png"
    @anchor = V 1/2, 1
    @parent = ladybug
Hat::tick = ->
  @vel = @parent.vel
  @pos = relativetobox @parent.gethitbox() , V(1/2, 0)
  @pos = @pos.vadd @vel

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

class Target extends GenericSprite
  constructor: ( @pos ) ->
    super @pos, 'target.png'
    @lifetime=-1
    @anchor = V 1/2, 1/2
  collide: ( otherent ) ->
    if otherent instanceof BoggleParticle
      @vel = @vel.vadd otherent.vel.nmul 1/8
    if otherent.attacktimeout? and otherent.attacktimeout > 0
      @gethitby otherent
  gethitby: ( otherent ) ->
    if not @broken
      @broken=true
      @src = 'shatteredtarget.png'
      @vel = otherent.vel.nmul 1/2
      @lifetime = 10

class Jelly extends GenericSprite
  constructor: ( @pos ) ->
    super @pos, 'jelly.png'
  collide: ( otherent ) ->
    if otherent instanceof Jelly
      @vel.x = (@vel.x+otherent.vel.x)/2
      @pos.x+=mafs.randfloat()*2
    if otherent instanceof BoggleParticle
      @vel = @vel.vadd otherent.vel.nmul 1/8
    #player bounce
    if otherent instanceof BugLady and otherent.vel.y > 0
      otherent.vel.y *= -2
    timeout=otherent.attacktimeout
    if timeout? and timeout > 0
      @gethitby otherent
  gethitby: ( otherent ) ->
    @vel.y += otherent.vel.y
    dir=if otherent.facingleft then -1 else 1
    @vel.x += dir*4
  render: ->
    flip = tickno%10<5
    anchor = V 1/2, 1
    pos=relativetobox(@gethitbox(),anchor)
    drawsprite @, @src, pos, flip, anchor


Jelly::size = V(32,16)
Jelly::anchor = V(1/2,1)

entitycount = ( classtype ) ->
  ents = WORLD.spritelayer.filter (sprite) -> sprite instanceof classtype
  return ents.length

GenericSprite::gravitate = () ->
  if not @touchingground()
    @vel.y++
Jelly::tick = () ->
  @physmove()
  if @touchingground()
    @jiggle()
    @pos.y--

Jelly::jiggle = () ->
  @vel.x*=9/10
  if Math.random()*100<50
    @vel.y = -Math.random()*4
    @vel.x += mafs.randfloat()*1

class Fence extends GenericSprite
  constructor: () ->
    super()
    @anchor=V 1/2,1
Fence::render = -> #noop

class Pickup extends Jelly
  constructor: ( @pos ) ->
    @vel=V()
    @src="energy1.png"
Pickup::jiggle = () -> #noop
Pickup::collide = ( otherent ) ->
  if otherent instanceof BugLady
    @pickedup otherent
Pickup::pickedup = ( otherent ) ->
  playsound 'boip.wav'
  @KILLME=true

class Energy extends Pickup
  constructor: ( @pos ) ->
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
  constructor: ( @pos ) ->
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
  if otherent.attacktimeout? and otherent.attacktimeout > 0 and @lifetime <= 0
    @gethitby otherent
Thug::gethitby = ( otherent ) ->
  @vel.y += otherent.vel.y
  dir=if otherent.facingleft then -1 else 1
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
  @angry = visionarea.containspoint ladybug.pos

Robo::tick = () ->
  super()
  isdead = @health <= 0
  @state=if @scampering then "attacking" else "idle"
  if isdead
    @scampering=false
    return
  @visioncheck()
  @scamperspeed = 1
  @scamperspeed = 3 if @angry
  @scampersubroutine()

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
Robo::getsprite = ->
  idlecycle = [ 'roboroll1.png' ]
  scampercycle = [1..2].map (n) -> "roboroll#{n}.png"
  if @angry
    idlecycle = [1..2].map (n) -> "roborage#{n}.png"
    scampercycle = [2..4].map (n) -> "roborage#{n}.png"
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
  if otherent instanceof BoggleParticle
    #parentstage.addChild bogglescreen
    if not (@kisstimeout > 0)
      ladybug.heal()
      WORLD.spritelayer.push new Smoochie @pos
    @kisstimeout = 100
  if otherent instanceof Fence
    @vel.x = 0
    offs = if otherent.pos.x < @pos.x then 1 else -1
    @pos.x += offs

class Burd extends GenericSprite
  constructor: ( @pos=V() ) ->
    @vel = V 0,0
    @anchor = V 1/2, 1/2
    @src='burd.png'
Burd::tick = () ->
  @getsprite()
  #@avoidwalls()
  @pos=@pos.vadd @vel
  lpos = ladybug.pos or V()
  dir=lpos.vsub(@pos).norm()
  @vel=@vel.vadd dir
  if @vel.mag() > 10
    @vel = @vel.norm().nmul 10
Burd::render = ->
  anchor = @anchor or V(0,0)
  flip=false
  pos=relativetobox(@gethitbox(),anchor)
  drawsprite @, @src, pos, flip, anchor
  @_pixisprite.scale.x = 1/3
  @_pixisprite.scale.y = 1/3
Burd::getsprite = ->
  framelist = [ 'burd.png', 'burdflap.png' ]
  @src = mafs.randelem framelist
  #@src = selectframe framelist, 2
Burd::collide = ( otherent ) ->
  if otherent instanceof BoggleParticle
    @vel = @vel.vadd otherent.vel.nmul 1/8
  timeout=otherent.attacktimeout
  if timeout? and timeout > 0
    @gethitby otherent
Burd::gethitby = ( otherent ) ->
  @vel.y += otherent.vel.y
  dir=if otherent.facingleft then -1 else 1
  @vel.x += dir*4
  @lifetime = 10

class BoggleParticle extends GenericSprite
  constructor: ( @pos=V() ) ->
    @vel = mafs.randvec().norm()
    @src = 'huh.png'
    @life = 50
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd mafs.randvec().norm().ndiv 8

BoggleParticle::render = ->
    drawsprite @, 'huh.png', @pos, false

class Smoochie extends GenericSprite
  constructor: ( @pos ) ->
    @anchor=V 1/2, 1
    @vel = mafs.randvec().norm()
    @src = 'kissparticle1.png'
    @life = 50
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd mafs.randvec().norm().ndiv 8
    @vel = @vel.vadd V 0, -1/8
  render: () ->
    super()
    @src=@getsprite()
    @_pixisprite.rotation = mafs.degstorads Math.cos(@life/100)*10

Smoochie::getsprite = ->
  framewait = 16
  framelist = [1..3].map (n) -> "kissparticle#{n}.png"
  return selectframe framelist, framewait

class PchooParticle extends GenericSprite
  constructor: ( @pos=V() ) ->
    @vel = mafs.randvec().norm().ndiv 8
    @life = 20
    @src = 'bughealth.png'
    @anchor = V 1/2, 1/2
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd mafs.randvec().norm().ndiv 64
  render: ->
    drawsprite @, @src, @pos, false, @anchor
    @_pixisprite.alpha = 0.25

class Bullet extends GenericSprite
  constructor: ( @pos=V() ) ->
    @owner = undefined
    @vel = V(8,0)
    @life = 20
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

Bullet::collide = ( otherent ) ->
  if otherent.health? and otherent isnt @owner
    otherent.gethitby?( @owner )
    @KILLME=true

Target::tick = ->
  @vel = @vel.nmul 7/10
  @pos = @pos.vadd @vel
  if @lifetime is 0 then @KILLME=true
  if @lifetime > 0 then @lifetime--
  if @lifetime is 0 and entitycount(Target) is 1 then achieve "target"

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
    @attacktimeout = 0
    @stuntimeout = 0
    @health=3
    @energy=0
    @score=0
    @facingleft=false
    @anchor = V 1/2, 1

class BugLady extends Hero
  constructor: () ->
    super()
    @invincibletimeout=0
    @controls={}
BugLady::heal = -> @health=3
BugLady::respawn = ->
  @pos = V()
  @vel = V()
  @heal()
BugLady::flinch = () ->
  @vel = @vel.vmul V -1, 1
  @invincibletimeout = 20
Hero::gethitby = ( otherent ) ->
  @takedamage()
BugLady::takedamage = ->
  if @invincibletimeout > 0 then return
  if @stuntimeout <= 0 then @flinch()
  @health-=1
  if @health <= 0 then @kill()


entcenter = ( ent ) ->
  hb=ent.gethitbox()
  return V hb.x+hb.w/2, hb.y+hb.h/2

BugLady::dmgvelocity = 20
BugLady::falldamage = ->
  if @vel.y > @dmgvelocity
    @stuntimeout = 20
    @takedamage()

GenericSprite::blockcollisions = ->
  box=@gethitbox()
  candidates = hitboxfilter box, WORLD.bglayer
  candidates.forEach (candidate) =>
    if @.gethitbox().bottom() >= candidate.top()
      @falldamage?()
      @pos.y = candidate.y
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0

BugLady::blockcollisions = ->
  box=@fallbox()
  candidates = hitboxfilter box, WORLD.bglayer
  candidates.forEach (candidate) =>
    if @.gethitbox().bottom() <= candidate.top()
      @pos.y = candidate.y
      @vel.y = 0
    #following lines handle ceiling collisions
    jumpthroughable = candidate instanceof OnewayBlock
    if @vel.y < 0 and not jumpthroughable and box.top()>candidate.top()
      @vel.y = 0

closestpoint = (p, pointarr) ->
  closest = pointarr[0]
  for point in pointarr
    if closest.dist(p) > point.dist(p)
      closest = point
  return closest

BugLady::polygoncollisions = ->
  allpolygons = WORLD.spritelayer.filter (sprit) -> sprit instanceof Poly
  allpolygons.forEach (candidate) =>
    p = new V2d @pos.x, @pos.y
    trajectory = new Line2d @pos, @pos.vadd(@vel)
    #if trajectory.lineintersect
    edges = pointlisttoedges candidate.points
    hits=edges.map (edg) -> trajectory.lineintersect edg
    hits = _.compact hits #strip nulls
    if hits.length > 0 #and @vel.y >= 0
      closest = closestpoint p, hits
      @pos = closest.vsub(@vel.norm())
      @vel.y = 0 #-Math.abs(@vel.x)
      #@vel.x = 0
    if geometry.pointInsidePoly p, candidate.points
      @vel.y--
    #  @vel.y = 0
      

Hero::checkcontrols = -> #noop
BugLady::checkcontrols = ->
  @holdingboggle = isholdingbound 'boggle'
  @holdingjump = isholdingbound 'jump'
  @controls.crouch = isholdingbound 'down'


BugLady::cancelattack = ->
  @attacktimeout = 0
  @attacking=false

Hero::outofbounds = ->
  @pos.y > 6400

BugLady::kill = ->
  @respawn()


BugLady::timeoutcheck = ->
  if @invincibletimeout > 0
    @invincibletimeout--
  if @poweruptimeout > 0
    @poweruptimeout--
    @vel = V2d.zero()
  if @stuntimeout > 0
    @stuntimeout--
    achieve "fall"
    @vel = V2d.zero()

BugLady::attackchecks = ->
  @attacking=@attacktimeout > 0
  heading = if @facingleft then -1 else 1
  if @attacking then @attacktimeout--
  if @attacking and not @punching
    @vel.y *= 0.7
    @vel.x += heading*0.3
    WORLD.spritelayer.push new PchooParticle entcenter @
  if @attacking and @punching
    if entitycount(Bullet) < 3 and @energy > 0
      @energy--
      firebullet @

firebullet = (ent) ->
  heading = if ent.facingleft then -1 else 1
  bullet = new Bullet()
  bullet.owner = ent
  bullet.vel = V heading*16, 0
  CENTER=V 1/2, 1/2
  bullet.pos = relativetobox ent.gethitbox(), CENTER
  WORLD.spritelayer.push bullet
  return bullet

get_sprites_of_class = (classtype) ->
  ents = WORLD.spritelayer.filter (sprite) -> sprite instanceof classtype

BugLady::submerged = () ->
  waterblocks = get_sprites_of_class Water
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, waterblocks
  if blockcandidates.length > 0
    return true
  return false

BugLady::waterdrag = ->
  @vel.y = @vel.y * 0.8
  @vel.x = @vel.x * 0.95
BugLady::tick = ->
  if @submerged()
    @waterdrag()
  unpowered = settings.altcostume
  if unpowered then @cancelattack()
  @checkcontrols()
  if @outofbounds() then @kill()
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  boggling = not walking and @touchingground() and @holdingboggle
  if boggling and Math.random()<0.3 then @boggle()
  @timeoutcheck()
  @movetick()

BugLady::limitvelocity = ->
  vellimit = 8
  @vel.x = mafs.clamp @vel.x, -vellimit, vellimit
BugLady::gravitate = ->
  if not @touchingground() and not @touchingwall()
    @vel.y += 1
    if not @holdingjump and @vel.y < 0 then @vel.y /= 2

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
  @limitvelocity()
  @blockcollisions()
  @polygoncollisions()
  @avoidwalls()
  if @vel.y > 0 and @touchingground()
    @vel.y = 0
  @pos = @pos.vadd @vel
  @gravitate()
  if @touchingground()
    @friction()

BugLady::movetick = ->
  unpowered = settings.altcostume
  @physmove()
  @attackchecks()
  jumpvel = if unpowered then 12 else 16
  @jumpimpulse jumpvel
  if @vel.y>1 and @controls.crouch
    @state = 'headfirst'
    @vel.y += 0.1
  if @touchingground() and @state == 'headfirst'
    @state = ''
    @stuntimeout=20
  @jumping = false #so we don't repeat by accident yo
  @climbing = @touchingwall()

BugLady::jumpimpulse = (jumpvel) ->
  if @touchingground() then @spentdoublejump = false
  jumplegal = @touchingground() or @submerged()
  doublejumplegal = @vel.y >= 0
  if @spentdoublejump then doublejumplegal = false
  if @jumping and doublejumplegal and not jumplegal
    @spentdoublejump = true
  if @jumping and (jumplegal or doublejumplegal)
    @vel.y = -jumpvel
  if @spentdoublejump
    WORLD.spritelayer.push new PchooParticle entcenter @

GenericSprite::friction = () ->
  @vel.x = @vel.x*0.5

BugLady::boggle = () ->
  WORLD.spritelayer.push new BoggleParticle entcenter @
  hit=ladybug.gethitbox()
  boxes = WORLD.fglayer.map (obj) -> obj.gethitbox()
  cand=hitboxfilter hit, boxes
  if cand.length > 0
    achieve "boggle"

BugLady::getsprite = ->
  if @invincibletimeout > 10 and @touchingground() then return "bugflinch.png"
  if @invincibletimeout > 15 then return "bugdmg.png"
  if @invincibletimeout > 0 and not @touchingground() then return "bugdmg2.png"
  if settings.beanmode then return "bugbean.png"
  src="lovelyshorter.png"
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  if walking
    src = selectframe [ 'lovelyrun1.png', 'lovelyrun2.png' ], 3
  if not @touchingground()
    src = if @vel.y < 0 then 'lovelyjump.png' else 'lovelycrouch.png'
  if not walking and @controls.crouch
    src = 'lovelycrouch.png'
  if not walking and isholdingbound 'up'
    src = 'lovelyjump.png'
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
  if @climbing and settings.altcostume then src = 'marl/boggle.png'
  if @state == 'headfirst' then src = 'bugheadfirst.png'
  return src

class Claire extends BugLady
Claire::getsprite = ->
  return "orcbabb.png"

BugLady::render = ->
  vel = Math.abs( @vel.x )
  walking = vel > 1
  src=@getsprite()
  flip = @facingleft
  if settings.beanmode and walking then flip = tickno % 8 < 4
  pos = relativetobox @gethitbox(), @anchor
  sprit=drawsprite @, src, pos, flip, @anchor
  if src == 'boggle.png'
    sprit.rotation=mafs.degstorads mafs.randfloat()*4
  else
    sprit.rotation=0


removesprite = ( ent ) ->
  if not ent._pixisprite? then return
  stage.removeChild ent._pixisprite
  ent._pixisprite=undefined

stageremovesprite = ( stage, ent ) ->
  if not ent._pixisprite? then return
  stage.removeChild ent._pixisprite
  ent._pixisprite=undefined

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


class Poly extends Renderable
  constructor: (@points=[]) ->
    @pos = V()
Poly::initsprite = () ->
  sprit=new PIXI.Graphics()
  sprit.beginFill 0xcc0000
  sprit.lineStyle 1, 0x000000
  firstpoint = @points[0]
  @points.forEach (point) ->
    sprit.lineTo point.x, point.y
  sprit.lineTo firstpoint.x, firstpoint.y
  sprit.endFill()
  @_pixisprite=sprit
  stage.addChild sprit
Poly::render = ->
  if not @hassprite() then @initsprite()

Poly::boundingbox = ->
  xs=@points.map (pt) -> pt.x
  ys=@points.map (pt) -> pt.y
  min = (a,b) -> Math.min a,b
  max = (a,b) -> Math.max a,b
  l=Math.round xs.reduce min
  r=Math.round xs.reduce max
  t=Math.round ys.reduce min
  b=Math.round ys.reduce max
  return makebox V(l,t), V(r-l,b-t), V(0,0)

Poly::gethitbox = ->
  @boundingbox()
#  makebox V(0,0), V(32,32), V(0,0)

# ok this hsould really be mmoved to some geometry library thing

class Block extends Renderable
  constructor: (@x,@y,@w,@h) -> @pos = V @x, @y


Block::intersection = (rectb) ->
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

Block::tostone = () ->
  @src="groundstone.png"
  @removesprite()

Block::fixnegative = () ->
  if @w<0
    @x+=@w
    @w*=-1
  if @h<0
    @y+=@h
    @h*=-1
  @pos = V @x, @y
  @removesprite()


absurdboundbox = { x: -1000, y: -1000, w: 100000, h: 100000 }
bglayerQuads = new QuadTree 0, absurdboundbox

hitboxfilter_OLD = ( hitbox, rectarray ) ->
  rectarray.filter (box) ->
    hitbox.overlaps box

hitboxfilter = ( hitbox, rectarray ) ->
  #if rectarray is WORLD.bglayer
  #  cands=bglayerQuads.retrieve hitbox
  #  return cands.map (c) -> quadunwrap c
  return hitboxfilter_OLD hitbox, rectarray

makebox = (position, dimensions, anchor) ->
  truepos = position.vsub dimensions.vmul anchor
  return new Block truepos.x, truepos.y, dimensions.x, dimensions.y

bottomcenter = V 1/2, 1
BugLady::anchor = bottomcenter
BugLady::size = V 16, 32+16

GenericSprite::fallbox = ->
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

Block::containspoint = (p) ->
  @x <= p.x and @y <= p.y and @x+@w >= p.x and @y+@h >= p.y

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
      @vel.x = 0
    ###
    ofs=1
    if notontop and collidebox.left() <= block.left()
      @pos.x-=ofs
    if notontop and rightof(collidebox) >= rightof(block)
      @pos.x+=ofs
    ###

GenericSprite::touchingground = () ->
  touch=false
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
  for block in blockcandidates
    if collidebox.bottom() <= block.bottom()
      touch=true
  #generic poly handling woo wee
  allpolygons = WORLD.spritelayer.filter (sprit) -> sprit instanceof Poly
  box=@gethitbox()
  box.y+=1
  allpolygons.forEach (candidate) =>
    p = new V2d @pos.x, @pos.y+1
    if geometry.pointInsidePoly p, candidate.points
      touch = true
  return touch

class PowerSuit extends GenericSprite
  constructor: (@pos) ->
    super @pos, 'suit.png'
PowerSuit::anchor = V 1/2, 1
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

ControlObj::keyholdbind = ( key, func ) ->
  @holdbindings[normalizekey(key)]=func
ControlObj::keyholdbindname = ( key, name, func ) ->
  @bindingnames[normalizekey(key)]=name
  @holdbindings[normalizekey(key)]=func

ControlObj::keyHoldBindRawNamed = ( key, name, func ) ->
  @bindingnames[key]=name
  @holdbindings[key]=func

control.keytapbindname '9', 'zoom out', -> camera.zoomout()
control.keytapbindname '0', 'zoom in', -> camera.zoomin()



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
pausefunc = ->
  playsound "pause.wav"
  settings.paused = not settings.paused
  if settings.paused then parentstage.addChild pausescreen
  if not settings.paused then parentstage.removeChild pausescreen
control.keytapbindname 'p', 'pause', pausefunc
control.keyBindRawNamed keyCharToCode['Pause/Break'], 'pause', pausefunc


control.keytapbindname 't', 'underclock/slowmo', ->
  settings.slowmo = not settings.slowmo

control.keytapbindname 'g', 'toggle grid', ->
  settings.grid = not settings.grid


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
jump = ->
  if ladybug.touchingground()
    playsound "jump.wav"
  ladybug.jumping=true
down = ->

bugspeed = ->
  amt = if ladybug.touchingground() then 6 else 1

left = ->
  ladybug.facingleft = true
  ladybug.vel.x-=bugspeed()
right = ->
  achieve "start"
  ladybug.facingleft = false
  ladybug.vel.x+=bugspeed()

availableactions = [ up, down, left, right ]

control.keyholdbindname 'w', 'up', up
control.keyholdbindname 's', 'down', down
control.keyholdbindname 'a', 'left', left
control.keyholdbindname 'd', 'right', right
control.keyholdbindname 'x', 'boggle', -> #noop

ControlObj::keyHoldBindCharNamed = ( key, name, func ) ->
  @keyHoldBindRawNamed keyCharToCode[key], name, func

control.keyHoldBindCharNamed 'Up', 'up', up
control.keyHoldBindCharNamed 'Down', 'down', down
control.keyHoldBindCharNamed 'Left', 'left', left
control.keyHoldBindCharNamed 'Right', 'right', right

control.keyHoldBindCharNamed 'Space', 'jump', jump

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



nextlevel = ->
  WORLD.clear()
  #ROBOWORLD_INIT()
  COLLTEST_INIT()
  WORLDINIT()
  ladybug.respawn()

restartlevel = ->
  WORLD.clear()
  loadlevelfile "levels/1.json"
  #WORLD_ONE_INIT()
  WORLDINIT()
  ladybug.respawn()

control.keytapbindname 'r', 'restart level', restartlevel
control.keytapbindname 'n', 'change level', nextlevel

@CONTROL = control

eventelement = $ document
# renderer.view

keypushcache = []
cheatcodecheck = ->
  code=["Up","Up","Down","Down","Left","Right","Left","Right","B","A","Enter"]
  input=_.last keypushcache, code.length
  if _.isEqual input, code
    alert "conglaturation"
    keypushcache=[]
  code=["Right","Up","Right","A","Down","Down","Enter"]
  input=_.last keypushcache, code.length
  if _.isEqual input, code
    alert "you'r a radical kid!! you have prooved the justice of our culture. god bless a merica. bean mode unlock!"
    settings.beanmode = not settings.beanmode
    keypushcache=[]

eventelement.bind 'keydown', (e) ->
  key = e.which
  control.bindings[key]?()
  if not (key in control.heldkeys)
    control.heldkeys.push key
    keypushcache.push keyCodeToChar[key]
    cheatcodecheck()
  return false
eventelement.bind 'keyup', (e) ->
  key = e.which
  control.heldkeys = _.without control.heldkeys, key
  return false

tmpcanvasjq = $ "<canvas>"
tmpcanvas = tmpcanvasjq[0]

tickno = 0

Block::gethitbox = () -> @

Block::initsprite = () ->
  src = @src or "groundtile.png"
  tex = PIXI.Texture.fromImage sourcebaseurl+src
  sprit = new PIXI.TilingSprite tex, @w, @h
  @_pixisprite=sprit
  stage.addChild sprit

Block::render = ->
  if not @hassprite() then @initsprite()
  sprit = @_pixisprite
  sprit.tilePosition.x = -@x
  sprit.tilePosition.y = -@y
  sprit.position.x = @x
  sprit.position.y = @y

class Water extends Block
  constructor: (@x,@y,@w,@h) ->
    super @x, @y, @w, @h
    @src = "snow.png"
Water::render = ->
  super()
  @_pixisprite.alpha=0.5

class OnewayBlock extends Block
  constructor: (@x,@y,@w,@h) ->
    super @x, @y, @w, @h
    @src = "groundstone.png"

ladybug = new BugLady

class Cloud extends Renderable
  constructor: () ->
    super()
    @src='cloud.png'
    if settings.decemberween then @src='snow.png'

Cloud::spriteinit = () ->
  tex = PIXI.Texture.fromImage sourcebaseurl+@src
  sprit = new PIXI.TilingSprite tex, screensize.x, screensize.y
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
    tex = PIXI.Texture.fromImage sourcebaseurl+@src
    {x,y}=adjustedscreensize()
    sprit = new PIXI.TilingSprite tex, x,y
    @_pixisprite=sprit
    parentstage.addChildAt sprit, 0

Grid::PIXREMOVE = ->
  if not settings.grid and @_pixisprite
    parentstage.removeChild @_pixisprite
    @_pixisprite=undefined

Cloud::render = () ->
  pos = cameraoffset()
  flip = false
  @PIXINIT()
  sprit = @_pixisprite
  offset=V tickno*-0.2, Math.sin(tickno/200)*64
  #sprit.position = VTOPP pos
  sprit.tilePosition = VTOPP offset
  if settings.grid and @_pixisprite
    parentstage.removeChild @_pixisprite
    @_pixisprite=undefined

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

WORLD=new World

randpos = -> V(640*1.5,64*2).vadd mafs.randvec().vmul V 640, 100

class Shrub extends GenericSprite
  constructor: (@pos) ->
    super @pos, 'shrub.png'
    @anchor=V 1/2,1

placeshrub = (pos) ->
  WORLD.fglayer.push new Shrub pos

class PlaceholderSprite extends GenericSprite
  constructor: (@pos) ->
    super @pos
    @label='a thing'
PlaceholderSprite::render = ->
  if @_pixisprite?
    sprit=@_pixisprite
    sprit.position = VTOPP @pos
    sprit.anchor = VTOPP V 0, 0
    return
  txt = new PIXI.Text @label,
    { font: "12px Arial", fill:"black" }
  txt.anchor = PP @anchor
  console.log @anchor
  sprit = new PIXI.Graphics()
  sprit.beginFill 0xFF00FF
  box=@gethitbox()
  sprit.position = VTOPP @pos
  sprit.drawRect 0, 0, box.w, box.h
  sprit.alpha = 0.9
  sprit.addChild txt
  stage.addChild sprit
  @_pixisprite=sprit

class BugMeter extends GenericSprite
  constructor: () ->
    super()
    @src='bughealth.png'
    @value=3
    @abspos = V 0, 0
    @spritesize = V 32, 32

BugMeter::spriteinit = () ->
  tex = PIXI.Texture.fromImage sourcebaseurl+@src
  sprit = new PIXI.TilingSprite tex, @spritesize.x*@value, @spritesize.y
  @_pixisprite=sprit
  HUDLAYER.addChild sprit
  #stage.addChild sprit
  return sprit

BugMeter::render = () ->
  #pos = cameraoffset()
  #pos = pos.vadd @abspos
  pos = @abspos
  flip = false
  if not @_pixisprite then @spriteinit()
  sprit = @_pixisprite
  sprit.width = @spritesize.x*@value
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
  tick: () -> @update ladybug.score

Block::toJSON = ->
  [ @x, @y, @w, @h ]

loadblocks = (blockdata) ->
  blockdata.forEach (blockdatum) ->
    [x,y,w,h]=blockdatum
    WORLD.bglayer.push new Block x, y, w, h
loadspawners = (entdata) ->
  entdata.forEach (entdatum) ->
    WORLD.spritelayer.push spawner=new Spawner entdatum.pos
    spawner.entdata = entdatum

scatterents = ( classproto, num ) ->
  WORLD.spritelayer=WORLD.spritelayer.concat [0...num].map ->
    new classproto randpos()

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
    @label="platform"
Platform::collide = ( otherent ) ->
  if otherent instanceof Hero
    otherent.vel.y = 0


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


spawnables = burd: Burd, target: Target, jelly: Jelly, powersuit: PowerSuit, gold: Gold, energy:Energy, lila: Lila, claire: Claire, platform: Platform
class Spawner extends PlaceholderSprite
  constructor: (@pos) ->
    super @pos
    @label="Entity spawner"
    @entdata=class: Jelly, pos: @pos
Spawner::tick = ->
  @entdata.pos = @pos
  console.log @entdata.pos
  @label = @entdata.class
Spawner::spawn = ->
  #ent=jame.spawn @classname
  #ent.load @entdata
  loadents [@entdata]
Spawner::toJSON = ->
  @entdata


entdata = [ class: "lila", pos: {x: 64*4, y: 64*4 }
class: "claire", pos: {x: 64*2, y: 64*4}
]


jame={}
jame.spawn = (classname) ->
  if not spawnables[classname]
    return
  ent=new spawnables[classname]?()
  WORLD.spritelayer.push ent
  return ent

loadent = (entdatum) ->
  ent=jame.spawn entdatum.class
  ent.load entdatum

loadents = (entdata) ->
  entdata.forEach (entdatum) -> loadent entdatum


WORLD_ONE_INIT = ->
  scatterents HurtWire, 4
  scatterents Target, 10
  scatterents Jelly, 10
  scatterents Energy, 10
  scatterents Gold, 10
  scatterents Thug, 3
  WORLD.spritelayer.push new PowerSuit V(128,32)
  loadents entdata

  placeshrub V 64*8, 64*5-4
  placeshrub V 64*7-48, 64*5-4
  placeshrub V 64*9, 64*5-4
  WORLD.spritelayer.push new Goal V 64*24, 64*4
  WORLD.spritelayer.push royaljel = new Jelly randpos()
  WORLD.spritelayer.push hat= new Hat()
  hat.src = 'crown.png'
  hat.parent=royaljel

WORLDINIT = () ->
  WORLD.entities.push new Cloud()
  WORLD.entities.push new Grid()
  bugmeter= new BugMeter
  WORLD.entities.push bugmeter
  energymeter= new EnergyMeter
  WORLD.entities.push energymeter
  WORLD.entities.push new MoneyMeter
  @bugmeter = bugmeter
  if settings.hat
    WORLD.entities.push new Hat()
  WORLD.bglayer.forEach (block) ->
    fence=new Fence
    fence.pos = relativetobox block, V(0,0)
    WORLD.spritelayer.push fence
    fence=new Fence
    fence.pos = relativetobox block, V(1,0)
    WORLD.spritelayer.push fence
  WORLD.spritelayer.push ladybug

randtri = ->
  new Poly [ randpos(), randpos(), randpos() ]

WORLD.getallents = ->
  return [].concat WORLD.entities, WORLD.spritelayer, WORLD.bglayer, WORLD.fglayer

WORLD.clear = ->
  ALLENTS = WORLD.getallents()
  ALLENTS.forEach (ent) -> removesprite ent
  WORLD.entities=[]
  WORLD.spritelayer=[]
  WORLD.bglayer=[]
  WORLD.fglayer=[]
  #resetstage()

roboblockdata=[]
roboblockdata.push [ -64, 64*4, 64*12, 100 ]
roboblockdata.push [ 64*12, 64*5, 64*12, 100 ]

ROBOWORLD_INIT = ->
  scatterents Burd, 8
  loadblocks roboblockdata
  WORLD.spritelayer=WORLD.spritelayer.concat [0..3].map ->
    new Robo randpos()
  WORLD.spritelayer.push randtri()

COLLTEST_INIT = ->
  scatterents Jelly, 8
  loadblocks roboblockdata
  WORLD.spritelayer.push randtri()

###
levelfilename = "levels/1.json"
$.ajax levelfilename, success: (data,status,xhr) ->
  jsondata=JSON.parse data
  loadlevel jsondata
  WORLD_ONE_INIT()
###

loadlevelfile = (levelfilename) ->
  $.ajax levelfilename, success: (data,status,xhr) ->
    jsondata=JSON.parse data
    loadlevel jsondata
    WORLD_ONE_INIT()
loadlevelfile "levels/1.json"


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
  tmppos = camera.trackingent.pos.nadd 0
  tmppos.y -= 64
  tmppos = tmppos.vsub camera.offset.ndiv scale
  tmppos = tmppos.vsub screensize.ndiv 2*scale
  #return tmppos
  return camera.pos.vadd(tmppos).ndiv 2

camera.tick = ->
  camera.pos = cameraoffset()

render = ->
  camera.tick()
  renderables = [].concat WORLD.bglayer, WORLD.spritelayer, [ladybug], WORLD.fglayer, WORLD.entities
  renderables.forEach (ent) -> ent.render?()
  highlighted = renderables.filter (ent) -> ent.HIGHLIGHT?
  if settings.grid then highlighted = renderables
  drawhitboxes highlighted

drawhitboxes = ( ents ) ->
  stage.removeChild hitboxlayer
  hitboxlayer = new PIXI.DisplayObjectContainer
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
  WORLD.spritelayer = _.difference WORLD.spritelayer, doomedsprites

quadwrap = (origobj) ->
  obj = origobj.gethitbox()
  { x: obj.x, y: obj.y, w: obj.w, h: obj.h, LINK: origobj }

quadunwrap = (obj) ->
  return obj.LINK

rejigCols = ->
  bglayerQuads.clear()
  WORLD.bglayer.forEach (block) ->
    bglayerQuads.insert quadwrap block

WORLD.tick = () ->
  rejigCols()
  for key in control.heldkeys
    control.holdbindings[key]?()
  checkcolls ladybug, WORLD.spritelayer
  WORLD.spritelayer.forEach (sprite) ->
    checkcolls sprite, _.without WORLD.spritelayer, sprite
  WORLD.euthanasia()
  ACTIVEENTS = [].concat WORLD.spritelayer, [ladybug], WORLD.entities
  ACTIVEENTS.forEach (ent) -> ent.updatehitbox?()
  ACTIVEENTS.forEach (ent) -> ent.tick?()
  render()
  tickno++

fpscounter=$ xmltag()
tt=0

updateinfobox = ->
  text= control.heldkeys.map (key) -> "<span>#{keyCodeToChar[key]}</span>"
  $(infobox).html text.join " "

mainloop = ->
  updatesettingstable()
  updateinfobox()
  if not settings.paused
    ticktime = timecall WORLD.tick
    tt=ticktime
    fps=Math.round 1000/Math.max(tickwaitms,ticktime)
    idealfps=Math.round 1000/tickwaitms
    fpscounter.html "~#{fps}/#{idealfps} fps ; per tick: #{tt}ms"
  fpsgoal = if settings.slowmo then 4 else settings.fps
  tickwaitms = 1000/fpsgoal
  setTimeout mainloop, Math.max tickwaitms-ticktime, 1
  requestAnimFrame animate

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
#for k,v of control.bindings
#  bindingsDOM.append maketablerow [keyCodeToChar[k],control.bindingnames[k] or "??"]

for k,v of control.bindingnames
  bindingsDOM.append maketablerow [keyCodeToChar[k],v or "??"]

#tmp, fix this shit
_CHARbindingnames = {}
for k,v of control.bindingnames
  _CHARbindingnames[keyCodeToChar[k]]=v

settingsDOM = $ "<table>"
updatesettingstable = () ->
  settingsDOM.html ""
  for k,v of settings
    settingsDOM.append maketablerow [k,v]

INIT = ->
  body.append fpscounter
  body.append "<b>bindings:</b>"
  #DEPENDS ON  keyboarddisplay.js
  body.append keyboardlayout.visualize _CHARbindingnames
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

class Tool
  constructor: ->

NOOPTOOL = name: 'noop', mousedown: (->), mouseup: (->), mousemove: (->)

BLOCKCREATIONTOOL = _.extend {}, NOOPTOOL,
  name: 'create block'
  creatingblock: false
  mousedown: (e) ->
    #ADD BLOCK, LEFT MBUTTON
    #HOLD Z TO SNAP TO GRID
    if e.button != 0 then return
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    BLOCKCREATIONTOOL.creatingblock=new Block adjusted.x, adjusted.y, 32, 32
    WORLD.bglayer.push BLOCKCREATIONTOOL.creatingblock
  mouseup: (e) ->
    if e.button != 0 then return
    BLOCKCREATIONTOOL.creatingblock.fixnegative()
    BLOCKCREATIONTOOL.creatingblock = false
  mousemove: (e) ->
    mpos = snapmouseadjust adjustmouseevent e
    creatingblock = BLOCKCREATIONTOOL.creatingblock
    if creatingblock
      creatingblock.w = mpos.x-creatingblock.x
      creatingblock.h = mpos.y-creatingblock.y
      creatingblock.removesprite()
      creatingblock.tostone()
    if ORIGCLICKPOS
      currclickpos=V e.pageX, e.pageY
      offset=currclickpos.vsub ORIGCLICKPOS
      camera.offset = offset

snapmouseadjust_always = (mpos) ->
  gridsize = 32
  mpos = mpos.ndiv(gridsize).op(Math.round).nmul(gridsize)
  return mpos
snapmouseadjust_down = (mpos) ->
  gridsize = 32
  mpos = mpos.ndiv(gridsize).op(Math.floor).nmul(gridsize)
  return mpos

snapmouseadjust = (mpos) ->
  snaptogrid = isholdingkey 'z'
  if snaptogrid
    return snapmouseadjust_always mpos
  return mpos

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
    setcursor '-moz-grabbing'
  else
    setcursor 'auto'
  if entsundercursor.length > 0
    setcursor '-moz-grab'
  p = snapmouseadjust p
  @selected.forEach (ent) ->
    ent.pos = p
    ent.vel = V()
class MoveBlockTool extends Tool
  name: 'move blocks'
  constructor: ->
    @selected = []
  mouseup: (e) ->
    @selected = []
    setcursor 'auto'
  mousemove: (e) ->
    @selected = @selected or [] #jesus christ how horrifying
    isSelecting = @selected.length > 0
    p = adjustmouseevent e
    p = snapmouseadjust p
    @selected.forEach (ent) ->
      ent.pos = p
      ent.x = p.x
      ent.y = p.y
      ent.removesprite()
MoveBlockTool::mousedown = (e) ->
  p = adjustmouseevent e
  blocksundercursor = blocksatpoint WORLD.bglayer, p
  @selected=blocksundercursor

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

$(renderer.view).mousedown (e) -> tool.mousedown? e
$(renderer.view).mouseup (e) -> tool.mouseup? e
$(renderer.view).mousemove (e) -> tool.mousemove? e

randposrel = (p=V()) -> p.vadd mafs.randvec().vmul V 32,32
TRIANGLETOOL=_.extend {}, NOOPTOOL,
  name: "add triangle"
  mousedown: (e) ->
    p = adjustmouseevent e
    triangle=new Poly [ randposrel(p), randposrel(p), randposrel(p) ]
    WORLD.spritelayer.push triangle
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
    WORLD.spritelayer.push ent=new Spawner p
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
    WORLD.bglayer.push blok

UNIONTOOL=_.extend {}, NOOPTOOL,
  name: "unfuck block overlaps"
  mousedown: (e) ->
    p = adjustmouseevent e
    blocks = blocksatpoint WORLD.bglayer, p
    if blocks.length == 2
      a=blocks[0]
      b=blocks[1]
      blockcarve a,b
      WORLD.bglayer = _.without WORLD.bglayer, a
      WORLD.bglayer = _.without WORLD.bglayer, b
      stage.removeChild a._pixisprite
      stage.removeChild b._pixisprite

carveoutblock = (b) ->
  #copy because reasons
  block = new Block b.x, b.y, b.w, b.h
  tocarve=block.allstrictoverlaps()
  for bloke in tocarve
    blockcarve bloke,block
  todelete=block.allstrictoverlaps()
  for bloke in todelete
    WORLD.bglayer = _.without WORLD.bglayer, bloke
    if bloke._pixisprite?
      stage.removeChild bloke._pixisprite


CARVER=_.extend {}, NOOPTOOL,
  name: "block carver"
  mousedown: (e) ->
    #ADD BLOCK, LEFT MBUTTON
    #HOLD Z TO SNAP TO GRID
    if e.button != 0 then return
    adjusted = adjustmouseevent e
    adjusted=snapmouseadjust adjusted
    CARVER.creatingblock=new Block adjusted.x, adjusted.y, 32, 32
    WORLD.bglayer.push CARVER.creatingblock
  mouseup: (e) ->
    if e.button != 0 then return
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
    if ORIGCLICKPOS
      currclickpos=V e.pageX, e.pageY
      offset=currclickpos.vsub ORIGCLICKPOS
      camera.offset = offset

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
  held: {}
  mousedown: (e) ->
    @held[e.button]=true
    if e.button is 0 then @leftclick adjustmouseevent e
  mouseup: (e) ->
    @held[e.button]=false
  mousemove: (e) ->
    if @held[0] then @lefthold adjustmouseevent e
  leftclick: (pos) ->
  lefthold: (pos) ->

BLOCKPAINT=_.extend {}, BASETOOL,
  name: "paint blocks"
  action: (p) ->
    snapped=snapmouseadjust_down p
    blocksundercursor = blocksatpoint WORLD.bglayer, p
    if blocksundercursor.length == 0
      newblock=new Block snapped.x, snapped.y, 32, 32
      WORLD.bglayer.push newblock
  leftclick: (p) -> @action p
  lefthold: (p) -> @action p

alltools = [ BLOCKCREATIONTOOL, MOVEBLOCKTOOL, MOVETOOL, TRIANGLETOOL, SPAWNERTOOL, TELEPORTTOOL, UNIONTOOL, CARVER, WATERTOOL, BLOCKPAINT ]

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




toolbar = $ xmltag 'div', class: 'toolbar'
toolbar.append $ xmltag 'em', undefined, 'tools:'
toolbar.insertAfter $(renderer.view)

alltools.forEach (t) ->
  but=$ xmltag 'button', undefined, t.name
  but.click -> tool = t
  toolbar.append but

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

allactions['spawn block under hero'] = ->
  p = ladybug.pos.vadd V -32, 0
  creatingblock=new Block p.x, p.y, 64, 64
  WORLD.bglayer.push creatingblock

getotherhero = ->
  heroes = jame.WORLD.spritelayer.filter (ent) -> ent instanceof Hero
  i = heroes.indexOf ladybug
  i = (i+1)%heroes.length
  return heroes[i]

allactions['swap character'] = ->
  ladybug = getotherhero()
  camera.trackingent = ladybug

bindaction("u","swap character")

unzip = (data) ->
  _.zip.apply _, data

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

loadlevel = (data) ->
  loadblocks data.blockdata
  loadents data.ents
  
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

allactions['become queen of the slimes'] = ->
  WORLD.spritelayer.push hat= new Hat()
  hat.src = 'crown.png'
  hat.parent=royaljel

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


toolbar.append $ xmltag 'em', undefined, 'actions: '
for k,v of allactions
  but=$ xmltag 'button', undefined, k
  but.click v
  toolbar.append but


ORIGCLICKPOS = false

mousemiddledownhandler = (e) ->
  if e.button != 1 then return
  e.preventDefault()
  ORIGCLICKPOS = V e.pageX, e.pageY
mousemiddleuphandler = (e) ->
  if e.button != 1 then return
  e.preventDefault()
  ORIGCLICKPOS = false
  camera.offset = V()


$(renderer.view).mousedown mousemiddledownhandler
$(renderer.view).mouseup mousemiddleuphandler

bglayer_remove_block = (ent) ->
  WORLD.bglayer = _.without WORLD.bglayer, ent
  #stage.removeChild ent._pixisprite
  removesprite ent

mouserightdownhandler = (e) ->
  if e.button != 2 then return
  e.preventDefault()
  adjusted = adjustmouseevent e
  blox=blocksatpoint WORLD.bglayer, adjusted
  if blox.length > 0
    ent=blox[0]
    bglayer_remove_block ent

$(renderer.view).mousedown mouserightdownhandler

$(renderer.view).contextmenu -> return false #NOOP

$(renderer.view).bind 'wheel', (e) ->
  e.preventDefault()
  delta=e.originalEvent.deltaY
  up=delta>0
  if up then camera.zoomout()
  if not up then camera.zoomin()

lastmodified = (date) ->
  body.prepend "<p>last modified #{jQuery.timeago(new Date(date))}, #{date}</p>"

$.ajax THISFILE, type: "HEAD", success: (data,satus,xhr) ->
  lastmodified xhr.getResponseHeader "Last-Modified"

root = exports ? this


spawnselection = $ xmltag 'select'
for classname of spawnables
  spawnselection.append $ xmltag 'option', value: classname, classname
toolbar.append $ xmltag 'em', undefined, "entity class:"
toolbar.append spawnselection
spawnselection.change (e) ->
  SPAWNTOOL.classname = $(@).val()
  
jame.WORLD = WORLD

jame.control = control


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


