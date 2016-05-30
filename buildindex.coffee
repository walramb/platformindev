#generates a simple HTML5 index.html file

ld = require "lodash"
fs = require "fs"

# * SETTINGS
topdir = "./public/"

# * FUNCTIONS
# extract values from obj in specific order
ech = ( statobj, cols ) ->
  (for n in cols
    statobj[n]
  )
xml = ( tag, inner="" ) -> "<#{tag}>#{inner}</#{tag}>"
xmls = ( tag, inners ) ->
  (for inner in inners
    xml tag, inner).join "\n"

# REST OF THE GARBAGE GOES HERE

filterdirs = (root,paths) ->
  paths.filter (name) -> fs.statSync(root+name).isDirectory()
filterfiles = (root,paths) ->
  paths.filter (name) -> not fs.statSync(root+name).isDirectory()

dirsIn = (name) ->
  filterdirs name, fs.readdirSync name
filesIn = (name) ->
  filterfiles name, fs.readdirSync name

filetable = ( dirname ) ->
  files = filesIn dirname
  dirs = files.filter (name) -> fs.statSync(dirname+name).isDirectory()
  cols = [ "size", "mtime" ]
  fstats=(for name in files
    stats = fs.statSync dirname + name
    ld.extend {name}, ld.pick stats, cols)
  cols = [ "name", "size", "mtime" ]
  for stat in fstats
    stat.name = "<a href=#{topdir + stat.name}>#{stat.name}</a>"
  o=""
  o+= "<table>"
  o+= "<tr>"
  o+= xmls "th", cols
  o+= "</tr>"
  for f in fstats
    o+= "<tr>"
    o+= xmls "td", ech f, cols
    o+= "</tr>"
  o+= "</table>"
  return o


deetsum = ( sum, deet ) ->
  xml "details", xml( "summary", sum ) + xml("div", deet)

tree = ( dirname ) ->
  subdirs = dirsIn dirname
  inner = ""
  if subdirs.length > 0
    for d in subdirs
      nd = dirname + d + "/"
      inner += tree nd
  inner += filetable dirname
  return deetsum dirname, inner

out = ""
put = (text) -> out += text

put "<style>summary + div {  margin: 0 2em;  }</style>"
put tree "./public/"

console.log out
