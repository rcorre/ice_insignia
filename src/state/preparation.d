module state.preparation;

import state.gamestate;
import gui.all;
import geometry.all;
import util.input;
import model.character;
import model.item;
import util.savegame;

class Preparation : GameState {
  this(SaveData data) {
    _data = data;
    auto forHire = [
      generateCharacter("Mercenary"),
      generateCharacter("Mercenary"),
      generateCharacter("Fighter"),
      generateCharacter("Fighter"),
      generateCharacter("Soldier"),
      generateCharacter("Soldier"),
    ];
    _rosterView = new RosterView(Vector2i.Zero, data, forHire);
    _input = new InputManager;
  }

  /// returns a GameState to request a state transition, null otherwise
  override GameState update(float time) {
    _rosterView.update(time);
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
  SaveData _data;
}
