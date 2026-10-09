# WoW Chess — lineamientos del proyecto

## Cliente y alcance

- El cliente objetivo es World of Warcraft: Forever (`Interface: 16001` en la beta 1.60.1). Verificar las APIs en el cliente objetivo; no asumir compatibilidad con Classic Era ni Retail por el nombre del producto.
- La primera versión permite una partida de ajedrez en tiempo real por personaje, entre jugadores de la misma facción y ruleset.
- El modo de práctica enfrenta al personaje con un bot local, sin mensajes de partida ni cambios en las estadísticas contra otros jugadores. Mantener la dificultad separada de las reglas y del transporte para poder ajustarla o reemplazar el bot.
- Descubrir usuarios conectados del addon que sean alcanzables por su canal. La lista puede ser incompleta debido a las limitaciones de comunicación de la beta.
- Anunciar el nombre completo del personaje en la presencia y validarlo contra el remitente del canal antes de usarlo como destino de invitaciones.
- Iniciar partidas por invitación directa; las invitaciones expiran tras 30 segundos.
- Reintentar la invitación, la aceptación y el inicio ante pérdidas de mensajes. Confirmar la conexión entre ambos clientes antes de activar los relojes y cancelar un inicio fallido sin registrar victoria ni derrota.
- Cada jugador dispone de 10 minutos sin incremento. Una desconexión o pérdida de contacto sostenida causa derrota.
- Aplicar las reglas del ajedrez, incluidos enroque, captura al paso, promoción, jaque mate y tablas.
- Sortear las blancas al aceptar el reto y mostrar el nombre de quien comienza junto a un indicador en el tablero.
- La interfaz admite español e inglés. Usar el idioma del cliente por defecto y permitir cambiarlo en Opciones sin alterar los códigos internos ni el protocolo. Las secciones futuras pueden mostrarse como vistas preliminares, sin simular funciones inexistentes.
- Avisar en el icono del minimapa cuando una jugada válida del bot o rival deja el turno al jugador. Quitar el aviso al abrir o usar el tablero y al terminar la partida; los mensajes duplicados no deben generar avisos nuevos.

## Arquitectura

- Mantener independientes la lógica de ajedrez, el estado y reloj de la partida, el transporte entre clientes, la interfaz y los recursos visuales.
- Guardar en SavedVariables el idioma y el fondo de tablero elegidos. Mantener las opciones visuales separadas de las reglas y de la asignación de blancas y negras.
- Ejecutar la búsqueda del bot por tramos breves entre cuadros para que la interfaz siga respondiendo; limitar también el tiempo total de cada jugada.
- El motor de ajedrez debe ser Lua puro y poder probarse fuera del cliente.
- Validar remitentes, estados y secuencia de todos los mensajes recibidos; limitar el tráfico y tolerar duplicados.
- Incluir el nombre completo `Personaje-Reino` en la invitación y la aceptación. Validar el nombre del personaje contra el remitente del evento y conservar ese remitente para autenticar los mensajes siguientes. La beta puede informar un sufijo de reino distinto en el evento.
- Mantener el nombre completo para identificar al rival en el protocolo, pero dirigir `SendAddonMessage(..., "WHISPER", target)` al nombre del personaje sin sufijo de reino en Forever; el servidor de la beta rechaza el destino `Personaje-Reino`.
- Usar APIs nativas y no añadir bibliotecas externas sin una necesidad comprobada.
- Usar eventos, evitar acciones protegidas y restricciones de combate, y usar SavedVariables solo para datos que se decida conservar.

## Recursos

- `designs/main.png` y `designs/match.png` son referencias de interfaz.
- Ofrecer el tablero de arriba a la izquierda de `designs/board` (Durotar) y un tablero clásico generado por la interfaz; mantener las piezas humanas contra orcos de `designs/pieces`.
- Mantener la asignación de blancas y negras separada del aspecto humano/orco; tablero y piezas deben poder sustituirse sin cambiar las reglas.

## Verificación

- Probar el motor de ajedrez, el bot, las opciones, el cambio de idioma y el inicio entre dos clientes simulados fuera de WoW. Comprobar los fondos y textos en el cliente, el modo de práctica y el flujo entre jugadores con dos clientes de la beta: descubrimiento, invitación, reintentos, jugadas, relojes, resultados y desconexión.
- Documentar las limitaciones que solo puedan verificarse dentro del juego.
