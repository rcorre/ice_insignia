module state.title;

import allegro;
import gui.all;
import util.all;
import graphics.all;
import geometry.all;
import state.gamestate;

class Title : GameState {
  this() {
    _saves = loadAllSaves();
    _input = new InputManager;
  }

  override {
    GameState update(float time) {
      _input.update(time);
      return null;
    }

    void draw() {
      _titleScreen.draw();
    }

    void onExit() { 
    }

    void handleEvent(ALLEGRO_EVENT event) { 
      _titleScreen.handleInput(_input);
    }
  }

  void startGame() {
    //new Preparation(data, false);
  }

  private:
  SaveData[] _saves;
  TitleScreen _titleScreen;
  InputManager _input;
}
