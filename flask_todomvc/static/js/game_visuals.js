// Generated by CoffeeScript 1.6.3
(function() {
  var GraphLines, GraphLinesOps, VisualSettings, VisualState, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  this.GameVisuals = (function() {
    function GameVisuals(_opts) {
      this.options = _opts;
      this.two = new Two({
        autostart: true,
        fullscreen: false,
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

  GraphLines = (function(_super) {
    __extends(GraphLines, _super);

    function GraphLines(_opts) {
      this.options = _opts;
      this.two = _opts.two;
      this.game_states = _opts.game_states;
      this.visual_settings = _opts.visual_settings;
      this._initScene();
      this.game_states.on('add', this._growNewState, this);
    }

    GraphLines.prototype._group = function() {
      if (this.group) {
        return this.group;
      }
      this.group = this.two.makeGroup();
      this.group.translation.set(0, this.visual_settings.get('verticalBase'));
      return this.group;
    };

    GraphLines.prototype._skillLine = function(skill) {
      this._skillLines || (this._skillLines = {});
      if (this._skillLines[skill.get('text')]) {
        return this._skillLines[skill.get('text')];
      }
      return this._setSkillLinePoints(skill, []);
    };

    GraphLines.prototype._setSkillLinePoints = function(skill, points) {
      var poly;
      poly = new Two.Polygon(points, true, false);
      if (this._skillLines[skill.get('text')]) {
        this._group().remove(this._skillLines[skill.get('text')]);
      }
      this._skillLines[skill.get('text')] = poly;
      poly.addTo(this._group());
      poly.fill = '#FF0000';
      poly.noStroke();
      return poly;
    };

    GraphLines.prototype._initScene = function() {
      var _this = this;
      return _.each(_.range(1, this.game_states.length - 1), function(i) {
        return _this._initState(_this.game_states.at(i - 1), _this.game_states.at(i), i);
      });
    };

    GraphLines.prototype._initState = function(prevState, state, idx) {
      var _this = this;
      return state.get('skills').each(function(skill) {
        var prevSkill;
        prevSkill = prevState.get('skills').find(function(pSkill) {
          return pSkill.get('text') === skill.get('text');
        });
        return _this.addLine(prevSkill, skill, idx);
      });
    };

    GraphLines.prototype.addLine = function(prevSkill, skill, index) {
      var line, x1, x2, y1, y2;
      x1 = (index - 1) * this.visual_settings.get('horizontalScale');
      y1 = this.visual_settings.get('verticalScale') * prevSkill.get('score');
      x2 = x1 + this.visual_settings.get('horizontalScale');
      y2 = this.visual_settings.get('verticalScale') * skill.get('score');
      line = this.two.makeLine(x1, y1, x2, y2);
      line.stroke = '#ff0000';
      line.linewidth = this.visual_settings.get('lineFatness');
      return line.addTo(this._group());
    };

    GraphLines.prototype.growLine = function(skill) {
      var line, point1, point2, second_half, vertices, x, y;
      line = this._skillLine(skill);
      vertices = line.vertices || [];
      x = vertices.length / 2 * this.two.width;
      y = this.visual_settings.get('verticalScale') * skill.get('score');
      point1 = new Two.Anchor(x, y + this.visual_settings.get('lineFatness') / 2);
      point2 = new Two.Anchor(x, y - this.visual_settings.get('lineFatness') / 2);
      if (vertices.length > 0) {
        second_half = _.map(_.range(vertices.length / 2, vertices.length / 2 - 1), function(i) {
          return vertices[i];
        });
        vertices = _.map(_.range(vertices.length / 2), function(i) {
          return vertices[i];
        });
        $.merge(vertices, $.merge([point1, point2], second_half));
      } else {
        vertices = [point1, point2];
      }
      return this._setSkillLinePoints(skill, vertices);
    };

    GraphLines.prototype._growNewState = function(newState) {
      var prevState;
      prevState = this.options.game_states.at(this.options.game_states.length - 2);
      this._initState(prevState, newState, this.game_states.length - 1);
      return this.trigger('new-state', newState);
    };

    return GraphLines;

  })(Backbone.Model);

  GraphLinesOps = (function() {
    function GraphLinesOps(_opts) {
      var _this = this;
      this.options = _opts || {};
      this.target = _opts.target || _opts.graph_lines;
      this.two = this.target.two;
      console.log(this.target.visual_settings.desiredBaseline());
      this.target._group().translation.set(this.two.width, this.target.visual_settings.desiredBaseline());
      this.target.on('new-state', (function() {
        return this.scrollTween().start();
      }), this);
      this.target.visual_settings.on('change:verticalBase', function(model, val, obj) {
        return _this.baselineShiftTween(model.desiredBaseline()).start();
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

  VisualState = (function() {
    function VisualState(_state, _opts) {
      this.state = _state;
      this.options = _opts || {};
    }

    return VisualState;

  })();

  VisualSettings = (function(_super) {
    __extends(VisualSettings, _super);

    function VisualSettings() {
      _ref = VisualSettings.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    VisualSettings.prototype.defaults = {
      verticalScale: 100,
      horizontalScale: 300,
      verticalBase: 0,
      lineFatness: 3
    };

    VisualSettings.prototype.initialize = function() {
      this.calculate();
      if (this.get('game_states')) {
        return this.get('game_states').on('add', this.calculate, this);
      }
    };

    VisualSettings.prototype.calculate = function() {
      return this.set({
        verticalBase: this.desiredBaseline()
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

    VisualSettings.prototype.deltaScore = function() {
      return this.maxScore() - this.minScore();
    };

    VisualSettings.prototype.desiredBaseline = function() {
      if (this.deltaScore() === 0) {
        return this.get('two').height / 2;
      }
      return this.maxScore() - this.maxScore() * this.get('two').height / this.deltaScore();
    };

    return VisualSettings;

  })(Backbone.Model);

}).call(this);
