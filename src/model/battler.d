module model.battler;

import geometry.vector;
import graphics.sprite;
import model.character;

class Battler {
  alias _character this;

  this(Character c, int row, int col, Vector2i pos, Sprite sprite) {
    _character = c;
    _row = row;
    _col = col;
    _pos = pos;
    _sprite = sprite;
  }

  @property {
    Sprite sprite() { return _sprite; }
    ref int row() { return _row; }
    ref int col() { return _col; }
    ref Vector2i pos() { return _pos; }
    Character character() { return _character; }
  }

  void draw() {
    _sprite.draw(pos);
  }

  private:
  Sprite _sprite;
  int _row, _col;
  Vector2i _pos;
  Character _character;
  int _hp;
}
