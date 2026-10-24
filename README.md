# Cinema home para Fire TV

Un inicio inspirado en tvOS, basado en [dumbtv home](https://github.com/humblemuzzu/dumbtv), con paisaje cinematográfico, aplicaciones en cuadrícula, enfoque animado y clima por ciudad.

## Qué incluye

- Tarjetas grandes con los banners originales de cada aplicación.
- Dos iconos pequeños para Personalizar y Ajustes, con etiquetas accesibles.
- Ciudad, temperatura, condiciones, máxima/mínima y probabilidad de lluvia junto al reloj y la fecha.
- Clima de [Open-Meteo](https://open-meteo.com/), actualizado cada 30 minutos mientras el inicio está visible. No solicita GPS.
- Configuración local en `home.conf` y fondo incluido.
- Paquete independiente `tv.dumbtv.cinema`: se puede probar conservando `tv.dumbtv.home`.

La versión 1.2 se compiló e instaló en un Fire TV Stick 4K Max de primera generación, modelo AFTKA, Fire OS 7.7.1.3 / PS7713.5443N / Android 9 (SDK 28). Se comprobó HOME desde Prime Video, Netflix y YouTube y su persistencia tras un reinicio. Se verificó el panel meteorológico con datos reales.

**Otros modelos y compilaciones necesitan su propio diagnóstico.** Cinema no se ha probado en Fire OS 6 ni en todos los dispositivos Fire OS 8. La prueba de apertura de una aplicación no certifica reproducción de vídeo o suscripciones.

## Empezar con Claude Code

1. Clona este repositorio y abre Claude Code en su carpeta.
2. Hazle leer `AGENTS.md`, `CLAUDE.md` y [la guía de instalación](docs/GUIA-CLAUDE-OTRO-FIRE-TV.txt).
3. Usa [el prompt preparado](docs/PROMPT-PARA-CLAUDE.txt) e indica la IP del nuevo Fire TV y su ciudad para el clima.
4. Ejecuta primero el diagnóstico de dumbtv, revisa el resultado y autoriza el plan antes de modificar la TV.

La guía conserva Prime Video, Netflix, YouTube, Alexa y las actualizaciones automáticas. La reducción opcional de publicidad se limita a ocho candidatos documentados, comprobados individualmente en cada TV. No ejecuta el paquete completo de limpieza ni instala filtros DNS.

## Descargar

El APK compilado está en [dist/cinema-home-1.2.apk](dist/cinema-home-1.2.apk). Compara su SHA-256 con [SHA256SUMS.txt](SHA256SUMS.txt). El fondo está en [cinema-launcher/assets/wallpaper.png](cinema-launcher/assets/wallpaper.png).

El APK **no configura HOME por sí solo**. Primero se prueba como una app. El enganche de HOME requiere respaldar y cambiar el servicio de accesibilidad según la guía. No desinstales un lanzador existente para resolver un conflicto de firma.

## Configuración

Archivo en el Fire TV:

```text
/sdcard/Android/data/tv.dumbtv.cinema/files/home.conf
```

Parte de [home.example.conf](cinema-launcher/home.example.conf) solo para una instalación nueva; no sobrescribas las preferencias de una instalación existente. El ejemplo no copia las listas de apps de la TV de referencia.

Para el clima, confirma la ciudad y añade:

```ini
weather.enabled=on
weather.city=NOMBRE_DE_LA_CIUDAD
weather.latitude=LATITUD
weather.longitude=LONGITUD
```

[Ejemplo con coordenadas generales de Santiago de los Caballeros](cinema-launcher/weather.santiago.example.conf). La ciudad es configurable; la app no determina la ubicación automáticamente. `weather.enabled=off` oculta el panel y evita consultas nuevas.

El APK solicita Internet para consultar `api.open-meteo.com` por HTTPS. No añade permisos de localización, cuentas ni analítica. Usa caché del mismo día de hasta dos horas y reintenta a los cinco minutos si falla una consulta. La atribución del proveedor aparece en Personalizar.

ARC se oculta solo como tarjeta en el lanzador cuando así se decide. Identifica el ID real de la entrada en cada TV; no desactives el servicio de audio.

## Compilar desde Windows

Requiere JDK 17, Android Platform API 25 y Android Build-Tools 34.0.0. Configura `JAVA_HOME` y `ANDROID_HOME` con esas herramientas o usa la estructura portátil descrita en la guía.

```powershell
cd cinema-launcher
.\build-windows.ps1
```

No usa Gradle ni dependencias de interfaz. Compila Java con `--release 8` y advertencias como errores, genera DEX y alinea y firma el APK. Guarda la clave creada en `cinema-launcher/build/cinema.keystore` de forma privada. **Una compilación con otra clave no puede actualizar el APK publicado sobre una instalación existente.**

Para instalar el APK ya compilado solo hacen falta ADB y Git Bash para el diagnóstico oficial; no necesitas JDK ni SDK. Descarga [Platform-Tools para Windows desde Android Developers](https://developer.android.com/tools/releases/platform-tools) y extrae la carpeta `platform-tools` dentro de `tools/` en este repositorio, de modo que exista `tools/platform-tools/adb.exe`. Las herramientas descargadas quedan excluidas de Git.

## Restauración

Conserva las capturas de ajustes y estados de paquetes de **cada TV** antes de modificarla. Para retirar Cinema, restaura primero el enganche HOME anterior y comprueba el retorno; después desinstala Cinema si quieres eliminar sus ajustes. El ejemplo [Restore-CinemaHome.ps1](scripts/Restore-CinemaHome.ps1) requiere las capturas de ese mismo aparato y verifica su identidad. No incluye ni inventa esas capturas.

No uses un restaurador general de otra TV ni actives en bloque paquetes que ya estaban desactivados. Los cambios opcionales de publicidad se revierten a sus estados originales individuales. No hace falta root ni restablecimiento de fábrica.

Las actualizaciones de Fire OS se conservan y pueden restablecer ajustes del lanzador; vuelve a diagnosticar si HOME cambia de comportamiento.

## Procedencia y licencia

Basado en `humblemuzzu/dumbtv`, commit `12c21f7d1db255a63786d250895a18e32d214924`, licencia [MIT](LICENSE), con modificaciones nativas de interfaz y clima. El fondo se generó con Imagegen para este proyecto. Los dos iconos de cabecera están dibujados como vectores en los recursos de la aplicación. Datos meteorológicos: Open-Meteo, CC BY 4.0; consulta su documentación y condiciones de uso.

Este repositorio no contiene IP, MAC, números de serie, cuentas, reportes privados, claves ADB o claves privadas de firma de las TVs usadas como referencia.
