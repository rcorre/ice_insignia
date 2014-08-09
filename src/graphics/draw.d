/// right now just used for background, later use for sprite batching (maybe primitives?)
module graphics.draw;

import std.string;
import allegro;

private ALLEGRO_BITMAP* _background;

/// set the current background to be drawn by calls to clearBackground. destroys the previous background if it was set
void setBackground(string bgName) { // TODO: use globbing to find files with any extension
  clearBackground();
  auto bgPath = Paths.backgroundDir ~ bgName ~ ".png";
  _background = al_load_bitmap(toStringz(bgPath));
  assert(_background, "could not load background " ~ bgPath);
}

/// destroy the current background bitmap. subsequent calls to setBackground will fail
void clearBackground() {
  if (_background) {
    al_destroy_bitmap(_background);
  }
}

/// draw the background set by the last call of setBackground
void drawBackground() {
  assert(_background, "called drawBackground() when no background was set");
  al_draw_bitmap(_background, 0, 0, 0);
}

static ~this() {
  clearBackground();
}
