class @GameVisuals
  constructor: (_opts) ->
    @options = _opts
    @two = new Two({autostart: true, fullscreen: false, type: Two.Types.svg}).appendTo(document.body)
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


class GraphLines extends Backbone.Model
  constructor: (_opts) ->
    @options = _opts
    @two = _opts.two
    @game_states = _opts.game_states
    @visual_settings = _opts.visual_settings

    @_initScene()

    # event hooks
    @game_states.on 'add', @_growNewState, this

  _group: ->
    return @group if @group
    @group = @two.makeGroup()
    @group.translation.set(0, @visual_settings.get('verticalBase'))
    return @group

  _skillLine: (skill) ->
    @_skillLines ||= {}
    return @_skillLines[skill.get('text')] if @_skillLines[skill.get('text')] 

    # initialize polygon
    @_setSkillLinePoints(skill, [])

  _setSkillLinePoints: (skill, points) ->
    poly = new Two.Polygon(points, true, false)
    @_group().remove(@_skillLines[skill.get('text')]) if @_skillLines[skill.get('text')]
    @_skillLines[skill.get('text')] = poly
    poly.addTo @_group()
    poly.fill = '#FF0000'
    poly.noStroke()
    return poly

  _initScene: ->
    _.each _.range(1, @game_states.length - 1), (i) =>
      @_initState(@game_states.at(i-1), @game_states.at(i), i)

  _initState: (prevState, state, idx) ->
    state.get('skills').each (skill) =>
        prevSkill = prevState.get('skills').find (pSkill) -> pSkill.get('text') == skill.get('text')
        @addLine(prevSkill, skill, idx)
    
    # @game_states.each (state) =>
    #   state.get('skills').each (skill) =>
    #     @growLine(skill, state)

  addLine: (prevSkill, skill, index) ->
    x1 = (index - 1) * @visual_settings.get('horizontalScale')
    y1 = @visual_settings.get('verticalScale') * prevSkill.get('score')
    x2 = x1 + @visual_settings.get('horizontalScale')
    y2 = @visual_settings.get('verticalScale') * skill.get('score')
    line = @two.makeLine(x1, y1, x2, y2)
    line.stroke = '#ff0000'
    line.linewidth = @visual_settings.get('lineFatness')
    line.addTo @_group()

  growLine: (skill) ->
    # console.log 'Growing line for: '+skill.get('text')
    line = @_skillLine(skill)
    vertices = line.vertices || []

    x = vertices.length / 2 * @two.width
    y = @visual_settings.get('verticalScale') * skill.get('score')
    point1 = new Two.Anchor(x, y+@visual_settings.get('lineFatness')/2)
    point2 = new Two.Anchor(x, y-@visual_settings.get('lineFatness')/2)

    if vertices.length > 0
      second_half = _.map _.range(vertices.length/2, vertices.length/2-1), (i) -> vertices[i]
      vertices = _.map _.range(vertices.length/2), (i) -> vertices[i]
      # last_vertice = vertices.pop()
      $.merge(vertices, $.merge([point1, point2], second_half))
    else
      vertices = [point1, point2]

    @_setSkillLinePoints(skill, vertices)

  _growNewState: (newState) ->
    prevState = @options.game_states.at @options.game_states.length - 2
    @_initState(prevState, newState, @game_states.length-1)
    @trigger 'new-state', newState   

    

class GraphLinesOps
  constructor: (_opts) ->
    @options = _opts || {}
    @target = _opts.target || _opts.graph_lines
    @two = @target.two

    # start by moving the whole group to the right edge of the screen, making it look the lines scroll into view
    console.log @target.visual_settings.desiredBaseline()
    @target._group().translation.set(@two.width, @target.visual_settings.desiredBaseline())

    # event hooks
    # @target.on 'new-state', (-> @shrinkTween().start()), this
    @target.on 'new-state', (-> @scrollTween().start()), this
    @target.visual_settings.on 'change:verticalBase', (model,val,obj) =>
      # console.log 'baseline shift to: ' + model.desiredBaseline()
      @baselineShiftTween(model.desiredBaseline()).start()

  scrollTween: ->
    tween = new TWEEN.Tween( @target._group().translation )
      .to({x: @target._group().translation.x - @target.visual_settings.get('horizontalScale')}, 500)
      .easing( TWEEN.Easing.Exponential.InOut )

  baselineShiftTween: (toY) ->
    tween = new TWEEN.Tween( @target._group().translation )
      .to({y: toY}, 500)
      .easing( TWEEN.Easing.Exponential.InOut )

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
class VisualState
  constructor: (_state, _opts) ->
    @state = _state # this attribute is required
    @options = _opts || {}
    

class VisualSettings extends Backbone.Model
  defaults:
    verticalScale: 100
    horizontalScale: 300
    verticalBase: 0
    lineFatness: 3

  initialize: ->
    @calculate()
    @get('game_states').on 'add', @calculate, this if @get('game_states')

  calculate: ->
    # set baseline in the (vertical) middle of the screen
    # @set(verticalBase: @get('two').height/2) if @get('two')
    @set(verticalBase: @desiredBaseline())

  _allScores: ->
    _.flatten (@get('game_states') || new Backbone.Collection()).map (state) ->
      state.get('skills').map (skill) ->
        skill.get('score')

  maxScore: -> _.max @_allScores()
  minScore: -> _.min @_allScores()
  deltaScore: -> @maxScore() - @minScore()
  desiredBaseline: ->
    return @get('two').height/2 if @deltaScore() == 0
    @maxScore() - @maxScore() * @get('two').height / @deltaScore()


      


