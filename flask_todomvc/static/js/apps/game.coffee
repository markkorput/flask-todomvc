#
# GameBoardView
#
class @GameView extends Backbone.View
  initialize: ->
    @admin_view = new AdminView()

    games = new GameList;
    games.fetch();
    games.create({}) if games.length < 1
    @game = games.last()
    @render()

    @on 'answer', @submitAnswer
    @game.on 'change', @renderGame, this
    @game.user.on 'change', @renderScores, this
    @game.user.skills.on 'change', @renderScores, this

  render: ->
    @$el.html '<h1>Next Question</h1><div id="current-question"></div><h1>Game Stats</h1><ul id="game-stats"></ul><hr/>'
    @$el.append @admin_view.render().el
    
    @renderGame()
    @renderScores()
    this

  game_el: -> @$el.find('#current-question')
  stats_el: -> @$el.find('#game-stats')

  renderGame: ->
    @game_el().html ''

    if q = @game.current_question()
      @game_el().append('<h2>'+q.get('text')+'</h2>')
      _.each q.get('answers'), (answer) =>
        button = $('<button>'+answer.get('text')+'</button>')
        button.on 'click', (event) =>
          @trigger('answer', answer)

        @game_el().append(button)


  renderScores: ->
    @stats_el().html ''

    if user = @game.user
      @stats_el().append('<li>User: '+user.get('name')+'</li>') 

      skills_el = $('<ul></ul>')
      user.skills.each (skill) -> skills_el.append('<li>'+skill.get('text')+': '+skill.get('score')+'</li>')
      skills_line = $('<li></li>')
      skills_line.append(skills_el)
      @stats_el().append(skills_line)


  submitAnswer: (answer) ->
    # apply the answer's manipulation values to the current user's skills
    _.each answer.get('manipulations'), (val, key, obj) =>
      if skill = @game.user.skills.findWhere(text: key)
        skill.set(score: skill.get('score') + val)

    # on to the net question
    @game.nextQuestion()

#
# Question
#
class Answer extends Backbone.Model
  defaults:
    text: 'Yes'
    manipulations:
      'income tax': 0
      'education level': 0
      'public health': 0
      'entrepreneurship': 0
      'community art': 0
      'immigration': 0


class @Question extends Backbone.Model
  defaults:
    text: 'Question Text'
    answers: [
      new Answer()
      new Answer(text: 'No')
    ]

class @QuestionList extends Backbone.Collection
  model: Question
  localStorage: new Backbone.LocalStorage("todos-backbone")

class QuestionListView extends Backbone.View
  tagName: "ul"
  className: "questions-list"

  initialize: ->
    @questions = new QuestionList;
    @questions.fetch();

  render: ->
    @$el.html '<h1>Questions</h1>'
    @questions.each (question) => 
      answers = _.map(question.get('answers') || [], (answer) -> answer.get('text'))
      @$el.append('<li>'+question.get('text')+' ('+answers.join(', ')+')</li>')
    this

#
# User
#

class User extends Backbone.Model
  defaults:
    name: 'John Doe'

  initialize: ->
    @skills = new Backbone.Collection([
      {text: 'income tax', score: 0}
      {text: 'education level', score: 0}
      {text: 'public health', score: 0}
      {text: 'entrepreneurship', score: 0}
      {text: 'community art', score: 0}
      {text: 'immigration', score: 0}
    ])

class @UserList extends Backbone.Collection
  model: User
  localStorage: new Backbone.LocalStorage("todos-backbone")

class UserListView extends Backbone.View
  tagName: "ul"
  className: "users-list"

  initialize: ->
    @users = new UserList;
    @users.fetch();

  render: ->
    @$el.html '<h1>Users</h1>'
    @users.each (user) => 
      @$el.append('<li>Name: '+user.get('name')+'</li>')

      skills_el = $('<ul></ul>')
      user.skills.each (skill) -> skills_el.append('<li>'+skill.get('text')+': '+skill.get('score')+'</li>')
      skills_line = $('<li></li>')
      skills_line.append(skills_el)
      @$el.append(skills_line)

    this

#
# Game
#

class Game extends Backbone.Model
  defaults: { created_at: new Date() }

  initialize: ->
    #   @on 'destroy', ->
    #     @get('user').destroy if @get('user')

    @user = new User()
    @questions = new QuestionList(@_questionData())
    # @questions.fetch();

  # returns the current question object
  current_question: ->
    @nextQuestion() if !@get('current_question_id')
    @questions.get(@get('current_question_id'))

  # just sets the current_question_id to a new value
  nextQuestion: ->
    @set(current_question_id: @questions.sample().cid)
    # return the question object
    @current_question()

  _questionData: ->
    [
      {
        text: 'Should we build more schools?'
        answers: [
          new Answer
            text: 'Yes'
            manipulations:
              'income tax': 5
              'education level': 3
              'public health': 2
              'entrepreneurship': 3
              'community art': -3
              'immigration': 0
          new Answer
            text: 'No'
            manipulations:
              'income tax': -3
              'education level': -4
              'public health': -5
              'entrepreneurship': -1
              'community art': +4
              'immigration': 0
        ],
      },
      {
        text: 'Should we let foreigners work in the USA?'
        answers: [
          new Answer
            text: 'Yes'
            manipulations:
              'income tax': -3
              'education level': 1
              'public health': 1
              'entrepreneurship': 3
              'community art': 2
              'immigration': 5
          new Answer
            text: 'No'
            manipulations:
              'income tax': 2
              'education level': -1
              'public health': -1
              'entrepreneurship': -3
              'community art': -2
              'immigration': -4
        ]
      }
    ]

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


class AdminView extends Backbone.View
  tagName: 'div'
  className: 'admin-info'

  initialize: ->
    @render()

  render: ->
    @$el.html ''
    @$el.append(new GameListView().render().el)
    @$el.append(new UserListView().render().el)
    @$el.append(new QuestionListView().render().el)
    this