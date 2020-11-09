package map;

import map.UniformPoissonDisk.GridIndex;
import map.UniformPoissonDisk.Point;

class UpdTools {
  public static var PI(default, never): Float = Math.PI;
  public static var HALF_PI(default, never): Float = (Math.PI / 2);
  public static var TWO_PI(default, never): Float = (Math.PI * 2);
  public static var SQUARE_ROOT_TWO(default, never): Float = Math.sqrt(2);

  public static inline function randomFloat(upperBound: Float = 1.0): Float {
    return Math.random() * upperBound;
  }

  // Random point in the annulus at `center`, with `minRadius = minDistance` and `maxRadius = 2 * minDistance`
  public static function randomPointAround(center: Point, minDistance: Float): Point {
    var d = randomFloat();
    var radius = minDistance + minDistance * d;

    d = randomFloat();
    var angle = TWO_PI * d;

    var x = radius * Math.sin(angle);
    var y = radius * Math.cos(angle);

    return new Point((center.x + x), (center.y + y));
  }

  public static function pointToGridCoords(point: Point, topLeft: Point, cellSize: Float): GridIndex {
    return {
      row: Std.int((point.y - topLeft.y) / cellSize),
      col: Std.int((point.x - topLeft.x) / cellSize),
    }
  }

  public static inline function distanceSquared(p: Point, q: Point): Float {
    var dx = p.x - q.x;
    var dy = p.y - q.y;
    return dx * dx + dy * dy;
  }

  public static inline function distance(p: Point, q: Point): Float {
    return Math.sqrt(distanceSquared(p, q));
  }

  public static inline function randomInt(upperBound: Int): Int {
    return Std.random(upperBound);
  }

  public static inline function clamp(value: Float, min: Float, max: Float): Float {
    return (value < min ? min : (value > max ? max : value));
  }

  public static function pointToStr(p: Point, decimals: Int = 2): String {
    var x = p.x;
    var y = p.y;
    if (decimals >= 0) {
      var pow = Math.pow(10, decimals);
      x = Math.fround(x * pow) / pow;
      y = Math.fround(y * pow) / pow;
    }
    return '($x, $y)';
  }

  public static function pointArrayToStr(points: Array<Point>): String {
    var strArr = [for (p in points) ' $pointToStr(p)'];
    return strArr.join('\n');
  }
}
