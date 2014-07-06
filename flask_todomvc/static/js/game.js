// Generated by CoffeeScript 1.6.3
(function() {
  var AdminView, Answer, Game, GameList, GameListView, QuestionListView, Submission, SubmissionList, User, UserListView, _ref, _ref1, _ref10, _ref11, _ref12, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  this.GameView = (function(_super) {
    __extends(GameView, _super);

    function GameView() {
      _ref = GameView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    GameView.prototype.initialize = function() {
      var games, no_func, yes_func;
      this.admin_view = new AdminView();
      games = new GameList;
      games.fetch();
      if (games.length < 1) {
        games.create({});
      }
      this.game = games.last();
      this.game_states = new Backbone.Collection([this.getCurrentState()]);
      this.render();
      this.$el.hide();
      this.game_ui = new GameUi();
      this.game_visuals = new GameVisuals({
        game_states: this.game_states
      });
      yes_func = (function() {
        return this.trigger('answer', this.getAnswer('yes'));
      });
      no_func = (function() {
        return this.trigger('answer', this.getAnswer('no'));
      });
      this.game_ui.on('answer-yes', yes_func, this);
      this.game_ui.on('answer-no', no_func, this);
      this.game_ui.on('toggle-stats', (function() {
        return this.$el.toggle();
      }), this);
      this.game_visuals.on('answer-yes', yes_func, this);
      this.game_visuals.on('answer-no', no_func, this);
      this.on('answer', (function(answer) {
        return this.game.submitAnswer(answer);
      }), this);
      this.game.on('change', this.renderGame, this);
      this.game.on('change', this.renderStats, this);
      this.game.user.on('change', this.renderStats, this);
      this.game.submissions.on('change', this.renderStats, this);
      this.game.submissions.on('add', (function() {
        return this.game_states.add([this.getCurrentState()]);
      }), this);
      this.game.on('new-question', (function(question) {
        return this.game_visuals.showQuestion(question);
      }), this);
      return this.game.nextQuestion();
    };

    GameView.prototype.game_el = function() {
      return this.$el.find('#current-question');
    };

    GameView.prototype.stats_el = function() {
      return this.$el.find('#game-stats');
    };

    GameView.prototype.getAnswer = function(txt) {
      return _.find(this.game.current_question().get('answers') || [], function(answer) {
        return answer.get('text').toLowerCase() === txt.toLowerCase();
      });
    };

    GameView.prototype.getCurrentState = function() {
      return new Backbone.Model({
        number_of_answers: this.game.submissions.length,
        skills: this.game.user.skillsClone()
      });
    };

    GameView.prototype.render = function() {
      this.$el.html('<h1>Next Question</h1><div id="current-question"></div><h1>Game Stats</h1><ul id="game-stats"></ul>');
      this.$el.append(this.admin_view.render().el);
      this.renderGame();
      this.renderStats();
      return this;
    };

    GameView.prototype.renderGame = function() {
      var q,
        _this = this;
      this.game_el().html('');
      if (q = this.game.current_question()) {
        this.game_el().append('<h2>' + q.get('text') + '</h2>');
        return _.each(q.get('answers'), function(answer) {
          var button;
          button = $('<button>' + answer.get('text') + '</button>');
          button.on('click', function(event) {
            return _this.trigger('answer', answer);
          });
          return _this.game_el().append(button);
        });
      }
    };

    GameView.prototype.renderStats = function() {
      var skills_el, skills_line, state;
      this.stats_el().html('');
      state = this.getCurrentState();
      if (this.game.user) {
        this.stats_el().append('<li>User: ' + this.game.user.get('name') + '</li>');
      }
      this.stats_el().append('<li>Questions answered: ' + state.get('number_of_answers') + '</li>');
      skills_el = $('<ul></ul>');
      (state.get('skills') || new Backbone.Collection).each(function(skill) {
        return skills_el.append('<li>' + skill.get('text') + ': ' + skill.get('score') + '</li>');
      });
      skills_line = $('<li></li>');
      skills_line.append(skills_el);
      return this.stats_el().append(skills_line);
    };

    return GameView;

  })(Backbone.View);

  Answer = (function(_super) {
    __extends(Answer, _super);

    function Answer() {
      _ref1 = Answer.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Answer.prototype.defaults = {
      text: 'Yes',
      manipulations: {
        'income tax': 0,
        'education level': 0,
        'public health': 0,
        'entrepreneurship': 0,
        'community art': 0,
        'immigration': 0
      }
    };

    return Answer;

  })(Backbone.Model);

  this.Question = (function(_super) {
    __extends(Question, _super);

    function Question() {
      _ref2 = Question.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    Question.prototype.defaults = {
      text: 'Question Text',
      answers: [
        new Answer(), new Answer({
          text: 'No'
        })
      ]
    };

    return Question;

  })(Backbone.Model);

  this.QuestionList = (function(_super) {
    __extends(QuestionList, _super);

    function QuestionList() {
      _ref3 = QuestionList.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    QuestionList.prototype.model = Question;

    QuestionList.prototype.localStorage = new Backbone.LocalStorage("todos-backbone");

    return QuestionList;

  })(Backbone.Collection);

  QuestionListView = (function(_super) {
    __extends(QuestionListView, _super);

    function QuestionListView() {
      _ref4 = QuestionListView.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    QuestionListView.prototype.tagName = "ul";

    QuestionListView.prototype.className = "questions-list";

    QuestionListView.prototype.initialize = function() {
      this.questions = new QuestionList;
      return this.questions.fetch();
    };

    QuestionListView.prototype.render = function() {
      var _this = this;
      this.$el.html('<h1>Questions</h1>');
      this.questions.each(function(question) {
        var answers;
        answers = _.map(question.get('answers') || [], function(answer) {
          return answer.get('text');
        });
        return _this.$el.append('<li>' + question.get('text') + ' (' + answers.join(', ') + ')</li>');
      });
      return this;
    };

    return QuestionListView;

  })(Backbone.View);

  User = (function(_super) {
    __extends(User, _super);

    function User() {
      _ref5 = User.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    User.prototype.defaults = {
      name: 'John Doe'
    };

    User.prototype.initialize = function() {
      var _this = this;
      this.skills = new Backbone.Collection([
        {
          text: 'income tax',
          score: 0
        }, {
          text: 'education level',
          score: 0
        }, {
          text: 'public health',
          score: 0
        }, {
          text: 'entrepreneurship',
          score: 0
        }, {
          text: 'community art',
          score: 0
        }, {
          text: 'immigration',
          score: 0
        }
      ]);
      return this.skills.on('change', function(model, obj) {
        return _this.trigger('change', model, obj);
      });
    };

    User.prototype.skillsClone = function() {
      return new Backbone.Collection(this.skills.map(function(skill) {
        return skill.clone();
      }));
    };

    return User;

  })(Backbone.Model);

  this.UserList = (function(_super) {
    __extends(UserList, _super);

    function UserList() {
      _ref6 = UserList.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    UserList.prototype.model = User;

    UserList.prototype.localStorage = new Backbone.LocalStorage("todos-backbone");

    return UserList;

  })(Backbone.Collection);

  UserListView = (function(_super) {
    __extends(UserListView, _super);

    function UserListView() {
      _ref7 = UserListView.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    UserListView.prototype.tagName = "ul";

    UserListView.prototype.className = "users-list";

    UserListView.prototype.initialize = function() {
      this.users = new UserList;
      return this.users.fetch();
    };

    UserListView.prototype.render = function() {
      var _this = this;
      this.$el.html('<h1>Users</h1>');
      this.users.each(function(user) {
        var skills_el, skills_line;
        _this.$el.append('<li>Name: ' + user.get('name') + '</li>');
        skills_el = $('<ul></ul>');
        user.skills.each(function(skill) {
          return skills_el.append('<li>' + skill.get('text') + ': ' + skill.get('score') + '</li>');
        });
        skills_line = $('<li></li>');
        skills_line.append(skills_el);
        return _this.$el.append(skills_line);
      });
      return this;
    };

    return UserListView;

  })(Backbone.View);

  Submission = (function(_super) {
    __extends(Submission, _super);

    function Submission() {
      _ref8 = Submission.__super__.constructor.apply(this, arguments);
      return _ref8;
    }

    return Submission;

  })(Backbone.Model);

  SubmissionList = (function(_super) {
    __extends(SubmissionList, _super);

    function SubmissionList() {
      _ref9 = SubmissionList.__super__.constructor.apply(this, arguments);
      return _ref9;
    }

    SubmissionList.prototype.model = Submission;

    SubmissionList.prototype.localStorage = new Backbone.LocalStorage("todos-backbone");

    return SubmissionList;

  })(Backbone.Collection);

  Game = (function(_super) {
    __extends(Game, _super);

    function Game() {
      _ref10 = Game.__super__.constructor.apply(this, arguments);
      return _ref10;
    }

    Game.prototype.defaults = {
      created_at: new Date()
    };

    Game.prototype.initialize = function() {
      this.user = new User();
      this.submissions = new SubmissionList();
      return this.questions = new QuestionList(this._questionData());
    };

    Game.prototype.current_question = function() {
      if (!this.get('current_question_id')) {
        this.nextQuestion();
      }
      return this.questions.get(this.get('current_question_id'));
    };

    Game.prototype.submitAnswer = function(answer) {
      var _this = this;
      _.each(answer.get('manipulations'), function(val, key, obj) {
        var skill;
        if (skill = _this.user.skills.findWhere({
          text: key
        })) {
          return skill.set({
            score: skill.get('score') + val
          });
        }
      });
      this.submissions.create({
        user_cid: this.user.cid,
        question_cid: this.current_question().cid,
        answer_cid: answer.cid
      });
      return this.nextQuestion();
    };

    Game.prototype.nextQuestion = function() {
      this.set({
        current_question_id: this.questions.sample().cid
      });
      this.trigger('new-question', this.current_question());
      return this.current_question();
    };

    Game.prototype._questionData = function() {
      return [
        {
          text: 'Should we build more schools?',
          answers: [
            new Answer({
              text: 'Yes',
              manipulations: {
                'income tax': 5,
                'education level': 3,
                'public health': 2,
                'entrepreneurship': 3,
                'community art': -3,
                'immigration': 0
              }
            }), new Answer({
              text: 'No',
              manipulations: {
                'income tax': -3,
                'education level': -4,
                'public health': -5,
                'entrepreneurship': -1,
                'community art': +4,
                'immigration': 0
              }
            })
          ]
        }, {
          text: 'Should we let foreigners work in the USA?',
          answers: [
            new Answer({
              text: 'Yes',
              manipulations: {
                'income tax': -3,
                'education level': 1,
                'public health': 1,
                'entrepreneurship': 3,
                'community art': 2,
                'immigration': 5
              }
            }), new Answer({
              text: 'No',
              manipulations: {
                'income tax': 2,
                'education level': -1,
                'public health': -1,
                'entrepreneurship': -3,
                'community art': -2,
                'immigration': -4
              }
            })
          ]
        }
      ];
    };

    return Game;

  })(Backbone.Model);

  GameList = (function(_super) {
    __extends(GameList, _super);

    GameList.prototype.model = Game;

    GameList.prototype.localStorage = new Backbone.LocalStorage("todos-backbone");

    function GameList(_opts) {
      GameList.__super__.constructor.call(this);
    }

    return GameList;

  })(Backbone.Collection);

  GameListView = (function(_super) {
    __extends(GameListView, _super);

    function GameListView() {
      _ref11 = GameListView.__super__.constructor.apply(this, arguments);
      return _ref11;
    }

    GameListView.prototype.tagName = "ul";

    GameListView.prototype.className = "games-list";

    GameListView.prototype.initialize = function() {
      this.games = new GameList;
      return this.games.fetch();
    };

    GameListView.prototype.render = function() {
      var _this = this;
      this.$el.html('<h1>Games</h1>');
      this.games.each(function(game) {
        return _this.$el.append('<li>Creation Date: ' + game.get('created_at') + '</li>');
      });
      return this;
    };

    return GameListView;

  })(Backbone.View);

  AdminView = (function(_super) {
    __extends(AdminView, _super);

    function AdminView() {
      _ref12 = AdminView.__super__.constructor.apply(this, arguments);
      return _ref12;
    }

    AdminView.prototype.tagName = 'div';

    AdminView.prototype.className = 'admin-info';

    AdminView.prototype.initialize = function() {
      this.games_view = new GameListView();
      this.users_view = new UserListView();
      this.questions_view = new QuestionListView();
      this.render();
      return this.users_view.users.on('change', this.render, this);
    };

    AdminView.prototype.render = function() {
      this.$el.html('');
      this.$el.append(this.games_view.render().el);
      this.$el.append(this.users_view.render().el);
      this.$el.append(this.questions_view.render().el);
      return this;
    };

    return AdminView;

  })(Backbone.View);

}).call(this);
