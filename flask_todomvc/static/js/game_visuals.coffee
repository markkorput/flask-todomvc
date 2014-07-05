class @GameVisuals
  constructor: (_opts) ->
    @options = _opts
    @two = new Two({autostart: true, fullscreen: false, type: Two.Types.svg}).appendTo(document.body)
    $(window).on('resize', @_resize)

    @_initScene()

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

  previousState: ->
    @options.game_states.at @options.game_states.length - 2

  _transitionToState: (newState) ->
    console.log 'new state'
    console.log newState
    console.log @previousState()

