package en;

import hxd.Key;
import h2d.Graphics;

class Hero extends Entity {
  var ca: dn.heaps.Controller.ControllerAccess;

  public function new(x, y) {
    super(x, y);

    // Some default rendering of our hero
    var g = new h2d.Graphics(spr);
    g.beginFill(0xff0000);
    g.drawRect(0, 0, 16, 16);

    // Creates an instance of controller
    ca = Main.ME.controller.createAccess('hero');
  }

  override function dispose() {
    super.dispose();
    ca.dispose(); // Release on dispose
  }

  override function update() {
    super.update();

    if (ca.leftDown() || ca.isKeyboardDown(Key.LEFT)) {
      dx -= 0.1 * tmod;
    }

    if (ca.rightDown() || ca.isKeyboardDown(Key.RIGHT)) {
      dx += 0.1 * tmod;
    }

    if (ca.upDown() || ca.isKeyboardDown(Key.UP)) {
      dy += 0.1 * tmod;
    }

    if (ca.downDown() || ca.isKeyboardDown(Key.DOWN)) {
      dy -= 0.1 * tmod;
    }
  }
}
