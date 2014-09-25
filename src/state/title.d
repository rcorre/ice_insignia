module state.title;

import allegro;
import gui.all;
import util.all;
import graphics.all;
import geometry.all;
import state.gamestate;
import state.preparation;

private enum {
  loadIconOffset = Vector2i(25, 25),
}

class Title : GameState {
  this() {
    _input = new InputManager;
    _titleScreen = new TitleScreen(loadAllSaves(), &startGame);
  }

  override {
    GameState update(float time) {
      _input.update(time);
      return _nextState;
    }

    void draw() {
      _titleScreen.draw();

      auto element = _titleScreen.selectedElement;
      auto pos = element.bounds.topRight + loadIconOffset;
      if (cast(Button) element) {
        drawInputIcon("confirm", pos, _input.gamepadConnected, "Edit");
      }
      else {
        drawInputIcon("confirm", pos, _input.gamepadConnected, "Load");
      }
    }

    void onExit() {
    }

    void handleEvent(ALLEGRO_EVENT event) {
      _titleScreen.handleInput(_input);
    }
  }

  void startGame(SaveData data) {
    _nextState = new Preparation(data, false);
  }

  private:
  TitleScreen _titleScreen;
  InputManager _input;
  GameState _nextState;
}
