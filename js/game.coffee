#
# GameBoardView
#
class @GameView extends Backbone.View
  initialize: ->
    console.log 'whhuuuu'
    # init logic
    @admin_view = new AdminView()
    games = new GameList;
    games.fetch();
    games.create({}) if games.length < 1
    @game = games.last()
    @game_states = new Backbone.Collection([@getCurrentState()])
    # console.log @game_states.first()
    @render()

    @$el.hide()

    # create UI
    @game_ui = new GameUi()
    @game_visuals = new GameVisuals(game_states: @game_states)

    # setup event hooks
    yes_func = (-> 
      @game_visuals.answerYesTween().start().onComplete =>
        @trigger 'answer', @getAnswer('yes')
    )
    no_func = (-> 
      @game_visuals.answerNoTween().start().onComplete =>
        @trigger 'answer', @getAnswer('no')
    )
    @game_ui.on 'answer-yes', yes_func, this
    @game_ui.on 'answer-no', no_func, this
    @game_ui.on 'toggle-stats', (-> @$el.toggle()), this
    @game_visuals.on 'answer-yes', yes_func, this
    @game_visuals.on 'answer-no', no_func, this

    @on 'answer', ((answer) -> @game.submitAnswer(answer)), this
    @game.on 'change', @renderGame, this
    @game.on 'change', @renderStats, this
    @game.user.on 'change', @renderStats, this
    @game.submissions.on 'change', @renderStats, this
    @game.submissions.on 'add', (-> @game_states.add([@getCurrentState()])), this
    @game.on 'new-question', ((question) -> @game_visuals.showQuestion(question) ), this 

    @game.nextQuestion()

  # helpers
  game_el: -> @$el.find('#current-question')
  stats_el: -> @$el.find('#game-stats')
  getAnswer: (txt) -> _.find @game.current_question().get('answers') || [], (answer) -> answer.get('text').toLowerCase() == txt.toLowerCase()
  getCurrentState: -> new Backbone.Model number_of_answers: @game.submissions.length, skills : @game.user.skillsClone()

  # renderers
  render: ->
    @$el.html '<h1>Next Question</h1><div id="current-question"></div><h1>Game Stats</h1><ul id="game-stats"></ul>'
    @$el.append @admin_view.render().el
    
    @renderGame()
    @renderStats()
    this

  renderGame: ->
    @game_el().html ''

    if q = @game.current_question()
      @game_el().append('<h2>'+q.get('text')+'</h2>')
      _.each q.get('answers'), (answer) =>
        button = $('<button>'+answer.get('text')+'</button>')
        button.on 'click', (event) =>
          @trigger('answer', answer)

        @game_el().append(button)

  renderStats: ->
    @stats_el().html ''

    state = @getCurrentState()

    # user and scores
    @stats_el().append('<li>User: '+@game.user.get('name')+'</li>') if @game.user

    # progress 
    @stats_el().append('<li>Questions answered: '+state.get('number_of_answers')+'</li>') 

    # skills
    skills_el = $('<ul></ul>')
    (state.get('skills') || new Backbone.Collection).each (skill) -> skills_el.append('<li>'+skill.get('text')+': '+skill.get('score')+'</li>')
    skills_line = $('<li></li>')
    skills_line.append(skills_el)
    @stats_el().append(skills_line)


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

    # "forward" skills changes as a change on this user
    @skills.on 'change', (model,obj) => @trigger 'change', model, obj

  skillsClone: -> new Backbone.Collection(@skills.map (skill) -> skill.clone())

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
# Submission
#

class Submission extends Backbone.Model

class SubmissionList extends Backbone.Collection
  model: Submission
  localStorage: new Backbone.LocalStorage("todos-backbone")


#
# Game
#

class Game extends Backbone.Model
  defaults: { created_at: new Date() }

  initialize: ->
    @user = new User()
    @submissions = new SubmissionList()
    @questions = new QuestionList(@_questionData())
    # @questions.fetch();

  # returns the current question object
  current_question: ->
    @nextQuestion() if !@get('current_question_id')
    @questions.get(@get('current_question_id'))

  submitAnswer: (answer) ->
    # apply the answer's manipulation values to the current user's skills
    _.each answer.get('manipulations'), (val, key, obj) =>
      if skill = @user.skills.findWhere(text: key)
        skill.set(score: skill.get('score') + val)

    @submissions.create(user_cid: @user.cid, question_cid: @current_question().cid, answer_cid: answer.cid)

    # on to the net question
    @nextQuestion()

  # just sets the current_question_id to a new value
  nextQuestion: ->
    @set(current_question_id: @questions.sample().cid)
    # let anybody hook into this event
    @trigger 'new-question', @current_question()
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
    @games_view = new GameListView()
    @users_view = new UserListView()
    @questions_view = new QuestionListView()
    @render()
    @users_view.users.on 'change', @render, this

  render: ->
    @$el.html ''
    @$el.append(@games_view.render().el)
    @$el.append(@users_view.render().el)
    @$el.append(@questions_view.render().el)
    this