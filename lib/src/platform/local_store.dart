import 'local_store_stub.dart'
    if (dart.library.js_interop) 'local_store_web.dart';

String? readLocalValue(String key) => readPlatformLocalValue(key);

void writeLocalValue(String key, String value) =>
    writePlatformLocalValue(key, value);

void removeLocalValue(String key) => removePlatformLocalValue(key);
