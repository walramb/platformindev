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
mafs={}
mafs.add = (a,b) -> a+b
mafs.sub = (a,b) -> a-b
mafs.mul = (a,b) -> a*b
mafs.div = (a,b) -> a/b

mafs.sum = (arr) -> arr.reduce mafs.add, 0
mafs.avg = (arr) -> mafs.sum(arr)/arr.length
mafs.sq = (n) -> Math.pow n,2
mafs.sign = (n) ->
  if n > 0 then return 1
  if n < 0 then return -1
  return 0

mafs.clamp = ( n, min, max ) ->
  if n > max then return max
  if n < min then return min
  return n

#vectors
class V2d
  constructor: ( @x=0, @y=0 ) ->

V = (x,y) -> new V2d x,y
V2d.clone = (v) -> new V2d v.x, v.y
V2d.zero = (v) -> new V2d 0, 0


vvop = (op) -> (v,u) -> V op(v.x,u.x), op(v.y,u.y)
vnop = (op) -> (v,n) -> V op(v.x,n), op(v.y,n)

# is poor opptimization of this bogging shit down?
###
V2d.vadd = vvop mafs.add
V2d.vsub = vvop mafs.sub
V2d.vmul = vvop mafs.mul
V2d.vdiv = vvop mafs.div

V2d.nadd = vnop mafs.add
V2d.nsub = vnop mafs.sub
V2d.nmul = vnop mafs.mul
V2d.ndiv = vnop mafs.div
###

V2d.vadd = (v,u) -> V v.x+u.x, v.y+u.y
V2d.vsub = (v,u) -> V v.x-u.x, v.y-u.y
V2d.vmul = (v,u) -> V v.x*u.x, v.y*u.y
V2d.vdiv = (v,u) -> V v.x/u.x, v.y/u.y

V2d.nadd = (v,n) -> V v.x+n, v.y+n
V2d.nsub = (v,n) -> V v.x-n, v.y-n
V2d.nmul = (v,n) -> V v.x*n, v.y*n
V2d.ndiv = (v,n) -> V v.x/n, v.y/n


V2d.dist = (v,u) -> v.vsub(u).mag()
V2d.dir = (v,u) -> u.sub(v).norm()
V2d.mag = (v) -> Math.sqrt mafs.sq(v.x)+mafs.sq(v.y)
V2d.norm = (v) -> v.ndiv v.mag()
V2d.dot = (v,b) -> v.x*b.x+v.y*b.y
V2d.cross = (v,b) -> v.x*b.y-v.y*b.x
V2d.toarr = (v) -> [ v.x, v.y ]

V2d::vadd = (v) -> V2d.vadd @,v
V2d::vsub = (v) -> V2d.vsub @,v
V2d::vmul = (v) -> V2d.vmul @,v
V2d::vdiv = (v) -> V2d.vdiv @,v
V2d::nadd = (n) -> V2d.nadd @,n
V2d::nsub = (n) -> V2d.nsub @,n
V2d::nmul = (n) -> V2d.nmul @,n
V2d::ndiv = (n) -> V2d.ndiv @,n
V2d::dist = (u) -> V2d.dist @,u
V2d::dir = (u) -> V2d.dir @,u
V2d::mag = () -> V2d.mag @
V2d::norm = () -> V2d.norm @
V2d::dot = (b) -> V2d.dot @,b
V2d::cross = (b) -> V2d.cross @,b
V2d::toarr = () -> V2d.toarr @

V2d::op = (op) -> new V2d op(@.x), op(@.y)

V2d::cross2d = (b) -> @.x*b.y-@.y*b.x

#alright fuck this
#for key,value of V2d
#  console.log key,value
#  V2d::[key] = (rest) => value @, rest


V2d.random = -> new V2d Math.random(), Math.random()

#random float between -1 and 1
randfloat = () -> -1+Math.random()*2
randint = (max) -> Math.floor Math.random()*max

memoize = (fn) ->
  (args...) ->
    fn._memos or fn._memos={}
    fn._memos[args] or fn._memos[args] = fn.apply @, args


xmlatts = (atts) ->
  (" #{key}=\"#{val}\"" for own key,val of atts).join() 
xmltag = (type="div", atts={}, body="") ->
  "<#{type}#{xmlatts atts}>#{body}</#{type}>"

root = exports ? this
root.V2d = V2d
root.mafs = mafs
root.memoize = memoize
root.xmltag = xmltag

