module util.input;

import allegro;
import geometry.vector;

enum MouseButton {
  lmb = 1,
  rmb = 2
}

class InputManager {
  void update() {
    _prevKeyboardState = _curKeyboardState;
    _prevMouseState = _curMouseState;
    al_get_keyboard_state(&_curKeyboardState);
    al_get_mouse_state(&_curMouseState);
  }

  @property {
    Vector2i scrollDirection() {
      Vector2i scroll;
      if (keyHeld(ALLEGRO_KEY_W)) {
        scroll.y = -1;
      }
      else if (keyHeld(ALLEGRO_KEY_S)) {
        scroll.y = 1;
      }
      if (keyHeld(ALLEGRO_KEY_A)) {
        scroll.x = -1;
      }
      else if (keyHeld(ALLEGRO_KEY_D)) {
        scroll.x = 1;
      }
      return scroll;
    }

    bool confirm() { return mouseClicked(MouseButton.lmb); }
    bool cancel()  { return mouseClicked(MouseButton.rmb); }
    bool endTurn() { return keyPressed(ALLEGRO_KEY_SPACE); }
  }

  Vector2i mousePos() {
    return Vector2i(_curMouseState.x, _curMouseState.y);
  }

  private:
  bool keyHeld(int keycode) {
    return al_key_down(&_curKeyboardState, keycode);
  }

  bool keyPressed(int keycode) {
    return !al_key_down(&_prevKeyboardState, keycode) && al_key_down(&_curKeyboardState, keycode);
  }

  bool keyReleased(int keycode) {
    return al_key_down(&_prevKeyboardState, keycode) && !al_key_down(&_curKeyboardState, keycode);
  }

  bool mouseClicked(MouseButton button) {
    int b = cast(int) button;
    return !al_mouse_button_down(&_prevMouseState, b) && al_mouse_button_down(&_curMouseState, b);
  }


  ALLEGRO_KEYBOARD_STATE _curKeyboardState, _prevKeyboardState;
  ALLEGRO_MOUSE_STATE _curMouseState, _prevMouseState;
}

