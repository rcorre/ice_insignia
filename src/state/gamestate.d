module state.gamestate;

import allegro;

abstract class GameState {
  /// returns a GameState to request a state transition, null otherwise
  GameState update(float time);
  /// render game state to screen
  void draw();
  /// called upon transition to a new state
  void onExit() { }
  /// handle an ALLEGRO_EVENT
  void handleEvent(ALLEGRO_EVENT event) { }
}
