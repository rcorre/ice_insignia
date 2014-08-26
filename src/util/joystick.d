module util.gamepad;

import allegro;
import std.conv;

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
  this(int id) {
    _joystick = al_get_joystick(id);
  }

  void update(float time) {
    _prevState = _currentState;
    if (_joystick) {
      al_get_joystick_state(_joystick, &_currentState);
    }
  }

  bool buttonPressed(Button360 button) {
    return (_currentState.button[button] != 0) && (_prevState.button[button] == 0);
  }

  bool buttonReleased(Button360 button) {
    return (_currentState.button[button] != 0) && (_prevState.button[button] == 0);
  }

  bool buttonHeld(Button360 button) {
    return (_currentState.button[button] != 0);
  }

  private:
  ALLEGRO_JOYSTICK* _joystick;
  ALLEGRO_JOYSTICK_STATE _currentState, _prevState;

}
