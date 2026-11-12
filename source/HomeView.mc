import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Pantalla inicial: qué entrenamiento toca y con qué pesos.
class HomeView extends WatchUi.View {
    var wk;

    function initialize() {
        View.initialize();
        wk = Logic.nextWorkout();
    }

    function onShow() {
        wk = Logic.nextWorkout();
    }

    function toggle() {
        wk = wk.equals("A") ? "B" : "A";
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        Draw.clear(dc);
        var lastDay = Logic.load("lastDay", null);
        var label = "HOY TOCA";
        var sub = "Primera sesión en el reloj";
        if (lastDay != null) {
            var d = Logic.daysSince(lastDay);
            if (d < 2) { label = "PRÓXIMO"; }
            var when = d <= 0 ? "hoy" : (d == 1 ? "ayer" : "hace " + d.toString() + " días");
            sub = "Último: " + Logic.shortDate(lastDay) + " (" + when + ")";
        }
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, label);
        Draw.text(dc, 0.26, Graphics.FONT_MEDIUM, Graphics.COLOR_BLUE, "Entrenamiento " + wk);

        var plan = Logic.planFor(wk);
        for (var i = 0; i < plan.size(); i++) {
            var k = plan[i];
            var line = Logic.liftName(k) + "  " + Logic.fmtKg(Logic.currentWeight(k)) + " kg";
            Draw.text(dc, 0.40 + 0.10 * i, Graphics.FONT_TINY, Graphics.COLOR_WHITE, line);
        }
        if (wk.equals("B")) {
            Draw.text(dc, 0.69, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, "Agarre: " + Logic.gripText(Logic.nextGrip()));
        }
        Draw.text(dc, 0.77, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, sub);
        Draw.text(dc, 0.88, Graphics.FONT_XTINY, Graphics.COLOR_WHITE, "START: empezar");
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    // Solo el botón START inicia la sesión (un toque accidental no graba una actividad)
    function onTap(evt) {
        return true;
    }

    function onSelect() {
        var wo = new Workout(view.wk);
        var sv = new SessionView(wo);
        WatchUi.pushView(sv, new SessionDelegate(sv, wo), WatchUi.SLIDE_LEFT);
        return true;
    }

    // Izquierda: cambiar A/B para hoy
    function onSwipe(evt) {
        if (evt.getDirection() == WatchUi.SWIPE_LEFT) {
            view.toggle();
            return true;
        }
        return false;
    }

    // Deslizar hacia arriba: historial
    function onNextPage() {
        var hv = new HistoryView();
        WatchUi.pushView(hv, new HistoryDelegate(hv), WatchUi.SLIDE_UP);
        return true;
    }
}
