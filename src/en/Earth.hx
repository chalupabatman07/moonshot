package en;

import map.UpdTools;
import h2d.Graphics;

class Earth extends Entity {
  var scale = 15;

  public function new() {
    super(10, 10);

    var g = new h2d.Graphics(spr);
    g.beginFill(0xff0000);
    g.drawCircle(0, 0, level.graphRadius * scale);

    for (point in level.graphSamples) {
      trace(UpdTools.pointToStr(point));
      g.beginFill(0x000000);
      g.drawCircle(point.x * scale, point.y * scale, 2);
    }
  }
}
