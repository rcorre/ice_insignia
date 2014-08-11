module state.battle;

import allegro;
import state.gamestate;
import map.all;
import geometry.all;
import util.input;

class Battle : GameState {
  this(string mapName) {
    _map = loadMap(mapName);
    _camera = Rect2i(0, 0, Settings.screenW, Settings.screenH);
    _input = new InputManager;
  }

  override GameState update(float time) {
    _input.update();
    return null;
  }

  override void draw() {
    _map.draw(Vector2i(0,0), _camera);
  }

  override void onExit() {
  }

  private:
  TileMap _map;
  Rect2i _camera;
  Vector2i _scrollVelocity;
  InputManager _input;
}
