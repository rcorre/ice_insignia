module state.preparation;

import std.range;
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
    auto forSale = [
      new Item("dirk"),
      new Item("broadsword"),
      new Item("quarterstaff"),
      new Item("spear"),
      new Item("handaxe"),
      new Item("mace"),
    ];
    auto rosterView = new RosterView(Vector2i.Zero, data, forHire);
    auto storeView = new StoreView(Vector2i.Zero, data, forSale);
    GUIContainer[] views = [rosterView, storeView];
    _views = cycle(views);
    _input = new InputManager;
  }

  /// returns a GameState to request a state transition, null otherwise
  override GameState update(float time) {
    activeView.update(time);
    _input.update(time);
    if (_input.next) {
      ++_viewIdx;
    }
    else if (_input.previous) {
      --_viewIdx;
    }
    activeView.handleInput(_input);
    return null;
  }

  /// render game state to screen
  override void draw() {
    activeView.draw();
  }

  override void onExit() {
  }

  @property auto activeView() {
    assert(_views[_viewIdx] !is null);
    return _views[_viewIdx];
  }

  private:
  int _viewIdx;
  Cycle!(GUIContainer[]) _views;
  InputManager _input;
  SaveData _data;
}
