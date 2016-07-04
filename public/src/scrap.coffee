#SCRAP CODE
# why not just delete it you ask
# because fug u


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

BugLady::polygoncollisions = ->
  stats.collisionchecks++
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
    if geometry.pointInsidePoly p, candidate.points
      @vel.y--


#pilfered from stackoverflow
hue2rgb = (p,q,t) ->
  if t < 0 then t++
  if t > 1 then t--
  if t < 1/6 then return p+(q-p)*6*t
  if t < 1/2 then return q
  if t < 2/3 then return p+(q-p)*(2/3-t)*6
  return p

hslToRgb = (h,s,l) ->
  if s is 0
    r = g = b = l
  else
    q = if l < 0.5 then l * (1+s) else l+s-l*s
    p = 2*l-q
    r=hue2rgb(p,q,h+1/3)
    g=hue2rgb(p,q,h)
    b=hue2rgb(p,q,h-1/3)
  return [Math.round(r*255),Math.round(g*255),Math.round(b*255)]

rgbToHex = (rgb) ->
  [r,g,b]=rgb
  r*256*256+g*256+b
