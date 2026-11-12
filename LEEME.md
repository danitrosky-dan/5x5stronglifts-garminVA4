# Bitácora 5x5 para Garmin vívoactive 4

App de reloj (Connect IQ) con la misma lógica que la Bitácora web:
StrongLifts A/B, progresión automática, calentamiento, discos por lado según tu inventario,
cronómetro de descanso con vibración, agarre alterno del peso muerto, accesorio del día y EMOM al final.
Cada sesión se graba como actividad de Fuerza en Garmin Connect (FC, calorías, una vuelta por serie).

> El código compila para vívoactive 4 (SDK 9.3.0), pero todavía no se ha probado en el simulador ni en un reloj.
> Si al probarlo algo falla, pégame el error y lo corrijo.

## 1. Instalar las herramientas (una vez)

1. Instala **Visual Studio Code**.
2. Descarga el **Connect IQ SDK Manager** desde developer.garmin.com/connect-iq/sdk (pide cuenta Garmin).
   Ábrelo, descarga el SDK más reciente y, en la pestaña Devices, el **vívoactive 4**.
3. En VS Code instala la extensión **Monkey C** (de Garmin).
4. En VS Code: `Ctrl/Cmd + Shift + P` → **Monkey C: Generate a Developer Key**. Guárdala en un lugar seguro.
5. Si la compilación se queja de tipos: Ajustes de VS Code → busca "Monkey C type check" → elige **Gradual** u **Off**.

## 2. Poner tus valores antes de compilar

Las apps instaladas por cable **no** pueden usar los ajustes de la app Garmin Connect del teléfono,
así que edita `resources/settings/properties.xml`:

- `plates`: tu inventario de discos, `peso x cantidad total`, separados por coma, con punto decimal.
  Ejemplo: `20x2,10x4,5x4,2.5x4,1.25x4`
- `barKg` (20) y `zbarKg` (6)
- `curlKg/curlSets/curlReps` (días A) y `triKg/triSets/triReps` (días B)
- `swMin/swReps/swKg` para el EMOM
- `start_*`: pesos con los que parte cada ejercicio la primera vez

Los pesos de trabajo también se ajustan **en el reloj**: en la pantalla de cada ejercicio, desliza
hacia arriba o abajo (±2,5 kg). La progresión sigue desde el peso que realmente usaste.
El peso del accesorio también se ajusta en su pantalla (±2,5 kg) y el reloj lo recuerda para el
próximo día A (curl) o B (extensión de tríceps). `curlKg` y `triKg` solo se usan la primera vez.

Para que el reloj vuelva a tomar los pesos de `properties.xml` (los `start_*` y los accesorios),
pon `applyStart` en `true`, compila e instala. Se aplica una vez y vuelve a `false` solo.

## 3. Probar en el simulador

`Ctrl/Cmd + Shift + P` → **Monkey C: Run** → elige vívoactive 4.
En el simulador, `File → Edit Persistent Storage` permite borrar los datos guardados para empezar de cero.

## 4. Instalar en el reloj

1. `Ctrl/Cmd + Shift + P` → **Monkey C: Build for Device** → vívoactive 4. Genera un archivo `.prg`.
2. Conecta el reloj por USB y copia el `.prg` a la carpeta `GARMIN/APPS` del reloj.
   (En Mac necesitas OpenMTP o Android File Transfer para ver el reloj.)
3. Desconecta. La app aparece en el menú de apps del reloj como "Bitácora 5x5".

Alternativa: subir la app al Connect IQ Store como **beta privada** (solo visible para ti). Así se
instala desde el teléfono y los ajustes se editan desde la app Garmin Connect.

## Cómo se usa

| Pantalla | START | Deslizar ↑ / ↓ | Deslizar ← | BACK |
|---|---|---|---|---|
| Inicio | Empezar sesión | ↑ Historial | Cambiar A/B de hoy | Salir |
| Ejercicio | Comenzar | ±2,5 kg | (peso muerto) cambiar agarre | Paso anterior |
| Calentamiento | Serie hecha (sin descanso) | | | Paso anterior |
| Serie de trabajo | Registrar reps | ±1 rep (si fallaste) | | Paso anterior |
| Descanso | Seguir | | | Corregir la serie |
| Accesorio | Hecho | ±2,5 kg (queda guardado) | Omitir | Paso anterior |
| EMOM | Iniciar / terminar | | Omitir | Paso anterior |
| Resumen | Guardar | | Descartar | Paso anterior |

- Descanso: vibra a la 1:30 y a los 3:00 si completaste la serie; a los 5:00 si fallaste.
  Durante el descanso los toques en pantalla se ignoran para no cortarlo sin querer.
- EMOM: vibra al inicio de cada minuto y al terminar.
- En la pantalla de inicio solo el botón START inicia la sesión.

## Trabajar con git en VS Code

El repositorio es público en GitHub:
[danitrosky-dan/5x5stronglifts-garminVA4](https://github.com/danitrosky-dan/5x5stronglifts-garminVA4).
- Panel **Source Control** (`Ctrl/Cmd + Shift + G`): ves los archivos cambiados,
  escribes un mensaje y presionas **Commit**.
- Para subir los commits a GitHub: en ese mismo panel, **Sync Changes**
  (o `git push` en la terminal).
- Al ser público, cualquiera puede ver lo que subas: no incluyas datos personales.
- `.gitignore` deja fuera la carpeta `bin/` (archivos compilados) y tu llave de desarrollador
  (`*.der`). Nunca subas la llave: con ella se firman tus apps.

## Qué no hace (todavía)

- No se sincroniza con la Bitácora web. Las sesiones quedan en el reloj (Historial, últimas 30)
  y en Garmin Connect como actividad. Para tenerlas en la web, regístralas ahí con "Completar todas".
- Un solo accesorio por día (curl en A, extensión de tríceps en B).
