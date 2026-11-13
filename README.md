# 5x5 StrongLifts para Garmin vívoactive 4

App de reloj (Connect IQ, Monkey C) para llevar el programa **StrongLifts 5x5** directamente en la
muñeca, sin teléfono. Compatible con **vívoactive 4** y **vívoactive 4S**.

Cada sesión se graba como actividad de **Fuerza** en Garmin Connect, con frecuencia cardiaca y
calorías. Cada serie, calentamiento y descanso queda como una vuelta separada con columnas de
ejercicio, serie, repeticiones y peso.

> **Estado:** funcional. Probada en un vívoactive 4 real (compilada con el SDK 9.3.0).

## Funciones

- **Rutinas A/B alternas**
  - A: sentadilla 5×5, press de banca 5×5, remo 5×5
  - B: sentadilla 5×5, press militar 5×5, peso muerto 1×5
- **Progresión automática**: +2,5 kg por sesión completada (+5 kg en peso muerto). Si fallas, se
  repite el peso; tras 3 fallos seguidos con el mismo peso, descarga del 10 %.
- **Calentamiento** calculado desde la barra vacía hasta el 50 % de la carga de trabajo.
- **Discos por lado** según tu propio inventario de discos.
- **Cronómetro de descanso** con vibración (1:30 y 3:00 si completaste la serie, 5:00 si fallaste).
- **Agarre alterno** en el peso muerto, que se alterna en cada sesión.
- **Accesorio del día**: curl con barra Z (días A) o extensión de tríceps (días B).
- **EMOM de swings** con kettlebell al final de la sesión.
- **Historial** de las últimas 30 sesiones en el reloj.
- Ajuste de pesos y repeticiones directamente en el reloj deslizando ↑/↓.

## Inicio rápido

1. Instala VS Code, el [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (con el
   dispositivo vívoactive 4) y la extensión **Monkey C**.
2. Genera una llave de desarrollador: `Monkey C: Generate a Developer Key`.
3. Edita `resources/settings/properties.xml` con tus discos, barras y pesos iniciales.
4. Prueba en el simulador con `Monkey C: Run`, o compila con `Monkey C: Build for Device` y copia el
   `.prg` a la carpeta `GARMIN/APPS` del reloj.

La guía completa (instalación, configuración, controles de cada pantalla y limitaciones) está en
**[LEEME.md](LEEME.md)**.

## Configuración

Los valores por defecto están en [`resources/settings/properties.xml`](resources/settings/properties.xml):

| Clave | Descripción |
|---|---|
| `plates` | Inventario de discos: `peso x cantidad`, separados por coma (p. ej. `20x2,10x4,5x4`) |
| `barKg`, `zbarKg` | Peso de la barra olímpica y de la barra Z |
| `incOther`, `incDeadlift` | Incremento por sesión completada |
| `start_*` | Peso inicial de cada ejercicio |
| `applyStart` | `true` para volver a aplicar los `start_*` y los pesos de accesorios (una sola vez) |
| `curl*`, `tri*` | Peso, series y repeticiones de los accesorios |
| `swMin`, `swReps`, `swKg` | Minutos, repeticiones por minuto y peso del EMOM de swings |

Si instalas la app desde el Connect IQ Store, estos ajustes también se pueden editar desde la app
Garmin Connect del teléfono.

## Estructura

```
source/
  App.mc          Punto de entrada de la app
  Logic.mc        Reglas del programa: progresión, calentamiento, discos por lado, almacenamiento
  Workout.mc      Flujo de la sesión y grabación de la actividad FIT
  SessionView.mc  Pantallas de la sesión (ejercicio, series, descanso, accesorio, EMOM, resumen)
  HomeView.mc     Pantalla de inicio
  HistoryView.mc  Historial de sesiones
resources/        Ajustes, textos e icono
manifest.xml      Dispositivos, permisos e idioma
```

## Nota

La llave de desarrollador (`*.der`) y los compilados (`bin/`, `*.prg`) están excluidos en
`.gitignore`. No subas nunca tu llave al repositorio.
