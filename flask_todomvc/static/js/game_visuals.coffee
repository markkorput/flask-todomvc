class @GameVisuals
  constructor: (_opts) ->
    @options = _opts
    @two = new Two({autostart: true, fullscreen: false, type: Two.Types.svg}).appendTo(document.body)
    $(window).on('resize', @_resize)

    @visual_settings = new VisualSettings(two: @two)

    # create visual elements
    @_initScene()

    # setup event hooks
    @options.game_states.on 'add', @_transitionToState, this if @options.game_states

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

  previousState: ->
    @options.game_states.at @options.game_states.length - 2

  _transitionToState: (newState) ->
    # console.log 'new state'
    # console.log newState
    # console.log @previousState()


class GraphLines
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
    @game_states.each (state) =>
      state.get('skills').each (skill) =>
        @growLine(skill, state)

  growLine: (skill) ->
    # console.log 'Growing line for: '+skill.get('text')
    line = @_skillLine(skill)
    vertices = line.vertices || []

    x = vertices.length / 2 * @two.width
    y = @visual_settings.get('verticalScale') * skill.get('score')
    point1 = new Two.Anchor(x, y+@visual_settings.get('lineFatness')/2)
    point2 = new Two.Anchor(x, y-@visual_settings.get('lineFatness')/2)

    if vertices.length > 0
      last_vertice = vertices.pop()
      $.merge(vertices, [point1, point2, last_vertice])
    else
      vertices = [point1, point2]

    @_setSkillLinePoints(skill, vertices)

  _growNewState: (newState) ->
    # console.log 'Growing new state'
    newState.get('skills').each (skill) => @growLine(skill)


# helper class to perform calculations based in a specific state
class VisualState
  constructor: (_state, _opts) ->
    @state = _state # this attribute is required
    @options = _opts || {}
    

class VisualSettings extends Backbone.Model
  defaults:
    verticalScale: 10
    verticalBase: 0
    lineFatness: 3

  initialize: ->
    # set baseline in the (vertical) middle of the screen
    @set(verticalBase: @get('two').height/2) if @get('two')
