import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Time;

// Una sesión en curso: lista de pasos (ejercicio, calentamiento, series, accesorio, EMOM, resumen),
// descanso entre series y grabación de la actividad de fuerza en Garmin Connect.
class Workout {
    var wk;
    var plan;
    var weights = {};     // lift -> Float
    var reps = {};        // lift -> Array (null = sin registrar)
    var warmDone = {};    // lift -> Number (calentamientos hechos)
    var grip;
    var steps = [];
    var idx = 0;
    var pendingReps = 5;

    var rest = null;      // { :start => seg, :fail => Boolean, :fired => Number }
    var emomStart = null;
    var emomDone = false;
    var emomLastMin = 0;
    var swDone = false;
    var accDone = false;

    var session = null;
    var discarded = false;
    var saved = false;

    function initialize(workoutType) {
        wk = workoutType;
        plan = Logic.planFor(wk);
        for (var i = 0; i < plan.size(); i++) {
            var k = plan[i];
            weights.put(k, Logic.currentWeight(k));
            var arr = [];
            for (var j = 0; j < Logic.workSets(k); j++) { arr.add(null); }
            reps.put(k, arr);
        }
        grip = Logic.nextGrip();
        rebuild();
        startRecording();
    }

    // ---------- Pasos ----------
    // El peso del accesorio se ajusta en el reloj y queda guardado por tipo de día (A/B)
    var accKg = null;

    function accessory() {
        if (accKg == null) { accKg = Logic.accessoryKg(wk); }
        if (wk.equals("A")) {
            return { :name => "Curl barra Z", :kg => accKg,
                     :sets => Logic.propN("curlSets", 3), :reps => Logic.propN("curlReps", 10) };
        }
        return { :name => "Ext. triceps barra Z", :kg => accKg,
                 :sets => Logic.propN("triSets", 3), :reps => Logic.propN("triReps", 10) };
    }

    function rebuild() {
        steps = [];
        for (var i = 0; i < plan.size(); i++) {
            var k = plan[i];
            steps.add({ :t => :intro, :k => k, :n => i + 1 });
            var ws = Logic.warmups(k, weights[k]);
            for (var j = 0; j < ws.size(); j++) {
                steps.add({ :t => :warm, :k => k, :i => j, :of => ws.size(), :w => ws[j] });
            }
            for (var m = 0; m < Logic.workSets(k); m++) {
                steps.add({ :t => :work, :k => k, :i => m });
            }
        }
        steps.add({ :t => :acc });
        steps.add({ :t => :emom });
        steps.add({ :t => :end });
    }

    function current() {
        return steps[idx];
    }

    function enterStep() {
        var s = current();
        if (s[:t] == :work) {
            var r = reps[s[:k]][s[:i]];
            pendingReps = r == null ? Logic.TARGET : r;
        }
    }

    function nextWorkStep() {
        for (var i = idx; i < steps.size(); i++) {
            if (steps[i][:t] == :work) { return steps[i]; }
            if (steps[i][:t] == :acc) { return null; }
        }
        return null;
    }

    // ---------- Acciones ----------
    // START / toque
    function confirm() {
        if (rest != null) {
            rest = null;
            return;
        }
        var s = current();
        var t = s[:t];
        if (t == :intro || t == :warm) {
            advance();
        } else if (t == :work) {
            var done = pendingReps;
            reps[s[:k]][s[:i]] = done;
            lap();
            advance();  // advance() reinicia pendingReps para la serie siguiente
            rest = { :start => Time.now().value(), :fail => done < Logic.TARGET, :fired => 0 };
        } else if (t == :acc) {
            accDone = true;
            advance();
        } else if (t == :emom) {
            if (emomStart == null && !emomDone) {
                emomStart = Time.now().value();
                emomLastMin = 0;
                vibrate(1);
            } else {
                swDone = true;
                emomStart = null;
                emomDone = true;
                advance();
            }
        }
    }

    // Deslizar arriba (+1) / abajo (-1)
    function adjust(delta) {
        if (rest != null) { return; }
        var s = current();
        if (s[:t] == :intro) {
            var k = s[:k];
            var w = weights[k] + 2.5 * delta;
            if (w < Logic.barKg()) { w = Logic.barKg(); }
            weights.put(k, w);
            rebuild();
        } else if (s[:t] == :acc) {
            accessory();
            accKg = accKg + 2.5 * delta;
            if (accKg < 0) { accKg = 0.0; }
            Logic.save("acc_kg_" + wk, accKg);
        } else if (s[:t] == :work) {
            pendingReps = pendingReps + delta;
            if (pendingReps > Logic.TARGET) { pendingReps = Logic.TARGET; }
            if (pendingReps < 0) { pendingReps = 0; }
        }
    }

    // Deslizar a la izquierda: cambia agarre / omite accesorio o EMOM
    function alt() {
        if (rest != null) { return false; }
        var s = current();
        if (s[:t] == :intro && s[:k].equals("deadlift")) {
            grip = grip.equals("izq") ? "der" : "izq";
            return true;
        }
        if (s[:t] == :acc) {
            accDone = false;
            advance();
            return true;
        }
        if (s[:t] == :emom) {
            emomStart = null;
            swDone = false;
            advance();
            return true;
        }
        return false;
    }

    // BACK: vuelve un paso. Devuelve false si ya está en el primero.
    function back() {
        if (rest != null) {
            rest = null;
            idx = idx - 1;
            enterStep();
            return true;
        }
        if (current()[:t] == :emom && emomStart != null) {
            emomStart = null;
            return true;
        }
        if (idx == 0) { return false; }
        idx = idx - 1;
        enterStep();
        return true;
    }

    function advance() {
        if (idx < steps.size() - 1) {
            idx = idx + 1;
            enterStep();
        }
    }

    // ---------- Cronómetros ----------
    function restLimits() {
        if (rest != null && rest[:fail]) { return [300, 300]; }
        return [90, 180];
    }

    function restElapsed() {
        return rest == null ? 0 : Time.now().value() - rest[:start];
    }

    function tick() {
        if (rest != null) {
            var e = restElapsed();
            var lim = restLimits();
            if (e >= lim[0] && rest[:fired] < 1) {
                rest[:fired] = 1;
                vibrate(2);
            }
            if (lim[1] > lim[0] && e >= lim[1] && rest[:fired] < 2) {
                rest[:fired] = 2;
                vibrate(3);
            }
        }
        if (emomStart != null) {
            var total = Logic.propN("swMin", 10);
            var el = Time.now().value() - emomStart;
            var m = el / 60;
            if (m >= total) {
                emomStart = null;
                emomDone = true;
                swDone = true;
                vibrate(3);
            } else if (m > emomLastMin) {
                emomLastMin = m;
                vibrate(1);
            }
        }
    }

    function emomElapsed() {
        return emomStart == null ? 0 : Time.now().value() - emomStart;
    }

    function vibrate(n) {
        if (Attention has :backlight) {
            try { Attention.backlight(true); } catch (e) { }
        }
        if (Attention has :vibrate) {
            var p = [];
            for (var i = 0; i < n; i++) {
                p.add(new Attention.VibeProfile(100, 350));
                if (i < n - 1) { p.add(new Attention.VibeProfile(0, 200)); }
            }
            Attention.vibrate(p);
        }
    }

    // ---------- Grabación de la actividad ----------
    function startRecording() {
        if (Toybox has :ActivityRecording) {
            try {
                session = ActivityRecording.createSession({
                    :name => "Fuerza 5x5 " + wk,
                    :sport => ActivityRecording.SPORT_TRAINING,
                    :subSport => ActivityRecording.SUB_SPORT_STRENGTH_TRAINING
                });
                session.start();
            } catch (e) {
                session = null;
            }
        }
    }

    function lap() {
        if (session != null && session.isRecording()) {
            session.addLap();
        }
    }

    function heartRate() {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) { return info.currentHeartRate; }
        return null;
    }

    function liftSuccess(k) {
        var arr = reps[k];
        for (var i = 0; i < arr.size(); i++) {
            if (arr[i] == null || arr[i] < Logic.TARGET) { return false; }
        }
        return true;
    }

    function repsText(k) {
        var arr = reps[k];
        var t = "";
        for (var i = 0; i < arr.size(); i++) {
            if (i > 0) { t = t + "/"; }
            t = t + (arr[i] == null ? "0" : arr[i].toString());
        }
        return t;
    }

    function finish() {
        if (session != null) {
            if (session.isRecording()) { session.stop(); }
            session.save();
            session = null;
        }
        var lines = [];
        for (var i = 0; i < plan.size(); i++) {
            var k = plan[i];
            var ok = liftSuccess(k);
            Logic.applyResult(k, weights[k], ok);
            var line = Logic.liftShort(k) + " " + Logic.fmtKg(weights[k]) + " " + repsText(k);
            if (k.equals("deadlift")) { line = line + (grip.equals("izq") ? " izq" : " der"); }
            lines.add(line);
        }
        var acc = accessory();
        if (accDone) {
            lines.add(acc[:name] + " " + Logic.fmtKg(acc[:kg]) + " " + acc[:sets].toString() + "x" + acc[:reps].toString());
        }
        if (swDone) {
            lines.add("Swings " + Logic.propN("swMin", 10).toString() + "x" + Logic.propN("swReps", 10).toString() + " " + Logic.fmtKg(Logic.propF("swKg", 16.0)));
        }
        Logic.save("last", wk);
        Logic.save("lastDay", Logic.todayValue());
        if (wk.equals("B")) { Logic.save("grip", grip); }

        var hist = Logic.load("hist", []);
        var entry = { "d" => Logic.todayValue(), "w" => wk, "l" => lines };
        var out = [entry];
        for (var h = 0; h < hist.size() && out.size() < 30; h++) { out.add(hist[h]); }
        Logic.save("hist", out);
        saved = true;
    }

    function discard() {
        if (session != null) {
            try {
                if (session.isRecording()) { session.stop(); }
                session.discard();
            } catch (e) {
            }
            session = null;
        }
        discarded = true;
    }
}
