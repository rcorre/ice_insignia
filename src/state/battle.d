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
      if (_camera.contains(rect)) {
        sprite.draw(rect.center);
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
  Battler[] _friendlies;
  Battler[] _enemies;
  Battler[] _neutrals;
}
