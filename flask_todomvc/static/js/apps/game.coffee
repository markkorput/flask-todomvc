class Game extends Backbone.Model
  defaults: { created_at: new Date() }

class GameList extends Backbone.Collection
  model: Game
  localStorage: new Backbone.LocalStorage("todos-backbone")
  constructor: (_opts) ->
    super()


class GameListView extends Backbone.View
  tagName: "ul"
  className: "games-list"

  initialize: ->
    @games = new GameList;
    @games.fetch();

  render: ->
    @$el.html '<h1>Games</h1>'
    @games.each (game) => 
      @$el.append('<li>Creation Date: '+game.get('created_at')+'</li>')

    this



class @GameView extends Backbone.View
  initialize: ->
    @games = new GameList;
    @games.fetch();
    @games.create({}) if @games.length < 1
    @game = @games.last()
    console.log @game
    @render()

  render: ->
    @$el.html ''
    @$el.append(new GameListView().render().el)

