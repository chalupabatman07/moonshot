package map;

typedef Point = SimplePoint;

typedef GridIndex = { row: Int, col: Int };
typedef PointArray = Array<Point>;
typedef RejectionFunction = Point->Bool;
typedef MinDistanceFunction = Point->Float;

class UniformPoissonDisk {
  public static var DEFAULT_POINTS_PER_ITERATION: Int = 30;
  public static var FIRST_POINT_TRIES: Int = 1000;
  public static var MAX_POINTS = 100000;

  // Debug
  public static var MIN_DISTANCE_THRESHOLD = .75;
  public static var MAX_DISTANCE_THRESHOLD = 10000;

  var maxPointsReached: Bool = false;

  var pointsPerIteration: Int = DEFAULT_POINTS_PER_ITERATION;

  var topLeft: Point;
  var bottomRight: Point;
  var width: Float;
  var height: Float;

  var reject: Null<RejectionFunction>;
  var minDistanceFunc: MinDistanceFunction;
  var currMinDistance: Float;
  var maxDistance: Float;

  var grid: Array<Array<PointArray>>; // NB: Grid[y][x]
  var gridWidth: Int;
  var gridHeight: Int;
  var cellSize: Float;

  var activePoints: Array<Point>;
  var sampledPoints: Array<Point>;

  public var firstPoint: Point;

  public function new(?firstPoint: Point): Void {
    if (firstPoint == null) return;
    this.firstPoint = firstPoint;
  }

  public inline function randomPointAround(center: Point, minDistance: Float): Point {
    return UpdTools.randomPointAround(center, minDistance);
  }

  public inline function pointToGridCoords(point: Point, topLeft: Point, cellSize: Float): GridIndex {
    return UpdTools.pointToGridCoords(point, topLeft, cellSize);
  }

  public inline function distanceSquared(p: Point, q: Point): Float {
    return UpdTools.distanceSquared(p, q);
  }

  public inline function distance(p: Point, q: Point): Float {
    return UpdTools.distanceSquared(p, q);
  }

  public static inline function makeConstMinDistance(minDistance: Float): MinDistanceFunction {
    return function (p: Point): Float {
      return minDistance;
    }
  }

  function init(
    topLeft: Point,
    bottomRight: Point,
    minDistanceFun: MinDistanceFunction,
    maxDistance: Float,
    ?reject: RejectionFunction,
    ?pointsPerIteration: Int
  ): Void {
    this.pointsPerIteration = pointsPerIteration == null ? DEFAULT_POINTS_PER_ITERATION : pointsPerIteration;

    this.topLeft = topLeft;
    this.bottomRight = bottomRight;
    this.minDistanceFunc = minDistanceFun;

    #if (debug)
    if (maxDistance > MAX_DISTANCE_THRESHOLD) {
      throw 'Error: maxDistance($maxDistance) is greater than MAX_DISTANCE_THRESHOLD($MAX_DISTANCE_THRESHOLD)';
    }
    #end

    this.maxDistance = maxDistance;
    this.currMinDistance = 0;
    this.reject = reject;

    this.width = bottomRight.x - topLeft.x;
    this.height = bottomRight.y - topLeft.y;
    this.cellSize = maxDistance / UpdTools.SQUARE_ROOT_TWO;

    this.gridWidth = Std.int(width / cellSize) + 1;
    this.gridHeight = Std.int(height / cellSize) + 1;

    this.grid = new Array<Array<PointArray>>();
    for (y in 0...gridHeight) {
      this.grid.push([ for (x in 0...gridWidth) null ]);
    }

    this.activePoints = new Array<Point>();
    this.sampledPoints = new Array<Point>();
  }

  function addSampledPoint(point: Point, index: GridIndex): Void {
    activePoints.push(point);
    sampledPoints.push(point);

    var cell = grid[index.row][index.col];
    if (cell != null) {
      cell.push(point);
    } else {
      cell = [point];
      grid[index.row][index.col] = cell;
    }

    if (sampledPoints.length > MAX_POINTS) {
      maxPointsReached = true;
      trace('Generated more than MAX_POINTS($MAX_POINTS)');
    }
  }

  function addFirstPoint(): Void {
    // Add a custom first point instead of finding a random one
    if (this.firstPoint != null) {
      var index = pointToGridCoords(firstPoint, topLeft, cellSize);
      addSampledPoint(firstPoint, index);
      return;
    }

    var added = false;
    var tries = FIRST_POINT_TRIES;

    while (!added && tries > 0) {
      tries--;

      var rndX = topLeft.x + width * UpdTools.randomFloat();
      var rndY = topLeft.y + height * UpdTools.randomFloat();

      var p = new Point(rndX, rndY);
      if (reject != null && reject(p)) continue;

      added = true;

      var index = pointToGridCoords(p, topLeft, cellSize);
      addSampledPoint(p, index);
    }
  }

  inline function isInRectangle(point: Point): Bool {
    return (point.x >= topLeft.x && point.x < bottomRight.x && point.y >= topLeft.y && point.y < bottomRight.y);
  }

  // Iterate the grid over a 5x5 square around `point` (identified by `index`)
  function isInNeighborhood(point: Point, index: GridIndex): Bool {
    var currMinDistanceSquared = currMinDistance * currMinDistance;

    var col = Std.int(Math.max(0, index.col - 2));
    while (col < Math.min(gridWidth, index.col + 3)) {
      var row = Std.int(Math.max(0, index.row - 2));
      while (row < Math.min(gridHeight, index.row + 3)) {
        var cell = grid[row][col];
        if (cell != null) {
          for (p in cell) {
            if (cell != null && distanceSquared(p, point) < currMinDistanceSquared) {
              return true;
            }
          }
        }
        row++;
      }
      col++;
    }
    return false;
  }

  function addNextPointAround(point: Point): Bool {
    var q = randomPointAround(point, currMinDistance);
    var mustReject = (reject != null && reject(q));

    if (isInRectangle(q) && !mustReject) {
      var qIndex = pointToGridCoords(q, topLeft, cellSize);
      if (!isInNeighborhood(q, qIndex)) {
        addSampledPoint(q, qIndex);
        return true;
      }
    }
    return false;
  }

  // The workhorse of the uniform poisson disk
  public function sample(
    topLeft: Point,
    bottomRight: Point,
    minDistance: MinDistanceFunction,
    maxDistance: Float,
    ?reject: RejectionFunction,
    ?pointsPerIteration: Int
  ): Array<Point> {
    init(topLeft, bottomRight, minDistanceFunc, maxDistance, reject, pointsPerIteration);

    addFirstPoint();

    while (activePoints.length != 0 && !maxPointsReached) {
      var randomIndex = UpdTools.randomInt(activePoints.length);

      var point = activePoints[randomIndex];
      var found = false;

      currMinDistance = minDistanceFunc(point);

      #if (debug)
      if (currMinDistance < MIN_DISTANCE_THRESHOLD) {
        throw 'Error: currMinDistance($currMinDistance) is lower than MIN_DISTANCE_THRESHOLD($MIN_DISTANCE_THRESHOLD)';
      }
      if (currMinDistance > maxDistance) {
        throw 'Error: currMinDistance($currMinDistance) is greater than maxDistance($maxDistance)';
      }
      #end

      for (k in 0...this.pointsPerIteration) {
        found = addNextPointAround(point);
        if (found) break;
      }

      // Remove the point
      if (!found) {
        activePoints.splice(randomIndex, 1);
      }
    }

    return sampledPoints;
  }

  public function sampleRectangle(topLeft: Point, bottomRight: Point, minDistance: Float, ?pointsPerIteration: Int): Array<Point> {
    return sample(topLeft, bottomRight, makeConstMinDistance(minDistance), minDistance, null, pointsPerIteration);
  }

  public function sampleCircle(center: Point, radius: Float, minDistance: Float, ?pointsPerIteration: Int): Array<Point> {
    var topLeft = new Point(center.x - radius, center.y - radius);
    var bottomRight = new Point(center.x + radius, center.y + radius);
    var radiusSquared = radius * radius;

    function reject(p: Point): Bool {
      return distanceSquared(center, p) > radiusSquared;
    }

    return sample(topLeft, bottomRight, makeConstMinDistance(minDistance), minDistance, reject, pointsPerIteration);
  }
}
