import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class Bitacora5x5App extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        Logic.applySettingsReset();
    }

    function onStop(state) {
    }

    function getInitialView() {
        var v = new HomeView();
        return [v, new HomeDelegate(v)];
    }

    function onSettingsChanged() {
        Logic.applySettingsReset();
        WatchUi.requestUpdate();
    }
}

// Ayudas de dibujo para pantalla redonda
module Draw {
    function clear(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
    }

    function text(dc, f, font, color, s) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() * f).toNumber(), font, s,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Anillo de progreso por el borde (0..1)
    function ring(dc, frac, color) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = cx - 6;
        dc.setPenWidth(8);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        if (frac > 0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            if (frac >= 1.0) {
                dc.drawCircle(cx, cy, r);
            } else {
                var end = 90 - (360.0 * frac).toNumber();
                if (end < 0) { end = end + 360; }
                dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90, end);
            }
        }
        dc.setPenWidth(1);
    }
}
