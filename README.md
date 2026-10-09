# WoW Chess

Addon de ajedrez para **World of Warcraft: Forever**. Permite desafiar a otro personaje de la misma facción y ruleset o practicar contra un bot local. Las partidas usan un reloj de 10 minutos por jugador.

## Instalación

La carpeta lista para copiar es [`WoWChess/`](WoWChess/). Contiene únicamente los archivos que carga el juego; `designs/`, `tests/` y la documentación quedan fuera. Elegí los pasos de tu sistema operativo. Los instaladores buscan la carpeta habitual de WoW: Forever y también aceptan la ruta de `Interface/AddOns` si instalaste el juego en otro lugar.

1. Cerrá WoW: Forever si está abierto.
2. Desde la raíz de este proyecto, instalá el addon:

   **Linux** (terminal Bash):

   ```bash
   ./install.sh
   ```

   Si no encuentra el juego, indicá la carpeta de AddOns de tu instalación de Wine, Lutris o Battle.net:

   ```bash
   ./install.sh '/ruta/a/World of Warcraft/_classic_beta_/Interface/AddOns'
   ```

   **Windows** (PowerShell):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

   Si instalaste el juego en otra unidad o carpeta:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -AddOnsDir 'D:\Juegos\World of Warcraft\_classic_beta_\Interface\AddOns'
   ```

   También podés copiar `WoWChess/` manualmente dentro de la carpeta `World of Warcraft/_classic_beta_/Interface/AddOns` de tu instalación.

3. Comprobá que exista `Interface/AddOns/WoWChess/WoWChess_Camelot.toc`. El archivo `.toc` debe estar directamente dentro de `WoWChess/`, sin otra carpeta intermedia.
4. Abrí **WoW: Forever**. En la selección de personajes, entrá a **AddOns** y asegurate de que **WoW Chess** esté habilitado. Para jugar entre dos personas, comprobá que el `## Version` del archivo `.toc` instalado sea el mismo en ambos equipos. Si actualizaste el addon con el juego abierto, reiniciá ambos clientes.
   Para jugar entre dos personas, ambos jugadores deben instalar `0.3.9-beta`; esta versión usa el protocolo 6 y no se conecta con las versiones anteriores.
5. Para jugar contra otra persona, ambos jugadores deben instalar y activar el addon. Para practicar contra el bot alcanza con una instalación.

Para actualizarlo, ejecutá de nuevo el instalador de tu sistema operativo con la misma ruta si la habías indicado.

Si un reto no llega, escribí `/chess status` en ambos clientes antes de que termine la espera. Muestra el protocolo cargado, el estado de la partida y la edad del último mensaje directo enviado y recibido. `invite=popup` indica que el receptor procesó la invitación; `received=none` indica que el addon no recibió ningún mensaje directo de este protocolo desde que inició. En Forever, los mensajes directos se envían al nombre del personaje sin sufijo de reino; el nombre completo sigue usándose para identificar al rival dentro del protocolo.

Para investigar un reto fallido con `0.3.9-beta` en **ambos** clientes:

1. Reiniciá ambos clientes y ejecutá `/chess log clear` en cada uno.
2. Enviá un reto y esperá unos segundos. Si no aparece el diálogo, ejecutá `/chess log` en cada cliente y compará las líneas con el mismo número después de `INV#`.
3. Compartí ambos registros. Podés ocultar los nombres de personajes, pero conservá los seis dígitos de `INV#` para relacionar las líneas. `SEND INV ... accepted` solo confirma que la API aceptó el envío; `RECV INV` confirma que llegó al addon del receptor. Después aparecen `INV popup`, `INV invalid-name`, `INV different-faction` o `INV busy` para mostrar qué hizo el receptor. `INV name-mismatch` registra que el nombre declarado no coincidió con el remitente informado por WoW y que el addon usó a ese remitente para continuar.

`/chess log all` muestra hasta 80 eventos recientes; `/chess debug` activa o desactiva la impresión en vivo. El registro solo conserva metadatos en memoria (acción, destinatario/remitente, los últimos seis dígitos del ID y el resultado de la API), no el contenido completo de los mensajes, y se pierde al reiniciar o usar `/reload`.
La versión instalada también aparece en la esquina inferior derecha de la pantalla principal.

## Cómo jugar

Para practicar, abrí la pantalla principal y pulsá **Practicar / Bot intermedio**. La partida empieza enseguida, sin invitación ni conexión con otro personaje. Se sortean las blancas; cada lado tiene 10 minutos. Podés rendirte y volver a jugar desde la pantalla principal. Las partidas de práctica no modifican las estadísticas contra otros jugadores.

Para jugar contra otra persona:

1. Entrá con un personaje. La pantalla principal se abre al ingresar; después podés abrirla o cerrarla con `/chess`, `/wowchess` o el botón **C** junto al minimapa.
2. Esperá unos segundos a que aparezcan usuarios del addon en **Jugadores disponibles**. Podés pulsar **Actualizar**. La ventana del otro jugador puede estar cerrada.
3. Pulsá **Retar** junto a un jugador disponible. Si no aparece, escribí el nombre completo del personaje (nombre y apellido, sin reino) en **Nombre completo** y presioná Enter. El mensaje directo debe poder llegarle.
4. El otro jugador acepta o rechaza la invitación. Si no responde en 30 segundos, vence. Al aceptar, se sortean las blancas; los clientes reintentan el inicio y confirman la conexión antes de poner en marcha los relojes. El tablero indica quién empieza. Si no logran conectar en 30 segundos, la partida se cancela sin contar un resultado.
5. En tu turno, hacé clic en una de tus piezas y luego en una casilla marcada. Si un peón promociona, elegí dama, torre, alfil o caballo.
6. El reloj de cada jugador corre durante su turno. Podés **Ofrecer tablas**, **Rendirte** o volver a la lista sin abandonar la partida; **Volver a partida** la reabre. Quedarse sin tiempo o desconectarse causa derrota.

Cuando el bot o tu rival hace una jugada, aparece un **!** en el botón **C** junto al minimapa para avisarte que es tu turno. Pulsá el botón para abrir la partida y quitar el aviso. También desaparece al interactuar con el tablero o al terminar la partida.

Cada personaje puede mantener una sola partida activa. Se admiten enroque, captura al paso, jaque mate, ahogado y tablas por material insuficiente, triple repetición, 50 movimientos o acuerdo entre jugadores.

## Opciones

En la pantalla principal, abrí **Opciones** en el menú lateral. En **Tablero** podés elegir el fondo ilustrado de Durotar o el tablero clásico de dos colores. En **Idioma** podés elegir español o inglés. Los cambios se aplican en el momento y se conservan al volver a entrar. Si todavía no elegiste un idioma, el addon usa inglés cuando el cliente está en inglés y español en los demás casos.

## Estructura

| Ruta | Responsabilidad |
| --- | --- |
| `WoWChess/Chess.lua` | Reglas y estado de ajedrez, sin dependencias del cliente |
| `WoWChess/Bot.lua` | Búsqueda y evaluación del bot local; usa las reglas de `Chess.lua` |
| `WoWChess/Locale.lua` | Textos en español e inglés |
| `WoWChess/Network.lua` | Descubrimiento, canal y mensajes directos |
| `WoWChess/Game.lua` | Invitaciones, partida, reloj y resultados |
| `WoWChess/Theme.lua` | Selección intercambiable de tablero y piezas |
| `WoWChess/UI.lua` | Pantalla principal, tablero y diálogos |
| `WoWChess/assets/` | Tablero y piezas preparados a partir de `designs/` |

Torneos, Aspectos, Historial y crear partida se muestran como vistas preliminares.

## Verificación y límites de la beta

Desde la raíz del proyecto:

```bash
lua5.1 tests/core_spec.lua
lua5.1 tests/chess_spec.lua
lua5.1 tests/game_spec.lua
lua5.1 tests/bot_spec.lua
lua5.1 tests/settings_spec.lua
lua5.1 tests/network_spec.lua
lua5.1 tests/handshake_spec.lua
luac5.1 -p WoWChess/*.lua
```

La búsqueda del bot tiene profundidad máxima de cuatro jugadas parciales y un presupuesto aproximado de cuatro segundos por turno. Es una dificultad orientativa, no una clasificación Elo. La integración del bot todavía requiere prueba dentro de Forever; la conexión entre jugadores requiere prueba con dos clientes actualizados. En la beta se han reportado canales personalizados separados entre reinos internos del mismo ruleset; por eso la lista puede omitir jugadores conectados. Si el cliente se cierra abruptamente, el rival detecta la pérdida de contacto tras 20 segundos. Las estadísticas locales del cliente cerrado pueden no guardarse, porque SavedVariables se escriben al salir normalmente.
