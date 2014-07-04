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


class Question extends Backbone.Model
  defaults:
    text: 'Question Text'
    answers: [
      new Answer()
      new Answer(text: 'No')
    ]

class QuestionList extends Backbone.Collection
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
    skills: [
      {text: 'income tax', score: 0}
      {text: 'education level', score: 0}
      {text: 'public health', score: 0}
      {text: 'entrepreneurship', score: 0}
      {text: 'community art', score: 0}
      {text: 'immigration', score: 0}
    ]

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
      _.each user.get('skills'), (skill) -> skills_el.append('<li>'+skill.text+': '+skill.score+'</li>')
      skills_line = $('<li></li>')
      skills_line.append(skills_el)
      @$el.append(skills_line)

    this

#
# Game
#

class Game extends Backbone.Model
  defaults: { created_at: new Date(), user: new User() }

  initialize: ->
    #   @on 'destroy', ->
    #     @get('user').destroy if @get('user')

    @questions = new QuestionList()
    @questions.fetch();
    @_createQuestions() if @questions.length < 1

  _createQuestions: ->
    @questions.create
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


class @GameView extends Backbone.View
  initialize: ->
    @games = new GameList;
    @games.fetch();
    @games.create({}) if @games.length < 1
    @game = @games.last()
    @render()

  render: ->
    @$el.html ''
    @$el.append(new GameListView().render().el)
    @$el.append(new UserListView().render().el)
    @$el.append(new QuestionListView().render().el)
    this