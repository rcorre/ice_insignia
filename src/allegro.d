module allegro;

// library setup
pragma(lib, "dallegro5");
version(none)
{

}
else
{
	pragma(lib, "allegro");
	pragma(lib, "allegro_primitives");
	pragma(lib, "allegro_image");
	pragma(lib, "allegro_font");
	pragma(lib, "allegro_ttf");
	pragma(lib, "allegro_color");
}

// make all allegro functions available
public import allegro5.allegro;
public import allegro5.allegro_primitives;
public import allegro5.allegro_image;
public import allegro5.allegro_font;
public import allegro5.allegro_ttf;
public import allegro5.allegro_color;

// global variables
ALLEGRO_DISPLAY* display;
ALLEGRO_EVENT_QUEUE* event_queue;
ALLEGRO_TIMER* frame_timer;

/// global settings
enum Settings {
  fps     = 30,   /// frames-per-second of update/draw loop
  screenW = 800,  /// screen width
  screenH = 600,  /// screen height
}

/// paths to configuration files and content
enum Paths {
  textureData   = "content/textures.cfg",
  spriteData    = "content/sprites.cfg",
  fontData      = "content/fonts.cfg",
  backgroundDir = "content/image/background/",
  mapDir        = "content/maps/",
}

/// common colors
enum Color {
  white = ALLEGRO_COLOR(1, 1, 1, 1),
  black = ALLEGRO_COLOR(0, 0, 0, 1),
  red   = ALLEGRO_COLOR(1, 0, 0, 1),
  green = ALLEGRO_COLOR(0, 1, 0, 1),
  blue  = ALLEGRO_COLOR(0, 0, 1, 1),
}

// allegro initialization
static this() {
  al_init();

  display = al_create_display(Settings.screenW, Settings.screenH);
  event_queue = al_create_event_queue();
  frame_timer = al_create_timer(1.0 / Settings.fps);

  al_install_keyboard();
  al_install_mouse();
  al_init_image_addon();
  al_init_font_addon();
  al_init_ttf_addon();
  al_init_primitives_addon();

  al_register_event_source(event_queue, al_get_display_event_source(display));
  al_register_event_source(event_queue, al_get_keyboard_event_source());
  al_register_event_source(event_queue, al_get_mouse_event_source());
  al_register_event_source(event_queue, al_get_timer_event_source(frame_timer));

  with(ALLEGRO_BLEND_MODE)
  {
    al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD, ALLEGRO_ALPHA, ALLEGRO_INVERSE_ALPHA);
  }

  al_start_timer(frame_timer); // start fps timer
}
