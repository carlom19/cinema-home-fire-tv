package tv.dumbtv.cinema;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.view.View;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Optional city-level forecast. Never requests location, identifiers or accounts. */
final class Weather {
    private static final long REFRESH_MS = 30 * 60 * 1000L;
    private static final long RETRY_MS = 5 * 60 * 1000L;
    private static final long MAX_CACHE_MS = 2 * 60 * 60 * 1000L;
    private final SharedPreferences cache;
    private final TextView view;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService network = Executors.newSingleThreadExecutor();
    private boolean loading, closed;
    private long retryAt;
    private String activeLocation = "";

    Weather(Context context, TextView view) {
        this.view = view;
        cache = context.getSharedPreferences("weather", Context.MODE_PRIVATE);
    }

    void refresh(Config cfg) {
        String latitude = cfg.get("weather.latitude", "");
        String longitude = cfg.get("weather.longitude", "");
        String city = cfg.get("weather.city", "");
        if (city.isEmpty() || !validCoordinate(latitude, 90) || !validCoordinate(longitude, 180)
                || "off".equals(cfg.get("weather.enabled", "on"))) {
            activeLocation = "";
            view.setVisibility(View.GONE);
            return;
        }
        String key = latitude + "," + longitude + ":" + city;
        if (!key.equals(activeLocation)) retryAt = 0;
        activeLocation = key;
        view.setVisibility(View.VISIBLE);
        long age = System.currentTimeMillis() - cache.getLong("updated", 0);
        boolean sameLocation = key.equals(cache.getString("location", ""));
        boolean sameDay = day(cache.getString("zone", "UTC")).equals(cache.getString("day", ""));
        boolean usable = sameLocation && sameDay && age >= 0 && age < MAX_CACHE_MS;
        if (usable) {
            view.setText(cache.getString("text", "") + (age >= REFRESH_MS ? " · Sin actualizar" : ""));
            view.setContentDescription(cache.getString("text", "") + ". Fuente: Open-Meteo");
        } else {
            view.setText(city + "\n" + (SystemClock.elapsedRealtime() < retryAt
                    ? "Clima no disponible" : "Consultando clima…"));
        }
        if (closed || loading || usable && age < REFRESH_MS || SystemClock.elapsedRealtime() < retryAt) return;
        loading = true;
        retryAt = SystemClock.elapsedRealtime() + RETRY_MS;
        network.execute(() -> {
            String result = null, date = null, zone = null;
            try {
                JSONObject response = request(latitude, longitude);
                JSONObject current = response.getJSONObject("current");
                JSONObject daily = response.getJSONObject("daily");
                zone = response.getString("timezone");
                date = daily.getJSONArray("time").getString(0);
                if (!day(zone).equals(date)) throw new IOException("Forecast is not for today");
                int code = current.getInt("weather_code");
                result = city + " · " + Math.round(current.getDouble("temperature_2m")) + "°C"
                        + "\n" + description(code)
                        + "\nHoy " + Math.round(number(daily, "temperature_2m_max")) + "°/"
                        + Math.round(number(daily, "temperature_2m_min")) + "° · Lluvia "
                        + Math.round(number(daily, "precipitation_probability_max")) + "%";
            } catch (IOException | JSONException | RuntimeException ignored) {
                // Network failures never affect the launcher; retry later while it is visible.
            }
            final String text = result, forecastDay = date, forecastZone = zone;
            main.post(() -> {
                loading = false;
                if (closed || !key.equals(activeLocation)) return;
                if (text != null) {
                    cache.edit().putString("location", key).putString("text", text)
                            .putString("day", forecastDay).putString("zone", forecastZone)
                            .putLong("updated", System.currentTimeMillis()).apply();
                    view.setText(text);
                    view.setContentDescription(text + ". Fuente: Open-Meteo");
                } else if (!usable) {
                    view.setText(city + "\nClima no disponible");
                    view.setContentDescription(city + ". Clima no disponible");
                } else {
                    view.setText(cache.getString("text", "") + " · Sin actualizar");
                }
            });
        });
    }

    private static JSONObject request(String latitude, String longitude) throws IOException, JSONException {
        URL url = new URL("https://api.open-meteo.com/v1/forecast?latitude=" + Double.parseDouble(latitude)
                + "&longitude=" + Double.parseDouble(longitude)
                + "&current=temperature_2m,weather_code"
                + "&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max"
                + "&timezone=auto&forecast_days=1");
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setConnectTimeout(8000);
        connection.setReadTimeout(8000);
        connection.setInstanceFollowRedirects(false);
        connection.setRequestProperty("Accept", "application/json");
        try {
            if (connection.getResponseCode() != 200) throw new IOException("Weather request failed");
            try (InputStream input = connection.getInputStream();
                    ByteArrayOutputStream output = new ByteArrayOutputStream()) {
                byte[] buffer = new byte[2048];
                int read;
                while ((read = input.read(buffer)) != -1) {
                    if (output.size() + read > 65536) throw new IOException("Response too large");
                    output.write(buffer, 0, read);
                }
                return new JSONObject(output.toString("UTF-8"));
            }
        } finally {
            connection.disconnect();
        }
    }

    private static double number(JSONObject daily, String key) throws JSONException {
        JSONArray values = daily.getJSONArray(key);
        return values.getDouble(0);
    }

    private static boolean validCoordinate(String value, double limit) {
        try {
            double coordinate = Double.parseDouble(value);
            return !Double.isNaN(coordinate) && !Double.isInfinite(coordinate) && Math.abs(coordinate) <= limit;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    private static String day(String zone) {
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd", Locale.ROOT);
        format.setTimeZone(TimeZone.getTimeZone(zone));
        return format.format(new Date());
    }

    static String description(int code) {
        if (code == 0) return "Despejado";
        if (code == 1) return "Mayormente despejado";
        if (code == 2) return "Parcialmente nublado";
        if (code == 3) return "Nublado";
        if (code == 45 || code == 48) return "Niebla";
        if (code >= 51 && code <= 57) return "Llovizna";
        if (code >= 61 && code <= 67) return "Lluvia";
        if (code >= 71 && code <= 77 || code == 85 || code == 86) return "Nieve";
        if (code >= 80 && code <= 82) return "Chubascos";
        if (code >= 95 && code <= 99) return "Tormentas";
        return "Condiciones variables";
    }

    void close() {
        closed = true;
        network.shutdownNow();
    }
}
