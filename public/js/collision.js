// Generated by CoffeeScript 1.10.0
(function() {
  var $body, PHYSOBJTORECT, PhysElem, PhysGroup, animate, i, physobjdraw, physobjs, renderer, results, root, screensize, stage;

  $body = $('body');

  $body.append($('<p>fug</p>'));

  screensize = {
    x: 640,
    y: 480
  };

  renderer = PIXI.autoDetectRenderer(screensize.x, screensize.y);

  stage = new PIXI.Stage(0xcccccc);

  $body.append(renderer.view);

  PhysElem = (function() {
    function PhysElem() {
      this.vel = {
        x: 0,
        y: 0
      };
      this.pos = {
        x: 0,
        y: 0
      };
      this.size = {
        x: 32,
        y: 32
      };
    }

    return PhysElem;

  })();

  PhysElem.prototype.overlaps = function(other) {
    if (other.pos.x > (this.pos.x + this.size.x) || other.pos.y > (this.pos.y + this.size.y) || (other.pos.x + other.size.x) < this.pos.x || (other.pos.y + other.size.y) < this.pos.y) {
      return false;
    } else {
      return true;
    }
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

  PhysGroup = (function() {
    function PhysGroup() {
      this.children = [];
      this.domain = {
        x: 0,
        y: 0,
        w: 640,
        h: 480
      };
      this.tree = new QuadTree(0, this.domain);
    }

    PhysGroup.prototype.addchild = function(child) {
      return this.children.push(child);
    };

    return PhysGroup;

  })();

  PhysGroup.prototype.rebuildtree = function() {
    this.tree = new QuadTree();
    return this.children.forEach((function(_this) {
      return function(child) {
        return _this.tree.insert(PHYSOBJTORECT(child));
      };
    })(this));
  };

  PHYSOBJTORECT = function(child) {
    var fuck;
    fuck = {
      x: child.pos.x,
      y: child.pos.y,
      w: child.size.x,
      h: child.size.y,
      LINK: child
    };
    return fuck;
  };

  QuadTree.prototype.grafics = function() {
    var color, grafic, pad;
    grafic = new PIXI.Graphics();
    color = 0x0000ff - this.level * 8;
    grafic.lineStyle(1, color, 1);
    pad = -this.level * 2;
    grafic.drawRect(this.bounds.x - pad, this.bounds.y - pad, this.bounds.w + pad, this.bounds.h + pad);
    stage.addChild(grafic);
    return _.invoke(this.subnodes, 'grafics');
  };

  PhysGroup.prototype.grafics = function() {
    return this.tree.grafics();
  };

  PhysElem.prototype.integrate = function() {
    this.pos.x += this.vel.x;
    return this.pos.y += this.vel.y;
  };

  PhysElem.prototype.wraparound = function() {
    this.pos.x = this.pos.x % 640;
    return this.pos.y = this.pos.y % 480;
  };

  PhysGroup.prototype.tick = function() {
    this.grafics();
    this.colls = [];
    this.children.forEach(function(child) {
      child.integrate();
      return child.wraparound();
    });
    this.rebuildtree();
    return this.children.forEach((function(_this) {
      return function(child) {
        var candidates, newcolls;
        candidates = _this.tree.retrieve(PHYSOBJTORECT(child));
        candidates = candidates.map(function(cand) {
          return cand.LINK;
        });
        newcolls = _.filter(candidates, function(candidate) {
          return child.overlaps(candidate);
        });
        return child.iscolliding = newcolls.length > 1;
      };
    })(this));
  };

  physobjs = new PhysGroup();

  (function() {
    results = [];
    for (i = 0; i <= 100; i++){ results.push(i); }
    return results;
  }).apply(this).forEach(function() {
    var elm;
    elm = new PhysElem();
    elm.pos.x = Math.random() * 640;
    elm.pos.y = Math.random() * 480;
    elm.size.x = Math.random() * 50;
    elm.size.y = Math.random() * 50;
    elm.vel.x = Math.random() * 10;
    elm.vel.x = Math.random() * 3;
    return physobjs.addchild(elm);
  });

  physobjdraw = function(obj) {
    var color, grafic, h, ref, w;
    grafic = new PIXI.Graphics();
    ref = [obj.size.x, obj.size.y], w = ref[0], h = ref[1];
    color = 0x00ff00;
    if (obj.iscolliding) {
      color = 0xff0000;
    }
    grafic.lineStyle(1, color, 1);
    grafic.drawRect(obj.pos.x, obj.pos.y, obj.size.x, obj.size.y);
    return stage.addChild(grafic);
  };

  animate = function() {
    stage = new PIXI.Stage();
    physobjs.tick();
    physobjs.children.forEach(function(child) {
      return physobjdraw(child);
    });
    renderer.render(stage);
    return requestAnimFrame(animate);
  };

  requestAnimFrame(animate);

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

}).call(this);

//# sourceMappingURL=collision.js.map
