module util.math;

import std.math : ceil, floor;
import std.algorithm : min, max;

T clamp(T, U, V)(T val, U lower, V upper) if (is(typeof(min(V.init, max(U.init, T.init))) : T)) {
  return min(upper, max(lower, val));
}

int roundUp(real val) {
  return cast(int) ceil(val);
}

int roundDown(real val) {
  return cast(int) floor(val);
}

unittest {
  assert(5.clamp(0, 3) == 3);
  assert((-2).clamp(0, 3) == 0);
  assert(0.clamp(-5, 5) == 0);

  assert(clamp(0.5, 0, 1) == 0.5);
  assert(clamp(1.5, 0, 1) == 1);
  assert(clamp(-1.5, 0, 1) == 0);
}