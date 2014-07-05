// Generated by CoffeeScript 1.6.3
(function() {
  this.GameVisuals = (function() {
    function GameVisuals(_opts) {
      this.options = _opts;
      this.two = new Two({
        autostart: true,
        fullscreen: false,
        type: Two.Types.svg
      }).appendTo(document.body);
      $(window).on('resize', this._resize);
      this._initScene();
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
      bg.fill = '#000000';
      bg.noStroke();
      return this.two.add(bg);
    };

    return GameVisuals;

  })();

}).call(this);
