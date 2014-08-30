module state.preparation;

import state.gamestate;
import gui.all;
import geometry.all;
import util.input;
import model.character;
import model.item;

class Preparation : GameState {
  this(Character[] characters) {
    _rosterView = new RosterView(Vector2i.Zero, characters);
    _input = new InputManager;
  }

  /// returns a GameState to request a state transition, null otherwise
  override GameState update(float time) {
    _rosterView.update();
    _input.update(time);
    _rosterView.handleInput(_input);
    return null;
  }

  /// render game state to screen
  override void draw() {
    _rosterView.draw();
  }

  override void onExit() {
  }

  private:
  RosterView _rosterView;
  InputManager _input;
}
