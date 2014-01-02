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
randfloat = () -> -1+Math.random()*2
randvec = () -> V randfloat(), randfloat()
randint = (max) -> Math.floor Math.random()*max
randelem = (arr) -> arr[randint(arr.length)]

degstorads = (degs) -> degs*Math.PI/180

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
  makechievbox chievs[title].pic, randelem chievs[title].text

bogimg = xmltag 'img', src: sourcebaseurl+'boggle.png'

chievs.fall = pic: "lovelyfall.png"
chievs.kick = pic: "jelly.png"
chievs.boggle = pic: "boggle.png"
chievs.murder = pic: "lovelyshorter.png"
chievs.target = pic: "target.png"
chievs.start = pic: "crown.png"

chievs.start.text = [
  "wow u started playin the game, congrats", "walking to the right",
  "chievo modern gaming edition", "baby's first achievement" ]
chievs.murder.text = [ "This isn't brave, it's murder", "Jellycide" ]
chievs.kick.text = [
  "3 points field goal", "Into the dunklesphere",
  "Blasting off again", "pow zoom straight to the moon" ]
chievs.fall.text = [
  "Fractured spine", "Faceplant", "Dats gotta hoit", "OW FUCK",
  "pomf =3", "Broken legs", "Have a nice trip", "Ow my organs", "Shattered pelvis", "Bugsplat" ]
chievs.boggle.text = [
  "Buggy the boggle champ", "Bushboggler 2013", "Boggle that bush",
  "Collosal waste of time", "Boggle 2: Electric boggleoo", "Buggy bushboggle",
  "excuse me wtf are you doing", "Bush it, bush it real good", "Fondly regard flora",
  "&lt;chievo title unavailable due to trademark infringement&gt;", "Returning a bug to its natural habitat",
  "Bush it to the limit", "Live Free or Boggle Hard", "Identifying bushes, accurate results with simple tools",
  "Bugtester", "A proper lady (bug)", "Stupid achievement title", "The daily boggle", bogimg+bogimg+bogimg ]
chievs.target.text = [
  "there's no achievement for this", "\"Pow, motherfucker, pow\" -socrates",
  "Expect more. Pay less.", "You're supposed to use arrows you dingus" ]


makechievbox = ( src, text ) ->
  style="style='display: inline-block; margin-left: 16px'"
  body.append chievbox = $(
    "<div class=chievbox><span #{style}><b>ACHIEVEMENT UNLOCKED</b><br/>#{text}</span></div>")
  chievbox.prepend pic=$ xmltag 'img', src: sourcebaseurl+src
  chievbox.animate( top: '32px' ).delay 4000
  chievbox.animate( { top: '-100px'}, { queue: true } ).delay 2000


class Renderable
  constructor: () ->
Renderable::hassprite = -> typeof @._pixisprite isnt "undefined"
Renderable::removesprite = ->
  removesprite @
class GenericSprite extends Renderable
  constructor: ( @pos=V(), @src ) ->
    @vel=V()
  render: ->
    anchor = @anchor or V(0,0)
    flip=false
    pos=relativetobox(@gethitbox(),anchor)
    drawsprite @, @src, pos, flip, anchor
    #drawsprite @, @src, @pos, false
GenericSprite::cleanup = ->
  removesprite @

class Sprite
  constructor: () ->
    @vel=V()
    @pos=V()
  tick: () ->

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
      otherent.vel.y *= -2
    timeout=otherent.attacktimeout
    if timeout? and timeout > 0 and topof(otherent.gethitbox()) < topof(@.gethitbox())
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
  ents = WORLD.spritelayer.filter (sprite) -> sprite instanceof classtype
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

class Fence extends GenericSprite
  constructor: () ->
    @pos=V()
    @vel=V()
    @src="hat.png"
    @anchor=V 1/2,1

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
  constructor: ( @pos ) ->
    @lifetime=-1
    @vel = V()
    @src='bugthug.png'
    @facingleft = true
  render: ->
    flip = not @facingleft
    box = @gethitbox()
    anchor = V 1/2, 1
    pos = relativetobox box, anchor
    sprit=drawsprite @, @src, pos, flip, anchor
    #sprit.anchor = VTOPP anchor
bottomcenter = V 1/2, 1
Thug::gethitbox = ->
  return makebox @pos, V(24,64), bottomcenter
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
#and @touchingground() then @src = 'bugthug.png'
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

class Lila extends Thug
class Robo extends Thug
Lila::tick = Robo::tick = () ->
  super()
  scamperspeed = 3
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
  scampercycle = [1..4].map (n) -> "lilascamper#{n}.png"
  framewait = 4
  framelist=idlecycle
  if not @scampering then framewait = 20
  if @scampering then framelist=scampercycle
  @src = selectframe framelist, framewait
Robo::getsprite = ->
  idlecycle = [ 'roboroll1.png' ]
  scampercycle = [1..2].map (n) -> "roboroll#{n}.png"
  framelist=idlecycle
  if @scampering then framelist=scampercycle
  if @lifetime > 0
    @lifetime--
    framelist=["robohurt.png"]
  framewait = 4
  @src = selectframe framelist, framewait

Lila::collide = ( otherent ) ->
  if otherent instanceof BoggleParticle
    parentstage.addChild bogglescreen
  if otherent instanceof Fence
    console.log "LEDGE"
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
  #console.log @
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
  @src = randelem framelist
  #@src = selectframe framelist, 2

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
    @vel = randvec().norm().ndiv 8
    @life = 20
    @src = 'bughealth.png'
    @anchor = V 1/2, 1/2
  tick: () ->
    @life--
    if @life<=0 then @KILLME=true
    @pos = @pos.vadd @vel
    @vel = @vel.vadd randvec().norm().ndiv 64
  render: ->
    drawsprite @, @src, @pos, false, @anchor
    @_pixisprite.alpha = 0.25

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

class BugLady extends Hero
  constructor: () ->
    super()
    @jumping = false
    @attacking = false
    @attacktimeout = 0
    @stuntimeout = 0
    @health=3
    @energy=0
    @score=0

BugLady::respawn = ->
  @pos = V()
  @vel = V()
  @health=3

BugLady::takedamage = ->
  @health-=1
  if @health <= 0 then @kill()


entcenter = ( ent ) ->
  hb=ent.gethitbox()
  return V hb.x+hb.w/2, hb.y+hb.h/2

BugLady::blockcollisions = ->
  spriteheight=64
  box=@fallbox()
  candidates = hitboxfilter box, bglayer
  candidates.forEach (candidate) =>
    if bottomof(@.gethitbox()) <= topof( candidate )
      if @vel.y > 20
        @stuntimeout = 20
        @takedamage()
      @pos.y = candidate.y
      @vel.y = 0
  if candidates.length > 0 and @vel.y < 0
    @vel.y = 0

Hero::checkcontrols = ->
  #noop
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
  if @attacking
    @vel.y *= 0.7
    @attacktimeout-=1
    @vel.x += heading*0.3
    WORLD.spritelayer.push new PchooParticle entcenter @
  if @attacking and @punching and @touchingground()
    @vel.x = @vel.x*0.1

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
  boxes = fglayer.map (obj) -> obj.gethitbox()
  cand=hitboxfilter hit, boxes
  if cand.length > 0
    achieve "boggle"

BugLady::getsprite = ->
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
  offs = V 0, 4
  anchor = V 1/2, 1
  pos = relativetobox @gethitbox(), anchor
  pos = offs.vadd pos
  sprit=drawsprite @, src, pos, flip, anchor
  if src == 'boggle.png'
    sprit.rotation=degstorads randfloat()*4
  else
    sprit.rotation=0

class PlayerBurd extends Hero
  constructor: () ->
    super()
    @jumping = false
    @attacking = false
    @attacktimeout = 0
    @stuntimeout = 0
    @health=3
    @energy=0
    @score=0
    @src='burd.png'
    @facingleft=false
    @anchor = V 1/2, 1
PlayerBurd::takedamage = BugLady::takedamage
PlayerBurd::getsprite = ->
  return 'burd.png'
PlayerBurd::render = ->
  console.log @src
  src=@src
  anchor = @anchor or V(0,0)
  flip=false
  #pos=relativetobox(@gethitbox(),anchor)
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
  makebox V(0,0), V(0,0), V(0,0)


class Block extends Renderable
  constructor: (@x,@y,@w,@h) -> @pos = V @x, @y

Block::tostone = () ->
  @src="groundstone.png"
  @removesprite()


Block::overlaps = ( rectb ) ->
  recta=@
  if recta.x > rectb.x+rectb.w or
  recta.y > rectb.y+rectb.h or
  recta.x+recta.w < rectb.x or
  recta.y+recta.h < rectb.y
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
@control = control

normalizekey = (key) -> key.toUpperCase().charCodeAt 0

ControlObj::keytapbindraw = ( key, func ) ->
  @bindings[key]=func
ControlObj::keytapbind = ( key, func ) ->
  @bindings[normalizekey(key)]=func

ControlObj::keytapbindname = ( key, name, func ) ->
  @bindingnames[normalizekey(key)]=name
  console.log @bindingnames
  @keytapbind key, func

ControlObj::keyBindRawNamed = ( key, name, func ) ->
  @bindingnames[key]=name
  console.log @bindingnames
  @keytapbindraw key, func

ControlObj::keyholdbind = ( key, func ) ->
  @holdbindings[normalizekey(key)]=func

control.keytapbindname '9', 'zoom out', -> scale-=0.1
control.keytapbindname '0', 'zoom in', -> scale+=0.1

control.keytapbindname 'v', 'spawn burd', -> jame.spawn 'burd'
control.keytapbindname 'z', 'become burd', -> jame.burdme()


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

arrowleft = 37
arrowup = 38
arrowright = 39
arrowdown = 40
control.keyBindRawNamed arrowup, 'jump', up

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
  clearworld()
  ROBOWORLD_INIT()
  WORLDINIT()

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
ladybug.facingleft = false
ladybug.jumping=false
ladybug.pos = V 64, 128+64

bglayer = []

fglayer = []
#spritelayer=[]

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
WORLD.spritelayer=[]

randpos = -> V(640*1.5,64*2).vadd randvec().vmul V 640, 100

placeshrub = (pos) ->
  pos = pos.vsub V 0, 32
  fglayer.push new GenericSprite pos, 'shrub.png'

class BugMeter extends GenericSprite
  constructor: () ->
    super()
    @src='bughealth.png'
    @value=3

BugMeter::spriteinit = () ->
  tex = PIXI.Texture.fromImage sourcebaseurl+@src
  @spritesize = V 32, 32
  sprit = new PIXI.TilingSprite tex, @spritesize.x*@value, @spritesize.y
  @_pixisprite=sprit
  stage.addChild sprit
  return sprit

BugMeter::render = () ->
  pos = cameraoffset()
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
EnergyMeter::render = () ->
  pos = cameraoffset()
  pos = pos.vadd V 0, 16
  flip = false
  if not @_pixisprite then @spriteinit()
  sprit = @_pixisprite
  sprit.width = @spritesize.x*@value
  sprit.position = VTOPP pos
EnergyMeter::tick = () ->
  @update ladybug.energy


blockdata=[]
blockdata.push [ -64, 64*5-4, 64*12, 100 ]
blockdata.push [ 64*4, 64*2, 32, 32 ]
blockdata.push [ 64*5, 64*4, 32, 32 ]
blockdata.push [ 64*6, 64*3, 32, 32 ]
blockdata.push [ 0, 64*4, 32, 32 ]
blockdata.push [ 32, 64*4, 64*2, 64*2 ]
blockdata.push [ 64*12, 64*4, 64*12, 200 ]

loadblocks = (blockdata) ->
  blockdata.forEach (blockdatum) ->
    [x,y,w,h]=blockdatum
    bglayer.push new Block x, y, w, h


scatterents = ( classproto, num ) ->
  WORLD.spritelayer=WORLD.spritelayer.concat [0...num].map ->
    new classproto randpos()

WORLD_ONE_INIT = ->
  scatterents Target, 10
  scatterents Jelly, 10
  scatterents Energy, 10
  scatterents Gold, 10
  scatterents Thug, 3
  scatterents Lila, 1
  WORLD.spritelayer.push new PowerSuit V(128,32)
  blockdata.push [ 128+8, 64+20, 64, 32 ]
  blockdata.push [ 128+8+64, 64+20+32, 32, 32 ]
  loadblocks(blockdata)

  placeshrub V 64*8, 64*5-4
  placeshrub V 64*7-48, 64*5-4
  placeshrub V 64*9, 64*5-4

WORLDINIT = () ->
  bugmeter= new BugMeter
  WORLD.entities.push bugmeter
  energymeter= new EnergyMeter
  WORLD.entities.push energymeter
  @bugmeter = bugmeter
  if settings.hat
    WORLD.entities.push new Hat()
  bglayer.forEach (block) ->
    fence=new Fence
    fence.pos = relativetobox block, V(0,0)
    WORLD.spritelayer.push fence
    fence=new Fence
    fence.pos = relativetobox block, V(1,0)
    WORLD.spritelayer.push fence

randtri = ->
  new Poly [ randpos(), randpos(), randpos() ]

omnicide = ->
  WORLD.spritelayer.forEach (sprite) -> sprite.KILLME=true
  WORLD.euthanasia()

clearworld = ->
  WORLD.entities.forEach (sprite) -> removesprite sprite
  WORLD.entities=[]
  WORLD.spritelayer.forEach (sprite) -> removesprite sprite
  WORLD.spritelayer=[]
  WORLD.spritelayer=[]
  bglayer.forEach (sprite) -> removesprite sprite
  bglayer=[]
  WORLD.bglayer=[]
  fglayer.forEach (sprite) -> removesprite sprite
  fglayer=[]
  WORLD.fglayer=[]

ROBOWORLD_INIT = ->
  scatterents Burd, 8
  blockdata=[]
  blockdata.push [ -64, 64*4, 64*12, 100 ]
  blockdata.push [ 64*12, 64*5, 64*12, 100 ]
  loadblocks blockdata
  WORLD.spritelayer=WORLD.spritelayer.concat [0..3].map ->
    new Robo randpos()
  WORLD.spritelayer.push randtri()

#worldchoice = randint 2
#console.log worldchoice
#if worldchoice == 0
#  WORLD_ONE_INIT()
#if worldchoice == 1
#  ROBOWORLD_INIT()
WORLD_ONE_INIT()
WORLDINIT()

camera={}
camera.offset=V()
camera.pos=V()

PIXI.DisplayObjectContainer
cameraoffset = ->
  #tmppos = ladybug.pos.nadd(64).vsub screensize.ndiv 2
  tmppos = ladybug.pos.vsub screensize.ndiv 2
  #tmppos.y = mafs.clamp tmppos.y, -screensize.y, 0
  tmppos.y = 0
  return tmppos.vsub camera.offset.ndiv scale

render = ->
  camera.pos = cameraoffset()
  renderables = [].concat WORLD.bglayer, WORLD.spritelayer, [ladybug], fglayer, WORLD.entities
  renderables.forEach (sprite) -> sprite.render?()
  #WORLD.entities.forEach (ent) -> ent.render?()
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
  WORLD.spritelayer.forEach (sprite) -> sprite.tick?()
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
  fpsgoal = if settings.slowmo then 4 else 60
  tickwaitms = 1000/fpsgoal
  setTimeout mainloop, Math.max tickwaitms-ticktime, 1
  requestAnimFrame animate

xmlwrap = (tagname,body) ->
  xmltag tagname, undefined, body

maketablerow = ( values ) ->
  tds = values.map (v) -> xmlwrap "td", v
  return xmlwrap "tr", tds

bindingsDOM = $ "<table>"
for k,v of control.bindings
  bindingsDOM.append maketablerow [keyCodeToChar[k],control.bindingnames[k] or "??"]

settingsDOM = $ "<table>"
updatesettingstable = () ->
  settingsDOM.html ""
  for k,v of settings
    settingsDOM.append maketablerow [k,v]

INIT = ->
  #body.append "<p>oh my goodness look at all these crimes!</p>"
  #use <em>WASD</em> to wiggle around,
  #<br/><em>X</em> to boggle vacantly and
  #<em>JKL</em> to beat the shit out of your enemies in a lovely manner</p>
  #<p>G and T for some debug dev mode shit, Y for fullscreen, P to pause</p>"
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

BLOCKCREATIONTOOL = {}
BLOCKCREATIONTOOL.creatingblock = false
BLOCKCREATIONTOOL.mousedown = (e) ->
  #ADD BLOCK, LEFT MBUTTON
  #HOLD Z TO SNAP TO GRID
  if e.button != 0 then return
  adjusted = adjustmouseevent e
  adjusted=snapmouseadjust adjusted
  BLOCKCREATIONTOOL.creatingblock=new Block adjusted.x, adjusted.y, 32, 32
  bglayer.push BLOCKCREATIONTOOL.creatingblock
BLOCKCREATIONTOOL.mouseup = (e) ->
  BLOCKCREATIONTOOL.creatingblock.fixnegative()
  BLOCKCREATIONTOOL.creatingblock = false

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
  blox=blocksatpoint bglayer, adjusted
  console.log blox
  if blox.length > 0
    ent=blox[0]
    bglayer = _.without bglayer, ent
    WORLD.bglayer=bglayer
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

spawnables = {}
spawnables.burd = Burd

jame={}
jame.spawn = (classname) ->
  if not spawnables[classname]
    return
  ent=new spawnables[classname]?()
  WORLD.entities.push ent


jame.burdme = ->
  ladybug = new PlayerBurd()
  WORLD.entities.push ladybug
  console.log ladybug

jame.WORLD = WORLD


root.jame = jame
root.stage = stage

