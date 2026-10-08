# WoW Chess — lineamientos del proyecto

## Cliente y alcance

- El cliente objetivo es World of Warcraft: Forever (`Interface: 16001` en la beta 1.60.1). Verificar las APIs en el cliente objetivo; no asumir compatibilidad con Classic Era ni Retail por el nombre del producto.
- La primera versión permite una partida de ajedrez en tiempo real por personaje, entre jugadores de la misma facción y ruleset.
- El modo de práctica enfrenta al personaje con un bot local, sin mensajes de partida ni cambios en las estadísticas contra otros jugadores. Mantener la dificultad separada de las reglas y del transporte para poder ajustarla o reemplazar el bot.
- Descubrir usuarios conectados del addon que sean alcanzables por su canal. La lista puede ser incompleta debido a las limitaciones de comunicación de la beta.
- Iniciar partidas por invitación directa; las invitaciones expiran tras 30 segundos.
- Cada jugador dispone de 10 minutos sin incremento. Una desconexión o pérdida de contacto sostenida causa derrota.
- Aplicar las reglas del ajedrez, incluidos enroque, captura al paso, promoción, jaque mate y tablas.
- Sortear las blancas al aceptar el reto y mostrar el nombre de quien comienza junto a un indicador en el tablero.
- La interfaz inicial está en español. Las secciones futuras pueden mostrarse como vistas preliminares, sin simular funciones inexistentes.

## Arquitectura

- Mantener independientes la lógica de ajedrez, el estado y reloj de la partida, el transporte entre clientes, la interfaz y los recursos visuales.
- Ejecutar la búsqueda del bot por tramos breves entre cuadros para que la interfaz siga respondiendo; limitar también el tiempo total de cada jugada.
- El motor de ajedrez debe ser Lua puro y poder probarse fuera del cliente.
- Validar remitentes, estados y secuencia de todos los mensajes recibidos; limitar el tráfico y tolerar duplicados.
- Usar APIs nativas y no añadir bibliotecas externas sin una necesidad comprobada.
- Usar eventos, evitar acciones protegidas y restricciones de combate, y usar SavedVariables solo para datos que se decida conservar.

## Recursos

- `designs/main.png` y `designs/match.png` son referencias de interfaz.
- Empezar con el tablero de arriba a la izquierda de `designs/board` y las piezas humanas contra orcos de `designs/pieces`.
- Mantener la asignación de blancas y negras separada del aspecto humano/orco; tablero y piezas deben poder sustituirse sin cambiar las reglas.

## Verificación

- Probar el motor de ajedrez y el bot fuera de WoW. Comprobar el modo de práctica en el cliente y el flujo entre jugadores con dos clientes de la beta: descubrimiento, invitación, jugadas, relojes, resultados y desconexión.
- Documentar las limitaciones que solo puedan verificarse dentro del juego.
