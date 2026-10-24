# Instrucciones para agentes

Lee este archivo y `docs/GUIA-CLAUDE-OTRO-FIRE-TV.txt` antes de operar un Fire TV.

## Diagnóstico y autorización

- Cada dispositivo requiere un clon del dumbtv oficial, la lectura de sus README/AGENTS y la ejecución de `scripts/preflight.sh` antes de modificarlo.
- Usa un directorio de reportes nuevo por TV. Define tanto ADB_SERIAL como SERIAL si usas sus scripts; apunta siempre a un único dispositivo autorizado.
- Muestra modelo, Fire OS, SDK, compilación y plan concreto. Pide autorización para las modificaciones del nuevo dispositivo.
- La referencia AFTKA/Fire OS 7 no prueba compatibilidad de otros modelos o firmwares.

## Alcance

- Conserva Prime Video, Netflix, YouTube, Alexa y las actualizaciones automáticas.
- Instala y comprueba primero dumbtv home oficial. Prueba Cinema como app separada antes de configurar HOME.
- No ejecutes all.sh, debloat.sh, lockdown.sh, dnsfilter.sh o youtube.sh para este alcance limitado.
- No root, no escritura en /system, no factory reset, no borrado de APKs del sistema, no cambios de SELinux.
- Nunca actúes sobre un paquete ausente o incluido en cualquier never-disable.txt. No desactives com.amazon.vizzini ni OTA.
- No elimines aplicaciones para resolver conflictos de firma. Respalda y consulta al propietario.
- ARC es una entrada de audio. Oculta su tarjeta por configuración solo si se solicita; no desactives el servicio.

## HOME y restauración

- Cinema usa `tv.dumbtv.cinema/tv.dumbtv.cinema.Guard`. No dejes dos Guard de lanzadores activos a la vez.
- Conserva otros servicios de accesibilidad existentes y captura los valores exactos previos. Verifica enlace real con dumpsys accessibility y prueba HOME desde apps y tras un reinicio confirmado por boot_id.
- El verificador oficial tiene nombres de dumbtv escritos en el código; no lo presentes como prueba automática de Cinema.
- Fire OS 6 usa Keeper: no apliques el procedimiento Guard de Fire OS 7/8 por analogía.
- Prepara una restauración específica de cada TV. Restaura estados enabled=N originales, valores ausentes y exclusiones de batería exactos.

## Desarrollo

- Plataforma real: Android Views y Java, no HTML ni React. Mantén navegación D-pad, Back, OK y accesibilidad.
- Compila con JDK 17 / API 25 / Build-Tools 34, mediante cinema-launcher/build-windows.ps1. Trata advertencias como errores y verifica la firma.
- Evalúa la UI mediante capturas de la TV o un emulador Android, no una representación web que aparente ser una prueba nativa.
- El clima requiere ciudad confirmada; nunca infieras ubicación precisa ni solicites GPS. Conserva tiempos de espera, caché, reintentos y ausencia de cuentas/analítica.
- Revisa que la ciudad, datos y foco se vean completos junto al reloj. Iconos pequeños deben conservar blancos de enfoque accesibles.

## Privacidad

Nunca publiques reports/, report/, review/, números de serie, IP/MAC/SSID,
cuentas, home.conf real, claves ADB, tokens ni keystores. Los ejemplos públicos
son genéricos. Revisa el contenido preparado antes de hacer commit o subirlo.
