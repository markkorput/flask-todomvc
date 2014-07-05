// Generated by CoffeeScript 1.6.3
(function() {
  var GraphLine, GraphLines, GraphLinesOps, VisualSettings, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  this.GameVisuals = (function() {
    function GameVisuals(_opts) {
      this.options = _opts;
      this.two = new Two({
        autostart: true,
        fullscreen: true,
        type: Two.Types.svg
      }).appendTo(document.body);
      $(window).on('resize', this._resize);
      this.visual_settings = new VisualSettings({
        two: this.two,
        game_states: this.options.game_states
      });
      this._initScene();
      this.two.bind('update', function() {
        return TWEEN.update();
      });
    }

    GameVisuals.prototype._resize = function() {
      if (!this.two) {
        return;
      }
      this.two.renderer.setSize($(window).width(), $(window).height());
      this.two.width = this.two.renderer.width;
      return this.two.height = this.two.renderer.height;
    };

    GameVisuals.prototype._initScene = function() {
      var bg;
      bg = this.two.makeRectangle(this.two.width / 2, this.two.height / 2, this.two.width, this.two.height);
      bg.fill = '#92adac';
      bg.noStroke();
      this.two.add(bg);
      this.graph_lines = new GraphLines({
        two: this.two,
        game_states: this.options.game_states,
        visual_settings: this.visual_settings
      });
      return this.graph_lines_ops = new GraphLinesOps({
        target: this.graph_lines
      });
    };

    GameVisuals.prototype.previousState = function() {
      return this.options.game_states.at(this.options.game_states.length - 2);
    };

    return GameVisuals;

  })();

  GraphLine = (function(_super) {
    __extends(GraphLine, _super);

    function GraphLine(_opts) {
      this.options = _opts;
      this.two = _opts.two;
      this.game_states = _opts.game_states;
      this.visual_settings = _opts.visual_settings;
      this.skill = _opts.skill;
      this.group = this.two.makeGroup();
      this.group.translation.set(0, 0);
      this._initPolygons();
      this.game_states.on('add', this._growNewState, this);
      this.visual_settings.on('change:animationRange', this._updateVertices, this);
    }

    GraphLine.prototype._initPolygons = function() {
      var _this = this;
      return _.each(_.range(1, this.game_states.length - 1), function(i) {
        return _this._initState(_this.game_states.at(i - 1), _this.game_states.at(i), i);
      });
    };

    GraphLine.prototype._initState = function(prevState, state, idx) {
      var prevSkill, skill;
      skill = this._skillFromState(state);
      prevSkill = this._skillFromState(prevState);
      if (skill && prevSkill) {
        return this._addLine(prevSkill, skill, idx);
      }
    };

    GraphLine.prototype._skillFromState = function(state) {
      var _this = this;
      return state.get('skills').find(function(_skill) {
        return _skill.get('text') === _this.skill.get('text');
      });
    };

    GraphLine.prototype._addLine = function(prevSkill, skill, index) {
      var line, x1, x2;
      x1 = (index - 1) * this.visual_settings.get('horizontalScale');
      x2 = x1 + this.visual_settings.get('horizontalScale');
      line = this.two.makeLine(x1, 0, x2, 0);
      line.stroke = '#ff0000';
      line.linewidth = this.visual_settings.get('lineFatness');
      line.addTo(this.group);
      return this._updateVertices();
    };

    GraphLine.prototype._growNewState = function(newState) {
      var prevState;
      prevState = this.game_states.at(this.options.game_states.length - 2);
      return this._initState(prevState, newState, this.game_states.length - 1);
    };

    GraphLine.prototype.yForScore = function(score, range) {
      return this.visual_settings.scoreToScreenFactor(range) * score;
    };

    GraphLine.prototype._linesPolygons = function() {
      return _.map(this.group.children, function(poly, key, obj) {
        return poly;
      });
    };

    GraphLine.prototype._verticesByStateIndex = function(idx) {
      var p, vertices;
      vertices = [];
      if (p = this._linesPolygons()[idx]) {
        vertices.push(p.vertices[0]);
      }
      if (p = this._linesPolygons()[idx - 1]) {
        if (p.vertices[1]) {
          vertices.push(p.vertices[1]);
        }
      }
      return vertices;
    };

    GraphLine.prototype._updateVertices = function() {
      var _this = this;
      return this.game_states.each(function(state, idx) {
        var skill;
        if (skill = _this._skillFromState(state)) {
          return _.each(_this._verticesByStateIndex(idx), function(vertice) {
            return vertice.y = _this.yForScore(skill.get('score'));
          });
        }
      });
    };

    return GraphLine;

  })(Backbone.Model);

  GraphLines = (function(_super) {
    __extends(GraphLines, _super);

    function GraphLines(_opts) {
      this.options = _opts;
      this.two = _opts.two;
      this.game_states = _opts.game_states;
      this.visual_settings = _opts.visual_settings;
      this.group = this.two.makeGroup();
      this.group.translation.set(0, this.visual_settings.get('verticalBase'));
      this._initScene();
    }

    GraphLines.prototype._group = function() {
      return this.group;
    };

    GraphLines.prototype._initScene = function() {
      var _this = this;
      if (this.game_states && this.game_states.first()) {
        return this.graph_lines = this.game_states.first().get('skills').map(function(skill) {
          var gl;
          gl = new GraphLine({
            two: _this.two,
            game_states: _this.game_states,
            visual_settings: _this.visual_settings,
            skill: skill
          });
          gl.group.addTo(_this.group);
          return gl;
        });
      }
    };

    return GraphLines;

  })(Backbone.Model);

  GraphLinesOps = (function() {
    function GraphLinesOps(_opts) {
      var _this = this;
      this.options = _opts || {};
      this.target = _opts.target || _opts.graph_lines;
      this.two = this.target.two;
      this.target._group().translation.set(0, this.target.visual_settings.desiredBaseline());
      this.target.visual_settings.on('change:scoreRange', function(model, val, obj) {
        return _this.rangeShiftTween(model.previous('scoreRange'), val).start();
      });
    }

    GraphLinesOps.prototype.scrollTween = function() {
      var tween;
      return tween = new TWEEN.Tween(this.target._group().translation).to({
        x: this.target._group().translation.x - this.target.visual_settings.get('horizontalScale')
      }, 500).easing(TWEEN.Easing.Exponential.InOut);
    };

    GraphLinesOps.prototype.baselineShiftTween = function(toY) {
      var tween;
      return tween = new TWEEN.Tween(this.target._group().translation).to({
        y: toY
      }, 500).easing(TWEEN.Easing.Exponential.InOut);
    };

    GraphLinesOps.prototype.rangeShiftTween = function(from, to) {
      var that, tween;
      from = this.target.visual_settings.get('animationRange');
      that = this;
      return tween = new TWEEN.Tween({
        range: from
      }).to({
        range: to
      }, 500).easing(TWEEN.Easing.Exponential.InOut).onUpdate(function(progress) {
        return that.target.visual_settings.set({
          animationRange: this.range
        });
      });
    };

    GraphLinesOps.prototype.shrinkTween = function() {
      var toLineWidth, toScale, tween;
      toScale = this._shrinkScale();
      toLineWidth = this.target.visual_settings.get('lineFatness') / toScale;
      return tween = new TWEEN.Tween(this.target._group()).to({
        scale: toScale,
        linewidth: toLineWidth
      }, 500).easing(TWEEN.Easing.Exponential.InOut);
    };

    GraphLinesOps.prototype._shrinkScale = function() {
      var bound, scale;
      bound = this.target._group().getBoundingClientRect();
      return scale = 1 / ((bound.width / this.target._group().scale) / this.two.width);
    };

    return GraphLinesOps;

  })();

  VisualSettings = (function(_super) {
    __extends(VisualSettings, _super);

    function VisualSettings() {
      _ref = VisualSettings.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    VisualSettings.prototype.defaults = {
      horizontalScale: 100,
      verticalBase: 0,
      lineFatness: 3,
      originalScoreRange: 15,
      scoreRange: 15,
      verticalScaler: 1,
      animationRange: 15
    };

    VisualSettings.prototype.initialize = function() {
      this.calculate();
      if (this.get('game_states')) {
        return this.get('game_states').on('add', this.calculate, this);
      }
    };

    VisualSettings.prototype.calculate = function() {
      return this.set({
        verticalBase: this.desiredBaseline(),
        scoreRange: this.deltaScore()
      });
    };

    VisualSettings.prototype._allScores = function() {
      return _.flatten((this.get('game_states') || new Backbone.Collection()).map(function(state) {
        return state.get('skills').map(function(skill) {
          return skill.get('score');
        });
      }));
    };

    VisualSettings.prototype.maxScore = function() {
      return _.max(this._allScores());
    };

    VisualSettings.prototype.minScore = function() {
      return _.min(this._allScores());
    };

    VisualSettings.prototype.avgScore = function() {
      return this.minScore() + this.deltaScore() / 2;
    };

    VisualSettings.prototype.deltaScore = function() {
      return this.maxScore() - this.minScore();
    };

    VisualSettings.prototype.scoreToScreenFactor = function(range) {
      if (range === void 0) {
        range = this.get('animationRange');
      }
      if (range === 0) {
        return 100;
      }
      return (this.get('two').height) / -range;
    };

    VisualSettings.prototype.desiredBaseline = function() {
      if (this.deltaScore() === 0) {
        return this.get('two').height / 2;
      }
      return this.get('two').height / 2 - this.avgScore() * this.scoreToScreenFactor();
    };

    return VisualSettings;

  })(Backbone.Model);

}).call(this);
