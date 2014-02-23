# video gem

#dependencies:
#jQuery
#Underscore.js
#pixi.js

THISFILE = "src/platformindev.coffee"


settings={}
settings.drawsprites = true
settings.slowmo = false
settings.altcostume = true
settings.beanmode = false
settings.muted = true
settings.paused = false
settings.volume = 0.2
settings.decemberween = false
settings.hat = false

settings.scale=2/3
screensize = new V2d 64*16*settings.scale, 64*9*settings.scale

sourcebaseurl = "./sprites/"
audiobaseurl="./audio/"

#random float between -1 and 1
#mafs = mafs or {}

mafs.randfloat = () -> -1+Math.random()*2
mafs.randvec = () -> V mafs.randfloat(), mafs.randfloat()
mafs.randint = (max) -> Math.floor Math.random()*max
mafs.randelem = (arr) -> arr[mafs.randint(arr.length)]

mafs.degstorads = (degs) -> degs*Math.PI/180

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

scale = 1
animate = ->
  cam=cameraoffset().nmul -scale
  stage.position = VTOPP cam
  stage.scale = PP scale, scale
  renderer.render parentstage

chievs={}

achieve = (title) ->
  if chievs[title].gotten? then return
  chievs[title].gotten = true
  console.log chievs
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
    flip=false
    pos=relativetobox(@gethitbox(),anchor)
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

GenericSprite::gethitbox = ->
  size=@size or V 32, 32
  anchor = @anchor or V 1/2, 1/2
  makebox @pos, size, anchor

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
    @vel.x += mafs.randfloat()*1

class Fence extends GenericSprite
  constructor: () ->
    super()
    @anchor=V 1/2,1
Fence::render = -> #noop

class Energy extends Jelly
  constructor: ( @pos ) ->
    @vel=V()
    @src="energy1.png"

class Gold extends Energy
  constructor: ( @pos ) ->
    @vel=V()
    @src="crown.png"
Gold::getsprite = ->
Gold::collide = ( otherent ) ->
  if otherent instanceof BugLady
    playsound 'boip.wav'
    @KILLME=true
    otherent.score += 1

Energy::getsprite = ->
  framelist = [1..6].map (n) -> "energy#{n}.png"
  @src = selectframe framelist, 4
Energy::tick = () ->
  super()
  @getsprite()
Energy::jiggle = () -> #noop

Energy::collide = ( otherent ) ->
  if otherent instanceof BugLady
    playsound 'boip.wav'
    @KILLME=true
    otherent.energy += 1

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
  render: ->
    flip = not @facingleft
    box = @gethitbox()
    anchor = V 1/2, 1
    pos = relativetobox box, anchor
    sprit=drawsprite @, @src, pos, flip, anchor
    #sprit.anchor = VTOPP anchor
bottomcenter = V 1/2, 1
Thug::size = V 24, 64+16
Thug::anchor = bottomcenter
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
Lila::tick = () ->
  if @kisstimeout > 0
    @kisstimeout--
  super()
  if @kisstimeout > 50
    return
  scamperspeed = 2
  if not @scampering and Math.random()<1/10
    @scampering=true
  if @scampering and Math.random()<1/10
    @scampering=false
  if @scampering and Math.abs(@vel.x)<3
    @vel.x += if @facingleft then -scamperspeed else scamperspeed
    #@pos.x += vel
  if not @scampering and Math.random()<1/20
    @facingleft = not @facingleft
Robo::tick = () ->
  super()
  isdead = @health <= 0
  @state=if @scampering then "attacking" else "idle"
  if isdead
    @scampering=false
    return
  CENTER = V 1/2, 1/2
  dim = 64*4
  visionarea = makebox @.pos, V(dim,dim), CENTER
  @angry = visionarea.containspoint ladybug.pos
  scamperspeed = 1
  scamperspeed = 3 if @angry
  if not @scampering and Math.random()<1/10
    @scampering=true
  if @scampering and Math.random()<1/10
    @scampering=false
  if @scampering and Math.abs(@vel.x)<3
    @vel.x += if @facingleft then -scamperspeed else scamperspeed
    #@pos.x += vel
  if not @scampering and Math.random()<1/20
    @facingleft = not @facingleft

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
  @pos.y++ #AUGH
  if @health <= 0 and @lifetime == 0 and @touchingground()
    framelist=["roboded.png"]
  @pos.y--
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

GenericSprite::blockcollisions = ->
  box=@gethitbox()
  spriteheight=box.h
  candidates = hitboxfilter box, WORLD.bglayer
  candidates.forEach (candidate) =>
    if bottomof(@.gethitbox()) >= topof( candidate )
      @pos.y = candidate.y
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0

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
#mafs.randfloat()*10
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
    #mafs.randvec().norm().ndiv 8
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
   # rot = if flip then 90 else -90
   # @_pixisprite.rotation = mafs.degstorads rot
    
    

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
  key in control.heldkeys

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
BugLady::heal = ->
  @health=3
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

BugLady::blockcollisions = ->
  spriteheight=64
  box=@fallbox()
  candidates = hitboxfilter box, WORLD.bglayer
  candidates.forEach (candidate) =>
    if bottomof(@.gethitbox()) <= topof( candidate )
      if @vel.y > 20
        @stuntimeout = 20
        @takedamage()
      @pos.y = candidate.y
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0

Hero::checkcontrols = -> #noop
BugLady::checkcontrols = ->
  @holdingboggle = isholdingkey 'x'
  @holdingjump = isholdingkey 'w'

BugLady::cancelattack = ->
  @attacktimeout = 0
  @attacking=false

Hero::outofbounds = ->
  @pos.y > 640

$deathmsg=$("<p id=deathmsg></p>").html(
  "<b>YOU'RE DEAD</b> now don't let me catch you doing that again young lady")

BugLady::kill = ->
  if @ded then $('#deathmsg').html "<b>WHAT DID I JUST TELL YOU</b>"
  if not @ded
    body.prepend $deathmsg
    @ded=true
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
  if @attacking and @punching and @touchingground()
    @vel.x = @vel.x*0.1
  if @attacking and @punching
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
  

BugLady::tick = ->
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

BugLady::movetick = ->
  unpowered = settings.altcostume
  vel = Math.abs( @vel.x )
  walking = vel > 0.2
  #LIMIT VELOCITY
  vellimit = if @touchingground() then 4 else 5
  @vel.x = mafs.clamp @vel.x, -vellimit, vellimit
  #BLOCK COLLISIONS
  @blockcollisions()
  @avoidwalls()
  @attackchecks()
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
    src = selectframe [ 'lovelyrun1.png', 'lovelyrun2.png' ], 6
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
  if @climbing and settings.altcostume then src = 'marl/boggle.png'
  return src

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

class PlayerBurd extends Hero
  constructor: () ->
    super()
    @src='burd.png'
    @anchor = V 1/2, 1

PlayerBurd::takedamage = BugLady::takedamage
PlayerBurd::getsprite = -> 'burd.png'
PlayerBurd::render = ->
  src=@src
  anchor = @anchor or V(0,0)
  flip=false
  pos=@pos
  sprit=drawsprite @, src, pos, flip, anchor
  return

PlayerBurd::tick = ->
  @checkcontrols()
  if @outofbounds() then @kill()
  vel = Math.abs( @vel.x )
  #BLOCK COLLISIONS
  @blockcollisions()
  @avoidwalls()
  heading = if @facingleft then -1 else 1
  @pos = @pos.vadd @vel
  if not @touchingground()
    @gravitate()

removesprite = ( ent ) ->
  if not ent._pixisprite then return
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
Poly::gethitbox = ->
  makebox V(0,0), V(32,32), V(0,0)


class Block extends Renderable
  constructor: (@x,@y,@w,@h) -> @pos = V @x, @y

Block::tostone = () ->
  @src="groundstone.png"
  @removesprite()

Block::intersection = (rectb) ->
  recta=@
  l=Math.max recta.left(), rectb.left()
  t=Math.max recta.top(), rectb.top()
  r=Math.min recta.right(), rectb.right()
  b=Math.min recta.bottom(), rectb.bottom()
  w=r-l
  h=b-t
  return new Block l,t,w,h

Block::overlaps = ( rectb ) ->
  recta=@
  if recta.left() > rectb.right() or
  recta.top() > rectb.bottom() or
  recta.right() < rectb.left() or
  recta.bottom() < rectb.top()
    return false
  else
    return true
Block::fixnegative = () ->
  if @w<0
    @x+=@w
    @w*=-1
  if @h<0
    @y+=@h
    @h*=-1
  @pos = V @x, @y
  @removesprite()

hitboxfilter = ( hitbox, rectarray ) ->
  rectarray.filter (box) ->
    hitbox.overlaps box

makebox = (position, dimensions, anchor) ->
  truepos = position.vsub dimensions.vmul anchor
  return new Block truepos.x, truepos.y, dimensions.x, dimensions.y

bottomcenter = V 1/2, 1
BugLady::anchor = bottomcenter
BugLady::size = V 16, 32+16

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

Block::containspoint = (p) ->
  @x <= p.x and @y <= p.y and @x+@w >= p.x and @y+@h >= p.y

blocksatpoint = (blocks, p) ->
  blocks.filter (box) -> box.containspoint p

GenericSprite::touchingwall = () ->
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
  for block in blockcandidates
    notontop = bottomof(collidebox)>topof(block)
    if notontop and collidebox.left() < block.left()
      return true
    if notontop and collidebox.right() > block.right()
      return true
  return false

GenericSprite::avoidwalls = () ->
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
  for block in blockcandidates
    notontop = bottomof(collidebox)>topof(block)
    ofs=1
    if notontop and leftof(collidebox) < leftof(block)
      @vel.x=0
      @pos.x-=ofs
    if notontop and rightof(collidebox) > rightof(block)
      @vel.x=0
      @pos.x+=ofs

GenericSprite::touchingground = () ->
  touch=false
  collidebox = @gethitbox()
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
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
@control = control

normalizekey = (key) -> key.toUpperCase().charCodeAt 0

ControlObj::keytapbindraw = ( key, func ) ->
  @bindings[key]=func
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

control.keytapbindname '9', 'zoom out', -> scale-=0.1
control.keytapbindname '0', 'zoom in', -> scale+=0.1

control.keytapbindname 'v', 'spawn burd', -> jame.spawn 'burd'
control.keytapbindname 'c', 'become burd', -> jame.burdme()


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
  achieve "start"
  ladybug.facingleft = false
  amt = if ladybug.touchingground() then 3 else 1
  ladybug.vel.x+=amt

availableactions = [ up, down, left, right ]

control.keyholdbind 'w', up
control.keyholdbind 's', down
control.keyholdbind 'a', left
control.keyholdbind 'd', right

control.keyBindRawNamed keyCharToCode['Up'], 'jump', up

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
  ROBOWORLD_INIT()
  WORLDINIT()
  ladybug.respawn()
restartlevel = ->
  WORLD.clear()
  WORLD_ONE_INIT()
  WORLDINIT()
  ladybug.respawn()

control.keytapbindname 'r', 'restart level', restartlevel
control.keytapbindname 'n', 'change level', nextlevel

@CONTROL = control

$(document).bind 'keydown', (e) ->
  key = e.which
  control.bindings[key]?()
  if not (key in control.heldkeys)
    control.heldkeys.push key
$(document).bind 'keyup', (e) ->
  key = e.which
  control.heldkeys = _.without control.heldkeys, key

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

class Grid extends Renderable
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
  if @_pixisprite? then return
  txt = new PIXI.Text @label,
    { font: "12px Arial", fill:"black" }
  txt.anchor = PP @anchor
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
  stage.addChild sprit
  return sprit

BugMeter::render = () ->
  pos = cameraoffset()
  pos = pos.vadd @abspos
  flip = false
  if not @_pixisprite then @spriteinit()
  sprit = @_pixisprite
  sprit.width = @spritesize.x*@value
  sprit.position = VTOPP pos
BugMeter::tick = () ->
  @update ladybug.health
BugMeter::update = (value) ->
  @removesprite()
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


blockdata=[]
blockdata.push [ -64, 64*5-4, 64*12, 100 ]
blockdata.push [ 64*4, 64*2, 32, 32 ]
blockdata.push [ 64*5, 64*4, 32, 32 ]
blockdata.push [ 64*6, 64*3, 32, 32 ]
blockdata.push [ 0, 64*4, 32, 32 ]
blockdata.push [ 32, 64*4, 64*2, 64*2 ]
blockdata.push [ 64*12, 64*4, 64*12, 200 ]
blockdata.push [ 128+8, 64+20, 64, 32 ]
blockdata.push [ 128+8+64, 64+20+32, 32, 32 ]

Block::toJSON = ->
  [ @x, @y, @w, @h ]

loadblocks = (blockdata) ->
  blockdata.forEach (blockdatum) ->
    [x,y,w,h]=blockdatum
    WORLD.bglayer.push new Block x, y, w, h

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


class HurtWire extends GenericSprite
HurtWire::size = V 8, 32
HurtWire::anchor = V 1/2, 0
HurtWire::getsprite = ->
  framewait = 1
  framelist = [1..4].map (n) -> "wirespark#{n}.png"
  return selectframe framelist, framewait
HurtWire::collide = ( otherent ) ->
  if otherent instanceof Hero
    otherent.takedamage()
HurtWire::render = ->
  @src=@getsprite()
  super()


spawnables = burd: Burd, target: Target, jelly: Jelly, powersuit: PowerSuit, gold: Gold, energy:Energy, lila: Lila
class Spawner extends PlaceholderSprite
  constructor: (@pos) ->
    super @pos
    @label="Entity spawner"
    @entdata=class: Jelly, pos: @pos
Spawner::tick = ->
  @label = @entdata.class
Spawner::spawn = ->
  #ent=jame.spawn @classname
  #ent.load @entdata
  loadents [@entdata]


entdata = [ class: "lila", pos: {x: 64*4, y: 64*4 } ]


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
  loadblocks(blockdata)
  loadents(entdata)

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

WORLD_ONE_INIT()
WORLDINIT()

camera={}
jame.camera=camera
camera.offset=V()
camera.pos=V()
camera.trackingent = ladybug

cameraoffset = ->
  tmppos = camera.trackingent.pos.nadd 0
  tmppos.y -= 64
  tmppos = tmppos.vsub camera.offset.ndiv scale
  tmppos = tmppos.vsub screensize.ndiv 2*scale
  return tmppos

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
    graf.drawCircle ent.pos.x, ent.pos.y, 4
    box = ent.gethitbox?()
    if not box then return
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
  doomedsprites = WORLD.spritelayer.filter (sprite) -> sprite.KILLME?
  doomedsprites.forEach (sprite) -> sprite.cleanup?()
  WORLD.spritelayer = _.difference WORLD.spritelayer, doomedsprites

WORLD.tick = () ->
  for key in control.heldkeys
    control.holdbindings[key]?()
  checkcolls ladybug, WORLD.spritelayer
  WORLD.spritelayer.forEach (sprite) ->
    checkcolls sprite, _.without WORLD.spritelayer, sprite
  WORLD.euthanasia()
  ACTIVEENTS = [].concat WORLD.spritelayer, [ladybug], WORLD.entities
  ACTIVEENTS.forEach (ent) -> ent.tick?()
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
  fpsgoal = if settings.slowmo then 4 else 60
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


bindingsDOM = $ "<table>"
for k,v of control.bindings
  bindingsDOM.append maketablerow [keyCodeToChar[k],control.bindingnames[k] or "??"]

settingsDOM = $ "<table>"
updatesettingstable = () ->
  settingsDOM.html ""
  for k,v of settings
    settingsDOM.append maketablerow [k,v]

INIT = ->
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

class Tool
  constructor: ->

BLOCKCREATIONTOOL = {}
BLOCKCREATIONTOOL.name = 'create block'
BLOCKCREATIONTOOL.creatingblock = false
BLOCKCREATIONTOOL.mousedown = (e) ->
  #ADD BLOCK, LEFT MBUTTON
  #HOLD Z TO SNAP TO GRID
  if e.button != 0 then return
  adjusted = adjustmouseevent e
  adjusted=snapmouseadjust adjusted
  BLOCKCREATIONTOOL.creatingblock=new Block adjusted.x, adjusted.y, 32, 32
  WORLD.bglayer.push BLOCKCREATIONTOOL.creatingblock
BLOCKCREATIONTOOL.mouseup = (e) ->
  if e.button != 0 then return
  BLOCKCREATIONTOOL.creatingblock.fixnegative()
  BLOCKCREATIONTOOL.creatingblock = false


snapmouseadjust = (mpos) ->
  snaptogrid = isholdingkey 'z'
  if snaptogrid
    gridsize = 32
    mpos = mpos.ndiv(gridsize).op(Math.floor).nmul(gridsize)
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


getentsunderpoint = (p) ->
  WORLD.spritelayer.filter (ent) ->
    box = ent.gethitbox?()
    return box and box.containspoint p

MoveTool::mousedown = (e) ->
  p = adjustmouseevent e
  entsundercursor = getentsunderpoint p
  console.log entsundercursor
  @selected=entsundercursor

setcursor = (cursorname) ->
  $(renderer.view).css 'cursor', cursorname

MOVETOOL=new MoveTool()
MOVETOOL.selected = []

tool = MOVETOOL

$(renderer.view).mousedown (e) -> tool.mousedown? e
$(renderer.view).mouseup (e) -> tool.mouseup? e
$(renderer.view).mousemove (e) -> tool.mousemove? e

TRIANGLETOOL= name: "add triangle"
TRIANGLETOOL.mousedown = (e) ->
  p = adjustmouseevent e
  WORLD.spritelayer.push randtri()

TRIANGLETOOL.mouseup = (e) ->
TRIANGLETOOL.mousemove = (e) ->

SPAWNTOOL= name: 'Spawn entity'
SPAWNTOOL.classname = 'burd'
SPAWNTOOL.mousedown = (e) ->
  p = adjustmouseevent e
  ent=jame.spawn SPAWNTOOL.classname
  ent.pos = p

SPAWNTOOL.mouseup = (e) ->
SPAWNTOOL.mousemove = (e) ->

NOOPTOOL = name: 'noop', mousedown: (->), mouseup: (->), mousemove: (->)

SPAWNERTOOL=_.extend {}, NOOPTOOL
SPAWNERTOOL.name= 'Spawn entity'
SPAWNERTOOL.classname = 'burd'
SPAWNERTOOL.mousedown = (e) ->
  p = adjustmouseevent e
  WORLD.spritelayer.push ent=new Spawner
  ent.pos = p
  ent.entdata.class = SPAWNTOOL.classname
  ent.spawn()


alltools = [ BLOCKCREATIONTOOL , MOVETOOL, TRIANGLETOOL, SPAWNERTOOL ]
toolbar = $ xmltag()
toolbar.append $ xmltag 'em', undefined, 'tools:'
toolbar.insertAfter $(renderer.view)

alltools.forEach (t) ->
  but=$ xmltag 'button', undefined, t.name
  but.click -> tool = t
  toolbar.append but

allactions={}

allactions['export level'] = ->
  console.log WORLD.bglayer
  data=JSON.stringify WORLD.bglayer
  window.open().document.write data
  console.log data
allactions['import level'] = ->
  rawdata=prompt 'paste data here'
  data=JSON.parse rawdata
  WORLD.clear()
  loadblocks data
  WORLDINIT()
  ladybug.respawn()
allactions['load .json test level'] = ->
  levelfilename = "levels/2.json"
  $.ajax levelfilename, success: (data,status,xhr) ->
    jsondata=JSON.parse data
    WORLD.clear()
    loadblocks jsondata
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


toolbar.append $ xmltag 'em', undefined, 'actions: '
for k,v of allactions
  but=$ xmltag 'button', undefined, k
  but.click v
  toolbar.append but


ORIGCLICKPOS = false
mousemiddledownhandler = (e) ->
  if e.button != 1 then return
  e.preventDefault()
  console.log "MIDDLE"
  ORIGCLICKPOS = V e.pageX, e.pageY
mousemiddleuphandler = (e) ->
  if e.button != 1 then return
  e.preventDefault()
  ORIGCLICKPOS = false
  camera.offset = V()
mousemovehandler = (e) ->
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
    console.log offset

$(renderer.view).mousemove mousemovehandler
$(renderer.view).mousedown mousemiddledownhandler
$(renderer.view).mouseup mousemiddleuphandler

mouserightdownhandler = (e) ->
  if e.button != 2 then return
  e.preventDefault()
  adjusted = adjustmouseevent e
  blox=blocksatpoint WORLD.bglayer, adjusted
  console.log blox
  if blox.length > 0
    ent=blox[0]
    WORLD.bglayer = _.without WORLD.bglayer, ent
    #stage.removeChild ent._pixisprite
    removesprite ent

$(renderer.view).mousedown mouserightdownhandler

$(renderer.view).contextmenu -> return false #NOOP

$(renderer.view).bind 'wheel', (e) ->
  e.preventDefault()
  delta=e.originalEvent.deltaY
  up=delta>0
  console.log delta
  if up then scale-=0.1
  if not up then scale+=0.1

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
  
jame.burdme = ->
  ladybug = new PlayerBurd()
  WORLD.entities.push ladybug
  console.log ladybug

jame.WORLD = WORLD

root.jame = jame
root.stage = stage



Block::alloverlaps = ->
  blox=WORLD.bglayer
  return blox.filter (otherblock) => @overlaps otherblock
Block::equals = (b) ->
  return @x=b.x and @y=b.y and @w=b.w and @h=b.h

jame.cleanobj = (obj) ->
  arr= ( [key,val] for own key,val of obj)
  return _.object arr


