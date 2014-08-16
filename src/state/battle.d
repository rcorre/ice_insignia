module state.battle;

import allegro;
import state.gamestate;
import map.all;
import geometry.all;
import util.input;
import model.battler;

enum scrollSpeed = 300;

class Battle : GameState {
  this(string mapName) {
    auto data = loadBattle(mapName);
    _map = data.map;
    _enemies = data.enemies;
    _allies = data.allies;
    _neutrals = data.neutrals;
    _battlers = _enemies ~ _allies ~ _neutrals;
    _camera = Rect2i(0, 0, Settings.screenW, Settings.screenH);
    _input = new InputManager;
  }

  override GameState update(float time) {
    _input.update();
    _camera.topLeft = _camera.topLeft + cast(Vector2i) (_input.scrollDirection * time * scrollSpeed);
    _camera.keepInside(_map.bounds);
    return null;
  }

  override void draw() {
    _map.draw(Vector2i(0,0), _camera);
    foreach(battler ; _battlers) {
      auto sprite = battler.sprite;
      auto rect = Rect2i.CenteredAt(battler.pos, sprite.width, sprite.height);
      if (_camera.intersects(rect)) {
        sprite.draw(rect.center - _camera.topLeft);
      }
    }
  }

  override void onExit() {
  }

  private:
  TileMap _map;
  Rect2i _camera;
  Vector2i _scrollVelocity;
  InputManager _input;
  Battler[] _battlers;
  Battler[] _allies;
  Battler[] _enemies;
  Battler[] _neutrals;
}
