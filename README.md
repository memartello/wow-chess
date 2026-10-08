# WoW Chess

Addon de ajedrez para **World of Warcraft: Forever**. Permite desafiar a otro personaje de la misma facción y ruleset o practicar contra un bot local. Las partidas usan un reloj de 10 minutos por jugador.

## Instalación en Linux

La carpeta lista para copiar es [`WoWChess/`](WoWChess/). Contiene únicamente los archivos que carga el juego; `designs/`, `tests/` y la documentación quedan fuera.

1. Cerrá WoW: Forever si está abierto.
2. Desde la raíz de este proyecto, ejecutá el instalador:

   ```bash
   ./install.sh
   ```

   También podés copiar la carpeta manualmente:

   ```bash
   cp -a WoWChess '/home/mmartello/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/'
   ```

3. Comprobá que exista `.../_classic_beta_/Interface/AddOns/WoWChess/WoWChess_Camelot.toc`. El archivo `.toc` debe estar directamente dentro de `WoWChess/`, sin otra carpeta intermedia.
4. Abrí **WoW: Forever**. En la selección de personajes, entrá a **AddOns** y asegurate de que **WoW Chess** esté habilitado. Si actualizaste el addon con el juego abierto, usá `/reload`.
5. Para jugar contra otra persona, ambos jugadores deben instalar y activar el addon. Para practicar contra el bot alcanza con una instalación.

Para actualizar una instalación existente, copiá el contenido nuevo encima de la carpeta instalada:

```bash
cp -a WoWChess/. '/home/mmartello/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/WoWChess/'
```

## Cómo jugar

Para practicar, abrí la pantalla principal y pulsá **Practicar / Bot intermedio**. La partida empieza enseguida, sin invitación ni conexión con otro personaje. Se sortean las blancas; cada lado tiene 10 minutos. Podés rendirte y volver a jugar desde la pantalla principal. Las partidas de práctica no modifican las estadísticas contra otros jugadores.

Para jugar contra otra persona:

1. Entrá con un personaje. La pantalla principal se abre al ingresar; después podés abrirla o cerrarla con `/chess`, `/wowchess` o el botón **C** junto al minimapa.
2. Esperá unos segundos a que aparezcan usuarios del addon en **Jugadores disponibles**. Podés pulsar **Actualizar**. La ventana del otro jugador puede estar cerrada.
3. Pulsá **Retar** junto a un jugador disponible. Si no aparece, escribí `Nombre` o `Nombre-Reino` en **Desafiar por nombre** y presioná Enter. El mensaje directo debe poder llegarle.
4. El otro jugador acepta o rechaza la invitación. Si no responde en 30 segundos, vence. Al aceptar, se sortean las blancas y el tablero indica quién empieza.
5. En tu turno, hacé clic en una de tus piezas y luego en una casilla marcada. Si un peón promociona, elegí dama, torre, alfil o caballo.
6. El reloj de cada jugador corre durante su turno. Podés **Ofrecer tablas**, **Rendirte** o volver a la lista sin abandonar la partida; **Volver a partida** la reabre. Quedarse sin tiempo o desconectarse causa derrota.

Cada personaje puede mantener una sola partida activa. Se admiten enroque, captura al paso, jaque mate, ahogado y tablas por material insuficiente, triple repetición, 50 movimientos o acuerdo entre jugadores.

## Estructura

| Ruta | Responsabilidad |
| --- | --- |
| `WoWChess/Chess.lua` | Reglas y estado de ajedrez, sin dependencias del cliente |
| `WoWChess/Bot.lua` | Búsqueda y evaluación del bot local; usa las reglas de `Chess.lua` |
| `WoWChess/Network.lua` | Descubrimiento, canal y mensajes directos |
| `WoWChess/Game.lua` | Invitaciones, partida, reloj y resultados |
| `WoWChess/Theme.lua` | Selección intercambiable de tablero y piezas |
| `WoWChess/UI.lua` | Pantalla principal, tablero y diálogos |
| `WoWChess/assets/` | Tablero y piezas preparados a partir de `designs/` |

Torneos, Aspectos, Historial y crear partida se muestran como vistas preliminares.

## Verificación y límites de la beta

Desde la raíz del proyecto:

```bash
lua5.1 tests/chess_spec.lua
lua5.1 tests/game_spec.lua
lua5.1 tests/bot_spec.lua
luac5.1 -p WoWChess/*.lua
```

La búsqueda del bot tiene profundidad máxima de cuatro jugadas parciales y un presupuesto aproximado de cuatro segundos por turno. Es una dificultad orientativa, no una clasificación Elo. La integración del bot todavía requiere prueba dentro de Forever; la integración entre jugadores requiere prueba con dos clientes. En la beta se han reportado canales personalizados separados entre reinos internos del mismo ruleset; por eso la lista puede omitir jugadores conectados. Si el cliente se cierra abruptamente, el rival detecta la pérdida de contacto tras 20 segundos. Las estadísticas locales del cliente cerrado pueden no guardarse, porque SavedVariables se escriben al salir normalmente.
