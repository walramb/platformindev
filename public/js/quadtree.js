// Generated by CoffeeScript 1.10.0
(function() {
  var QuadTree, rect, root;

  rect = function(x, y, w, h) {
    return {
      x: x,
      y: y,
      w: w,
      h: h
    };
  };

  QuadTree = (function() {
    function QuadTree(level, bounds) {
      this.level = level != null ? level : 0;
      this.bounds = bounds;
      if (this.bounds == null) {
        this.bounds = {
          x: 0,
          y: 0,
          w: 640,
          h: 480
        };
      }
      this.MAXOBJS = 1;
      this.MAXDEPTH = 4;
      this.objs = [];
      this.subnodes = [];
    }

    QuadTree.prototype.clear = function() {
      this.objs = [];
      return this.subnodes = [];
    };

    return QuadTree;

  })();

  QuadTree.prototype.split = function() {
    var h, w, x, y;
    x = this.bounds.x;
    y = this.bounds.y;
    w = Math.floor(this.bounds.w / 2);
    h = Math.floor(this.bounds.h / 2);
    this.subnodes[0] = new QuadTree(this.level + 1, rect(x + w, y, w, h));
    this.subnodes[1] = new QuadTree(this.level + 1, rect(x, y, w, h));
    this.subnodes[2] = new QuadTree(this.level + 1, rect(x, y + h, w, h));
    return this.subnodes[3] = new QuadTree(this.level + 1, rect(x + w, y + h, w, h));
  };

  QuadTree.prototype.getindex = function(rect) {
    var index, isbot, isleft, isright, istop, xmid, ymid;
    index = -1;
    xmid = this.bounds.x + this.bounds.w / 2;
    ymid = this.bounds.y + this.bounds.h / 2;
    istop = rect.y + rect.h < ymid;
    isbot = rect.y > ymid;
    isleft = rect.x + rect.w < ymid;
    isright = rect.x > ymid;
    if (istop && isright) {
      index = 0;
    }
    if (istop && isleft) {
      index = 1;
    }
    if (isbot && isleft) {
      index = 2;
    }
    if (isbot && isright) {
      index = 3;
    }
    return index;
  };

  QuadTree.prototype.insert = function(newobj) {
    var index;
    if (this.subnodes.length > 0) {
      index = this.getindex(newobj);
      if (index !== -1) {
        this.subnodes[index].insert(newobj);
      }
    }
    this.objs.push(newobj);
    if (this.objs.length > this.MAXOBJS && this.level < this.MAXDEPTH) {
      if (this.subnodes.length === 0) {
        this.split();
        return this.objs.forEach((function(_this) {
          return function(obj) {
            index = _this.getindex(obj);
            if (index !== -1) {
              _this.subnodes[index].insert(obj);
              return _this.objs = _.without(_this.objs, obj);
            }
          };
        })(this));
      }
    }
  };

  QuadTree.prototype.retrieve = function(rect) {
    var index, retobjs;
    retobjs = [];
    index = this.getindex(rect);
    if (index !== -1 && this.subnodes.length !== 0) {
      retobjs = this.subnodes[index].retrieve(retobjs, rect);
    }
    retobjs = _.union(retobjs, this.objs);
    return retobjs;
  };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.QuadTree = QuadTree;

}).call(this);

//# sourceMappingURL=quadtree.js.map
