// Generated by CoffeeScript 1.10.0
(function() {
  var HitboxRayIntersect, Line2d, V, V2d, arrclone, arrsansval, mafs, memoize, root, vnop, vvop, xmlatts, xmltag,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    slice = [].slice,
    hasProp = {}.hasOwnProperty;

  arrclone = function(arr) {
    return arr.slice(0);
  };

  arrsansval = function(arr, val) {
    var i, newarr, ref;
    newarr = arrclone(arr);
    if (ref = !val, indexOf.call(arr, ref) >= 0) {
      return newarr;
    }
    i = newarr.indexOf(val);
    newarr.splice(i, 1);
    return newarr;
  };

  mafs = {};

  mafs.add = function(a, b) {
    return a + b;
  };

  mafs.sub = function(a, b) {
    return a - b;
  };

  mafs.mul = function(a, b) {
    return a * b;
  };

  mafs.div = function(a, b) {
    return a / b;
  };

  mafs.sum = function(arr) {
    return arr.reduce(mafs.add, 0);
  };

  mafs.avg = function(arr) {
    return mafs.sum(arr) / arr.length;
  };

  mafs.sq = function(n) {
    return Math.pow(n, 2);
  };

  mafs.sign = function(n) {
    if (n > 0) {
      return 1;
    }
    if (n < 0) {
      return -1;
    }
    return 0;
  };

  mafs.clamp = function(n, min, max) {
    if (n > max) {
      return max;
    }
    if (n < min) {
      return min;
    }
    return n;
  };

  V2d = (function() {
    function V2d(x1, y1) {
      this.x = x1 != null ? x1 : 0;
      this.y = y1 != null ? y1 : 0;
    }

    return V2d;

  })();

  V = function(x, y) {
    return new V2d(x, y);
  };

  V2d.clone = function(v) {
    return new V2d(v.x, v.y);
  };

  V2d.zero = function(v) {
    return new V2d(0, 0);
  };

  vvop = function(op) {
    return function(v, u) {
      return V(op(v.x, u.x), op(v.y, u.y));
    };
  };

  vnop = function(op) {
    return function(v, n) {
      return V(op(v.x, n), op(v.y, n));
    };
  };


  /*
  V2d.vadd = vvop mafs.add
  V2d.vsub = vvop mafs.sub
  V2d.vmul = vvop mafs.mul
  V2d.vdiv = vvop mafs.div
  
  V2d.nadd = vnop mafs.add
  V2d.nsub = vnop mafs.sub
  V2d.nmul = vnop mafs.mul
  V2d.ndiv = vnop mafs.div
   */

  V2d.vadd = function(v, u) {
    return V(v.x + u.x, v.y + u.y);
  };

  V2d.vsub = function(v, u) {
    return V(v.x - u.x, v.y - u.y);
  };

  V2d.vmul = function(v, u) {
    return V(v.x * u.x, v.y * u.y);
  };

  V2d.vdiv = function(v, u) {
    return V(v.x / u.x, v.y / u.y);
  };

  V2d.nadd = function(v, n) {
    return V(v.x + n, v.y + n);
  };

  V2d.nsub = function(v, n) {
    return V(v.x - n, v.y - n);
  };

  V2d.nmul = function(v, n) {
    return V(v.x * n, v.y * n);
  };

  V2d.ndiv = function(v, n) {
    return V(v.x / n, v.y / n);
  };

  V2d.dist = function(v, u) {
    return v.vsub(u).mag();
  };

  V2d.dir = function(v, u) {
    return u.sub(v).norm();
  };

  V2d.mag = function(v) {
    return Math.sqrt(mafs.sq(v.x) + mafs.sq(v.y));
  };

  V2d.norm = function(v) {
    return v.ndiv(v.mag());
  };

  V2d.dot = function(v, b) {
    return v.x * b.x + v.y * b.y;
  };

  V2d.cross = function(v, b) {
    return v.x * b.y - v.y * b.x;
  };

  V2d.toarr = function(v) {
    return [v.x, v.y];
  };

  V2d.prototype.vadd = function(v) {
    return V2d.vadd(this, v);
  };

  V2d.prototype.vsub = function(v) {
    return V2d.vsub(this, v);
  };

  V2d.prototype.vmul = function(v) {
    return V2d.vmul(this, v);
  };

  V2d.prototype.vdiv = function(v) {
    return V2d.vdiv(this, v);
  };

  V2d.prototype.nadd = function(n) {
    return V2d.nadd(this, n);
  };

  V2d.prototype.nsub = function(n) {
    return V2d.nsub(this, n);
  };

  V2d.prototype.nmul = function(n) {
    return V2d.nmul(this, n);
  };

  V2d.prototype.ndiv = function(n) {
    return V2d.ndiv(this, n);
  };

  V2d.prototype.dist = function(u) {
    return V2d.dist(this, u);
  };

  V2d.prototype.dir = function(u) {
    return V2d.dir(this, u);
  };

  V2d.prototype.mag = function() {
    return V2d.mag(this);
  };

  V2d.prototype.norm = function() {
    return V2d.norm(this);
  };

  V2d.prototype.dot = function(b) {
    return V2d.dot(this, b);
  };

  V2d.prototype.cross = function(b) {
    return V2d.cross(this, b);
  };

  V2d.prototype.toarr = function() {
    return V2d.toarr(this);
  };

  V2d.prototype.op = function(op) {
    return new V2d(op(this.x), op(this.y));
  };

  V2d.prototype.cross2d = function(b) {
    return this.x * b.y - this.y * b.x;
  };

  V2d.random = function() {
    return new V2d(Math.random(), Math.random());
  };

  mafs.randfloat = function() {
    return -1 + Math.random() * 2;
  };

  mafs.randvec = function() {
    return V(mafs.randfloat(), mafs.randfloat());
  };

  mafs.randint = function(max) {
    return Math.floor(Math.random() * max);
  };

  mafs.randelem = function(arr) {
    return arr[mafs.randint(arr.length)];
  };

  mafs.degstorads = function(degs) {
    return degs * Math.PI / 180;
  };

  memoize = function(fn) {
    return function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      fn._memos || (fn._memos = {});
      return fn._memos[args] || (fn._memos[args] = fn.apply(this, args));
    };
  };

  xmlatts = function(atts) {
    var key, val;
    return ((function() {
      var results;
      results = [];
      for (key in atts) {
        if (!hasProp.call(atts, key)) continue;
        val = atts[key];
        results.push(" " + key + "=\"" + val + "\"");
      }
      return results;
    })()).join();
  };

  xmltag = function(type, atts, body) {
    if (type == null) {
      type = "div";
    }
    if (atts == null) {
      atts = {};
    }
    if (body == null) {
      body = "";
    }
    return "<" + type + (xmlatts(atts)) + ">" + body + "</" + type + ">";
  };

  Line2d = (function() {
    function Line2d(p1, p2) {
      this.p1 = p1;
      this.p2 = p2;
    }

    return Line2d;

  })();

  Line2d.prototype.lineintersect = function(lineb) {
    var linea, p, q, r, s, t, u;
    linea = this;
    p = linea.p1;
    r = linea.p2.vsub(p);
    q = lineb.p1;
    s = lineb.p2.vsub(q);
    t = q.vsub(p).cross2d(s) / r.cross2d(s);
    u = q.vsub(p).cross2d(r) / r.cross2d(s);
    if (t <= 1 && t >= 0 && u <= 1 && u >= 0) {
      return p.vadd(r.nmul(t));
    }
    return null;
  };

  HitboxRayIntersect = function(rect, line) {
    var a, b, dx, maxx, maxy, minx, miny, tmp;
    minx = line.p1.x;
    maxx = line.p2.x;
    if (line.p1.x > line.p2.x) {
      minx = line.p2.x;
      maxx = line.p1.x;
    }
    maxx = Math.min(maxx, rect.bottomright.x);
    minx = Math.max(minx, rect.topleft.x);
    if (minx > maxx) {
      return false;
    }
    miny = line.p1.y;
    maxy = line.p2.y;
    dx = line.p2.x - line.p1.x;
    if (Math.abs(dx) > 0.0000001) {
      a = (line.p2.y - line.p1.y) / dx;
      b = line.p1.y - a * line.p1.x;
    }
    miny = a * minx + b;
    maxy = a * maxx + b;
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

  mafs.pointlisttoedges = function(parr) {
    var curr, edges, i, j, len, prev;
    edges = [];
    prev = parr[parr.length - 1];
    for (i = j = 0, len = parr.length; j < len; i = ++j) {
      curr = parr[i];
      edges.push(new Line2d(prev, curr));
      prev = curr;
    }
    return edges;
  };

  mafs.HitboxRayIntersect = HitboxRayIntersect;

  mafs.Line2d = Line2d;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.V2d = V2d;

  root.mafs = mafs;

  root.memoize = memoize;

  root.xmltag = xmltag;

}).call(this);

//# sourceMappingURL=helpers.js.map
