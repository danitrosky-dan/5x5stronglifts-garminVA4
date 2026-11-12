import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Últimas 30 sesiones guardadas en el reloj, una por pantalla.
class HistoryView extends WatchUi.View {
    var i = 0;
    var hist;

    function initialize() {
        View.initialize();
        hist = Logic.load("hist", []);
    }

    function move(d) {
        i = i + d;
        if (i < 0) { i = 0; }
        if (i > hist.size() - 1) { i = hist.size() - 1; }
        if (i < 0) { i = 0; }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        Draw.clear(dc);
        if (hist.size() == 0) {
            Draw.text(dc, 0.45, Graphics.FONT_SMALL, Graphics.COLOR_WHITE, "Sin sesiones");
            Draw.text(dc, 0.58, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, "Guarda una sesión para verla aquí");
            return;
        }
        var e = hist[i];
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, "HISTORIAL " + (i + 1).toString() + "/" + hist.size().toString());
        Draw.text(dc, 0.26, Graphics.FONT_SMALL, Graphics.COLOR_BLUE, Logic.shortDate(e["d"]) + "  ·  " + e["w"]);
        var lines = e["l"];
        for (var j = 0; j < lines.size() && j < 5; j++) {
            Draw.text(dc, 0.40 + 0.10 * j, Graphics.FONT_XTINY, Graphics.COLOR_WHITE, lines[j]);
        }
        Draw.text(dc, 0.90, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, "Desliza para navegar");
    }
}

class HistoryDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() {
        view.move(1);
        return true;
    }

    function onPreviousPage() {
        view.move(-1);
        return true;
    }
}
