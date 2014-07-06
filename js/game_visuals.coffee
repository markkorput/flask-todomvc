class @GameVisuals extends Backbone.Model
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

  showQuestion: (question) ->
    @questionVisual.remove() if @questionVisual

    # create and add element to page
    @questionVisual = new QuestionVisual()
    $('body').append @questionVisual.el

    # let question appear
    @questionVisual.appear(question)

    # event hooks
    @questionVisual.on 'answer-yes', => @trigger 'answer-yes'
    @questionVisual.on 'answer-no', => @trigger 'answer-no'

  answerYesTween: -> @questionVisual.leftTween()
  answerNoTween: -> @questionVisual.rightTween()

# the QuestionVisual class represents the "question" foreground elements
class QuestionVisual extends Backbone.View
  tagName: 'div'
  className: 'game-question'

  events:
    'click .yes': 'clickYes'
    'click .no': 'clickNo'

  initialize: ->
    # create question span
    @$el.append $('<span class="question"></span>')

    # create buttons
    @$el.append $('<span class="yes button">&larr; &nbsp; &nbsp; Yes</span>')
    @$el.append $('<span class="no button">No &nbsp; &nbsp; &rarr;</span>')

    # start out of screen
    @moveTo @topPosition()

  clickYes: -> @trigger 'answer-yes'
  clickNo: -> @trigger 'answer-no'

  appear: (question) ->
    # we'll be dropping down
    @moveTo @topPosition()

    # set question text
    @$el.find('span.question').html(question.get('text'))

    @tween(@topPosition(), @centerPosition()).start() #.onComplete(=> @disappearTween().delay(1000).start())

  moveTo: (pos) -> @$el.css('margin-left', pos.x); @$el.css('margin-top', pos.y);
  centerPosition: -> {x: $(window).width()/2 - @$el.width()/2, y: $(window).height()/2 - @$el.height()/2}
  rightPosition: -> {x: $(window).width() + 10, y: @centerPosition().y}
  leftPosition: -> {x: -@$el.width() - 10, y: @centerPosition().y}
  topPosition: -> {x: @centerPosition().x, y: -@$el.height() - 10}
  currentPosition: -> {x: @$el.css('margin-left').replace(/px$/, ''), y: @$el.css('margin-top').replace(/px$/, '')}

  leftTween: -> @tween @currentPosition(), @leftPosition()
  rightTween: -> @tween @currentPosition(), @rightPosition()

  tween: (from, to) ->
    # save our context for the onUpdate callback
    that = this
    tween = new TWEEN.Tween(from)
      .to(to, 500)
      .easing( TWEEN.Easing.Exponential.InOut )
      .onUpdate (progress) -> that.moveTo this


# the GraphLine class represent a single line in the graph
class GraphLine extends Backbone.Model
  constructor: (_opts) ->
    @options = _opts
    @two = _opts.two
    @game_states = _opts.game_states
    @visual_settings = _opts.visual_settings
    @skill = _opts.skill

    @clr = _.sample [
      '#0e2a99'
      '#1f79aa'
      '#9edbfc'
      '#fffeff'
      '#f33060'
      '#d8245b'
    ]

    @group = @two.makeGroup()
    @group.translation.set(0, 0)

    @_initPolygons()

    # event hooks
    @game_states.on 'add', @_growNewState, this
    @visual_settings.on 'change:animationRange', @_updateVertices, this

  _initPolygons: ->
    _.each _.range(1, @game_states.length - 1), (i) =>
      @_initState(@game_states.at(i-1), @game_states.at(i), i)

  _initState: (prevState, state, idx) ->
    skill = @_skillFromState(state)
    prevSkill = @_skillFromState(prevState)
    @_addLine(prevSkill, skill, idx) if skill && prevSkill
  
  _skillFromState: (state) -> state.get('skills').find (_skill) => _skill.get('text') == @skill.get('text')

  _addLine: (prevSkill, skill, index) ->
    x1 = (index - 1) * @visual_settings.get('horizontalScale')
    # y1 = @yForScore prevSkill.get('score')
    x2 = x1 + @visual_settings.get('horizontalScale')
    # y2 = @yForScore skill.get('score')
    line = @two.makeLine(x1, 0, x2, 0)
    line.stroke = @clr
    line.linewidth = @visual_settings.get('lineFatness')
    line.addTo @group
    @_updateVertices()

  _growNewState: (newState) ->
    # console.log "new score: "+@_skillFromState(newState).get('score')
    prevState = @game_states.at @options.game_states.length - 2
    @_initState(prevState, newState, @game_states.length-1)

  yForScore: (score, range) ->
    @visual_settings.scoreToScreenFactor(range) * score

  _linesPolygons: -> _.map @group.children, (poly,key,obj) -> poly

  _verticesByStateIndex: (idx) ->
    vertices = []
    if p = @_linesPolygons()[idx]
      vertices.push p.vertices[0]
    if p = @_linesPolygons()[idx-1] 
      if p.vertices[1]
        vertices.push p.vertices[1]
    return vertices

  _updateVertices: ->
    @game_states.each (state, idx) =>
      if skill = @_skillFromState(state)
        _.each @_verticesByStateIndex(idx), (vertice) =>
          vertice.y = @yForScore(skill.get('score'))


# the GaphLines class represent a collection of lines in the graph
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


# the GraphLinesOps class represents operations (animations) performed on the visual graph elements (lines)
class GraphLinesOps
  constructor: (_opts) ->
    @options = _opts || {}
    @target = _opts.target || _opts.graph_lines
    @two = @target.two

    # start by moving the whole group to the right edge of the screen, making it look the lines scroll into view
    @target._group().translation.set(@two.width, @target.visual_settings.desiredBaseline())

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
    from = @target.visual_settings.get('animationRange')
    that = this
    tween = new TWEEN.Tween({range: from})
      .to({range: to}, 500)
      .easing( TWEEN.Easing.Exponential.InOut )
      .onUpdate (progress) ->
        that.target.visual_settings.set({animationRange: this.range})


# VisualSettings is a helper class to perform calculations
class VisualSettings extends Backbone.Model
  defaults:
    horizontalScale: 300
    verticalBase: 0
    lineFatness: 3
    originalScoreRange: 15
    scoreRange: 15
    verticalScaler: 1
    animationRange: 15

  initialize: ->
    @calculate()
    @get('game_states').on 'add', @calculate, this if @get('game_states')

  calculate: ->
    # set baseline in the (vertical) middle of the screen
    # @set(verticalBase: @get('two').height/2) if @get('two')
    @set {
      horizontalScale: @get('two').width/4
      verticalBase: @desiredBaseline()
      scoreRange: @deltaScore()
    }

  _allScores: ->
    _.flatten (@get('game_states') || new Backbone.Collection()).map (state) ->
      state.get('skills').map (skill) ->
        skill.get('score')

  maxScore: -> _.max @_allScores()
  minScore: -> _.min @_allScores()
  avgScore: -> @minScore() + @deltaScore()/2
  deltaScore: -> @maxScore() - @minScore()

  scoreToScreenFactor: (range) ->
    range = @get('animationRange') if range == undefined
    return 100 if range == 0
    (@get('two').height) / -range

  desiredBaseline: ->
    return @get('two').height/2 if @deltaScore() == 0
    return @get('two').height/2 - @avgScore()*@scoreToScreenFactor()

    


      


