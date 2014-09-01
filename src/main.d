import allegro;
import state.gamestate;
import state.preparation;
import state.battle;
import util.config;
import util.savegame;
import model.character;

private bool _run = true;        /// if false, shutdown game
private bool _frameTick = false; /// if true, time for an update/draw cycle

private GameState _currentState;

int main(char[][] args) {
  auto data = new SaveData;
  data.roster = [
    generateCharacter("Mercenary"),
    generateCharacter("Mercenary"),
    generateCharacter("Fighter"),
    generateCharacter("Fighter"),
    generateCharacter("Soldier"),
    generateCharacter("Soldier"),
  ];
  data.gold = 600;
  data.mission = 0;
  _currentState = new Battle("map1", data.roster);
  //_currentState = new Preparation(data);

  return al_run_allegro({
      while(_run) {
        process_events();
        if (_frameTick) {
          main_update();
          main_draw();
          _frameTick = false;
        }
      }

      return 0;
  });
}

void process_events() {
  ALLEGRO_EVENT event;
  while(al_get_next_event(event_queue, &event))
  {
    switch(event.type)
    {
      case ALLEGRO_EVENT_TIMER:
        {
          if (event.timer.source == frame_timer) {
            _frameTick = true;
          }
          break;
        }
      case ALLEGRO_EVENT_DISPLAY_CLOSE:
        {
          _run = false;
          break;
        }
      case ALLEGRO_EVENT_KEY_DOWN:
        {
          switch(event.keyboard.keycode)
          {
            case ALLEGRO_KEY_ESCAPE:
              {
                _run = false;
                break;
              }
            default:
          }
          break;
        }
      default:
    }
  }
}

void main_update() {
  static float last_update_time = 0;
  float current_time = al_get_time();
  float delta = current_time - last_update_time;
  last_update_time = current_time;
  _currentState.update(delta);
}

void main_draw() {
  al_clear_to_color(al_map_rgb(0,0,0));
  _currentState.draw();
  al_flip_display();
}
