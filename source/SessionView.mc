import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Pantalla de la sesión: dibuja el paso actual o el descanso.
class SessionView extends WatchUi.View {
    var wo;
    var timer = null;

    function initialize(w) {
        View.initialize();
        wo = w;
    }

    function onShow() {
        if (wo.discarded) {
            // Volvemos de la confirmación "Descartar": salir al inicio
            timer = new Timer.Timer();
            timer.start(method(:closeSelf), 50, false);
            return;
        }
        timer = new Timer.Timer();
        timer.start(method(:onTick), 1000, true);
    }

    function onHide() {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }

    function closeSelf() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onTick() as Void {
        wo.tick();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        Draw.clear(dc);
        if (wo.rest != null) {
            drawRest(dc);
            return;
        }
        var s = wo.current();
        var t = s[:t];
        if (t == :intro) { drawIntro(dc, s); }
        else if (t == :warm) { drawWarm(dc, s); }
        else if (t == :work) { drawWork(dc, s); }
        else if (t == :acc) { drawAcc(dc); }
        else if (t == :emom) { drawEmom(dc); }
        else { drawEnd(dc); }
    }

    function gray() { return Graphics.COLOR_LT_GRAY; }
    function white() { return Graphics.COLOR_WHITE; }

    function drawIntro(dc, s) {
        var k = s[:k];
        var w = wo.weights[k];
        var sug = Logic.currentWeight(k);
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, gray(), "EJERCICIO " + s[:n].toString() + "/" + wo.plan.size().toString());
        Draw.text(dc, 0.26, Graphics.FONT_SMALL, white(), Logic.liftName(k));
        Draw.text(dc, 0.41, Graphics.FONT_LARGE, Graphics.COLOR_BLUE, Logic.fmtKg(w) + " kg");
        var why = (w - sug).abs() < 0.01 ? Logic.reason(k) : "Ajustado (sugerido " + Logic.fmtKg(sug) + ")";
        Draw.text(dc, 0.54, Graphics.FONT_XTINY, gray(), Logic.workSets(k).toString() + "x5 · " + why);
        if (k.equals("deadlift")) {
            Draw.text(dc, 0.64, Graphics.FONT_XTINY, Graphics.COLOR_YELLOW, "Agarre: " + Logic.gripText(wo.grip));
            Draw.text(dc, 0.73, Graphics.FONT_XTINY, gray(), Logic.platesText(w, Logic.barKg()));
            Draw.text(dc, 0.82, Graphics.FONT_XTINY, gray(), "Izq: cambiar agarre");
        } else {
            var n = Logic.warmups(k, w).size();
            if (n == 0) {
                Draw.text(dc, 0.64, Graphics.FONT_XTINY, gray(), "Sin calentamiento");
                Draw.text(dc, 0.73, Graphics.FONT_XTINY, gray(), Logic.platesText(w, Logic.barKg()));
            } else {
                Draw.text(dc, 0.64, Graphics.FONT_XTINY, gray(), "Calentamiento: " + n.toString() + " series");
            }
            Draw.text(dc, 0.82, Graphics.FONT_XTINY, gray(), "Desliza: +/- 2,5 kg");
        }
        Draw.text(dc, 0.91, Graphics.FONT_XTINY, white(), "START: comenzar");
    }

    function drawWarm(dc, s) {
        var k = s[:k];
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, gray(), "CALENTAMIENTO " + (s[:i] + 1).toString() + "/" + s[:of].toString());
        Draw.text(dc, 0.26, Graphics.FONT_SMALL, white(), Logic.liftName(k));
        Draw.text(dc, 0.42, Graphics.FONT_LARGE, Graphics.COLOR_ORANGE, Logic.fmtKg(s[:w]) + " kg x 5");
        Draw.text(dc, 0.56, Graphics.FONT_XTINY, white(), Logic.platesText(s[:w], Logic.barKg()));
        Draw.text(dc, 0.66, Graphics.FONT_XTINY, gray(), "Sin descanso: recarga y sigue");
        Draw.text(dc, 0.77, Graphics.FONT_XTINY, gray(), "Trabajo: " + Logic.fmtKg(wo.weights[k]) + " kg");
        Draw.text(dc, 0.89, Graphics.FONT_XTINY, white(), "START: hecha");
    }

    function drawWork(dc, s) {
        var k = s[:k];
        var w = wo.weights[k];
        var total = Logic.workSets(k);
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, gray(), "SERIE " + (s[:i] + 1).toString() + "/" + total.toString());
        Draw.text(dc, 0.25, Graphics.FONT_SMALL, white(), Logic.liftName(k) + " " + Logic.fmtKg(w));
        var c = wo.pendingReps >= Logic.TARGET ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
        Draw.text(dc, 0.47, Graphics.FONT_NUMBER_HOT, c, wo.pendingReps.toString());
        Draw.text(dc, 0.62, Graphics.FONT_XTINY, gray(), "repeticiones");
        Draw.text(dc, 0.71, Graphics.FONT_XTINY, white(), Logic.platesText(w, Logic.barKg()));
        Draw.text(dc, 0.80, Graphics.FONT_XTINY, gray(), "Desliza si fallaste");
        Draw.text(dc, 0.89, Graphics.FONT_XTINY, white(), "START: registrar");
    }

    function drawRest(dc) {
        var e = wo.restElapsed();
        var lim = wo.restLimits();
        var fail = wo.rest[:fail];
        var color = fail ? Graphics.COLOR_RED : Graphics.COLOR_LT_GRAY;
        var cap;
        if (e < lim[0]) {
            cap = (fail ? "Serie fallida: faltan " : "Mínimo 1:30: faltan ") + Logic.mmss(lim[0] - e);
        } else if (e < lim[1]) {
            color = Graphics.COLOR_GREEN;
            cap = "Listo · máximo en " + Logic.mmss(lim[1] - e);
        } else {
            color = Graphics.COLOR_BLUE;
            cap = "A la barra";
        }
        var frac = e.toFloat() / lim[1];
        Draw.ring(dc, frac > 1.0 ? 1.0 : frac, color);
        Draw.text(dc, 0.20, Graphics.FONT_XTINY, gray(), fail ? "DESCANSO LARGO" : "DESCANSO");
        Draw.text(dc, 0.42, Graphics.FONT_NUMBER_HOT, color, Logic.mmss(e));
        Draw.text(dc, 0.59, Graphics.FONT_XTINY, white(), cap);
        var hr = wo.heartRate();
        if (hr != null) {
            Draw.text(dc, 0.68, Graphics.FONT_XTINY, gray(), "FC " + hr.toString());
        }
        var nx = wo.nextWorkStep();
        if (nx != null) {
            var k = nx[:k];
            Draw.text(dc, 0.77, Graphics.FONT_XTINY, gray(), "Sigue: " + Logic.liftShort(k) + " serie " + (nx[:i] + 1).toString());
        } else {
            Draw.text(dc, 0.77, Graphics.FONT_XTINY, gray(), "Sigue: accesorio");
        }
        Draw.text(dc, 0.87, Graphics.FONT_XTINY, white(), "START: seguir");
    }

    function drawAcc(dc) {
        var a = wo.accessory();
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, gray(), "ACCESORIO");
        Draw.text(dc, 0.27, Graphics.FONT_SMALL, white(), a[:name]);
        Draw.text(dc, 0.42, Graphics.FONT_LARGE, Graphics.COLOR_BLUE, Logic.fmtKg(a[:kg]) + " kg");
        Draw.text(dc, 0.55, Graphics.FONT_TINY, white(), a[:sets].toString() + " x " + a[:reps].toString());
        Draw.text(dc, 0.66, Graphics.FONT_XTINY, gray(), Logic.platesText(a[:kg], Logic.zbarKg()));
        Draw.text(dc, 0.75, Graphics.FONT_XTINY, gray(), "Desliza: +/- 2,5 kg");
        Draw.text(dc, 0.82, Graphics.FONT_XTINY, gray(), "Izq: omitir");
        Draw.text(dc, 0.89, Graphics.FONT_XTINY, white(), "START: hecho");
    }

    function drawEmom(dc) {
        var total = Logic.propN("swMin", 10);
        var reps = Logic.propN("swReps", 10);
        var kg = Logic.propF("swKg", 16.0);
        if (wo.emomStart != null) {
            var e = wo.emomElapsed();
            var m = e / 60;
            var left = 60 - (e % 60);
            Draw.ring(dc, (e % 60) / 60.0, Graphics.COLOR_GREEN);
            Draw.text(dc, 0.20, Graphics.FONT_XTINY, gray(), "EMOM MINUTO " + (m + 1).toString() + "/" + total.toString());
            Draw.text(dc, 0.42, Graphics.FONT_NUMBER_HOT, white(), Logic.mmss(left));
            Draw.text(dc, 0.59, Graphics.FONT_XTINY, white(), reps.toString() + " swings al iniciar el minuto");
            Draw.text(dc, 0.69, Graphics.FONT_XTINY, gray(), "Total " + Logic.mmss(e) + " · " + Logic.fmtKg(kg) + " kg");
            Draw.text(dc, 0.87, Graphics.FONT_XTINY, white(), "START: terminar");
            return;
        }
        if (wo.emomDone) {
            Draw.text(dc, 0.30, Graphics.FONT_XTINY, gray(), "EMOM");
            Draw.text(dc, 0.45, Graphics.FONT_MEDIUM, Graphics.COLOR_GREEN, "Completo");
            Draw.text(dc, 0.60, Graphics.FONT_XTINY, white(), (total * reps).toString() + " swings");
            Draw.text(dc, 0.89, Graphics.FONT_XTINY, white(), "START: seguir");
            return;
        }
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, gray(), "AL FINAL: EMOM");
        Draw.text(dc, 0.27, Graphics.FONT_SMALL, white(), "Kettlebell swings");
        Draw.text(dc, 0.42, Graphics.FONT_LARGE, Graphics.COLOR_BLUE, Logic.fmtKg(kg) + " kg");
        Draw.text(dc, 0.55, Graphics.FONT_TINY, white(), total.toString() + " min x " + reps.toString());
        Draw.text(dc, 0.66, Graphics.FONT_XTINY, gray(), "Vibra al inicio de cada minuto");
        Draw.text(dc, 0.79, Graphics.FONT_XTINY, gray(), "Izq: omitir");
        Draw.text(dc, 0.89, Graphics.FONT_XTINY, white(), "START: iniciar");
    }

    function drawEnd(dc) {
        Draw.text(dc, 0.14, Graphics.FONT_XTINY, gray(), "RESUMEN · ENTRENAMIENTO " + wo.wk);
        var y = 0.27;
        for (var i = 0; i < wo.plan.size(); i++) {
            var k = wo.plan[i];
            var c = wo.liftSuccess(k) ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
            Draw.text(dc, y, Graphics.FONT_XTINY, c, Logic.liftShort(k) + " " + Logic.fmtKg(wo.weights[k]) + "  " + wo.repsText(k));
            y = y + 0.09;
        }
        Draw.text(dc, y, Graphics.FONT_XTINY, wo.accDone ? white() : gray(), "Accesorio: " + (wo.accDone ? "hecho" : "omitido"));
        y = y + 0.09;
        Draw.text(dc, y, Graphics.FONT_XTINY, wo.swDone ? white() : gray(), "EMOM: " + (wo.swDone ? "hecho" : "omitido"));
        Draw.text(dc, 0.80, Graphics.FONT_XTINY, gray(), "Izq: descartar");
        Draw.text(dc, 0.89, Graphics.FONT_XTINY, white(), "START: guardar");
    }
}

class SessionDelegate extends WatchUi.BehaviorDelegate {
    var view;
    var wo;

    function initialize(v, w) {
        BehaviorDelegate.initialize();
        view = v;
        wo = w;
    }

    // Durante el descanso se ignoran los toques en pantalla (solo START lo corta)
    function onTap(evt) {
        return wo.rest != null;
    }

    function onSelect() {
        if (wo.rest == null && wo.current()[:t] == :end) {
            wo.finish();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        wo.confirm();
        WatchUi.requestUpdate();
        return true;
    }

    // Deslizar hacia arriba suma, hacia abajo resta
    function onNextPage() {
        wo.adjust(1);
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() {
        wo.adjust(-1);
        WatchUi.requestUpdate();
        return true;
    }

    function onSwipe(evt) {
        if (evt.getDirection() != WatchUi.SWIPE_LEFT) { return false; }
        if (wo.rest == null && wo.current()[:t] == :end) {
            askDiscard();
            return true;
        }
        if (wo.alt()) { WatchUi.requestUpdate(); }
        return true;
    }

    function onBack() {
        if (!wo.back()) {
            askDiscard();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function askDiscard() {
        WatchUi.pushView(new WatchUi.Confirmation("¿Descartar la sesión?"), new DiscardDelegate(wo), WatchUi.SLIDE_IMMEDIATE);
    }
}

class DiscardDelegate extends WatchUi.ConfirmationDelegate {
    var wo;

    function initialize(w) {
        ConfirmationDelegate.initialize();
        wo = w;
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            wo.discard();
        }
        return true;
    }
}
