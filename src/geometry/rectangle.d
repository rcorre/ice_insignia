module geometry.rectangle;

import geometry.vector;

alias Rect2i = Rect2!int;
alias Rect2f = Rect2!float;

struct Rect2(T) {
  T x, y, width, height;

  this(T x, T y, T width, T height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  this(Vector2!T topLeft, T width, T height) {
    this(topLeft.x, topLeft.y, width, height);
  }

  this(Vector2!T topLeft, Vector2!T size) {
    this(topLeft.x, topLeft.y, size.x, size.y);
  }

  static auto CenteredAt(Vector2!T center, T width, T height) {
    return Rect2!T(center.x - width / 2, center.y - height / 2, width, height);
  }

  @property {
    T bottom()      { return y + height; }
    T bottom(T val) { return y = val - height; }

    T right()      { return x + width; }
    T right(T val) { return x = val - width; }

    auto center() { return Vector2!T(x + width / 2, y + height / 2); }
    auto center(Vector2!T val) {
      x = val.x;
      y = val.y;
      return center;
    }

    auto topLeft() { return Vector2!T(x, y); }
    auto topLeft(Vector2!T val) {
      x = val.x;
      y = val.y;
      return topLeft;
    }

    auto bottomRight() { return Vector2!T(right, bottom); }
    auto bottomRight(Vector2!T val) {
      right  = val.x;
      bottom = val.y;
      return bottomRight;
    }
  }

  bool contains(T px, T py) {
    return px >= x && px <= right && py >= y && py <= bottom;
  }

  bool contains(Vector2!T point) {
    return point.x >= x && point.x <= right && point.y >= y && point.y <= bottom;
  }

  bool contains(Rect2!T rect) {
    return rect.x >= x && rect.right <= right && rect.y >= y && rect.bottom <= bottom;
  }

  bool intersects(Rect2!T rect) {
    return !(rect.right < x || rect.x > right || rect.bottom < y || rect.y > bottom);
  }

  void keepInside(Rect2!T bounds) {
    if (x < bounds.x) { x = bounds.x; }
    if (y < bounds.y) { y = bounds.y; }
    if (right  > bounds.right)  { right = bounds.right; }
    if (bottom > bounds.bottom) { bottom = bounds.bottom; }
  }
}

// int rects
unittest {
  auto r1 = Rect2i(1, 2, 3, 4);
  // value access
  assert(r1.x == 1 && r1.y == 2 && r1.width == 3 && r1.height == 4);
  assert(r1.bottom == 6 && r1.right == 4);
  assert(r1.center == Vector2i(2, 4)); // center is an approximate -- rounds down
  // assignments
  r1.bottom = 10;
  assert(r1.y == 6 && r1.center == Vector2i(2, 8));

  auto r2 = Rect2i(0, 0, 20, 20);

  assert(!r1.contains(r2) && r2.contains(r1));
}

// float rects
unittest {
  auto r1 = Rect2f(1, 2, 3, 4);
  assert(r1.x == 1 && r1.y == 2 && r1.width == 3 && r1.height == 4);
  assert(r1.bottom == 6 && r1.right == 4);
  assert(r1.center == Vector2f(2.5, 4)); // center is an approximate -- rounds down

  r1.bottom = 5.5;
  assert(r1.y == 1.5 && r1.center == Vector2f(2.5, 3.5));
}
