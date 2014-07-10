// Generated by CoffeeScript 1.6.3
(function() {
  var Graph, HitboxRayIntersect, Line, LineSegment, Point, Polygon, Rect, Square, Tracer, V, angletonorm, body, cornerstorect, degstorads, edgestopolys, entDir, entDist, entfirebullet, firetracer, firstwallhitloc, geometry, normtoangle, pointInsidePoly, pointlisttoedges, randangle, ricochet, root, rotate2d, vectorindex, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  body = $("body");

  V = function(x, y) {
    return new V2d(x, y);
  };

  degstorads = function(deg) {
    return deg * Math.PI / 180;
  };

  rotate2d = function(vec, deg) {
    var matrix, newv, theta;
    theta = degstorads(deg);
    matrix = [[Math.cos(theta), -Math.sin(theta)], [Math.sin(theta), Math.cos(theta)]];
    newv = matrixtransform(matrix, [vec.x, vec.y]);
    return V(newv[0], newv[1]);
  };

  cornerstorect = function(a, b) {
    var l, r, t;
    l = Math.min(a.x, b.x);
    r = Math.max(a.x, b.x);
    t = Math.min(a.y, b.y);
    b = Math.max(a.y, b.y);
    return new Rect(V(l, t), V(r, b));
  };

  Rect = (function() {
    function Rect(left, top, bottom, right) {
      this.left = left;
      this.top = top;
      this.bottom = bottom;
      this.right = right;
    }

    Object.defineProperties(Rect.prototype, {
      width: {
        get: function() {
          return this.right - this.left;
        }
      },
      height: {
        get: function() {
          return this.bottom - this.top;
        }
      },
      area: {
        get: function() {
          return this.width * this.height;
        }
      },
      perimeter: {
        get: function() {
          return (this.width + this.height) * 2;
        }
      }
    });

    return Rect;

  })();

  Rect.prototype.overlap = function(other) {
    var b, l, r, t;
    l = Math.max(this.left, other.left);
    r = Math.min(this.right, other.right);
    t = Math.max(this.top, other.top);
    b = Math.min(this.bottom, other.bottom);
    return new Rect(l, t, b, r);
  };

  Line = (function() {
    function Line(from, to) {
      this.from = from != null ? from : V();
      this.to = to != null ? to : V();
    }

    return Line;

  })();

  Tracer = (function(_super) {
    __extends(Tracer, _super);

    function Tracer() {
      _ref = Tracer.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return Tracer;

  })(Line);

  Line.prototype.intersection = function(lineb) {
    var p, q, r, s, t, u;
    p = this.loc;
    r = this.to.sub(p);
    q = lineb.loc;
    s = lineb.to.sub(q);
    t = q.sub(p).cross2d(s) / r.cross2d(s);
    u = q.sub(p).cross2d(r) / r.cross2d(s);
    if (t <= 1 && t >= 0 && u <= 1 && u >= 0) {
      return p.add(r.nmul(t));
    }
    return null;
  };

  HitboxRayIntersect = function(rect, line) {
    var a, b, dx, maxx, maxy, minx, miny, tmp;
    minx = line.loc.x;
    maxx = line.to.x;
    if (line.loc.x > line.to.x) {
      minx = line.to.x;
      maxx = line.loc.x;
    }
    maxx = Math.min(maxx, rect.bottomright.x);
    minx = Math.max(minx, rect.topleft.x);
    if (minx > maxx) {
      return false;
    }
    miny = line.loc.y;
    maxy = line.to.y;
    dx = line.to.x - line.loc.x;
    if (Math.abs(dx) > 0.0000001) {
      a = (line.to.y - line.loc.y) / dx;
      b = line.loc.y - a * line.loc.x;
      miny = a * minx + b;
      maxy = a * maxx + b;
    }
    if (miny > maxy) {
      tmp = maxy;
      maxy = miny;
      miny = tmp;
    }
    maxy = Math.min(maxy, rect.bottomright.y);
    miny = Math.max(miny, rect.topleft.y);
    if (miny > maxy) {
      return false;
    }
    return true;
  };

  randangle = function() {
    return Math.random() * 360;
  };

  ricochet = function(v, n) {
    var u, vprime, w;
    u = n.nmul(v.dot2d(n) / n.dot2d(n));
    w = v.sub(u);
    vprime = w.sub(u);
    return vprime;
  };

  Tracer.prototype.intersectlocs = function() {
    var allLineDefs, intersections, linedef, results;
    allLineDefs = gameworld.getLineDefs();
    results = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = allLineDefs.length; _i < _len; _i++) {
        linedef = allLineDefs[_i];
        _results.push(getLineIntersection(this, linedef));
      }
      return _results;
    }).call(this);
    intersections = results.filter(function(n) {
      return n !== null;
    });
    return intersections;
  };

  Tracer.prototype.intersectwalls = function() {
    var allLineDefs, intersections,
      _this = this;
    allLineDefs = gameworld.getLineDefs();
    intersections = allLineDefs.filter(function(ld) {
      return getLineIntersection(_this, ld) !== null;
    });
    return intersections;
  };

  firstwallhitloc = function(trace, intersections) {
    var firsthit, fromloc;
    fromloc = trace.loc;
    firsthit = intersections.reduce(function(prev, curr) {
      if (fromloc.dist(prev) > fromloc.dist(curr)) {
        return curr;
      } else {
        return prev;
      }
    });
    return firsthit;
  };

  firetracer = function(fromloc, dir) {
    var firsthit, intersections, toloc, trace, tracerange;
    tracerange = 500;
    toloc = fromloc.add(dir.norm().nmul(tracerange));
    trace = new Tracer(fromloc, toloc);
    intersections = trace.intersectlocs();
    if (intersections.length > 0) {
      firsthit = firstwallhitloc(trace, intersections);
      trace = new Tracer(trace.loc, firsthit);
    }
    return trace;
  };

  entfirebullet = function(ent, dir) {
    var allactors, bulletrange, fromloc, hits, targets, trace;
    bulletrange = 200;
    fromloc = ent.loc.nadd(0);
    dir = dir.add(randompoint().nsub(1 / 2).ndiv(4)).norm();
    trace = firetracer(fromloc, dir);
    allactors = gameworld.entitylist.filter(function(ent) {
      return ent instanceof Actor;
    });
    targets = allactors.filter(function(actor) {
      return actor !== ent;
    });
    hits = trace.checkEnts(targets);
    hits.forEach(function(hitent) {
      return bullethit(hitent, trace);
    });
    return gameworld.addent(trace);
  };

  LineDef.prototype.normal = function() {
    var wallnormal;
    wallnormal = this.to.sub(this.loc).norm();
    wallnormal = V(-wallnormal.y, wallnormal.x);
    return wallnormal;
  };

  Polygon = (function(_super) {
    __extends(Polygon, _super);

    function Polygon(points) {
      this.points = points;
      this.loc = this.points[0];
    }

    return Polygon;

  })(Entity);

  pointlisttoedges = function(parr) {
    var curr, edges, i, prev, _i, _len;
    edges = [];
    prev = parr[parr.length - 1];
    for (i = _i = 0, _len = parr.length; _i < _len; i = ++_i) {
      curr = parr[i];
      edges.push(new Tracer(prev, curr));
      prev = curr;
    }
    return edges;
  };

  pointInsidePoly = function(p, poly) {
    var e, edges, intersections, results, trace;
    trace = new Tracer(p, p.add(V(10000, 0)));
    edges = pointlisttoedges(poly);
    results = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = edges.length; _i < _len; _i++) {
        e = edges[_i];
        _results.push(getLineIntersection(trace, e));
      }
      return _results;
    })();
    intersections = results.filter(function(n) {
      return n !== null;
    });
    if (intersections.length % 2 === 1) {
      return true;
    }
    return false;
  };

  Graph = (function() {
    function Graph() {
      this.nodes = [];
      this.edges = [];
    }

    return Graph;

  })();

  normtoangle = function(vec) {
    return Math.atan2(vec.x, vec.y) * 180 / Math.PI;
  };

  angletonorm = function(degs) {
    var augh;
    augh = degstorads(degs);
    return V(Math.sin(augh), Math.cos(augh));
  };

  Point = (function() {
    function Point(pos) {
      this.pos = pos;
    }

    return Point;

  })();

  LineSegment = (function() {
    function LineSegment(startpoint, endpoint) {
      this.startpoint = startpoint;
      this.endpoint = endpoint;
    }

    return LineSegment;

  })();

  Rect = (function(_super) {
    __extends(Rect, _super);

    function Rect(topleft, bottomright) {
      this.topleft = topleft;
      this.bottomright = bottomright;
      this.loc = this.topleft;
    }

    Rect.prototype.draw = function() {
      var size;
      size = this.bottomright.sub(this.topleft);
      return "<rect x=" + this.topleft.x + " y=" + this.topleft.y + " width=" + size.x + " height=" + size.y + " stroke=magenta fill=none/>";
    };

    return Rect;

  })(Entity);

  Rect.prototype.containspoint = function(pt) {
    if (this.topleft.x > pt.x) {
      return false;
    }
    if (this.bottomright.x < pt.x) {
      return false;
    }
    if (this.topleft.y > pt.y) {
      return false;
    }
    if (this.bottomright.y < pt.y) {
      return false;
    }
    return true;
  };

  Square = (function(_super) {
    __extends(Square, _super);

    function Square(topleft, bottomright) {
      this.topleft = topleft;
      this.bottomright = bottomright;
      this.loc = this.topleft;
      this.age = 0;
    }

    Square.prototype.tick = function() {
      this.age++;
      if (this.age > 4) {
        return this.kill();
      }
    };

    Square.prototype.draw = function() {
      var size;
      size = this.bottomright.sub(this.topleft);
      return "<rect x=" + this.topleft.x + " y=" + this.topleft.y + " width=" + size.x + " height=" + size.y + " stroke=magenta fill=none/>";
    };

    return Square;

  })(Entity);

  entDist = function(enta, entb) {
    return enta.loc.dist(entb.loc);
  };

  entDir = function(enta, entb) {
    return enta.loc.dir(entb.loc);
  };

  vectorindex = function(array, vector) {
    var i, res, v, _i, _len;
    res = -1;
    for (i = _i = 0, _len = array.length; _i < _len; i = ++_i) {
      v = array[i];
      if (vector.dist(v) === 0) {
        res = i;
      }
    }
    return res;
  };

  edgestopolys = function(edges) {
    var a, b, edge, i, ia, ib, len, pol, polys, restedges, sploiced, _i, _j, _len, _len1;
    polys = [];
    restedges = edges.map(function(e) {
      var a, b;
      a = V(e[0].x, e[0].y);
      b = V(e[1].x, e[1].y);
      return [a, b];
    });
    for (i = _i = 0, _len = restedges.length; _i < _len; i = ++_i) {
      edge = restedges[i];
      a = edge[0];
      b = edge[1];
      sploiced = false;
      for (i = _j = 0, _len1 = polys.length; _j < _len1; i = ++_j) {
        pol = polys[i];
        ia = vectorindex(pol, a);
        ib = vectorindex(pol, b);
        len = pol.length;
        if (ib === 0 || ia === 0 || ib === len - 1 || ia === len - 1) {
          sploiced = true;
        }
        if (ia === 0) {
          pol.splice(0, 0, b);
          break;
        }
        if (ib === 0) {
          pol.splice(0, 0, a);
          break;
        }
        if (ia === len - 1) {
          pol.splice(len, 0, b);
          break;
        }
        if (ib === len - 1) {
          pol.splice(len, 0, a);
          break;
        }
      }
      if (sploiced === false) {
        polys.push(edge);
      }
    }
    return polys;
  };

  geometry = {};

  geometry.pointInsidePoly = pointInsidePoly;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.geometry = geometry;

}).call(this);
