import map.UpdTools;
import map.UniformPoissonDisk;
import map.UniformPoissonDisk.Point;

class Level extends dn.Process {
  public var game(get, never): Game; inline function get_game() return Game.ME;
  public var fx(get, never): Fx; inline function get_fx() return Game.ME.fx;

  public var wid(get, never): Int; inline function get_wid() return level.l_Collisions.cWid;
  public var hei(get, never): Int; inline function get_hei() return level.l_Collisions.cHei;

  public var level: World.World_Level;
  var tilesetSource: h2d.Tile;

  var marks: Map<LevelMark, Map<Int,Bool>> = new Map();
  var invalidated = true;

  // Graph + map variables
  var mapCenter: Point;
  var mapRadius: Float;
  var samples: Array<Point>;
  public var graphCenter(get, never): Point; inline function get_graphCenter() return mapCenter;
  public var graphRadius(get, never): Float; inline function get_graphRadius() return mapRadius;
  public var graphSamples(get, never): Array<Point>; inline function get_graphSamples() return samples;

  public function new(l: World.World_Level) {
    super(Game.ME);
    createRootInLayers(Game.ME.scroller, Const.DP_BG);
    level = l;
    tilesetSource = hxd.Res.world.tiles.toTile();

    // Graph + map shit
    mapCenter = new Point(0, 0);
    mapRadius = 10.0;
    var minDist = 1;
    var upd = new UniformPoissonDisk();
    samples = upd.sampleCircle(mapCenter, mapRadius, minDist);
    trace("points(" + samples.length + ") sampled in circle(c=" + UpdTools.pointToStr(mapCenter) + ", r=" + mapRadius + "): \n" + UpdTools.pointArrayToStr(samples) + "\n");
  }

  /**
    Mark the level for re-render at the end of current frame (before display)
  **/
  public inline function invalidate() {
    invalidated = true;
  }

  /**
    Return TRUE if given coordinates are in level bounds
  **/
  public inline function isValid(cx, cy) return cx >= 0 && cx < wid && cy >= 0 && cy < hei;

  /**
    Transform coordinates into a coordId
  **/
  public inline function coordId(cx, cy) return cx + cy * wid;


  /** Return TRUE if mark is present at coordinates **/
  public inline function hasMark(mark: LevelMark, cx: Int, cy: Int) {
    return !isValid(cx, cy) || !marks.exists(mark) ? false : marks.get(mark).exists(coordId(cx, cy));
  }

  /** Enable mark at coordinates **/
  public function setMark(mark: LevelMark, cx: Int, cy: Int) {
    if (isValid(cx, cy) && !hasMark(mark, cx, cy)) {
      if (!marks.exists(mark)) {
        marks.set(mark, new Map());
      }
      marks.get(mark).set(coordId(cx, cy), true);
    }
  }

  /** Remove mark at coordinates **/
  public function removeMark(mark: LevelMark, cx: Int, cy: Int) {
    if (isValid(cx, cy) && hasMark(mark, cx, cy)) {
      marks.get(mark).remove(coordId(cx, cy));
    }
  }

  /** Return TRUE if "Collisions" layer contains a collision value **/
  public inline function hasCollision(cx, cy): Bool {
    return !isValid(cx, cy) ? true : level.l_Collisions.getInt(cx, cy) == 0;
  }

  /** Render current level**/
  function render() {
    root.removeChildren();

    var tg = new h2d.TileGroup(tilesetSource, root);

    var layer = level.l_Collisions;
    for (autoTile in layer.autoTiles) {
      var tile = layer.tileset.getAutoLayerHeapsTile(tilesetSource, autoTile);
      tg.add(autoTile.renderX, autoTile.renderY, tile);
    }
  }

  override function postUpdate() {
    super.postUpdate();

    if (invalidated) {
      invalidated = false;
      render();
    }
  }
}
