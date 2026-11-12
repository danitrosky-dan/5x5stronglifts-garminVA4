import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Reglas del programa: progresión StrongLifts, calentamiento, discos por lado.
// Todo lo que se guarda en el reloj vive en Application.Storage.
module Logic {

    const LIFTS = ["squat", "bench", "row", "ohp", "deadlift"];
    const TARGET = 5;

    // ---------- Ajustes (app Garmin Connect) ----------
    function prop(key, def) {
        var v = null;
        try {
            v = Application.Properties.getValue(key);
        } catch (e) {
            v = null;
        }
        return v == null ? def : v;
    }

    function propF(key, def) {
        var v = prop(key, def);
        if (v instanceof Lang.String) {
            var f = v.toFloat();
            return f == null ? def : f;
        }
        return v.toFloat();
    }

    function propN(key, def) {
        var v = prop(key, def);
        if (v instanceof Lang.String) {
            var n = v.toNumber();
            return n == null ? def : n;
        }
        return v.toNumber();
    }

    function load(key, def) {
        var v = Application.Storage.getValue(key);
        return v == null ? def : v;
    }

    function save(key, v) {
        Application.Storage.setValue(key, v);
    }

    // Peso del accesorio del día: el último usado en el reloj, o el de properties.xml
    function accessoryKg(wk) {
        var v = Application.Storage.getValue("acc_kg_" + wk);
        if (v != null) { return v.toFloat(); }
        return wk.equals("A") ? propF("curlKg", 20.0) : propF("triKg", 15.0);
    }

    function barKg() { return propF("barKg", 20.0); }
    function zbarKg() { return propF("zbarKg", 6.0); }

    // Si en el teléfono se activó "Aplicar estos pesos", reemplaza la progresión del reloj.
    function applySettingsReset() {
        if (prop("applyStart", false) == true) {
            for (var i = 0; i < LIFTS.size(); i++) {
                var k = LIFTS[i];
                Application.Storage.deleteValue("w_" + k);
                Application.Storage.deleteValue("f_" + k);
                Application.Storage.deleteValue("fw_" + k);
                Application.Storage.deleteValue("r_" + k);
            }
            Application.Storage.deleteValue("acc_kg_A");
            Application.Storage.deleteValue("acc_kg_B");
            try {
                Application.Properties.setValue("applyStart", false);
            } catch (e) {
            }
        }
    }

    // ---------- Textos ----------
    function liftName(k) {
        if (k.equals("squat")) { return "Sentadilla"; }
        if (k.equals("bench")) { return "Press banca"; }
        if (k.equals("row")) { return "Remo con barra"; }
        if (k.equals("ohp")) { return "Press militar"; }
        return "Peso muerto";
    }

    function liftShort(k) {
        if (k.equals("squat")) { return "Sentad."; }
        if (k.equals("bench")) { return "Banca"; }
        if (k.equals("row")) { return "Remo"; }
        if (k.equals("ohp")) { return "Militar"; }
        return "P. muerto";
    }

    function planFor(wk) {
        if (wk.equals("A")) { return ["squat", "bench", "row"]; }
        return ["squat", "ohp", "deadlift"];
    }

    function workSets(k) {
        return k.equals("deadlift") ? 1 : 5;
    }

    // 62.5 -> "62,5"; 1.25 -> "1,25"; 60.0 -> "60"
    function fmtKg(x) {
        var c = (x.toFloat() * 100.0 + 0.5).toNumber();
        var whole = c / 100;
        var r = c % 100;
        if (r == 0) { return whole.toString(); }
        if (r % 10 == 0) { return whole.toString() + "," + (r / 10).toString(); }
        return whole.toString() + "," + r.format("%02d");
    }

    function mmss(sec) {
        if (sec < 0) { sec = 0; }
        var s = sec.toNumber();
        return (s / 60).toString() + ":" + (s % 60).format("%02d");
    }

    // Redondea siempre hacia abajo a múltiplos de 2,5 kg
    function floor25(x) {
        return (x.toFloat() / 2.5 + 0.0001).toNumber() * 2.5;
    }

    // ---------- Progresión ----------
    function currentWeight(k) {
        var w = Application.Storage.getValue("w_" + k);
        if (w == null) { w = propF("start_" + k, 20.0); }
        return w.toFloat();
    }

    function reason(k) {
        return load("r_" + k, "Peso inicial");
    }

    function nextWorkout() {
        var forced = propN("nextWk", 0);
        if (forced == 1) { return "A"; }
        if (forced == 2) { return "B"; }
        var last = load("last", null);
        if (last == null) { return "A"; }
        return last.equals("A") ? "B" : "A";
    }

    // Agarre mixto del peso muerto: "izq" = mano izquierda palma arriba
    function nextGrip() {
        var g = load("grip", null);
        if (g == null) { return "izq"; }
        return g.equals("izq") ? "der" : "izq";
    }

    function gripText(g) {
        return g.equals("izq") ? "Izq. palma arriba" : "Der. palma arriba";
    }

    function applyResult(k, weight, success) {
        var inc = k.equals("deadlift") ? propF("incDeadlift", 5.0) : propF("incOther", 2.5);
        var fails = load("f_" + k, 0);
        var next = weight;
        var why = "";
        if (success) {
            next = weight + inc;
            fails = 0;
            why = "+" + fmtKg(inc) + " kg: completaste " + fmtKg(weight);
        } else {
            var lastFailW = load("fw_" + k, -1.0);
            if ((lastFailW.toFloat() - weight).abs() < 0.01) {
                fails = fails + 1;
            } else {
                fails = 1;
            }
            save("fw_" + k, weight);
            if (fails >= 3) {
                next = floor25(weight * 0.9);
                if (next < barKg()) { next = barKg(); }
                fails = 0;
                why = "Descarga 10% tras 3 fallos";
            } else {
                why = "Repite (intento " + (fails + 1).toString() + " de 3)";
            }
        }
        save("w_" + k, next);
        save("f_" + k, fails);
        save("r_" + k, why);
    }

    // ---------- Calentamiento ----------
    // Interpolación desde la barra vacía hasta el 50% de la carga, series de 5.
    function warmups(k, w) {
        var bar = barKg();
        var n = 0;
        if (k.equals("deadlift")) { return []; }
        if (k.equals("squat")) {
            if (w < 30) { return []; }
            if (w < 45) { return w > bar ? [bar] : []; }
            n = w >= 100 ? 5 : 3;
        } else {
            n = w < 40 ? 0 : (w < 60 ? 3 : 5);
        }
        if (n == 0 || w <= bar) { return []; }
        var top = w * 0.5;
        if (top < bar) { top = bar; }
        var out = [];
        for (var i = 0; i < n; i++) {
            var x = floor25(bar + (top - bar) * i / (n - 1));
            if (x < bar) { x = bar; }
            out.add(x);
        }
        return out;
    }

    // ---------- Discos por lado ----------
    function stripSpaces(s) {
        var chars = s.toCharArray();
        var out = "";
        for (var i = 0; i < chars.size(); i++) {
            if (chars[i] != ' ') { out = out + chars[i].toString(); }
        }
        return out;
    }

    function split(s, sep) {
        var out = [];
        var rest = s;
        while (true) {
            var i = rest.find(sep);
            if (i == null) {
                out.add(rest);
                break;
            }
            out.add(rest.substring(0, i));
            rest = rest.substring(i + 1, rest.length());
        }
        return out;
    }

    // Devuelve [gramos[], pares[]] ordenado de mayor a menor
    function inventory() {
        var s = stripSpaces(prop("plates", "25x2,20x2,15x2,10x4,5x4,2.5x4,1.25x4").toString());
        var g = [];
        var n = [];
        var parts = split(s, ",");
        for (var i = 0; i < parts.size(); i++) {
            var p = parts[i];
            var x = p.find("x");
            if (x == null) { x = p.find("X"); }
            if (x == null || x == 0) { continue; }
            var kg = p.substring(0, x).toFloat();
            var cnt = p.substring(x + 1, p.length()).toNumber();
            if (kg == null || cnt == null || kg <= 0 || cnt < 2) { continue; }
            var grams = (kg * 1000.0 + 0.5).toNumber();
            var pos = g.size();
            for (var j = 0; j < g.size(); j++) {
                if (grams > g[j]) { pos = j; break; }
            }
            g = insertAt(g, pos, grams);
            n = insertAt(n, pos, cnt / 2);
        }
        return [g, n];
    }

    function insertAt(arr, pos, v) {
        var out = [];
        for (var i = 0; i < arr.size(); i++) {
            if (i == pos) { out.add(v); }
            out.add(arr[i]);
        }
        if (pos >= arr.size()) { out.add(v); }
        return out;
    }

    // Texto "Por lado: 20 + 10 + 2,5" para una barra cargada a w kg
    function platesText(w, bar) {
        if (w < bar - 0.001) { return "Menos que la barra"; }
        if ((w - bar).abs() < 0.001) { return "Solo la barra"; }
        var inv = inventory();
        var solver = new PlateSolver(inv[0], inv[1], ((w - bar) / 2.0 * 1000.0 + 0.5).toNumber());
        solver.run();
        var used = solver.bestUsed;
        var txt = "";
        for (var i = 0; i < used.size(); i++) {
            if (i > 0) { txt = txt + " + "; }
            txt = txt + fmtKg(used[i] / 1000.0);
        }
        if (txt.length() == 0) { txt = "sin discos"; }
        var rest = solver.target - solver.bestSum;
        if (rest > 0) { txt = txt + " (faltan " + fmtKg(rest / 1000.0) + ")"; }
        return "Por lado: " + txt;
    }

    // ---------- Fechas ----------
    function todayValue() {
        return Time.today().value();
    }

    function shortDate(epoch) {
        var info = Gregorian.info(new Time.Moment(epoch), Time.FORMAT_SHORT);
        return info.day.toString() + "/" + info.month.toString();
    }

    function daysSince(epoch) {
        return (todayValue() - epoch) / 86400;
    }
}

// Busca la combinación exacta con menos discos; si no existe, la más cercana por debajo.
class PlateSolver {
    var g;
    var n;
    var target;
    var bestSum = -1;
    var bestCnt = 999;
    var bestUsed = [];
    var cur = [];

    function initialize(grams, pairs, t) {
        g = grams;
        n = pairs;
        target = t;
    }

    function run() {
        dfs(0, 0, 0);
    }

    function dfs(i, sum, cnt) {
        if (sum > bestSum || (sum == bestSum && cnt < bestCnt)) {
            bestSum = sum;
            bestCnt = cnt;
            bestUsed = [];
            for (var a = 0; a < cur.size(); a++) { bestUsed.add(cur[a]); }
        }
        if (i >= g.size() || sum == target) { return; }
        if (bestSum == target && cnt >= bestCnt) { return; }
        var maxC = (target - sum) / g[i];
        if (maxC > n[i]) { maxC = n[i]; }
        for (var c = maxC; c >= 0; c--) {
            for (var b = 0; b < c; b++) { cur.add(g[i]); }
            dfs(i + 1, sum + c * g[i], cnt + c);
            for (var d = 0; d < c; d++) { cur.remove(g[i]); }
        }
    }
}
