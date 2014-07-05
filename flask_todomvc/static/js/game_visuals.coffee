class @GameVisuals
  constructor: (_opts) ->
    @options = _opts
    @two = new Two({autostart: true, fullscreen: true, type: Two.Types.svg}).appendTo(document.body)
    $(window).on('resize', @_resize)

    @visual_settings = new VisualSettings(two: @two, game_states: @options.game_states)

    # create visual elements
    @_initScene()

    # setup event hooks
    @two.bind 'update', -> TWEEN.update()

  _resize: ->
    return if !@two
    @two.renderer.setSize $(window).width(), $(window).height()
    @two.width = @two.renderer.width
    @two.height = @two.renderer.height

  _initScene: ->
    # bg
    bg = @two.makeRectangle(@two.width/2,@two.height/2, @two.width, @two.height)
    bg.fill = '#92adac'
    bg.noStroke()
    @two.add(bg)

    # graph lines are wrapped in a separate class
    @graph_lines = new GraphLines(two : @two, game_states: @options.game_states, visual_settings: @visual_settings)
    @graph_lines_ops = new GraphLinesOps(target: @graph_lines)

  previousState: ->
    @options.game_states.at @options.game_states.length - 2


class GraphLine extends Backbone.Model
  constructor: (_opts) ->
    @options = _opts
    @two = _opts.two
    @game_states = _opts.game_states
    @visual_settings = _opts.visual_settings
    @skill = _opts.skill

    @group = @two.makeGroup()
    @group.translation.set(0, 0)

    @_initPolygons()

    # event hooks
    @game_states.on 'add', @_growNewState, this

  _initPolygons: ->
    _.each _.range(1, @game_states.length - 1), (i) =>
      @_initState(@game_states.at(i-1), @game_states.at(i), i)

  _initState: (prevState, state, idx) ->
    skill = state.get('skills').find (_skill) => _skill.get('text') == @skill.get('text')
    prevSkill = prevState.get('skills').find (_skill) => _skill.get('text') == @skill.get('text')
    @_addLine(prevSkill, skill, idx) if skill && prevSkill
    
  _addLine: (prevSkill, skill, index) ->
    x1 = (index - 1) * @visual_settings.get('horizontalScale')
    y1 = @yForScore prevSkill.get('score')
    x2 = x1 + @visual_settings.get('horizontalScale')
    y2 = @yForScore skill.get('score')
    line = @two.makeLine(x1, y1, x2, y2)
    line.stroke = '#ff0000'
    line.linewidth = @visual_settings.get('lineFatness')
    line.addTo @group

  _growNewState: (newState) ->
    prevState = @game_states.at @options.game_states.length - 2
    @_initState(prevState, newState, @game_states.length-1)

  yForScore: (score) ->
    # -y * @get('two').height / @get('scoreRange')
    @visual_settings.scoreToScreenFactor() * score * @visual_settings.get('verticalScaler')


class GraphLines extends Backbone.Model
  constructor: (_opts) ->
    @options = _opts
    @two = _opts.two
    @game_states = _opts.game_states
    @visual_settings = _opts.visual_settings

    @group = @two.makeGroup()
    @group.translation.set(0, @visual_settings.get('verticalBase'))

    @_initScene()

  _group: -> @group

  _initScene: ->
    if @game_states && @game_states.first()
      @graph_lines = @game_states.first().get('skills').map (skill) =>
        gl = new GraphLine(two: @two, game_states: @game_states, visual_settings: @visual_settings, skill: skill)
        gl.group.addTo @group
        return gl

class GraphLinesOps
  constructor: (_opts) ->
    @options = _opts || {}
    @target = _opts.target || _opts.graph_lines
    @two = @target.two

    # start by moving the whole group to the right edge of the screen, making it look the lines scroll into view
    # console.log @target.visual_settings.desiredBaseline()
    @target._group().translation.set(@two.width, @target.visual_settings.desiredBaseline())
    # @target._group().scale = 0.3

    # event hooks
    # @target.on 'new-state', (-> @shrinkTween().start()), this

    @target.game_states.on 'add', =>
      # console.log 'Scroll Tween'
      @scrollTween().start()

    @target.visual_settings.on 'change:verticalBase', (model,val,obj) =>
      # console.log 'baseline shift to: ' + model.desiredBaseline()
      @baselineShiftTween(model.desiredBaseline()).start()

    @target.visual_settings.on 'change:scoreRange', (model,val,obj) =>
      # console.log 'range shift to: ' + model.minScore() + ', '+ model.maxScore()
      @rangeShiftTween(model.previous('scoreRange'), val).start()


  scrollTween: ->
    tween = new TWEEN.Tween( @target._group().translation )
      .to({x: @target._group().translation.x - @target.visual_settings.get('horizontalScale')}, 500)
      .easing( TWEEN.Easing.Exponential.InOut )

  baselineShiftTween: (toY) ->
    tween = new TWEEN.Tween( @target._group().translation )
      .to({y: toY}, 500)
      .easing( TWEEN.Easing.Exponential.InOut )

  rangeShiftTween: (from, to) ->
    scaleFactor = from / to
    console.log 'rangeShiftTween: '+scaleFactor
    # console.log from
    # console.log to

    tween = new TWEEN.Tween( {y: 0} )
      .to({y: 1}, 500)
      .easing( TWEEN.Easing.Exponential.InOut )
      .onStart =>
        _.each @target._group().children, (polygon,nr) ->
          _.each polygon.vertices, (vertice) ->
            new TWEEN.Tween(vertice)
              .to({y: vertice.y * scaleFactor})
              .easing( TWEEN.Easing.Exponential.InOut )
              .start()


  shrinkTween: ->
    toScale = @_shrinkScale()
    toLineWidth = @target.visual_settings.get('lineFatness') / toScale

    tween = new TWEEN.Tween( @target._group() )
      .to({scale: toScale, linewidth: toLineWidth}, 500)
      .easing( TWEEN.Easing.Exponential.InOut )

  _shrinkScale: ->
    bound = @target._group().getBoundingClientRect()
    scale = 1 / ((bound.width / @target._group().scale) / @two.width)






# helper class to perform calculations based in a specific state
class VisualSettings extends Backbone.Model
  defaults:
    horizontalScale: 300
    verticalBase: 0
    lineFatness: 3
    scoreRange: 5
    verticalScaler: 1

  initialize: ->
    @calculate()
    @get('game_states').on 'add', @calculate, this if @get('game_states')

  calculate: ->
    # set baseline in the (vertical) middle of the screen
    # @set(verticalBase: @get('two').height/2) if @get('two')
    @set {
      verticalBase: @desiredBaseline()
      # scoreRange: @deltaScore()
    }

  _allScores: ->
    _.flatten (@get('game_states') || new Backbone.Collection()).map (state) ->
      state.get('skills').map (skill) ->
        skill.get('score')

  maxScore: -> _.max @_allScores()
  minScore: -> _.min @_allScores()
  avgScore: -> @minScore() + @deltaScore()/2
  deltaScore: -> @maxScore() - @minScore()
  scoreToScreenFactor: ->
    return 1 if @get('scoreRange') == 0
    @get('two').height / -@get('scoreRange')

  desiredBaseline: ->
    return @get('two').height/2 if @deltaScore() == 0
    return @get('two').height/2 - @avgScore()*@scoreToScreenFactor()

    


      


