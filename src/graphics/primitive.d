module graphics.primitive;

import allegro;
import geometry.all;

void draw(T)(Vector2!T point, float radius = 1, ALLEGRO_COLOR color = Color.white) {
  al_draw_filled_circle(point.x, point.y, radius, color);
}

void draw(T)(Rect2!T rect, float thickness = 1, ALLEGRO_COLOR color = Color.white) {
  al_draw_rectangle(rect.x, rect.y, rect.right, rect.bottom, color, thickness);
}

void drawFilled(T)(Rect2!T rect, ALLEGRO_COLOR color = Color.white) {
  al_draw_filled_rectangle(rect.x, rect.y, rect.right, rect.bottom, color);
}
