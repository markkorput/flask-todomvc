""" factory.py """
from flask import Flask

from . import settings
from .extensions import db, security
from .models import User, Role, Question, Skill
from .index import bp as index
from .todos import bp as todos
from .game import bp as game

from flask_security import SQLAlchemyUserDatastore
from flask_security.utils import encrypt_password


def create_app(priority_settings=None):
    app = Flask(__name__, static_url_path='')

    app.config.from_object(settings)
    app.config.from_envvar('TODO_SETTINGS', silent=True)
    app.config.from_object(priority_settings)

    db.init_app(app)
    user_datastore = SQLAlchemyUserDatastore(db, User, Role)
    security.init_app(app, user_datastore)

    app.register_blueprint(index)
    app.register_blueprint(todos)
    app.register_blueprint(game)

    with app.app_context():
        db.create_all()

        if not User.query.first():
            user_datastore.create_user(email='admin', password=encrypt_password('admin'))
        if not Question.query.first():
            db.session.add(Question(text='Should we build more schools?'))
            db.session.add(Question(text='Should we allow foreigners to work in the USA?'))
        if not Skill.query.first():
            db.session.add(Skill(text='income tax'))
            db.session.add(Skill(text='education level'))
            db.session.add(Skill(text='public health'))
            db.session.add(Skill(text='entrepreneurship'))
            db.session.add(Skill(text='community art'))
            db.session.add(Skill(text='immigration'))

        db.session.commit()
    return app
