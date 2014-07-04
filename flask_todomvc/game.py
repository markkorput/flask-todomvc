""" index.py """
from flask import Blueprint, render_template
# from flask_security import login_required
# from .models import Todo

bp = Blueprint('game', __name__)


@bp.route('/game')
# @login_required
def index():
    # todos = Todo.query.all()
    # todo_list = map(Todo.to_json, todos)
    return render_template('game.html')
