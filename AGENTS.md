# WoW Chess — lineamientos del proyecto

## Cliente y alcance

- El cliente objetivo es World of Warcraft: Forever (`Interface: 16001` en la beta 1.60.1). Verificar las APIs en el cliente objetivo; no asumir compatibilidad con Classic Era ni Retail por el nombre del producto.
- La primera versión permite una partida de ajedrez en tiempo real por personaje, entre jugadores de la misma facción y ruleset.
- El modo de práctica permite elegir entre dificultades fácil, intermedia y difícil, y jugar con blancas o negras contra un bot local. No usa mensajes de partida ni modifica las estadísticas contra otros jugadores. Mantener la dificultad separada de las reglas y del transporte para poder ajustarla o reemplazar el bot.
- Descubrir usuarios conectados del addon que sean alcanzables por su canal. La lista puede ser incompleta debido a las limitaciones de comunicación de la beta.
- Anunciar el nombre completo del personaje en la presencia y validarlo contra el remitente del canal antes de usarlo como destino de invitaciones.
- Iniciar partidas por invitación directa; las invitaciones expiran tras 30 segundos.
- Ofrecer Partida rápida, que invita al azar a un usuario descubierto y disponible; si no hay ninguno, informar al jugador sin iniciar una invitación.
- Reintentar la invitación, la aceptación y el inicio ante pérdidas de mensajes. Confirmar la conexión entre ambos clientes antes de activar los relojes y cancelar un inicio fallido sin registrar victoria ni derrota.
- Cada jugador dispone de 10 minutos sin incremento. Una desconexión o pérdida de contacto sostenida causa derrota.
- Aplicar las reglas del ajedrez, incluidos enroque, captura al paso, promoción, jaque mate y tablas.
- Sortear las blancas al aceptar el reto y mostrar el nombre de quien comienza junto a un indicador en el tablero.
- La interfaz admite español e inglés. Usar el idioma del cliente por defecto y permitir cambiarlo en Opciones sin alterar los códigos internos ni el protocolo. Las secciones futuras pueden mostrarse como vistas preliminares, sin simular funciones inexistentes.
- Mostrar el retrato actual del personaje en la sección de perfil y refrescarlo cuando el cliente notifique un cambio de retrato.
- Avisar con el sonido de solicitud del buscador de grupos y un pulso visible y centrado en el borde del icono del minimapa cuando una jugada válida del bot o rival deja el turno al jugador. Reproducir el sonido una vez por aviso; quitar el pulso al abrir o usar el tablero y al terminar la partida. Los mensajes duplicados no deben generar avisos nuevos.
- Con una partida activa, el icono del minimapa abre o cierra solo la pantalla de partida; cerrar la partida con la X deja la interfaz cerrada. Abrir la pantalla principal requiere una navegación explícita.
- En el historial de la partida, permitir seleccionar por separado las jugadas de blancas y negras para resaltar origen y destino en el tablero actual. La selección visual no modifica la posición ni el reloj.
- Mostrar nombres y relojes del rival en una sección separada encima de la ilustración del tablero y los propios en otra sección separada debajo, sin solapar la ilustración ni las casillas; enseñar en cada fila las piezas perdidas por ese jugador a partir de capturas reales, incluida la captura al paso. Centrar el tablero en altura y mantener las piezas dentro de sus casillas.
- Resaltar solo el borde de la sección del jugador al que le toca mover con un brillo sutil; mantener el fondo de la sección igual. Situar el indicador de turno dentro de esa sección, actualizarlo al cambiar el turno y quitarlo al finalizar la partida.
- La pantalla de partida usa el tablero con las secciones de jugadores encima y debajo y una columna a la derecha para historial, pieza seleccionada y acciones. No agregar una columna izquierda redundante; ubicar Rendirse en la sección de pieza seleccionada y ocultar Ofrecer tablas en práctica contra bot.
- La navegación principal no tiene entradas separadas para Jugadores ni Torneos. El listado de conectados vive en Jugar; conservar altura suficiente en el banner y en la lista visible.

## Arquitectura

- Mantener independientes la lógica de ajedrez, el estado y reloj de la partida, el transporte entre clientes, la interfaz y los recursos visuales.
- Guardar en SavedVariables el idioma, el fondo de tablero, el set de piezas y la posición angular del icono del minimapa elegidos. Mantener las opciones visuales separadas de las reglas y de la asignación de blancas y negras.
- Permitir mostrar u ocultar coordenadas de rango y columna dentro de las casillas del borde desde Opciones; habilitarlas por defecto y guardar la preferencia en SavedVariables. Orientar etiquetas según el lado del tablero.
- Ejecutar la búsqueda del bot por tramos breves entre cuadros para que la interfaz siga respondiendo; limitar también el tiempo total de cada jugada.
- El motor de ajedrez debe ser Lua puro y poder probarse fuera del cliente.
- Validar remitentes, estados y secuencia de todos los mensajes recibidos; limitar el tráfico y tolerar duplicados.
- Mantener un registro de diagnóstico acotado en memoria para envíos, recepciones, descartes y transiciones del inicio. No guardar el contenido completo de los mensajes ni asumir que el éxito de la API confirma la entrega al otro cliente.
- Incluir el nombre completo `Personaje-Reino` en la invitación y la aceptación. Usar el remitente del evento como identidad autorizada para el intercambio; si el nombre declarado no coincide, registrar la diferencia y responder al remitente, sin aceptar la identidad declarada. Conservar el remitente para autenticar los mensajes siguientes. La beta puede informar un sufijo de reino distinto en el evento.
- Mantener el nombre completo para identificar al rival en el protocolo, pero dirigir `SendAddonMessage(..., "WHISPER", target)` al nombre del personaje sin sufijo de reino en Forever; el servidor de la beta rechaza el destino `Personaje-Reino`.
- Usar APIs nativas y no añadir bibliotecas externas sin una necesidad comprobada.
- Usar eventos, evitar acciones protegidas y restricciones de combate, y usar SavedVariables solo para datos que se decida conservar.

## Recursos

- `designs/main.png` y `designs/match.png` son referencias de interfaz. `designs/bacgrounds.png` contiene paneles y fondos para la interfaz; `designs/icon.png` es una hoja de iconos para Jugar/Partida rápida, Aspectos, Historial, Opciones y Jugar con bot. Preparar los recursos que se usen de forma independiente en `WoWChess/assets/`.
- En la pantalla principal, usar el banner panorámico a todo el ancho de la columna de juego y el fondo de pergamino debajo, detrás de las acciones y la lista de jugadores.
- Ofrecer el tablero cuadrado de `designs/square-board.png` para la Alianza y el tablero cuadrado de la Horda de `designs/horde-square.png` para la Horda como valores predeterminados por facción cuando no haya una selección guardada; incluir también el tablero de arriba a la izquierda de `designs/board` (Durotar) y un tablero clásico generado por la interfaz. Ofrecer las piezas básicas de `designs/basic-pieces.png` como opción predeterminada y las piezas humanas contra orcos de `designs/pieces` como alternativa. Conservar los temas ya elegidos en SavedVariables.
- Mantener la asignación de blancas y negras separada del aspecto humano/orco; tablero y piezas deben poder sustituirse sin cambiar las reglas.

## Verificación

- Probar el motor de ajedrez, el bot, las opciones, el cambio de idioma y el inicio entre dos clientes simulados fuera de WoW. Comprobar los fondos y textos en el cliente, el modo de práctica y el flujo entre jugadores con dos clientes de la beta: descubrimiento, invitación, reintentos, jugadas, relojes, resultados y desconexión.
- Documentar las limitaciones que solo puedan verificarse dentro del juego.
