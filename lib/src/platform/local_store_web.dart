import 'package:web/web.dart' as web;

String? readPlatformLocalValue(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void writePlatformLocalValue(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {
    // Private browsing and strict browser policies can disable local storage.
  }
}

void removePlatformLocalValue(String key) {
  try {
    web.window.localStorage.removeItem(key);
  } catch (_) {
    // Keep the app usable even when browser storage is unavailable.
  }
}
