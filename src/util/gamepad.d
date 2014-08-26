module util.gamepad;

import allegro;
import std.conv;
import std.typecons;
import geometry.all;

enum Button360 {
  a           = 0,
  b           = 1,
  x           = 2,
  y           = 3,
  lb          = 4,
  rb          = 5,
  back        = 6,
  start       = 7,
  xbox        = 8,
  left_stick  = 9,
  right_stick = 10
}

class GamePad {
  private enum deadZone = 0.2;

  this(int id) {
    _joystick = al_get_joystick(id);
  }

  void update(float time) {
    _prevState = _currentState;
    if (_joystick) {
      al_get_joystick_state(_joystick, &_currentState);
    }
  }

  @property {
    Vector2f scrollDirection() {
      if (!_joystick) { return Vector2f.Zero; }

      auto stick = _currentState.stick[0];
      auto scroll = Vector2f(stick.axis[0], stick.axis[1]);
      return (scroll.len < deadZone) ? Vector2f.Zero : scroll;
    }
  }

  bool pressed(Button360 button) {
    if (!_joystick) { return false; }
    return (_currentState.button[button] != 0) && (_prevState.button[button] == 0);
  }

  bool released(Button360 button) {
    if (!_joystick) { return false; }
    return (_currentState.button[button] != 0) && (_prevState.button[button] == 0);
  }

  bool held(Button360 button) {
    if (!_joystick) { return false; }
    return (_currentState.button[button] != 0);
  }

  private:
  ALLEGRO_JOYSTICK* _joystick;
  ALLEGRO_JOYSTICK_STATE _currentState, _prevState;
}
