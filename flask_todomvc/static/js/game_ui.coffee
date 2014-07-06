class @GameUi extends Backbone.Model
  constructor: (_opts) ->
    @options = _opts || {}

    $(window).on('keydown', @_keyDown).mousemove(@_mouseMove)

  _keyDown: (e) =>
    # console.log('keydown event:')
    # console.log(e)

    return if (e.metaKey || e.ctrlKey)
    e.preventDefault()

    #do something if e.keyCode == 32 # SPACE

    @trigger 'answer-no', e if e.keyCode == 78 # 'n'
    @trigger 'answer-yes', e if e.keyCode == 89 # 'y'
    @trigger 'answer-yes', e if e.keyCode == 37 # LEFT
    @trigger 'answer-no', e if e.keyCode == 39 # RIGHT
    @trigger 'toggle-stats', e if e.keyCode == 9 # TAB 

